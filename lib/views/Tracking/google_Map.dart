import 'dart:async';
import 'dart:math'; // <-- Add this import for math functions
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'websockets.dart';
import '../../helpers/Apicall.dart';
import './data_Structures.dart';

class CustomGoogleMap extends StatefulWidget {
  final MapType initialMapType;
  final String orderId;
  final IO.Socket socket;

  const CustomGoogleMap({
    Key? key,
    this.initialMapType = MapType.normal,
    required this.orderId,
    required this.socket,
  }) : super(key: key);

  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _controllerDisposed = false;

  final Map<MarkerId, Marker> _markers = {};
  MapType _mapType = MapType.normal;
  LatLng? _currentLatLng; // <-- Only declare once here
  CameraPosition? _initialCamera;

  Timer? _locationTimer;
  bool _trackingActive = true;
  bool _trackingConfirmed = false;
  RouteData? _routeData;
  Set<Polyline> _polylines = {};
  final List<RouteData> _receivedRoutes = [];

  double? _lastHeading;

  @override
  void initState() {
    super.initState();
    _mapType = widget.initialMapType;
    _setCurrentLocationMarkerAndCamera();
    _ensureSocketConnectedAndStartDelivery();
    _subscribeSocketEvents();
  }

  Future<void> _ensureSocketConnectedAndStartDelivery() async {
    // Ensure socket is connected before starting delivery
    if (widget.socket.disconnected) {
      final completer = Completer<void>();
      void onConnect(_) {
        widget.socket.off('connect', onConnect);
        completer.complete();
      }
      widget.socket.on('connect', onConnect);
      widget.socket.connect();
      await completer.future;
    }
    await _startDeliveryProcess();
  }

  Future<void> _startDeliveryProcess() async {
    // Make PUT API request to start delivery
    final response = await ApiCall.callApiPut(
      {},
      '/riders/orders/${widget.orderId}/start-delivery',
      withAuth: true,
      context: context,
    );
    if (response['statusCode'] == 200) {
      // Tracking is enabled only after successful delivery start
      _trackingActive = true;
      _startDeliveryTracking();
      // Immediately emit location after starting delivery
      await _sendLocationUpdate();
    } else {
      final msg = response['body']?['message'] ?? 'Failed to start delivery';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
      _trackingActive = false;
    }
  }

  void _updateRouteOnMap(RouteData routeData) {
    if (!mounted) return;
    setState(() {
      _routeData = routeData;
      _receivedRoutes.add(routeData);

      // Only show the left distance (not the covered part)
      List<LatLng> routePoints = routeData.decodedCoordinates.isNotEmpty
          ? routeData.decodedCoordinates
              .map((c) => LatLng(c.latitude, c.longitude))
              .toList()
          : routeData.waypoints
              .map((wp) => LatLng(wp.latitude, wp.longitude))
              .toList();

      // Remove covered distance: find nearest point to current location and show only remaining route
      if (_currentLatLng != null && routePoints.isNotEmpty) {
        int closestIdx = 0;
        double minDist = double.infinity;
        for (int i = 0; i < routePoints.length; i++) {
          double dist = _distanceBetween(
            _currentLatLng!.latitude,
            _currentLatLng!.longitude,
            routePoints[i].latitude,
            routePoints[i].longitude,
          );
          if (dist < minDist) {
            minDist = dist;
            closestIdx = i;
          }
        }
        // Only show the remaining route from closestIdx onwards
        routePoints = routePoints.sublist(closestIdx);
      }

      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_polyline'),
          color: Colors.blue,
          width: 5,
          points: routePoints,
        ),
      };
    });
  }

  // Helper to calculate distance between two lat/lng points (Haversine formula)
  double _distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const double R = 6371000; // meters
    double dLat = (lat2 - lat1) * (pi / 180.0);
    double dLng = (lng2 - lng1) * (pi / 180.0);
    double a =
      (sin(dLat / 2) * sin(dLat / 2)) +
      cos(lat1 * (pi / 180.0)) *
      cos(lat2 * (pi / 180.0)) *
      (sin(dLng / 2) * sin(dLng / 2));
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  void _subscribeSocketEvents() {
    final socket = widget.socket;
    final orderId = widget.orderId;

    socket.on('order_subscription_confirmed', (data) {
      if (!mounted) return;
      print('[WebSocket] order_subscription_confirmed: $data');
      if (data is Map && data['orderId'] == orderId) {
        _trackingConfirmed = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tracking started for this order.')),
          );
        }
      }
    });

    socket.on('order_unsubscribe_from_order', (data) {
      print('[WebSocket] order_unsubscribe_from_order: $data');
    });

    socket.on('delivery_tracking_started', (data) {
      if (!mounted) return;
      print('[WebSocket] delivery_tracking_started: $data');
      if (data is Map && data['orderId'] == orderId && data['initialRoute'] != null) {
        final routeData = RouteData.fromJson(data['initialRoute']);
        _updateRouteOnMap(routeData);
      }
    });

    socket.on('rider_location_update', (data) {
      print('[WebSocket] rider_location_update: $data');
    });

    socket.on('delivery_completed', (data) {
      print('[WebSocket] delivery_completed: $data');
    });

    void handleRoute(dynamic data) {
      if (!mounted) return;
      print('[WebSocket] route_calculated/route_updated: $data');
      if (data is Map && data['orderId'] == orderId && data['route'] != null) {
        final routeData = RouteData.fromJson(data['route']);
        _updateRouteOnMap(routeData);
      }
    }

    socket.on('route_calculated', handleRoute);
    socket.on('route_updated', handleRoute);

    socket.on('route_tracking_data', (data) {
      if (!mounted) return;
      print('[WebSocket] route_tracking_data: $data');
      if (data is Map && data['orderId'] == orderId && data['route'] != null) {
        final routeData = RouteData.fromJson(data['route']);
        _updateRouteOnMap(routeData);
      }
    });
  }

  void _startDeliveryTracking() {
    startDeliveryTracking(widget.socket, widget.orderId);
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationTimer?.cancel();
    // Emit location every 5 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      print('[DEBUG] Timer triggered for location_update');
      _sendLocationUpdate();
    });
  }

  Future<void> _sendLocationUpdate() async {
    print('[DEBUG] _sendLocationUpdate called');
    // Allow location updates if tracking is active (not just confirmed)
    if (!_trackingActive || widget.socket.disconnected) {
      print('[DEBUG] Location update skipped: trackingActive=$_trackingActive, trackingConfirmed=$_trackingConfirmed, socketDisconnected=${widget.socket.disconnected}');
      return;
    }
    Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      print('[DEBUG] Got current location: $currentLocation');
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        // Emit to socket with event name "location_update" every 5 seconds
        print('[DEBUG] Emitting location_update to socket');
        sendLocationUpdate(
          widget.socket,
          widget.orderId,
          currentLocation.latitude!,
          currentLocation.longitude!,
          accuracy: currentLocation.accuracy,
          heading: currentLocation.heading,
          speed: currentLocation.speed,
        );

        // Update marker and animate camera to follow user
        final latLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _currentLatLng = latLng; // Update currentLatLng for route filtering

        // If routeData exists, update polyline to show only left distance
        if (_routeData != null) {
          _updateRouteOnMap(_routeData!);
        }

        // Only update heading if it is valid and has changed significantly
        double heading = (currentLocation.heading ?? 0.0);
        if (heading < 0 || heading > 360) heading = 0.0;
        if (_lastHeading == null || (heading - _lastHeading!).abs() > 2) {
          _lastHeading = heading;
        } else {
          heading = _lastHeading!;
        }

        if (mounted) {
          setState(() {
            _currentLatLng = latLng;
            _markers[const MarkerId('current_location')] = Marker(
              markerId: const MarkerId('current_location'),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'Your Location'),
              rotation: heading,
            );
          });
        }

        // Animate camera to follow user and rotate according to heading
        final controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: 17.5,
              bearing: heading,
              tilt: 45,
            ),
          ),
        );
      } else {
        print('[DEBUG] Location data missing latitude/longitude');
      }
    } catch (e) {
      print('[DEBUG] Error in _sendLocationUpdate: $e');
    }
  }

  Future<void> _setCurrentLocationMarkerAndCamera() async {
    Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        final latLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        setState(() {
          _currentLatLng = latLng;
          _initialCamera = CameraPosition(
            target: latLng,
            zoom: 17.5,
            bearing: currentLocation.heading ?? 0.0,
            tilt: 45,
          );
          _markers[const MarkerId('current_location')] = Marker(
            markerId: const MarkerId('current_location'),
            position: latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
            rotation: currentLocation.heading ?? 0.0,
          );
        });
        // Always send current coordinates to websocket
        sendLocationUpdate(
          widget.socket,
          widget.orderId,
          currentLocation.latitude!,
          currentLocation.longitude!,
          accuracy: currentLocation.accuracy,
          heading: currentLocation.heading,
          speed: currentLocation.speed,
        );
      }
    } catch (_) {}
  }

  Future<void> recenter() async {
    final controller = await _controller.future;
    Location location = Location();
    LocationData currentLocation;

    try {
      currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        final latLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        setState(() {
          _currentLatLng = latLng;
          _markers[const MarkerId('current_location')] = Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Your Location'),
            rotation: currentLocation.heading ?? 0.0,
          );
        });
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: 17.5,
              bearing: currentLocation.heading ?? 0.0,
              tilt: 45,
            ),
          ),
        );
        // Always send current coordinates to websocket
        sendLocationUpdate(
          widget.socket,
          widget.orderId,
          currentLocation.latitude!,
          currentLocation.longitude!,
          accuracy: currentLocation.accuracy,
          heading: currentLocation.heading,
          speed: currentLocation.speed,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get current location')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel(); // Cancel timer to avoid memory leaks
    if (_trackingActive) {
      stopDeliveryTracking(widget.socket, widget.orderId);
      _trackingActive = false;
    }
    if (!_controllerDisposed) {
      _controller.future.then((c) {
        c.dispose();
        _controllerDisposed = true;
      }).catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Defensive: If initial camera is null for too long, try to reset location
    if (_initialCamera == null) {
      // Try to re-fetch location and set camera after a short delay
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _initialCamera == null) {
          _setCurrentLocationMarkerAndCamera();
        }
      });
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialCamera!,
          onMapCreated: _onMapCreated,
          mapType: _mapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          zoomControlsEnabled: false,
          markers: Set<Marker>.of(_markers.values),
          polylines: _polylines, // Always show the latest complete route
        ),
        Positioned(
          top: 16,
          left: 16,
          child: FloatingActionButton(
            heroTag: "toggle_map_type",
            mini: true,
            onPressed: () {
              setState(() {
                _mapType = _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
              });
            },
            child: const Icon(Icons.layers_outlined),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            heroTag: "recenter",
            mini: false,
            onPressed: recenter,
            child: const Icon(Icons.my_location),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          child: ElevatedButton(
            onPressed: () async {
              if (_trackingActive) {
                final now = DateTime.now().toUtc();
                final completionTime = now.toIso8601String().split('.').first + 'Z';
                final response = await ApiCall.callApiPut(
                  {
                    'completionTime': completionTime,
                  },
                  '/riders/orders/${widget.orderId}/complete',
                  withAuth: true,
                  context: context,
                );

                if (response['statusCode'] == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order marked as complete.')),
                  );
                  stopDeliveryTracking(widget.socket, widget.orderId);
                  _trackingActive = false;
                  _locationTimer?.cancel();
                  // Move user to home screen and refresh list
                  if (mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    // Optionally, trigger a refresh if HomeScreen is still mounted
                    // (You may need to use a callback or state management for this)
                  }
                } else {
                  final msg = response['body']?['message'] ?? 'Failed to complete order';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                  _trackingActive = false;
                  _locationTimer?.cancel();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Complete order', style: TextStyle(color: Colors.white)),
          ),
        ),
        Positioned(
          bottom: 90,
          left: 16,
          child: ElevatedButton(
            onPressed: () async {
              Location location = Location();
              LocationData? currentLocation;
              try {
                currentLocation = await location.getLocation();
              } catch (_) {}
              requestRouteUpdate(
                widget.socket,
                widget.orderId,
                latitude: currentLocation?.latitude,
                longitude: currentLocation?.longitude,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Route update requested.')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Request route update', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

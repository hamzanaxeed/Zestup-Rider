import 'dart:async';
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
  LatLng? _currentLatLng;
  CameraPosition? _initialCamera;

  Timer? _locationTimer;
  bool _trackingActive = true;
  bool _trackingConfirmed = false;
  RouteData? _routeData;
  Set<Polyline> _polylines = {};
  final List<RouteData> _receivedRoutes = [];

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
    if (!mounted) return; // Prevent setState after dispose
    setState(() {
      _routeData = routeData;
      _receivedRoutes.add(routeData);
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_polyline'),
          color: Colors.blue,
          width: 5,
          points: routeData.decodedCoordinates.isNotEmpty
              ? routeData.decodedCoordinates
                  .map((c) => LatLng(c.latitude, c.longitude))
                  .toList()
              : routeData.waypoints
                  .map((wp) => LatLng(wp.latitude, wp.longitude))
                  .toList(),
        ),
      };
    });
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
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _sendLocationUpdate());
  }

  Future<void> _sendLocationUpdate() async {
    if (!_trackingActive || !_trackingConfirmed || widget.socket.disconnected) return;
    Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
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

  /// Send the user's current coordinates immediately
  Future<void> sendCurrentCoordinates() async {
    if (!_trackingActive || !_trackingConfirmed || widget.socket.disconnected) return;
    Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
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

  Future<void> _setCurrentLocationMarkerAndCamera() async {
    Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        final latLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
        setState(() {
          _currentLatLng = latLng;
          _initialCamera = CameraPosition(target: latLng, zoom: 16.0);
          _markers[const MarkerId('current_location')] = Marker(
            markerId: const MarkerId('current_location'),
            position: latLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Your Location'),
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
        setState(() {
          _currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _markers[const MarkerId('current_location')] = Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Your Location'),
          );
        });
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(currentLocation.latitude!, currentLocation.longitude!),
              zoom: 16.0,
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
    if (_initialCamera == null) {
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
                // 1. Make API request to complete the order
                // Ensure ISO string is valid (no microseconds, UTC, ends with Z)
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

                // 2. Stop delivery tracking via websocket
                stopDeliveryTracking(widget.socket, widget.orderId);

                // 3. Show result to user
                if (response['statusCode'] == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order marked as complete.')),
                  );
                } else {
                  final msg = response['body']?['message'] ?? 'Failed to complete order';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                }

                _trackingActive = false;
                _locationTimer?.cancel();
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

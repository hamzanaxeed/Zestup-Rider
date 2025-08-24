import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'websockets.dart';

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

  @override
  void initState() {
    super.initState();
    _mapType = widget.initialMapType;
    _setCurrentLocationMarkerAndCamera();
    _startDeliveryTracking();
    _subscribeSocketEvents();
  }

  void _subscribeSocketEvents() {
    final socket = widget.socket;
    final orderId = widget.orderId;

    socket.on('order_subscription_confirmed', (data) {
      print('[WebSocket] order_subscription_confirmed: $data');
      if (data is Map && data['orderId'] == orderId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tracking started for this order.')),
          );
        }
      }
    });

    socket.on('order_unsubscribe_from_order', (data) {
      print('[WebSocket] order_unsubscribe_from_order: $data');
      if (data is Map && data['orderId'] == orderId) {
        // Optionally handle unsubscription confirmation
      }
    });

    socket.on('delivery_tracking_started', (data) {
      print('[WebSocket] delivery_tracking_started: $data');
      if (data is Map && data['orderId'] == orderId) {
        // Optionally handle delivery tracking started
        // You can access: data['riderId'], data['timestamp'], data['initialRoute'], data['routeError']
      }
    });

    socket.on('rider_location_update', (data) {
      print('[WebSocket] rider_location_update: $data');
      if (data is Map && data['orderId'] == orderId) {
        // Optionally update rider marker or UI
      }
    });

    socket.on('delivery_completed', (data) {
      print('[WebSocket] delivery_completed: $data');
      if (data is Map && data['orderId'] == orderId) {
        // Optionally handle delivery completion
      }
    });

    socket.on('route_calculated', (data) {
      print('[WebSocket] route_calculated: $data');
      if (data is Map && data['orderId'] == orderId) {
        // Optionally handle initial route calculation
      }
    });

    socket.on('route_updated', (data) {
      print('[WebSocket] route_updated: $data');
      if (data is Map && data['orderId'] == orderId) {
        // Optionally handle route update
      }
    });

    socket.on('route_tracking_data', (data) {
      print('[WebSocket] route_tracking_data: $data');
      if (data is Map && data['orderId'] == orderId) {
        // Optionally handle comprehensive route tracking data
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
    if (!_trackingActive) return;
    Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
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
    _locationTimer?.cancel();
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
            onPressed: () {
              if (_trackingActive) {
                stopDeliveryTracking(widget.socket, widget.orderId);
                _trackingActive = false;
                _locationTimer?.cancel();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order marked as complete.')),
                );
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
            onPressed: () {
              requestRouteUpdate(widget.socket, widget.orderId);
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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _controllerDisposed = false;

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(24.8607, 67.0011),
    zoom: 12.0,
  );

  final Map<MarkerId, Marker> _markers = {};
  MapType _mapType = MapType.normal;

  LatLng? _currentLatLng;

  @override
  void initState() {
    super.initState();
    _setCurrentLocationMarker();
  }

  Future<void> _setCurrentLocationMarker() async {
    Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {

        setState(() {
          _currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          // Add or update blue marker for current location
          _markers[const MarkerId('current_location')] = Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),

            infoWindow: const InfoWindow(title: 'Your Location'),
          );
        });
      }
    } catch (_) {}
  }

  Future<void> _recenter() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location')),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
    }
  }

  void _addMarker(LatLng position) {
    final id = MarkerId('m_${DateTime.now().millisecondsSinceEpoch}');
    final marker = Marker(
      markerId: id,
      position: position,
      infoWindow: InfoWindow(
        title: 'Pinned',
        snippet:
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
      ),
      draggable: true,
      onDragEnd: (p) {
        setState(() {
          _markers[id] = _markers[id]!.copyWith(positionParam: p);
        });
      },
    );

    setState(() => _markers[id] = marker);
  }

  @override
  void dispose() {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        actions: [
          IconButton(
            tooltip: 'Toggle map type',
            onPressed: () {
              setState(() {
                _mapType =
                _mapType == MapType.normal ? MapType.hybrid : MapType.normal;
              });
            },
            icon: const Icon(Icons.layers_outlined),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCamera,
        onMapCreated: _onMapCreated,
        mapType: _mapType,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
        markers: Set<Marker>.of(_markers.values),
        onTap: _addMarker,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _recenter,
        label: const Text('Recenter'),
        icon: const Icon(Icons.my_location),
      ),
    );
  }
}

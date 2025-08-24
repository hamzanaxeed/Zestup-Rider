import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class CustomGoogleMap extends StatefulWidget {
  final CameraPosition initialCamera;
  final MapType initialMapType;

  const CustomGoogleMap({
    Key? key,
    required this.initialCamera,
    this.initialMapType = MapType.normal,
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

  @override
  void initState() {
    super.initState();
    _mapType = widget.initialMapType;
    _setCurrentLocationMarker();
  }

  Future<void> _setCurrentLocationMarker() async {
    Location location = Location();
    try {
      LocationData currentLocation = await location.getLocation();
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentLatLng = LatLng(currentLocation.latitude!, currentLocation.longitude!);
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

  void _addMarker(LatLng position) {
    final id = MarkerId('m_${DateTime.now().millisecondsSinceEpoch}');
    final marker = Marker(
      markerId: id,
      position: position,
      infoWindow: InfoWindow(
        title: 'Pinned',
        snippet: '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}',
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
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: widget.initialCamera,
          onMapCreated: _onMapCreated,
          mapType: _mapType,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          compassEnabled: true,
          zoomControlsEnabled: false,
          markers: Set<Marker>.of(_markers.values),
          onTap: _addMarker,
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
      ],
    );
  }
}


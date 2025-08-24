import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'google_Map.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(24.8607, 67.0011),
    zoom: 12.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
      ),
      body: CustomGoogleMap(
        initialCamera: _initialCamera,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'google_Map.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class OrderTrackingScreen extends StatelessWidget {
  final String orderId;
  final IO.Socket socket;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    required this.socket,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
      ),
      body: CustomGoogleMap(orderId: orderId, socket: socket),
    );
  }
}

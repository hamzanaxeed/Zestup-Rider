import 'package:flutter/material.dart';
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
      body: Center(
        child: Text('Order tracking in progress for order: $orderId'),
      ),
    );
  }
}

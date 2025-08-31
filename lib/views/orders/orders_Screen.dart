import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../Models/order_Model.dart';
import '../../helpers/Apicall.dart';
import '../../views/Tracking/websockets.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? orderData;
  bool loading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchOrderDetail();
  }

  Future<void> fetchOrderDetail() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });
    final response = await ApiCall.callApiGet('/order/${widget.orderId}', withAuth: true, context: context);
    if (response['statusCode'] == 200 && response['body'] != null && response['body']['success'] == true) {
      orderData = response['body']['data']['order'];
      loading = false;
      errorMsg = null;
    } else {
      loading = false;
      errorMsg = response['body']?['message'] ?? 'Failed to load order details';
    }
    setState(() {});
  }

  // Helper to get current location
  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> openGoogleMaps(double lat, double lon) async {
    final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('[OrderScreen] Could not launch Google Maps');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMsg != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(child: Text(errorMsg!, style: const TextStyle(color: Colors.red))),
      );
    }

    final order = orderData!;
    final items = order['items'] as List<dynamic>? ?? [];
    final customer = order['customer'] ?? {};
    final rider = order['rider'] ?? {};
    final address = order['address'] ?? {};
    final branch = order['branch'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${order['displayId'] ?? ''}'),
        backgroundColor: theme.primaryColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: fetchOrderDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Order ID: ${order['id']}'),
                      Text('Display ID: ${order['displayId']}'),
                      Text('Display Metadata: ${order['displayIdMetadata']}'),
                      Text('Type: ${order['type']}'),
                      Text('Status: ${order['status']}'),
                      Text('Total: ${order['total']}'),
                      Text('Tax: ${order['tax']}'),
                      Text('Delivery Cost: ${order['deliveryCost']}'),
                      Text('Discount: ${order['discount'] ?? 'N/A'}'),
                      Text('Comment: ${order['comment'] ?? 'N/A'}'),
                      Text('Created At: ${order['createdAt']}'),
                      Text('Updated At: ${order['updatedAt']}'),
                      Text('Delivery Name: ${order['deliveryName']}'),
                      Text('Delivery Phone: ${order['deliveryPhone'] ?? 'N/A'}'),
                      Text('Delivery Address: ${order['deliveryAddress']}'),
                      Text('Items Count: ${order['itemsCount']}'),
                      Text('Rating: ${order['rating'] ?? 'N/A'}'),
                      Text('Rate Comment: ${order['rateComment'] ?? 'N/A'}'),
                      Text('Cancelled Reason: ${order['cancelledReason'] ?? 'N/A'}'),
                      Text('Returned Reason: ${order['returnedReason'] ?? 'N/A'}'),
                      Text('Cancelled On: ${order['cancelledOn'] ?? 'N/A'}'),
                      Text('Completed On: ${order['completedOn'] ?? 'N/A'}'),
                      Text('Returned On: ${order['returnedOn'] ?? 'N/A'}'),
                      const Divider(height: 24),
                      Text('Customer Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Customer ID: ${customer['id'] ?? ''}'),
                      Text('Name: ${customer['firstName'] ?? ''} ${customer['lastName'] ?? ''}'),
                      Text('Phone: ${customer['phone'] ?? ''}'),
                      Text('Email: ${customer['email'] ?? ''}'),
                      const Divider(height: 24),
                      Text('Rider Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Rider ID: ${rider['id'] ?? ''}'),
                      Text('Name: ${rider['firstName'] ?? ''} ${rider['lastName'] ?? ''}'),
                      Text('Phone: ${rider['phone'] ?? ''}'),
                      Text('Email: ${rider['email'] ?? ''}'),
                      const Divider(height: 24),
                      Text('Address Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('City: ${address['city'] ?? ''}'),
                      Text('Country: ${address['country'] ?? ''}'),
                      Text('Line 1: ${address['line1'] ?? ''}'),
                      Text('Line 2: ${address['line2'] ?? ''}'),
                      Text('Latitude: ${address['lat'] ?? ''}'),
                      Text('Longitude: ${address['lon'] ?? ''}'),
                      const Divider(height: 24),
                      Text('Branch Info', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Branch ID: ${branch['id'] ?? ''}'),
                      Text('Name: ${branch['name'] ?? ''}'),
                      Text('Address: ${branch['address'] ?? ''}'),
                      Text('Latitude: ${branch['lat'] ?? ''}'),
                      Text('Longitude: ${branch['lon'] ?? ''}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((item) => Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item['variant']?['itemImage'] != null
                        ? Image.network(
                            item['variant']['itemImage'],
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey[200],
                            child: const Icon(Icons.fastfood, size: 32, color: Colors.grey),
                          ),
                  ),
                  title: Text(
                    item['variant']?['itemName'] ?? '',
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item['variant']?['name'] != null)
                        Text('Variant: ${item['variant']['name']}', style: theme.textTheme.bodySmall),
                      Text('Quantity: ${item['variant']?['quantity'] ?? ''}', style: theme.textTheme.bodySmall),
                      Text('Price: ${item['price'] ?? ''}', style: theme.textTheme.bodySmall),
                      if (item['variant']?['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item['variant']['description'],
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              )),
              // Only show buttons if order is not completed
              if ((order['status']?.toString().toLowerCase() != 'completed') &&
                  (order['status']?.toString().toLowerCase() != 'delivered'))
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final socket = await WebSocketManager().initializeSocket();

                            if (!socket.connected) {
                              socket.on('connect', (_) {
                                moveToBranch(socket, order['id'] ?? '');
                                socket.off('connect');
                              });
                            } else {
                              moveToBranch(socket, order['id'] ?? '');
                            }

                            final branch = order['branch'] ?? {};
                            final branchLat = branch['lat'] is double
                                ? branch['lat']
                                : branch['lat'] != null
                                    ? double.tryParse(branch['lat'].toString()) ?? 0.0
                                    : 0.0;
                            final branchLon = branch['lon'] is double
                                ? branch['lon']
                                : branch['lon'] != null
                                    ? double.tryParse(branch['lon'].toString()) ?? 0.0
                                    : 0.0;
                            await openGoogleMaps(branchLat, branchLon);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Go to branch',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final socket = await WebSocketManager().initializeSocket();
                            final orderId = order['id'] ?? '';

                            LocationPermission permission = await Geolocator.checkPermission();
                            if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                              permission = await Geolocator.requestPermission();
                              if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                                print("Location permission denied.");
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Location permission denied. Please enable location permissions in settings.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                            }

                            Position position;
                            try {
                              position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                            } catch (e) {
                              print("Error fetching location: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Location unavailable.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            void startTrackingFlow() {
                              startDeliveryTracking(socket, orderId, position.latitude, position.longitude);

                              socket.on('delivery_tracking_confirmed', (data) async {
                                print('[WebSocket] delivery_tracking_confirmed: $data');
                                // For now, just emit location every 2 seconds (no foreground service)
                                Timer.periodic(const Duration(seconds: 2), (timer) async {
                                  if (!mounted) {
                                    timer.cancel();
                                    return;
                                  }
                                  try {
                                    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                    sendLocationUpdate(socket, orderId, pos.latitude, pos.longitude);
                                  } catch (e) {
                                    print("Error sending location: $e");
                                  }
                                });
                                socket.off('delivery_tracking_confirmed');
                              });
                            }

                            if (!socket.connected) {
                              socket.on('connect', (_) {
                                startTrackingFlow();
                                socket.off('connect');
                              });
                            } else {
                              startTrackingFlow();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Go to delivery',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

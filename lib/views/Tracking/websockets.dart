import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

Future<IO.Socket> initializeSocket() async {
  final prefs = await SharedPreferences.getInstance();
  final jwtToken = prefs.getString('accessToken') ?? '';

  final socket = IO.io(
    'ws://zestupbackend-59oze.sevalla.app',
    IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': jwtToken})
        .build(),
  );

  socket.onConnect((_) {
    print('[WebSocket] Connected successfully');
  });
  socket.onConnectError((err) {
    print('[WebSocket] Connection error: $err');
  });
  socket.onError((err) {
    print('[WebSocket] General error: $err');
  });
  socket.onDisconnect((_) {
    print('[WebSocket] Disconnected');
  });

  return socket;
}

// Emit when delivery tracking starts
void startDeliveryTracking(IO.Socket socket, String orderId) {
  print('[WebSocket] Emitting start_delivery_tracking for orderId: $orderId');
  socket.emit("start_delivery_tracking", {
    "orderId": orderId,
  });
}

// Emit location updates
void sendLocationUpdate(
  IO.Socket socket,
  String orderId,
  double lat,
  double lng, {
  double? accuracy,
  double? heading,
  double? speed,
}) {
  final payload = {
    "orderId": orderId,
    "latitude": lat,
    "longitude": lng,
    "timestamp": DateTime.now().toIso8601String(),
    "accuracy": accuracy ?? 5.0,
    "heading": heading ?? 0.0,
    "speed": speed ?? 0.0,
  };
  print('[WebSocket] Emitting location_update: $payload');
  socket.emit("location_update", payload);
}

// Emit when delivery tracking stops
void stopDeliveryTracking(IO.Socket socket, String orderId) {
  print('[WebSocket] Emitting stop_delivery_tracking for orderId: $orderId');
  socket.emit("stop_delivery_tracking", {
    "orderId": orderId,
  });
}

// Emit to request a route update
void requestRouteUpdate(IO.Socket socket, String orderId, {double? latitude, double? longitude}) {
  final payload = {
    "orderId": orderId,
    if (latitude != null) "latitude": latitude,
    if (longitude != null) "longitude": longitude,
  };
  print('[WebSocket] Emitting request_route_update: $payload');
  socket.emit("request_route_update", payload);
}

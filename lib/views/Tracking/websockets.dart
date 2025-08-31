import 'package:flutter/widgets.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class WebSocketManager with WidgetsBindingObserver {
  IO.Socket? _socket;
  String? _jwtToken;

  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  Future<IO.Socket> initializeSocket() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('accessToken') ?? '';

    _socket = IO.io(
      'ws://zestupbackend-59oze.sevalla.app',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _jwtToken})
          .build(),
    );

    _socket!.onConnect((_) {
      print('[WebSocket] Connected successfully');
    });
    _socket!.onConnectError((err) {
      print('[WebSocket] Connection error: $err');
    });
    _socket!.onError((err) {
      print('[WebSocket] General error: $err');
    });
    _socket!.onDisconnect((_) {
      print('[WebSocket] Disconnected');
    });

    WidgetsBinding.instance.addObserver(this);

    return _socket!;
  }

  IO.Socket? get socket => _socket;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_socket == null) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Optionally keep alive or reconnect on resume
      print('[WebSocket] App in background, keeping socket alive');
    } else if (state == AppLifecycleState.resumed) {
      if (!(_socket?.connected ?? false)) {
        print('[WebSocket] App resumed, reconnecting socket');
        _socket?.connect();
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socket?.dispose();
    _socket = null;
  }
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

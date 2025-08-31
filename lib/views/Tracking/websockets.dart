import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';

class WebSocketManager with WidgetsBindingObserver {
  IO.Socket? _socket;
  String? _jwtToken;

  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();

  Future<IO.Socket> initializeSocket() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('accessToken') ?? '';

    if (_socket != null && _socket!.connected) {
      return _socket!;
    }

    _socket = IO.io(
      'ws://zestupbackend-59oze.sevalla.app',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _jwtToken})
          .enableReconnection()
          .setReconnectionAttempts(9999)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!.onConnect((_) {
      print('[WebSocket] Connected');
    });
    _socket!.onConnectError((err) {
      print('[WebSocket] Connect error: $err');
      if (err != null) {
        print('[WebSocket] Connect error details: ${err.toString()}');
      }
    });
    _socket!.onError((err) {

      print('[WebSocket] General error: $err');
      if (err != null) {
        print('[WebSocket] General error details: ${err.toString()}');
      }
    });
    _socket!.onDisconnect((_) {
      print('[WebSocket] Disconnected');
    });

    // --- RECEIVE EVENTS ---
    _socket!.on("delivery_tracking_confirmed", (data) {
      print('[WebSocket] delivery_tracking_confirmed: $data');
      if (data is Map && data.containsKey('error')) {
        print('[WebSocket] delivery_tracking_confirmed error: ${data['error']}');
      }
    });

    _socket!.on("order_out_for_delivery_by_rider", (data) {
      print('[WebSocket] order_out_for_delivery_by_rider: $data');
      if (data is Map && data.containsKey('error')) {
        print('[WebSocket] order_out_for_delivery_by_rider error: ${data['error']}');
      }
    });

    _socket!.on("route_calculated", (data) {
      print('[WebSocket] route_calculated: $data');
      if (data is Map && data.containsKey('error')) {
        print('[WebSocket] route_calculated error: ${data['error']}');
      }
    });

    _socket!.on("route_updated", (data) {
      print('[WebSocket] route_updated: $data');
      if (data is Map && data.containsKey('error')) {
        print('[WebSocket] route_updated error: ${data['error']}');
      }
    });

    _socket!.on("route_tracking_data", (data) {
      print('[WebSocket] route_tracking_data: $data');
      if (data is Map && data.containsKey('error')) {
        print('[WebSocket] route_tracking_data error: ${data['error']}');
      }
    });

    _socket!.on("error", (data) {
      print('[WebSocket] Received error event: $data');
    });

    WidgetsBinding.instance.addObserver(this);

    return _socket!;
  }

  IO.Socket? get socket => _socket;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_socket == null) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      print('[WebSocket] App in background, keeping socket alive');
    } else if (state == AppLifecycleState.resumed) {
      print('[WebSocket] App resumed');
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}

// --- EMIT EVENTS ---

void startDeliveryTracking(IO.Socket socket, String orderId, double latitude, double longitude) {
  if (socket.disconnected) {
    print('[WebSocket] Error: Socket is not connected. Cannot emit start_delivery_tracking.');
    return;
  }
  if (orderId.isEmpty) {
    print('[WebSocket] Error: orderId is empty for start_delivery_tracking.');
    return;
  }
  print('[WebSocket] Emitting start_delivery_tracking: {orderId: $orderId, latitude: $latitude, longitude: $longitude}');
  socket.emit("start_delivery_tracking", {
    "orderId": orderId,
    "latitude": latitude,
    "longitude": longitude,
  });
}

void moveToBranch(IO.Socket socket, String orderId) {
  if (socket.disconnected) {
    print('[WebSocket] Error: Socket is not connected. Cannot emit move_to_branch.');
    return;
  }
  if (orderId.isEmpty) {
    print('[WebSocket] Error: orderId is empty for move_to_branch.');
    return;
  }
  print('[WebSocket] Emitting move_to_branch: {orderId: $orderId}');
  socket.emit("move_to_branch", {
    "orderId": orderId,
  });
}

void sendLocationUpdate(
  IO.Socket socket,
  String orderId,
  double latitude,
  double longitude, {
  DateTime? timestamp,
  double? accuracy,
  double? heading,
  double? speed,
}) {
  if (socket.disconnected) {
    print('[WebSocket] Error: Socket is not connected. Cannot emit location_update.');
    return;
  }
  if (orderId.isEmpty) {
    print('[WebSocket] Error: orderId is empty for location_update.');
    return;
  }
  final payload = {
    "orderId": orderId,
    "latitude": latitude,
    "longitude": longitude,
    "timestamp": (timestamp ?? DateTime.now()).toIso8601String(),
    "accuracy": accuracy ?? 5.0,
    "heading": heading ?? 0.0,
    "speed": speed ?? 0.0,
  };
  print('[WebSocket] Emitting location_update: $payload');
  socket.emit("location_update", payload);
}

void stopDeliveryTracking(IO.Socket socket, String orderId) {
  if (socket.disconnected) {
    print('[WebSocket] Error: Socket is not connected. Cannot emit stop_delivery_tracking.');
    return;
  }
  if (orderId.isEmpty) {
    print('[WebSocket] Error: orderId is empty for stop_delivery_tracking.');
    return;
  }
  print('[WebSocket] Emitting stop_delivery_tracking: {orderId: $orderId}');
  socket.emit("stop_delivery_tracking", {
    "orderId": orderId,
  });
}

void requestRouteUpdate(IO.Socket socket, String orderId) {
  if (socket.disconnected) {
    print('[WebSocket] Error: Socket is not connected. Cannot emit request_route_update.');
    return;
  }
  if (orderId.isEmpty) {
    print('[WebSocket] Error: orderId is empty for request_route_update.');
    return;
  }
  print('[WebSocket] Emitting request_route_update: {orderId: $orderId}');
  socket.emit("request_route_update", {
    "orderId": orderId,
  });
}

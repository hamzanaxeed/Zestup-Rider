import 'dart:convert';

/// ------------------- BASIC COORDINATES -------------------
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// ------------------- ROUTE WAYPOINT -------------------
class RouteWaypoint {
  final double latitude;
  final double longitude;
  final String instruction;
  final double distance; // meters
  final double duration; // seconds

  RouteWaypoint({
    required this.latitude,
    required this.longitude,
    required this.instruction,
    required this.distance,
    required this.duration,
  });

  factory RouteWaypoint.fromJson(Map<String, dynamic> json) {
    return RouteWaypoint(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      instruction: json['instruction'] ?? '',
      distance: json['distance']?.toDouble() ?? 0.0,
      duration: json['duration']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'instruction': instruction,
    'distance': distance,
    'duration': duration,
  };
}

/// ------------------- ROUTE DATA -------------------
class RouteData {
  final List<RouteWaypoint> waypoints;
  final double totalDistance;
  final double totalDuration;
  final String polyline;
  final List<Coordinates> decodedCoordinates;

  RouteData({
    required this.waypoints,
    required this.totalDistance,
    required this.totalDuration,
    required this.polyline,
    required this.decodedCoordinates,
  });

  factory RouteData.fromJson(Map<String, dynamic> json) {
    return RouteData(
      waypoints: (json['waypoints'] as List<dynamic>? ?? [])
          .map((wp) => RouteWaypoint.fromJson(wp))
          .toList(),
      totalDistance: json['totalDistance']?.toDouble() ?? 0.0,
      totalDuration: json['totalDuration']?.toDouble() ?? 0.0,
      polyline: json['polyline'] ?? '',
      decodedCoordinates:
      (json['decodedCoordinates'] as List<dynamic>? ?? [])
          .map((c) => Coordinates.fromJson(c))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'waypoints': waypoints.map((wp) => wp.toJson()).toList(),
    'totalDistance': totalDistance,
    'totalDuration': totalDuration,
    'polyline': polyline,
    'decodedCoordinates':
    decodedCoordinates.map((c) => c.toJson()).toList(),
  };
}

/// ------------------- ROUTE TRACKING DATA -------------------
class RouteTrackingData {
  final String orderId;
  final String riderId;
  final RouteData route;
  final Coordinates currentLocation;
  final DateTime timestamp;
  final bool isRouteUpdated;

  RouteTrackingData({
    required this.orderId,
    required this.riderId,
    required this.route,
    required this.currentLocation,
    required this.timestamp,
    required this.isRouteUpdated,
  });

  factory RouteTrackingData.fromJson(Map<String, dynamic> json) {
    return RouteTrackingData(
      orderId: json['orderId'] ?? '',
      riderId: json['riderId'] ?? '',
      route: RouteData.fromJson(json['route'] ?? {}),
      currentLocation:
      Coordinates.fromJson(json['currentLocation'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ??
          DateTime.now(),
      isRouteUpdated: json['isRouteUpdated'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'riderId': riderId,
    'route': route.toJson(),
    'currentLocation': currentLocation.toJson(),
    'timestamp': timestamp.toIso8601String(),
    'isRouteUpdated': isRouteUpdated,
  };
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/order_Controller.dart';
import 'views/Authentication/login_Screen.dart';
import 'views/home_Screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Notifications.dart'; // <-- Add this import
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:io';

// Handle background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message: ${message.notification?.title}");
}

// Remove requestPermission() here, handled by Notifications class

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService(); // <-- Add this line

  // Fetch Firebase config from backend
  const String configUrl = "https://zestupbackend-59oze.sevalla.app/api/application-info/rider/firebase-config";
  final configResp = await http.get(Uri.parse(configUrl));
  if (configResp.statusCode == 200) {
    final configJson = jsonDecode(configResp.body);
    print('[Firebase Config] $configJson');
    final data = configJson['data'];
    print('[Firebase Config Data] $data');
    final client = data['client'][0];
    print('[Firebase Client] $client');
    final apiKey = client['api_key'][0]['current_key'];
    print('[Firebase) API Key] $apiKey');
    final appId = client['client_info']['mobilesdk_app_id'];
    print('[Firebase App ID] $appId');
    final projectId = data['project_info']['project_id'];
    print('[Firebase Project ID] $projectId');
    final messagingSenderId = data['project_info']['project_number'];
    print('[Firebase Messaging Sender ID] $messagingSenderId');
    final storageBucket = data['project_info']['storage_bucket'];
    print('[Firebase Storage Bucket] $storageBucket');

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
      ),
    );
  } else {
    // Handle error or fallback to default config if needed
    throw Exception('Failed to load Firebase config');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notifications setup
  await Notifications.initialize();

  runApp(const MyApp());
}

// Add this function for background service initialization
Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// iOS background handler (must be top-level)
@pragma('vm:entry-point')
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Rider Tracking",
      content: "Your location is being shared...",
    );
  }

  // Example: Keep WebSocket connection alive (replace with your logic)
  // You may want to use socket_io_client or dart:io WebSocket here
  WebSocket.connect('wss://zestupbackend-59oze.sevalla.app').then((socket) {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      socket.add("ping from background");
    });
  }).catchError((e) {
    print('[BackgroundService] WebSocket error: $e');
  });

  // Track location and send updates
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      print("[BackgroundService] Current Location: ${position.latitude}, ${position.longitude}");
      // TODO: Send to your server via WebSocket or API
    } catch (e) {
      print("[BackgroundService] Location error: $e");
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken != null && accessToken.isNotEmpty) {
      return const HomeScreen();
    } else {
      return const LoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OrderController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorObservers: [routeObserver], // Add the global RouteObserver here
        home: FutureBuilder<Widget>(
          future: _getInitialScreen(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasData) {
              return snapshot.data!;
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

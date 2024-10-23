// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trackmyrun/pages/home_page.dart';
import 'package:trackmyrun/services/gps_pusher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background service
  await initializeService();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackMyRun',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Tracking'),
    );
  }
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'TrackMyRun',
      initialNotificationContent: 'Tracking location in the background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Access shared preferences
  final prefs = await SharedPreferences.getInstance();
  String name = prefs.getString('name') ?? 'unknown';
  String number = prefs.getString('number') ?? 'unknown';

  // Create an instance of GpsPusher
  GpsPusher gpsPusher = GpsPusher(name: name, number: number);

  // Start pushing GPS data
  await gpsPusher.start();

  // Listen for stopService event
  service.on('stopService').listen((event) {
    // Stop the GPS pusher when service is stopped
    gpsPusher.stop();
    service.stopSelf();
  });

  // Optional: Listen for data updates to notify the UI
  // You can use service.invoke() to send data back to the UI
}

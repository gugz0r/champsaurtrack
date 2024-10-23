// lib/services/background_task.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart'; // Import your existing LocationService

void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Access shared preferences
  final prefs = await SharedPreferences.getInstance();
  String name = prefs.getString('name') ?? 'unknown';
  String number = prefs.getString('number') ?? 'unknown';

  // Initialize a variable to hold the timer
  Timer? timer;

  // Listen for stopService event
  service.on('stopService').listen((event) {
    // Stop the timer when service is stopped
    timer?.cancel();
    service.stopSelf();
  });

  // Check if location services are enabled
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Cannot proceed without location services
    // Optionally, you can notify the user or handle this case
    return;
  }

  // Check and request permissions
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      // Permissions are not granted
      // Handle accordingly
      return;
    }
  }

  // Start a timer that runs every 5 seconds
  timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
    try {
      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      // Push location to server
      await LocationService.pushLocationToServer(
          name, number, position.latitude, position.longitude);

      // Update the service data to notify the UI
      service.invoke(
        "update",
        {
          "latitude": position.latitude,
          "longitude": position.longitude,
          "timestamp": DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Handle exceptions, e.g., log or retry logic
      print('Error in background service: $e');
    }
  });
}

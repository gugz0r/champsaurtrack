// lib/services/gps_pusher.dart

import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For formatting date and time
import 'log_service.dart'; // Import LogService

class GpsPusher {
  Timer? _timer;
  final String name;
  final String number;
  final Duration interval;
  bool _isRunning = false;

  GpsPusher({
    required this.name,
    required this.number,
    this.interval = const Duration(seconds: 5),
  });

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      _isRunning = false;
      return;
    }

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        print('Location permissions are not granted.');
        _isRunning = false;
        return;
      }
    }

    _timer = Timer.periodic(interval, (Timer timer) async {
      try {
        // Get the current position
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        // Prepare data
        Map<String, dynamic> data = {
          'name': name,
          'number': number,
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Convert to JSON
        String jsonData = jsonEncode(data);

        // Send HTTPS POST request
        final response = await http.post(
          Uri.parse('https://track.dialup.fr/api.php'), // Changed to HTTPS
          headers: {"Content-Type": "application/json"},
          body: jsonData,
        );

        if (response.statusCode == 200) {
          print('Location pushed successfully: $jsonData');

          // Save the timestamp of the successful push
          await LogService.saveLastPushTime(DateTime.now());

          // Add log entry
          String logMessage =
              '[${DateFormat('y-MM-dd HH:mm:ss').format(DateTime.now())}] '
              'Push successful: $jsonData';
          await LogService.addLog(logMessage);
        } else {
          print('Failed to push location: ${response.statusCode}');

          // Add log entry for failure
          String logMessage =
              '[${DateFormat('y-MM-dd HH:mm:ss').format(DateTime.now())}] '
              'Push failed with status code: ${response.statusCode}';
          await LogService.addLog(logMessage);
        }
      } catch (e) {
        print('Error in GPS pusher: $e');

        // Log the exception
        String logMessage =
            '[${DateFormat('y-MM-dd HH:mm:ss').format(DateTime.now())}] '
            'Error: $e';
        await LogService.addLog(logMessage);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }
}

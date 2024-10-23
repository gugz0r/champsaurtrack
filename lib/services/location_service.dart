import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String _serverUrl = 'http://track.dialup.fr/api.php';

  // Method to push GPS data to the server
  static Future<bool> pushLocationToServer(
      String name, String number, double latitude, double longitude) async {
    try {
      Map<String, dynamic> data = {
        'name': name,
        'number': number,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      String jsonData = jsonEncode(data);

      // Push the data to the server
      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonData,
      );

      if (response.statusCode == 200) {
        print('Location pushed successfully: $jsonData');
        return true;
      } else {
        print('Failed to push location: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error pushing location: $e');
      return false;
    }
  }
}

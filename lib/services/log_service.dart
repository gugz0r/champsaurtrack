import 'package:shared_preferences/shared_preferences.dart';

class LogService {
  static const String _logKey = 'logMessages';
  static const String _lastPushTimeKey = 'lastPushTime';

  // Function to add a log message
  static Future<void> addLog(String message) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> logs = prefs.getStringList(_logKey) ?? [];

    // Add the new message at the beginning
    logs.insert(0, message);

    // Limit the log list to the last 50 messages
    if (logs.length > 50) {
      logs = logs.sublist(0, 50);
    }

    await prefs.setStringList(_logKey, logs);
  }

  // Function to retrieve all log messages
  static Future<List<String>> getLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_logKey) ?? [];
  }

  // Function to clear logs
  static Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logKey);
  }

  // Function to save the last push timestamp
  static Future<void> saveLastPushTime(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPushTimeKey, timestamp.toIso8601String());
  }

  // Function to retrieve the last push timestamp
  static Future<DateTime?> getLastPushTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestampStr = prefs.getString(_lastPushTimeKey);
    if (timestampStr != null) {
      return DateTime.parse(timestampStr);
    }
    return null;
  }
}

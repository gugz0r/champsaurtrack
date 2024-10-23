import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _nameKey = 'name';
  static const String _numberKey = 'number';

  // Save config to SharedPreferences
  static Future<void> saveConfig(String name, String number) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_numberKey, number);
  }

  // Load config from SharedPreferences
  static Future<Map<String, String>> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString(_nameKey);
    String? number = prefs.getString(_numberKey);
    return {
      'name': name ?? '',
      'number': number ?? '',
    };
  }

  // Reset config in SharedPreferences
  static Future<void> resetConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_numberKey);
  }
}

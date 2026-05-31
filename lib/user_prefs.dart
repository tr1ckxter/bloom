import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  static const _keyName = 'userName';
  static const _keyIsFirstTime = 'isFirstTime';

  // Save the user's name
  static Future<void> saveUser(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setBool(_keyIsFirstTime, false); // Mark that they have visited
  }

  // Get the user's name
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyName);
  }

  // Check if it's the first time
  static Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    // If the key doesn't exist, it returns null, so we default to true
    return prefs.getBool(_keyIsFirstTime) ?? true;
  }

  static Future<void> setCheckTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  static Future<bool> getCheckTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isDarkMode') ?? false; // Default to Light (false)
  }
}
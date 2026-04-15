import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> setFirstLaunch(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_launch', value);
  }
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_launch') ?? true;
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> clearToken() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
}

static Future<void> saveUserId(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_id', userId);
}

static Future<String?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_id');
}

static Future<void> saveRole(String role) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('role', role);
}

static Future<String?> getRole() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('role');
}

static Future<void> clearAll() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
  await prefs.remove('role');
  await prefs.remove('user_id');
}

static Future<void> saveFcmToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('fcm_token', token);
}

static Future<String?> getFcmToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('fcm_token');
}
}


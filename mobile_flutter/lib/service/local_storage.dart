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

static Future<bool> isProfilComplete() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id') ?? '';
  if (userId.isEmpty) return false;
  return prefs.getBool('profil_complete_$userId') ?? false;
}

static Future<void> setProfilComplete(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id') ?? '';
  if (userId.isEmpty) return;
  await prefs.setBool('profil_complete_$userId', value);
}

static Future<void> saveInfosSupplementaires(Map<String, dynamic> infos) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id') ?? '';
  if (userId.isEmpty) return;
  await prefs.setString('filiere_$userId', infos['filiere'] ?? '');
  await prefs.setString('ville_$userId', infos['ville'] ?? '');
  await prefs.setString('religion_$userId', infos['religion'] ?? '');
  await prefs.setString('telephone_coloc_$userId', infos['telephone'] ?? '');
  await prefs.setString('description_coloc_$userId', infos['description'] ?? '');
  await prefs.setBool('fumeur_$userId', infos['fumeur'] ?? false);
  await prefs.setBool('brutal_$userId', infos['brutal'] ?? false);
}

static Future<Map<String, dynamic>> getInfosSupplementaires() async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id') ?? '';
  if (userId.isEmpty) {
    return {
      'filiere': '',
      'ville': '',
      'religion': '',
      'telephone': '',
      'description': '',
      'fumeur': false,
      'brutal': false,
    };
  }
  return {
    'filiere': prefs.getString('filiere_$userId') ?? '',
    'ville': prefs.getString('ville_$userId') ?? '',
    'religion': prefs.getString('religion_$userId') ?? '',
    'telephone': prefs.getString('telephone_coloc_$userId') ?? '',
    'description': prefs.getString('description_coloc_$userId') ?? '',
    'fumeur': prefs.getBool('fumeur_$userId') ?? false,
    'brutal': prefs.getBool('brutal_$userId') ?? false,
  };
}

}


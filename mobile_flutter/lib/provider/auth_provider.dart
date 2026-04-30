import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/service/auth/api.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/service/session_service.dart';
enum GoogleLoginResult { locataire, proprietaire, choixRole, error }

class UtilisateurProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  Utilisateur? _user;
  String? _token;
  String? _error;
  String? _role;

  String? get token => _token;
  Utilisateur? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get role => _role;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> init() async {
    _token = await LocalStorage.getToken();
    print("Token récupéré au lancement : $_token");
    notifyListeners();
  }
  Future<void> setRole(String newRole) async{
      _role =  newRole;
  notifyListeners();
}
  Future<bool> inscription(Utilisateur user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.inscription(user);
      if (response.statusCode == 201) {
        _token = response.data['token'] ?? response.data['access'];
        _user = Utilisateur.fromJson(response.data['user'] ?? response.data);
        return true;
      }
      throw Exception('Inscription échouée');
    } on Exception catch (e) {
      _error = e.toString();
      debugPrint('Registration error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiService.login(email, password);
      if (response.statusCode == 200) {
        _token = response.data['token'] ?? response.data['access'];
        await LocalStorage.saveToken(_token!);
        await LocalStorage.saveUserId(response.data['user']?['id']?.toString() ?? '');
        _user = Utilisateur.fromJson(response.data['user'] ?? response.data);
        _role =  response.data['user']?['role'] ?? "";
        _apiService.setToken(_token!);
        // Après login réussi
        final fcmToken = await LocalStorage.getFcmToken();
        if (fcmToken != null) {
          await ApiService().envoyerTokenFCM(fcmToken);
        }
                notifyListeners();
        return true;
      }
      throw Exception('Connexion échouée');
    } on Exception catch (e) {
      _error = e.toString();
      debugPrint('Login error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() async {
    _user = null;
    _token = null;
    _error = null;
    SessionService.stop();
    await LocalStorage.saveToken('');
    await LocalStorage.setFirstLaunch(false);
    _apiService.clearToken();
    notifyListeners();
  }

  // Résultat de loginWithGoogle

Future<GoogleLoginResult> loginAvecGoogle() async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    final data = await _apiService.loginWithGoogle();

    _token = data['access'] ?? data['token'] ?? '';
    if (_token != null && _token!.isNotEmpty) {
      _apiService.setToken(_token!);
      await LocalStorage.saveToken(_token!);
    }

    _user = Utilisateur.fromJson(data['user'] ?? data);
    _role = data['user']?['role'] ?? 'non_defini';

    await LocalStorage.saveUserId(
        data['user']?['id']?.toString() ?? '');
    await LocalStorage.saveRole(_role ?? '');

    // Envoie token FCM
    final fcmToken = await LocalStorage.getFcmToken();
    if (fcmToken != null && _token != null && _token!.isNotEmpty) {
      try {
        await ApiService().envoyerTokenFCM(fcmToken);
      } catch (_) {}
    }

    notifyListeners();

    if (_role == 'proprietaire') return GoogleLoginResult.proprietaire;
    if (_role == 'locataire') return GoogleLoginResult.locataire;
    return GoogleLoginResult.choixRole; // role == 'non_defini'
  } on Exception catch (e) {
    _error = e.toString().replaceAll('Exception: ', '');
    return GoogleLoginResult.error;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<bool> choisirRole(String role) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    await _apiService.mettreAJourRole(role);
    _role = role;
    await LocalStorage.saveRole(role);
    notifyListeners();
    return true;
  } on Exception catch (e) {
    _error = e.toString().replaceAll('Exception: ', '');
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}


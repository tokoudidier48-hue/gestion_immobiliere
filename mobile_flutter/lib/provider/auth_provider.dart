
import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/service/api.dart';

class UtilisateurProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  Utilisateur? _user;
  String? _token;
  String? _error;

  String? get token => _token;
  Utilisateur? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
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
        _user = Utilisateur.fromJson(response.data['user'] ?? response.data);
        _apiService.setToken(_token!);
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

  void logout() {
    _user = null;
    _token = null;
    _error = null;
    _apiService.clearToken();
    notifyListeners();
  }
}


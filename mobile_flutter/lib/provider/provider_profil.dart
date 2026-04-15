import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/service/auth/api.dart';

class ProfilProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  Utilisateur? _profil;
  bool _isLoading = false;
  String? _error;

  Utilisateur? get profil => _profil;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchProfil() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profil = await _api.getProfil();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> modifierProfil({
  required String firstName,
  required String lastName,
  required String telephone,
  File? photo,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    _profil = await _api.modifierProfil(
      firstName: firstName,
      lastName: lastName,
      telephone: telephone,
      photo: photo,
    );
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

}
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
  // ← ajoute
  String? filiere,
  String? ville,
  String? religion,
  String? telephoneColoc,
  String? description,
  bool? fumeur,
  bool? brutal,
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
      filiere: filiere,
      ville: ville,
      religion: religion,
      telephoneColoc: telephoneColoc,
      description: description,
      fumeur: fumeur,
      brutal: brutal,
    );
  } catch (e) {
    _error = e.toString().replaceAll('Exception: ', '');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

}
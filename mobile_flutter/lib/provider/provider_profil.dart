import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/service/auth/api.dart';
import 'package:mobile_flutter/service/local_storage.dart';

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

Future<void> fetchEtSauvegarderInfosSupp() async {
  try {
    final infos = await _api.getInfosSupplementairesBackend();
    // Sauvegarde localement pour accès hors ligne
    await LocalStorage.saveInfosSupplementaires(infos);

    // Met à jour le flag profil complet
    final filiere = infos['filiere'] ?? '';
    final ville = infos['ville'] ?? '';
    final telephone = infos['telephone'] ?? '';
    final description = infos['description'] ?? '';
    if (filiere.isNotEmpty && ville.isNotEmpty &&
        telephone.isNotEmpty && description.isNotEmpty) {
      await LocalStorage.setProfilComplete(true);
    }
    notifyListeners();
  } catch (e) {
    print("==> Erreur fetchEtSauvegarderInfosSupp : $e");
  }
}

}
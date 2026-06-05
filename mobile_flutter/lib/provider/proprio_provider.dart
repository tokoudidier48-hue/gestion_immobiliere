import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/proprietaire/proprietes.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/service/proprietaire/apiProprietaire.dart';

class ProprieteProvider extends ChangeNotifier {
  final ApiProprietaire _api = ApiProprietaire();

  List<Propriete> _proprietes = [];
  bool _isLoading = false;
  String? _error;

  List<Propriete> get proprietes => _proprietes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> creerPropriete(Propriete propriete) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.creerPropriete(propriete);
      // On recharge la liste après création
      await fetchProprietes();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchProprietes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _proprietes = await _api.getProprietes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> modifierPropriete(Propriete propriete) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    await _api.modifierPropriete(propriete);
    final index = _proprietes.indexWhere((p) => p.id == propriete.id);
    if (index != -1) {
      _proprietes[index] = propriete; // ← met à jour la liste locale
    }
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> supprimerPropriete(int proprieteId) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    await _api.supprimerPropriete(proprieteId);
    _proprietes.removeWhere((p) => p.id == proprieteId); // ← retire de la liste
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<void> ajouterUnite(int proprieteId, Unites unite, List<File> images) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    await _api.ajouterUnite(proprieteId, unite, images);
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}




}

class UniteProvider extends ChangeNotifier {
  final ApiProprietaire _api = ApiProprietaire();

  List<Unites> _unites = [];
  bool _isLoading = false;
  String? _error;

  List<Unites> get unites => _unites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUnites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _unites = await _api.getUnitesProprio();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

      Future<void> fetchUnitesByPropriete(int proprieteId) async {
      _isLoading = true;
      _error = null;
      notifyListeners();

      try {
        _unites = await _api.getUnitesByPropriete(proprieteId);
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }

    Future<void> supprimerUnite(int uniteId) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    await _api.supprimerUnite(uniteId);
    _unites.removeWhere((u) => u.id == uniteId); // ← retire de la liste locale
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  Future<void> modifierUnite(Unites unite, List<File> images) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    await _api.modifierUnite(unite, images);
    // Met à jour l'unité dans la liste locale
    final index = _unites.indexWhere((u) => u.id == unite.id);
    if (index != -1) {
      _unites[index] = unite;
    }
  } catch (e) {
    _error = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

}
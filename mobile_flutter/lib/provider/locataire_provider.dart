import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';

class DemandeProvider extends ChangeNotifier {
  final ApiLocataire _api = ApiLocataire();

  List<dynamic> _demandes = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get demandes => _demandes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDemandes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _demandes = await _api.getMesDemandes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> envoyerDemande(int uniteId, {String? message}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.envoyerDemande(uniteId, message: message);
      await fetchDemandes();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> annulerDemande(int demandeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.annulerDemande(demandeId);
      _demandes.removeWhere((d) => d['id'] == demandeId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class PaiementProvider extends ChangeNotifier {
  final ApiLocataire _api = ApiLocataire();

  List<dynamic> _paiements = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get paiements => _paiements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPaiements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _paiements = await _api.getMesPaiements();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> effectuerPaiement(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.effectuerPaiement(data);
      await fetchPaiements();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}

class MessageProvider extends ChangeNotifier {
  final ApiLocataire _api = ApiLocataire();

  List<dynamic> _conversations = [];
  List<dynamic> _messages = [];
  bool _isLoading = false;
  String? _error;
  int _nonLus = 0;

  List<dynamic> get conversations => _conversations;
  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get nonLus => _nonLus;

  Future<void> fetchConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _api.getConversations();
      try {
        _nonLus = await _api.getNonLusCount();
      } catch (_) {
        _nonLus = 0;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int conversationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _messages = await _api.getMessages(conversationId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vide les messages sans déclencher rebuild
  void clearMessages() {
    _messages = [];
  }

  // Récupère ou crée une conversation
  Future<int> getOuCreerConversation(int autreUserId, {int? uniteId}) async {
    return await _api.getOuCreerConversation(autreUserId, uniteId: uniteId);
  }

  // Envoie dans une conversation connue
  Future<void> envoyerMessageDirect(int conversationId, String contenu) async {
  try {
    print("==> Envoi message direct dans conversation $conversationId");
    final response = await _api.envoyerMessage(conversationId, contenu);
    print("==> Réponse backend : ${response.data}");
    // Ajoute la réponse du backend directement — pas de message local
    _messages.add(response.data);
    notifyListeners();
  } catch (e) {
    print("==> Erreur envoyerMessageDirect : $e");
    _error = e.toString();
    notifyListeners();
  }
}

  void ajouterMessageLocal(Map<String, dynamic> message) {
  _messages.add(message);
    notifyListeners();
  }

 // Envoie via destinataire (crée la conversation si besoin)
 Future<void> envoyerMessage(int destinataireId, String contenu) async {
    try {
      print("==> Envoi message à $destinataireId");
      final conversationId = await _api.getOuCreerConversation(destinataireId);
      print("==> ConversationId : $conversationId");
      final response = await _api.envoyerMessage(conversationId, contenu);
      print("==> Message envoyé : ${response.data}");
      _messages.add(response.data);
      notifyListeners();
    } catch (e) {
      print("==> Erreur envoi message : $e");
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> supprimerMessage(int messageId) async {
  try {
    await _api.supprimerMessage(messageId);
    _messages.removeWhere((m) => m['id'] == messageId);
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}

Future<void> modifierMessage(int messageId, String nouveauContenu) async {
  try {
    final response = await _api.modifierMessage(messageId, nouveauContenu);
    final index = _messages.indexWhere((m) => m['id'] == messageId);
    if (index != -1) {
      _messages[index] = response.data;
    }
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}

void clearAll() {
  _conversations = [];
  _messages = [];
  _nonLus = 0;
  _error = null;
}
  
}

class NotificationProvider extends ChangeNotifier {
  final ApiLocataire _api = ApiLocataire();

  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String? _error;
  int _nonLues = 0;

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get nonLues => _nonLues;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _api.getNotifications();
      print("==> Notifications dans provider : ${_notifications.length}");
    } catch (e) {
      _error = e.toString();
      print("==> Erreur fetchNotifications : $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> marquerLue(int notifId) async {
    try {
      await _api.marquerNotificationLue(notifId);
      final index = _notifications.indexWhere((n) => n['id'] == notifId);
      if (index != -1) {
        _notifications[index]['est_lue'] = true;
        if (_nonLues > 0) _nonLues--;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> marquerToutesLues() async {
    try {
      await _api.marquerToutesLues();
      for (var n in _notifications) {
        n['est_lue'] = true;
      }
      _nonLues = 0;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}

class UniteDProvider extends ChangeNotifier {
  final ApiLocataire _api = ApiLocataire();

  List<dynamic> _unites = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get unites => _unites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUnitesDisponibles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _unites = await _api.getUnitesDisponibles();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class ColocataireProvider extends ChangeNotifier {
  final ApiLocataire _api = ApiLocataire();

  List<dynamic> _recherches = [];
  List<dynamic> _candidatures = [];
  List<dynamic> _candidaturesRecues = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get recherches => _recherches;
  List<dynamic> get candidatures => _candidatures;
  List<dynamic> get candidaturesRecues => _candidaturesRecues;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> lancerRecherche({
    required int uniteId,
    required String filiere,
    required String ville,
    String? religion,
    required String telephone,
    required String description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.lancerRechercheColocataire(
        uniteId: uniteId,
        filiere: filiere,
        ville: ville,
        religion: religion,
        telephone: telephone,
        description: description,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> postuler({
    required int rechercheId,
    required String filiere,
    required String ville,
    String? religion,
    required String telephone,
    required String description,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.postulerColocataire(
        rechercheId: rechercheId,
        filiere: filiere,
        ville: ville,
        religion: religion,
        telephone: telephone,
        description: description,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCandidaturesRecues() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _candidaturesRecues = await _api.getCandidaturesRecues();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<dynamic>> getRecherchesByUnite(int uniteId) async {
    try {
      return await _api.getRecherchesByUnite(uniteId);
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getCandidaturesRecherche(int rechercheId) async {
    try {
      return await _api.getCandidaturesRecherche(rechercheId);
    } catch (e) {
      return [];
    }
  }

  Future<bool> accepterCandidature(int candidatureId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.accepterCandidature(candidatureId);
      final index = _candidaturesRecues.indexWhere((c) => c['id'] == candidatureId);
      if (index != -1) _candidaturesRecues[index]['est_acceptee'] = true;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refuserCandidature(int candidatureId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.refuserCandidature(candidatureId);
      _candidaturesRecues.removeWhere((c) => c['id'] == candidatureId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
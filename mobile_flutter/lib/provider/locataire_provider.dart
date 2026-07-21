import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';
import 'package:mobile_flutter/service/websocket_service.dart';

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

  Future<List<dynamic>> fetchDemandesByUnite(int uniteId) async {
  try {
    // Utilise les demandes déjà chargées ou refetch
    if (_demandes.isEmpty) {
      _demandes = await _api.getMesDemandes();
    }
    return _demandes.where((d) {
      return d['unite'] == uniteId ||
          d['unite_details']?['id'] == uniteId;
    }).toList();
  } catch (e) {
    return [];
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

 Future<bool> effectuerPaiement({
  required int uniteId,
  required double montant,
  required String modePaiement,
  required String numeroPaiement,
  String typePaiement = 'loyer',
  int? demandeId,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    await _api.effectuerPaiement(
      uniteId: uniteId,
      montant: montant,
      modePaiement: modePaiement,
      numeroPaiement: numeroPaiement,
      typePaiement: typePaiement,
      demandeId: demandeId,
    );
    await fetchPaiements();
    return true;
  } catch (e) {
    _error = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

Future<bool> demanderPaiementEspece({
  required int uniteId,
  required double montant,
  String typePaiement = 'loyer',
  int? demandeId,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    await _api.demanderPaiementEspece(
      uniteId: uniteId,
      montant: montant,
      typePaiement: typePaiement,
      demandeId: demandeId,
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

Future<Map<String, dynamic>?> initierPaiement({
  required int uniteId,
  required int? demandeId,
  required String typePaiement,
  required String modePaiement,
  required double montant,
  required String numeroPaiement,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();
  try {
    final result = await _api.initierPaiement(
      uniteId: uniteId,
      demandeId: demandeId,
      typePaiement: typePaiement,
      modePaiement: modePaiement,
      montant: montant,
      numeroPaiement: numeroPaiement,
    );
    return result;
  } catch (e) {
    _error = e.toString();
    return null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
  
}

// Remplace toute la classe MessageProvider par :

class MessageProvider extends ChangeNotifier {
  final ApiLocataire _api = ApiLocataire();

  List<dynamic> _conversations = [];
  List<dynamic> _messages = [];
  bool _isLoading = false;
  String? _error;
  int _nonLus = 0;
  int? _conversationOuverte; // ← conversation actuellement ouverte
  StreamSubscription? _wsSubscription;

  List<dynamic> get conversations => _conversations;
  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get nonLus => _nonLus;

  // ── Connexion WebSocket ─────────────────────────────────────────────────
  void connecterWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = webSocketService.stream?.listen((data) {
      _handleWebSocketMessage(data);
    });
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type'];
    print("==> WebSocket message type: $type");

    if (type == 'new_message') {
      final convId = data['conversation_id'] as int?;
      final msgData = data['message'] as Map<String, dynamic>?;

      if (msgData == null) return;

      // Si la conversation est ouverte → ajoute le message directement
      if (_conversationOuverte != null && _conversationOuverte == convId) {
        // Évite les doublons par ID
        final msgId = msgData['id'];
        final exists = _messages.any((m) => m['id'] == msgId);
        if (!exists) {
          _messages.add(msgData);
          notifyListeners();
        }
      }

      // Met à jour le badge non lus si conversation pas ouverte
      if (_conversationOuverte != convId) {
        _nonLus++;
        // Met à jour le dernier message dans la liste des conversations
        final idx = _conversations.indexWhere((c) => c['id'] == convId);
        if (idx != -1) {
          _conversations[idx]['dernier_message'] = {
            'contenu': msgData['contenu'],
            'date': msgData['date_envoi'],
          };
          final nonLusActuel = (_conversations[idx]['non_lus'] ?? 0) as int;
          _conversations[idx]['non_lus'] = nonLusActuel + 1;
        }
        notifyListeners();
      }
    }
  }

  void setConversationOuverte(int? conversationId) {
    _conversationOuverte = conversationId;
  }

  void deconnecterWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
  }

  Future<void> fetchConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _conversations = await _api.getConversations();
      try {
        _nonLus = await _api.getNonLusCount();
      } catch (_) {
        // Calcule localement
        _nonLus = _conversations.fold<int>(
          0, (sum, c) => sum + ((c['non_lus'] ?? 0) as int),
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> supprimerConversation(int conversationId) async {
  try {
    await _api.supprimerConversation(conversationId);
    _conversations.removeWhere((c) => c['id'] == conversationId);
    notifyListeners();
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}

  /*Future<void> fetchMessages(int conversationId) async {
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
*/

Future<void> fetchMessages(int conversationId) async {
  _error = null;
  try {
    _messages.clear();
    final nouveaux = await _api.getMessages(conversationId);
    final idsExistants = _messages
        .where((m) => m['id'] != null)
        .map((m) => m['id'])
        .toSet();
    for (final msg in nouveaux) {
      if (!idsExistants.contains(msg['id'])) {
        _messages.add(msg);
      }
    }
    _messages.sort((a, b) {
      final da = DateTime.tryParse(a['date_envoi'] ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['date_envoi'] ?? '') ?? DateTime(2000);
      return da.compareTo(db);
    });
    notifyListeners();
  } catch (e) {
    // ← Message court et propre, jamais le HTML brut
    _error = "Connexion au serveur interrompue";
    print("==> Erreur fetchMessages (masquée à l'UI) : $e");
    notifyListeners();
  }
}

  void clearMessages() {
  _messages.clear();
  notifyListeners();
}

  Future<int> getOuCreerConversation(int autreUserId, {int? uniteId}) async {
    return await _api.getOuCreerConversation(autreUserId, uniteId: uniteId);
  }

  Future<void> envoyerMessageDirect(int conversationId, String contenu) async {
    try {
      final response = await _api.envoyerMessage(conversationId, contenu);
      // Vérifie doublon avant d'ajouter
      final msgId = response.data['id'];
      final exists = _messages.any((m) => m['id'] == msgId);
      if (!exists) {
        _messages.add(response.data);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void ajouterMessageLocal(Map<String, dynamic> message) {
    _messages.add(message);
    notifyListeners();
  }

  Future<void> envoyerMessage(int destinataireId, String contenu) async {
    try {
      final conversationId = await _api.getOuCreerConversation(destinataireId);
      final response = await _api.envoyerMessage(conversationId, contenu);
      final msgId = response.data['id'];
      final exists = _messages.any((m) => m['id'] == msgId);
      if (!exists) {
        _messages.add(response.data);
        notifyListeners();
      }
    } catch (e) {
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
  int get nonLues => _nonLues; // ← expose le compteur

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _notifications = await _api.getNotifications();
      // ← Calcule le nombre de non lues localement
      _nonLues = _notifications.where((n) => n['est_lue'] != true).length;
      print("==> Notifications : ${_notifications.length}, Non lues : $_nonLues");
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
      // ← Met à jour localement sans refetch
      for (var n in _notifications) {
        n['est_lue'] = true;
      }
      _nonLues = 0;
      notifyListeners();
    } catch (e) {
      print("==> Erreur marquerToutesLues : $e");
      // ← Si l'API échoue, force quand même la mise à jour locale
      for (var n in _notifications) {
        n['est_lue'] = true;
      }
      _nonLues = 0;
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
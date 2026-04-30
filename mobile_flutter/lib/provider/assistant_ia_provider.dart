import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';

class AssistantIAProvider extends ChangeNotifier {
  final ApiLocataire _api = ApiLocataire();

  List<dynamic> _messages = [];
  int? _conversationId;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 🚀 Charger conversation
  Future<void> initConversation() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getMaConversationIA();

      _conversationId = data['id'];
      _messages = data['messages'] ?? [];

      print("==> Conversation ID : $_conversationId");
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // 🚀 Envoyer message
  Future<void> envoyerMessage(String contenu) async {
    if (_conversationId == null) return;

    // Ajout local (UX instantané)
    _messages.add({
      'type_expediteur': 'locataire',
      'contenu': contenu,
    });
    notifyListeners();

    try {
      final response = await _api.envoyerMessageIA(
        conversationId: _conversationId!,
        contenu: contenu,
      );

      final messageIA = response['message_ia'];

      _messages.add(messageIA);
    } catch (e) {
      _messages.add({
        'type_expediteur': 'ia',
        'contenu': 'Erreur, veuillez réessayer.',
      });
    }

    notifyListeners();
  }
}
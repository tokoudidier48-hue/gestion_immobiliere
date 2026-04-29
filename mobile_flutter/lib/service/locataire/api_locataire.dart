import 'package:dio/dio.dart';
import 'package:mobile_flutter/service/local_storage.dart';
const String kBaseUrl = 'http://10.199.70.129:8000';
class ApiLocataire {
  final Dio _dio;

  ApiLocataire() : _dio = Dio(
    BaseOptions(
      //baseUrl: 'http://10.190.5.129:8000',
      baseUrl: 'http://10.199.70.129:8000', // URL de ton API
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          final token = await LocalStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ── DEMANDES ──────────────────────────────────────────────────────────────

  Future<Response> envoyerDemande(int uniteId, {String? message}) async {
    try {
      print("==> Envoi demande pour unité $uniteId");
      final response = await _dio.post(
        '/api/locations/demandes/',
        data: {
          'unite': uniteId,
          if (message != null) 'message': message,
        },
      );
      print("==> Réponse : ${response.data}");
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception(e.response?.data);
      }
      throw Exception('Failed to send request: $e');
    } catch (e) {
      throw Exception('Failed to send request: $e');
    }
  }

  Future<List<dynamic>> getMesDemandes() async {
    try {
      print("==> Récupération des demandes");
      final response = await _dio.get('/api/locations/demandes/');
      print("==> Réponse : ${response.data}");
      print("==> dhdbr : ${response}");
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception(e.response?.data);
      }
      throw Exception('Failed to fetch requests: $e');
    } catch (e) {
      throw Exception('Failed to fetch requests: $e');
    }
  }

  Future<Response> annulerDemande(int demandeId) async {
    try {
      final response = await _dio.post('/api/locations/demandes/$demandeId/annuler/');
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to cancel request: $e');
    } catch (e) {
      throw Exception('Failed to cancel request: $e');
    }
  }

  Future<Response> accepterDemande(int demandeId) async {
    try {
      final response = await _dio.post('/api/locations/demandes/$demandeId/accepter/');
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to accept request: $e');
    } catch (e) {
      throw Exception('Failed to accept request: $e');
    }
  }

  Future<Response> refuserDemande(int demandeId) async {
    try {
      final response = await _dio.post('/api/locations/demandes/$demandeId/refuser/');
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to refuse request: $e');
    } catch (e) {
      throw Exception('Failed to refuse request: $e');
    }
  }

  // ── PAIEMENTS ─────────────────────────────────────────────────────────────

  Future<Response> effectuerPaiement({
  required int uniteId,
  required double montant,
  required String modePaiement,
  required String numeroPaiement,
  String typePaiement = 'loyer',
  int? demandeId, // ← ajoute
}) async {
  try {
    final now = DateTime.now();
    final data = <String, dynamic>{
      'unite': uniteId,
      'type_paiement': typePaiement,
      'mode_paiement': modePaiement,
      'montant': montant.toInt(),
      'numero_paiement': numeroPaiement,
      'periode_debut': '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
      'periode_fin': '${now.year}-${now.month.toString().padLeft(2, '0')}-30',
      if (demandeId != null) 'demande': demandeId, // ← ajoute
    };
    final response = await _dio.post('/api/paiements/paiements/', data: data);
    print("==> Paiement effectué : ${response.data}");
    return response;
  } on DioException catch (e) {
    if (e.response != null) {
      print("==> Erreur paiement : ${e.response?.data}");
      throw Exception(e.response?.data);
    }
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

Future<Response> demanderPaiementEspece({
  required int uniteId,
  required double montant,
  String typePaiement = 'loyer',
  int? demandeId, // ← ajoute 
}) async {
  try {
    final now = DateTime.now();
    final response = await _dio.post(
      '/api/paiements/paiements/',
      data: {
        'unite': uniteId,
        'type_paiement': typePaiement,
        'mode_paiement': 'especes',
        'montant': montant.toInt(),
        'numero_paiement': 'ESPECE',
        'statut': 'en_attente',
        'periode_debut': '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
        'periode_fin': '${now.year}-${now.month.toString().padLeft(2, '0')}-30',
        if (demandeId != null) 'demande': demandeId, // ← ajoute
      },
    );
    print("==> Demande espèce envoyée : ${response.data}");
    return response;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

  Future<List<dynamic>> getMesPaiements() async {
    try {
      print("==> Récupération des paiements");
      final response = await _dio.get('/api/paiements/paiements/');
      print("==> Réponse : ${response.data}");
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to fetch payments: $e');
    } catch (e) {
      throw Exception('Failed to fetch payments: $e');
    }
  }

  Future<List<dynamic>> getHistoriquePaiements() async {
  try {
    final response = await _dio.get('/api/paiements/paiements/');
    print("==> Historique paiements : ${response.data}");
    return response.data as List;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}


  Future<dynamic> getRecu(int recuId) async {
    try {
      final response = await _dio.get('/api/paiements/recus/$recuId/');
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to fetch receipt: $e');
    } catch (e) {
      throw Exception('Failed to fetch receipt: $e');
    }
  }

Future<dynamic> getDetailRecu(int recuId) async {
  try {
    final response = await _dio.get('/api/paiements/recus/$recuId/');
    print("==> Détail reçu $recuId : ${response.data}");
    return response.data;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}


Future<dynamic?> getRecuParPaiement(int paiementId) async {
  try {
    final response = await _dio.get('/api/paiements/recus/');

    final List recus = response.data;

    return recus.firstWhere(
      (r) => r['paiement'] == paiementId,
      orElse: () => null,
    );
  } on DioException catch (e) {
    throw Exception(e.response?.data ?? 'Erreur getRecuParPaiement');
  }
}

Future<String> getRecuPdfUrl(int recuId) async {
  try {
    // 1. Essaie d'abord de télécharger directement
    final response = await _dio.get(
      '/api/paiements/recus/$recuId/telecharger/',
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    // Si c'est du JSON avec une URL
    if (response.headers.value('content-type')?.contains('json') == true) {
      final data = response.data;
      final url = data['url'] ?? data['pdf_url'] ?? data['file'];
      if (url != null) return url.toString();
      throw Exception("PDF pas encore généré côté serveur");
    }

    // Si c'est directement le PDF en bytes → on retourne un flag spécial
    return '__BYTES__:$recuId';
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  }
}
    // Télécharge directement le PDF en bytes via GET /download/
Future<List<int>> telechargerRecuPdf(int recuId) async {
  try {
    final response = await _dio.get(
      '/api/paiements/recus/$recuId/download/',
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    print("==> PDF téléchargé, taille : ${(response.data as List).length} bytes");
    return List<int>.from(response.data);
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

// Récupère l'URL du PDF via POST /telecharger/
Future<String?> getUrlRecuPdf(int recuId) async {
  try {
    final response = await _dio.post('/api/paiements/recus/$recuId/telecharger/');
    print("==> URL PDF reçu : ${response.data}");
    final data = response.data;
    if (data is Map) {
      return data['url']?.toString() ??
             data['pdf_url']?.toString() ??
             data['file']?.toString() ??
             data['link']?.toString();
    }
    return null;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

// Télécharge depuis une URL complète
Future<List<int>> downloadPdfFromUrl(String url) async {
  try {
    final fullUrl = url.startsWith('http') ? url : 'http://10.122.254.129:8000$url';
    print("==> Téléchargement PDF depuis : $fullUrl");
    final response = await _dio.get(
      fullUrl,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final bytes = List<int>.from(response.data);
    print("==> PDF téléchargé : ${bytes.length} bytes");
    return bytes;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

  // ── MESSAGERIE ────────────────────────────────────────────────────────────

  Future<List<dynamic>> getConversations() async {
    try {
      final response = await _dio.get('/api/messagerie/conversations/');
      print("==> Conversations : ${response.data}");
      print("==> Type : ${response.data.runtimeType}");
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  // URL correcte avec query param
  Future<List<dynamic>> getMessages(int conversationId) async {
    try {
      final response = await _dio.get(
        '/api/messagerie/messages/',
        queryParameters: {'conversation': conversationId},
      );
      print("==> Messages conversation $conversationId : ${response.data}");
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<Response> envoyerMessage(int conversationId, String contenu) async {
    try {
      final response = await _dio.post(
        '/api/messagerie/messages/',
        data: {
          'conversation': conversationId,
          'contenu': contenu,
        },
      );
      print("==> Message envoyé : ${response.data}");
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception(e.response?.data);
      }
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<int> getOuCreerConversation(int autreUserId, {int? uniteId}) async {
    try {
      final response = await _dio.post(
        '/api/messagerie/conversations/',
        data: {
          'autre_participant': autreUserId,
          if (uniteId != null) 'unite': uniteId,
        },
      );
      print("==> Conversation créée/récupérée : ${response.data}");
      return response.data['id'];
    } on DioException catch (e) {
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception(e.response?.data);
      }
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<int> getNonLusCount() async {
    try {
      final response = await _dio.get('/api/messagerie/messages/non_lus/count/');
      print("==> Non lus count : ${response.data}");
      return response.data['count'] ?? 0;
    } on DioException catch (e) {
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<Response> supprimerMessage(int messageId) async {
  try {
    final response = await _dio.delete('/api/messagerie/messages/$messageId/');
    print("==> Message supprimé : $messageId");
    return response;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

Future<Response> modifierMessage(int messageId, String nouveauContenu) async {
  try {
    final response = await _dio.patch(
      '/api/messagerie/messages/$messageId/',
      data: {'contenu': nouveauContenu},
    );
    print("==> Message modifié : ${response.data}");
    return response;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

  // ── NOTIFICATIONS ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getNotifications() async {
    try {
      print("==> Récupération des notifications");
      final response = await _dio.get('/api/notifications/notifications/');
      print("==> Réponse : ${response.data}");
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to fetch notifications: $e');
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<Response> marquerNotificationLue(int notifId) async {
    try {
      final response = await _dio.post('/api/notifications/notifications/$notifId/marquer_lue/');
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to mark notification: $e');
    } catch (e) {
      throw Exception('Failed to mark notification: $e');
    }
  }

  Future<Response> marquerToutesLues() async {
    try {
      final response = await _dio.post('/api/notifications/notifications/marquer_tout_lu/');
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to mark all notifications: $e');
    } catch (e) {
      throw Exception('Failed to mark all notifications: $e');
    }
  }

  Future<int> getNotifsNonLues() async {
    try {
      final response = await _dio.get('/api/notifications/notifications/non_lus/');
      print("==> Notifs non lues réponse : ${response.data}");
      final count = response.data['count'];
      return int.tryParse(count.toString()) ?? 0;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed to fetch notif count: $e');
    }
  }

  Future<List<dynamic>> getUnitesDisponibles() async {
    try {
      print("==> Récupération des unités disponibles");
      final response = await _dio.get('/api/unites/unites/disponibles/');
      print("==> Réponse unités : ${response.data}");
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed to fetch units: $e');
    } catch (e) {
      throw Exception('Failed to fetch units: $e');
    }
  }

  // ── COLOCATAIRES ──────────────────────────────────────────────────────────

  Future<Response> lancerRechercheColocataire({
    required int uniteId,
    required String filiere,
    required String ville,
    String? religion,
    required String telephone,
    required String description,
  }) async {
    try {
      print("==> Lancer recherche colocataire");
      final response = await _dio.post(
        '/api/colocataires/recherches/',
        data: {
          'unite': uniteId,
          'filiere': filiere,
          'ville': ville,
          if (religion != null && religion.isNotEmpty) 'religion': religion,
          'telephone': telephone,
          'description': description,
        },
      );
      print("==> Réponse : ${response.data}");
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<List<dynamic>> getCandidaturesRecherche(int rechercheId) async {
    try {
      final response = await _dio.get('/api/colocataires/recherches/$rechercheId/candidatures/');
      print("==> Candidatures pour recherche $rechercheId : ${response.data}");
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<Response> postulerColocataire({
    required int rechercheId,
    required String filiere,
    required String ville,
    String? religion,
    required String telephone,
    required String description,
  }) async {
    try {
      final response = await _dio.post(
        '/api/colocataires/candidatures/',
        data: {
          'recherche': rechercheId,
          'filiere': filiere,
          'ville': ville,
          if (religion != null && religion.isNotEmpty) 'religion': religion,
          'telephone': telephone,
          'description': description,
        },
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<List<dynamic>> getMesCandidatures() async {
    try {
      final response = await _dio.get('/api/colocataires/candidatures/');
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<List<dynamic>> getCandidaturesRecues() async {
    try {
      final response = await _dio.get('/api/colocataires/candidatures/recues/');
      return response.data as List;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<Response> accepterCandidature(int candidatureId) async {
    try {
      final response = await _dio.post('/api/colocataires/candidatures/$candidatureId/accepter/');
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<Response> refuserCandidature(int candidatureId) async {
    try {
      final response = await _dio.post('/api/colocataires/candidatures/$candidatureId/refuser/');
      return response;
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<List<dynamic>> getRecherchesByUnite(int uniteId) async {
    try {
      final response = await _dio.get(
        '/api/colocataires/recherches/',
        queryParameters: {'unite': uniteId},
      );
      final List<dynamic> toutes = response.data as List;
      return toutes.where((r) => r['unite'] == uniteId).toList();
    } on DioException catch (e) {
      if (e.response != null) throw Exception(e.response?.data);
      throw Exception('Failed: $e');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }
}
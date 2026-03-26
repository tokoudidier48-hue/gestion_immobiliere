import 'package:dio/dio.dart';
import 'package:mobile_flutter/model/proprietaire/proprietes.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';

class ApiProprietaire {
  final Dio _dio = Dio(
    BaseOptions(
      //baseUrl: 'http://192.168.100.22:8000', // URL de ton API
      baseUrl: 'http://10.19.84.19/:8000', // URL de ton API
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

//--------------------------- PROPRIETAIRE ------------------------------------//


// Méthode pour créer une propriété
Future<Response> creerPropriete(Propriete propriete) async {
  try {
    print("==> Début de la création de propriété");
    print("Données envoyées : ${propriete.toJson()}");
    final response = await _dio.post(
      '/api/proprietaire/creer_propriete/',
      data: propriete.toJson(),
    );
    return response;
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur création propriété');
    }
    throw Exception('Failed to create property: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to create property: $e');
  }
}

// Méthode pour récupérer les propriétés d'un propriétaire
Future<Response> getProprietes() async {
  try {
    print("==> Début de la récupération des propriétés");
    final response = await _dio.get('/api/proprietaire/mes_proprietes/');
    return response.data.map<Propriete>((json) => Propriete.fromJson(json)).toList();
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur récupération propriétés');
    }
    throw Exception('Failed to fetch properties: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to fetch properties: $e');
  }
}

// Méthode pour supprimer une propriété
Future<Response> supprimerPropriete(int proprieteId) async {
  try {
    print("==> Début de la suppression de propriété");
    final response = await _dio.delete('/api/proprietaire/supprimer_propriete/$proprieteId/');
    return response;
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur suppression propriété');
    }
    throw Exception('Failed to delete property: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to delete property: $e');
  }
}

// Méthode pour modifier une propriété
Future<Response> modifierPropriete(Propriete propriete) async {
  try {
    print("==> Début de la modification de propriété");
    print("Données envoyées : ${propriete.toJson()}");
    final response = await _dio.put(
      '/api/proprietaire/modifier_propriete/${propriete.id}/',
      data: propriete.toJson(),
    );
    return response;
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur modification propriété');
    }
    throw Exception('Failed to update property: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to update property: $e');
  }
}

//--------------------------- UNITE ------------------------------------//

// Méthode pour ajouter une unité à une propriété
Future<Response> ajouterUnite(int proprieteId, Unites unite) async {
  try {
    print("==> Début de l'ajout d'une unité");
    print("Données envoyées : ${unite.toJson()}");
    final response = await _dio.post(
      '/api/proprietaire/ajouter_unite/$proprieteId/',
      data: unite.toJson(),
    );
    return response;
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur ajout unité');
    }
    throw Exception('Failed to add unit: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to add unit: $e');
  }
}

// Méthode pour récupérer les unités d'une propriété
Future<Response> getUnites(int proprieteId) async {
  try {
    print("==> Début de la récupération des unités");
    final response = await _dio.get('/api/proprietaire/mes_unites/$proprieteId/');
    return response.data.map<Unites>((json) => Unites.fromJson(json)).toList();
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur récupération unités');
    }
    throw Exception('Failed to fetch units: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to fetch units: $e');
  }
}

// Méthode pour supprimer une unité
Future<Response> supprimerUnite(int uniteId) async {
  try {
    print("==> Début de la suppression d'une unité");
    final response = await _dio.delete('/api/proprietaire/supprimer_unite/$uniteId/');
    return response;
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur suppression unité');
    }
    throw Exception('Failed to delete unit: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to delete unit: $e');
  }
}

// Méthode pour modifier une unité
Future<Response> modifierUnite(Unites unite) async {
  try {
    print("==> Début de la modification d'une unité");
    print("Données envoyées : ${unite.toJson()}");
    final response = await _dio.put(
      '/api/proprietaire/modifier_unite/${unite.id}/',
      data: unite.toJson(),
    );
    return response;
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur modification unité');
    }
    throw Exception('Failed to update unit: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to update unit: $e');
  }
}

// Méthode pour récupérer les détails d'une unité
Future<Unites> getDetailsUnite(int uniteId) async {
  try {
    print("==> Début de la récupération des détails d'une unité");
    final response = await _dio.get('/api/proprietaire/details_unite/$uniteId/');
    return Unites.fromJson(response.data);
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur récupération détails unité');  
    }
    throw Exception('Failed to fetch unit details: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to fetch unit details: $e');
  }
}

//

}
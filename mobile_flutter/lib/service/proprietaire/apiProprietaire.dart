import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mobile_flutter/model/proprietaire/proprietes.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/service/local_storage.dart';

class ApiProprietaire {
  final Dio _dio;

  ApiProprietaire() : _dio = Dio(
    BaseOptions(
      //baseUrl: 'http://192.168.100.22:8000',
      baseUrl: 'http://10.187.67.129:8000', // URL de ton API
      //baseUrl: 'http://10.92.225.129:8000', // URL de ton API
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (
          RequestOptions options,
          RequestInterceptorHandler handler,
        ) async {
          print("==> Intercepteur déclenché !");
          final token = await LocalStorage.getToken();
          print("==> Token récupéré : $token");

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
      ),
    );
  }
  

//--------------------------- PROPRIETAIRE ------------------------------------//


// Méthode pour créer une propriété
Future<Response> creerPropriete(Propriete propriete) async {
  try {
    print("==> Début de la création de propriété");
    print("Données envoyées : ${propriete.toJson()}");
    final response = await _dio.post(
      '/api/proprietes/proprietes/',
      data: propriete.toJson(),
    );
    return response;
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['detail']);
    }
    throw Exception('Failed to create property: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to create property: $e');
  }
}

// Méthode pour récupérer les propriétés d'un propriétaire
Future<List<Propriete>> getProprietes() async {
  try {
    print("==> Début de la récupération des propriétés");
    final response = await _dio.get('/api/proprietes/proprietes/');
    print("==> Réponse getProprietes : ${response.data}");
    return (response.data as List).map<Propriete>((json) => Propriete.fromJson(json)).toList(); // ✅
  } on DioException catch (e) {
    print(e.response?.data['detail']);
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
    final response = await _dio.delete('/api/proprietes/proprietes/$proprieteId/'); // ← nouvelle URL
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
    final response = await _dio.put(
      '/api/proprietes/proprietes/${propriete.id}/', // ← URL corrigée
      data: propriete.toJson(),
    );
    return response;
  } on DioException catch (e) {
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data);
    }
    throw Exception('Failed to update property: $e');
  } catch (e) {
    throw Exception('Failed to update property: $e');
  }
}

//--------------------------- UNITE ------------------------------------//

// Méthode pour ajouter une unité à une propriété
    Future<Response> ajouterUnite(int proprieteId, Unites unite, List<File> images) async {
      try {
        print("==> Début de l'ajout d'une unité");

        // Tout dans un seul FormData
        final Map<String, dynamic> data = {
          ...unite.toJson(),
          'propriete': proprieteId,
        };

        final formData = FormData.fromMap(data);

        // Ajoute les images si présentes
        if (images.isNotEmpty) {
          for (int i = 0; i < images.length; i++) {
            formData.files.add(MapEntry(
              'photos',
              await MultipartFile.fromFile(
                images[i].path,
                filename: images[i].path.split('/').last,
              ),
            ));
          }
        }

        final response = await _dio.post(
          '/api/unites/unites/create-with-photos/',
          data: formData,
        );

        print("==> Réponse ajout unité : ${response.data}");
        return response;
      } on DioException catch (e) {
        if (e.response != null) {
          print("Détails réponse : ${e.response?.data}");
          throw Exception(e.response?.data);
        }
        throw Exception('Failed to add unit: $e');
      } catch (e) {
        print("Erreur inconnue : $e");
        throw Exception('Failed to add unit: $e');
      }
    }

// Méthode pour récupérer les unités d'une propriété
  Future<List<Unites>> getUnitesProprio() async {
    try {
      print("==> Récupération de toutes les unités du propriétaire");
      final response = await _dio.get('/api/unites/unites/');
      print("==> Réponse : ${response.data}");
      return (response.data as List).map<Unites>((json) => Unites.fromJson(json)).toList();
    } on DioException catch (e) {
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception(e.response?.data);
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
    final response = await _dio.delete('/api/unites/unites/$uniteId/');
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
Future<Response> modifierUnite(Unites unite, List<File> images) async {
  try {
    print("==> Début de la modification d'une unité");

    final Map<String, dynamic> data = {
      ...unite.toJson(),
      'propriete': unite.proprieteId,
    };

    final formData = FormData.fromMap(data);

    // Ajoute les nouvelles images si présentes
    if (images.isNotEmpty) {
      for (int i = 0; i < images.length; i++) {
        formData.files.add(MapEntry(
          'photos',
          await MultipartFile.fromFile(
            images[i].path,
            filename: images[i].path.split('/').last,
          ),
        ));
      }
    }

    final response = await _dio.put(
      '/api/unites/unites/${unite.id}/',
      data: formData,
    );

    print("==> Réponse modification unité : ${response.data}");
    return response;
  } on DioException catch (e) {
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data);
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

Future<List<Unites>> getUnitesByPropriete(int proprieteId) async {
  try {
    print("==> Récupération des unités de la propriété $proprieteId");
    final response = await _dio.get('/api/unites/unites/?propriete=$proprieteId');
    print("==> Réponse : ${response.data}");
    return (response.data as List).map<Unites>((json) => Unites.fromJson(json)).toList();
  } on DioException catch (e) {
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data);
    }
    throw Exception('Failed to fetch units: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to fetch units: $e');
  }
}

//--------------------------- LOCATAIRE ------------------------------------//

Future<List<Unites>> getLocatairesByUnite(int uniteId) async {
  try {
    print("==> Récupération des locataires de l'unité $uniteId");
    final response = await _dio.get('/api/unites/locataires/?unite=$uniteId');
    print("==> Réponse : ${response.data}");
    return (response.data as List).map<Unites>((json) => Unites.fromJson(json)).toList();
  } on DioException catch (e) {
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data);
    }
    throw Exception('Failed to fetch tenants: $e');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to fetch tenants: $e');
  }
}

Future<List<dynamic>> getLocataires({int? proprieteId}) async {
  try {
    final queryParams = proprieteId != null ? {'propriete': proprieteId} : null;
    final response = await _dio.get(
      '/api/locataires/locataires/',
      queryParameters: queryParams,
    );
    print("==> Locataires : ${response.data}");
    return response.data as List;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

Future<List<dynamic>> getPaiementsEspece({int? proprieteId}) async {
  try {
    final params = <String, dynamic>{
      'mode_paiement': 'especes',
      'statut': 'en_attente',
      if (proprieteId != null) 'propriete': proprieteId,
    };
    final response = await _dio.get(
      '/api/paiements/paiements/',
      queryParameters: params,
    );
    print("==> Paiements espèce en attente : ${response.data}");
    return response.data as List;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

/*Future<List<dynamic>> getPaiementsEnAttente({int? proprieteId}) async {
  try {
    final response = await _dio.get(
      '/api/paiements/en_attente/',
      queryParameters: proprieteId != null
          ? {'propriete': proprieteId}
          : null,
    );

    print("==> Paiements en attente : ${response.data}");
    return response.data as List;
  } on DioException catch (e) {
    print("Erreur paiements: ${e.response?.data}");
    throw Exception('Failed to fetch paiements');
  }
}*/

Future<void> ajouterLocataireManuel({
  required String email,
  required int uniteId,
}) async {
  try {
    final response = await _dio.post(
      '/api/locataires/locataires/',
      data: {
        'email': email,
        'unite': uniteId,
      },
    );
    print("==> Locataire ajouté manuellement : ${response.data}");
  } on DioException catch (e) {
    if (e.response != null) {
      print("==> Erreur ajout locataire : ${e.response?.data}");
      throw Exception(e.response?.data);
    }
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

Future<void> accepterPaiement(int id) async {
  await _dio.post('/api/paiements/paiements/$id/accepter/');
  print("==> Paiement accepté : $id");
}

Future<void> refuserPaiement(int id) async {
  await _dio.post('/api/paiements/paiements/$id/refuser/');
  print("==> Paiement refusé : $id");
}

Future<void> supprimerLocataire(int locataireId) async {
  try {
    await _dio.delete('/api/locataires/locataires/$locataireId/');
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

/*
Future<List<dynamic>> getPaiementsLocataire(int locataireId) async {
  try {
    final response = await _dio.get('/api/paiements/paiements/');
    print("==> Paiements locataire $locataireId : ${response.data}");
    return response.data as List;
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}*/

Future<List<dynamic>> getPaiementsLocataire() async {
  try {
    print("==> Récupération des paiements du locataire connecté");

    final response = await _dio.get('/api/paiements/paiements/');

    print("==> Paiements : ${response.data}");

    return response.data as List;
  } on DioException catch (e) {
    print("==> Erreur paiements : ${e.response?.data}");
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

Future<void> modifierLocataire({
  required int locataireId,
  required Map<String, dynamic> data,
}) async {
  try {
    final response = await _dio.patch(
      '/api/locataires/$locataireId/',
      data: data,
    );
    print("==> Locataire modifié : ${response.data}");
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}

}
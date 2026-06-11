import 'dart:io';

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/service/notification_service.dart';
import 'package:mobile_flutter/Config/app_config.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(
    BaseOptions(
      baseUrl: '${AppConfig.baseUrl}', // URL de ton API
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  ) {
    _dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {

      print("==> Intercepteur déclenché !");

      final token = await LocalStorage.getToken();
      print("==> Token récupéré : $token");

      // routes publiques
      final publicRoutes = [
        '/api/comptes/inscription/',
        '/api/comptes/connexion/',
        '/api/comptes/social-login/',
        '/api/comptes/mot-de-passe-oublie/',
        '/api/comptes/verifier-code/',
        '/api/comptes/nouveau-mot-de-passe/',
      ];

      bool isPublicRoute = publicRoutes.any(
        (route) => options.path.contains(route),
      );

      if (!isPublicRoute && token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    },
  ),
);
  }
  // Interceptor pour ajouter token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

 String _parseInscriptionError(dynamic data) {
  if (data == null) return 'Erreur lors de l\'inscription.';

  // Django retourne les erreurs par champ : {"email": ["already exists"], "telephone": [...]}
  if (data is Map) {
    final messages = <String>[];

    data.forEach((key, value) {
      final fieldErrors = value is List ? value : [value];
      for (final err in fieldErrors) {
        final errStr = err.toString().toLowerCase();

        if (key == 'email') {
          if (errStr.contains('already') || errStr.contains('exist') || errStr.contains('unique')) {
            messages.add('Cet email est déjà utilisé.');
          } else if (errStr.contains('valid') || errStr.contains('invalid')) {
            messages.add('Email invalide.');
          } else {
            messages.add('Email : $err');
          }
        } else if (key == 'telephone' || key == 'phone') {
          if (errStr.contains('already') || errStr.contains('exist') || errStr.contains('unique')) {
            messages.add('Ce numéro de téléphone est déjà utilisé.');
          } else if (errStr.contains('valid') || errStr.contains('invalid')) {
            messages.add('Numéro de téléphone invalide.');
          } else {
            messages.add('Téléphone : $err');
          }
        } else if (key == 'password' || key == 'mot_de_passe') {
          if (errStr.contains('common')) {
            messages.add('Mot de passe trop simple. Choisissez-en un plus sécurisé.');
          } else if (errStr.contains('short') || errStr.contains('least')) {
            messages.add('Mot de passe trop court.');
          } else if (errStr.contains('match')) {
            messages.add('Les mots de passe ne correspondent pas.');
          } else {
            messages.add('Mot de passe : $err');
          }
        } else if (key == 'non_field_errors' || key == 'detail' || key == 'message') {
          messages.add(err.toString());
        } else {
          messages.add(err.toString());
        }
      }
    });

    if (messages.isNotEmpty) return messages.join('\n');
  }

  // Si c'est une string directe
  if (data is String) {
    final d = data.toLowerCase();
    if (d.contains('already') || d.contains('exist')) {
      return 'Un compte existe déjà avec ces informations.';
    }
    return data;
  }

  return 'Erreur lors de l\'inscription.';
}

  // Méthode pour l'inscription
  Future<Response> inscription(Utilisateur user) async {
  print("==> Début de l'inscription");
  print("Données envoyées : ${user.toJson()}");

  try {
    final response = await _dio.post(
      '/api/comptes/inscription/',
      data: user.toJson(),
    );
    print("Réponse reçue : ${response.statusCode}");
    print("Données réponse : ${response.data}");
    return response;
  } on DioException catch (e) {
    print("Erreur DioException : ${e.message}");
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      final data = e.response?.data;
      throw Exception(_parseInscriptionError(data));
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw Exception('La connexion a expiré. Vérifiez votre internet.');
    }
    if (e.type == DioExceptionType.connectionError) {
      throw Exception('Impossible de se connecter. Vérifiez votre connexion internet.');
    }
    throw Exception('Erreur réseau : ${e.message}');
  } catch (e) {
    print("Erreur inconnue : $e");
    rethrow;
  }
}



  // Méthode pour la connexion
  Future<Response> login(String email, String password) async {
    print("==> Début de la connexion");
    print("Email : $email, Password : $password");

    try {
      await LocalStorage.clearToken();
      clearToken();
      final response = await _dio.post(
        '/api/comptes/connexion/',
        data: {'email': email, 'password': password},
      );
      final token = response.data['access']?? "";
      final role = response.data['user']?['role']?? "";
      final userId = response.data['user']?['id']?.toString() ?? '';
      await LocalStorage.saveUserId(userId);
      await LocalStorage.saveToken(token); 
      await LocalStorage.saveRole(role); // ← ajoute ça
      Future.delayed(const Duration(seconds: 1), () async {
        await NotificationService.renvoyerTokenApresLogin();
      });
      print("Token : $token");
      print("Role : $role");
      print("Role : ${response.data}");
      return response;
    } on DioException catch (e) {
      print("Erreur DioException : ${e.message}");
      // ← Gestion claire selon le type d'erreur
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Impossible de joindre le serveur. Vérifiez votre connexion internet.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw Exception('Serveur inaccessible. Vérifiez votre connexion internet.');
      }
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception('${e.response?.data}');
      }
      throw Exception('Erreur réseau. Réessayez.');
    } catch (e) {
      print("Erreur inconnue : $e");
      throw Exception('Une erreur inattendue s\'est produite.');
    }
  }

  // Methode pour la réinitialisation du mot de passe (à implémenter selon ton API)
  Future<Response> resetPassword(String email) async {
    try {
      final response = await _dio.post(
        '/api/comptes/mot-de-passe-oublie/',
        data: {'email': email},
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response?.data;

        if (data is Map) {
          print("Détails réponse : ${e.response?.data}");
          throw Exception(
            data['message'] ?? 'Aucun utilisateur trouvé avec cet email',
          );
        } else {
          print("Détails réponse : ${e.response?.data}");
          throw Exception(data.toString());
        }
      }
      print("Erreur DioException : ${e.message}");
      throw Exception('Failed to reset password: ${e.message}');
    } catch (e) {
      print("Erreur inconnue : $e");
      throw Exception('Failed to reset password: $e');
    }
  }

  // Methode pour comparer le code OTP (à implémenter selon ton API)
  Future<Response> verifyOtp(String email, String code) async {
    try {
      final response = await _dio.post(
        '/api/comptes/verifier-code/',
        data: {'email': email, 'code': code},
      );
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception(e.response?.data['message'] ?? 'Code OTP invalide');
      }
      print("Erreur DioException : ${e.message}");
      throw Exception('Failed to verify OTP: ${e.message}');
    } catch (e) {
      print("Erreur inconnue : $e");
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Methode pour changer le mot de passe (à implémenter selon ton API)
  Future<Response> changePassword(String email, String newPassword) async {
    try {
      final response = await _dio.post(
        '/api/comptes/nouveau-mot-de-passe/',
        data: {'email': email, 'nouveau_password': newPassword},
      );
      print("Données envoyées : Email: $email, Nouveau Password: $newPassword");
      return response;
    } on DioException catch (e) {
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception(
          e.response?.data['message'] ??
              'Erreur lors du changement de mot de passe',
        );
      }
      print("Erreur DioException : ${e.message}");
      throw Exception('Failed to change password: ${e.message}');
    } catch (e) {
      print("Erreur inconnue : $e");
      throw Exception('Failed to change password: $e');
    }
  }

// Méthode pour récupérer le profil de l'utilisateur connecté
  Future<Utilisateur> getProfil() async {
  try {
    print("==> Récupération du profil");
    final response = await _dio.get('/api/comptes/profil/');
    print("==> Réponse profil : ${response.data}");
    return Utilisateur.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data);
    }
    throw Exception('Failed to fetch profile: $e');
  } catch (e) {
    throw Exception('Failed to fetch profile: $e');
  }
}

// Méthode pour mettre à jour le profil de l'utilisateur connecté
Future<Utilisateur> modifierProfil({
  required String firstName,
  required String lastName,
  required String telephone,
  File? photo,
  // ← ajoute ces paramètres
  String? filiere,
  String? ville,
  String? religion,
  String? telephoneColoc,
  String? description,
  bool? fumeur,
  bool? brutal,
}) async {
  try {
    print("==> Modification du profil");

    final formData = FormData.fromMap({
      'first_name': firstName,
      'last_name': lastName,
      'telephone': telephone,
      // ← ajoute les champs colocation
      if (filiere != null && filiere.isNotEmpty) 'filiere': filiere,
      if (ville != null && ville.isNotEmpty) 'ville': ville,
      if (religion != null && religion.isNotEmpty) 'religion': religion,
      if (telephoneColoc != null && telephoneColoc.isNotEmpty) 'telephone_coloc': telephoneColoc,
      if (description != null && description.isNotEmpty) 'description_coloc': description,
      if (fumeur != null) 'fumeur': fumeur,
      if (brutal != null) 'brutal': brutal,
      if (photo != null)
        'photo_profil': await MultipartFile.fromFile(
          photo.path,
          filename: photo.path.split('/').last,
        ),
    });

    final response = await _dio.patch(
      '/api/comptes/profil/',
      data: formData,
    );
    print("==> Réponse modification profil : ${response.data}");
    return Utilisateur.fromJson(response.data);
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed to update profile: $e');
  } catch (e) {
    throw Exception('Failed to update profile: $e');
  }
}

Future<void> envoyerTokenFCM(String token) async {
  try {
    final response = await _dio.post(
      '/api/comptes/fcm-token/',
      data: {'token': token},
    );

    print("==> Token FCM envoyé au backend");
    print("==> Réponse serveur : ${response.data}");
  } on DioException catch (e) {
    print("==> Erreur envoi token FCM : ${e.response?.data}");
    rethrow;
  } catch (e) {
    print("==> Erreur : $e");
    rethrow;
  }
}
  

  Future<Map<String, dynamic>> loginWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: '351694266943-2l1mko2kq83v0i20ablg5qpffuee6195.apps.googleusercontent.com',
    );

    await googleSignIn.signOut();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception("Connexion annulée");

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    if (accessToken == null) throw Exception("Token Google introuvable");

    print("==> Access Token Google : $accessToken");

    final response = await _dio.post(
      '/api/comptes/social-login/',
      data: {'provider': 'google', 
      'access_token': accessToken,
      'id_token': googleAuth.idToken,
      'token': accessToken
      },
      options: Options(
        // ← accepte aussi les réponses non-200 pour les gérer manuellement
        validateStatus: (status) => status != null && status < 500,
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    print("==> Réponse social-login : ${response.data}");

    // Vérifie si c'est une erreur HTML (IntegrityError)
    if (response.data is String && (response.data as String).contains('IntegrityError')) {
      throw Exception(
          "Cet email est déjà utilisé avec un autre compte. Connectez-vous avec votre email et mot de passe.");
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      final msg = response.data is Map
          ? response.data['error'] ?? response.data['message'] ?? 'Erreur inconnue'
          : 'Erreur serveur';
      throw Exception(msg);
    }

    final accessJwt = response.data['access'] ?? response.data['token'] ?? '';
    final userId = response.data['user']?['id']?.toString() ?? '';
    final role = response.data['user']?['role'] ?? 'non_defini';

    if (accessJwt.isNotEmpty) {
      await LocalStorage.saveToken(accessJwt);
      await LocalStorage.saveUserId(userId);
      await LocalStorage.saveRole(role);
    }

    return response.data as Map<String, dynamic>;
  } on DioException catch (e) {
    print("==> Erreur social-login : ${e.response?.data}");
    print("==> Status code : ${e.response?.statusCode}");
    print("==> Headers : ${e.response?.headers}");
    final data = e.response?.data;
    if (data is String && data.contains('IntegrityError')) {
      throw Exception("Cet email est déjà utilisé. Connectez-vous avec email/mot de passe.");
    }
    if (data is Map) throw Exception(data['error'] ?? data['message'] ?? 'Erreur connexion Google');
    throw Exception('Connexion Google échouée');
  } catch (e) {
    print("==> Erreur Google : $e");
    throw Exception(e.toString().replaceAll('Exception: ', ''));
  }
}

Future<void> mettreAJourRole(String role) async {
  try {
    await _dio.patch(
      '/api/comptes/profil/',
      data: {'role': role},
    );
    await LocalStorage.saveRole(role);
    print("==> Rôle mis à jour : $role");
  } on DioException catch (e) {
    if (e.response != null) throw Exception(e.response?.data);
    throw Exception('Failed: $e');
  } catch (e) {
    throw Exception('Failed: $e');
  }
}
  

 /* 
  // Methode pour connecter l'utilisateur avec google (à implémenter selon ton API)
Future<void> loginWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: const ['email'],
    );

    final GoogleSignInAccount? googleUser =
        await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception("Connexion annulée");
    }

    final googleAuth = await googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception("Token Google introuvable");
    }

    final response = await _dio.post(
      '/api/auth/google/',
      data: {
        'id_token': idToken,
      },
    );

    print(response.data);

  } catch (e) {
    print("Erreur Google Sign-In: $e");
    throw Exception("Connexion Google échouée");
  }
}
*/
  
}

import 'dart:io';

import 'package:dio/dio.dart';
//import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/service/notification_service.dart';

class ApiService {
  final Dio _dio;

  ApiService() : _dio = Dio(
    BaseOptions(
      //baseUrl: 'http://192.168.100.22:8000',
      //baseUrl: 'http://10.190.5.129:8000', // URL de ton API
      baseUrl: 'http://10.69.91.129:8000', // URL de ton API
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
  // Interceptor pour ajouter token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
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
        throw Exception(e.response?.data['message'] ?? 'Erreur inscription');
      }
      throw Exception('Failed to register: $e');
    } catch (e) {
      print("Erreur inconnue : $e");
      throw Exception('Failed to register: $e');
    }
  }

  // Méthode pour la connexion
  Future<Response> login(String email, String password) async {
    print("==> Début de la connexion");
    print("Email : $email, Password : $password");

    try {
      await LocalStorage.clearToken();
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
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception('${e.response?.data}');
      }
      throw Exception('Failed to login: $e');
    } catch (e) {
      print("Erreur inconnue : $e");
      throw Exception('Failed to login: $e');
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
}) async {
  try {
    print("==> Modification du profil");

    final formData = FormData.fromMap({
      'first_name': firstName,
      'last_name': lastName,
      'telephone': telephone,
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
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data);
    }
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
  

  /*
  // Methode pour connecter l'utilisateur avec google (à implémenter selon ton API)
/Future<void> loginWithGoogle() async {
  try {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email'],
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

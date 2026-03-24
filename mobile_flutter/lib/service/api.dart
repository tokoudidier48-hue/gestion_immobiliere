
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile_flutter/model/utilisateur.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.100.22:8000', // URL de ton API
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  // Interceptor pour ajouter token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Token $token';
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
      final response = await _dio.post(
        '/api/comptes/connexion/',
        data: {
          'email': email,
          'password': password,
        },
      );
      print("Réponse reçue : ${response.statusCode}");
      print("Données réponse : ${response.data}");
      return response;
    } on DioException catch (e) {
      print("Erreur DioException : ${e.message}");
      if (e.response != null) {
        print("Détails réponse : ${e.response?.data}");
        throw Exception(e.response?.data['message'] ?? 'Erreur connexion');
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
        throw Exception(data['message'] ?? 'Aucun utilisateur trouvé avec cet email');
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
      data: {
        'email': email, 
        'nouveau_password': newPassword
      },
    );
    return response;
  } on DioException catch (e) {
    if (e.response != null) {
      print("Détails réponse : ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? 'Erreur lors du changement de mot de passe');
    }
    print("Erreur DioException : ${e.message}");  
    throw Exception('Failed to change password: ${e.message}');
  } catch (e) {
    print("Erreur inconnue : $e");
    throw Exception('Failed to change password: $e');
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
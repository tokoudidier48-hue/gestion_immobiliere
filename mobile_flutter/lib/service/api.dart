
import 'package:dio/dio.dart';
import 'package:mobile_flutter/model/utilisateur.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://127.0.0.2:8000', // URL de ton API
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
        '/api/users/register/',
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
        '/api/users/login/',
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
}


import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiResetPassword {
  late final Dio _dio;
  final CookieJar _cookieJar = CookieJar();

  static const String baseUrl = 'http://10.92.225.129:8000';

  ApiResetPassword() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    // ← Cookie jar pour garder la session entre les 3 appels
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  // Étape 1 — Demande OTP
  Future<String> demanderOtp(String email) async {
    try {
      final response = await _dio.post(
        '/api/comptes/mot-de-passe-oublie/',
        data: {'email': email},
      );
      print("==> OTP demandé : ${response.data}");
      return response.data['message'] ?? 'Code envoyé';
    } on DioException catch (e) {
      final msg = e.response?.data;
      if (msg is Map) {
        throw Exception(msg['message'] ?? msg['error'] ?? 'Email introuvable');
      }
      throw Exception('Erreur réseau');
    }
  }

  // Étape 2 — Vérifier OTP
  Future<void> verifierOtp(String email, String code) async {
    try {
      await _dio.post(
        '/api/comptes/verifier-code/',
        data: {'email': email, 'code': code},
      );
      print("==> OTP vérifié");
    } on DioException catch (e) {
      final msg = e.response?.data;
      if (msg is Map) {
        throw Exception(msg['error'] ?? msg['message'] ?? 'Code invalide ou expiré');
      }
      throw Exception('Code invalide');
    }
  }

  // Étape 3 — Nouveau mot de passe
  Future<void> nouveauMotDePasse(String password, String confirm) async {
    try {
      await _dio.post(
        '/api/comptes/nouveau-mot-de-passe/',
        data: {
          'nouveau_password': password,
          'nouveau_password2': confirm,
        },
      );
      print("==> Mot de passe changé");
    } on DioException catch (e) {
      final msg = e.response?.data;
      if (msg is Map) {
        throw Exception(
            msg['error'] ?? msg['message'] ?? 'Session expirée. Recommencez.');
      }
      throw Exception('Erreur lors du changement');
    }
  }
}
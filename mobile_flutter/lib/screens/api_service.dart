import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // =========================
  // URL DE BASE API DJANGO
  // =========================
  static const String baseUrl =
      "https://eulah-unconsoling-elliott.ngrok-free.dev/api/utilisateurs/";

  // =========================
  // STORAGE SECURISE
  // =========================
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // =========================
  // REGISTER
  // =========================
  Future<bool> register(
    String email,
    String password,
    String nom,
    String prenom,
    String telephone,
    String role,
  ) async {
    try {
      final uri = Uri.parse("${baseUrl}register/");

      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "nom": nom,
          "prenom": prenom,
          "telephone": telephone,
          "role": role,
        }),
      );

      print("REGISTER STATUS: ${response.statusCode}");
      print("REGISTER BODY: ${response.body}");

      if (response.statusCode == 201) {
        return true;
      }

      return false;
    } catch (e) {
      print("REGISTER ERROR: $e");
      return false;
    }
  }

  // =========================
  // LOGIN
  // =========================
  Future<bool> login(String email, String password) async {
    try {
      final uri = Uri.parse("${baseUrl}login/");

      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email.trim(), "password": password}),
          )
          .timeout(const Duration(seconds: 30));

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // STOCKAGE TOKEN
        await storage.write(key: "access", value: data["access"]);
        await storage.write(key: "refresh", value: data["refresh"]);

        return true;
      }

      return false;
    } catch (e) {
      print("LOGIN ERROR: $e");
      return false;
    }
  }

  // =========================
  // GET TOKEN
  // =========================
  Future<String?> getToken() async {
    return await storage.read(key: "access");
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    await storage.deleteAll();
  }
}

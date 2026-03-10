import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController inputController = TextEditingController();

  bool isLoading = false;

  /// ⚠️ Ton API via ngrok
  final String baseUrl =
      "https://eulah-unconsoling-elliott.ngrok-free.dev/api/utilisateurs";

  /// ===============================
  /// ENVOYER LE CODE OTP
  /// ===============================
  Future<void> sendCode() async {
    String input = inputController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer votre email")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> body = {};

    /// Si c'est un email
    if (input.contains("@")) {
      body["email"] = input;
    } else {
      body["telephone"] = input;
    }

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/forgot-password/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["detail"] ?? "Code OTP envoyé"),
            backgroundColor: Colors.green,
          ),
        );

        /// Aller vers l'écran vérification OTP
        Navigator.pushNamed(context, '/verify-code', arguments: input);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["detail"] ?? "Erreur lors de l'envoi du code"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible de contacter le serveur"),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 28,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'RÉCUPÉRATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// ICON
            Center(
              child: Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFF137FEC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  size: 48,
                  color: Color(0xFF137FEC),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// TITRE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Text(
                    "Mot de passe oublié",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Entrez votre email pour recevoir un code OTP",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            /// INPUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: inputController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                  hintText: "Votre email",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Colors.grey,
                      width: 0.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(
                      color: Color(0xFF137FEC),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// BOUTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: isLoading ? null : sendCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 6,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Envoyer le code",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const Spacer(),

            /// LOGIN LINK
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Vous vous en souvenez ?",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      "Se connecter",
                      style: TextStyle(
                        color: Color(0xFF137FEC),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

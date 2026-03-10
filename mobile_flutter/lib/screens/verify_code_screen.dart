import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  bool isLoading = false;

  /// 🌍 URL API (NGROK)
  final String baseUrl =
      "https://eulah-unconsoling-elliott.ngrok-free.dev/api/utilisateurs";

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }

    for (var node in focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  /// =============================
  /// VERIFIER LE CODE OTP
  /// =============================
  Future<void> verifyCode() async {
    String input = ModalRoute.of(context)?.settings.arguments as String? ?? "";

    String code = otpControllers.map((c) => c.text).join();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer les 6 chiffres du code")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> body = {"code": code};

    if (input.contains("@")) {
      body["email"] = input;
    } else {
      body["telephone"] = input;
    }

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/verify-code/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Code OTP validé"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushNamed(context, '/new-password', arguments: input);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["detail"] ?? "Code invalide"),
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

  /// =============================
  /// GESTION DU FOCUS OTP
  /// =============================
  void moveToNext(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      focusNodes[index + 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF137FEC);

    String input = ModalRoute.of(context)?.settings.arguments as String? ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [
            /// HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 28),
                    ),
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        "Vérification",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      /// ICON
                      Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          Icons.domain_verification,
                          color: Color(0xFF137FEC),
                          size: 48,
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// TITRE
                      const Text(
                        "Code de vérification",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// TEXTE
                      Text(
                        "Veuillez saisir le code envoyé à\n$input",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// OTP INPUT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          6,
                          (index) => SizedBox(
                            width: 48,
                            height: 52,
                            child: TextField(
                              controller: otpControllers[index],
                              focusNode: focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,

                              onChanged: (value) => moveToNext(index, value),

                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),

                              decoration: InputDecoration(
                                counterText: "",
                                filled: true,
                                fillColor: Colors.grey.shade200,

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF137FEC),
                                    width: 2,
                                  ),
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      /// BOUTON
                      ElevatedButton(
                        onPressed: isLoading ? null : verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Vérifier",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  SizedBox(width: 8),

                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

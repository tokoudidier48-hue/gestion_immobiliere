import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool showNewPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  /// 🌍 API URL (NGROK)
  final String baseUrl =
      "https://eulah-unconsoling-elliott.ngrok-free.dev/api/utilisateurs";

  @override
  void dispose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// ============================
  /// RESET PASSWORD
  /// ============================
  Future<void> resetPassword() async {
    String input = ModalRoute.of(context)?.settings.arguments as String? ?? "";

    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Le mot de passe doit contenir au moins 6 caractères"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Les mots de passe ne correspondent pas"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> body = {"password": newPassword};

    if (input.contains("@")) {
      body["email"] = input;
    } else {
      body["telephone"] = input;
    }

    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/reset-password/"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Mot de passe réinitialisé"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["detail"] ?? "Erreur lors de la réinitialisation",
            ),
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
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF137FEC);

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
                    child: const Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: primaryColor,
                    ),
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        "Nouveau Mot de Passe",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),

                child: Column(
                  children: [
                    /// ICON
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        color: primaryColor,
                        size: 32,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// TITLE
                    const Text(
                      "Réinitialisez votre mot de passe",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    /// SUBTITLE
                    Text(
                      "Pour $input, entrez votre nouveau mot de passe.",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    /// PASSWORD FIELD
                    passwordField(
                      label: "Nouveau mot de passe",
                      controller: newPasswordController,
                      showPassword: showNewPassword,
                      onToggle: () {
                        setState(() {
                          showNewPassword = !showNewPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    /// CONFIRM PASSWORD
                    passwordField(
                      label: "Confirmer le mot de passe",
                      controller: confirmPasswordController,
                      showPassword: showConfirmPassword,
                      onToggle: () {
                        setState(() {
                          showConfirmPassword = !showConfirmPassword;
                        });
                      },
                    ),

                    const SizedBox(height: 28),

                    /// BUTTON
                    ElevatedButton(
                      onPressed: isLoading ? null : resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Réinitialiser",
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

                    const SizedBox(height: 14),

                    const Text(
                      "LoyaSmart sécurise vos données immobilières au Bénin.",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ============================
  /// PASSWORD FIELD
  /// ============================
  Widget passwordField({
    required String label,
    required TextEditingController controller,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: !showPassword,

          decoration: InputDecoration(
            hintText: "••••••••",
            filled: true,
            fillColor: Colors.white,

            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: onToggle,
            ),

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

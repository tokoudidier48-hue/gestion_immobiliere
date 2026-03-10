import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  final void Function(String email, String password, String role)? onLogin;

  const LoginScreen({super.key, this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePassword = true;
  bool isLoading = false;

  // 🔹 Déclaration de la variable pour stocker le rôle
  String userRole = "Locataire"; // valeur par défaut

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // ⚠️ IMPORTANT : Mets ici ton URL correcte vers ton API Django
  final String baseUrl =
      "https://eulah-unconsoling-elliott.ngrok-free.dev/api/utilisateurs";

  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() => setState(() {}));
    passwordFocus.addListener(() => setState(() {}));
  }

  Future<void> login() async {
    String input = emailController.text.trim();
    String password = passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    setState(() => isLoading = true);

    Map<String, dynamic> body = {"password": password};
    if (input.contains("@")) {
      body["email"] = input;
    } else {
      body["telephone"] = input;
    }

    try {
      String loginUrl = baseUrl.trim() + "/login/";
      print("Je clique sur LOGIN avec: $input / $password");
      print("Login URL: $loginUrl");

      final response = await http
          .post(
            Uri.parse(loginUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString("access", data["access"]);
        await prefs.setString("refresh", data["refresh"]);

        // 🔹 Récupération du rôle depuis l'API
        userRole = data["role"] ?? "Locataire";

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Connexion réussie")));

        print("Login result: true, role: $userRole");

        // 🔹 Redirection selon le rôle
        if (userRole.toLowerCase() == "proprietaire") {
          Navigator.pushReplacementNamed(context, "/home-proprietaire");
        } else {
          Navigator.pushReplacementNamed(context, "/home-locataire");
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["detail"] ?? "Erreur de connexion")),
        );
        print("Login result: false");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur serveur ou timeout")),
      );
      print("Login exception: $e");
    }

    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Connexion",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.domain_add,
                    size: 55,
                    color: Color(0xFF137FEC),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "LoyaSmart",
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Gérez votre patrimoine avec intelligence",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 40),
                _buildAnimatedField(
                  label: "Votre e-mail",
                  hint: "Votre email",
                  icon: Icons.person_outline,
                  focusNode: emailFocus,
                  controller: emailController,
                ),
                const SizedBox(height: 20),
                _buildAnimatedField(
                  label: "Mot de passe",
                  hint: "••••••••",
                  icon: Icons.lock_outline,
                  focusNode: passwordFocus,
                  controller: passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/forgot-password');
                    },
                    child: const Text(
                      "Mot de passe oublié ?",
                      style: TextStyle(
                        color: Color(0xFF137FEC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Connexion",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Ou continuer avec",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialCircleButton("assets/images/google.png"),
                    const SizedBox(width: 20),
                    _socialCircleButton("assets/images/facebook.png"),
                    const SizedBox(width: 20),
                    _socialCircleButton("assets/images/twitter.png"),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Pas encore de compte ? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        "S'inscrire",
                        style: TextStyle(
                          color: Color(0xFF137FEC),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedField({
    required String label,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    bool isPassword = false,
    TextEditingController? controller,
  }) {
    final bool isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? const Color(0xFF137FEC) : Colors.grey.shade300,
              width: isFocused ? 2 : 1,
            ),
          ),
          child: TextField(
            focusNode: focusNode,
            controller: controller,
            obscureText: isPassword ? obscurePassword : false,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialCircleButton(String imagePath) {
    return Container(
      height: 56,
      width: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: Image.asset(imagePath, height: 26)),
    );
  }
}

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePassword = true;

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    emailFocus.addListener(() => setState(() {}));
    passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    emailFocus.dispose();
    passwordFocus.dispose();
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

                /// 🔙 Header
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

                /// 🏢 Logo
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
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Gérez votre patrimoine avec intelligence",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

                /// 📧 Champ Email / Téléphone
                _buildAnimatedField(
                  label: "E-mail ou Téléphone",
                  hint: "Votre email ou Téléphone",
                  icon: Icons.person_outline,
                  focusNode: emailFocus,
                ),

                const SizedBox(height: 20),

                /// 🔒 Champ Mot de passe
                _buildAnimatedField(
                  label: "Mot de passe",
                  hint: "••••••••",
                  icon: Icons.lock_outline,
                  focusNode: passwordFocus,
                  isPassword: true,
                ),

                const SizedBox(height: 10),

                /// 🔁 Mot de passe oublié
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

                /// 🔥 Bouton Connexion
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () {
                      // TODO: Implement home screen navigation
                      // Navigator.pushReplacementNamed(context, '/home');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Connexion réussie!')),
                      );
                    },
                    child: const Text(
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

                /// 🌐 Logos modernes (CORRIGÉS)
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

                /// 📝 Register
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ✨ Champ avec animation au focus
  Widget _buildAnimatedField({
    required String label,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    bool isPassword = false,
  }) {
    final bool isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),

        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused
                  ? const Color(0xFF137FEC)
                  : Colors.grey.shade300,
              width: isFocused ? 2 : 1,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFF137FEC).withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: TextField(
            focusNode: focusNode,
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

  /// 🌐 Bouton Social Rond Moderne
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
      child: Center(
        child: Image.asset(imagePath, height: 26),
      ),
    );
  }
}
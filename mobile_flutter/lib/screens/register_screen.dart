import 'package:flutter/material.dart';
import '../screens/api_service.dart';

class RegisterScreen extends StatefulWidget {
  final void Function(String email, String password, String role)? onRegister;

  const RegisterScreen({super.key, this.onRegister});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String role = "Locataire";

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  final ApiService api = ApiService();

  final FocusNode nomFocus = FocusNode();
  final FocusNode prenomFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode phoneFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (var node in [
      nomFocus,
      prenomFocus,
      emailFocus,
      phoneFocus,
      passwordFocus,
      confirmPasswordFocus
    ]) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    nomFocus.dispose();
    prenomFocus.dispose();
    emailFocus.dispose();
    phoneFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();

    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // =========================
  // REGISTER FUNCTION
  // =========================
  Future<void> register() async {

    if (nomController.text.isEmpty ||
        prenomController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _showError("Tous les champs sont obligatoires");
      return;
    }

    if (!emailController.text.contains("@")) {
      _showError("Email invalide");
      return;
    }

    if (phoneController.text.length < 8) {
      _showError("Numéro de téléphone invalide");
      return;
    }

    if (passwordController.text.length < 6) {
      _showError("Mot de passe minimum 6 caractères");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showError("Les mots de passe ne correspondent pas");
      return;
    }

    setState(() => isLoading = true);

    bool success = await api.register(
      emailController.text.trim(),
      passwordController.text.trim(),
      nomController.text.trim(),
      prenomController.text.trim(),
      phoneController.text.trim(),
      role,
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Inscription réussie 🎉"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } else {
      _showError("Erreur lors de l'inscription");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Inscription",
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

                const SizedBox(height: 20),

                const Text(
                  "Créer un compte",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Commencez à gérer vos biens intelligemment.",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Je suis un :",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),

                const SizedBox(height: 10),

                Container(
                  height: 52,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _roleButton("Locataire"),
                      _roleButton("Proprietaire"),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: _animatedField(
                        label: "Nom",
                        hint: "Nom",
                        icon: Icons.badge_outlined,
                        focusNode: nomFocus,
                        controller: nomController,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _animatedField(
                        label: "Prénom",
                        hint: "Prénom",
                        icon: Icons.person_outline,
                        focusNode: prenomFocus,
                        controller: prenomController,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _animatedField(
                  label: "Email",
                  hint: "votre@email.com",
                  icon: Icons.email_outlined,
                  focusNode: emailFocus,
                  controller: emailController,
                ),

                const SizedBox(height: 16),

                _animatedField(
                  label: "Téléphone",
                  hint: "97000000",
                  icon: Icons.phone_outlined,
                  focusNode: phoneFocus,
                  controller: phoneController,
                  prefixText: "+229 ",
                ),

                const SizedBox(height: 16),

                _animatedField(
                  label: "Mot de passe",
                  hint: "••••••••",
                  icon: Icons.lock_outline,
                  focusNode: passwordFocus,
                  controller: passwordController,
                  isPassword: true,
                  obscure: obscurePassword,
                  onToggle: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),

                const SizedBox(height: 16),

                _animatedField(
                  label: "Confirmer le mot de passe",
                  hint: "••••••••",
                  icon: Icons.lock_reset,
                  focusNode: confirmPasswordFocus,
                  controller: confirmPasswordController,
                  isPassword: true,
                  obscure: obscureConfirmPassword,
                  onToggle: () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  },
                ),

                const SizedBox(height: 25),

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
                    onPressed: isLoading ? null : register,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "S'inscrire",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                const Center(
                  child: Text(
                    "Ou continuer avec",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    _socialButton("assets/images/google.png"),
                    const SizedBox(width: 12),
                    _socialButton("assets/images/facebook.png"),
                    const SizedBox(width: 12),
                    _socialButton("assets/images/twitter.png"),
                  ],
                ),

                const SizedBox(height: 25),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      "Déjà un compte ? Se connecter",
                      style: TextStyle(
                        color: Color(0xFF137FEC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleButton(String value) {
    final bool selected = role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => role = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? const Color(0xFF137FEC) : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedField({
    required String label,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    TextEditingController? controller,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    String? prefixText,
  }) {
    final bool isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
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
            obscureText: isPassword ? obscure : false,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixText != null
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        prefixText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  : Icon(icon),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: onToggle,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _socialButton(String assetPath) {
    return Expanded(
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 26,
            height: 26,
          ),
        ),
      ),
    );
  }
}
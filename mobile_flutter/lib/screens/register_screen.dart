import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String role = "Locataire";
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

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

                /// 🔙 Header
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        "Inscription",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 20),

                /// 📝 Title
                const Text(
                  "Créer un compte",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  "Gérez vos biens avec des prévisions de paiement par IA.",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                /// 👤 Role selector
                const Text(
                  "Je suis un :",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  height: 50,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _roleButton("Locataire"),
                      _roleButton("Propriétaire"),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// 👤 Nom + Prénom
                Row(
                  children: [
                    Expanded(child: _inputField("Nom", "Ex: Dossou")),
                    const SizedBox(width: 12),
                    Expanded(child: _inputField("Prénom", "Ex: Marc")),
                  ],
                ),

                const SizedBox(height: 16),

                /// 📧 Email
                _inputField("Email", "votre@email.com"),

                const SizedBox(height: 16),

                /// 📞 Téléphone
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Téléphone",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: Container(
                          width: 70,
                          alignment: Alignment.center,
                          child: const Text(
                            "+229",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        hintText: "01 02 03 04",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                /// 🔒 Mot de passe
                _passwordField(
                  label: "Mot de passe",
                  obscure: obscurePassword,
                  onToggle: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),

                const SizedBox(height: 16),

                /// 🔐 Confirmation
                _passwordField(
                  label: "Confirmer le mot de passe",
                  obscure: obscureConfirmPassword,
                  onToggle: () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  },
                ),

                const SizedBox(height: 25),

                /// 🔥 Bouton Inscription
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF137FEC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// 🌐 Social login
                const Center(
                  child: Text(
                    "Ou continuer avec",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    _socialButton(Icons.g_mobiledata),
                    const SizedBox(width: 10),
                    _socialButton(Icons.facebook),
                    const SizedBox(width: 10),
                    _socialButton(Icons.alternate_email),
                  ],
                ),

                const SizedBox(height: 25),

                /// 🔁 Login link
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

  /// 👤 Role Button
  Widget _roleButton(String value) {
    final bool selected = role == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            role = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected
                  ? const Color(0xFF137FEC)
                  : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  /// 🧾 Input Field
  Widget _inputField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  /// 🔒 Password Field
  Widget _passwordField({
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: "••••••••",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  /// 🌐 Social Button
  Widget _socialButton(IconData icon) {
    return Expanded(
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/mot_de_passe_oublier.dart';
import 'package:mobile_flutter/Pages/pages_locataire/accueil_locataire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/accueil_proprietaire.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/Pages/pages_auth/inscription.dart';
import 'package:mobile_flutter/widgets/widget_auth/customField.dart';
import 'package:mobile_flutter/Pages/pages_auth/choix_role_page.dart';
import 'package:mobile_flutter/widgets/session_wrapper.dart';

class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends State<Connexion> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Erreurs inline sous les champs
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Valide les champs et retourne true si tout est ok
  bool _valider() {
    bool valid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;

      if (emailController.text.trim().isEmpty) {
        _emailError = 'Veuillez entrer votre email';
        valid = false;
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(emailController.text.trim())) {
        _emailError = 'Email invalide';
        valid = false;
      }

      if (passwordController.text.isEmpty) {
        _passwordError = 'Veuillez entrer votre mot de passe';
        valid = false;
      } else if (passwordController.text.length < 6) {
        _passwordError = 'Mot de passe trop court';
        valid = false;
      }
    });
    return valid;
  }

  // Nettoie les erreurs en live quand l'utilisateur tape
  void _clearEmailError() {
    if (_emailError != null) setState(() => _emailError = null);
  }

  void _clearPasswordError() {
    if (_passwordError != null) setState(() => _passwordError = null);
  }

  // Parse l'erreur du backend en message lisible
  String _parseError(String rawError) {
    final e = rawError.toLowerCase();
    if (e.contains('socketexception') || e.contains('connection refused') ||
        e.contains('network') || e.contains('errno = 111')) {
      return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
    }
    if (e.contains('timeout') || e.contains('timed out')) {
      return 'La connexion a expiré. Réessayez.';
    }
    if (e.contains('invalid') || e.contains('incorrect') ||
        e.contains('no active account') || e.contains('identifiants')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (e.contains('not found') || e.contains('404')) {
      return 'Aucun compte trouvé avec cet email.';
    }
    if (e.contains('email') && e.contains('verif')) {
      return 'Veuillez vérifier votre email avant de vous connecter.';
    }
    // Enlève les préfixes techniques
    return rawError
        .replaceAll('Exception: ', '')
        .replaceAll('{', '')
        .replaceAll('}', '')
        .replaceAll("detail:", "")
        .trim();
  }

  Future<void> _loginGoogle(BuildContext context) async {
    final auth = context.read<UtilisateurProvider>();
    auth.clearError();
    final result = await auth.loginAvecGoogle();
    if (!context.mounted) return;
    switch (result) {
      case GoogleLoginResult.locataire:
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => const SessionWrapper(child: AccueilLocatairePage())));
        break;
      case GoogleLoginResult.proprietaire:
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => SessionWrapper(child: const HomePageProprietaire())));
        break;
      case GoogleLoginResult.choixRole:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ChoixRolePage()));
        break;
      case GoogleLoginResult.error:
        _showErrorSnack(auth.error ?? 'Erreur connexion Google');
        break;
    }
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Connexion',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const SizedBox(height: 30),

              // Logo
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_view, size: 30, color: Colors.blue),
              ),
              const SizedBox(height: 10),
              const Text('LoyaSmart',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // Email
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('E-mail', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 5),
              customFieldConnexion(
                controller: emailController,
                hint: 'Identifiant de connexion',
                icon: Icons.person,
                keyboardType: 'email',
                errorText: _emailError,
              ),

              const SizedBox(height: 12),

              // Mot de passe
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
              const SizedBox(height: 5),
              customFieldConnexion(
                controller: passwordController,
                hint: '••••••••',
                icon: Icons.lock,
                keyboardType: 'text',
                isPassword: true,
                errorText: _passwordError,
              ),

              // Mot de passe oublié
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
                    child: const Text('Mot de passe oublié ?',
                        style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Bouton connexion
              Consumer<UtilisateurProvider>(
                builder: (context, auth, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              if (!_valider()) return;
                              auth.clearError();
                              final success = await auth.login(
                                emailController.text.trim(),
                                passwordController.text,
                              );
                              if (!context.mounted) return;
                              if (success) {
                                final role = auth.role ?? '';
                                if (role == 'locataire') {
                                  Navigator.pushReplacement(context,
                                      MaterialPageRoute(builder: (_) =>
                                          const SessionWrapper(child: AccueilLocatairePage())));
                                } else if (role == 'proprietaire') {
                                  Navigator.pushReplacement(context,
                                      MaterialPageRoute(builder: (_) =>
                                          SessionWrapper(child: const HomePageProprietaire())));
                                }
                              } else if (auth.error != null) {
                                _showErrorSnack(_parseError(auth.error!));
                              }
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Connexion',
                              style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text('ou continuer avec'),
              const SizedBox(height: 15),

              // Google
              Consumer<UtilisateurProvider>(
                builder: (context, auth, child) {
                  return GestureDetector(
                    onTap: auth.isLoading ? null : () => _loginGoogle(context),
                    child: Container(
                      width: 80, height: 50,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                      ),
                      child: Center(child: Image.asset('assets/images/logo_google.png', width: 24, height: 24)),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Pas encore de compte ? "),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const Inscription())),
                    child: const Text("S'inscrire",
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
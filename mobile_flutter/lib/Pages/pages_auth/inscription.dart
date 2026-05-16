
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/email_verification_screen.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/widgets/widget_auth/customField.dart';
import 'package:mobile_flutter/Pages/pages_auth/choix_role_page.dart';
import 'package:mobile_flutter/Pages/pages_locataire/accueil_locataire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/accueil_proprietaire.dart';
import 'package:mobile_flutter/widgets/session_wrapper.dart';
class Inscription extends StatefulWidget {
  const Inscription({super.key});

  @override
  _InscriptionState createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final _formKey = GlobalKey<FormState>();
  String selectedRole = 'locataire';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phonenumberController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phonenumberController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loginGoogle(BuildContext context) async {
  final auth = context.read<UtilisateurProvider>();
  auth.clearError();

  final result = await auth.loginAvecGoogle();

  if (!context.mounted) return;

  switch (result) {
    case GoogleLoginResult.locataire:
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const SessionWrapper(child: AccueilLocatairePage())));
      break;
    case GoogleLoginResult.proprietaire:
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => SessionWrapper(child: const HomePageProprietaire())));
      break;
    case GoogleLoginResult.choixRole:
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const ChoixRolePage()));
      break;
    case GoogleLoginResult.error:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Erreur connexion Google'), backgroundColor: Colors.red),
      );
      break;
  }
}

// Ajoute dans _InscriptionState

String _parseError(String rawError) {
  final e = rawError.toLowerCase();
  if (e.contains('socketexception') || e.contains('connection refused') ||
      e.contains('errno = 111') || e.contains('network')) {
    return 'Impossible de se connecter. Vérifiez votre connexion internet.';
  }
  if (e.contains('timeout')) return 'La connexion a expiré. Réessayez.';
  if (e.contains('email') && e.contains('exist')) return 'Cet email est déjà utilisé.';
  if (e.contains('email') && e.contains('already')) return 'Un compte existe déjà avec cet email.';
  if (e.contains('password') && e.contains('match')) return 'Les mots de passe ne correspondent pas.';
  if (e.contains('telephone') || e.contains('phone')) return 'Numéro de téléphone invalide ou déjà utilisé.';
  return rawError.replaceAll('Exception: ', '').replaceAll('{', '').replaceAll('}', '').trim();
}

  @override
 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.grey[100],
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      title: const Text(
        "Inscription",
        style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
    ),
      centerTitle: true,
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Consumer<UtilisateurProvider>(
          builder: (context, auth, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                /// TITRE
                const Text(
                  "Créer un compte",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                /// ROLE
                const Text("JE SUIS UN :"),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRole = "locataire";
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedRole == "locataire"
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "Locataire",
                                style: TextStyle(
                                  color: selectedRole == "locataire"
                                      ? Colors.blue
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRole = "proprietaire";
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedRole == "proprietaire"
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                "Propriétaire",
                                style: TextStyle(
                                  color: selectedRole == "proprietaire"
                                      ? Colors.blue
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// NOM + PRENOM
                Row(
                  children: [
                    Expanded(
                      child: // Nom
                        customField(
                          keyboardType: 'text',
                          controller: nameController,
                          icon: Icons.person,
                          hint: 'Prénom',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Prénom requis';
                            if (value.trim().length < 2) return 'Prénom trop court';
                            return null;
                          },
                        ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: // Prénom
                          customField(
                            keyboardType: 'text',
                            controller: lastnameController,
                            icon: Icons.person,
                            hint: 'Nom',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Nom requis';
                              if (value.trim().length < 2) return 'Nom trop court';
                              return null;
                            },
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                customField(
                  controller: emailController,
                  keyboardType: 'email',
                  hint: "votre@gmail.com",
                  icon: Icons.email,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email requis";
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Email invalide";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                customField(
                  keyboardType: 'phone',
                  controller: phonenumberController,
                  hint: " 01 02 03 04",
                  icon: Icons.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Numéro requis";
                    }
                    if (value.length < 10 || value.length > 10 ) {
                      return "Numéro béninois invalide";
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),

                // Mot de passe
                customField(
                  keyboardType: 'password',
                  controller: passwordController,
                  hint: '••••••••',
                  icon: Icons.lock,
                  isPassword: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Mot de passe requis';
                    if (value.length < 8) return 'Au moins 8 caractères requis';
                    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Au moins une majuscule requise';
                    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Au moins un chiffre requis';
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Confirmation
                  customField(
                    keyboardType: 'password',
                    controller: confirmPasswordController,
                    hint: '••••••••',
                    icon: Icons.lock,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Confirmation requise';
                      if (value != passwordController.text) return 'Les mots de passe ne correspondent pas';
                      return null;
                    },
                  ),

                const SizedBox(height: 10),

                /// BOUTON
                auth.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              // Vérifie les mots de passe avant d'appeler l'API
                              if (passwordController.text != confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.error_outline, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Expanded(child: Text('Les mots de passe ne correspondent pas.')),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    margin: const EdgeInsets.all(12),
                                  ),
                                );
                                return;
                              }

                              if (nameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(children: [
                                      Icon(Icons.error_outline, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('Veuillez entrer votre prénom.'),
                                    ]),
                                    backgroundColor: Colors.red.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    margin: const EdgeInsets.all(12),
                                  ),
                                );
                                return;
                              }

                              auth.clearError();
                              final user = Utilisateur(
                                role: selectedRole,
                                name: nameController.text.trim(),
                                lastName: lastnameController.text.trim(),
                                email: emailController.text.trim(),
                                phoneNumber: phonenumberController.text.trim(),
                                password: passwordController.text,
                                confirmPassword: confirmPasswordController.text,
                              );

                              final success = await auth.inscription(user);
                              if (!context.mounted) return;

                              if (success) {
                                Navigator.pushReplacement(context, MaterialPageRoute(
                                    builder: (_) => EmailVerificationScreen(email: emailController.text.trim())));
                              } else if (auth.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_parseError(auth.error!))),
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
                            }
                          },
                          child: const Text("S'inscrire",
                              style: TextStyle(fontSize: 16,color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 5),

                        Center(
                            child: Text(
                              "ou continuer avec",
                              style: TextStyle(fontSize: 10, color: Colors.black54),
                            ),
                          ),

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Consumer<UtilisateurProvider>(
                            builder: (context, auth, child) {
                              return GestureDetector(
                                onTap: auth.isLoading ? null : () => _loginGoogle(context),
                                child: Container(
                                  width: 80, height: 50,
                                  padding: const EdgeInsets.all(5),
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
                        ],
                      ),

                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Vous avez déjà un compte ?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Connexion(),
                              ),
                            );
                          },
                          child: const Text("Se connecter",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                      ),
                        ),
                      ],
                    ),

              ],
            );
          },
        ),
      ),
    ),
  );
}


//Methode pour formater le numéro de téléphone en temps réel
void formatPhone(String value) {
  if (!value.startsWith("+229")) {
    phonenumberController.text = "+229 $value";
    phonenumberController.selection = TextSelection.fromPosition(
      TextPosition(offset: phonenumberController.text.length),
    );
  }
}
//  Widget bouton social
 Widget socialButton(Widget icon, Color color) {
  return Container(
    width: 80,
    height: 50,
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade300),
      color: Colors.white,
    ),
    child: Center(child: icon),
  );
}

}


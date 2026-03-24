
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/Pages/pages_auth/home.dart';
import 'package:mobile_flutter/widgets/customField.dart';
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
                      child: customField(
                        controller: nameController,
                        icon: Icons.person,
                        hint: "Barack",
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: customField(
                        controller: lastnameController,
                        icon: Icons.person,
                        hint: "Obama",
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),
                customField(
                  controller: emailController,
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
                  controller: phonenumberController,
                  hint: " 01 02 03 04",
                  icon: Icons.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Numéro requis";
                    }
                    if (value.length == 10 ) {
                      return "Numéro béninois invalide";
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 15),

                customField(
                  controller: passwordController,
                  hint: "••••••••",
                  icon: Icons.lock,
                  isPassword: true,
                ),

                const SizedBox(height: 15),

                customField(
                  controller: confirmPasswordController,
                  hint: "••••••••",
                  icon: Icons.lock,
                  isPassword: true,
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
                              auth.clearError();
                              final user = Utilisateur(
                                role: selectedRole,
                                name: nameController.text.trim(),
                                lastName:lastnameController.text.trim(),
                                email: emailController.text.trim(),
                                phoneNumber:phonenumberController.text.trim(),
                                password: passwordController.text,
                                confirmPassword:confirmPasswordController.text,
                              );
                              final success = await auth.inscription(user);
                              if (success && context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const Home()),
                                );
                              } else if (auth.error != null &&
                                  context.mounted) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(auth.error!),
                                    backgroundColor: Colors.red,
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
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          socialButton(Image.asset('assets/images/logo_google.png', width: 24, height: 24), Colors.red),
                          socialButton(Icon(Icons.facebook, color: Colors.blue), Colors.blue),
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


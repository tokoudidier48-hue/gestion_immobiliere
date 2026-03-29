import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/mot_de_passe_oublier.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/Pages/pages_auth/inscription.dart';
import 'package:mobile_flutter/Pages/pages_auth/home.dart';
import 'package:mobile_flutter/widgets/widget_auth/customField.dart';
// tekebariba@gmail.com, Password : Sonon48@
class Connexion extends StatefulWidget {
  const Connexion({super.key});

  @override
  State<Connexion> createState() => _ConnexionState();
}

class _ConnexionState extends State<Connexion> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios, 
                  color: Colors.black,
                ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            //automaticallyImplyLeading: true,
            title: const Text(
              "Connexion",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
        ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              //  Retour + Titre
             
              const SizedBox(height: 30),

              // Logo + Nom app
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.grid_view, size: 30, color: Colors.blue),
              ),

              const SizedBox(height: 10),

              const Text(
                "LoyaSmart",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              // Email / Téléphone
              Align(
                alignment: Alignment.centerLeft,
                child: const Text("E-mail"),
              ),
              const SizedBox(height: 5),
             customFieldConnexion(
                controller: emailController,
                hint: "Identifiant de connexion",
                icon: Icons.person,
              ),

              const SizedBox(height: 20),

              //  Mot de passe
              Align(
                alignment: Alignment.centerLeft,
                child: const Text("Mot de passe"),
              ),
              const SizedBox(height: 5),
              customFieldConnexion(
                  controller: passwordController,
                  hint: "••••••••",
                  icon: Icons.lock,
                  isPassword: true,
                 
            ),

              const SizedBox(height: 10),

              // Remember + forgot
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text("Mot de passe oublié ?"),
                  ),
                ],
              ),


              const SizedBox(height: 10),

              // Bouton connexion
              Consumer<UtilisateurProvider>(
                builder: (context, auth, child) {
                  if (auth.isLoading) {
                    return const CircularProgressIndicator();
                  }

                  return SizedBox(
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
                        auth.clearError();

                        final success = await auth.login(
                          emailController.text.trim(),
                          passwordController.text,
                        );
                        if (success) {
                          if (context.mounted) {

                            final role = auth.role?? ""; // récupérer le role depuis le provider

                            if (role == "locataire") {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => Home(role: auth.role?? "")),
                              );

                            } else if (role == "proprietaire") {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => Home(role: auth.role?? "")),
                              );

                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) =>  Home(role: auth.role?? "")),
                              );
                            }
                          }
                        } else if (auth.error != null &&
                            context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(auth.error!),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      child: const Text(
                        "Connexion",
                        style: TextStyle(fontSize: 16,color: Colors.white),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text("ou continuer avec"),

              const SizedBox(height: 15),

              // Social buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  socialButton(Image(image: AssetImage('assets/images/logo_google.png'), width: 20), Colors.blue),
                  socialButton(Icon(Icons.facebook,color:  Colors.blue,), Colors.blue),
                ],
              ),

              const SizedBox(height: 20),

              // Inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Pas encore de compte ? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Inscription(),
                        ),
                      );
                    },
                    child: const Text(
                      "S'inscrire",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  //  Widget bouton social
  Widget socialButton(dynamic iconOrWidget, Color color) {
    return Container(
      width: 80,
      height: 50,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: iconOrWidget is IconData
          ? Icon(iconOrWidget, color: color)
          : iconOrWidget,
    );
  }
}

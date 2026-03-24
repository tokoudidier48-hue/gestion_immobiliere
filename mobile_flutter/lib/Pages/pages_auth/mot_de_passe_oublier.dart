import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:mobile_flutter/Pages/pages_auth/verification.dart';
import 'package:mobile_flutter/service/api.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  bool isLoading = false; // 👉 à déclarer dans ton State
  String? message;
  bool isError = false;

   //Nettoyage des erreurs
  String cleanError(dynamic e) {
  return e.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    emailController.dispose();
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Connexion()),
          ),
        ),
        title: const Text(
          "RÉCUPÉRATION",
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.of(context).viewInsets.bottom + 20,),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// ICON
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              /// TITLE
              const Center(
                child: Text(
                  "Mot de passe oublié",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              /// SUBTITLE
              const Center(
                child: Text(
                  "Entrez votre email pour réinitialiser votre mot de passe",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

              const SizedBox(height: 30),

              /// LABEL
              const Text(
                "Email",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 8),

              /// INPUT
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "loyasmart@example.com",
                  prefixIcon: const Icon(Icons.person_outline, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              if (message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Aucun compte trouvé avec cet email",
                    style: TextStyle(
                      color: isError ? Colors.red : Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

              const SizedBox(height: 25),


              /// BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      elevation: 6,
                      shadowColor: Colors.blue.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (emailController.text.isEmpty) {
                              setState(() {
                                message = "Veuillez entrer votre email";
                                isError = true;
                              });
                              return;
                            }

                            setState(() {
                              isLoading = true;
                              message = null;
                            });

                            try {
                              final response = await ApiService()
                                  .resetPassword(emailController.text.trim());

                              setState(() {
                                message = "Code envoyé avec succès";
                                isError = false;
                              });

                              // 👉 Navigation (optionnel après succès)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VerificationPage(email: emailController.text.trim()),
                                ),
                              );

                            } catch (e) {
                              setState(() {
                               message = cleanError(e);
                                isError = true;
                              });
                            } finally {
                              setState(() => isLoading = false);
                            }
                          },
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Envoyer le code",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                              const SizedBox(height: 40),

              /// FOOTER
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Vous vous en souvenez ? "),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Se connecter",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
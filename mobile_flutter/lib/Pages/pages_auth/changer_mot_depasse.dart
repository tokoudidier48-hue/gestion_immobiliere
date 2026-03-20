import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:mobile_flutter/widgets/changer_mot_passe.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  double strength = 0;

  void checkStrength(String value) {
    double s = 0;

    if (value.length >= 8) s += 0.3;
    if (RegExp(r'[A-Z]').hasMatch(value) &&
        RegExp(r'[a-z]').hasMatch(value)) s += 0.3;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) s += 0.4;

    setState(() {
      strength = s.clamp(0, 1);
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Nouveau Mot de Passe",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 20),
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

               const SizedBox(height: 10),

              /// SUBTITLE
              const Center(
                child: Text(
                  "Réinitialisez votre mot de passe",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),

                const SizedBox(height: 20), 
              /// PASSWORD
              PasswordField(
                controller: passwordController,
                label: "Nouveau mot de passe",
                onChanged: checkStrength,
              ),

              const SizedBox(height: 10),

              PasswordStrengthBar(strength: strength),

              const SizedBox(height: 20),

              /// CONFIRM
              PasswordField(
                controller: confirmController,
                label: "Confirmer le mot de passe",
              ),

              const SizedBox(height: 20),

              /// RULES
              const Text(
                "EXIGENCES DE SÉCURITÉ",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 10),

              PasswordRule(
                text: "Au moins 8 caractères",
                valid: passwordController.text.length >= 8,
              ),

              PasswordRule(
                text: "Caractère spécial",
                valid: RegExp(r'[!@#\$%^&*(),.?":{}|<>]')
                    .hasMatch(passwordController.text),
              ),

              PasswordRule(
                text: "Majuscules/minuscules",
                valid: RegExp(r'[A-Z]').hasMatch(passwordController.text) &&
                    RegExp(r'[a-z]').hasMatch(passwordController.text),
              ),

              const SizedBox(height: 30),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: 
                      ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                  )),
                  onPressed: () {
                    if (passwordController.text != confirmController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Les mots de passe ne correspondent pas"),
                        ),
                      );
                    }else{
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Mot de passe réinitialisé avec succès"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) =>  Connexion(),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    "Réinitialiser",
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
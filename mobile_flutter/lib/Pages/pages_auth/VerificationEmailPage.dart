import 'package:flutter/material.dart';

class VerificationEmailPage extends StatelessWidget {
  const VerificationEmailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vérification"),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "Un lien de vérification a été envoyé à votre adresse email.\n\n"
            "Veuillez vérifier votre boîte mail pour activer votre compte.",
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
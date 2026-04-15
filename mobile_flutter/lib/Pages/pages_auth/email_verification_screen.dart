// lib/Pages/email_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  bool _emailRenvoye = false;

  Future<void> _resendEmail() async {
    setState(() => _isResending = true);

    try {
      // Appel ton API de renvoi d'email ici
      // await AuthService.resendVerificationEmail();

      setState(() => _emailRenvoye = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du renvoi. Réessayez.")),
      );
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Empêcher de revenir en arrière
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mark_email_unread_outlined,
                size: 72,
                color: Colors.blue.shade700,
              ),
            ),

            const SizedBox(height: 32),

            // Titre
            const Text(
              "Vérifiez votre email",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // Message
            Text(
              "Un lien de vérification a été envoyé à",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Cliquez sur le lien dans l'email pour activer votre compte.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),

            const SizedBox(height: 40),

            // Bannière verte si email renvoyé
            if (_emailRenvoye)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text("Email renvoyé avec succès !"),
                    ),
                  ],
                ),
              ),

            // Bouton renvoyer
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isResending ? null : _resendEmail,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Renvoyer l'email"),
              ),
            ),

            const SizedBox(height: 16),

            // Retour à la connexion
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                "Retourner à la connexion",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
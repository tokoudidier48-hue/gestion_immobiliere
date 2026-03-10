import 'package:flutter/material.dart';

class HomeLocataireScreen extends StatelessWidget {
  const HomeLocataireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Center(
          child: Text(
            "Bienvenue Locataire",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
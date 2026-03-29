
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';

class Home extends StatefulWidget {
  final String role;

  const Home({super.key, required this.role});

@override
State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          Consumer<UtilisateurProvider>(
            builder: (context, auth, child) {
              return IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  auth.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Connexion())
                  );
                },
              );
            },
          ),
        ],
      ),
      body:  Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 100, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              'Bienvenue dans Gestion Immobilière ! ${widget.role}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('API intégrée avec Provider', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}


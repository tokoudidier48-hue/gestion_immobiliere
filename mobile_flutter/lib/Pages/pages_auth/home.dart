
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';

class Home extends StatelessWidget {
  const Home({super.key});

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
                },
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home, size: 100, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              'Bienvenue dans Gestion Immobilière !',
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


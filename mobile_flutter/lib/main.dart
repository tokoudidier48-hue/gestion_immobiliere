
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/Pages/pages_auth/home.dart';
import 'package:mobile_flutter/Pages/pages_auth/onboarding_pages.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UtilisateurProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestion Immobilière',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UtilisateurProvider>(
      builder: (context, auth, child) {
        if (auth.user != null) {
          return const Home();
        }
        return  OnboarningPages(); // or Inscription() if preferred
      },
    );
  }
}
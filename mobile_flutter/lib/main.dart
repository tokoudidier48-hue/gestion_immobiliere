
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:mobile_flutter/Pages/pages_locataire/accueil_locataire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Mes_locataires.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/a_propos.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/accueil_proprietaire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/ajouter_locataire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/decision.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/detail_paiement.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/detail_unit%C3%A9_occupee.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/detail_unite_libre.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/evolution_financiere.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/liste_unite.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/mes_biens.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/mes_locataires.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/message.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/modifier_ch_libre.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/modifier_chambre_occupee.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/modifier_profil.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/profil_proprietaire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/proprio_notification.dart';
import 'package:mobile_flutter/widgets/widget_auth/onboarding.dart';
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


class LinkHandler {
  static Future<void> init(BuildContext context) async {
    final appLinks = AppLinks();

    // 1. Si l'app est ouverte par un lien au lancement
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null && initialUri.host == 'login') {
        final verified = initialUri.queryParameters['verified'];
        if (verified == 'true') {
          Navigator.pushNamed(context, '/Connexion');
          print("Vérification réussie (initial)");
        }
      }
    } catch (e) {
      print("Erreur getInitialAppLink: $e");
    }

    // 2. Si l'app est déjà ouverte et reçoit un lien
    appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null && uri.host == 'login') {
        final verified = uri.queryParameters['verified'];
        if (verified == 'true') {
          Navigator.pushNamed(context, '/Connexion');
          print("Vérification réussie (stream)");
        }
      }
    });
  }
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
        routes: {
          '/login': (context) => const Connexion(), // adapte ici
        },
      );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}class _AuthWrapperState extends State<AuthWrapper> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LinkHandler.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UtilisateurProvider>(
      builder: (context, auth, child) {
        if (auth.user != null) {
          return Home(role: auth.role ?? "");
        }
        return AProposPage()  ;
      },
    );
  }
}
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_flutter/Pages/pages_locataire/mes_demandes.dart';
import 'package:mobile_flutter/Pages/pages_locataire/message_locataire.dart';
import 'package:mobile_flutter/Pages/pages_locataire/paiement.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/message.dart';
import 'package:mobile_flutter/provider/assistant_ia_provider.dart';
import 'package:mobile_flutter/widgets/session_wrapper.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart'; 
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:app_links/app_links.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:mobile_flutter/provider/provider_profil.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/service/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/Pages/pages_auth/onboarding_pages.dart';
import 'package:mobile_flutter/Pages/pages_locataire/accueil_locataire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/accueil_proprietaire.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

// ← Définition de l'enum ici
enum StartState { onboarding, locataire, proprietaire, login }

Future<void> main() async {
   // Initialisation des notifications locales 
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UtilisateurProvider()),
        ChangeNotifierProvider(create: (_) => ProprieteProvider()),
        ChangeNotifierProvider(create: (_) => UniteProvider()),
        ChangeNotifierProvider(create: (_) => UniteDProvider()),
        ChangeNotifierProvider(create: (_) => ProfilProvider()),
        ChangeNotifierProvider(create: (_) => DemandeProvider()),
        ChangeNotifierProvider(create: (_) => PaiementProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => ColocataireProvider()),
        ChangeNotifierProvider(create: (_) => AssistantIAProvider()),
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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Gestion Immobilière',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const Connexion(),
        '/messages': (context) => const MessageLocatairePage(),
        '/messages_proprio': (context) => const MessagesPage(),
        '/demandes': (context) => const MesDemandesPage(),
        '/paiements': (context) => const PaiementPage(),
      },  
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _appLinks = AppLinks();
  late Future<StartState> _startState;

  @override
  void initState() {
    super.initState();
    _listenToDeepLinks();
    _startState = _checkStartPage();
  }

  Future<StartState> _checkStartPage() async {
    try {
      final firstLaunch = await LocalStorage.isFirstLaunch();

      if (firstLaunch) {
        await LocalStorage.setFirstLaunch(false);
        return StartState.onboarding;
      }

      final token = await LocalStorage.getToken();
      final role = await LocalStorage.getRole();
      final userId = await LocalStorage.getUserId();

      // ← vérifie que le token existe ET n'est pas vide
      if (token == null || token.isEmpty) return StartState.login;

      print("==> Token : $token");
      print("==> Role : $role");
      print("==> UserId : $userId");

      if (role == 'locataire') return StartState.locataire;
      if (role == 'proprietaire') return StartState.proprietaire;

      return StartState.login;
    } catch (e) {
      print("==> Erreur _checkStartPage : $e");
      return StartState.login;
    }
  }

  void _listenToDeepLinks() {
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });

    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.host == 'email-verified') {
      final success = uri.queryParameters['success'] == 'true';
      navigatorKey.currentState?.pushReplacementNamed(
        '/login',
        arguments: {
          'message': success
              ? 'Email vérifié ! Vous pouvez vous connecter.'
              : 'Lien invalide ou expiré.'
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StartState>(
      future: _startState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Erreur de chargement")),
          );
        } 

        switch (snapshot.data) {
          case StartState.onboarding:
            return OnboarningPages();
          case StartState.locataire:
            return SessionWrapper(child: const AccueilLocatairePage());
          case StartState.proprietaire:
            return SessionWrapper(child: const HomePageProprietaire());
          case StartState.login:
          default:
            return const Connexion();
        }
      },
    );
  }
}
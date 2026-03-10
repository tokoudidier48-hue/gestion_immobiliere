import 'package:flutter/material.dart';

// 🔹 Import des écrans
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/verify_code_screen.dart';
import 'screens/new_password_screen.dart';
import 'screens/home_locataire_screen.dart';
import 'screens/home_proprietaire_screen.dart';
import 'screens/agent_ia_screen.dart';

/// 🔥 Simulation des infos utilisateur (frontend uniquement)
class FakeUserStorage {
  static String email = '';
  static String password = '';
  static String role = 'Locataire'; // 'Locataire' ou 'Proprietaire'
}

void main() {
  runApp(const MyApp());
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

      // PAGE DE DÉPART
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => LoginScreenWrapper(),
        '/register': (context) => RegisterScreenWrapper(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/verify-code': (context) => const VerifyCodeScreen(),
        '/new-password': (context) => const NewPasswordScreen(),
        '/home-locataire': (context) => const HomeLocataireScreen(),
        '/home-proprietaire': (context) => const HomeProprietaireScreen(),
        '/agent-ia': (context) => const AgentIaScreen(),
      },
    );
  }
}

///////////////////////////////////////////////////////////////
/// 🔵 WRAPPER REGISTER
///////////////////////////////////////////////////////////////

class RegisterScreenWrapper extends StatelessWidget {
  const RegisterScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return RegisterScreen(
      onRegister: (email, password, role) {
        FakeUserStorage.email = email;
        FakeUserStorage.password = password;
        FakeUserStorage.role = role;

        Navigator.pushReplacementNamed(context, '/login');
      },
    );
  }
}

///////////////////////////////////////////////////////////////
/// 🔵 WRAPPER LOGIN
///////////////////////////////////////////////////////////////

class LoginScreenWrapper extends StatelessWidget {
  const LoginScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(
      onLogin: (email, password, role) {
        if (email == FakeUserStorage.email &&
            password == FakeUserStorage.password) {
          if (FakeUserStorage.role.toLowerCase() == 'proprietaire') {
            Navigator.pushReplacementNamed(context, '/home-proprietaire');
          } else {
            Navigator.pushReplacementNamed(context, '/home-locataire');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email ou mot de passe incorrect')),
          );
        }
      },
    );
  }
}

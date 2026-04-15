import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Mes_locataires.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/accueil_proprietaire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/mes_biens.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/message.dart';

class ProprioNavBar extends StatelessWidget {
  final int selectedIndex;

  const ProprioNavBar({super.key, required this.selectedIndex});

  void _onTap(BuildContext context, int index) {
    if (index == selectedIndex) return; // déjà sur cette page

    final pages = [
      const HomePageProprietaire(),
      const MesBiensPage(),
      const MesMaisonsPage(),
      const MessagesPage(),
    ];

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => pages[index],
        transitionDuration: Duration.zero, // pas d'animation = natif
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onTap(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.apartment_outlined),
          selectedIcon: Icon(Icons.apartment),
          label: 'Mes Biens',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Locataires',
        ),
        NavigationDestination(
          icon: Icon(Icons.message_outlined),
          selectedIcon: Icon(Icons.message),
          label: 'Messages',
        ),
      ],
    );
  }
}
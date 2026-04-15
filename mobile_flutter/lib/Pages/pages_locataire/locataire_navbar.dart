import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/accueil_locataire.dart';
import 'package:mobile_flutter/Pages/pages_locataire/mes_demandes.dart';
import 'package:mobile_flutter/Pages/pages_locataire/message_locataire.dart';
import 'package:mobile_flutter/Pages/pages_locataire/paiement.dart';
import 'package:mobile_flutter/Pages/pages_locataire/profil_locataire.dart';

const Color kLocataireBlue = Color(0xFF1A3C6E);

class LocataireNavBar extends StatelessWidget {
  final int selectedIndex;

  const LocataireNavBar({super.key, required this.selectedIndex});

  void _onTap(BuildContext context, int index) {
    if (index == selectedIndex) return;

    final pages = [
      const AccueilLocatairePage(),
      const MesDemandesPage(),
      const MessageLocatairePage(),
      const PaiementPage(),
      const ProfilLocatairePage(),
    ];

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => pages[index],
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _onTap(context, index),
      backgroundColor: Colors.white,
      indicatorColor: kLocataireBlue.withOpacity(0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: kLocataireBlue),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description, color: kLocataireBlue),
          label: 'Demandes',
        ),
        NavigationDestination(
          icon: Icon(Icons.message_outlined),
          selectedIcon: Icon(Icons.message, color: kLocataireBlue),
          label: 'Messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.payment_outlined),
          selectedIcon: Icon(Icons.payment, color: kLocataireBlue),
          label: 'Paiement',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: kLocataireBlue),
          label: 'Profil',
        ),
      ],
    );
  }
}
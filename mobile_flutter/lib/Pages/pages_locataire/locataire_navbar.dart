import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/accueil_locataire.dart';
import 'package:mobile_flutter/Pages/pages_locataire/mes_demandes.dart';
import 'package:mobile_flutter/Pages/pages_locataire/message_locataire.dart';
import 'package:mobile_flutter/Pages/pages_locataire/paiement.dart';
import 'package:mobile_flutter/Pages/pages_locataire/profil_locataire.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

const Color kLocataireBlue = Color(0xFF1A3C6E);

class LocataireNavBar extends StatelessWidget {
  final int selectedIndex;

  const LocataireNavBar({
    super.key,
    required this.selectedIndex,
  });

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
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DemandeProvider, MessageProvider>(
      builder: (context, demandeProvider, messageProvider, _) {
        // Badge demandes
        final nbDemandes = demandeProvider.demandes
            .where((d) => d['statut'] == 'en_attente')
            .length;

        // Badge messages
        final nbMessages = messageProvider.nonLus;

        return NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => _onTap(context, index),
          backgroundColor: Colors.white,
          indicatorColor: kLocataireBlue.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 72,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(
                Icons.home,
                color: kLocataireBlue,
              ),
              label: 'Accueil',
            ),

            // DEMANDES
            NavigationDestination(
              icon: _buildBadgeIcon(
                icon: Icons.description_outlined,
                badge: nbDemandes,
              ),
              selectedIcon: _buildBadgeIcon(
                icon: Icons.description,
                badge: nbDemandes,
                selected: true,
              ),
              label: 'Demandes',
            ),

            // MESSAGES
            NavigationDestination(
              icon: _buildBadgeIcon(
                icon: Icons.message_outlined,
                badge: nbMessages,
              ),
              selectedIcon: _buildBadgeIcon(
                icon: Icons.message,
                badge: nbMessages,
                selected: true,
              ),
              label: 'Messages',
            ),

            const NavigationDestination(
              icon: Icon(Icons.payment_outlined),
              selectedIcon: Icon(
                Icons.payment,
                color: kLocataireBlue,
              ),
              label: 'Paiement',
            ),

            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(
                Icons.person,
                color: kLocataireBlue,
              ),
              label: 'Profil',
            ),
          ],
        );
      },
    );
  }

  static Widget _buildBadgeIcon({
    required IconData icon,
    required int badge,
    bool selected = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          icon,
          color: selected ? kLocataireBlue : null,
        ),

        if (badge > 0)
          Positioned(
            right: -10,
            top: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                badge > 99 ? '99+' : badge.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
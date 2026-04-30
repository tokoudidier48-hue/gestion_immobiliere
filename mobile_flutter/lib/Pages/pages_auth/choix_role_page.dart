import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/accueil_locataire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/accueil_proprietaire.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/widgets/session_wrapper.dart';
import 'package:provider/provider.dart';

class ChoixRolePage extends StatelessWidget {
  const ChoixRolePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline, size: 48, color: Colors.blue),
              ),
              const SizedBox(height: 28),
              const Text(
                'Bienvenue sur LoyaSmart !',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Choisissez votre rôle pour continuer',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),

              // Bouton Locataire
              _RoleCard(
                icon: Icons.home_outlined,
                title: 'Locataire',
                subtitle: 'Je cherche un logement à louer',
                color: const Color(0xFF1A3C6E),
                onTap: () => _choisir(context, 'locataire'),
              ),
              const SizedBox(height: 16),

              // Bouton Propriétaire
              _RoleCard(
                icon: Icons.apartment_outlined,
                title: 'Propriétaire',
                subtitle: 'Je propose des logements à louer',
                color: const Color(0xFF1565C0),
                onTap: () => _choisir(context, 'proprietaire'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choisir(BuildContext context, String role) async {
    final provider = context.read<UtilisateurProvider>();
    final success = await provider.choisirRole(role);

    if (!context.mounted) return;

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionWrapper(
            child: role == 'locataire'
                ? const AccueilLocatairePage()
                : const HomePageProprietaire(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors du choix du rôle'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UtilisateurProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: provider.isLoading ? null : onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: color)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                if (provider.isLoading)
                  SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                else
                  Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/historique_paiements.dart';
import 'package:mobile_flutter/Pages/pages_locataire/locataire_navbar.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:mobile_flutter/Pages/pages_locataire/modificationProfilLocatairePage.dart' hide kLocataireBlue;
import 'package:mobile_flutter/Pages/pages_locataire/notification_locataire.dart';
import 'package:mobile_flutter/Pages/pages_locataire/paiement.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/provider/provider_profil.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:provider/provider.dart';

class ProfilLocatairePage extends StatefulWidget {
  const ProfilLocatairePage({super.key});

  @override
  State<ProfilLocatairePage> createState() => _ProfilLocatairePageState();
}

class _ProfilLocatairePageState extends State<ProfilLocatairePage> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<ProfilProvider>().fetchProfil()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<ProfilProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Vérifiez votre connexion internet et réessayez',
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchProfil(),
                    child: const Text('Réessayer'),
                  ),
                ]
              ),
            );
              
          }
          final profil = provider.profil;
          if (profil == null) return const SizedBox();

          return SingleChildScrollView(
            child: Column(
              children: [
                // ── HEADER ──────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: kLocataireBlue.withOpacity(0.15),
                        backgroundImage: profil.photoProfil != null
                            ? NetworkImage(profil.photoProfil!)
                            : null,
                        child: profil.photoProfil == null
                            ? Text(
                                '${profil.name.isNotEmpty ? profil.name[0].toUpperCase() : ''}${profil.lastName.isNotEmpty ? profil.lastName[0].toUpperCase() : ''}',
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kLocataireBlue),
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${profil.name} ${profil.lastName}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: kLocataireBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'LOCATAIRE LOYASMART',
                          style: TextStyle(fontSize: 11, color: kLocataireBlue, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(profil.phoneNumber, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── MENU ────────────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Text(
                          'MENU DU LOCATAIRE',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 1),
                        ),
                      ),
                      _buildMenuItem(
                        icon: Icons.person_outline,
                        iconColor: kLocataireBlue,
                        title: 'Modification du profil',
                        subtitle: 'Informations personnelles et photo',
                        onTap: () {
                          // Naviguer vers la page de modification du profil
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ModificationProfilLocatairePage()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.receipt_long_outlined,
                        iconColor: kLocataireBlue,
                        title: 'Historique des paiements',
                        subtitle: 'Reçus, loyers et cautions',
                        onTap: () {
                          // Naviguer vers la page d'historique des paiements
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoriquePaiementsPage()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_outlined,
                        iconColor: kLocataireBlue,
                        title: 'Notifications',
                        subtitle: 'Alertes de paiement et messages',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationLocatairePage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── DÉCONNEXION ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer<UtilisateurProvider>(
                    builder: (context, auth, child) {
                      return OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.w700)),
                              content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Annuler'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    await LocalStorage.clearAll(); // ← vide tout
                                    auth.logout();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const Connexion()),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                        label: const Text('Déconnexion', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 15)),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: Colors.red, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.red.shade50,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const LocataireNavBar(selectedIndex: 4),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 70, endIndent: 16, color: Colors.grey.shade100);
  }
}
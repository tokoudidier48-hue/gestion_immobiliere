import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_auth/connexion.dart';
import 'package:mobile_flutter/Pages/a_propos.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/evolution_financiere.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/modifier_profil.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/proprio_notification.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/provider/provider_profil.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/service/session_service.dart';
import 'package:provider/provider.dart';

class MonProfilPage extends StatefulWidget {
  const MonProfilPage({super.key});

  @override
  State<MonProfilPage> createState() => _MonProfilPageState();
}

class _MonProfilPageState extends State<MonProfilPage> {

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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<ProfilProvider>(
        builder: (context, provider, child) {

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text("Erreur : ${provider.error}"));
          }

          final profil = provider.profil;
          if (profil == null) return const SizedBox();

          return Column(
            children: [
              // ── HEADER ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: profil.photoProfil != null
                              ? NetworkImage(profil.photoProfil!)
                              : null,
                          child: profil.photoProfil == null
                              ? Text(
                                  '${profil.name.isNotEmpty ? profil.name[0].toUpperCase() : ''}${profil.lastName.isNotEmpty ? profil.lastName[0].toUpperCase() : ''}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 11),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Nom
                    Text(
                      '${profil.name} ${profil.lastName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Rôle
                    Text(
                      profil.role == 'proprietaire' ? 'Propriétaire Certifié' : profil.role,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Email
                    Text(
                      profil.email,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),

                    const SizedBox(height: 2),

                    // Téléphone
                    if (profil.phoneNumber.isNotEmpty)
                      Text(
                        profil.phoneNumber,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      ),

                    // Dernière connexion
                    if (profil.derniereConnexion != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Dernière connexion : ${_formatDate(profil.derniereConnexion!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // ── MENU ──────────────────────────────────────────────────
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      iconColor: const Color(0xFF1565C0),
                      title: 'Modifier le profil',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ModifierProfilPage(profil: profil)),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: const Color(0xFF1565C0),
                      title: 'Finances',
                      subtitle: "Évolution du chiffre d'affaires",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const EvolutionFinancesPage()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFF1565C0),
                      title: 'Notifications',
                      onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationsPage()),
                          );
                      },
                      hasDot: true,
                    ),
                    _buildDivider(),
                    _buildMenuItem(
                      icon: Icons.info_outline,
                      iconColor: const Color(0xFF1565C0),
                      title: 'À propos de LoyaSmart',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AProposPage()),
                        );

                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── BOUTON DÉCONNEXION ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: OutlinedButton.icon(
                  onPressed: _showLogoutDialog,
                  icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    side: const BorderSide(color: Colors.red, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.red.shade50,
                  ),
                ),
              ),

              const Spacer(),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool hasDot = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
            if (hasDot)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
              ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 20,
      color: Colors.grey.shade100,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Se déconnecter',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          Consumer<UtilisateurProvider>(
            builder: (context, auth, child) {
              return ElevatedButton(
            onPressed: () async {
              await LocalStorage.clearAll(); // ← vide tout
              SessionService.stop(); // ← arrête les timers de session
                  auth.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const Connexion()),
                    (route) => false,
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.white)),
          );
            },
          ),
        ],
      ),
    );
  }
}
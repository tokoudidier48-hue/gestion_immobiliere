import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/locataire_navbar.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

class MesDemandesPage extends StatefulWidget {
  const MesDemandesPage({super.key});

  @override
  State<MesDemandesPage> createState() => _MesDemandesPageState();
}

class _MesDemandesPageState extends State<MesDemandesPage> {
  static const _primaryColor = Color(0xFF1A3C6E);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DemandeProvider>().fetchDemandes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Mes Demandes',
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () => context.read<DemandeProvider>().fetchDemandes(),
          ),
        ],
      ),
      body: Consumer<DemandeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Voirifiez votre connexion internet et réessayez',
                      style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchDemandes(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.demandes.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Aucune demande pour le moment',
                      style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Text('HISTORIQUE DES DEMANDES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: Colors.grey, letterSpacing: 1.2)),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: provider.demandes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildDemandeCard(context, provider, provider.demandes[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const LocataireNavBar(selectedIndex: 1),
    );
  }

  Widget _buildDemandeCard(BuildContext context, DemandeProvider provider, dynamic demande) {
    final statut = demande['statut'] ?? 'en_attente';
    final titre = demande['unite_nom'] ?? 'Unité sans nom';         // ← était unite_details['nom']
    final type = demande['unite_type'] ?? '';                        // ← nouveau
    final loyer = demande['unite_loyer']?.toString() ?? '0';         // ← nouveau
    final proprietaire = demande['proprietaire_nom'] ?? '';           // ← nouveau
    final date = demande['date_demande'] ?? '';
    final demandeId = demande['id'];

    IconData typeIcon;
    switch (type) {
      case 'studio':
        typeIcon = Icons.home;
        break;
      case 'f1':
      case 'f2':
      case 'f3':
      case 'f4':
        typeIcon = Icons.apartment;
        break;
      case 'maison':
        typeIcon = Icons.house;
        break;
      default:
        typeIcon = Icons.business;
    }

    Color statusColor;
    String statusLabel;
    switch (statut) {
      case 'acceptee':
        statusColor = const Color(0xFF4CAF50);
        statusLabel = 'Acceptée';
        break;
      case 'refusee':
        statusColor = const Color(0xFFE53935);
        statusLabel = 'Refusée';
        break;
      case 'annulee':
        statusColor = Colors.grey;
        statusLabel = 'Annulée';
        break;
      default:
        statusColor = const Color(0xFFFF9800);
        statusLabel = 'En attente';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icône à la place de l'image (pas de photo dans la réponse)
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3C6E).withOpacity(0.08),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                ),
                child: Icon(typeIcon, color: const Color(0xFF1A3C6E), size: 36),
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(titre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          _buildStatusBadge(statusLabel, statusColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(type,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1A3C6E),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(proprietaire,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('$loyer FCFA / mois',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: Color(0xFF1A3C6E))),
                      const SizedBox(height: 3),
                      Text(_formatDate(date),
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Bouton annuler si en attente
          if (statut == 'en_attente')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Annuler la demande'),
                        content: const Text('Voulez-vous annuler cette demande ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Non'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Annuler', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await provider.annulerDemande(demandeId);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Annuler la demande',
                      style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      return 'Demande le ${d.day.toString().padLeft(2, '0')} ${_mois(d.month)} ${d.year}';
    } catch (_) {
      return date;
    }
  }

  String _mois(int m) {
    const mois = ['Jan.', 'Fév.', 'Mar.', 'Avr.', 'Mai', 'Jun.',
        'Jul.', 'Aoû.', 'Sep.', 'Oct.', 'Nov.', 'Déc.'];
    return mois[m - 1];
  }
}
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/chatPageDirect.dart';
import 'package:mobile_flutter/Pages/pages_locataire/paiement.dart';
import 'package:mobile_flutter/Pages/pages_locataire/trouver_colocataire.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:provider/provider.dart';

class DetailsLogementPage extends StatefulWidget {
  final Map<String, dynamic> unite;
  const DetailsLogementPage({super.key, required this.unite});

  @override
  State<DetailsLogementPage> createState() => _DetailsLogementPageState();
}

class _DetailsLogementPageState extends State<DetailsLogementPage> {
  int _selectedTab = 0;
  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    final u = widget.unite;
    final photos = (u['photos'] as List?) ?? [];
    final prix = u['loyer']?.toString() ?? '0';
    final titre = u['nom'] ?? 'Sans titre';
    final adresse = '${u['ville'] ?? ''}, ${u['adresse'] ?? ''}';
    final statut = (u['statut'] ?? 'libre').toString();
    final type = (u['type_unite'] ?? '').toString().replaceAll('_', ' ');
    final description = u['description'] ?? 'Aucune description disponible.';
    final prepaye = u['prepaye'] == true;
    final nbrAvances = u['nombre_avances'] ?? 0;
    final typeCaution = (u['type_caution'] ?? '').toString().replaceAll('_', ' ');
    final prixCaution = u['prix_caution']?.toString() ?? '0';
    final contact = u['contact_proprietaire'] ?? '';
    final typeDouche = (u['type_douche'] ?? '').toString();
    final uniteId = u['id'];
    final totalEntree = (double.tryParse(prix) ?? 0) * nbrAvances +
        (double.tryParse(prixCaution) ?? 0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageHeader(context, photos, statut),
                _buildTabs(),
                _selectedTab == 0
                    ? _buildDetailsTab(
                        context: context,
                        titre: titre,
                        adresse: adresse,
                        prix: prix,
                        type: type,
                        typeDouche: typeDouche,
                        prepaye: prepaye,
                        description: description,
                        nbrAvances: nbrAvances,
                        typeCaution: typeCaution,
                        prixCaution: prixCaution,
                        totalEntree: totalEntree,
                        contact: contact,
                      )
                    : _buildAnnonceTab(),
              ],
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomButton(context, uniteId),
          ),
        ],
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context, List photos, String statut) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: photos.isNotEmpty
              ? PageView.builder(
                  itemCount: photos.length,
                  onPageChanged: (i) => setState(() => _currentImage = i),
                  itemBuilder: (_, i) => Image.network(
                    photos[i]['image'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE8EEF7),
                      child: const Icon(Icons.apartment, size: 80, color: Color(0xFF1A3C6E)),
                    ),
                  ),
                )
              : Container(
                  color: const Color(0xFFE8EEF7),
                  child: const Icon(Icons.apartment, size: 80, color: Color(0xFF1A3C6E)),
                ),
        ),
        // Dégradé haut
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withOpacity(0.4), Colors.transparent],
              ),
            ),
          ),
        ),
        // AppBar
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _iconButton(Icons.arrow_back, () => Navigator.pop(context)),
                  const Expanded(
                    child: Center(
                      child: Text('Détails du Logement',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                  _iconButton(Icons.share_outlined, () {}),
                  const SizedBox(width: 8),
                  _iconButton(Icons.favorite_border, () {}),
                ],
              ),
            ),
          ),
        ),
        // Badge statut
        Positioned(
          bottom: 12, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statut == 'libre' ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statut == 'libre' ? 'Disponible' : 'Occupé',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ),
        // Compteur photos
        if (photos.length > 1)
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_library_outlined, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text('${_currentImage + 1}/${photos.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ["Détails de l'unité", 'Annonce'];
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? const Color(0xFF1A3C6E) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? const Color(0xFF1A3C6E) : Colors.grey,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDetailsTab({
    required BuildContext context,
    required String titre,
    required String adresse,
    required String prix,
    required String type,
    required String typeDouche,
    required bool prepaye,
    required String description,
    required int nbrAvances,
    required String typeCaution,
    required String prixCaution,
    required double totalEntree,
    required String contact,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + Prix
          Text(titre,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(adresse,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Détails financiers
          _buildSectionTitle('Détails Financiers'),
          const SizedBox(height: 12),
          _buildFinanceRow('Loyer Mensuel', '$prix FCFA', bold: true),
          const SizedBox(height: 4),
          _buildFinanceRow("Avances sur Loyer\n$nbrAvances Mois",
              '${(double.tryParse(prix) ?? 0) * nbrAvances} FCFA'),
          const SizedBox(height: 4),
          _buildFinanceRow('Caution ($typeCaution)\nForfaitaire', '$prixCaution FCFA'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(prepaye ? Icons.bolt : Icons.bolt_outlined,
                    size: 14, color: const Color(0xFF1A3C6E)),
                const SizedBox(width: 4),
                Text(
                  prepaye ? 'Avec prépayé' : 'Sans prépayé',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1A3C6E)),
                ),
              ],
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total à prévoir',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                '${totalEntree.toInt()} FCFA',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A3C6E)),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Description
          _buildSectionTitle('Description'),
          const SizedBox(height: 10),
          Text(description,
              style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.5)),
          const SizedBox(height: 24),

          // Caractéristiques
          _buildSectionTitle('Caractéristiques'),
          const SizedBox(height: 10),
          _buildCaracRow('Type', type),
          _buildCaracRow('Douche', typeDouche == 'interne' ? 'Interne' : 'Externe'),
          const SizedBox(height: 24),

          // Colocataire
          _buildColocataireCard(context),
          const SizedBox(height: 24),

          // Contact
          _buildSectionTitle('Contact Propriétaire'),
          const SizedBox(height: 12),
          _buildContactCard(contact),
        ],
      ),
    );
  }

Widget _buildAnnonceTab() {
  final uniteId = widget.unite['id'];

  return FutureBuilder<String?>(
    future: LocalStorage.getUserId(),
    builder: (context, userSnapshot) {
      final currentUserId = userSnapshot.data ?? '' ;

      return FutureBuilder<List<dynamic>>(
        future: context.read<ColocataireProvider>().getRecherchesByUnite(uniteId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final recherches = snapshot.data ?? [];
          // Trier pour mettre l'annonce du lanceur en premier
          recherches.sort((a, b) {
            final aIsMine = (a['locataire'] ?? '').toString() == currentUserId;
            final bIsMine = (b['locataire'] ?? '').toString() == currentUserId;

            if (aIsMine && !bIsMine) return -1;
            if (!aIsMine && bIsMine) return 1;
            return 0;
          });

      if (recherches.isEmpty) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1A3C6E).withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF1A3C6E), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aucune annonce de colocation pour le moment.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1A3C6E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF1F8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_outline, size: 44, color: Color(0xFF9DADC8)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucune annonce de colocation\npour le moment',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        );
      }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: recherches.length,
            itemBuilder: (context, index) {
              return _buildRechercheCard(recherches[index], currentUserId);
            },
          );
        },
      );
    },
  );
}

Widget _buildRechercheCard(dynamic recherche, String currentUserId) {
  final rechercheId = recherche['id'];
  final locataireId = recherche['locataire']?.toString() ?? '';
  final locataireNom = recherche['locataire_nom'] ?? 'Locataire';
  final filiere = recherche['filiere'] ?? '';
  final ville = recherche['ville'] ?? '';
  final religion = recherche['religion'] ?? '';
  final telephone = recherche['telephone'] ?? '';
  final description = recherche['description'] ?? '';
  final estActive = recherche['est_active'] == true;

  // L'utilisateur connecté est-il le lanceur de cette recherche ?
  final estLanceur = currentUserId.isNotEmpty && locataireId == currentUserId;
    print("locataireId = $locataireId");
    print("currentUserId = $currentUserId");
    print("estLanceur = $estLanceur");

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4FF),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF1A3C6E).withOpacity(0.15),
                child: Text(
                  locataireNom.isNotEmpty ? locataireNom[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A3C6E),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locataireNom,
                        style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87,
                        )),
                    Text(
                      estLanceur ? 'Votre annonce' : 'Cherche un colocataire',
                      style: TextStyle(
                        fontSize: 12,
                        color: estLanceur ? const Color(0xFF1A3C6E) : Colors.grey,
                        fontWeight: estLanceur ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estActive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: estActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Infos
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoChip(Icons.school_outlined, 'Filière', filiere),
              const SizedBox(height: 8),
              _infoChip(Icons.location_on_outlined, 'Ville', ville),
              if (religion.isNotEmpty) ...[
                const SizedBox(height: 8),
                _infoChip(Icons.favorite_outline, 'Religion', religion),
              ],
              const SizedBox(height: 8),
              _infoChip(Icons.phone_outlined, 'Téléphone', telephone),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(description,
                    style: const TextStyle(
                      fontSize: 13, color: Colors.black54, height: 1.5,
                    )),
              ],
            ],
          ),
        ),

        // Candidatures
        FutureBuilder<List<dynamic>>(
            future: context.read<ColocataireProvider>().getCandidaturesRecherche(rechercheId),
            builder: (context, snapshot) {
              final candidatures = snapshot.data ?? [];

              // Vérifie si l'utilisateur connecté a déjà postulé
              final dejaPostule = candidatures.any(
                (c) => (c['candidat'] ?? c['candidat_id'] ?? '').toString() == currentUserId,
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (candidatures.isNotEmpty) ...[
                    Divider(color: Colors.grey.shade100),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                      child: Text(
                        '${candidatures.length} candidature(s)',
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey,
                        ),
                      ),
                    ),
                    ...candidatures.map((c) => _buildCandidatureItem(
                      c,
                      estLanceur,
                      currentUserId, // ← passe currentUserId
                    )).toList(),
                  ],

                  // Bouton postuler — masqué si lanceur OU déjà postulé
                  if (!estLanceur && !dejaPostule)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TrouverColocatairePage(
                                  rechercheId: rechercheId,
                                  estPostulant: true,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add_outlined,
                              size: 16, color: Color(0xFF1A3C6E)),
                          label: const Text('Je suis intéressé(e)',
                              style: TextStyle(color: Color(0xFF1A3C6E), fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1A3C6E)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),

                  // Message si déjà postulé
                  if (!estLanceur && dejaPostule)
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('Vous avez déjà postulé à cette annonce',
                                style: TextStyle(fontSize: 13, color: Colors.green,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    ),
  );
}

Widget _buildCandidatureItem(dynamic candidature, bool estLanceur, String currentUserId) {
  final candidatureId = candidature['id'];
  final candidatId = (candidature['candidat'] ?? candidature['candidat_id'] ?? '').toString();
  final candidatNom = candidature['candidat_nom'] ?? 'Candidat';
  final filiere = candidature['filiere'] ?? '';
  final ville = candidature['ville'] ?? '';
  final telephone = candidature['telephone'] ?? '';
  final description = candidature['description'] ?? '';
  final estAcceptee = candidature['est_acceptee'] == true;

  // Est-ce que c'est la candidature de l'utilisateur connecté ?
  final estMaCandidature = candidatId == currentUserId;

  return Container(
    margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: estAcceptee
          ? Colors.green.withOpacity(0.05)
          : const Color(0xFFF9F9F9),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: estAcceptee
            ? Colors.green.withOpacity(0.3)
            : Colors.grey.shade200,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: estMaCandidature
                  ? const Color(0xFF1A3C6E).withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              child: Text(
                candidatNom.isNotEmpty ? candidatNom[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: estMaCandidature ? const Color(0xFF1A3C6E) : Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(candidatNom,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (estMaCandidature)
                    const Text('Votre candidature',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1A3C6E),
                            fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (estAcceptee)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('ACCEPTÉ',
                    style: TextStyle(fontSize: 10, color: Colors.green,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _infoChip(Icons.school_outlined, 'Filière', filiere),
        const SizedBox(height: 4),
        _infoChip(Icons.location_on_outlined, 'Ville', ville),
        const SizedBox(height: 4),
        _infoChip(Icons.phone_outlined, 'Tél', telephone),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(description,
              style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4)),
        ],

        // Boutons accepter/refuser — uniquement pour le lanceur, candidature non encore acceptée
        if (estLanceur && !estAcceptee) ...[
          const SizedBox(height: 12),
          Consumer<ColocataireProvider>(
            builder: (context, provider, child) {
              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : () async {
                        final success =
                            await provider.accepterCandidature(candidatureId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? 'Candidature acceptée !'
                              : 'Erreur : ${provider.error}'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ));
                        if (success) setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Accepter',
                          style: TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.isLoading ? null : () async {
                        final success =
                            await provider.refuserCandidature(candidatureId);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success
                              ? 'Candidature refusée.'
                              : 'Erreur : ${provider.error}'),
                          backgroundColor: success ? Colors.orange : Colors.red,
                        ));
                        if (success) setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Refuser',
                          style: TextStyle(
                            color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ],
    ),
  );
}

Widget _infoChip(IconData icon, String label, String value) {
  if (value.isEmpty) return const SizedBox();
  return Row(
    children: [
      Icon(icon, size: 14, color: Colors.grey),
      const SizedBox(width: 6),
      Text('$label : ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Flexible(
        child: Text(value,
            style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _buildFinanceRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13, color: Colors.black87,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                color: bold ? const Color(0xFF1A3C6E) : Colors.black87,
              )),
        ],
      ),
    );
  }

  Widget _buildCaracRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildColocataireCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrouverColocatairePage(
              uniteId: widget.unite['id'],  // ← passe l'ID
              estPostulant: false,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1A3C6E).withOpacity(0.15)),
        ),
        child: Row(
          children: [
            const Icon(Icons.people_outline, color: Color(0xFF1A3C6E), size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHERCHER UN COLOCATAIRE',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A3C6E))),
                  SizedBox(height: 2),
                  Text('Trouvez quelqu\'un pour partager ce logement',
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF1A3C6E)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(String contact) {
  // Récupère l'ID du propriétaire depuis les données de l'unité
  final proprietaireId = widget.unite['proprietaire'];
  final proprietaireNom = widget.unite['proprietaire_nom'] ?? 'Propriétaire';
  final initiales = proprietaireNom.split(' ')
      .take(2)
      .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
      .join();

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF1A3C6E).withOpacity(0.1),
          child: Text(
            initiales,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A3C6E),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DIRECT PROPRIÉTAIRE',
                  style: TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(proprietaireNom,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(contact,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
        _contactIcon(Icons.phone_outlined, Colors.green),
        const SizedBox(width: 8),
        // Bouton message branché
       GestureDetector(
        onTap: () async {
          if (proprietaireId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Propriétaire introuvable')),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPageDirect(
                autreUserId: proprietaireId,
                nom: proprietaireNom,
                initiales: initiales,
                uniteId: widget.unite['id'], // ← passe l'uniteId
              ),
            ),
          );
        },
        child: _contactIcon(Icons.chat_bubble_outline, const Color(0xFF1A3C6E)),
      ),
        const SizedBox(width: 8),
        _contactIcon(Icons.share_outlined, Colors.orange),
      ],
    ),
  );
}

  Widget _contactIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildBottomButton(BuildContext context, dynamic uniteId) {
  final isAnnonce = _selectedTab == 1;

  if (isAnnonce) {
    return FutureBuilder<List<dynamic>>(
      future: context.read<ColocataireProvider>().getRecherchesByUnite(uniteId),
      builder: (context, snapshot) {
        final recherches = snapshot.data ?? [];
        if (recherches.isNotEmpty) return const SizedBox.shrink();
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => TrouverColocatairePage(uniteId: uniteId, estPostulant: false),
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C6E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('+ AJOUTER VOTRE INFORMATION',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }

  // ← Onglet Détails — bouton dynamique selon statut demande
  return FutureBuilder<List<dynamic>>(
    future: context.read<DemandeProvider>().fetchDemandesByUnite(uniteId),
    builder: (context, snapshot) {
      final demandes = snapshot.data ?? [];

      // Cherche une demande active pour cette unité
      dynamic demande;
      try {
        demande = demandes.firstWhere(
          (d) => d['unite'] == uniteId || d['unite_details']?['id'] == uniteId,
        );
      } catch (_) {
        demande = null;
      }

      final statut = demande?['statut'] ?? '';

      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Consumer<DemandeProvider>(
          builder: (context, demandeProvider, child) {
            // ── Demande acceptée → Effectuer le paiement ──
            if (statut == 'acceptee') {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const PaiementPage(),
                    ));
                  },
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text('Effectuer le paiement',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              );
            }

            // ── Demande en attente → désactivé ──
            if (statut == 'en_attente') {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Demande en cours...',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              );
            }

            // ── Pas de demande ou refusée → peut envoyer ──
            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: demandeProvider.isLoading ? null : () async {
                  final messageController = TextEditingController();
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: const Text('Envoyer une demande',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Voulez-vous envoyer une demande pour ce logement ?'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: messageController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Message optionnel...',
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3C6E)),
                          child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    final success = await demandeProvider.envoyerDemande(
                      uniteId,
                      message: messageController.text.trim().isEmpty
                          ? null
                          : messageController.text.trim(),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Demande envoyée avec succès !'
                            : 'Erreur : ${demandeProvider.error}'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    if (success) setState(() {}); // ← rafraîchit le bouton
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: demandeProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        statut == 'refusee'
                            ? 'Renvoyer une demande'
                            : 'Envoyez une demande de chambre',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            );
          },
        ),
      );
    },
  );
}
}
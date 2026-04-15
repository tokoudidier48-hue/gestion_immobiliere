import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/widgets/widgets_proprietaire/detail_libre.dart';

class DetailUniteScreen extends StatelessWidget {
  final Unites unite;
  const DetailUniteScreen({super.key, required this.unite});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroInfo(),
                const SizedBox(height: 8),
                _buildStatutRow(),
                const SizedBox(height: 8),
                _buildDescription(),
                const SizedBox(height: 8),
                _buildCaracteristiques(),
                const SizedBox(height: 8),
                _buildConditionsLocation(),
                const SizedBox(height: 8),
                _buildTotalEntree(),
                const SizedBox(height: 8),
                _buildContactProprietaire(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SliverAppBar avec image ───────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 18,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: kTextDark, size: 16),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
      ),
      title: const Text(
        'Détails de l\'unité',
        style: TextStyle(color: kTextDark, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image principale ou placeholder
            unite.photos.isNotEmpty
                ? Image.network(
                    unite.photos[0],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE0F2FE),
                      child: const Center(
                        child: Icon(Icons.apartment, size: 80, color: Color(0xFF93C5FD)),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFE0F2FE),
                    child: const Center(
                      child: Icon(Icons.apartment, size: 80, color: Color(0xFF93C5FD)),
                    ),
                  ),
            // Dégradé bas
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                  ),
                ),
              ),
            ),
            // Badges
            Positioned(
              bottom: 16, left: 16,
              child: Row(
                children: [
                  TopBadge(label: unite.typeUnite.toUpperCase().replaceAll('_', ' '), color: kBadgeChambre),
                  const SizedBox(width: 8),
                  const TopBadge(label: 'LIBRE', color: kLibreGreen),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Infos principales ─────────────────────────────────────────────────────

  Widget _buildHeroInfo() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  unite.nomUnite,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextDark),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${unite.loyer.toInt()} FCFA',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kPrimary),
                  ),
                  const Text('Loyer Mensuel', style: TextStyle(fontSize: 11, color: kTextMid)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: kTextMid),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${unite.ville}, ${unite.adresse}',
                  style: const TextStyle(fontSize: 12, color: kTextMid),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Statut ────────────────────────────────────────────────────────────────

  Widget _buildStatutRow() {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: StatutItem(
              icon: Icons.check_circle_outline,
              iconColor: kLibreGreen,
              label: 'Statut',
              value: unite.statut.toUpperCase(),
              valueColor: kLibreGreen,
            ),
          ),
          Container(width: 1, height: 40, color: kDivider),
          Expanded(
            child: StatutItem(
              icon: Icons.payment_outlined,
              iconColor: kPrimary,
              label: 'Prépayé',
              value: unite.prepaye ? 'Avec prépayé' : 'Sans prépayé',
              valueColor: kTextDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ───────────────────────────────────────────────────────────

  Widget _buildDescription() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'DESCRIPTION'),
          const SizedBox(height: 10),
          Text(
            unite.description.isNotEmpty ? unite.description : 'Aucune description disponible.',
            style: const TextStyle(fontSize: 13, color: kTextMid, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Caractéristiques ──────────────────────────────────────────────────────

  Widget _buildCaracteristiques() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'CARACTÉRISTIQUES'),
          const SizedBox(height: 12),
          CaracRow(label: 'Type', value: unite.typeUnite.replaceAll('_', ' ')),
          const Divider(height: 16, color: kDivider),
          CaracRow(label: 'Douche', value: unite.typeDouche),
          const Divider(height: 16, color: kDivider),
          CaracRow(label: 'Garage', value: unite.garage ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  // ── Conditions de location ────────────────────────────────────────────────

  Widget _buildConditionsLocation() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'CONDITIONS DE LOCATION'),
          const SizedBox(height: 12),
          CaracRow(label: "Nombre d'avances", value: '${unite.nbrAvances} mois'),
          const Divider(height: 20, color: kDivider),
          CaracRow(label: 'Type de caution', value: unite.typeCaution.replaceAll('_', ' ')),
          const Divider(height: 20, color: kDivider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Montant caution', style: TextStyle(fontSize: 13, color: kTextMid)),
              Text(
                '${unite.montantCaution.toInt()} FCFA',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Total à l'entrée ──────────────────────────────────────────────────────

  Widget _buildTotalEntree() {
    final total = (unite.loyer * unite.nbrAvances) + unite.montantCaution;
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total à l'entrée",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextDark),
          ),
          Text(
            '${total.toInt()} FCFA',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kPrimary),
          ),
        ],
      ),
    );
  }

  // ── Contact propriétaire ──────────────────────────────────────────────────

  Widget _buildContactProprietaire() {
    // Initiales depuis le contact
    final initiales = unite.contactProprietaire.isNotEmpty
        ? unite.contactProprietaire.substring(0, 2)
        : 'PR';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'CONTACT PROPRIÉTAIRE / GÉRANT'),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kPrimary.withOpacity(0.15),
                child: Text(
                  initiales,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kPrimary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Propriétaire',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unite.contactProprietaire,
                      style: const TextStyle(fontSize: 13, color: kTextMid),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(color: kLibreGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
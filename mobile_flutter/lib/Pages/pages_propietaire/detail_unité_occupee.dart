import 'package:flutter/material.dart';
import 'package:mobile_flutter/widgets/widgets_proprietaire/detail_occupe.dart';

class DetailUniteScreenn extends StatelessWidget {
  const DetailUniteScreenn({super.key});

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
                _buildLocataireActuel(),
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

  // ── SliverAppBar ─────────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 230,
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
        style: TextStyle(
          color: kTextDark,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image placeholder — remplacer par Image.asset(...) ou Image.network(...)
            Container(
              color: const Color(0xFFE0F2FE),
              child: const Center(
                child: Icon(Icons.park, size: 90, color: Color(0xFF22C55E)),
              ),
            ),
            // Badge OCCUPÉ en haut à droite
            Positioned(
              top: 96,
              right: 16,
              child: TopBadge(
                label: 'OCCUPÉ',
                color: kOccupeOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Nom + loyer + adresse ────────────────────────────────────────────────────

  Widget _buildHeroInfo() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Chambre C1',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text(
                    '250.000 FCFA',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                    ),
                  ),
                  Text(
                    'Loyer Mensuel',
                    style: TextStyle(fontSize: 11, color: kTextMid),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.location_on_outlined, size: 14, color: kTextMid),
              SizedBox(width: 4),
              Text(
                'Cotonou, Agblé 7ème Tranche, Abidjan',
                style: TextStyle(fontSize: 12, color: kTextMid),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Statut + Paiement ────────────────────────────────────────────────────────

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
              value: 'Disponible',
              valueColor: kLibreGreen,
            ),
          ),
          Container(width: 1, height: 40, color: kDivider),
          Expanded(
            child: StatutItem(
              icon: Icons.payment_outlined,
              iconColor: kPrimary,
              label: 'Paiement',
              value: 'Avec prépayé',
              valueColor: kTextDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Description ──────────────────────────────────────────────────────────────

  Widget _buildDescription() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionTitle(title: 'DESCRIPTION'),
          SizedBox(height: 10),
          Text(
            'Magnifique appartement de 3 pièces situé au cœur d\'Agblé. Composé de 2 chambres lumineuses, un grand salon lumineux avec balcon, une cuisine moderne équipée et un parking sécurisé. Idéal pour petite famille ou jeune couple.',
            style: TextStyle(fontSize: 13, color: kTextMid, height: 1.6),
          ),
        ],
      ),
    );
  }

  // ── Caractéristiques ─────────────────────────────────────────────────────────

  Widget _buildCaracteristiques() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionTitle(title: 'CARACTÉRISTIQUES'),
          SizedBox(height: 12),
          InfoRow(label: 'Douche', value: 'Interne'),
        ],
      ),
    );
  }

  // ── Conditions de location ───────────────────────────────────────────────────

  Widget _buildConditionsLocation() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'CONDITIONS DE LOCATION'),
          const SizedBox(height: 12),
          const InfoRow(label: "Nombre d'avance", value: '3 Mois'),
          const Divider(height: 20, color: kDivider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caution Electricité / Eau',
                    style: TextStyle(fontSize: 13, color: kTextMid),
                  ),
                  Text(
                    'Frais de garde en sus',
                    style: TextStyle(
                      fontSize: 11,
                      color: kTextMid.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const Text(
                '100.000 FCFA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Total à l'entrée ─────────────────────────────────────────────────────────

  Widget _buildTotalEntree() {
    return SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Text(
            "Total à l'entrée",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          Text(
            '1.100.000 FCFA',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Locataire actuel ─────────────────────────────────────────────────────────

  Widget _buildLocataireActuel() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionTitle(title: 'LOCATAIRE ACTUEL'),
          SizedBox(height: 14),
          LocataireInfoRow(label: 'Nom', value: 'Jean Marc Kouassi'),
          LocataireInfoRow(label: 'Contact', value: '+225 00 00 00 00'),
          LocataireInfoRow(label: 'Email', value: 'j.kouassi@email.com'),
        ],
      ),
    );
  }

  // ── Contact propriétaire / gérant ────────────────────────────────────────────

  Widget _buildContactProprietaire() {
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
                child: const Text(
                  'MJ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'M. Koffi Jean-Pierre',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '+225 00 00 00 00',
                      style: TextStyle(fontSize: 13, color: kTextMid),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: kLibreGreen,
                    shape: BoxShape.circle,
                  ),
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
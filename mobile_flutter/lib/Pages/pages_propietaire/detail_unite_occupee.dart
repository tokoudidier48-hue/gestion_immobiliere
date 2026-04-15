import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/widgets/widgets_proprietaire/detail_occupe.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailUniteScreenn extends StatelessWidget {
  final Unites unite;
  const DetailUniteScreenn({super.key, required this.unite});

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
        style: TextStyle(color: kTextDark, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            unite.photos.isNotEmpty
                ? Image.network(
                    unite.photos[0],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFFFEDD5),
                      child: const Center(
                        child: Icon(Icons.apartment, size: 90, color: Color(0xFFF97316)),
                      ),
                    ),
                  )
                : Container(
                    color: const Color(0xFFFFEDD5),
                    child: const Center(
                      child: Icon(Icons.apartment, size: 90, color: Color(0xFFF97316)),
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
            // Badge OCCUPÉ
            Positioned(
              bottom: 16, left: 16,
              child: Row(
                children: [
                  TopBadge(
                    label: unite.typeUnite.toUpperCase().replaceAll('_', ' '),
                    color: kBadgeChambre,
                  ),
                  const SizedBox(width: 8),
                  const TopBadge(label: 'OCCUPÉ', color: kOccupeOrange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildStatutRow() {
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: StatutItem(
              icon: Icons.cancel_outlined,
              iconColor: kOccupeOrange,
              label: 'Statut',
              value: 'OCCUPÉ',
              valueColor: kOccupeOrange,
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

  Widget _buildCaracteristiques() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'CARACTÉRISTIQUES'),
          const SizedBox(height: 12),
          InfoRow(label: 'Type', value: unite.typeUnite.replaceAll('_', ' ')),
          const Divider(height: 16, color: kDivider),
          InfoRow(label: 'Douche', value: unite.typeDouche),
          const Divider(height: 16, color: kDivider),
          InfoRow(label: 'Garage', value: unite.garage ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  Widget _buildConditionsLocation() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'CONDITIONS DE LOCATION'),
          const SizedBox(height: 12),
          InfoRow(label: "Nombre d'avances", value: '${unite.nbrAvances} mois'),
          const Divider(height: 20, color: kDivider),
          InfoRow(label: 'Type de caution', value: unite.typeCaution.replaceAll('_', ' ')),
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

  Widget _buildLocataireActuel() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SectionTitle(title: 'LOCATAIRE ACTUEL'),
          SizedBox(height: 14),
          LocataireInfoRow(label: 'Nom', value: '—'),
          LocataireInfoRow(label: 'Contact', value: '—'),
          LocataireInfoRow(label: 'Email', value: '—'),
        ],
      ),
    );
  }

  Widget _buildContactProprietaire() {
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
                  onTap: () {
                    appeler(unite.contactProprietaire);
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: kLibreGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }


  Future<void> appeler(String numero) async {
  final Uri phoneUri = Uri(scheme: 'tel', path: numero);

  if (await canLaunchUrl(phoneUri)) {
    await launchUrl(phoneUri);
  } else {
    throw 'Impossible de lancer l\'appel';
  }
}
}
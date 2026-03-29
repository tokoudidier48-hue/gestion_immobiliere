import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/unitmodel.dart';


const Color kPrimary = Color(0xFF2563EB);
const Color kLibreGreen = Color(0xFF16A34A);
const Color kOccupeOrange = Color(0xFFEA580C);
const Color kBackground = Color(0xFFF3F4F6);
const Color kCardBg = Colors.white;
const Color kTextDark = Color(0xFF111827);
const Color kTextMid = Color(0xFF6B7280);
const Color kDeleteRed = Color(0xFFDC2626);
const Color kNavBorder = Color(0xFFE5E7EB);

// ─── Écran principal ─────────────────────────────────────────────────────────

class ChambresMaisonScreen extends StatefulWidget {
  const ChambresMaisonScreen({super.key});

  @override
  State<ChambresMaisonScreen> createState() => _ChambresMaisonScreenState();
}

class _ChambresMaisonScreenState extends State<ChambresMaisonScreen> {
  int _currentNavIndex = 2; // "Locataires" actif par défaut

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: units.length,
              itemBuilder: (context, index) {
                return _UnitCard(unit: units[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: kTextDark, size: 20),
        onPressed: () {},
      ),
      title: const Text(
        'Chambres de la Maison 1',
        style: TextStyle(
          color: kTextDark,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kNavBorder),
      ),
    );
  }

  // ── En-tête de la liste ─────────────────────────────────────────────────────

  Widget _buildListHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Liste des unités',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gérez les occupations et les détails de vos unités.',
            style: TextStyle(
              fontSize: 13,
              color: kTextMid,
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de navigation ─────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    // 🔹 BOTTOM NAVBAR
    return  NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home), 
            label: "Accueil",
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment), 
            label: "Mes Biens",
          ),
          NavigationDestination(
            icon: Icon(Icons.people), 
            label: "Locataires",
          ),
          NavigationDestination(
            icon: Icon(Icons.message), 
            label: "Messages",
          )
        ]
      );
  }

  Widget _buildNavItem(_NavItem item) {
    final bool isActive = _currentNavIndex == item.index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = item.index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isActive ? kPrimary : kTextMid,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? kPrimary : kTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Carte d'unité ────────────────────────────────────────────────────────────

class _UnitCard extends StatelessWidget {
  final UnitModel unit;

  const _UnitCard({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _UnitImage(imageKey: unit.imagePath),
            ),
            const SizedBox(width: 12),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + Badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          unit.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusBadge(status: unit.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Locataire ou statut
                  if (unit.status == UnitStatus.occupe && unit.locataire != null)
                    Text(
                      'Locataire: ${unit.locataire}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextMid,
                      ),
                    )
                  else if (unit.statusDetail != null)
                    Text(
                      'Statut: ${unit.statusDetail}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: kTextMid,
                      ),
                    ),
                  const SizedBox(height: 10),
                  // Boutons
                  Row(
                    children: [
                      _ActionButton(
                        label: 'Détail',
                        isPrimary: true,
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Modifier',
                        isPrimary: false,
                        onPressed: () {},
                      ),
                      const Spacer(),
                      // Bouton supprimer
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kDeleteRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: kDeleteRed,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge de statut ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final UnitStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isLibre = status == UnitStatus.libre;
    final Color bgColor = isLibre
        ? kLibreGreen.withOpacity(0.12)
        : kOccupeOrange.withOpacity(0.12);
    final Color textColor = isLibre ? kLibreGreen : kOccupeOrange;
    final String label = isLibre ? 'LIBRE' : 'OCCUPÉ';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Bouton d'action ──────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? kPrimary : Colors.transparent,
          border: Border.all(
            color: isPrimary ? kPrimary : const Color(0xFFD1D5DB),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isPrimary ? Colors.white : kTextDark,
          ),
        ),
      ),
    );
  }
}

// ─── Image de l'unité (placeholder coloré avec icône) ────────────────────────

class _UnitImage extends StatelessWidget {
  final String imageKey;

  const _UnitImage({required this.imageKey});

  // Associe chaque unité à une couleur et une icône
  static const Map<String, _ImageMeta> _meta = {
    'apt_f3': _ImageMeta(Color(0xFFBFDBFE), Icons.apartment, Color(0xFF3B82F6)),
    'boutique_rdc': _ImageMeta(Color(0xFFFED7AA), Icons.storefront, Color(0xFFF97316)),
    'chambre_salon': _ImageMeta(Color(0xFFD1FAE5), Icons.chair, Color(0xFF10B981)),
    'studio_meuble': _ImageMeta(Color(0xFFE9D5FF), Icons.bed, Color(0xFF8B5CF6)),
    'local_commercial': _ImageMeta(Color(0xFFFEE2E2), Icons.store, Color(0xFFEF4444)),
    'apt_t2': _ImageMeta(Color(0xFFCFFAFE), Icons.home, Color(0xFF06B6D4)),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _meta[imageKey] ??
        const _ImageMeta(Color(0xFFE5E7EB), Icons.home_work, Color(0xFF6B7280));

    return Container(
      width: 72,
      height: 72,
      color: meta.bgColor,
      child: Center(
        child: Icon(meta.icon, color: meta.iconColor, size: 32),
      ),
    );
  }
}

class _ImageMeta {
  final Color bgColor;
  final IconData icon;
  final Color iconColor;

  const _ImageMeta(this.bgColor, this.icon, this.iconColor);
}

// ─── Modèle nav ───────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  _NavItem({required this.icon, required this.label, required this.index});
}
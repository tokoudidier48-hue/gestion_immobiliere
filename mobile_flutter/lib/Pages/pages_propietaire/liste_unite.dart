import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/creer_unite.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/detail_unite_occupee.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/detail_unite_libre.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/modifier_ch_libre.dart';
import 'package:mobile_flutter/model/unitmodel.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

const Color kPrimary = Color(0xFF2563EB);
const Color kLibreGreen = Color(0xFF16A34A);
const Color kOccupeOrange = Color(0xFFEA580C);
const Color kBackground = Color(0xFFF3F4F6);
const Color kCardBg = Colors.white;
const Color kTextDark = Color(0xFF111827);
const Color kTextMid = Color(0xFF6B7280);
const Color kDeleteRed = Color(0xFFDC2626);
const Color kNavBorder = Color(0xFFE5E7EB);

// ─── Écran principal ──────────────────────────────────────────────────────────

class ChambresMaisonScreen extends StatefulWidget {
  final int proprieteId;
  final String nomPropriete;

  const ChambresMaisonScreen({super.key, required this.proprieteId, required this.nomPropriete});

  @override
  State<ChambresMaisonScreen> createState() => _ChambresMaisonScreenState();
}

class _ChambresMaisonScreenState extends State<ChambresMaisonScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UniteProvider>(context, listen: false)
          .fetchUnitesByPropriete(widget.proprieteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: _buildAppBar(),
      body: Consumer<UniteProvider>(
        builder: (context, uniteProvider, child) {
          if (uniteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (uniteProvider.error != null) {
            return Center(child: Text("Erreur: ${uniteProvider.error}"));
          }

          final unitsMaison = uniteProvider.unites
              .where((u) => u.proprieteId == widget.proprieteId)
              .toList();

          if (unitsMaison.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Aucune unité pour cette maison',
                      style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListHeader(unitsMaison.length),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: unitsMaison.length,
                  itemBuilder: (context, index) {
                    return _UnitCard(unit: unitsMaison[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: kTextDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.nomPropriete,
        style: const TextStyle(color: kTextDark, fontSize: 17, fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      actions: [
            Container(
              margin: const EdgeInsets.only(right: 14),
              child: FloatingActionButton.small(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) =>  CreerUnite(idPropriete: widget.proprieteId)),
                  );
                },
                backgroundColor: kPrimary,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kNavBorder),
      ),
    );
  }

  Widget _buildListHeader(int count) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Liste des unités ($count)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextDark),
          ),
          const SizedBox(height: 4),
          Text(
            'Gérez les occupations et les détails de vos unités.',
            style: TextStyle(fontSize: 13, color: kTextMid),
          ),
        ],
      ),
    );
  }
}

// ─── Carte d'unité ────────────────────────────────────────────────────────────

class _UnitCard extends StatelessWidget {
  final Unites unit;

  const _UnitCard({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
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
              child: _UnitImage(imageKey: unit.typeUnite),
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
                          unit.nomUnite,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTextDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusBadge(
                        status: unit.statut == 'libre' ? UnitStatus.libre : UnitStatus.occupe,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${unit.adresse}, ${unit.ville} — ${unit.loyer.toInt()} FCFA/mois',
                    style: const TextStyle(fontSize: 12, color: kTextMid),
                  ),
                  const SizedBox(height: 10),
                  // Boutons
                  Row(
                    children: [
                      _ActionButton(
                        label: 'Détail',
                        isPrimary: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => unit.statut == 'libre'
                                  ? DetailUniteScreen(unite: unit)
                                  : DetailUniteScreenn(unite: unit),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        label: 'Modifier',
                        isPrimary: false,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ModifierChambrePageLibre(unite: unit,),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      // Bouton supprimer
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Supprimer'),
                              content: Text('Supprimer "${unit.nomUnite}" ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await context.read<UniteProvider>().supprimerUnite(unit.id!);
                          }
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: kDeleteRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.delete_outline, color: kDeleteRed, size: 16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isLibre ? kLibreGreen.withOpacity(0.12) : kOccupeOrange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isLibre ? 'LIBRE' : 'OCCUPÉ',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isLibre ? kLibreGreen : kOccupeOrange,
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

  const _ActionButton({required this.label, required this.isPrimary, required this.onPressed});

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

// ─── Image de l'unité ────────────────────────────────────────────────────────

class _UnitImage extends StatelessWidget {
  final String imageKey;

  const _UnitImage({required this.imageKey});

  static const Map<String, _ImageMeta> _meta = {
    'appartement': _ImageMeta(Color(0xFFBFDBFE), Icons.apartment, Color(0xFF3B82F6)),
    'boutique': _ImageMeta(Color(0xFFFED7AA), Icons.storefront, Color(0xFFF97316)),
    'chambre_salon_ordinaire': _ImageMeta(Color(0xFFD1FAE5), Icons.chair, Color(0xFF10B981)),
    'chambre_salon_sanitaire': _ImageMeta(Color(0xFFD1FAE5), Icons.shower, Color(0xFF10B981)),
    'entree_coucher_ordinaire': _ImageMeta(Color(0xFFE9D5FF), Icons.bed, Color(0xFF8B5CF6)),
    'entree_coucher_sanitaire': _ImageMeta(Color(0xFFE9D5FF), Icons.bed, Color(0xFF8B5CF6)),
    'deux_chambres_ordinaire': _ImageMeta(Color(0xFFFEE2E2), Icons.home, Color(0xFFEF4444)),
    'deux_chambres_sanitaire': _ImageMeta(Color(0xFFFEE2E2), Icons.home, Color(0xFFEF4444)),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _meta[imageKey] ??
        const _ImageMeta(Color(0xFFE5E7EB), Icons.home_work, Color(0xFF6B7280));

    return Container(
      width: 72,
      height: 72,
      color: meta.bgColor,
      child: Center(child: Icon(meta.icon, color: meta.iconColor, size: 32)),
    );
  }
}

class _ImageMeta {
  final Color bgColor;
  final IconData icon;
  final Color iconColor;

  const _ImageMeta(this.bgColor, this.icon, this.iconColor);
}
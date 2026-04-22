import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/proprietaire/apiProprietaire.dart';

const Color kPrimaryLoc = Color(0xFF2563EB);

class LocatairesPage extends StatefulWidget {
  final int? proprieteId;
  final String? nomPropriete;

  const LocatairesPage({super.key, this.proprieteId, this.nomPropriete});

  @override
  State<LocatairesPage> createState() => _LocatairesPageState();
}

class _LocatairesPageState extends State<LocatairesPage> {
  final ApiProprietaire _api = ApiProprietaire();
  final _searchController = TextEditingController();
  List<dynamic> _locataires = [];
  List<dynamic> _paiementsEnAttente = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
  setState(() {
    _isLoading = true;
    _error = null;
  });

  try {
    await _fetchPaiementsEnAttente();

    await _fetchLocataires();
  } catch (e) {
    setState(() {
      _error = e.toString();
    });
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  Future<void> _fetchLocataires() async {
  try {
    final data = await _api.getLocataires(proprieteId: widget.proprieteId);
    setState(() => _locataires = data);
  } catch (e) {
    setState(() => _error = e.toString());
  }
}

  Future<void> _fetchPaiementsEnAttente() async {
  try {
    final data = await _api.getPaiementsEspece(
      proprieteId: widget.proprieteId,
    );

    setState(() {
      _paiementsEnAttente = data.where((p) =>
          p['mode_paiement'] == 'especes' &&
          p['statut'] == 'en_attente' // 🔥 IMPORTANT
      ).toList();
      print("Paiements en attente : $_paiementsEnAttente");
    });
  } catch (e) {
    print("ERREUR PAIEMENTS: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    final filtered = _locataires.where((l) {
      final nom = '${l['nom'] ?? ''} ${l['prenom'] ?? ''}'.toLowerCase();
      return _searchController.text.isEmpty ||
          nom.contains(_searchController.text.toLowerCase());
    }).toList();

    final locatairesAvecPaiement = filtered.where((l) {
      return _paiementsEnAttente.any((p) =>
         p['locataire'] == l['utilisateur']); // ou locataire_id selon ton API
    }).toList();

    final autresLocataires = filtered.where((l) {
      return !_paiementsEnAttente.any((p) =>
          p['locataire'] == l['utilisateur']);
    }).toList();

    final locatairesTries = [
      ...locatairesAvecPaiement,
      ...autresLocataires,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        shadowColor: Colors.transparent,
        leading: const BackButton(color: Color(0xFF111827)),
        centerTitle: true,
        title: Text(
          widget.nomPropriete != null
              ? 'Locataires de ${widget.nomPropriete}'
              : 'Mes locataires',
          style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 17,
              fontWeight: FontWeight.w600),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            child: FloatingActionButton.small(
              onPressed: _showAjouterLocataireDialog,
              backgroundColor: kPrimaryLoc,
              elevation: 0,
              child: const Icon(Icons.person_add_outlined,
                  color: Colors.white, size: 18),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
  child: Column(
    children: [

      // HEADER + SEARCH + BUTTON (OK)
       // ── SEARCH ─────────────────────────────
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un locataire...',
                            prefixIcon: Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),

// ── HEADER ─────────────────────────────
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Liste des locataires (${filtered.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gérez les locataires de votre propriété.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
/*
                       // 👇 ICI
    if (_paiementsEnAttente.isNotEmpty)
      Column(
        children: _paiementsEnAttente
            .map((p) => _buildPaiementAttenteCard(p))
            .toList(),
      ),
*/

      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: locatairesTries.length,
                    itemBuilder: (_, i) {
                      final locataire = locatairesTries[i];

                      final hasPaiement = _paiementsEnAttente.any(
                        (p) => p['locataire'] == locataire['utilisateur'],
                      );

                      return Column(
                        children: [
                          if (hasPaiement)
                            _buildPaiementAttenteCard(
                              _paiementsEnAttente.firstWhere(
                                (p) => p['locataire'] == locataire['utilisateur'],
                              ),
                            ),
                          _buildLocataireCard(locataire),
                        ],
                      );
                    },
                  ),
      ),
    ],
  ),
),
    );
  }

  Widget _buildLocataireCard(dynamic l) {
    print("Locataire: $l");
    final prenom = l['prenom'] ?? '';
    final nom = l['nom'] ?? '';
    final nomComplet =
        '$prenom $nom'.trim().isEmpty ? 'Inconnu' : '$prenom $nom'.trim();
    final unite = l['unite_nom']?.toString() ?? '';
    final loyer = l['loyer']?.toString() ?? l['montant']?.toString() ?? '0';

    final initiales = [prenom, nom]
        .where((e) => e.toString().isNotEmpty)
        .map((e) => e.toString()[0].toUpperCase())
        .join();

    // Couleurs selon l'index comme dans ChambresMaisonScreen
    final List<Color> avatarColors = [
      const Color(0xFFBFDBFE), // bleu
      const Color(0xFFD1FAE5), // vert
      const Color(0xFFE9D5FF), // violet
      const Color(0xFFFED7AA), // orange
      const Color(0xFFFEE2E2), // rouge
    ];
    final List<Color> iconColors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
      const Color(0xFFF97316),
      const Color(0xFFEF4444),
    ];
    final idx = ((l['id'] ?? 0) as int) % avatarColors.length;
    final bgColor = avatarColors[idx];
    final iconColor = iconColors[idx];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar coloré comme les icônes de ChambresMaisonScreen
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 72,
                height: 72,
                color: bgColor,
                child: l['photo_profil'] != null
                    ? Image.network(l['photo_profil'],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(initiales.isEmpty ? '?' : initiales,
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: iconColor)),
                        ))
                    : Center(
                        child: Text(initiales.isEmpty ? '?' : initiales,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: iconColor)),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom + loyer
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          nomComplet,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$loyer CFA',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unite,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 10),

                  // Boutons actions (même style que _ActionButton)
                  Row(
                    children: [
                      _locBtn('Voir détail', true,
                          () => _showDetailLocataire(l)),
                      const SizedBox(width: 8),
                      _locBtn('Modifier', false,
                          () => _showDetailLocataire(l)),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _confirmerSuppression(l),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Color(0xFFDC2626), size: 16),
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

  Widget _locBtn(String label, bool isPrimary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isPrimary ? kPrimaryLoc : Colors.transparent,
          border: Border.all(
            color: isPrimary ? kPrimaryLoc : const Color(0xFFD1D5DB),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isPrimary ? Colors.white : const Color(0xFF111827),
          ),
        ),
      ),
    );
  }

  Widget _buildPaiementAttenteCard(dynamic p) {
    final locataireNom = p['locataire_nom'] ?? 'Locataire';
    final montant = p['montant']?.toString() ?? '0';
    final uniteNom = p['unite_nom'] ?? '';
    final paiementId = p['id'];
    final initiales = (locataireNom as String)
    .split(' ')
    .take(2)
    .where((e) => (e as String).isNotEmpty)
    .map((e) => (e as String)[0].toUpperCase())
    .join();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.orange.withOpacity(0.15),
                child: Text(initiales,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(locataireNom,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(uniteNom,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$montant FCFA',
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text('Paiement en espèce — en attente',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _validerPaiementEspece(paiementId, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  child: const Text('Accepter',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _validerPaiementEspece(paiementId, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Refuser',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _validerPaiementEspece(int paiementId, bool accepter) async {
  try {
    if (accepter) {
      await _api.accepterPaiement(paiementId);
      // 🔥 refresh ordre correct
      await _fetchPaiementsEnAttente();
      await _fetchLocataires();
    } else {
      await _api.refuserPaiement(paiementId);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accepter
            ? 'Paiement accepté ! Locataire ajouté.'
            : 'Paiement refusé.'),
        backgroundColor: accepter ? Colors.green : Colors.orange,
      ),
    );

    // 🔥 recharge données
    _fetchAll();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  void _showAjouterLocataireDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AjouterLocataireSheet(
        proprieteId: widget.proprieteId,
        onAdded: _fetchLocataires,
      ),
    );
  }

  void _showDetailLocataire(dynamic l) {
    final nomComplet =
        '${l['nom'] ?? ''} ${l['prenom'] ?? ''}'.trim();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: kPrimaryLoc.withOpacity(0.1),
                  child: Text(
                    nomComplet.isNotEmpty
                        ? nomComplet[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryLoc),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nomComplet,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(l['email'] ?? '',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _detailRow(Icons.phone_outlined, 'Téléphone',
                l['telephone'] ?? '—'),
            _detailRow(Icons.home_outlined, 'Unité',
                l['unite_nom']?.toString() ?? '—'),
            _detailRow(Icons.payments_outlined, 'Loyer',
                '${l['loyer'] ?? l['montant'] ?? 0} FCFA / mois'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label : ',
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmerSuppression(dynamic l) async {
    final nomComplet =
        '${l['nom'] ?? ''} ${l['prenom'] ?? ''}'.trim();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce locataire ?'),
        content:
            Text('Voulez-vous retirer $nomComplet de cette propriété ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await _api.supprimerLocataire(l['id']);
        _fetchLocataires();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erreur : $e'),
                backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(_error ?? '', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _fetchLocataires,
                child: const Text('Réessayer')),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Aucun locataire pour le moment',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );
}

// ─── Sheet d'ajout manuel ─────────────────────────────────────────────────────

class _AjouterLocataireSheet extends StatefulWidget {
  final int? proprieteId;
  final VoidCallback onAdded;

  const _AjouterLocataireSheet(
      {this.proprieteId, required this.onAdded});

  @override
  State<_AjouterLocataireSheet> createState() =>
      _AjouterLocataireSheetState();
}

class _AjouterLocataireSheetState
    extends State<_AjouterLocataireSheet> {
  final ApiProprietaire _api = ApiProprietaire();
  final _emailController = TextEditingController();
  final _uniteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _uniteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('Ajouter un locataire',
              style:
                  TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInput('Email du locataire', _emailController,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          _buildInput("ID de l'unité", _uniteController,
              keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _ajouter,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryLoc,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Ajouter',
                      style: TextStyle(
                          color: Colors.white, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _ajouter() async {
    if (_emailController.text.trim().isEmpty ||
        _uniteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Remplissez tous les champs')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _api.ajouterLocataireManuel(
        email: _emailController.text.trim(),
        uniteId: int.parse(_uniteController.text.trim()),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Locataire ajouté !'),
          backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}


import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/historique_paiements.dart';
import 'package:mobile_flutter/Pages/pages_locataire/locataire_navbar.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

class PaiementPage extends StatefulWidget {
  final Map<String, dynamic>? unite;
  const PaiementPage({super.key, this.unite});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  static const _primaryColor = Color(0xFF1A3C6E);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DemandeProvider>().fetchDemandes());
  }

  @override
  Widget build(BuildContext context) {
    // Si une unité est passée directement → affiche le formulaire directement
    if (widget.unite != null) {
      return _PaiementFormPage(unite: widget.unite!);
    }

    // Sinon → affiche la liste des demandes acceptées
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Paiement',
            style: TextStyle(
                color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black54),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoriquePaiementsPage())),
          ),
        ],
      ),
      body: Consumer<DemandeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filtre uniquement les demandes acceptées
          final demandesAcceptees = provider.demandes
              .where((d) => d['statut'] == 'acceptee')
              .toList();

          if (demandesAcceptees.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payment_outlined,
                          size: 40, color: _primaryColor),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Aucune chambre disponible\npour le paiement',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.5),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vos demandes doivent être acceptées\npar le propriétaire avant de pouvoir payer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      onPressed: () => provider.fetchDemandes(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Actualiser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryColor,
                        side: const BorderSide(color: _primaryColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // En-tête
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _primaryColor.withOpacity(0.15)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: _primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${demandesAcceptees.length} chambre(s) prête(s) au paiement',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Liste des chambres acceptées
              ...demandesAcceptees.map((demande) =>
                  _buildChambreCard(context, demande)).toList(),
            ],
          );
        },
      ),
      bottomNavigationBar: const LocataireNavBar(selectedIndex: 3),
    );
  }

  Widget _buildChambreCard(BuildContext context, dynamic demande) {
    final uniteNom = demande['unite_nom'] ?? 'Chambre';
    final uniteType = demande['unite_type'] ?? '';
    final uniteLoyer = demande['unite_loyer']?.toString() ?? '0';
    final proprietaireNom = demande['proprietaire_nom'] ?? '';

    final initiales = uniteNom.isNotEmpty ? uniteNom[0].toUpperCase() : 'C';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _PaiementFormPage(unite: demande),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(initiales,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(uniteNom,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 3),
                    Text(uniteType.replaceAll('_', ' '),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                    const SizedBox(height: 3),
                    Text('$uniteLoyer FCFA / mois',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text(proprietaireNom,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('Payer',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios,
                        size: 10, color: Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Page formulaire de paiement ─────────────────────────────────────────────

class _PaiementFormPage extends StatefulWidget {
  final Map<String, dynamic> unite;
  const _PaiementFormPage({required this.unite});

  @override
  State<_PaiementFormPage> createState() => _PaiementFormPageState();
}

class _PaiementFormPageState extends State<_PaiementFormPage> {
  static const _primaryColor = Color(0xFF1A3C6E);

  int _selectedMainTab = 0;
  int _selectedPayment = 0;
  int _selectedMode = 0;
  final _phoneController = TextEditingController(text: '+229');

  final List<Map<String, dynamic>> _paymentOptions = [
    {'label': 'MoMo', 'color': const Color(0xFFFFCC00), 'textColor': Colors.black, 'code': 'mtn'},
    {'label': 'Moov', 'color': const Color(0xFF0066CC), 'textColor': Colors.white, 'code': 'moov'},
    {'label': 'Celtiis', 'color': const Color(0xFFE53935), 'textColor': Colors.white, 'code': 'celtiis'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _nom => widget.unite['unite_nom'] ?? widget.unite['nom'] ?? 'Logement';
  String get _loyer => widget.unite['unite_loyer']?.toString() ?? widget.unite['loyer']?.toString() ?? '0';
  String get _proprietaireNom => widget.unite['proprietaire_nom'] ?? '';
  int? get _uniteId => widget.unite['unite'] ?? widget.unite['id'];
  List get _photos => (widget.unite['photos'] as List?) ?? [];

  // Remplace les getters _montant et _caution dans _PaiementFormPageState

String get _caution => widget.unite['prix_caution']?.toString() ?? 
                       widget.unite['caution']?.toString() ?? '0';

double get _montant {
  final loyer = double.tryParse(_loyer) ?? 0;
  if (_selectedMainTab == 0) {
    // Avance = loyer × 3 (fixe)
    return loyer * 3;
  }
  return loyer;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text('Paiement LoyaSmart',
            style: TextStyle(
                color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black54),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoriquePaiementsPage())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMainTabs(),
            _buildLogementCard(),
            _buildModeToggle(),
            if (_selectedMode == 0) _buildFormEnLigne() else _buildFormEnEspece(),
            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: _buildBottomButton(),
    );
  }

  Widget _buildMainTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F2F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(2, (i) {
            final labels = ['Avance', 'Loyer'];
            final selected = _selectedMainTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedMainTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLogementCard() {
    final image = _photos.isNotEmpty ? (_photos[0]['image'] ?? '') : '';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: image.isNotEmpty
                ? Image.network(image,
                    height: 140, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_nom,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Text('$_loyer FCFA',
                        style: const TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
                if (_proprietaireNom.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(_proprietaireNom,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Caution : $_caution FCFA',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
      height: 140,
      color: Colors.grey.shade200,
      child: const Icon(Icons.apartment, size: 50, color: Colors.grey));

  Widget _buildModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            _modeBtn(0, Icons.wifi, 'En ligne'),
            _modeBtn(1, Icons.money, 'En espèce'),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn(int index, IconData icon, String label) {
    final selected = _selectedMode == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : Colors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormEnLigne() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedMainTab == 0 ? "Détails de l'avance" : "Détails du loyer",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Text(
            _selectedMainTab == 0 ? 'PRIX DES AVANCES (FCFA)' : 'PRIX DU LOYER (FCFA)',
            style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          _readonlyField(_montant.toInt().toString()),
          if (_selectedMainTab == 0) ...[
            const SizedBox(height: 14),
            const Text('PRIX DE LA CAUTION (FCFA)',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            const SizedBox(height: 6),
            _readonlyField(_caution),
          ],
          const SizedBox(height: 20),
          const Text('CHOIX DU MODE DE PAIEMENT',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_paymentOptions.length, (i) {
              final selected = _selectedPayment == i;
              final opt = _paymentOptions[i];
              return GestureDetector(
                onTap: () => setState(() => _selectedPayment = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: opt['color'] as Color,
                    borderRadius: BorderRadius.circular(10),
                    border: selected ? Border.all(color: Colors.black, width: 2) : null,
                    boxShadow: selected
                        ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6)]
                        : null,
                  ),
                  child: Text(opt['label'] as String,
                      style: TextStyle(
                          color: opt['textColor'] as Color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Text('NUMÉRO DE TÉLÉPHONE',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: _primaryColor, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormEnEspece() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PAIEMENT EN ESPÈCE',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Votre demande sera envoyée au propriétaire qui devra confirmer la réception du paiement en espèce.',
                    style: TextStyle(fontSize: 12, color: Colors.orange, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('MONTANT À PAYER (FCFA)',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          _readonlyField(_montant.toInt().toString()),
        ],
      ),
    );
  }

  Widget _readonlyField(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Consumer<PaiementProvider>(
        builder: (context, provider, child) {
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: provider.isLoading ? null : () => _handlePaiement(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _selectedMode == 0 ? 'Payer maintenant' : 'Valider',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
            ),
          );
        },
      ),
    );
  }

  void _handlePaiement(PaiementProvider provider) async {
    final id = _uniteId;
    print("==> ID envoyé au backend : $id");
  print("==> Données complètes unité : ${widget.unite}");
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unité introuvable')));
      return;
    }

    if (_selectedMode == 0) {
      final success = await provider.effectuerPaiement(
        uniteId: id,
        montant: _montant,
        modePaiement: _paymentOptions[_selectedPayment]['code'],
        numeroPaiement: _phoneController.text.trim(),
        typePaiement: _selectedMainTab == 0 ? 'avance' : 'loyer',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Paiement effectué !' : 'Erreur : ${provider.error}'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) Navigator.pop(context);
    } else {
      final success = await provider.demanderPaiementEspece(
        uniteId: id,
        montant: _montant,
        typePaiement: _selectedMainTab == 0 ? 'avance' : 'loyer',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Demande envoyée ! En attente de confirmation du propriétaire.'
            : 'Erreur : ${provider.error}'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
      if (success) Navigator.pop(context);
    }
  }
}
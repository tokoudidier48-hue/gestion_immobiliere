import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/historique_paiements.dart';
import 'package:mobile_flutter/Pages/pages_locataire/locataire_navbar.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

class PaiementPage extends StatefulWidget {
  const PaiementPage({super.key});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  static const _primaryColor = Color(0xFF1A3C6E);

  int _selectedMainTab = 0;
  int _selectedPayment = 0;
  final _phoneController = TextEditingController(text: '+229');

  final List<Map<String, dynamic>> _paymentOptions = [
    {'label': 'MoMo', 'color': const Color(0xFFFFCC00), 'textColor': Colors.black, 'code': 'momo'},
    {'label': 'Moov', 'color': const Color(0xFF0066CC), 'textColor': Colors.white, 'code': 'moov'},
    {'label': 'Celtiis', 'color': const Color(0xFFE53935), 'textColor': Colors.white, 'code': 'celtiis'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PaiementProvider>().fetchPaiements());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
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
        title: const Text('Paiement LoyaSmart',
            style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black54),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoriquePaiementsPage()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PaiementProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildMainTabs(),
                if (provider.paiements.isNotEmpty) _buildLogementCard(provider.paiements.first),
                _buildFormSection(provider),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
      bottomSheet: _buildBottomButton(),
      bottomNavigationBar: const LocataireNavBar(selectedIndex: 3),
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
                        fontSize: 14,
                      )),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildLogementCard(dynamic paiement) {
    final unite = paiement['unite_details'] ?? {};
    final photos = (unite['photos'] as List?) ?? [];
    final image = photos.isNotEmpty ? photos[0]['image'] ?? '' : '';
    final nom = unite['nom'] ?? 'Logement';
    final adresse = '${unite['ville'] ?? ''}, ${unite['adresse'] ?? ''}';
    final loyer = unite['loyer']?.toString() ?? '0';
    final caution = unite['prix_caution']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: image.isNotEmpty
                ? Image.network(image, height: 140, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140, color: Colors.grey.shade200,
                      child: const Icon(Icons.apartment, size: 50, color: Colors.grey),
                    ))
                : Container(height: 140, color: Colors.grey.shade200,
                    child: const Icon(Icons.apartment, size: 50, color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(nom,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    Text('$loyer FCFA',
                        style: const TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: Colors.grey),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(adresse,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Caution: $caution FCFA',
                      style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(PaiementProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
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

          if (provider.paiements.isNotEmpty) ...[
            _buildInputField(
              label: 'MONTANT (FCFA)',
              value: _selectedMainTab == 0
                  ? (provider.paiements.first['unite_details']?['prix_caution']?.toString() ?? '0')
                  : (provider.paiements.first['unite_details']?['loyer']?.toString() ?? '0'),
              icon: Icons.content_copy_outlined,
            ),
            const SizedBox(height: 14),
          ],

          const Text('CHOIX DU MODE DE PAIEMENT',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 12),
          _buildPaymentOptions(),
          const SizedBox(height: 20),

          const Text('NUMÉRO DE TÉLÉPHONE',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: _primaryColor, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
              Icon(icon, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentOptions() {
    return Row(
      children: List.generate(_paymentOptions.length, (i) {
        final selected = _selectedPayment == i;
        final opt = _paymentOptions[i];
        return GestureDetector(
          onTap: () => setState(() => _selectedPayment = i),
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                    color: opt['textColor'] as Color, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        );
      }),
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
              onPressed: provider.isLoading ? null : () async {
                if (provider.paiements.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Aucun logement actif trouvé')),
                  );
                  return;
                }

                final unite = provider.paiements.first['unite_details'] ?? {};
                final montant = _selectedMainTab == 0
                    ? unite['prix_caution']
                    : unite['loyer'];

                final success = await provider.effectuerPaiement({
                  'unite': unite['id'],
                  'type': _selectedMainTab == 0 ? 'avance' : 'loyer',
                  'montant': montant,
                  'mode_paiement': _paymentOptions[_selectedPayment]['code'],
                  'telephone': _phoneController.text.trim(),
                });

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Paiement effectué !' : 'Erreur : ${provider.error}'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: provider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Payer maintenant',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/paiement.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

class DetailsLogementDepuisDemandePage extends StatefulWidget {
  final dynamic demande;
  const DetailsLogementDepuisDemandePage({super.key, required this.demande});

  @override
  State<DetailsLogementDepuisDemandePage> createState() =>
      _DetailsLogementDepuisDemandePage();
}

class _DetailsLogementDepuisDemandePage
    extends State<DetailsLogementDepuisDemandePage> {
  @override
  Widget build(BuildContext context) {
    final d = widget.demande;
    final statut = d['statut'] ?? 'en_attente';
    final uniteNom = d['unite_nom'] ?? '';
    final uniteType = d['unite_type'] ?? '';
    final uniteLoyer = d['unite_loyer']?.toString() ?? '0';
    final proprietaireNom = d['proprietaire_nom'] ?? '';
    final message = d['message'] ?? '';
    final uniteId = d['unite'];
    final demandeId = d['id'];
    final photoPath = d['unite_photo']?.toString() ?? '';
    const baseUrl = 'http://10.199.70.129:8000';
    final fullImageUrl = photoPath.isNotEmpty
        ? (photoPath.startsWith('http') ? photoPath : '$baseUrl$photoPath')
        : '';

    Color statutColor;
    String statutLabel;
    String statutDesc;
    switch (statut) {
      case 'acceptee':
        statutColor = Colors.green;
        statutLabel = 'Acceptée ✅';
        statutDesc = 'Votre demande a été acceptée. Vous pouvez effectuer le paiement.';
        break;
      case 'refusee':
        statutColor = Colors.red;
        statutLabel = 'Refusée ❌';
        statutDesc = 'Votre demande a été refusée par le propriétaire.';
        break;
      default:
        statutColor = Colors.orange;
        statutLabel = 'En attente ⏳';
        statutDesc = 'Votre demande est en cours de traitement.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text('Détails de la demande',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
child: Column(
  
  children: [
    if (fullImageUrl.isNotEmpty)
  Container(
    margin: const EdgeInsets.only(bottom: 14),
    height: 160,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.grey.shade200,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        fullImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
            Icons.apartment, size: 60, color: Colors.grey),
      ),
    ),
  ),
    // ── STATUT ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statutColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statutColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: statutColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statut == 'acceptee'
                              ? Icons.check_circle_outline
                              : statut == 'refusee'
                                  ? Icons.cancel_outlined
                                  : Icons.hourglass_empty,
                          color: statutColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statutLabel,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: statutColor)),
                            const SizedBox(height: 4),
                            Text(statutDesc,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── INFOS UNITÉ ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LOGEMENT',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 12),
                  _infoRow(Icons.home_outlined, 'Nom', uniteNom),
                  const Divider(height: 20),
                  _infoRow(Icons.category_outlined, 'Type', uniteType),
                  const Divider(height: 20),
                  _infoRow(Icons.payments_outlined, 'Loyer',
                      '$uniteLoyer FCFA / mois'),
                  const Divider(height: 20),
                  _infoRow(
                      Icons.person_outline, 'Propriétaire', proprietaireNom),
                ],
              ),
            ),

            if (message.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VOTRE MESSAGE',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.8)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F6FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.5)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── BOUTON SELON STATUT ────────────────────────────────
            if (statut == 'acceptee')
              _buildBoutonPaiement(context, uniteId, demandeId, uniteLoyer)
            else if (statut == 'en_attente')
              _buildBoutonEnAttente()
            else
              _buildBoutonRefuse(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBoutonPaiement(BuildContext context, int uniteId, int demandeId, String loyer) {
  return SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton.icon(
      onPressed: () {
        // ← passe les infos de l'unité à PaiementPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaiementPage(unite: widget.demande),
          ),
        );
      },
      icon: const Icon(Icons.payment_outlined, color: Colors.white),
      label: const Text('Effectuer le paiement',
          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A3C6E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

  Widget _buildBoutonEnAttente() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange, size: 20),
          SizedBox(width: 8),
          Text('Demande en cours de traitement',
              style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBoutonRefuse() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text('Demande refusée',
              style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showPaiementDialog(BuildContext context, PaiementProvider provider,
      int uniteId, String loyer) {
    final montantController =
        TextEditingController(text: loyer);
    final numeroController = TextEditingController();
    String modePaiement = 'mtn';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Effectuer le paiement',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Montant
                const Text('Montant (FCFA)',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: montantController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 14),

                // Mode de paiement
                const Text('Mode de paiement',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Row(
                  children: ['mtn', 'moov', 'especes'].map((mode) {
                    final labels = {
                      'mtn': 'MTN',
                      'moov': 'Moov',
                      'especes': 'Espèces'
                    };
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setStateDialog(() => modePaiement = mode),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: modePaiement == mode
                                ? const Color(0xFF1A3C6E)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              labels[mode]!,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: modePaiement == mode
                                      ? Colors.white
                                      : Colors.black87),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Numéro de paiement
                const Text('Numéro / Référence',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 6),
                TextField(
                  controller: numeroController,
                  decoration: InputDecoration(
                    hintText: 'Ex: MTN123456',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await provider.effectuerPaiement(
                  uniteId: uniteId,
                  montant: double.tryParse(montantController.text) ?? 0,
                  modePaiement: modePaiement,
                  numeroPaiement: numeroController.text.trim(),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success
                      ? 'Paiement effectué avec succès !'
                      : 'Erreur : ${provider.error}'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E)),
              child: const Text('Payer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 10),
        Text('$label : ',
            style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Config/app_config.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile_flutter/service/proprietaire/apiProprietaire.dart';

class EvolutionFinancesPage extends StatefulWidget {
  const EvolutionFinancesPage({super.key});

  @override
  State<EvolutionFinancesPage> createState() => _EvolutionFinancesPageState();
}

class _EvolutionFinancesPageState extends State<EvolutionFinancesPage> {
  static const _primaryColor = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<FinanceProvider>().fetchSolde();
      context.read<FinanceProvider>().fetchHistoriqueRetraits();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Mes Finances',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchSolde();
              await provider.fetchHistoriqueRetraits();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── SOLDE CARD ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1A3C6E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'SOLDE DISPONIBLE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        provider.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(
                                '${_formatMontant(provider.solde)} FCFA',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                        const SizedBox(height: 4),
                        const Text(
                          'Revenus collectés via LoyaSmart',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Bouton retrait
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: provider.isLoading
                                ? null
                                : () => _showRetraitDialog(context, provider),
                            icon: const Icon(Icons.send_to_mobile,
                                size: 18, color: _primaryColor),
                            label: const Text(
                              'Retirer mes fonds',
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── HISTORIQUE RETRAITS ────────────────────────────────
                  const Text(
                    'Historique des retraits',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (provider.historiqueRetraits.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.history,
                              size: 50, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun retrait effectué',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...provider.historiqueRetraits
                        .map((r) => _buildRetraitCard(context, r))
                        .toList(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRetraitCard(BuildContext context, dynamic retrait) {
    final id = retrait['id'];
    final montant = retrait['montant'];
    final operateur = retrait['operateur'] ?? '';
    final telephone = retrait['telephone'] ?? '';
    final dateStr = retrait['date_generation'] ?? '';
    final fichierPdf = retrait['fichier_pdf'] ?? '';

    String operateurLabel;
    Color operateurColor;
    switch (operateur) {
      case 'mtn':
        operateurLabel = 'MTN MoMo';
        operateurColor = const Color(0xFFFFCC00);
        break;
      case 'moov':
        operateurLabel = 'Moov Money';
        operateurColor = const Color(0xFF0066CC);
        break;
      case 'celtis':
        operateurLabel = 'Celtiis Cash';
        operateurColor = const Color(0xFFE53935);
        break;
      default:
        operateurLabel = operateur.toUpperCase();
        operateurColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône opérateur
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: operateurColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.send_to_mobile,
                color: operateurColor, size: 22),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatMontant(montant?.toDouble() ?? 0)} FCFA',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: operateurColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        operateurLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: operateurColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      telephone,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(dateStr),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          // Bouton PDF
          if (fichierPdf.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf,
                  color: Colors.red, size: 24),
              tooltip: 'Télécharger le reçu PDF',
              onPressed: () => _telechargerPdf(context, id),
            ),
        ],
      ),
    );
  }

  void _showRetraitDialog(BuildContext context, FinanceProvider provider) {
    final montantController = TextEditingController();
    final telephoneController = TextEditingController(text: '(+229)');
    String operateur = 'mtn';

    final operateurs = [
      {'code': 'mtn', 'label': 'MTN MoMo', 'color': const Color(0xFFFFCC00)},
      {'code': 'moov', 'label': 'Moov Money', 'color': const Color(0xFF0066CC)},
      {'code': 'celtis', 'label': 'Celtiis Cash', 'color': const Color(0xFFE53935)},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Retirer mes fonds',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Solde disponible : ${_formatMontant(provider.solde)} FCFA',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 20),

              // Montant
              const Text(
                'MONTANT (FCFA)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: montantController,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade300, fontSize: 20),
                  suffixText: 'FCFA',
                  suffixStyle: TextStyle(color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius:
                        BorderRadius.all(Radius.circular(10)),
                    borderSide:
                        BorderSide(color: _primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Téléphone
              const Text(
                'NUMÉRO DE TÉLÉPHONE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: telephoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius:
                        BorderRadius.all(Radius.circular(10)),
                    borderSide:
                        BorderSide(color: _primaryColor, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Opérateur
              const Text(
                'OPÉRATEUR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              
              SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child:Row(
                children: operateurs.map((op) {
                  final selected = operateur == op['code'];
                  final color = op['color'] as Color;
                  return GestureDetector(
                    onTap: () =>
                        setModalState(() => operateur = op['code'] as String),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        op['label'] as String,
                        style: TextStyle(
                          color: op['code'] == 'mtn'
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
              const SizedBox(height: 24),

              // Bouton valider
              Consumer<FinanceProvider>(
                builder: (ctx2, prov, _) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: prov.isRetrait
                        ? null
                        : () async {
                            final montantText =
                                montantController.text.trim();
                            final telephone =
                                telephoneController.text.trim();

                            if (montantText.isEmpty || telephone.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Veuillez remplir tous les champs'),
                                ),
                              );
                              return;
                            }

                            final montant =
                                double.tryParse(montantText) ?? 0;
                            if (montant <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Montant invalide'),
                                ),
                              );
                              return;
                            }

                            if (montant > prov.solde) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Solde insuffisant'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final result = await prov.demanderRetrait(
                              montant: montant,
                              telephone: telephone,
                              operateur: operateur,
                            );

                            if (!context.mounted) return;
                            Navigator.pop(ctx);

                            if (result != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      '✅ Retrait initié avec succès !'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Erreur : ${prov.error}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: prov.isRetrait
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : const Text(
                            'Valider le retrait',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _telechargerPdf(BuildContext context, int recuId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement en cours...')),
      );
      final api = ApiProprietaire();
      final bytes = await api.telechargerPdfRetrait(recuId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/recu_retrait_$recuId.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur téléchargement : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatMontant(double montant) {
    return montant
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} à ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }
}
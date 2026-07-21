import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/detail_recu.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';

class HistoriquePaiementsPage extends StatefulWidget {
  const HistoriquePaiementsPage({super.key});

  @override
  State<HistoriquePaiementsPage> createState() =>
      _HistoriquePaiementsPageState();
}

class _HistoriquePaiementsPageState extends State<HistoriquePaiementsPage> {
  static const _primaryColor = Color(0xFF1A3C6E);
  final ApiLocataire _api = ApiLocataire();
  List<dynamic> _paiements = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPaiements();
  }

  Future<void> _fetchPaiements() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _api.getHistoriquePaiements();
      if (!mounted) return;
      // ← Trie par date décroissante
      data.sort((a, b) {
        final da = DateTime.tryParse(a['date_paiement'] ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b['date_paiement'] ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });
      setState(() => _paiements = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text('Historique Paiements',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: _fetchPaiements,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _paiements.isEmpty
                  ? _buildEmpty()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Row(
                            children: [
                              const Text(
                                'DERNIÈRES TRANSACTIONS',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                    letterSpacing: 1.2),
                              ),
                              const Spacer(),
                              Text(
                                '${_paiements.length} paiement(s)',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _paiements.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _buildPaiementCard(
                                    context, _paiements[index]),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildPaiementCard(BuildContext context, dynamic p) {
    print("Valeur montant : ${p['montant']}");
print("Type montant : ${p['montant'].runtimeType}");
    final String typePaiement = (p['type_paiement'] ?? '').toString();
    final String modePaiement = (p['mode_paiement'] ?? '').toString();
    final String statut = (p['statut'] ?? '').toString().toLowerCase().trim();
    final dynamic montant = p['montant'];

final num montantNum = montant is num
    ? montant
    : num.tryParse(montant.toString()) ?? 0;
    final String uniteNom = (p['unite_nom'] ?? '').toString();
    final String datePaiement = _formatDate(p['date_paiement'] ?? '');
    final int paiementId = p['id'] ?? 0;
  
    final bool isAvance = typePaiement == 'avance';
    final bool isEspece = modePaiement == 'especes';

    final bool isReussi = statut == 'reussi' ||
        statut == 'valide' ||
        statut == 'confirme' ||
        statut == 'confirmed' ||
        statut == 'success' ||
        statut == 'completed' ||
        statut == 'paid' ||
        statut == 'paye';

    final bool isEnAttente = statut == 'en_attente' ||
        statut == 'pending' ||
        statut == 'attente';

    final bool isEchoue = statut == 'echoue' ||
        statut == 'failed' ||
        statut == 'refuse' ||
        statut == 'annule';

    Color statutColor;
    String statutLabel;
    IconData statutIcon;

    if (isReussi) {
      statutColor = Colors.green;
      statutLabel = 'PAYÉ';
      statutIcon = Icons.check_circle_outline;
    } else if (isEnAttente) {
      statutColor = Colors.orange;
      statutLabel = isEspece ? 'EN ATTENTE PROPRIO' : 'EN ATTENTE';
      statutIcon = Icons.hourglass_empty;
    } else if (isEchoue) {
      statutColor = Colors.red;
      statutLabel = 'ÉCHOUÉ';
      statutIcon = Icons.cancel_outlined;
    } else {
      statutColor = Colors.orange;
      statutLabel = statut.isEmpty ? 'EN COURS' : statut.toUpperCase();
      statutIcon = Icons.info_outline;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailRecuPage(
              paiementId: paiementId,
              paiement: p,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isAvance
                    ? Colors.orange.withOpacity(0.12)
                    : _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isAvance
                    ? Icons.lock_outline
                    : Icons.calendar_today_outlined,
                color: isAvance ? Colors.orange : _primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAvance ? 'Avance sur loyer' : 'Loyer mensuel',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 3),
                  Text(uniteNom,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(datePaiement,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400)),
                  if (isEspece) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('💵 Espèces',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${montantNum.toInt()} FCFA',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isAvance ? Colors.orange : _primaryColor),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statutIcon,
                          color: statutColor, size: 10),
                      const SizedBox(width: 3),
                      Text(statutLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statutColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios,
                color: Colors.grey.shade300, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(_error ?? '',
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _fetchPaiements,
                child: const Text('Réessayer')),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Aucun paiement effectué',
                style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      final months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
        'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }
}
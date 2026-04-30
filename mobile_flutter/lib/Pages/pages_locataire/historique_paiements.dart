import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/detail_recu.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';

class HistoriquePaiementsPage extends StatefulWidget {
  const HistoriquePaiementsPage({super.key});

  @override
  State<HistoriquePaiementsPage> createState() => _HistoriquePaiementsPageState();
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
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _api.getHistoriquePaiements();
      if (!mounted) return;
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
            style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700)),
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
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                          child: Text('DERNIÈRES TRANSACTIONS',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                  letterSpacing: 1.2)),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _paiements.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _buildPaiementCard(context, _paiements[index]),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildPaiementCard(BuildContext context, dynamic p) {
  final String typePaiement = (p['type_paiement'] ?? '').toString();
  final String modePaiement = (p['mode_paiement'] ?? '').toString();
  final String statut = (p['statut'] ?? '').toString();
  final String montant = (p['montant'] ?? 0).toString();
  final String uniteNom = (p['unite_nom'] ?? '').toString();
  final String datePaiement = _formatDate(p['date_paiement'] ?? '');
  final int? recuId = p['recu_id'] ?? p['id'];

  final bool isAvance = typePaiement == 'avance';
  final bool isEspece = modePaiement == 'especes';

  // ← Correction : accepte tous les statuts positifs possibles du backend
  final bool isReussi = statut == 'reussi' ||
                        statut == 'valide' ||
                        statut == 'confirme' ||
                        statut == 'success' ||
                        statut == 'completed';
  final bool isEnAttente = statut == 'en_attente' ||
                           statut == 'pending' ||
                           statut == 'attente';

  Color statutColor;
  String statutLabel;
  if (isReussi) {
    statutColor = Colors.green;
    statutLabel = 'PAYÉ';
  } else if (isEnAttente) {
    statutColor = Colors.orange;
    statutLabel = 'EN ATTENTE';
  } else {
    // Debug — affiche le vrai statut pour identifier le problème
    print("==> Statut inconnu : '$statut'");
    statutColor = Colors.orange;
    statutLabel = statut.toUpperCase().isEmpty ? 'EN COURS' : statut.toUpperCase();
  }

  return GestureDetector(
    onTap: () {
      if (recuId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailRecuPage(paiementId: recuId, paiement: p),
          ),
        );
      }
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isAvance
                  ? Colors.orange.withOpacity(0.12)
                  : _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isAvance ? Icons.lock_outline : Icons.calendar_today_outlined,
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
                  isAvance ? 'Avance' : 'Loyer',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
                const SizedBox(height: 3),
                Text(uniteNom,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 2),
                Text(datePaiement,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                if (isEspece)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Espèces',
                        style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$montant FCFA',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isAvance ? Colors.orange : _primaryColor),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(statutLabel,
                    style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600, color: statutColor)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios, color: Colors.grey.shade300, size: 14),
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
            Text(_error ?? '', style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchPaiements, child: const Text('Réessayer')),
          ],
        ),
      );

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('Aucun paiement effectué', style: TextStyle(color: Colors.grey[400])),
          ],
        ),
      );

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }
}
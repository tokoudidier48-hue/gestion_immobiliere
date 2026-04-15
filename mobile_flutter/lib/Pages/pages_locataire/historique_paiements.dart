import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/locataire_navbar.dart';
import 'package:mobile_flutter/Pages/pages_locataire/detail_recu.dart';

class HistoriquePaiementsPage extends StatelessWidget {
  const HistoriquePaiementsPage({super.key});

  final List<Map<String, dynamic>> _transactions = const [
    {
      'type': 'Loyer',
      'periode': 'Septembre',
      'date': '01 Sept. 2024 • 12:05',
      'montant': '125.000 FCFA',
      'statut': 'payé',
    },
    {
      'type': 'Loyer',
      'periode': 'Août',
      'date': '12 Août 2024 • 09:43',
      'montant': '125.000 FCFA',
      'statut': 'payé',
    },
    {
      'type': 'Avance (Caution)',
      'periode': '',
      'date': '15 Juil 2024 • 11:00',
      'montant': '375.000 FCFA',
      'statut': 'initial',
    },
    {
      'type': 'Loyer',
      'periode': 'Juillet',
      'date': '05 Juil 2024 • 14:43',
      'montant': '125.000 FCFA',
      'statut': 'payé',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text(
          'Historique Paiements',
          style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: Text(
              'DERNIÈRES TRANSACTIONS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey, letterSpacing: 1.2),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _buildTransactionCard(context, _transactions[index]);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const LocataireNavBar(selectedIndex: 3),
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> transaction) {
    final bool isInitial = transaction['statut'] == 'initial';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailRecuPage(transaction: transaction),
          ),
        );
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
            // Icône
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isInitial
                    ? Colors.orange.withOpacity(0.12)
                    : const Color(0xFF1A3C6E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isInitial ? Icons.lock_outline : Icons.calendar_today_outlined,
                color: isInitial ? Colors.orange : const Color(0xFF1A3C6E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['periode'].isNotEmpty
                        ? '${transaction['type']} - ${transaction['periode']}'
                        : transaction['type'],
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    transaction['date'],
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // Montant + statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  transaction['montant'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isInitial ? Colors.orange : const Color(0xFF1A3C6E),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isInitial
                        ? Colors.orange.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isInitial ? 'INITIAL' : 'PAYÉ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isInitial ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),
            Icon(Icons.download_outlined, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}
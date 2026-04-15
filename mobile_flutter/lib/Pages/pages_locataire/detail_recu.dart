import 'package:flutter/material.dart';

class DetailRecuPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const DetailRecuPage({super.key, required this.transaction});

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
          'Détails du Reçu',
          style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ── SUCCÈS ────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  // Icône succès
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 36),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'PAIEMENT RÉUSSI',
                    style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w700, letterSpacing: 1),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    transaction['montant'],
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),

                  const SizedBox(height: 24),
                  Divider(color: Colors.grey.shade100),
                  const SizedBox(height: 16),

                  // Infos
                  _buildInfoRow('Date & Heure', transaction['date']),
                  const SizedBox(height: 12),
                  _buildInfoRow('Méthode', 'MoMo'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Type', transaction['periode'].isNotEmpty
                      ? '${transaction['type']} - ${transaction['periode']}'
                      : transaction['type']),
                  const SizedBox(height: 12),
                  _buildInfoRow('Locataire', 'Jean-Baptiste Dupont'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Propriété', 'Résidence Fidjrossè, Villa A2, Appt B4, Cotonou'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── BOUTON TÉLÉCHARGER ────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, color: Colors.white),
                label: const Text(
                  'Télécharger le reçu (PDF)',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
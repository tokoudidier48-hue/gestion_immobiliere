import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DetailRecuPage extends StatefulWidget {
  final int paiementId;
  final dynamic paiement;

  const DetailRecuPage({super.key, required this.paiementId, required this.paiement});

  @override
  State<DetailRecuPage> createState() => _DetailRecuPageState();
}

class _DetailRecuPageState extends State<DetailRecuPage> {
  static const _primaryColor = Color(0xFF1A3C6E);
  final ApiLocataire _api = ApiLocataire();
  dynamic _recu;
  bool _isLoading = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchRecu();
  }

  Future<void> _fetchRecu() async {
    try {
      final data = await _api.getDetailRecu(widget.paiementId);
      if (!mounted) return;
      setState(() => _recu = data);
    } catch (_) {
      // Si pas de reçu disponible, on utilise les données du paiement directement
      if (mounted) setState(() => _recu = null);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


Future<void> _telecharger() async {
  setState(() => _isDownloading = true);

      try {
        // 1. Télécharger les bytes
        final recuId = _recu?['id'];

    if (recuId == null) {
      throw Exception("Reçu introuvable");
    }

    final bytes = await _api.telechargerRecuPdf(recuId);
    print("RECU DATA: $bytes");

    // 2. Permission
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception("Permission refusée");
    }

    // 3. Dossier Download
    Directory dir = Directory('/storage/emulated/0/Download');

    if (!await dir.exists()) {
      dir = await getExternalStorageDirectory() ?? Directory('/storage/emulated/0/Download');
    }

    // 4. Chemin fichier
    final filePath = "${dir.path}/recu_${widget.paiementId}.pdf";

    // 5. Écriture du fichier
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reçu enregistré dans : $filePath"),
        backgroundColor: Colors.green,
      ),
    );

  } catch (e, stack) {
    print("Erreur lors du téléchargement : $e");
    print(stack);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur : $e"),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) setState(() => _isDownloading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final p = widget.paiement;
    final String typePaiement = (p['type_paiement'] ?? '').toString();
    final String modePaiement = (p['mode_paiement'] ?? '').toString();
    final String statut = (p['statut'] ?? '').toString();
    final String montant = (p['montant'] ?? 0).toString();
    final String uniteNom = (p['unite_nom'] ?? '—').toString();
    final String proprietaireNom = (p['proprietaire_nom'] ?? '—').toString();
    final String locataireNom = (p['locataire_nom'] ?? '—').toString();
    final String datePaiement = _formatDate(p['date_paiement'] ?? '');
    final String periodeDebut = _formatDateSimple(p['periode_debut'] ?? '');
    final String periodeFin = _formatDateSimple(p['periode_fin'] ?? '');
    final String numeroPaiement = (p['numero_paiement'] ?? '—').toString();

    final bool isReussi = statut == 'reussi';
    final bool isEnAttente = statut == 'en_attente';
    final bool isAvance = typePaiement == 'avance';

    Color statutColor = isReussi
        ? Colors.green
        : isEnAttente
            ? Colors.orange
            : Colors.red;
    String statutLabel = isReussi ? 'PAIEMENT RÉUSSI' : isEnAttente ? 'EN ATTENTE' : 'ÉCHOUÉ';
    IconData statutIcon = isReussi
        ? Icons.check_circle
        : isEnAttente
            ? Icons.hourglass_empty
            : Icons.cancel;

    String modeLabel = modePaiement == 'mtn'
        ? 'MoMo MTN'
        : modePaiement == 'moov'
            ? 'Moov Money'
            : modePaiement == 'celtiis'
                ? 'Celtiis Cash'
                : modePaiement == 'especes'
                    ? 'Espèces'
                    : modePaiement;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
        title: const Text('Détails du Reçu',
            style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // ── CARTE STATUT ──────────────────────────────────────
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
                        Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: statutColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statutIcon, color: statutColor, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text(statutLabel,
                            style: TextStyle(
                                fontSize: 12,
                                color: statutColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                        const SizedBox(height: 10),
                        Text(
                          '$montant FCFA',
                          style: const TextStyle(
                              fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: isAvance
                                ? Colors.orange.withOpacity(0.1)
                                : _primaryColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isAvance ? 'Avance sur loyer' : 'Loyer mensuel',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAvance ? Colors.orange : _primaryColor),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Divider(color: Colors.grey.shade100),
                        const SizedBox(height: 16),

                        // Infos
                        _buildInfoRow('Date & Heure', datePaiement),
                        const SizedBox(height: 12),
                        _buildInfoRow('Méthode', modeLabel),
                        if (modePaiement != 'especes') ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Numéro', numeroPaiement),
                        ],
                        const SizedBox(height: 12),
                        _buildInfoRow('Logement', uniteNom),
                        const SizedBox(height: 12),
                        _buildInfoRow('Locataire', locataireNom),
                        const SizedBox(height: 12),
                        _buildInfoRow('Propriétaire', proprietaireNom),
                        if (periodeDebut.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow('Période', '$periodeDebut → $periodeFin'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── BOUTON TÉLÉCHARGER ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _telecharger,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.download_outlined, color: Colors.white),
                      label: Text(
                        _isDownloading ? 'Téléchargement...' : 'Télécharger le reçu (PDF)',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
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
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '—';
    try {
      final d = DateTime.parse(date);
      final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
      return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year} • ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  String _formatDateSimple(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date;
    }
  }
}
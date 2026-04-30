import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

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
  bool _isDownloading = false;

  // ── Statut helpers ─────────────────────────────────────────────────────────

  bool _isStatutReussi(String statut) {
    final s = statut.toLowerCase().trim();
    return s == 'reussi' ||
        s == 'valide' ||
        s == 'confirme' ||
        s == 'confirmed' ||
        s == 'success' ||
        s == 'completed' ||
        s == 'paid' ||
        s == 'paye';
  }

  bool _isStatutEnAttente(String statut) {
    final s = statut.toLowerCase().trim();
    return s == 'en_attente' ||
        s == 'pending' ||
        s == 'attente' ||
        s == 'en attente';
  }

  // ── Téléchargement PDF ─────────────────────────────────────────────────────
Future<void> _telecharger() async {
  setState(() => _isDownloading = true);
  try {
    // 1. Récupère le reçu lié à ce paiement
    print("==> Recherche reçu pour paiement ID : ${widget.paiementId}");
    final recu = await _api.getRecuParPaiement(widget.paiementId);

    if (recu == null) {
      throw Exception("Aucun reçu trouvé pour ce paiement. Le reçu est peut-être pas encore généré.");
    }

    final recuId = recu['id'] as int;
    print("==> Reçu trouvé, ID : $recuId");

    // 2. Télécharge le PDF via GET /download/
    List<int> bytes = [];
    try {
      bytes = await _api.telechargerRecuPdf(recuId);
      print("==> Bytes reçus via /download/ : ${bytes.length}");
    } catch (e) {
      print("==> /download/ échoué, essai via /telecharger/ : $e");
      // Fallback : récupère l'URL via POST /telecharger/ puis télécharge
      final url = await _api.getUrlRecuPdf(recuId);
      if (url == null || url.isEmpty) {
        throw Exception("Impossible d'obtenir le PDF. Contactez le support.");
      }
      print("==> URL PDF obtenue : $url");
      bytes = await _api.downloadPdfFromUrl(url);
    }

    if (bytes.isEmpty) throw Exception("Le fichier PDF reçu est vide.");

    // 3. Vérifie que c'est bien un PDF
    final isPdf = bytes.length >= 4 &&
        bytes[0] == 37 && // %
        bytes[1] == 80 && // P
        bytes[2] == 68 && // D
        bytes[3] == 70;   // F

    if (!isPdf) {
      // Affiche le message d'erreur du serveur
      try {
        final errMsg = String.fromCharCodes(bytes);
        print("==> Réponse non-PDF : $errMsg");
        throw Exception("Erreur serveur : $errMsg");
      } catch (_) {
        throw Exception("Le serveur n'a pas retourné un PDF valide.");
      }
    }

    // 4. Sauvegarde dans Downloads
 final params = SaveFileDialogParams(
  data: Uint8List.fromList(bytes),
  fileName: 'recu_loyasmart_${widget.paiementId}.pdf',
);

final path = await FlutterFileDialog.saveFile(params: params);

if (path == null) {
  print("==> Téléchargement annulé");
  return;
}

await OpenFile.open(path);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text('Reçu enregistré dans Téléchargements ✓')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );

    // 5. Ouvre le fichier
    // Le fichier est déjà ouvert juste après la sauvegarde.
  } catch (e) {
    print("==> Erreur téléchargement : $e");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
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

    // Debug statut
    print("==> Statut dans DetailRecuPage : '$statut'");

    final bool isReussi = _isStatutReussi(statut);
    final bool isEnAttente = _isStatutEnAttente(statut);
    final bool isAvance = typePaiement == 'avance';

    final Color statutColor = isReussi
        ? Colors.green
        : isEnAttente
            ? Colors.orange
            : Colors.grey; // ← gris au lieu de rouge pour les statuts inconnus

    final String statutLabel = isReussi
        ? 'PAIEMENT RÉUSSI'
        : isEnAttente
            ? 'EN ATTENTE DE CONFIRMATION'
            : statut.toUpperCase().isEmpty
                ? 'EN COURS'
                : statut.toUpperCase(); // ← affiche le vrai statut

    final IconData statutIcon = isReussi
        ? Icons.check_circle
        : isEnAttente
            ? Icons.hourglass_empty
            : Icons.info_outline; // ← info au lieu de cancel

    final String modeLabel = modePaiement == 'mtn'
        ? 'MoMo MTN'
        : modePaiement == 'moov'
            ? 'Moov Money'
            : modePaiement == 'celtiis'
                ? 'Celtiis Cash'
                : modePaiement == 'especes'
                    ? 'Espèces'
                    : modePaiement;

 print("==> Détails du paiement : ${widget.paiement}");

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ── CARTE STATUT ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
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
                      textAlign: TextAlign.center,
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

                  _buildInfoRow('Date & Heure', datePaiement),
                  const SizedBox(height: 12),
                  _buildInfoRow('Méthode', modeLabel),
                  if (modePaiement != 'especes' && numeroPaiement != '—') ...[
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

            // ── BOUTON TÉLÉCHARGER ────────────────────────────────────
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
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
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
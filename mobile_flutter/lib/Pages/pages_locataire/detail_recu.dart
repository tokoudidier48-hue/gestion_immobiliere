import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';
import 'dart:typed_data';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class DetailRecuPage extends StatefulWidget {
  final int paiementId;
  final dynamic paiement;

  const DetailRecuPage(
      {super.key, required this.paiementId, required this.paiement});

  @override
  State<DetailRecuPage> createState() => _DetailRecuPageState();
}

class _DetailRecuPageState extends State<DetailRecuPage> {
  static const _primaryColor = Color(0xFF1A3C6E);
  final ApiLocataire _api = ApiLocataire();
  bool _isDownloading = false;
  bool _isRefreshing = false;
  late dynamic _paiement;

  @override
  void initState() {
    super.initState();
    _paiement = widget.paiement;
    // ← Rafraîchit le statut automatiquement après 3 secondes
    Future.delayed(const Duration(seconds: 3), _refreshStatut);
  }

  // ── Rafraîchit le statut depuis le backend ─────────────────────────────────
  Future<void> _refreshStatut() async {
  if (!mounted) return;
  setState(() => _isRefreshing = true);
  try {
    // 1. Demande au backend de vérifier le statut auprès de FedaPay
    try {
      await _api.verifierStatutPaiement(widget.paiementId);
    } catch (e) {
      print("==> verifierStatut ignoré : $e");
    }

    // 2. Recharge les données fraîches
    final updated = await _api.getDetailPaiement(widget.paiementId);
    if (!mounted) return;
    setState(() => _paiement = updated);

    // 3. Affiche un message selon le nouveau statut
    final nouveauStatut = (_paiement['statut'] ?? '').toString();
    if (_isStatutReussi(nouveauStatut)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paiement confirmé ! Vous pouvez télécharger votre reçu.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    print("==> Erreur refresh statut : $e");
  } finally {
    if (mounted) setState(() => _isRefreshing = false);
  }
}

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
    return s == 'en_attente' || s == 'pending' || s == 'attente';
  }

  // ── Téléchargement PDF ──────────────────────────────────────────────────────
  Future<void> _telecharger() async {
    final statut = (_paiement['statut'] ?? '').toString();
    final modePaiement = (_paiement['mode_paiement'] ?? '').toString();
    final isEspece = modePaiement == 'especes';

    // ← Si en attente ET espèces → message propriétaire
    if (_isStatutEnAttente(statut) && isEspece) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⏳ Votre paiement en espèces attend la confirmation du propriétaire. Le reçu sera disponible après validation.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // ← Si en attente ET paiement mobile → vérifie le statut réel
    if (_isStatutEnAttente(statut) && !isEspece) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '⏳ Paiement en cours de confirmation par FedaPay. Veuillez patienter...'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      await _refreshStatut();
      // Revérifie après refresh
      final newStatut = (_paiement['statut'] ?? '').toString();
      if (!_isStatutReussi(newStatut)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '⏳ Le reçu sera disponible dès que le paiement sera confirmé.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isDownloading = true);
    try {
      print("==> Recherche reçu pour paiement ID : ${widget.paiementId}");

      // Essaie d'abord de récupérer le reçu lié à ce paiement
      dynamic recu;
      try {
        recu = await _api.getRecuParPaiement(widget.paiementId);
      } catch (e) {
        print("==> Erreur getRecuParPaiement : $e");
      }

      List<int> bytes = [];

      if (recu != null) {
        final recuId = recu['id'] as int;
        print("==> Reçu trouvé, ID : $recuId");

        // Essaie via /download/
        try {
          bytes = await _api.telechargerRecuPdf(recuId);
          print("==> Bytes via /download/ : ${bytes.length}");
        } catch (e) {
          print("==> /download/ échoué : $e");
          // Fallback via /telecharger/
          try {
            final url = await _api.getUrlRecuPdf(recuId);
            if (url != null && url.isNotEmpty) {
              bytes = await _api.downloadPdfFromUrl(url);
            }
          } catch (e2) {
            print("==> /telecharger/ échoué aussi : $e2");
          }
        }
      }

      // ← Si aucun reçu trouvé → essaie directement avec l'ID du paiement
      if (bytes.isEmpty) {
        print("==> Tentative directe avec paiement ID : ${widget.paiementId}");
        try {
          bytes = await _api.telechargerRecuPdf(widget.paiementId);
        } catch (e) {
          print("==> Tentative directe échouée : $e");
        }
      }

      if (bytes.isEmpty) {
        throw Exception(
            'Le reçu n\'est pas encore disponible. Réessayez dans quelques instants.');
      }

      // Vérifie que c'est un PDF
      final isPdf = bytes.length >= 4 &&
          bytes[0] == 37 &&
          bytes[1] == 80 &&
          bytes[2] == 68 &&
          bytes[3] == 70;

      if (!isPdf) {
        throw Exception(
            'Le fichier reçu n\'est pas un PDF valide. Réessayez plus tard.');
      }

      // Sauvegarde dans le répertoire temporaire
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/recu_loyasmart_${widget.paiementId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(Uint8List.fromList(bytes));

      print("==> PDF sauvegardé : ${file.path}");

      await OpenFile.open(file.path);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Reçu téléchargé avec succès ✓'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
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
    final p = _paiement;

    final String typePaiement = (p['type_paiement'] ?? '').toString();
    final String modePaiement = (p['mode_paiement'] ?? '').toString();
    final String statut = (p['statut'] ?? '').toString();
    final num montantNum = num.tryParse(p['montant'].toString()) ?? 0;
    final String uniteNom = (p['unite_nom'] ?? '—').toString();
    final String proprietaireNom = (p['proprietaire_nom'] ?? '—').toString();
    final String locataireNom = (p['locataire_nom'] ?? '—').toString();
    final String datePaiement = _formatDate(p['date_paiement'] ?? '');
    final String periodeDebut = _formatDateSimple(p['periode_debut'] ?? '');
    final String periodeFin = _formatDateSimple(p['periode_fin'] ?? '');
    final String numeroPaiement = (p['numero_paiement'] ?? '—').toString();

    final bool isAvance = typePaiement == 'avance';
    final bool isEspece = modePaiement == 'especes';

    final bool isReussi = _isStatutReussi(statut);
    final bool isEnAttente = _isStatutEnAttente(statut);
    final bool isEchoue = statut.toLowerCase() == 'echoue' ||
        statut.toLowerCase() == 'failed';

    final Color statutColor = isReussi
        ? Colors.green
        : isEnAttente
            ? Colors.orange
            : isEchoue
                ? Colors.red
                : Colors.grey;

    final String statutLabel = isReussi
        ? 'PAIEMENT RÉUSSI'
        : isEnAttente
            ? isEspece
                ? 'EN ATTENTE DE CONFIRMATION PROPRIÉTAIRE'
                : 'EN ATTENTE DE CONFIRMATION FEDAPAY'
            : isEchoue
                ? 'PAIEMENT ÉCHOUÉ'
                : statut.toUpperCase().isEmpty
                    ? 'EN COURS'
                    : statut.toUpperCase();

    final IconData statutIcon = isReussi
        ? Icons.check_circle
        : isEnAttente
            ? Icons.hourglass_empty
            : isEchoue
                ? Icons.cancel
                : Icons.info_outline;

    final String modeLabel = modePaiement == 'mtn'
        ? 'MTN MoMo'
        : modePaiement == 'moov'
            ? 'Moov Money'
            : modePaiement == 'celtiis' || modePaiement == 'celtis'
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
            style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        actions: [
          // Bouton rafraîchir statut
          _isRefreshing
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.grey),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.black54),
                  tooltip: 'Actualiser le statut',
                  onPressed: _refreshStatut,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // ── CARTE STATUT ─────────────────────────────────────────────
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: statutColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statutIcon,
                        color: statutColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(statutLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: statutColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),

                  // ← Message explicatif si en attente
                  if (isEnAttente) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isEspece
                            ? 'Le propriétaire doit valider votre paiement en espèces. Le reçu sera généré automatiquement après validation.'
                            : 'Votre paiement est en cours de traitement. Appuyez sur ↻ pour actualiser le statut.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            height: 1.4),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    '${montantNum.toInt()} FCFA',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
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
                  if (modePaiement != 'especes' &&
                      numeroPaiement != '—') ...[
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
                    _buildInfoRow(
                        'Période', '$periodeDebut → $periodeFin'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── BOUTON TÉLÉCHARGER ────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _telecharger,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(
                        isEnAttente
                            ? Icons.hourglass_empty
                            : Icons.download_outlined,
                        color: Colors.white),
                label: Text(
                  _isDownloading
                      ? 'Téléchargement...'
                      : isEnAttente
                          ? 'En attente de confirmation...'
                          : 'Télécharger le reçu (PDF)',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isEnAttente ? Colors.orange : _primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            // ← Bouton rafraîchir visible si en attente
            if (isEnAttente) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _isRefreshing ? null : _refreshStatut,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1A3C6E)))
                      : const Icon(Icons.refresh,
                          color: Color(0xFF1A3C6E), size: 18),
                  label: const Text('Actualiser le statut',
                      style: TextStyle(
                          color: Color(0xFF1A3C6E),
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: Color(0xFF1A3C6E)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

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
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '—';
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
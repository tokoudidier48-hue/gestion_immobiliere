import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:dio/dio.dart';

class DetailDemandeNotifPage extends StatefulWidget {
  final int demandeId;
  const DetailDemandeNotifPage({super.key, required this.demandeId});

  @override
  State<DetailDemandeNotifPage> createState() => _DetailDemandeNotifPageState();
}

class _DetailDemandeNotifPageState extends State<DetailDemandeNotifPage> {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.55.17.129:8000',
    headers: {'Content-Type': 'application/json'},
  ));

  Map<String, dynamic>? _demande;
  bool _isLoading = true;
  bool _isActing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initDio();
    _fetchDemande();
  }

  void _initDio() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await LocalStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<void> _fetchDemande() async {
    try {
      setState(() { _isLoading = true; _error = null; });
      final response = await _dio.get('/api/locations/demandes/${widget.demandeId}/');
      setState(() { _demande = response.data; _isLoading = false; });
    } catch (e) {
      // Si pas d'endpoint détail, fetch la liste et filtre
      try {
        final response = await _dio.get('/api/locations/demandes/');
        final liste = response.data as List;
        final demande = liste.firstWhere(
          (d) => d['id'] == widget.demandeId,
          orElse: () => null,
        );
        setState(() {
          _demande = demande;
          _isLoading = false;
          if (demande == null) _error = 'Demande introuvable';
        });
      } catch (e2) {
        setState(() { _error = e2.toString(); _isLoading = false; });
      }
    }
  }

  Future<void> _accepter() async {
  final statut = _demande?['statut'] ?? '';
  if (statut == 'acceptee') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cette demande a déjà été acceptée.'), backgroundColor: Colors.orange),
    );
    return;
  }

  setState(() => _isActing = true);
  try {
    await _dio.post('/api/locations/demandes/${widget.demandeId}/accepter/');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande acceptée avec succès !'), backgroundColor: Colors.green),
    );
    setState(() => _demande!['statut'] = 'acceptee');
  } on DioException catch (e) {
    if (!mounted) return;
    final msg = e.response?.statusCode == 500
        ? 'Cette demande a déjà été traitée.'
        : 'Erreur : ${e.response?.data ?? e.message}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) setState(() => _isActing = false);
  }
}

  Future<void> _refuser() async {
  // Vérifie le statut actuel avant d'agir
  final statut = _demande?['statut'] ?? '';
  if (statut == 'refusee') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cette demande a déjà été refusée.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  setState(() => _isActing = true);
  try {
    await _dio.post('/api/locations/demandes/${widget.demandeId}/refuser/');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demande refusée.'), backgroundColor: Colors.orange),
    );
    setState(() => _demande!['statut'] = 'refusee');
  } on DioException catch (e) {
    if (!mounted) return;
    // Erreur 500 = déjà refusée côté backend
    final msg = e.response?.statusCode == 500
        ? 'Cette demande a déjà été traitée.'
        : 'Erreur : ${e.response?.data ?? e.message}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  } finally {
    if (mounted) setState(() => _isActing = false);
  }
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
        title: const Text('Détail de la demande',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text(_error!,
                          style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _fetchDemande,
                          child: const Text('Réessayer')),
                    ],
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _demande!;
    final statut = d['statut'] ?? 'en_attente';
    final locataireNom = d['locataire_nom'] ?? '';
    final uniteNom = d['unite_nom'] ?? '';
    final uniteType = d['unite_type'] ?? '';
    final uniteLoyer = d['unite_loyer']?.toString() ?? '0';
    final message = d['message'] ?? '';
    final date = d['date_demande'] ?? '';

    Color statutColor;
    String statutLabel;
    switch (statut) {
      case 'acceptee':
        statutColor = Colors.green;
        statutLabel = 'Acceptée';
        break;
      case 'refusee':
        statutColor = Colors.red;
        statutLabel = 'Refusée';
        break;
      default:
        statutColor = Colors.orange;
        statutLabel = 'En attente';
    }

    final initiales = locataireNom.split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── CARTE LOCATAIRE ───────────────────────────────────────
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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      const Color(0xFF1565C0).withOpacity(0.12),
                  child: Text(initiales,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(locataireNom,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statutColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(statutLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: statutColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── INFOS UNITÉ ────────────────────────────────────────────
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
                const Text('UNITÉ CONCERNÉE',
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
                _infoRow(Icons.calendar_today_outlined, 'Date demande',
                    _formatDate(date)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── MESSAGE ────────────────────────────────────────────────
          if (message.isNotEmpty)
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
                  const Text('MESSAGE DU LOCATAIRE',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FA),
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

          const SizedBox(height: 28),

          // ── BOUTONS ACCEPTER / REFUSER ─────────────────────────────
          if (statut == 'en_attente') ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isActing ? null : _accepter,
                icon: _isActing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                label: const Text('Accepter la demande',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isActing ? null : _refuser,
                icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                label: const Text('Refuser la demande',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            // Statut final
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statutColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statutColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    statut == 'acceptee'
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: statutColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statut == 'acceptee'
                        ? 'Demande acceptée'
                        : 'Demande refusée',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: statutColor),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
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

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return date;
    }
  }
}
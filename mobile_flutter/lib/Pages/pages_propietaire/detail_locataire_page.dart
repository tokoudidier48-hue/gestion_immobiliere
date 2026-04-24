import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/proprietaire/apiProprietaire.dart';

class DetailLocatairePage extends StatefulWidget {
  final dynamic locataire;
  const DetailLocatairePage({super.key, required this.locataire});

  @override
  State<DetailLocatairePage> createState() => _DetailLocatairePageState();
}

class _DetailLocatairePageState extends State<DetailLocatairePage> {
  static const _primary = Color(0xFF2563EB);
  final ApiProprietaire _api = ApiProprietaire();
  List<dynamic> _paiements = [];
  bool _loadingPaiements = true;

  @override
  void initState() {
    super.initState();
    _fetchPaiements();
  }

  Future<void> _fetchPaiements() async {
    try {
      final id = widget.locataire['id'];
      final response = await _api.getPaiementsLocataire(id);
      if (mounted) setState(() => _paiements = response);
    } catch (_) {}
    if (mounted) setState(() => _loadingPaiements = false);
  }

  String _getNom() {
    final prenom = (widget.locataire['prenom'] ?? '').toString();
    final nom = (widget.locataire['nom'] ?? '').toString();
    return '$prenom $nom'.trim().isEmpty ? 'Inconnu' : '$prenom $nom'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.locataire;
    final nomComplet = _getNom();
    final email = (l['email'] ?? '').toString();
    final telephone = (l['telephone'] ?? '—').toString();
    final uniteNom = (l['unite_nom'] ?? '—').toString();
    final loyer = (l['loyer'] ?? '0').toString();
    final photoProfil = l['photo_profil']?.toString();
    final initiales = nomComplet.split(' ')
        .take(2)
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase())
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF111827)),
        centerTitle: true,
        title: const Text('Détails du locataire',
            style: TextStyle(color: Color(0xFF111827), fontSize: 17, fontWeight: FontWeight.w600)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── CARTE PROFIL ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                children: [
                  // Photo de profil
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: _primary.withOpacity(0.12),
                    backgroundImage: photoProfil != null && photoProfil.isNotEmpty
                        ? NetworkImage(photoProfil)
                        : null,
                    child: photoProfil == null || photoProfil.isEmpty
                        ? Text(initiales,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primary))
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(nomComplet,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(height: 4),
                  Text('Locataire chez LoyaSmart',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.message_outlined,
                          label: 'Message',
                          color: _primary,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _actionBtn(
                          icon: Icons.phone_outlined,
                          label: 'Appeler',
                          color: Colors.green,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── INFORMATIONS PERSONNELLES ─────────────────────────────
            _buildSection('INFORMATIONS PERSONNELLES', [
              _infoRow(Icons.person_outline, 'Prénom & Nom', nomComplet),
              _divider(),
              _infoRow(Icons.phone_outlined, 'Contact', telephone),
              if (email.isNotEmpty) ...[
                _divider(),
                _infoRow(Icons.email_outlined, 'Email', email),
              ],
            ]),
            const SizedBox(height: 14),

            // ── CONTRAT & PAIEMENT ────────────────────────────────────
            _buildSection('CONTRAT & PAIEMENT', [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type de chambre',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(uniteNom,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 44, color: Colors.grey.shade200),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prix du loyer',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('$loyer FCFA',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: _primary)),
                      ],
                    ),
                  ),
                ],
              ),
              _divider(),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nombre d\'avance',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text('${l['nombre_avances'] ?? 3} Mois',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Statut Prépayé',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 14,
                                color: l['prepaye'] == true ? Colors.green : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              l['prepaye'] == true ? 'Avec prépayé' : 'Sans prépayé',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: l['prepaye'] == true ? Colors.green : Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: 14),

            // ── CAUTION ───────────────────────────────────────────────
            if (l['type_caution'] != null)
              _buildSection('CAUTION', [
                Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.water_drop_outlined, color: Colors.green, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (l['type_caution'] ?? '').toString().replaceAll('_', ' '),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const Text('Payée et validée',
                              style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              ]),
            const SizedBox(height: 14),

            // ── HISTORIQUE PAIEMENTS ──────────────────────────────────
            _buildSection('HISTORIQUE DES PAIEMENTS', [
              if (_loadingPaiements)
                const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else if (_paiements.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Aucun paiement enregistré',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                )
              else
                ..._paiements.take(5).map((p) => _buildPaiementRow(p)).toList(),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.8)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade400),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: Colors.grey.shade100),
      );

  Widget _buildPaiementRow(dynamic p) {
    final montant = (p['montant'] ?? 0).toString();
    final type = (p['type_paiement'] ?? '').toString();
    final statut = (p['statut'] ?? '').toString();
    final date = _formatDate(p['date_paiement'] ?? '');
    final isReussi = statut == 'reussi';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: isReussi ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isReussi ? Icons.check_circle_outline : Icons.pending_outlined,
              size: 18,
              color: isReussi ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.replaceAll('_', ' '),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Text('$montant FCFA',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isReussi ? Colors.green : Colors.orange)),
        ],
      ),
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
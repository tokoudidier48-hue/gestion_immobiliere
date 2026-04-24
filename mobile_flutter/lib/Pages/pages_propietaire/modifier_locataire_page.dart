import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/proprietaire/apiProprietaire.dart';

class ModifierLocatairePage extends StatefulWidget {
  final dynamic locataire;
  final VoidCallback? onModified;
  const ModifierLocatairePage({super.key, required this.locataire, this.onModified});

  @override
  State<ModifierLocatairePage> createState() => _ModifierLocatairePageState();
}

class _ModifierLocatairePageState extends State<ModifierLocatairePage> {
  static const _primary = Color(0xFF2563EB);
  final ApiProprietaire _api = ApiProprietaire();

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _telephoneController;
  late TextEditingController _loyerController;
  late TextEditingController _nombreAvancesController;

  String _typeUnite = '';
  String _prepaye = 'sans_prepaye';
  String _typeCaution = '';
  bool _isLoading = false;

  final List<String> _typesUnite = [
    'appartement', 'boutique', 'chambre_salon_ordinaire',
    'chambre_salon_sanitaire', 'entree_coucher_ordinaire',
    'entree_coucher_sanitaire', 'deux_chambres_ordinaire', 'deux_chambres_sanitaire',
  ];
  final List<String> _typesCaution = [
    'eau_et_electricite', 'forfaitaire', 'sans_caution',
  ];

  @override
  void initState() {
    super.initState();
    final l = widget.locataire;
    _nomController = TextEditingController(text: l['nom'] ?? '');
    _prenomController = TextEditingController(text: l['prenom'] ?? '');
    _telephoneController = TextEditingController(text: l['telephone'] ?? '');
    _loyerController = TextEditingController(text: (l['loyer'] ?? '').toString());
    _nombreAvancesController = TextEditingController(text: (l['nombre_avances'] ?? 3).toString());
    _typeUnite = l['type_unite'] ?? (_typesUnite.isNotEmpty ? _typesUnite[0] : '');
    _prepaye = l['prepaye'] == true ? 'avec_prepaye' : 'sans_prepaye';
    _typeCaution = l['type_caution'] ?? (_typesCaution.isNotEmpty ? _typesCaution[0] : '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _loyerController.dispose();
    _nombreAvancesController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (_nomController.text.trim().isEmpty || _prenomController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et prénom sont requis')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _api.modifierLocataire(
        locataireId: widget.locataire['id'],
        data: {
          'nom': _nomController.text.trim(),
          'prenom': _prenomController.text.trim(),
          'telephone': _telephoneController.text.trim(),
        },
      );
      if (!mounted) return;
      widget.onModified?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Locataire modifié !'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF111827)),
        centerTitle: true,
        title: const Text('Modifier le locataire',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField('Nom', _nomController),
                  const SizedBox(height: 14),
                  _buildField('Prénom', _prenomController),
                  const SizedBox(height: 14),
                  _buildField('Contact', _telephoneController,
                      keyboardType: TextInputType.phone,
                      prefix: const Icon(Icons.phone_outlined, size: 16, color: Colors.grey)),
                  const SizedBox(height: 14),

                  // Type de chambre
                  _buildLabel('Type de chambre'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _typesUnite.contains(_typeUnite) ? _typeUnite : _typesUnite[0],
                    items: _typesUnite,
                    onChanged: (v) => setState(() => _typeUnite = v!),
                    display: (v) => v.replaceAll('_', ' '),
                  ),
                  const SizedBox(height: 14),

                  _buildField('Prix du loyer (FCFA)', _loyerController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 14),

                  _buildField("Nombre d'avance (mois)", _nombreAvancesController,
                      keyboardType: TextInputType.number),
                  const SizedBox(height: 14),

                  // Prépayé
                  _buildLabel('Prépayé'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _prepaye,
                    items: ['avec_prepaye', 'sans_prepaye'],
                    onChanged: (v) => setState(() => _prepaye = v!),
                    display: (v) => v == 'avec_prepaye' ? 'Avec prépayé' : 'Sans prépayé',
                  ),
                  const SizedBox(height: 14),

                  // Caution
                  _buildLabel('Caution'),
                  const SizedBox(height: 6),
                  _buildDropdown(
                    value: _typesCaution.contains(_typeCaution) ? _typeCaution : _typesCaution[0],
                    items: _typesCaution,
                    onChanged: (v) => setState(() => _typeCaution = v!),
                    display: (v) => v.replaceAll('_', ' '),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _enregistrer,
                icon: _isLoading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                label: const Text('Enregistrer les modifications',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
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

  Widget _buildLabel(String label) {
    return Text(label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade600));
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, Widget? prefix}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: prefix,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    required String Function(String) display,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          items: items.map((v) => DropdownMenuItem(
            value: v,
            child: Text(display(v)),
          )).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
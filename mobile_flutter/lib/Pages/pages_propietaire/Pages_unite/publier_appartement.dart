import 'package:flutter/material.dart';

class PublierAppartementPage extends StatefulWidget {
  const PublierAppartementPage({super.key});

  @override
  State<PublierAppartementPage> createState() => _PublierAppartementPageState();
}

class _PublierAppartementPageState extends State<PublierAppartementPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _loyerController = TextEditingController();
  final _nbChambresController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();

  String? _typeLogement = 'Quartier, Rue, Ville';
  String? _typeAuction;
  String? _locationElectrique;
  String? _marcheGazCoffee;

  bool _whatsappEnabled = false;

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _loyerController.dispose();
    _nbChambresController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Publier l\'Appartement',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ── PHOTOS ──────────────────────────────────────────────────
            _sectionLabel('PHOTOS DE L\'APPARTEMENT'),
            const SizedBox(height: 8),
            // Grande image principale
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 32, color: Colors.blue[400]),
                    const SizedBox(height: 4),
                    Text(
                      'AJOUTEZ UNE PHOTO',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Grille 3x2
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
              children: List.generate(
                6,
                (index) => Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.blue[300],
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// ── INFORMATIONS GÉNÉRALES ───────────────────────────────────
            _sectionCard(
              title: 'INFORMATIONS GÉNÉRALES',
              children: [
                _inputField(
                  label: 'Nom de l\'appartement',
                  controller: _nomController,
                  hint: 'Ex: Résidence Lion',
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Adresse complète',
                  value: _typeLogement,
                  hint: 'Quartier, Rue, Ville',
                  items: const [
                    'Quartier, Rue, Ville',
                    'Cotonou Centre',
                    'Akpakpa',
                    'Fidjrossè',
                  ],
                  onChanged: (v) => setState(() => _typeLogement = v),
                ),
              ],
            ),
            const SizedBox(height: 14),

            /// ── CONDITIONS FINANCIÈRES ───────────────────────────────────
            _sectionCard(
              title: 'CONDITIONS FINANCIÈRES',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _inputField(
                        label: 'Loyer (FCFA)',
                        controller: _loyerController,
                        hint: 'Montant',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _inputField(
                        label: 'Nb. d\'avances',
                        controller: _nbChambresController,
                        hint: 'Qties',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Subvention issues de deux l\'espace',
                  value: _typeAuction,
                  hint: 'Avis (obligé)',
                  items: const ['Oui', 'Non', 'Négociable'],
                  onChanged: (v) => setState(() => _typeAuction = v),
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Type de l\'auction',
                  value: null,
                  hint: 'Conditions Eau/Elec',
                  items: const ['Inclus', 'Non inclus', 'Partiel'],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Location Electrique',
                  value: _locationElectrique,
                  hint: 'Location Electrique',
                  items: const ['Compteur personnel', 'Compteur partagé'],
                  onChanged: (v) => setState(() => _locationElectrique = v),
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Location Electrique (bis)',
                  value: null,
                  hint: 'Location Electrique/Eau',
                  items: const ['Inclus', 'Non inclus'],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Marché Gaz ou Coffee (FCFA)',
                  value: _marcheGazCoffee,
                  hint: 'FCFA',
                  items: const ['500', '1000', '2000', '5000'],
                  onChanged: (v) => setState(() => _marcheGazCoffee = v),
                ),
              ],
            ),
            const SizedBox(height: 14),

            /// ── DÉTAILS & CONTACT ─────────────────────────────────────────
            _sectionCard(
              title: 'DÉTAILS & CONTACT',
              children: [
                _multilineField(
                  label: 'Description',
                  controller: _descriptionController,
                  hint:
                      'Ex: Appartement moderne, cuisine équipée, proche des grandes...',
                ),
                const SizedBox(height: 12),
                _inputField(
                  label: 'Contact direct',
                  controller: _contactController,
                  hint: '+229 00-00-00-00',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone, size: 18, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // WhatsApp toggle
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/6/6b/WhatsApp.svg',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.chat,
                          color: Color(0xFF25D366),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Switch(
                        value: _whatsappEnabled,
                        onChanged: (v) => setState(() => _whatsappEnabled = v),
                        activeColor: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            /// ── BOUTON PUBLIER ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Publier l\'Appartement',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _inputField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _multilineField({
    required String label,
    required TextEditingController controller,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
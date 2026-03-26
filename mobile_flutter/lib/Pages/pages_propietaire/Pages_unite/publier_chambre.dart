import 'package:flutter/material.dart';

class PublierChambrePage extends StatefulWidget {
  const PublierChambrePage({super.key});

  @override
  State<PublierChambrePage> createState() => _PublierChambrePageState();
}

class _PublierChambrePageState extends State<PublierChambrePage> {
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _loyerController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _typeResidence;
  String? _typeChambre = 'Semaine';
  String? _cautionBoulee;
  bool _negociable = false;
  int _nombreMaxPersonnes = 2;

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _loyerController.dispose();
    _contactController.dispose();
    _descriptionController.dispose();
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
          'Publier une Chambre',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ── NOM DE LA CHAMBRE ────────────────────────────────────────
            _sectionCard(
              children: [
                _sectionLabel('NOM DE LA CHAMBRE'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _nomController,
                  hint: 'Ex: Chambre confort',
                ),
                const SizedBox(height: 14),

                /// ── PHOTOS ───────────────────────────────────────────────
                _sectionLabel('PHOTOS DE LA CHAMBRE (MAX 7)'),
                const SizedBox(height: 8),
                // Grande image principale
                Container(
                  width: double.infinity,
                  height: 130,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.camera_alt_outlined,
                      size: 32,
                      color: Colors.blue[300],
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
                  childAspectRatio: 1.4,
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
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            /// ── ADRESSE ──────────────────────────────────────────────────
            _sectionCard(
              children: [
                _sectionLabel('ADRESSE'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _adresseController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rechercher Quartier, Rue, Ville',
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon:
                        const Icon(Icons.location_on_outlined, size: 18),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
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
            ),
            const SizedBox(height: 14),

            /// ── LOYER + TYPE RÉSIDENCE ───────────────────────────────────
            _sectionCard(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('LOYER MENSUEL'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: _loyerController,
                            hint: 'Montant',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('TYPE RÉSIDENCE'),
                          const SizedBox(height: 8),
                          _dropdownCompact(
                            value: _typeResidence,
                            hint: 'Avance',
                            items: const ['1 mois', '2 mois', '3 mois', '6 mois'],
                            onChanged: (v) =>
                                setState(() => _typeResidence = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                /// ── SÉJOUR ───────────────────────────────────────────────
                _sectionLabel('SÉJOUR PROPOSÉ AVEC AUSSI RENOUVELABLE'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: _typeChambre,
                  hint: 'Type de séjour',
                  items: const ['Semaine', 'Mois', 'Année'],
                  onChanged: (v) => setState(() => _typeChambre = v),
                ),
                const SizedBox(height: 14),

                /// ── TYPE DE CHAMBRE ──────────────────────────────────────
                _sectionLabel('TYPE DE CHAMBRE'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: _typeChambre,
                  hint: 'Semaine',
                  items: const [
                    'Semaine',
                    'Studio',
                    'Chambre simple',
                    'Chambre double',
                  ],
                  onChanged: (v) => setState(() => _typeChambre = v),
                ),
                const SizedBox(height: 14),

                /// ── CAUTION BOULEE ───────────────────────────────────────
                _sectionLabel('CAUTION REQUISES'),
                const SizedBox(height: 8),
                _dropdownField(
                  value: _cautionBoulee,
                  hint: 'Caution Eau Save',
                  items: const ['Oui', 'Non', 'Partielle'],
                  onChanged: (v) => setState(() => _cautionBoulee = v),
                ),
                const SizedBox(height: 14),

                /// ── MONTANT TOTAL CAUTION ────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('MONTANT TOTAL CAUTION'),
                          const SizedBox(height: 8),
                          _inputField(
                            controller: TextEditingController(),
                            hint: 'Montant/caution',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(''),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Non',
                              style: TextStyle(fontSize: 12),
                            ),
                            Switch(
                              value: _negociable,
                              onChanged: (v) =>
                                  setState(() => _negociable = v),
                              activeColor: Colors.blue,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                /// ── NOMBRE DE PERSONNES ──────────────────────────────────
                _sectionLabel('NOMBRE DE MAXINUM PRÉVU'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (_nombreMaxPersonnes > 1) {
                            setState(() => _nombreMaxPersonnes--);
                          }
                        },
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Text(
                        '$_nombreMaxPersonnes',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _nombreMaxPersonnes++),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            /// ── CONTACT & DESCRIPTION ────────────────────────────────────
            _sectionCard(
              children: [
                _sectionLabel('CONTACT PROPRIÉTAIRE FIXÉ'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _contactController,
                  hint: '+229 00-00-00-00',
                  keyboardType: TextInputType.phone,
                  prefixIcon:
                      const Icon(Icons.phone, size: 18, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                _sectionLabel('DESCRIPTION (opt)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText:
                        'Prenez note, les informations & photos...',
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 13),
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
                  'Publier la chambre',
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

  Widget _sectionCard({required List<Widget> children}) {
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
        children: children,
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    Widget? prefixIcon,
  }) {
    return TextFormField(
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
    );
  }

  Widget _dropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
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
    );
  }

  Widget _dropdownCompact({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
    );
  }
}
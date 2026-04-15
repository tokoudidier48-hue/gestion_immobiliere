import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

class ModifierChambrePageLibre extends StatefulWidget {
  final Unites unite;
  const ModifierChambrePageLibre({super.key, required this.unite});

  @override
  State<ModifierChambrePageLibre> createState() => _ModifierChambrePageLibreState();
}

class _ModifierChambrePageLibreState extends State<ModifierChambrePageLibre> {
  final List<File> _newImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;

  late final TextEditingController _nomController;
  late final TextEditingController _villeController;
  late final TextEditingController _adresseController;
  late final TextEditingController _loyerController;
  late final TextEditingController _nbAvancesController;
  late final TextEditingController _cautionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contactController;

  late String? _typeDouche;
  late String? _typeCaution;
  late bool _prepaye;

  final Map<String, String> _cautionChoix = {
    'eau_seule': 'Caution eau seule',
    'electricite_seule': 'Caution électricité seule',
    'eau_et_electricite': 'Caution eau et électricité',
  };

  final Map<String, String> _doucheChoix = {
    'interne': 'Douche interne',
    'externe': 'Douche externe',
  };

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec les valeurs existantes
    _nomController = TextEditingController(text: widget.unite.nomUnite);
    _villeController = TextEditingController(text: widget.unite.ville);
    _adresseController = TextEditingController(text: widget.unite.adresse);
    _loyerController = TextEditingController(text: widget.unite.loyer.toInt().toString());
    _nbAvancesController = TextEditingController(text: widget.unite.nbrAvances.toString());
    _cautionController = TextEditingController(text: widget.unite.montantCaution.toInt().toString());
    _descriptionController = TextEditingController(text: widget.unite.description);
    _contactController = TextEditingController(text: widget.unite.contactProprietaire);
    _typeDouche = widget.unite.typeDouche.isNotEmpty ? widget.unite.typeDouche : null;
    _typeCaution = widget.unite.typeCaution.isNotEmpty ? widget.unite.typeCaution : null;
    _prepaye = widget.unite.prepaye;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _loyerController.dispose();
    _nbAvancesController.dispose();
    _cautionController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image != null && mounted) {
        setState(() => _newImages.add(File(image.path)));
      }
    } finally {
      _isPickingImage = false;
    }
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
          'Modifier l\'unité',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.unite.statut == 'libre' ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.unite.statut.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── PHOTOS ──────────────────────────────────────────────
            _sectionLabel('PHOTOS'),
            const SizedBox(height: 8),

            // Photos existantes
            if (widget.unite.photos.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.unite.photos.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(widget.unite.photos[index], fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),

            // Nouvelles photos
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue[300]!),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.blue[50],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: Colors.blue[400]),
                    const SizedBox(width: 8),
                    Text('Ajouter des photos', style: TextStyle(color: Colors.blue[400])),
                  ],
                ),
              ),
            ),

            if (_newImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(_newImages[index], fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 2, right: 10,
                          child: GestureDetector(
                            onTap: () => setState(() => _newImages.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── INFORMATIONS GÉNÉRALES ───────────────────────────────
            _sectionCard(
              title: 'INFORMATIONS GÉNÉRALES',
              children: [
                _inputField(label: 'Nom de l\'unité', controller: _nomController),
                const SizedBox(height: 12),
                _inputField(label: 'Ville', controller: _villeController),
                const SizedBox(height: 12),
                _inputField(label: 'Adresse complète', controller: _adresseController),
              ],
            ),
            const SizedBox(height: 14),

            // ── CONDITIONS FINANCIÈRES ───────────────────────────────
            _sectionCard(
              title: 'CONDITIONS FINANCIÈRES',
              children: [
                Row(
                  children: [
                    Expanded(child: _inputField(label: 'Loyer (FCFA)', controller: _loyerController, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _inputField(label: 'Nb. avances', controller: _nbAvancesController, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                _inputField(label: 'Prix caution (FCFA)', controller: _cautionController, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _mapDropdownField(
                  label: 'Type de caution',
                  value: _typeCaution,
                  hint: 'Choisir',
                  choix: _cautionChoix,
                  onChanged: (v) => setState(() => _typeCaution = v),
                ),
                const SizedBox(height: 12),
                _mapDropdownField(
                  label: 'Type de douche',
                  value: _typeDouche,
                  hint: 'Choisir',
                  choix: _doucheChoix,
                  onChanged: (v) => setState(() => _typeDouche = v),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.orange),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('Prépayé', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                      Switch(value: _prepaye, onChanged: (v) => setState(() => _prepaye = v), activeColor: Colors.blue),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── DÉTAILS & CONTACT ────────────────────────────────────
            _sectionCard(
              title: 'DÉTAILS & CONTACT',
              children: [
                _multilineField(label: 'Description', controller: _descriptionController),
                const SizedBox(height: 12),
                _inputField(
                  label: 'Contact direct',
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone, size: 18, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── BOUTON PUBLIER ───────────────────────────────────────
            Consumer<UniteProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : () async {
                      final uniteModifiee = Unites(
                        id: widget.unite.id,
                        proprieteId: widget.unite.proprieteId,
                        nomUnite: _nomController.text,
                        typeUnite: widget.unite.typeUnite, // ← on garde le type
                        adresse: _adresseController.text,
                        ville: _villeController.text,
                        loyer: double.tryParse(_loyerController.text) ?? widget.unite.loyer,
                        description: _descriptionController.text,
                        nbrAvances: int.tryParse(_nbAvancesController.text) ?? widget.unite.nbrAvances,
                        typeDouche: _typeDouche ?? widget.unite.typeDouche,
                        typeCaution: _typeCaution ?? widget.unite.typeCaution,
                        montantCaution: double.tryParse(_cautionController.text) ?? widget.unite.montantCaution,
                        contactProprietaire: _contactController.text,
                        prepaye: _prepaye,
                        garage: widget.unite.garage,
                        contratLocation: widget.unite.contratLocation,
                        statut: widget.unite.statut,
                        dateCreation: widget.unite.dateCreation,
                        photos: widget.unite.photos,
                      );

                      await provider.modifierUnite(uniteModifiee, _newImages);

                      if (!mounted) return;

                      if (provider.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur : ${provider.error}")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Unité modifiée avec succès !")),
                        );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('PUBLIER LES MODIFICATIONS',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5));

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _inputField({required String label, required TextEditingController controller, TextInputType? keyboardType, Widget? prefixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            prefixIcon: prefixIcon,
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
          ),
        ),
      ],
    );
  }

  Widget _multilineField({required String label, required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
          ),
        ),
      ],
    );
  }

  Widget _mapDropdownField({required String label, required String? value, required String hint, required Map<String, String> choix, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
          ),
          items: choix.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
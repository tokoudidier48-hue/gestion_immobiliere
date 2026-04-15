import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Mes_locataires.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

class PublierChambrePage extends StatefulWidget {
  final int proprieteId;
  const PublierChambrePage({super.key, required this.proprieteId});

  @override
  State<PublierChambrePage> createState() => _PublierChambrePageState();
}

class _PublierChambrePageState extends State<PublierChambrePage> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false; // ← une seule fois ici

  final _nomController = TextEditingController();
  final _villeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _loyerController = TextEditingController();
  final _nbAvancesController = TextEditingController();
  final _cautionController = TextEditingController();
  final _contactController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _typeDouche;
  String? _typeCaution;
  String? _typeUnite ;
  bool _prepaye = false;

  final Map<String, String> _cautionChoix = {
    'eau_seule': 'Caution eau seule',
    'electricite_seule': 'Caution électricité seule',
    'eau_et_electricite': 'Caution eau et électricité',
  };

  final Map<String, String> _doucheChoix = {
    'interne': 'Douche interne',
    'externe': 'Douche externe',
  };

  final Map<String, String> _typeUniteChoix = {
    'chambre_salon_ordinaire': 'Chambre salon ordinaire',
    'chambre_salon_sanitaire': 'Chambre salon sanitaire',
  };

  Future<void> _pickImage() async {
    if (_images.length >= 7 || _isPickingImage) return;
    _isPickingImage = true;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() => _images.add(File(image.path)));
      }
    } finally {
      _isPickingImage = false;
    }
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  @override
  void dispose() {
    _nomController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _loyerController.dispose();
    _nbAvancesController.dispose();
    _cautionController.dispose();
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
        title: const Text('Publier une Chambre',
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              _nomController.clear();
              _villeController.clear();
              _adresseController.clear();
              _loyerController.clear();
              _nbAvancesController.clear();
              _cautionController.clear();
              _contactController.clear();
              _descriptionController.clear();
              setState(() {
                _typeDouche = null;
                _typeCaution = null;
                _typeUnite = 'chambre_salon_ordinaire';
                _prepaye = false;
                _images.clear();
              });
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// ── NOM + PHOTOS ────────────────────────────────────────────
            _sectionCard(
              children: [
                _sectionLabel('NOM DE LA CHAMBRE'),
                const SizedBox(height: 8),
                _inputField(controller: _nomController, hint: 'Ex: Chambre confort'),
                const SizedBox(height: 14),

                _sectionLabel('TYPE DE CHAMBRE'),
                const SizedBox(height: 8),
                _mapDropdownField(
                  value: _typeUnite,
                  hint: 'Choisir',
                  choix: _typeUniteChoix,
                  onChanged: (v) => setState(() => _typeUnite = v),
                ),
                const SizedBox(height: 14),

                _sectionLabel('PHOTOS DE LA CHAMBRE (MAX 7)'),
                const SizedBox(height: 8),

                // Grande image principale
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 130,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                    child: _images.isEmpty
                        ? Center(child: Icon(Icons.camera_alt_outlined, size: 32, color: Colors.blue[300]))
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_images[0], fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 8, right: 8,
                                child: GestureDetector(
                                  onTap: () => _removeImage(0),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
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
                  childAspectRatio: 1.4,
                  children: List.generate(6, (index) {
                    final imageIndex = index + 1;
                    return GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                        child: imageIndex < _images.length
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(_images[imageIndex], fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4, right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(imageIndex),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Icon(Icons.camera_alt_outlined, color: Colors.blue[300], size: 22),
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 14),

            /// ── ADRESSE ──────────────────────────────────────────────────
            _sectionCard(
              children: [
                _sectionLabel('VILLE'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _villeController,
                  hint: 'Ex: Cotonou',
                  prefixIcon: const Icon(Icons.location_city, size: 18, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                _sectionLabel('ADRESSE'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _adresseController,
                  hint: 'Rechercher Quartier, Rue, Ville',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 14),

            /// ── DÉTAILS FINANCIERS ───────────────────────────────────────
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
                          _inputField(controller: _loyerController, hint: 'Montant', keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('NB. AVANCES'),
                          const SizedBox(height: 8),
                          _inputField(controller: _nbAvancesController, hint: 'Ex: 3', keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionLabel('PRIX CAUTION (FCFA)'),
                const SizedBox(height: 8),
                _inputField(controller: _cautionController, hint: 'Ex: 15000', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _mapDropdownField(
                  value: _typeCaution,
                  hint: 'Type de caution',
                  choix: _cautionChoix,
                  onChanged: (v) {
                    setState(() {
                      _typeCaution = v;
                    });
                    print(_typeCaution);
                  },
                ),
                const SizedBox(height: 12),
                _mapDropdownField(
                  value: _typeDouche,
                  hint: 'Type de douche',
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

            /// ── CONTACT & DESCRIPTION ────────────────────────────────────
            _sectionCard(
              children: [
                _sectionLabel('CONTACT PROPRIÉTAIRE'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _contactController,
                  hint: '+229 00-00-00-00',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone, size: 18, color: Colors.grey),
                ),
                const SizedBox(height: 14),
                _sectionLabel('DESCRIPTION (opt)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Prenez note, les informations & photos...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            /// ── BOUTON PUBLIER ────────────────────────────────────────────
            Consumer<ProprieteProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : () async {
                      final unite = Unites(
                        nomUnite: _nomController.text,
                        typeUnite: _typeUnite!,
                        adresse: _adresseController.text,
                        ville: _villeController.text,
                        loyer: double.tryParse(_loyerController.text) ?? 0,
                        description: _descriptionController.text,
                        nbrAvances: int.tryParse(_nbAvancesController.text) ?? 0,
                        typeDouche: _typeDouche ?? '',
                        typeCaution: _typeCaution ?? '',
                        montantCaution: double.tryParse(_cautionController.text) ?? 0,
                        contactProprietaire: _contactController.text,
                        prepaye: _prepaye,
                        garage: false,
                        contratLocation: '',
                        statut: 'Libre',
                        dateCreation: DateTime.now(),
                      );

                      await provider.ajouterUnite(widget.proprieteId, unite, _images);

                      if (!mounted) return;

                      if (provider.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur : ${provider.error}")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Chambre publiée avec succès !")),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MesMaisonsPage()
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Publier la chambre',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
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

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _inputField({required TextEditingController controller, String? hint, TextInputType? keyboardType, Widget? prefixIcon}) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }

  Widget _mapDropdownField({required String? value, required String hint, required Map<String, String> choix, required ValueChanged<String?> onChanged}) {
    return DropdownButtonFormField<String>(
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
    );
  }
}
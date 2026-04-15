import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Mes_locataires.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

class PublierBoutiquePage extends StatefulWidget {
  final int proprieteId;
  const PublierBoutiquePage({super.key, required this.proprieteId});

  @override
  State<PublierBoutiquePage> createState() => _PublierBoutiquePageState();
}

class _PublierBoutiquePageState extends State<PublierBoutiquePage> {
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _loyerController = TextEditingController();
  final _avancesController = TextEditingController();
  final _cautionController = TextEditingController();
  final _contactController = TextEditingController();

  String? _typeDouche;
  String? _typeCaution;
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

  Future<void> _pickImage() async {
    if (_images.length >= 7) return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) setState(() => _images.add(File(image.path)));
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _loyerController.dispose();
    _avancesController.dispose();
    _cautionController.dispose();
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
        title: const Text('Publier la boutique',
            style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              _nomController.clear();
              _descriptionController.clear();
              _adresseController.clear();
              _villeController.clear();
              _loyerController.clear();
              _avancesController.clear();
              _cautionController.clear();
              _contactController.clear();
              setState(() {
                _typeDouche = null;
                _typeCaution = null;
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
            /// ── PHOTOS ──────────────────────────────────────────────────
            _sectionLabel('Visuel (Max 7 photos)'),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                child: _images.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, size: 32, color: Colors.blue[400]),
                            const SizedBox(height: 4),
                            Text('AJOUTEZ UNE PHOTO',
                                style: TextStyle(fontSize: 11, color: Colors.blue[400], fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
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

            const SizedBox(height: 6),
            Text('Ajoutez jusqu\'à 7 photos pour mieux présenter votre boutique',
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),

            /// ── INFORMATIONS GÉNÉRALES ───────────────────────────────────
            _sectionCard(
              title: 'Informations générales',
              children: [
                _inputField(controller: _nomController, hint: 'Ex: Boutique Les Flairs'),
                const SizedBox(height: 12),
                _multilineField(controller: _descriptionController, hint: 'Décrivez les atouts de votre boutique...'),
              ],
            ),
            const SizedBox(height: 14),

            /// ── LOCALISATION ─────────────────────────────────────────────
            _sectionCard(
              title: 'Localisation',
              children: [
                _inputField(
                  controller: _villeController,
                  hint: 'Ex: Cotonou',
                  prefixIcon: const Icon(Icons.location_city, size: 18, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                _inputField(
                  controller: _adresseController,
                  hint: 'Rue 13, Cotonou...',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 14),

            /// ── DÉTAILS FINANCIERS ───────────────────────────────────────
            _sectionCard(
              title: 'Détails financiers',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('LOYER / FCFA / MOIS'),
                          const SizedBox(height: 6),
                          _inputField(controller: _loyerController, hint: '150 000', keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('NB. AVANCES'),
                          const SizedBox(height: 6),
                          _inputField(controller: _avancesController, hint: '3', keyboardType: TextInputType.number),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _inputField(controller: _cautionController, hint: 'Prix caution (FCFA)', keyboardType: TextInputType.number),
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

            /// ── CONTACT ──────────────────────────────────────────────────
            _sectionCard(
              title: 'Contact',
              children: [
                _fieldLabel('Numéro du propriétaire'),
                const SizedBox(height: 8),
                _inputField(
                  controller: _contactController,
                  hint: '+229 00-00-00-00',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone, size: 18, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 28),

            /// ── BOUTON PUBLIER ────────────────────────────────────────────
            Consumer<ProprieteProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: provider.isLoading ? null : () async {
                      final unite = Unites(
                        nomUnite: _nomController.text,
                        typeUnite: 'boutique',           // ← type boutique
                        adresse: _adresseController.text,
                        ville: _villeController.text,
                        loyer: double.tryParse(_loyerController.text) ?? 0,
                        description: _descriptionController.text,
                        nbrAvances: int.tryParse(_avancesController.text) ?? 0,
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
                          const SnackBar(content: Text("Boutique publiée avec succès !")),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => MesMaisonsPage()
                          ),
                        );
                      }
                    },
                    icon: provider.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.storefront, color: Colors.white, size: 20),
                    label: provider.isLoading
                        ? const Text('Publication...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white))
                        : const Text('Publier la boutique →', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
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
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87));

  Widget _fieldLabel(String text) => Text(text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.4));

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
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
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

  Widget _multilineField({required TextEditingController controller, String? hint}) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.blue)),
      ),
    );
  }

  Widget _mapDropdownField({required String label, required String? value, required String hint, required Map<String, String> choix, required ValueChanged<String?> onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label),
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
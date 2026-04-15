import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/provider/provider_profil.dart';
import 'package:provider/provider.dart';

const Color kLocataireBlue = Color(0xFF1A3C6E);

class ModificationProfilLocatairePage extends StatefulWidget {
  const ModificationProfilLocatairePage({super.key});

  @override
  State<ModificationProfilLocatairePage> createState() =>
      _ModificationProfilLocatairePageState();
}

class _ModificationProfilLocatairePageState
    extends State<ModificationProfilLocatairePage> {
  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  late TextEditingController _telephoneController;
  late TextEditingController _emailController;

  File? _newPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;
  bool _initialized = false;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _initControllers(Utilisateur profil) {
    if (_initialized) return;
    _prenomController = TextEditingController(text: profil.name);
    _nomController = TextEditingController(text: profil.lastName);
    _telephoneController = TextEditingController(text: profil.phoneNumber);
    _emailController = TextEditingController(text: profil.email);
    _initialized = true;
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        setState(() => _newPhoto = File(image.path));
      }
    } finally {
      _isPickingImage = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Modifier le profil',
          style: TextStyle(
              color: Colors.black87,
              fontSize: 17,
              fontWeight: FontWeight.w700),
        ),
      ),
      body: Consumer<ProfilProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !_initialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final profil = provider.profil;
          if (profil == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Profil introuvable',
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchProfil(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          _initControllers(profil);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // ── AVATAR ──────────────────────────────────────
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor:
                                        kLocataireBlue.withOpacity(0.15),
                                    backgroundImage: _newPhoto != null
                                        ? FileImage(_newPhoto!)
                                            as ImageProvider
                                        : profil.photoProfil != null
                                            ? NetworkImage(profil.photoProfil!)
                                            : null,
                                    child: (_newPhoto == null &&
                                            profil.photoProfil == null)
                                        ? Text(
                                            '${profil.name.isNotEmpty ? profil.name[0].toUpperCase() : ''}${profil.lastName.isNotEmpty ? profil.lastName[0].toUpperCase() : ''}',
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: kLocataireBlue),
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: kLocataireBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          color: Colors.white, size: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _pickImage,
                              child: const Text(
                                'Changer la photo',
                                style: TextStyle(
                                    color: kLocataireBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── CHAMPS ───────────────────────────────────────
                      Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            _buildField(
                                label: 'PRÉNOM',
                                controller: _prenomController),
                            _buildSeparator(),
                            _buildField(
                                label: 'NOM', controller: _nomController),
                            _buildSeparator(),
                            _buildField(
                              label: 'TÉLÉPHONE',
                              controller: _telephoneController,
                              keyboardType: TextInputType.phone,
                            ),
                            _buildSeparator(),
                            _buildField(
                              label: 'EMAIL',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              readOnly: true,
                              hint: 'Non modifiable',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── BOUTON ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    await provider.modifierProfil(
                                      firstName:
                                          _prenomController.text.trim(),
                                      lastName: _nomController.text.trim(),
                                      telephone:
                                          _telephoneController.text.trim(),
                                      photo: _newPhoto,
                                    );

                                    if (!mounted) return;

                                    if (provider.error != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Erreur : ${provider.error}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Profil mis à jour !'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kLocataireBlue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              elevation: 2,
                            ),
                            child: provider.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Enregistrer les modifications',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text('LoyaSmart • v4.0',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(
              fontSize: 15,
              color: readOnly ? Colors.grey.shade400 : Colors.black87,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: kLocataireBlue.withOpacity(0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Divider(
        height: 1,
        indent: 20,
        endIndent: 20,
        color: Colors.grey.shade200);
  }
}
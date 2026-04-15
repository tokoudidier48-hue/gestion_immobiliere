import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_flutter/model/utilisateur.dart';
import 'package:mobile_flutter/provider/provider_profil.dart';
import 'package:provider/provider.dart';

class ModifierProfilPage extends StatefulWidget {
  final Utilisateur profil;
  const ModifierProfilPage({super.key, required this.profil});

  @override
  State<ModifierProfilPage> createState() => _ModifierProfilPageState();
}

class _ModifierProfilPageState extends State<ModifierProfilPage> {
  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _emailController;

  File? _newPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController(text: widget.profil.name);
    _nomController = TextEditingController(text: widget.profil.lastName);
    _telephoneController = TextEditingController(text: widget.profil.phoneNumber);
    _emailController = TextEditingController(text: widget.profil.email);
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    super.dispose();
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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FA),
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Modifier le profil',
          style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── AVATAR ────────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey.shade300,
                                backgroundImage: _newPhoto != null
                                    ? FileImage(_newPhoto!) as ImageProvider
                                    : widget.profil.photoProfil != null
                                        ? NetworkImage(widget.profil.photoProfil!)
                                        : null,
                                child: (_newPhoto == null && widget.profil.photoProfil == null)
                                    ? Text(
                                        '${widget.profil.name.isNotEmpty ? widget.profil.name[0].toUpperCase() : ''}${widget.profil.lastName.isNotEmpty ? widget.profil.lastName[0].toUpperCase() : ''}',
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 2, right: 2,
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
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
                            style: TextStyle(color: Color(0xFF1565C0), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── CHAMPS ────────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildField(label: 'PRÉNOM', controller: _prenomController),
                        _buildSeparator(),
                        _buildField(label: 'NOM', controller: _nomController),
                        _buildSeparator(),
                        _buildField(label: 'TÉLÉPHONE', controller: _telephoneController, keyboardType: TextInputType.phone),
                        _buildSeparator(),
                        _buildField(
                          label: 'EMAIL',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          readOnly: true, // ← email non modifiable
                          hint: 'Non modifiable',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── BOUTON ────────────────────────────────────────────
                  Consumer<ProfilProvider>(
                    builder: (context, provider, child) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: provider.isLoading ? null : () async {
                              await provider.modifierProfil(
                                firstName: _prenomController.text.trim(),
                                lastName: _nomController.text.trim(),
                                telephone: _telephoneController.text.trim(),
                                photo: _newPhoto,
                              );

                              if (!mounted) return;

                              if (provider.error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Erreur : ${provider.error}"), backgroundColor: Colors.red),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Profil mis à jour !'), backgroundColor: Colors.green),
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 2,
                            ),
                            child: provider.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'Enregistrer les modifications',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  Text('LoyaSmart • v4.0', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
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
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500, letterSpacing: 0.8),
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
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Divider(height: 1, indent: 20, endIndent: 20, color: Colors.grey.shade200);
  }
}
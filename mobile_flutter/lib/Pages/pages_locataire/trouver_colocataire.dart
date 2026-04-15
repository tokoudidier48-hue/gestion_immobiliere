import 'package:flutter/material.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

class TrouverColocatairePage extends StatefulWidget {
  final int? uniteId;       // Si lanceur de recherche
  final int? rechercheId;   // Si postulant
  final bool estPostulant;  // true = postulant, false = lanceur

  const TrouverColocatairePage({
    super.key,
    this.uniteId,
    this.rechercheId,
    this.estPostulant = false,
  });

  @override
  State<TrouverColocatairePage> createState() => _TrouverColocatairePageState();
}

class _TrouverColocatairePageState extends State<TrouverColocatairePage> {
  final _formKey = GlobalKey<FormState>();
  final _filiereController = TextEditingController();
  final _villeController = TextEditingController();
  final _religionController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _filiereController.dispose();
    _villeController.dispose();
    _religionController.dispose();
    _telephoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.estPostulant ? 'Postuler à la colocation' : 'Trouver un colocataire',
          style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1A3C6E).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF1A3C6E), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.estPostulant
                            ? 'Remplissez vos informations pour postuler à cette colocation.'
                            : 'Remplissez vos critères pour trouver un colocataire idéal.',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1A3C6E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildField(
                label: 'Filière / Profession',
                controller: _filiereController,
                hint: 'Ex: Informatique, Médecine...',
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Ville',
                controller: _villeController,
                hint: 'Ex: Cotonou, Calavi...',
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Religion (Optionnel)',
                controller: _religionController,
                hint: 'Ex: Catholique, Musulman...',
                required: false,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: 'Numéro de téléphone',
                controller: _telephoneController,
                hint: '+229 00 00 00 00',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),
              _buildField(
                label: widget.estPostulant
                    ? 'Pourquoi êtes-vous intéressé ?'
                    : 'Description de votre recherche',
                controller: _descriptionController,
                hint: widget.estPostulant
                    ? 'Décrivez-vous et expliquez votre intérêt...'
                    : 'Décrivez votre colocataire idéal...',
                maxLines: 5,
              ),
              const SizedBox(height: 32),

              Consumer<ColocataireProvider>(
                builder: (context, provider, child) {
                  print("uniteId = ${widget.uniteId}");
print("rechercheId = ${widget.rechercheId}");
print("estPostulant = ${widget.estPostulant}");
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : () async {
                        if (!_formKey.currentState!.validate()) return;

                        bool success;

                        if (widget.estPostulant && widget.rechercheId != null) {
                          success = await provider.postuler(
                            rechercheId: widget.rechercheId!,
                            filiere: _filiereController.text.trim(),
                            ville: _villeController.text.trim(),
                            religion: _religionController.text.trim(),
                            telephone: _telephoneController.text.trim(),
                            description: _descriptionController.text.trim(),
                          );
                        } else if (widget.uniteId != null) {
                          success = await provider.lancerRecherche(
                            uniteId: widget.uniteId!,
                            filiere: _filiereController.text.trim(),
                            ville: _villeController.text.trim(),
                            religion: _religionController.text.trim(),
                            telephone: _telephoneController.text.trim(),
                            description: _descriptionController.text.trim(),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Informations manquantes")),
                          );
                          return;
                        }

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success
                                ? widget.estPostulant
                                    ? 'Candidature envoyée avec succès !'
                                    : 'Recherche lancée avec succès !'
                                : 'Vous avez déjà postulé ou lancé une recherche pour cette unité.'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );

                        if (success) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3C6E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: provider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.estPostulant ? 'Envoyer ma candidature' : 'Lancer la recherche',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: required
              ? (value) => (value == null || value.isEmpty) ? 'Ce champ est requis' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Color(0xFF1A3C6E), width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:mobile_flutter/model/proprietaire/proprietes.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

class ModifierMaisonPage extends StatefulWidget {
  final Propriete propriete;
  const ModifierMaisonPage({super.key, required this.propriete});

  @override
  State<ModifierMaisonPage> createState() => _ModifierMaisonPageState();
}

class _ModifierMaisonPageState extends State<ModifierMaisonPage> {
  late final TextEditingController _nomController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.propriete.nomPropriete);
  }

  @override
  void dispose() {
    _nomController.dispose();
    super.dispose();
  }

  String _formatNomMaison(String text) {
  final mots = text.trim().split(' ');
  if (mots.isEmpty) return text;
  
  final result = mots.asMap().entries.map((entry) {
    if (entry.key == 0) return entry.value; // ← premier mot tel quel
    return entry.value.toUpperCase();        // ← les suivants en majuscule
  }).join(' ');
  
  return result;
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
          'Modifier la maison',
          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'NOM DE LA MAISON',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nomController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: Résidence Balinor',
                      prefixIcon: const Icon(Icons.home_outlined, color: Colors.grey, size: 20),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            ),

            const SizedBox(height: 28),

            Consumer<ProprieteProvider>(
              builder: (context, provider, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : () async {
                      if (_nomController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Le nom ne peut pas être vide")),
                        );
                        return;
                      }

                      final proprieteModifiee = Propriete(
                        id: widget.propriete.id,
                        nomPropriete: _formatNomMaison(_nomController.text.trim()),
                        dateCreation: widget.propriete.dateCreation,
                      );

                      await provider.modifierPropriete(proprieteModifiee);

                      if (!mounted) return;

                      if (provider.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Erreur : ${provider.error}")),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Maison modifiée avec succès !")),
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
                        : const Text(
                            'ENREGISTRER LES MODIFICATIONS',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
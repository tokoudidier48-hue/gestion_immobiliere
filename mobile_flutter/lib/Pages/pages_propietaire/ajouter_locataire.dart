import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoyaSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const AjouterLocatairePage(),
    );
  }
}

class AjouterLocatairePage extends StatefulWidget {
  const AjouterLocatairePage({super.key});

  @override
  State<AjouterLocatairePage> createState() => _AjouterLocatairePageState();
}

class _AjouterLocatairePageState extends State<AjouterLocatairePage> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _contactController = TextEditingController();
  final _typeChambreController = TextEditingController();
  final _prixController = TextEditingController();
  final _avanceController = TextEditingController();

  String _prepaye = 'Avec prépayé';
  String _caution = "Caution de l'eau seul";

  final List<String> _prepayeOptions = [
    'Avec prépayé',
    'Sans prépayé',
  ];

  final List<String> _cautionOptions = [
    "Caution de l'eau seul",
    "Caution d'électricité",
    'Caution complète',
    'Sans caution',
  ];

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _contactController.dispose();
    _typeChambreController.dispose();
    _prixController.dispose();
    _avanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.home_work, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'LoyaSmart',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Ajouter un Locataire',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Veuillez remplir les informations du nouveau\nrésident.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Nom
            _buildLabel('Nom'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nomController,
              hint: 'Entrez le nom',
            ),
            const SizedBox(height: 18),

            // Prénom
            _buildLabel('Prénom'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _prenomController,
              hint: 'Entrez le prénom',
            ),
            const SizedBox(height: 18),

            // Contact
            _buildLabel('Contact'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _contactController,
              hint: 'Numéro de téléphone',
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(
                Icons.phone_outlined,
                size: 18,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 18),

            // Type de chambre
            _buildLabel('Type de chambre'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _typeChambreController,
              hint: 'Ex. Studio, 2 pièces...',
            ),
            const SizedBox(height: 18),

            // Prix
            _buildLabel('Prix'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _prixController,
              hint: 'Montant du loyer',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),

            // Nombre d'avance
            _buildLabel("Nombre d'avance"),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _avanceController,
              hint: 'Nombre de mois',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 18),

            // Prépayé
            _buildLabel('Prépayé'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _prepaye,
              items: _prepayeOptions,
              onChanged: (v) => setState(() => _prepaye = v!),
            ),
            const SizedBox(height: 18),

            // Caution
            _buildLabel('Caution'),
            const SizedBox(height: 8),
            _buildDropdown(
              value: _caution,
              items: _cautionOptions,
              onChanged: (v) => setState(() => _caution = v!),
            ),
            const SizedBox(height: 36),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white, size: 20),
                label: const Text(
                  'Ajouter le locataire',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    // Validation basique
    if (_nomController.text.isEmpty || _prenomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Locataire ajouté avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: prefixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
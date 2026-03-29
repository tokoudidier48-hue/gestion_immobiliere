import 'package:flutter/material.dart';

class ModifierChambrePageLibre extends StatelessWidget {
  const ModifierChambrePageLibre({super.key});

  Widget champ(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            )),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6AA3FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6AA3FF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget dropdown(String label, String value, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: options.contains(value) ? value : null,
          items: options
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: (v) {},
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6AA3FF)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6AA3FF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget miniature({bool add = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF6AA3FF)),
      ),
      child: add
          ? const Icon(Icons.add, color: Color(0xFF6AA3FF))
          : ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                "https://picsum.photos/200",
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text("Modifier la chambre"),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "À louer",
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            champ("Nom de la chambre", "Chambre salon sanitaire"),
            const SizedBox(height: 15),

            const Text("Photo de la chambre",
                style: TextStyle(fontSize: 12, color: Colors.grey)),

            const SizedBox(height: 8),

            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    "https://picsum.photos/500",
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.delete, size: 14, color: Colors.white),
                  ),
                )
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                miniature(),
                miniature(),
                miniature(),
                miniature(add: true),
              ],
            ),

            const SizedBox(height: 15),

            champ("Adresse", "Rue des Cocotiers, Cotonou"),
            const SizedBox(height: 12),

            champ("Loyer (FCFA)", "25000"),
            const SizedBox(height: 12),

            champ("Description", "Studio spacieux avec balcon"),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                    child: dropdown("Sanitaire", "Interne",
                        ["Interne", "Externe"])),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        dropdown("Douche", "Interne", ["Interne", "Externe"])),
              ],
            ),

            const SizedBox(height: 12),

            champ("Caution (mois)", "3"),
            const SizedBox(height: 12),

            champ("Marché de la caution (FCFA)", "25000"),
            const SizedBox(height: 12),

            dropdown("Prépayé", "Avec", ["Avec", "Sans"]),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                    child: dropdown("Cuisine", "Interne",
                        ["Interne", "Externe"])),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        dropdown("Douche", "Interne", ["Interne", "Externe"])),
              ],
            ),

            const SizedBox(height: 12),

            champ("Contact propriétaire", "+229 97 00 00 22"),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F80ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "PUBLIER LES MODIFICATIONS",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
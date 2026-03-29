import 'package:flutter/material.dart';
import 'package:mobile_flutter/widgets/widgets_proprietaire/custom_ch_occupee.dart';
import 'package:mobile_flutter/widgets/widgets_proprietaire/modifier_ch_occupee.dart';
class ModifierChambrePage extends StatefulWidget {
  const ModifierChambrePage({super.key});

  @override
  State<ModifierChambrePage> createState() =>
      _ModifierChambrePageState();
}

class _ModifierChambrePageState extends State<ModifierChambrePage> {

  final numeroCtrl = TextEditingController(text: "Chambre salon sanitaire");
  final adresseCtrl = TextEditingController(text: "Rue des Cocotiers, Cotonou");
  final loyerCtrl = TextEditingController(text: "50000");
  final descriptionCtrl = TextEditingController(text: "Studio spacieux avec balcon...");
  final nombrePiecesCtrl = TextEditingController(text: "3");
  final cautionCtrl = TextEditingController(text: "250000");

  String typeLocation = "Directe";
  String type = "Meublé";
  String pays = "Niger";
  String salle = "Douche";
  String sanitaires = "Interne";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier la chambre"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [

            /// SECTION STATUT
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.cancel, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Occupée", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// NUMERO
            CustomField(
              label: "Numéro de chambre",
              controller: numeroCtrl,
            ),

            const SizedBox(height: 15),

            /// IMAGES (mock)
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  buildImageBox(),
                  buildImageBox(),
                  buildImageBox(),
                  buildAddImageBox(),
                ],
              ),
            ),

            const SizedBox(height: 15),

            CustomField(
              label: "Adresse",
              controller: adresseCtrl,
            ),

            const SizedBox(height: 15),

            CustomField(
              label: "Loyer (FCFA)",
              controller: loyerCtrl,
            ),

            const SizedBox(height: 15),

            CustomField(
              label: "Description",
              controller: descriptionCtrl,
              maxLines: 3,
            ),

            const SizedBox(height: 15),

            CustomField(
              label: "Nombre de pièces (Min)",
              controller: nombrePiecesCtrl,
            ),

            const SizedBox(height: 15),

            CustomDropdown(
              label: "Type de location",
              value: typeLocation,
              items: const ["Directe", "Indirecte"],
              onChanged: (val) => setState(() => typeLocation = val!),
            ),

            const SizedBox(height: 15),

            CustomField(
              label: "Montant de la caution (FCFA)",
              controller: cautionCtrl,
            ),

            const SizedBox(height: 15),

            CustomDropdown(
              label: "Pays",
              value: pays,
              items: const ["Niger", "Bénin"],
              onChanged: (val) => setState(() => pays = val!),
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: CustomDropdown(
                    label: "Type",
                    value: type,
                    items: const ["Meublé", "Non meublé"],
                    onChanged: (val) => setState(() => type = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomDropdown(
                    label: "Salle",
                    value: salle,
                    items: const ["Douche", "Baignoire"],
                    onChanged: (val) => setState(() => salle = val!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            CustomDropdown(
              label: "Sanitaires",
              value: sanitaires,
              items: const ["Interne", "Externe"],
              onChanged: (val) => setState(() => sanitaires = val!),
            ),

            const SizedBox(height: 15),

            /// COORDONNÉES
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text("Coordonnées GPS : +229 97 00 00 22"),
            ),

            const SizedBox(height: 20),

            /// LOCATAIRE
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Locataire Actuel",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            const SizedBox(height: 10),

            Row(
              children: const [
                Expanded(child: Text("Jean Dupont")),
                Expanded(child: Text("Contact")),
                Expanded(child: Text("Email")),
              ],
            ),

            const SizedBox(height: 20),

            /// BOUTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: () {},
                child: const Text("PUBLIER LES MODIFICATIONS"),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildImageBox() {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget buildAddImageBox() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.add, color: Colors.blue),
    );
  }
}
/*
import 'package:flutter/material.dart';

class ModifierChambrePage extends StatelessWidget {
  const ModifierChambrePage({super.key});

  Widget field(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            )),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget imageCard({bool add = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: add
          ? const Icon(Icons.add, color: Colors.blue)
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "https://picsum.photos/200",
                fit: BoxFit.cover,
              ),
            ),
    );
  }

  Widget dropdown(String label, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            )),
        const SizedBox(height: 6),
        DropdownButtonFormField(
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e),
                  ))
              .toList(),
          onChanged: (v) {},
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Modifier la chambre",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            field("Nom de la chambre", "Ex: chambre confort"),

            const SizedBox(height: 20),

            Align(
                alignment: Alignment.centerLeft,
                child: Text("Photos de la chambre",
                    style: TextStyle(color: Colors.grey.shade600))),

            const SizedBox(height: 10),

            Row(
              children: [
                imageCard(),
                imageCard(),
                imageCard(),
                imageCard(add: true),
              ],
            ),

            const SizedBox(height: 20),

            field("Adresse", "Hêvié des Cocotiers, Cotonou"),

            const SizedBox(height: 12),

            field("Loyer", "25000"),

            const SizedBox(height: 12),

            field("Description", "Salle d'eau avec sanitaire"),

            const SizedBox(height: 12),

            dropdown("Type de douche", ["Interne", "Externe"]),

            const SizedBox(height: 12),

            dropdown("Type de cuisine", ["Interne", "Externe"]),

            const SizedBox(height: 12),

            dropdown("Prépayé", ["Avec", "Sans"]),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: field("Durée", "3 mois")),
                const SizedBox(width: 10),
                Expanded(child: field("Caution", "3 mois")),
              ],
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          "Jean Dupont\nCotonou\n+229 00 00 00 00")),
                ],
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {},
                child: const Text(
                  "PUBLIER LES MODIFICATIONS",
                  style: TextStyle(fontSize: 15),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}*/
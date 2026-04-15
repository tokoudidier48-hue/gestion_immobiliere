import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/maisons_creer.dart';
import 'package:mobile_flutter/model/proprietaire/proprietes.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

class HomeNew extends StatefulWidget {
  const HomeNew({super.key});

  @override
  State<HomeNew> createState() => _HomeNewState();
}

class _HomeNewState extends State<HomeNew> {
  final nomMaisonController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🔹 APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[100],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LoyaSmart",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "PROPRIÉTAIRE",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // 🔹 BODY
      body: Padding(
        padding: const EdgeInsets.fromLTRB(5, 50, 5, 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🏠 TITLE
              const Text(
                "Nouvelle Maison",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 LABEL
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "NOM DU PROPRIÉTAIRE",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 🔹 TEXT FIELD
              TextField(
                controller: nomMaisonController,
                decoration: InputDecoration(
                  hintText: "Entrez votre nom complet",
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 🔹 BUTTON
              Consumer<ProprieteProvider>(
                builder: (context, provider, child) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: () async {
                        final provider = context.read<ProprieteProvider>();

                        final propriete = Propriete(
                          nomPropriete: '${"Maison "}${(nomMaisonController.text).toUpperCase()}',
                        );

                        await provider.creerPropriete(propriete);

                        if (provider.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Erreur : ${provider.error}")),
                          );
                        } else {
                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const MaisonsCreer()),
                            );
                          }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Créer votre maison",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                          ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white),
                    ],
                  ),
                ),
              );
                },)
            ],
          ),
        ),
      ),

    );
  }

}
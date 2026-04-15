import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_appartement.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_boutique.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_chambre.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_deux_chambre.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_entree_couchee.dart';
import 'package:mobile_flutter/widgets/widgets_proprietaire/CategoryCard.dart';

class CreerUnite extends StatelessWidget {
  final int idPropriete; // ID de la propriété à laquelle l'unité sera associée
  const CreerUnite({super.key, required this.idPropriete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // APPBAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.home_work, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              "LOYASMART",
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),

      // BODY
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Gestion des Biens",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 5),

            Text(
              "Sélectionnez une catégorie pour gérer vos unités",
              style: TextStyle(color: Colors.grey),
            ),

            SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [

                  CategoryCard(
                    icon: Icons.apartment,
                    color: Colors.blue,
                    title: "Appartement",
                    onTap: () {
                      print("Appartement cliqué");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  PublierAppartementPage(proprieteId: idPropriete)),
                      );
                    },
                  ),

                  CategoryCard(
                    icon: Icons.store,
                    color: Colors.orange,
                    title: "Boutique",
                    onTap: () {
                      print("Boutique cliqué");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  PublierBoutiquePage(proprieteId: idPropriete)),
                      );
                    },
                  ),

                  CategoryCard(
                    icon: Icons.bed,
                    color: Colors.green,
                    title: "Chambre salon",
                    onTap: () {
                      print("Appartement cliqué");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  PublierChambrePage(proprieteId: idPropriete)),
                      );
                    },
                  ),

                   CategoryCard(
                    icon: Icons.bathtub,
                    color: Colors.purple,
                    title: "Entrée coucher",
                    onTap: (){
                      print("Entrée coucher cliqué");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  PublierEntreeCoucherPage(proprieteId: idPropriete)),
                      );
                    }
                  ),

                   CategoryCard(
                    icon: Icons.meeting_room,
                    color: Colors.grey,
                    title: "Deux\nchambres salon",
                    onTap: (){
                        print("Deux chambres salon cliqué");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>  PublierDeuxChambresSalonPage(proprieteId: idPropriete)),
                        );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


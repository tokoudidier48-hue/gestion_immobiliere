import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_appartement.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_boutique.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_chambre.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/Pages_unite/publier_appartement.dart';
import 'package:mobile_flutter/widgets/widgets_proprietaire/CategoryCard.dart';

class CreerUnite extends StatelessWidget {
  const CreerUnite({super.key});

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
        actions: [
          Icon(Icons.notifications_none, color: Colors.black),
          SizedBox(width: 10),
          CircleAvatar(
            backgroundImage: NetworkImage(
              "https://i.pravatar.cc/150?img=3",
            ),
          ),
          SizedBox(width: 10),
        ],
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
                        MaterialPageRoute(builder: (context) => const PublierAppartementPage()),
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
                        MaterialPageRoute(builder: (context) => const PublierBoutiquePage()),
                      );
                    },
                  ),

                  CategoryCard(
                    icon: Icons.bed,
                    color: Colors.green,
                    title: "Chambre salon\nordinaire",
                    onTap: () {
                      print("Appartement cliqué");
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PublierChambrePage()),
                      );
                    },
                    
                  ),

                  const CategoryCard(
                    icon: Icons.bathtub,
                    color: Colors.purple,
                    title: "Chambre salon\nsanitaire",
                  ),

                  const CategoryCard(
                    icon: Icons.meeting_room,
                    color: Colors.grey,
                    title: "Entrée coucher\nordinaire",
                  ),

                  const CategoryCard(
                    icon: Icons.shower,
                    color: Colors.red,
                    title: "Entrée coucher\nsanitaire",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🔹 BOTTOM NAVBAR
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home), 
            label: "Accueil",
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment), 
            label: "Mes Biens",
          ),
          NavigationDestination(
            icon: Icon(Icons.people), 
            label: "Locataires",
          ),
          NavigationDestination(
            icon: Icon(Icons.message), 
            label: "Messages",
          )
        ]
      ),
    );
  }
}


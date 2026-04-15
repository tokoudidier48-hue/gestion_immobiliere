import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/creer_unite.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/nouvelle_maison.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

class MaisonsCreer extends StatefulWidget {
  const MaisonsCreer({super.key});

  @override
  State<MaisonsCreer> createState() => _MaisonsCreerState();
}

class _MaisonsCreerState extends State<MaisonsCreer> {
  @override
  void initState() {
    super.initState();
    // Charge les propriétés dès l'ouverture de la page
    Future.microtask(() =>
      context.read<ProprieteProvider>().fetchProprietes()
    );
  }
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
            const Text(
              "LoyaSmart",
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),

      // 🔹 BODY
      body:  Consumer<ProprieteProvider>(
  builder: (context, provider, child) {

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null) {
      return Center(child: Text("Erreur : ${provider.error}"));
    }

    final proprietes = provider.proprietes;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MES MAISONS",
                style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              Text(
                "${proprietes.length} TOTAL",  // ← dynamique
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 🔹 LISTE DES PROPRIÉTÉS
          Expanded(
            child: ListView.builder(
              itemCount: proprietes.length,
              itemBuilder: (context, index) {
                final propriete = proprietes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            propriete.nomPropriete,  // ← dynamique
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "Active",
                              style: TextStyle(color: Colors.blue, fontSize: 12),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) =>  CreerUnite(idPropriete: propriete.id!)),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Ajouter les Chambres"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

            // 🔹 BOUTON POINTILLÉ
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeNew()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DashedBorderPainter(),
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "Créer Une Maison",
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }    
  ),
  );
      
  }
}


// 🎨 Bordure pointillée
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6;
    const dashSpace = 4;

    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(12),
        ),
      );

    final dashPath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0;
      while (distance < pathMetric.length) {
        final next = distance + dashWidth;
        dashPath.addPath(
          pathMetric.extractPath(distance, next),
          Offset.zero,
        );
        distance = next + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
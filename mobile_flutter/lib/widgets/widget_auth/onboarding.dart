import 'package:flutter/material.dart';

class OnboardingWidget extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingWidget({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),

          /// IMAGE CARD
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black.withOpacity(0.1),
                )
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    image,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                /// PETIT BADGE
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Icon(Icons.auto_graph, color: Colors.blue),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Chambre confortable",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "Prix abordable aux Etudiants",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// TITLE
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          /// DESCRIPTION
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
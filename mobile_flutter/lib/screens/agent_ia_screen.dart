import 'package:flutter/material.dart';

class AgentIaScreen extends StatelessWidget {
  const AgentIaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            /// 🔵 HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF137FEC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Color(0xFF137FEC),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Assistant LoyaSmart",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        "En ligne",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.more_vert, color: Colors.grey),
                ],
              ),
            ),

            /// 💬 MESSAGE IA
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFF137FEC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.apartment,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(20),
                            bottomRight: Radius.circular(20),
                            bottomLeft: Radius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Bonjour ! Je suis votre assistant intelligent LoyaSmart.\n\n"
                          "Je peux vous aider à trouver le logement idéal par texte ou par la voix.\n\n"
                          "Que recherchez-vous aujourd'hui ?",
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔎 SUGGESTIONS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _suggestionChip("Chambre à Calavi"),
                  _suggestionChip("Appartement F3"),
                  _suggestionChip("Boutique à Cotonou"),
                ],
              ),
            ),

            /// ✍️ INPUT + MIC
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Décrivez votre recherche...",
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF137FEC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.mic, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}
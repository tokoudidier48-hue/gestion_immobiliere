import 'package:flutter/material.dart';


class HomePageLocataire extends StatefulWidget {
  const HomePageLocataire({super.key});

  @override
  State<HomePageLocataire> createState() => _HomePageLocataireState();
}

class _HomePageLocataireState extends State<HomePageLocataire> {
  int currentIndex = 0;
  int page = 1;

  List<Map<String, dynamic>> logements = List.generate(20, (index) {
    return {
      'prix': (50000 + index * 5000),
      'titre': 'Appartement ${index + 1}',
      'ville': 'Cotonou, Bénin',
      'statut': index % 2 == 0 ? 'LIBRE' : 'OCCUPÉ'
    };
  });

  List<Map<String, dynamic>> get paginatedData {
    int start = (page - 1) * 10;
    int end = start + 10;
    return logements.sublist(start, end > logements.length ? logements.length : end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
     
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("LoyaSmart", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Icon(Icons.notifications_none)
                ],
              ),
              const SizedBox(height: 10),

              // Search
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search),
                    hintText: 'Cotonou, Fidjrossè... ',
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Filters
              Row(
                children: [
                  _filterChip("Tous", true),
                  const SizedBox(width: 8),
                  _filterChip("Appartement", false),
                  const SizedBox(width: 8),
                  _filterChip("Chambre", false),
                ],
              ),

              const SizedBox(height: 10),
              const Text("Logements en vedette", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // List
              Expanded(
                child: ListView.builder(
                  itemCount: paginatedData.length,
                  itemBuilder: (context, index) {
                    var logement = paginatedData[index];
                    return _logementCard(logement);
                  },
                ),
              ),

              // Pagination
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: page > 1
                        ? () {
                            setState(() {
                              page--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text("Page $page"),
                  IconButton(
                    onPressed: page * 10 < logements.length
                        ? () {
                            setState(() {
                              page++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String text, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: selected ? Colors.white : Colors.black),
      ),
    );
  }

  Widget _logementCard(Map logement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text("Image")),
          ),
          const SizedBox(height: 8),
          Text("${logement['prix']} CFA / mois", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(logement['titre']),
          Text(logement['ville'], style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: logement['statut'] == 'LIBRE' ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(logement['statut'], style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: () {},
            child: const Text("Chercher un colocataire"),
          )
        ],
      ),
    );
  }
}

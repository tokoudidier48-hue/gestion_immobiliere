import 'package:flutter/material.dart';

class MesBiensPage extends StatefulWidget {
  const MesBiensPage({super.key});

  @override
  State<MesBiensPage> createState() => _MesBiensPageState();
}

class _MesBiensPageState extends State<MesBiensPage> {
  int _selectedCategory = 0;
  int _selectedTab = 0;

  final List<String> _categories = [
    'Appartement',
    'Boutique',
    'Chambre salon sanitaire',
  ];

  final List<String> _tabs = ['Tous', 'Likes', 'Réservés', 'Occupés'];

  final List<Map<String, dynamic>> _biens = [
    {
      'title': 'Villa Horizon',
      'location': 'Cotonou, Fidjrossè Plage',
      'address': 'auto-ressen',
      'price': '750k',
      'priceLabel': 'PAR MOIS',
      'badge': 'LIBRE',
      'badgeColor': Color(0xFF4CAF50),
      'views': '1',
      'likes': '1 247',
      'image': 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=600',
    },
    {
      'title': 'Résidence Marina',
      'location': 'Cotonou, Fidjrossè Plage',
      'address': 'auto-ressen',
      'price': '120k',
      'priceLabel': 'PAR MOIS',
      'badge': 'A LOUER',
      'badgeColor': Color(0xFF2196F3),
      'views': '9 876',
      'likes': null,
      'image': 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=600',
    },
    {
      'title': 'Studio Cazelier',
      'location': 'Cotonou, Fidjrossè Plage',
      'address': 'auto-ressen',
      'price': '45k',
      'priceLabel': 'PAR MOIS',
      'badge': 'SÉJOUR',
      'badgeColor': Color(0xFFFF9800),
      'views': null,
      'likes': null,
      'image': 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=600',
    },
    {
      'title': "Appartement L'Escale",
      'location': 'Cotonou, Fidjrossè Plage',
      'address': 'auto-ressen',
      'price': '350k',
      'priceLabel': 'PAR MOIS',
      'badge': 'OCCUPÉ',
      'badgeColor': Color(0xFFF44336),
      'views': null,
      'likes': null,
      'image': 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=600',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Mes Biens',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── TABS (Tous / Likes / Récents / Occupés) ───────────────────
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final selected = i == _selectedTab;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 20, top: 10),
                          padding: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: selected
                                    ? Colors.blue[700]!
                                    : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selected
                                  ? Colors.blue[700]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const Divider(height: 1),

                // ── FILTRES CATÉGORIES ──────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: List.generate(_categories.length, (i) {
                      final selected = i == _selectedCategory;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = i),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blue[700]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _categories[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ── LISTE DES BIENS ───────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: _biens.length,
              itemBuilder: (context, index) {
                return _buildBienCard(_biens[index]);
              },
            ),
          ),
        ],
      ),

      // ── BOTTOM NAV ────────────────────────────────────────────────────
     bottomNavigationBar: NavigationBar(
      selectedIndex: 1, // "Mes Biens" actif par défaut
      onDestinationSelected: (index) {
        // navigation ici
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.apartment_outlined),
          selectedIcon: Icon(Icons.apartment),
          label: 'Mes Biens',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Locataires',
        ),
        NavigationDestination(
          icon: Icon(Icons.message_outlined),
          selectedIcon: Icon(Icons.message),
          label: 'Messages',
        ),
      ],
    ),
    );
  }

  Widget _buildBienCard(Map<String, dynamic> bien) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── IMAGE + BADGE ────────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: Image.network(
                  bien['image'],
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 170,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
              // Badge statut
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bien['badgeColor'],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bien['badge'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
              ),

          // ── INFOS ────────────────────────────────────────────────────
          Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre + Prix sur la même ligne
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bien['title'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          bien['price'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Text(
                          bien['priceLabel'],
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 3),
                  Text(
                    bien['location'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.storefront_outlined, size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Text(
                    bien['address'],
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Statistiques (vues / likes)
              if (bien['views'] != null || bien['likes'] != null)
                Row(
                  children: [
                    if (bien['views'] != null) ...[
                      Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        bien['views'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 14),
                    ],
                    if (bien['likes'] != null) ...[
                      Icon(Icons.favorite_outline, size: 14, color: Colors.red[300]),
                      const SizedBox(width: 4),
                      Text(
                        bien['likes'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}
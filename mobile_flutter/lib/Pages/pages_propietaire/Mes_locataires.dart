import 'package:flutter/material.dart';

class MesMaisonsPage extends StatelessWidget {
  const MesMaisonsPage({super.key});

  final List<Map<String, dynamic>> _maisons = const [
    {
      'nom': 'Maison 1',
      'proprietaire': 'Jean Dupont',
      'locataires': 12,
    },
    {
      'nom': 'Maison 2',
      'proprietaire': 'Jean Dupont',
      'locataires': 8,
    },
    {
      'nom': 'Maison 3',
      'proprietaire': 'Jean Dupont',
      'locataires': 5,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Mes Maisons',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BARRE DE RECHERCHE ─────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une maison...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ── SOUS-TITRE ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              'Sélectionnez une maison pour gérer ses locataires',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),

          // ── LISTE DES MAISONS ──────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _maisons.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final maison = _maisons[index];
                return _buildMaisonCard(maison);
              },
            ),
          ),
        ],
      ),

      // ── BOTTOM NAV ─────────────────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (_) {},
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          const NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Mes Biens',
          ),
          NavigationDestination(
            icon: Badge(
              child: const Icon(Icons.people_outline),
            ),
            selectedIcon: const Icon(Icons.people),
            label: 'Locataires',
          ),
          NavigationDestination(
            icon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.message_outlined),
            ),
            selectedIcon: Badge(
              label: const Text('3'),
              child: const Icon(Icons.message),
            ),
            label: 'Messages',
          ),
        ],
      ),
    );
  }

  Widget _buildMaisonCard(Map<String, dynamic> maison) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── EN-TÊTE MAISON ─────────────────────────────────────────────
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.home, color: Colors.blue[700], size: 22),
            ),
            title: Text(
              maison['nom'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              'Propriétaire: ${maison['proprietaire']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ),

          // ── SÉPARATEUR ─────────────────────────────────────────────────
          Divider(height: 1, color: Colors.grey[100], indent: 14, endIndent: 14),

          // ── LOCATAIRES ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people_outline,
                        size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      '${maison['locataires']} Locataires',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Voir les chambres ajoutées',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
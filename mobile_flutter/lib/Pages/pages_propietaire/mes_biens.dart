import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/proprio_navBar.dart';
import 'package:mobile_flutter/model/proprietaire/unites.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

class MesBiensPage extends StatefulWidget {
  const MesBiensPage({super.key});

  @override
  State<MesBiensPage> createState() => _MesBiensPageState();
}

class _MesBiensPageState extends State<MesBiensPage> {
  int _selectedCategory = 0;
  int _selectedTab = 0;

  final List<String> _tabs = ['Tous', 'Libre', 'Réservés', 'Occupés'];

  final Map<String, String> _categoriesMap = {
    'tous': 'Tous',
    'appartement': 'Appartement',
    'boutique': 'Boutique',
    'chambre_salon_sanitaire': 'Chambre salon sanitaire',
    'chambre_salon_ordinaire': 'Chambre salon ordinaire',
    'entree_coucher_ordinaire': 'Entrée coucher ordinaire',
    'entree_coucher_sanitaire': 'Entrée coucher sanitaire',
    'deux_chambres_ordinaire': 'Deux chambres ordinaire',
    'deux_chambres_sanitaire': 'Deux chambres sanitaire',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<UniteProvider>().fetchUnites()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Mes Biens',
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black54),
            onPressed: () => context.read<UniteProvider>().fetchUnites(),
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        )
      ),
      body: Consumer<UniteProvider>(
        builder: (context, provider, child) {

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text("Erreur : ${provider.error}"));
          }

          // Filtre par catégorie
          final categorieKey = _categoriesMap.keys.toList()[_selectedCategory];
          var unitesFiltrees = categorieKey == 'tous'
              ? provider.unites
              : provider.unites.where((u) => u.typeUnite == categorieKey).toList();

          // Filtre par statut (tabs)
          final List<String> statutKeys = ['tous', 'libre', 'reserve', 'occupe'];
          final statutKey = statutKeys[_selectedTab];
          if (statutKey != 'tous') {
            unitesFiltrees = unitesFiltrees.where((u) => u.statut == statutKey).toList();
          }

          return Column(
            children: [
              // ── TABS ──────────────────────────────────────────────────
              Container(
                color: Colors.white,
                child: Column(
                  children: [
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
                                    color: selected ? Colors.blue[700]! : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              child: Text(
                                _tabs[i],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                  color: selected ? Colors.blue[700] : Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const Divider(height: 1),

                    // ── FILTRES CATÉGORIES ────────────────────────────────
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: List.generate(_categoriesMap.length, (i) {
                          final selected = i == _selectedCategory;
                          final label = _categoriesMap.values.toList()[i];
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = i),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? Colors.blue[700] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
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

              // ── LISTE DES UNITÉS ───────────────────────────────────────
              Expanded(
                child: unitesFiltrees.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.apartment_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text('Aucun bien dans cette catégorie',
                                style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: unitesFiltrees.length,
                        itemBuilder: (context, index) {
                          return _buildBienCard(unitesFiltrees[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),

      // ── BOTTOM NAV ────────────────────────────────────────────────────
      // mes_biens.dart
      bottomNavigationBar: const ProprioNavBar(selectedIndex: 1),
    );
  }

  Widget _buildBienCard(Unites unite) {
    Color badgeColor;
    String badgeLabel;
    switch (unite.statut) {
      case 'libre':
        badgeColor = const Color(0xFF4CAF50);
        badgeLabel = 'LIBRE';
        break;
      case 'occupe':
        badgeColor = const Color(0xFFF44336);
        badgeLabel = 'OCCUPÉ';
        break;
      case 'reserve':
        badgeColor = const Color(0xFFFF9800);
        badgeLabel = 'RÉSERVÉ';
        break;
      default:
        badgeColor = Colors.grey;
        badgeLabel = unite.statut.toUpperCase();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── IMAGE + BADGE ────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: unite.photos.isNotEmpty
                    ? Image.network(
                        unite.photos[0],
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 170,
                          color: Colors.grey[300],
                          child: const Icon(Icons.apartment, size: 60, color: Colors.grey),
                        ),
                      )
                    : Container(
                        height: 170,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.apartment, size: 60, color: Colors.grey),
                      ),
              ),
              Positioned(
                top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(badgeLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          // ── INFOS ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(unite.nomUnite,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${unite.loyer.toInt()} FCFA',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                          const Text('PAR MOIS',
                              style: TextStyle(fontSize: 9, color: Colors.grey, letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text('${unite.ville}, ${unite.adresse}, ',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.category_outlined, size: 13, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(unite.typeUnite,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
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
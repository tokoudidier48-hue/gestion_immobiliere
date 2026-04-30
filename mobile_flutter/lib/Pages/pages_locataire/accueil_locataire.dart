import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/assistant_ia_page.dart';
import 'package:mobile_flutter/Pages/pages_locataire/detail_unite.dart';
import 'package:mobile_flutter/Pages/pages_locataire/locataire_navbar.dart';
import 'package:mobile_flutter/Pages/pages_locataire/notification_locataire.dart';
import 'package:mobile_flutter/Pages/pages_locataire/trouver_colocataire.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

class AccueilLocatairePage extends StatefulWidget {
  const AccueilLocatairePage({super.key});

  @override
  State<AccueilLocatairePage> createState() => _AccueilLocatairePageState();
}

class _AccueilLocatairePageState extends State<AccueilLocatairePage> {
  int _selectedTab = 0;
  String _searchQuery = '';

  final Map<int, String> _tabTypes = {
    0: 'tous',
    1: 'appartement',
    2: 'boutique',
    3: 'chambre_salon_ordinaire',
    4: 'chambre_salon_sanitaire',
    5: 'entree_coucher_ordinaire',
    6: 'entree_coucher_sanitaire',
    7: 'deux_chambres_ordinaire',
    8: 'deux_chambres_sanitaire',
  };

  final List<String> _tabLabels = [
    'Tous',
    'Appartement',
    'Boutique',
    'Chambre salon',
    'Ch. salon sanitaire',
    'Entrée coucher',
    'Entrée c. sanitaire',
    'Deux chambres',
    'Deux ch. sanitaire',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<UniteDProvider>().fetchUnitesDisponibles();
    });
  }

  List<dynamic> _filtrerUnites(List<dynamic> unites) {
    final typeSelectionne = _tabTypes[_selectedTab] ?? 'tous';

    return unites.where((u) {
      final matchType = typeSelectionne == 'tous' ||
          (u['type_unite'] ?? '') == typeSelectionne;
      final matchSearch = _searchQuery.isEmpty ||
          (u['nom'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u['ville'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u['adresse'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchType && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Consumer<UniteDProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text('Vérifiez votre connexion internet et réessayez',
                              style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => provider.fetchUnitesDisponibles(),
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    );
                  }

                  final unitesFiltrees = _filtrerUnites(provider.unites);

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterTabs(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Logements disponibles',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                              Text(
                                '${unitesFiltrees.length} résultat(s)',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        if (unitesFiltrees.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.home_outlined, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  Text('Aucun logement dans cette catégorie',
                                      style: TextStyle(color: Colors.grey[400])),
                                ],
                              ),
                            ),
                          )
                        else
                          ...unitesFiltrees.map((u) => _buildListingCard(context, u)).toList(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const LocataireNavBar(selectedIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'LoyaSmart',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A3C6E)),
              ),
              const Spacer(),
              // ← Bouton IA
              IconButton(
                icon: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3C6E).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFF1A3C6E), size: 18),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssistantIaPage()),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationLocatairePage()),
                  );
                },
                child: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 26),
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Cotonou, Fidjrossè, Calavi...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                icon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: List.generate(_tabLabels.length, (i) {
          final selected = _selectedTab == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedTab = i),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1A3C6E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? const Color(0xFF1A3C6E) : Colors.grey.shade300,
                ),
              ),
              child: Text(
                _tabLabels[i],
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, Map<String, dynamic> u) {
    final photos = (u['photos'] as List?) ?? [];
    final image = photos.isNotEmpty ? photos[0]['image'] ?? '' : '';
    final prix = u['loyer']?.toString() ?? '0';
    final titre = u['nom'] ?? 'Sans titre';
    final adresse = '${u['ville'] ?? ''}, ${u['adresse'] ?? ''}';
    final statut = (u['statut'] ?? 'lbr').toString();
    final prepaye = u['prepaye'] == true;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailsLogementPage(unite: u)),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: image.isNotEmpty
                      ? Image.network(
                          image,
                          height: 160, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160, color: Colors.grey.shade200,
                            child: const Icon(Icons.image, size: 50, color: Colors.grey),
                          ),
                        )
                      : Container(
                          height: 160, color: Colors.grey.shade200,
                          child: const Icon(Icons.apartment, size: 50, color: Colors.grey),
                        ),
                ),
                // Badge statut
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statut == 'libre' ? Colors.green : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(statut.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                // Prix overlay
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                      ),
                    ),
                    child: Text('$prix FCFA / mois',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(titre,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3C6E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(prepaye ? Icons.bolt : Icons.bolt_outlined,
                                size: 12, color: const Color(0xFF1A3C6E)),
                            const SizedBox(width: 3),
                            Text(
                              prepaye ? 'AVEC PRÉPAYÉ' : 'SANS PRÉPAYÉ',
                              style: const TextStyle(fontSize: 9, color: Color(0xFF1A3C6E), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(adresse,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  // Bouton colocataire si libre
                  if (statut == 'libre') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrouverColocatairePage(
                                uniteId: u['id'],     // ← passe l'ID de l'unité
                                estPostulant: false,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.person_add_outlined, size: 16),
                        label: const Text('CHERCHER UN COLOCATAIRE',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3C6E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
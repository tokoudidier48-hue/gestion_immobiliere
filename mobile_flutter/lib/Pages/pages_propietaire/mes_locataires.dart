import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locataires',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const LocatairesPage(),
    );
  }
}

class Locataire {
  final String nom;
  final String appart;
  final String loyer;
  final Color avatarColor;

  const Locataire({
    required this.nom,
    required this.appart,
    required this.loyer,
    required this.avatarColor,
  });
}

class LocatairesPage extends StatefulWidget {
  const LocatairesPage({super.key});

  @override
  State<LocatairesPage> createState() => _LocatairesPageState();
}

class _LocatairesPageState extends State<LocatairesPage> {
  int _currentIndex = 2;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Locataire> _locataires = const [
    Locataire(
      nom: 'Koffi Mensah',
      appart: 'Appt 4B',
      loyer: '75 000 CFA',
      avatarColor: Color(0xFFE57373),
    ),
    Locataire(
      nom: 'Awa Diallo',
      appart: 'Appt 2A',
      loyer: '120 000 CFA',
      avatarColor: Color(0xFF81C784),
    ),
    Locataire(
      nom: 'Sessi Houedanou',
      appart: 'Chambre 12',
      loyer: '45 000 CFA',
      avatarColor: Color(0xFF64B5F6),
    ),
  ];

  List<Locataire> get _filtered => _locataires
      .where((l) =>
          l.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          l.appart.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        title: const Text(
          'Locataires de la Maison 1',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + button
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher un locataire...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF4F6FA),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Ajouter button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.person_add_alt_1, size: 18, color: Colors.white),
                    label: const Text(
                      'Ajouter un locataire',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun locataire trouvé',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _LocataireCard(locataire: _filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LocataireCard extends StatelessWidget {
  final Locataire locataire;

  const _LocataireCard({required this.locataire});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Top row: avatar + name + loyer
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: locataire.avatarColor,
                child: Text(
                  locataire.nom[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locataire.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      locataire.appart,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                locataire.loyer,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 10),

          // Action buttons
          Row(
            children: [
              _ActionButton(
                icon: Icons.visibility_outlined,
                label: 'Voir détail',
                color: Colors.black87,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _ActionButton(
                icon: Icons.edit_outlined,
                label: 'Modifier',
                color: Colors.black87,
                onTap: () {},
              ),
              const Spacer(),
              // Delete icon
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
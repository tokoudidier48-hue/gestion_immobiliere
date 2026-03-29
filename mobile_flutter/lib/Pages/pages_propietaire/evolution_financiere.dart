import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoyaSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const EvolutionFinancesPage(),
    );
  }
}

class CategoriFinance {
  final String nom;
  final String montant;
  final String variation;
  final Color couleur;
  final IconData icone;
  final double pourcentage;

  const CategoriFinance({
    required this.nom,
    required this.montant,
    required this.variation,
    required this.couleur,
    required this.icone,
    required this.pourcentage,
  });
}

class EvolutionFinancesPage extends StatefulWidget {
  const EvolutionFinancesPage({super.key});

  @override
  State<EvolutionFinancesPage> createState() => _EvolutionFinancesPageState();
}

class _EvolutionFinancesPageState extends State<EvolutionFinancesPage> {
  int _currentIndex = 0;
  String _selectedDate = 'Choisir une date';

  final List<CategoriFinance> _categories = const [
    CategoriFinance(
      nom: 'Appartement',
      montant: '1.200.000 CFA',
      variation: '34%',
      couleur: Color(0xFFFF7043),
      icone: Icons.apartment,
      pourcentage: 0.34,
    ),
    CategoriFinance(
      nom: 'Boutique',
      montant: '850.000 CFA',
      variation: '24%',
      couleur: Color(0xFF7E57C2),
      icone: Icons.storefront,
      pourcentage: 0.24,
    ),
    CategoriFinance(
      nom: 'Chambre salon\nsanitaire',
      montant: '800.000\nCFA',
      variation: '5%',
      couleur: Color(0xFF29B6F6),
      icone: Icons.meeting_room,
      pourcentage: 0.23,
    ),
    CategoriFinance(
      nom: 'Chambre salon\nordinaire',
      montant: '450.000\nCFA',
      variation: '13%',
      couleur: Color(0xFF26A69A),
      icone: Icons.bed,
      pourcentage: 0.13,
    ),
    CategoriFinance(
      nom: 'Entrée coucher\nsanitaire',
      montant: '250.000\nCFA',
      variation: '',
      couleur: Color(0xFF66BB6A),
      icone: Icons.sensor_door,
      pourcentage: 0.07,
    ),
    CategoriFinance(
      nom: 'Entrée coucher',
      montant: '150.000',
      variation: '',
      couleur: Color(0xFFFFCA28),
      icone: Icons.door_front_door,
      pourcentage: 0.04,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'Évolution des Finances',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate =
                          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    });
                  }
                },
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Color(0xFF1565C0), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate,
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedDate == 'Choisir une date'
                            ? Colors.grey.shade400
                            : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.grey.shade400, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Revenus totaux card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REVENUS TOTAUX',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: '3.500.000 ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        TextSpan(
                          text: 'CFA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Répartition par catégorie
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Répartition par catégorie',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._categories.map((cat) => _buildCategoryItem(cat)),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),

    );
  }

  Widget _buildCategoryItem(CategoriFinance cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cat.couleur.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(cat.icone, color: cat.couleur, size: 18),
              ),
              const SizedBox(width: 12),

              // Name
              Expanded(
                child: Text(
                  cat.nom,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),

              // Montant + variation
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    cat.montant,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  if (cat.variation.isNotEmpty)
                    Text(
                      cat.variation,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cat.pourcentage,
              minHeight: 5,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(cat.couleur),
            ),
          ),
        ],
      ),
    );
  }
}
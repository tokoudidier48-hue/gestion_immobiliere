import 'package:flutter/material.dart';

class HomePageLocataire extends StatefulWidget {
  const HomePageLocataire({super.key});

  @override
  State<HomePageLocataire> createState() => _HomePageLocataireState();
}

class _HomePageLocataireState extends State<HomePageLocataire> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> logements = [];
  int page = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadMore();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading) {
        loadMore();
      }
    });
  }

  Future<void> loadMore() async {
    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    List<Map<String, dynamic>> newData = List.generate(10, (index) {
      int id = (page - 1) * 10 + index + 1;
      return {
        'title': 'Appartement $id',
        'price': '${50000 + id * 1000} CFA / mois',
        'city': 'Cotonou, Bénin',
        'image': 'https://picsum.photos/200/300?random=$id',
        'status': id % 2 == 0 ? 'LIBRE' : 'OCCUPE'
      };
    });

    logements.addAll(newData);
    page++;

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: logements.length + 1,
                itemBuilder: (context, index) {
                  if (index < logements.length) {
                    return _card(logements[index]);
                  } else {
                    return isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox();
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('LoyaSmart',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Icon(Icons.notifications_none)
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Cotonou, Fidjrossè...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                        'Chercher votre logement grâce à l\'agent d\'IA'))
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> logement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: Image.network(
                  logement['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: logement['status'] == 'LIBRE'
                        ? Colors.green
                        : Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    logement['status'],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(logement['price'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(logement['title']),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    Text(logement['city'])
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {},
                  child: const Text('Chercher un colocataire'),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

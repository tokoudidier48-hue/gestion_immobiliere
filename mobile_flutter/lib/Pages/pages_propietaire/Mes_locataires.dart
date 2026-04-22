import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/liste_unite.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/mes_locataires.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/modifier_maison.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/nouvelle_maison.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/proprio_navBar.dart';
import 'package:mobile_flutter/model/proprietaire/proprietes.dart';
import 'package:mobile_flutter/provider/proprio_provider.dart';
import 'package:provider/provider.dart';

const Color kPrimary = Color(0xFF2563EB);
const Color kTextDark = Color(0xFF111827);

class MesMaisonsPage extends StatefulWidget {
  const MesMaisonsPage({super.key});

  @override
  State<MesMaisonsPage> createState() => _MesMaisonsPageState();
}

class _MesMaisonsPageState extends State<MesMaisonsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<ProprieteProvider>().fetchProprietes()
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Mes Maisons',
          style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 14),
              child: FloatingActionButton.small(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeNew()),
                  );
                },
                backgroundColor: kPrimary,
                elevation: 0,
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          ],
      ),
      body: Consumer<ProprieteProvider>(
        builder: (context, provider, child) {

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text("Erreur : ${provider.error}"));
          }

          final proprietes = provider.proprietes.where((p) =>
            p.nomPropriete.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── BARRE DE RECHERCHE ───────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
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

              // ── SOUS-TITRE ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Text(
                  '${proprietes.length} maison(s) trouvée(s)',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),

              // ── LISTE ────────────────────────────────────────────────
              Expanded(
                child: proprietes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text('Aucune maison trouvée',
                                style: TextStyle(color: Colors.grey[400])),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: proprietes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildMaisonCard(context, proprietes[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const ProprioNavBar(selectedIndex: 2),
    );
  }

  Widget _buildMaisonCard(BuildContext context, Propriete maison) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
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
              maison.nomPropriete,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            subtitle: Text(
              'Créée le ${maison.dateCreation != null ? _formatDate(maison.dateCreation!) : "—"}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400]),
              onSelected: (value) async {
                if (value == 'modifier') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ModifierMaisonPage(propriete: maison),
                    ),
                  );
                } else if (value == 'supprimer') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Supprimer'),
                      content: Text('Supprimer "${maison.nomPropriete}" ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<ProprieteProvider>().supprimerPropriete(maison.id!);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'modifier',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Modifier'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'supprimer',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[100], indent: 14, endIndent: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LocatairesPage(
                            proprieteId: maison.id,
                            nomPropriete: maison.nomPropriete,
                          ),
                        ),
                      );
                    },
                  child: Text(
                    'Locataires',
                    style: TextStyle(
                      fontSize: 12,
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<UniteProvider>(),
                          child: ChambresMaisonScreen(
                            proprieteId: maison.id!,
                            nomPropriete: maison.nomPropriete,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Voir les chambres ajoutées',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/modificationProfilLocatairePage.dart';
import 'package:mobile_flutter/service/local_storage.dart';

class ProfilCompletionChecker extends StatefulWidget {
  final Widget child;
  const ProfilCompletionChecker({super.key, required this.child});

  @override
  State<ProfilCompletionChecker> createState() => _ProfilCompletionCheckerState();
}

class _ProfilCompletionCheckerState extends State<ProfilCompletionChecker> {
  Timer? _timer;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    // Vérifie au démarrage après 3 secondes
    Future.delayed(const Duration(seconds: 3), _verifierEtAfficher);
    // Puis toutes les 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => _verifierEtAfficher());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _verifierEtAfficher() async {
    if (_dialogShowing || !mounted) return;
    final complete = await LocalStorage.isProfilComplete();
    if (complete || !mounted) return;

    _dialogShowing = true;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1A3C6E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text('Profil incomplet',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    'Complétez votre profil pour profiter pleinement de LoyaSmart et faciliter votre recherche de colocataire.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ModificationProfilLocatairePage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3C6E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Compléter mon profil',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Plus tard', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    _dialogShowing = false;
  }
  // Dans le checker, remplace la vérification locale par :
Future<bool> _verifierProfilComplet() async {
  // 1. Vérifie localement d'abord
  final localComplet = await LocalStorage.getProfilComplete();
  if (localComplet) return true;

  // 2. Vérifie via les infos locales
  final infos = await LocalStorage.getInfosSupplementaires();
  final filiere = infos['filiere'] ?? '';
  final ville = infos['ville'] ?? '';
  final telephone = infos['telephone'] ?? '';
  final description = infos['description'] ?? '';

  final complet = filiere.isNotEmpty && ville.isNotEmpty &&
      telephone.isNotEmpty && description.isNotEmpty;

  if (complet) await LocalStorage.setProfilComplete(true);
  return complet;
}

  @override
  Widget build(BuildContext context) => widget.child;
}
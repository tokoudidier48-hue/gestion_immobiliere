import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentStep = 0;

  final List<Map<String, String>> steps = [
    {
      "title": "Gestion Immobilière Intelligente",
      "desc":
          "Gérez vos propriétés, suivez les paiements et anticipez grâce à l'IA.",
      "image": "assets/images/onboarding1.png"
    },
    {
      "title": "Suivi des Paiements",
      "desc":
          "Visualisez les loyers payés, en retard et recevez des alertes.",
      "image": "assets/images/onboarding2.png"
    },
    {
      "title": "Prédictions IA",
      "desc":
          "Notre IA prédit les risques d'impayés et optimise vos revenus.",
      "image": "assets/images/onboarding3.png"
    },
  ];

  void nextStep() {
    if (currentStep < steps.length - 1) {
      setState(() => currentStep++);
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void skip() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStep];
    final bool isLastStep = currentStep == steps.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SafeArea(
        child: Column(
          children: [

            /// 🔝 Bouton Passer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: skip,
                    child: const Text(
                      "Passer",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 🖼 Image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      step["image"]!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            /// 📝 Texte
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  Text(
                    step["title"]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    step["desc"]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// 📍 Indicateurs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: currentStep == index ? 26 : 6,
                  decoration: BoxDecoration(
                    color: currentStep == index
                        ? const Color(0xFF137FEC)
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// 🔘 Bouton Next / Commencer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF137FEC),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastStep ? "Commencer" : "Suivant",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// 🔢 Step text
            Text(
              "Étape ${1 + currentStep} sur ${steps.length}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
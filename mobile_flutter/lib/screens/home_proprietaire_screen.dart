import 'package:flutter/material.dart';

class HomeProprietaireScreen extends StatelessWidget {
  const HomeProprietaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white.withOpacity(0.9),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF137FEC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.domain, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "LoyaSmart",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D141B),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.notifications, color: Color(0xFF0D141B)),
                      ),
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuC4OpupKtlBJgH0OR9GoHrwnZnNEk3aRpOSOKHnRBHw4kaA_P_Pu7RlDe0lJt5RIUB_YQPP_23ceT_X-PeH7OsUItIns0ol5Zi9M5h88wHEdqdRLVipShrxRoYzGntJmycT23wslRhQJ29d92ETfJTItL9WoGrgF1yfAMhfpvRHqZ0ziPRcuW91KuV6Wsll8J87JwG_M4HRoTH8YC408z5WWRQJezFQkUEobIS65GzSG0ArxiZronqD39t98gEzrNoOfu3qnJTRHA",
                        ),
                        radius: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Text(
                  "Bienvenue Propriétaire",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
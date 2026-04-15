import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/nouvelle_maison.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/profil_proprietaire.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/proprio_navBar.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/proprio_notification.dart';
import 'package:mobile_flutter/provider/provider_profil.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class HomePageProprietaire extends StatefulWidget {
  const HomePageProprietaire({super.key});

  @override
  State<HomePageProprietaire> createState() => _HomePageProprietaireState();
}

class _HomePageProprietaireState extends State<HomePageProprietaire> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();

     Future.microtask(() =>
        context.read<ProfilProvider>().fetchProfil()
      );

    _videoController = VideoPlayerController.asset(
      "assets/images/video.mp4", // ⚠️ mets ta vraie vidéo ici
    );

    _videoController.initialize().then((_) {
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: false,

        // 🎬 style YouTube
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,

        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white70,
        ),
      );

      setState(() {});
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // 🔹 APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.grey[100],
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.apartment, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              "LoyaSmart",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsPage()),
                  );
                },
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonProfilPage()),
                );
              },
              child:Consumer<ProfilProvider>(
                  builder: (context, provider, child) {

                    final profil = provider.profil;

                    if (profil == null) {
                      return CircleAvatar(
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.grey),
                      );
                    }

                    return Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF1565C0),
                                Color(0xFF42A5F5),
                              ],
                            ),
                          ),
                          child: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage: profil.photoProfil != null
                          ? NetworkImage(profil.photoProfil!)
                          : null,
                      child: profil.photoProfil == null
                          ? Text(
                              '${profil.name.isNotEmpty ? profil.name[0].toUpperCase() : ''}${profil.lastName.isNotEmpty ? profil.lastName[0].toUpperCase() : ''}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
              );
                  },
                ),
            ),
          )
        ],
      ),

      // 🔹 BODY
      body: Column(
        children: [
          const SizedBox(height: 30),

          // 🎬 VIDEO CARD (STYLE YOUTUBE)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: _chewieController != null &&
                      _videoController.value.isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),

          const SizedBox(height: 20),

          // 📝 TITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "Apprendre à créer une maison et ajouter des chambres",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 📝 SUBTITLE
          Text(
            "Regardez ce tutoriel rapide pour bien démarrer",
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 30),

          // 🔹 BUTTON TEXT
          GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeNew()),
                );
              },
          child: const Text(
            "CRÉER UNE MAISON",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
         )
          ),
        ],
      ),

      // ➕ FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeNew()),
            );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: const ProprioNavBar(selectedIndex: 0),





          );
  }

}

import 'package:flutter/material.dart';


class NotificationItem {
  final String nom;
  final String message;
  final String temps;
  final bool isNew;
  final String avatarUrl;

  const NotificationItem({
    required this.nom,
    required this.message,
    required this.temps,
    required this.isNew,
    required this.avatarUrl,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _currentIndex = 0;

  final List<NotificationItem> _recentes = const [
    NotificationItem(
      nom: 'TOKDU Didier (Maison 1)',
      message:
          'Vous avez reçu un message de TOKDU Didier pour la Chambre salon sanitaire...',
      temps: 'Il y a 2 min',
      isNew: true,
      avatarUrl: 'https://randomuser.me/api/portraits/men/11.jpg',
    ),
    NotificationItem(
      nom: 'TOKDU Didier (Maison 2)',
      message:
          "Vous avez reçu un message de TOKDU Didier pour l'Appartement...",
      temps: 'Il y a 5 min',
      isNew: true,
      avatarUrl: 'https://randomuser.me/api/portraits/men/12.jpg',
    ),
    NotificationItem(
      nom: 'TOKDU Didier (Maison 3)',
      message:
          "Vous avez reçu une demande de TOKDU Didier pour l'Entrée coucher ordinaire (Loyer: 35.000 FCFA)",
      temps: 'Il y a 8 h',
      isNew: true,
      avatarUrl: 'https://randomuser.me/api/portraits/men/13.jpg',
    ),
  ];

  final List<NotificationItem> _precedentes = const [
    NotificationItem(
      nom: 'SONON Didier (Maison 1)',
      message:
          'Vous avez reçu une demande de SONON Didier pour la Boutique (Loyer: 50.000 FCFA)',
      temps: 'Hier',
      isNew: false,
      avatarUrl: 'https://randomuser.me/api/portraits/men/21.jpg',
    ),
    NotificationItem(
      nom: 'TOKDU Didier (Maison 2)',
      message:
          "Paiement de 120.000 FCFA reçu pour l'Appartement de TOKDU Didier",
      temps: 'Hier',
      isNew: false,
      avatarUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
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
          'Notifications',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  color: Color(0xFF1565C0),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Section RÉCENTS
          _buildSectionHeader('RÉCENTS'),
          ..._recentes.map((n) => _buildNotifItem(n)),

          const SizedBox(height: 8),

          // Section PRÉCÉDEMMENT
          _buildSectionHeader('PRÉCÉDEMMENT'),
          ..._precedentes.map((n) => _buildNotifItem(n)),
        ],
      ),

    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade500,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNotifItem(NotificationItem notif) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: notif.isNew ? Colors.white : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(notif.avatarUrl),
                    backgroundColor: Colors.grey.shade300,
                  ),
                  if (notif.isNew)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.nom,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: notif.isNew
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          notif.temps,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
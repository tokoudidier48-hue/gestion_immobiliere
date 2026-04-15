import 'package:flutter/material.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

class NotificationLocatairePage extends StatefulWidget {
  const NotificationLocatairePage({super.key});

  @override
  State<NotificationLocatairePage> createState() => _NotificationLocatairePageState();
}

class _NotificationLocatairePageState extends State<NotificationLocatairePage> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<NotificationProvider>().fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifications',
            style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.isLoading ? null : () => provider.marquerToutesLues(),
                child: const Text('Tout lire',
                    style: TextStyle(color: Color(0xFF1A3C6E), fontSize: 13)),
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Erreur : ${provider.error}',
                      style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchNotifications(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Aucune notification', style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: provider.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildNotifCard(context, provider, provider.notifications[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotifCard(BuildContext context, NotificationProvider provider, dynamic notif) {
    final bool isRead = notif['est_lue'] == true;
    final String titre = notif['titre'] ?? 'Notification';
    final String message = notif['message'] ?? '';
    final String time = _formatDate(notif['date_creation'] ?? '');
    final int notifId = notif['id'];
    final String type = notif['type'] ?? '';

    IconData notifIcon;
    Color notifColor;
    switch (type) {
      case 'colocataire':
        notifIcon = Icons.people_outline;
        notifColor = const Color(0xFF1A3C6E);
        break;
      case 'demande':
        notifIcon = Icons.description_outlined;
        notifColor = Colors.orange;
        break;
      case 'paiement':
        notifIcon = Icons.payment_outlined;
        notifColor = Colors.green;
        break;
      case 'message':
        notifIcon = Icons.message_outlined;
        notifColor = Colors.blue;
        break;
      default:
        notifIcon = Icons.notifications_outlined;
        notifColor = const Color(0xFF1A3C6E);
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) provider.marquerLue(notifId);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(12),
          border: isRead
              ? null
              : Border.all(color: const Color(0xFF1A3C6E).withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône dynamique selon le type
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notifColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(notifIcon, color: notifColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titre,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
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
              if (!isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: notifColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      final now = DateTime.now();
      final diff = now.difference(d);
      if (diff.inMinutes < 60) return '${diff.inMinutes}min';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}j';
      return '${d.day}/${d.month}';
    } catch (_) {
      return date;
    }
  }
}
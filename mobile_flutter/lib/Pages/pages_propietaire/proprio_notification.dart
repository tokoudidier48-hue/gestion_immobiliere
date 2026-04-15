import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/detail_demande_notif.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<NotificationProvider>().fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              return TextButton(
                onPressed: provider.isLoading
                    ? null
                    : () => provider.marquerToutesLues(),
                child: const Text('Tout lire',
                    style: TextStyle(
                        color: Color(0xFF1565C0),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
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
                  Icon(Icons.notifications_off_outlined,
                      size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text('Aucune notification',
                      style: TextStyle(color: Colors.grey[400])),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              return _buildNotifItem(
                  context, provider, provider.notifications[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotifItem(BuildContext context, NotificationProvider provider,
      dynamic notif) {
    final bool isNew = notif['est_lue'] == false;
    final String titre = notif['titre'] ?? 'Notification';
    final String message = notif['message'] ?? '';
    final String temps = _formatDate(notif['date_creation'] ?? '');
    final String type = notif['type'] ?? '';
    final String lien = notif['lien'] ?? '';
    final int notifId = notif['id'];

    IconData icon;
    Color iconColor;
    switch (type) {
      case 'demande':
        icon = Icons.description_outlined;
        iconColor = Colors.orange;
        break;
      case 'paiement':
        icon = Icons.payment_outlined;
        iconColor = Colors.green;
        break;
      case 'message':
        icon = Icons.message_outlined;
        iconColor = const Color(0xFF1565C0);
        break;
      case 'colocataire':
        icon = Icons.people_outline;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = const Color(0xFF1565C0);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isNew ? const Color(0xFFEEF2FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isNew
            ? Border.all(color: const Color(0xFF1565C0).withOpacity(0.15))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Marque comme lue
          if (isNew) provider.marquerLue(notifId);

          // Navigation selon le type
          if (type == 'demande') {
            // Extrait l'ID de la demande depuis le lien ex: /demandes/3
            final parts = lien.split('/');
            final demandeId = int.tryParse(parts.last);
            if (demandeId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailDemandeNotifPage(demandeId: demandeId),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(titre,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isNew
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: Colors.black87,
                              )),
                        ),
                        Text(temps,
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey.shade400)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(message,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    if (type == 'demande') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Voir et décider →',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: iconColor,
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
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return date;
    }
  }
}
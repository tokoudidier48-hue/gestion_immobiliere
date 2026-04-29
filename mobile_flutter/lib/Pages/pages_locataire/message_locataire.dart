import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_locataire/locataire_navbar.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:provider/provider.dart';

const Color kLocataireBlue = Color(0xFF1A3C6E);

class MessageLocatairePage extends StatefulWidget {
  const MessageLocatairePage({super.key});

  @override
  State<MessageLocatairePage> createState() => _MessageLocatairePageState();
}

class _MessageLocatairePageState extends State<MessageLocatairePage> {
  final _searchController = TextEditingController();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _currentUserId = await LocalStorage.getUserId() ?? '';
      if (mounted) context.read<MessageProvider>().fetchConversations();
    });
  }

  Map<String, dynamic> _getAutreParticipant(dynamic conv) {
    final participants = (conv['participants'] as List?) ?? [];
    try {
      return participants.firstWhere(
        (p) => p['id']?.toString() != _currentUserId,
        orElse: () => participants.isNotEmpty ? participants[0] : <String, dynamic>{},
      ) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String _getNomComplet(Map<String, dynamic> p) {
    final prenom = p['first_name'] ?? '';
    final nom = p['last_name'] ?? '';
    return '$prenom $nom'.trim().isEmpty ? 'Inconnu' : '$prenom $nom'.trim();
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
        title: const Text('Messages', style: TextStyle(color: Colors.black87, fontSize: 17, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                filled: true, fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text('Vérifiez votre connexion et réessayez', style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: () => provider.fetchConversations(), child: const Text('Réessayer')),
                      ],
                    ),
                  );
                }
                if (provider.conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message_outlined, size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text('Aucune conversation', style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  );
                }
                final filtered = provider.conversations.where((conv) {
                final autre = _getAutreParticipant(conv);
                final nom = _getNomComplet(autre).toLowerCase();
                return _searchController.text.isEmpty ||
                    nom.contains(_searchController.text.toLowerCase());
              }).toList();

              filtered.sort((a, b) {

                  final msgA = a['dernier_message'];
                  final msgB = b['dernier_message'];

                  final dateA = DateTime.tryParse(
                      msgA is Map ? msgA['date'] ?? '' : a['date_dernier_message'] ?? ''
                  ) ?? DateTime(2000);

                  final dateB = DateTime.tryParse(
                      msgB is Map ? msgB['date'] ?? '' : b['date_dernier_message'] ?? ''
                  ) ?? DateTime(2000);

                  return dateB.compareTo(dateA);

                });
               return RefreshIndicator(
                  color: kLocataireBlue,
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await context.read<MessageProvider>().fetchConversations();
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(), // IMPORTANT
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, indent: 72, color: Colors.grey.shade100),
                    itemBuilder: (context, index) =>
                        _buildConversationTile(context, filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const LocataireNavBar(selectedIndex: 2),
    );
  }

  Widget _buildConversationTile(BuildContext context, dynamic conv) {
    final convId = conv['id'];
    final autre = _getAutreParticipant(conv);
    final autreUserId = autre['id'] ?? 0;
    final nom = _getNomComplet(autre);
    final role = autre['role'] ?? '';
    final dernierMsgMap = conv['dernier_message'];
    final dernierMessage = dernierMsgMap is Map ? (dernierMsgMap['contenu'] ?? '') : (dernierMsgMap?.toString() ?? '');
    final dernierMsgDate = dernierMsgMap is Map ? (dernierMsgMap['date'] ?? '') : (conv['date_dernier_message'] ?? '');
    final time = _formatDate(dernierMsgDate);
    final nonLus = conv['non_lus'] ?? 0;
    final bool hasUnread = nonLus > 0;
    final initiales = [autre['first_name'] ?? '', autre['last_name'] ?? '']
        .where((e) => e.isNotEmpty).map((e) => e[0].toUpperCase()).join();

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: convId,
          autreUserId: autreUserId,
          name: nom,
          role: role,
          initiales: initiales.isEmpty ? '?' : initiales,
          color: kLocataireBlue,
        ),
      )),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kLocataireBlue.withOpacity(0.15),
              child: Text(initiales.isEmpty ? '?' : initiales,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kLocataireBlue)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(nom, style: TextStyle(fontSize: 14, fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600, color: Colors.black87)),
                      ),
                      if (role.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: kLocataireBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                          child: Text(role == 'proprietaire' ? 'Propriétaire' : 'Locataire', style: const TextStyle(fontSize: 10, color: kLocataireBlue)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(dernierMessage,
                      style: TextStyle(fontSize: 12, color: hasUnread ? Colors.black87 : Colors.grey.shade500, fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: TextStyle(fontSize: 11, color: hasUnread ? kLocataireBlue : Colors.grey.shade400)),
                const SizedBox(height: 4),
                if (hasUnread)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$nonLus',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
      if (diff.inHours < 24) return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
      if (diff.inDays < 7) return ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'][d.weekday - 1];
      return '${d.day}/${d.month}';
    } catch (_) {
      return date;
    }
  }
}

// ─── Page Chat ────────────────────────────────────────────────────────────────

class ChatPage extends StatefulWidget {
  final int conversationId;
  final int autreUserId;
  final String name;
  final String role;
  final String initiales;
  final Color color;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.autreUserId,
    required this.name,
    required this.role,
    required this.initiales,
    required this.color,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _currentUserId = await LocalStorage.getUserId() ?? '';
      if (mounted) await context.read<MessageProvider>().fetchMessages(widget.conversationId);
      _startConversationPolling();
      _startMessagePolling();
    });
  }

  
  void _startMessagePolling() {
  Future.delayed(const Duration(seconds: 3), () async {
    if (!mounted) return;
    await context.read<MessageProvider>().fetchMessages(widget.conversationId);
    _startMessagePolling();
  });
}

  void _startConversationPolling() {
  Future.delayed(const Duration(seconds: 5), () async {
    if (!mounted) return;
    await context.read<MessageProvider>().fetchConversations();
    _startConversationPolling();
  });
}

  void _sendMessage() async {
  final text = _messageController.text.trim();
  if (text.isEmpty) return;

  _messageController.clear();

  await context.read<MessageProvider>()
      .envoyerMessageDirect(widget.conversationId, text);

  // recharge les messages
  await context.read<MessageProvider>()
      .fetchMessages(widget.conversationId);

  Future.delayed(const Duration(milliseconds: 100), () {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}

  void _showMessageOptions(int messageId, String contenuActuel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('Modifier le message'),
              onTap: () { Navigator.pop(context); _showModifierDialog(messageId, contenuActuel); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer le message', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<MessageProvider>().supprimerMessage(messageId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showModifierDialog(int messageId, String contenuActuel) {
    final controller = TextEditingController(text: contenuActuel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Modifier le message', style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller, maxLines: 4,
          decoration: InputDecoration(
            filled: true, fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty || newText == contenuActuel) { Navigator.pop(ctx); return; }
              Navigator.pop(ctx);
              await context.read<MessageProvider>().modifierMessage(messageId, newText);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kLocataireBlue),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: widget.color.withOpacity(0.15),
              child: Text(widget.initiales, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.color)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                Text(widget.role == 'proprietaire' ? 'Propriétaire' : 'Locataire',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.black54), onPressed: () {})],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.messages.isEmpty) return const Center(child: CircularProgressIndicator());
                if (provider.messages.isEmpty) return Center(child: Text('Démarrez la conversation !', style: TextStyle(color: Colors.grey[400])));
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                });
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) => _buildMessage(provider.messages[index]),
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true, fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: kLocataireBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(dynamic msg) {
    final bool isMe = msg['expediteur']?.toString() == _currentUserId;
    final String contenu = msg['contenu'] ?? '';
    final String time = _formatTime(msg['date_envoi'] ?? '');
    final int? messageId = msg['id'];

    return GestureDetector(
      onLongPress: isMe && messageId != null ? () => _showMessageOptions(messageId, contenu) : null,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isMe ? kLocataireBlue : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(contenu, style: TextStyle(fontSize: 13, color: isMe ? Colors.white : Colors.black87)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String date) {
    if (date.isEmpty) return '';
    try {
      final d = DateTime.parse(date);
      return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
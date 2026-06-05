import 'package:flutter/material.dart';
import 'package:mobile_flutter/Pages/pages_propietaire/proprio_navBar.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:provider/provider.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      _currentUserId = await LocalStorage.getUserId() ?? '';
      if (mounted) {
        context.read<MessageProvider>().fetchConversations();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getAutreParticipant(dynamic conv) {
    final participants = (conv['participants'] as List?) ?? [];
    try {
      return participants.firstWhere(
        (p) => p['id']?.toString() != _currentUserId,
        orElse: () => participants.isNotEmpty ? participants[0] : {},
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
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text('Messages',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1565C0)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                filled: true,
                fillColor: const Color(0xFFF4F6FA),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text('Erreur : ${provider.error}',
                            style: TextStyle(color: Colors.grey[400])),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchConversations(),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.conversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message_outlined,
                            size: 60, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text('Aucune conversation',
                            style: TextStyle(color: Colors.grey[400])),
                      ],
                    ),
                  );
                }

                final filtered = provider.conversations.where((conv) {
                  final autre = _getAutreParticipant(conv);
                  final nom = _getNomComplet(autre).toLowerCase();
                  return _searchQuery.isEmpty ||
                      nom.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 76,
                    endIndent: 16,
                    color: Colors.grey.shade100,
                  ),
                  itemBuilder: (context, index) {
                    return _buildConversationTile(filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ProprioNavBar(selectedIndex: 3),
    );
  }

  Widget _buildConversationTile(dynamic conv) {
    final convId = conv['id'];
    final autre = _getAutreParticipant(conv);
    final autreUserId = autre['id'] ?? 0;
    final nom = _getNomComplet(autre);
    final role = autre['role'] ?? '';
    final bool hasUnread = (conv['non_lus'] ?? 0) > 0;
    final nonLus = conv['non_lus'] ?? 0;

    final dernierMsgMap = conv['dernier_message'];
    final dernierMessage = dernierMsgMap is Map
        ? (dernierMsgMap['contenu'] ?? '')
        : (dernierMsgMap?.toString() ?? '');
    final dernierMsgDate = dernierMsgMap is Map
        ? (dernierMsgMap['date'] ?? '')
        : (conv['date_dernier_message'] ?? '');
    final time = _formatDate(dernierMsgDate);

    final initiales = [autre['first_name'] ?? '', autre['last_name'] ?? '']
        .where((e) => e.isNotEmpty)
        .map((e) => e[0].toUpperCase())
        .join();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationDetailPage(
            conversationId: convId,
            autreUserId: autreUserId,
            nom: nom,
            role: role,
            initiales: initiales.isEmpty ? '?' : initiales,
          ),
        ),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.12),
              child: Text(
                initiales.isEmpty ? '?' : initiales,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(nom,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: Colors.black87,
                            )),
                      ),
                      Text(time,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? const Color(0xFF1565C0)
                                : Colors.grey.shade400,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          )),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (role.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF1565C0).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role == 'proprietaire'
                                ? 'Propriétaire'
                                : 'Locataire',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFF1565C0)),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          dernierMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? Colors.black87
                                : Colors.grey.shade500,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            nonLus.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
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
      if (diff.inHours < 24)
        return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
      if (diff.inDays < 7)
        return ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'][d.weekday - 1];
      return '${d.day}/${d.month}';
    } catch (_) {
      return date;
    }
  }
}

// ─── Page détail conversation ────────────────────────────────────────────────

class ConversationDetailPage extends StatefulWidget {
  final int conversationId;
  final int autreUserId;
  final String nom;
  final String role;
  final String initiales;

  const ConversationDetailPage({
    super.key,
    required this.conversationId,
    required this.autreUserId,
    required this.nom,
    required this.role,
    required this.initiales,
  });

  @override
  State<ConversationDetailPage> createState() =>
      _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _currentUserId = '';
  bool _isSending = false;

  // Dans _ConversationDetailPageState, remplace initState par :
@override
void initState() {
  super.initState();
  Future.microtask(() async {
    _currentUserId = await LocalStorage.getUserId() ?? '';
    if (!mounted) return;
    context.read<MessageProvider>().setConversationOuverte(widget.conversationId);
    await context.read<MessageProvider>().fetchMessages(widget.conversationId);
  });
}

@override
void dispose() {
  context.read<MessageProvider>().setConversationOuverte(null);
  _msgController.dispose();
  _scrollController.dispose();
  super.dispose();
}


  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;
    _msgController.clear();
    setState(() => _isSending = true);

    await context.read<MessageProvider>().envoyerMessageDirect(
      widget.conversationId,
      text,
    );

    setState(() => _isSending = false);

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
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: Colors.blue),
            title: const Text('Modifier le message'),
            onTap: () {
              Navigator.pop(context);
              _showModifierDialog(messageId, contenuActuel);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Supprimer le message',
                style: TextStyle(color: Colors.red)),
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
      title: const Text('Modifier le message',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: TextField(
        controller: controller,
        maxLines: 4,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            final newText = controller.text.trim();
            if (newText.isEmpty || newText == contenuActuel) {
              Navigator.pop(ctx);
              return;
            }
            Navigator.pop(ctx);
            await context.read<MessageProvider>().modifierMessage(messageId, newText);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0)),
          child: const Text('Enregistrer',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.12),
              child: Text(widget.initiales,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  )),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nom,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                Text(
                  widget.role == 'proprietaire' ? 'Propriétaire' : 'Locataire',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined,
                color: Color(0xFF1565C0), size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.messages.isEmpty) {
                  return Center(
                    child: Text('Démarrez la conversation !',
                        style: TextStyle(color: Colors.grey[400])),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    return _buildBubble(provider.messages[index]);
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Écrire un message...',
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFFF4F6FA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1565C0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(dynamic msg) {
    final bool isMoi = msg['expediteur']?.toString() == _currentUserId;
    final String text = msg['contenu'] ?? '';
    final String time = _formatTime(msg['date_envoi'] ?? '');
    final int? messageId = msg['id'];

    return GestureDetector(
      onLongPress: isMoi && messageId != null
          ? () => _showMessageOptions(messageId, text)
          : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment:
              isMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMoi) ...[
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF1565C0).withOpacity(0.12),
                child: Text(
                  widget.initiales.isNotEmpty ? widget.initiales[0] : '?',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment:
                  isMoi ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMoi ? const Color(0xFF1565C0) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMoi ? 16 : 4),
                      bottomRight: Radius.circular(isMoi ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(text,
                      style: TextStyle(
                        fontSize: 13,
                        color: isMoi ? Colors.white : Colors.black87,
                        height: 1.4,
                      )),
                ),
                const SizedBox(height: 4),
                Text(time,
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400)),
              ],
            ),
            if (isMoi) const SizedBox(width: 4),
          ],
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
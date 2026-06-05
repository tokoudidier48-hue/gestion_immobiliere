import 'package:flutter/material.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:provider/provider.dart';

class ChatPageDirect extends StatefulWidget {
  final int autreUserId;
  final String nom;
  final String initiales;
  final int? uniteId;

  const ChatPageDirect({
    super.key,
    required this.autreUserId,
    required this.nom,
    required this.initiales,
    this.uniteId,
  });

  @override
  State<ChatPageDirect> createState() => _ChatPageDirectState();
}

class _ChatPageDirectState extends State<ChatPageDirect> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _currentUserId = '';
  int? _conversationId;
  bool _isLoading = true;
  bool _isSending = false;
  bool _isLoadingMessages = false;
  Set<int> _messageIds = {}; 

@override
void initState() {
  super.initState();
  Future.microtask(() async {
    _currentUserId = await LocalStorage.getUserId() ?? '';
    try {
      final convId = await context.read<MessageProvider>()
          .getOuCreerConversation(widget.autreUserId, uniteId: widget.uniteId);
      _conversationId = convId;
      if (!mounted) return;

      // ← Indique conversation ouverte pour WebSocket
      context.read<MessageProvider>().setConversationOuverte(convId);

      await context.read<MessageProvider>().fetchMessages(_conversationId!);
      _scrollToBottom();
    } catch (e) {
      print("==> Erreur init ChatPageDirect : $e");
    }
    if (mounted) setState(() => _isLoading = false);
  });
}

@override
void dispose() {
  context.read<MessageProvider>().setConversationOuverte(null);
  _messageController.dispose();
  _scrollController.dispose();
  super.dispose();
}


void _scrollToBottom() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}

  void _sendMessage() async {
  final text = _messageController.text.trim();

  if (text.isEmpty || _conversationId == null || _isSending) {
    return;
  }

  _messageController.clear();

  setState(() => _isSending = true);

  // Optimistic UI
  context.read<MessageProvider>().ajouterMessageLocal({
    'id': null,
    'contenu': text,
    'expediteur': int.tryParse(_currentUserId) ?? 0,
    'date_envoi': DateTime.now().toIso8601String(),
  });

  _scrollToBottom();

  try {
    await context
        .read<MessageProvider>()
        .envoyerMessageDirect(_conversationId!, text);

    // Synchronisation backend
    await context
        .read<MessageProvider>()
        .fetchMessages(_conversationId!);

    _scrollToBottom();
  } catch (e) {
    print("==> Erreur envoi message : $e");
  } finally {
    if (mounted) {
      setState(() => _isSending = false);
    }
  }
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3C6E)),
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
              backgroundColor: const Color(0xFF1A3C6E).withOpacity(0.15),
              child: Text(widget.initiales, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A3C6E))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.nom, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                const Text('Propriétaire', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.black54), onPressed: () {})],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Consumer<MessageProvider>(
                    builder: (context, provider, child) {
                      if (provider.messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Démarrez la conversation avec\n${widget.nom}',
                                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            ],
                          ),
                        );
                      }
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
                    textInputAction: TextInputAction.send,
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
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _isSending ? Colors.grey : const Color(0xFF1A3C6E),
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send, color: Colors.white, size: 20),
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
            color: isMe ? const Color(0xFF1A3C6E) : Colors.white,
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
      final parsed = DateTime.tryParse(date) ?? DateTime.now();
      return '${parsed.hour}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
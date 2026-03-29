import 'package:flutter/material.dart';


class MessageConversation {
  final String nom;
  final String dernierMessage;
  final String temps;
  final int nonLus;
  final String avatarUrl;
  final bool enLigne;

  const MessageConversation({
    required this.nom,
    required this.dernierMessage,
    required this.temps,
    required this.nonLus,
    required this.avatarUrl,
    required this.enLigne,
  });
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  int _currentIndex = 3;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<MessageConversation> _conversations = const [
    MessageConversation(
      nom: 'TOKDU Didier',
      dernierMessage: 'Bonjour, je voudrais avoir des informations sur la chambre...',
      temps: '09:42',
      nonLus: 3,
      avatarUrl: 'https://randomuser.me/api/portraits/men/11.jpg',
      enLigne: true,
    ),
    MessageConversation(
      nom: 'SONON Koffi',
      dernierMessage: 'Merci pour la confirmation du paiement !',
      temps: '08:15',
      nonLus: 0,
      avatarUrl: 'https://randomuser.me/api/portraits/men/21.jpg',
      enLigne: true,
    ),
    MessageConversation(
      nom: 'Awa Diallo',
      dernierMessage: 'D\'accord, je passerai demain matin pour signer.',
      temps: 'Hier',
      nonLus: 1,
      avatarUrl: 'https://randomuser.me/api/portraits/women/32.jpg',
      enLigne: false,
    ),
    MessageConversation(
      nom: 'Mensah Paul',
      dernierMessage: 'Est-ce que le loyer inclut l\'eau et l\'électricité ?',
      temps: 'Hier',
      nonLus: 0,
      avatarUrl: 'https://randomuser.me/api/portraits/men/44.jpg',
      enLigne: false,
    ),
    MessageConversation(
      nom: 'Sessi Houedanou',
      dernierMessage: 'Je vous enverrai le reçu ce soir.',
      temps: 'Lun',
      nonLus: 0,
      avatarUrl: 'https://randomuser.me/api/portraits/women/55.jpg',
      enLigne: false,
    ),
    MessageConversation(
      nom: 'Adjobi Clarisse',
      dernierMessage: 'La chambre est-elle toujours disponible ?',
      temps: 'Dim',
      nonLus: 2,
      avatarUrl: 'https://randomuser.me/api/portraits/women/66.jpg',
      enLigne: false,
    ),
  ];

  List<MessageConversation> get _filtered => _conversations
      .where((c) =>
          c.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.dernierMessage.toLowerCase().contains(_searchQuery.toLowerCase()))
      .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1565C0)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
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

          // Conversations list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucune conversation trouvée',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      indent: 76,
                      endIndent: 16,
                      color: Colors.grey.shade100,
                    ),
                    itemBuilder: (context, index) {
                      return _buildConversationTile(_filtered[index]);
                    },
                  ),
          ),
        ],
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.chat_outlined, color: Colors.white),
      ),

      // Bottom nav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined), label: 'Mes Biens'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline), label: 'Locataires'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
        ],
      ),
    );
  }

  Widget _buildConversationTile(MessageConversation conv) {
    final bool hasUnread = conv.nonLus > 0;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationDetailPage(conversation: conv),
        ),
      ),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar + online dot
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(conv.avatarUrl),
                  backgroundColor: Colors.grey.shade200,
                ),
                if (conv.enLigne)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
                          conv.nom,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        conv.temps,
                        style: TextStyle(
                          fontSize: 11,
                          color: hasUnread
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade400,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.dernierMessage,
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
                            conv.nonLus.toString(),
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
}

// ─── Page détail conversation ────────────────────────────────────────────────

class ConversationDetailPage extends StatefulWidget {
  final MessageConversation conversation;

  const ConversationDetailPage({super.key, required this.conversation});

  @override
  State<ConversationDetailPage> createState() =>
      _ConversationDetailPageState();
}

class _ConversationDetailPageState extends State<ConversationDetailPage> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Bonjour, je voudrais avoir des informations sur la chambre disponible.',
      'isMoi': false,
      'time': '09:40',
    },
    {
      'text': 'Bonjour ! Bien sûr, laquelle vous intéresse ?',
      'isMoi': true,
      'time': '09:41',
    },
    {
      'text': 'La chambre salon sanitaire à 75 000 CFA.',
      'isMoi': false,
      'time': '09:42',
    },
  ];

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({
        'text': text,
        'isMoi': true,
        'time':
            '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}',
      });
    });
    _msgController.clear();
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      NetworkImage(widget.conversation.avatarUrl),
                  backgroundColor: Colors.grey.shade200,
                ),
                if (widget.conversation.enLigne)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.nom,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  widget.conversation.enLigne ? 'En ligne' : 'Hors ligne',
                  style: TextStyle(
                    color: widget.conversation.enLigne
                        ? Colors.green
                        : Colors.grey.shade400,
                    fontSize: 11,
                  ),
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
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildBubble(
                  text: msg['text'],
                  isMoi: msg['isMoi'],
                  time: msg['time'],
                  avatarUrl: widget.conversation.avatarUrl,
                );
              },
            ),
          ),

          // Input bar
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

  Widget _buildBubble({
    required String text,
    required bool isMoi,
    required String time,
    required String avatarUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMoi ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMoi) ...[
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(avatarUrl),
              backgroundColor: Colors.grey.shade200,
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
                  color: isMoi
                      ? const Color(0xFF1565C0)
                      : Colors.white,
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
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: isMoi ? Colors.white : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          if (isMoi) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
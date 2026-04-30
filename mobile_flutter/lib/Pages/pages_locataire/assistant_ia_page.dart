import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AssistantIaPage extends StatefulWidget {
  const AssistantIaPage({super.key});

  @override
  State<AssistantIaPage> createState() => _AssistantIaPageState();
}

class _AssistantIaPageState extends State<AssistantIaPage> {
  static const _primaryColor = Color(0xFF1A3C6E);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final ApiLocataire _api = ApiLocataire();
  List<dynamic> _messages = [];
  bool _isLoading = false;
  int? _conversationId;

  Timer? _refreshTimer;

  final List<String> _suggestions = [
    "Comment payer mon loyer ?",
    "Quels documents pour une demande ?",
    "Comment contacter mon propriétaire ?",
    "C'est quoi une caution ?",
  ];
  
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _initConversation();
  }

  Future<void> _initConversation() async {
    setState(() => _isLoading = true);

    try {
      final data = await _api.getMaConversationIA();

      _conversationId = data['id'];

      _messages = data['messages'] ?? [];

      // 🔁 Auto refresh messages (chat vivant)
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        if (_conversationId == null) return;

        try {
          final newMessages =
              await _api.getMessagesIA(_conversationId!);

          setState(() {
            _messages = newMessages;
          });
        } catch (_) {}
      });
    } catch (e) {
      print("Erreur init IA: $e");
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _envoyer([String? texte]) async {
    final message = texte ?? _controller.text.trim();
    if (message.isEmpty || _conversationId == null) return;

    setState(() => _isLoading = true);
    _controller.clear();

    try {
      final response = await _api.envoyerMessageIA(
        conversationId: _conversationId!,
        contenu: message,
      );

      setState(() {
        _messages.add(response['message_locataire']);
        _messages.add(response['message_ia']);
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'type_expediteur': 'ia',
          'contenu': 'Erreur serveur, veuillez réessayer.',
          'date_envoi': ''
        });
      });
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> _startRecording() async {
  if (await _audioRecorder.hasPermission()) {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _audioPath = path;
    });
  }
}

Future<void> _stopRecording() async {
  final path = await _audioRecorder.stop();

  setState(() {
    _isRecording = false;
    _audioPath = path;
  });

  if (path != null) {
    await _envoyerAudio(File(path));
  }
}

Future<void> _envoyerAudio(File file) async {
  setState(() {
    _messages.add({
      'role': 'user',
      'content': '🎤 Message vocal envoyé...'
    });
    _isLoading = true;
  });

  try {final response = await _api.envoyerMessageIA(
  conversationId: _conversationId!,
  contenu: "Message vocal",
  typeMessage: "audio", // ou "voix"
);

    final reply = response['message_ia']['contenu'];

    setState(() {
      _messages.add({'role': 'assistant', 'content': reply});
    });
  } catch (e) {
    setState(() {
      _messages.add({
        'role': 'assistant',
        'content': 'Erreur envoi audio'
      });
    });
  } finally {
    setState(() => _isLoading = false);
    _scrollToBottom();
  }
}

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    try {
      final d = DateTime.parse(date).toLocal();
      return "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: _primaryColor, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'Assistant LoyaSmart',
              style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.black54),
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTyping();
                      }
                      return _buildMessage(_messages[index]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: _primaryColor, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bonjour ! Je suis votre assistant LoyaSmart',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Posez-moi vos questions sur la gestion locative...',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                height: 1.5),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () => _envoyer(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    s,
                    style: const TextStyle(
                        fontSize: 13, color: _primaryColor),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(dynamic msg) {
    final isUser = msg['type_expediteur'] == 'locataire';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome,
                  color: _primaryColor, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['contenu'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(msg['date_envoi']),
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser
                          ? Colors.white70
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTyping() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 40),
          Container(
            padding: const EdgeInsets.all(12),
            child: const CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
  children: [
    Expanded(
      child: TextField(
        controller: _controller,
        maxLines: null,
        decoration: InputDecoration(
          hintText: 'Posez votre question...',
          filled: true,
          fillColor: const Color(0xFFF5F6FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (_) => _envoyer(),
      ),
    ),

    const SizedBox(width: 10),

    // 🎤 MICRO
    GestureDetector(
      onLongPress: _startRecording,
      onLongPressUp: _stopRecording,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _isRecording ? Colors.red : Colors.grey.shade300,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isRecording ? Icons.mic : Icons.mic_none,
          color: Colors.white,
        ),
      ),
    ),

    const SizedBox(width: 8),

    // 📤 ENVOI TEXTE
    GestureDetector(
      onTap: _isLoading ? null : () => _envoyer(),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: _primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.send, color: Colors.white),
      ),
    ),
  ],
)
    );
  }
}
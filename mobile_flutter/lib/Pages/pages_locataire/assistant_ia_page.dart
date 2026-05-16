import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_flutter/service/locataire/api_locataire.dart';

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

  final List<Map<String, dynamic>> _messages = [];
  bool _isInitLoading = false;
  bool _iaEnTrainDEcrire = false;
  bool _isLoadingMessages = false; // ← anti double appel
  bool _conversationChargee = false; // ← init une seule fois
  int? _conversationId;

  Timer? _uiRefreshTimer;
  DateTime? _debutAttente;

  final List<String> _suggestions = [
    "Comment payer mon loyer ?",
    "Quels documents pour une demande ?",
    "Comment contacter mon propriétaire ?",
    "C'est quoi une caution ?",
  ];

  @override
  void initState() {
    super.initState();
    _initConversation();
    // ← PAS de Timer.periodic ici — zéro polling
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _uiRefreshTimer?.cancel();
    // ← PAS de _refreshTimer à annuler — il n'existe pas
    super.dispose();
  }

  // ── Chargé UNE SEULE FOIS à l'ouverture ─────────────────────────────────
  Future<void> _initConversation() async {
    if (_conversationChargee || _isLoadingMessages) return; // ← anti double appel

    _isLoadingMessages = true;
    setState(() => _isInitLoading = true);

    try {
      final data = await _api.getMaConversationIA();
      _conversationId = data['id'];
      _conversationChargee = true;

      final msgs = (data['messages'] as List?) ?? [];
      setState(() {
        _messages.addAll(
          msgs.map((m) => Map<String, dynamic>.from(m)),
        );
      });
      _scrollToBottom();
    } catch (e) {
      print("==> Erreur init IA : $e");
    } finally {
      _isLoadingMessages = false;
      if (mounted) setState(() => _isInitLoading = false);
    }
  }

  // ── Envoi — append only, UN SEUL appel API ──────────────────────────────
  Future<void> _envoyer([String? texte]) async {
    final message = texte ?? _controller.text.trim();
    if (message.isEmpty || _conversationId == null || _iaEnTrainDEcrire) return;

    _controller.clear();

    // 1. Affiche message utilisateur immédiatement (local)
    setState(() {
      _messages.add({
        'type_expediteur': 'locataire',
        'contenu': message,
        'date_envoi': DateTime.now().toIso8601String(),
      });
      _iaEnTrainDEcrire = true;
      _debutAttente = DateTime.now();
    });
    _scrollToBottom();

    // 2. Chrono UX (rafraîchit juste le widget typing)
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _iaEnTrainDEcrire) setState(() {});
    });

    // 3. Timeout 90s
    bool timedOut = false;
    final timeoutTimer = Timer(const Duration(seconds: 90), () {
      timedOut = true;
      _uiRefreshTimer?.cancel();
      if (mounted) {
        setState(() {
          _iaEnTrainDEcrire = false;
          _debutAttente = null;
          _messages.add({
            'type_expediteur': 'ia',
            'contenu': '⏱ Réponse trop longue. Réessayez dans un moment.',
            'date_envoi': DateTime.now().toIso8601String(),
          });
        });
        _scrollToBottom();
      }
    });

    try {
      // 4. UN SEUL appel API — pas de refresh conversation après
      final response = await _api.envoyerMessageIA(
        conversationId: _conversationId!,
        contenu: message,
      );

      if (timedOut || !mounted) return;
      timeoutTimer.cancel();
      _uiRefreshTimer?.cancel();

      final msgIA = response['message_ia'];
      if (msgIA != null) {
        // 5. Append réponse IA directement — pas de reload complet
        setState(() {
          _iaEnTrainDEcrire = false;
          _debutAttente = null;
          _messages.add(Map<String, dynamic>.from(msgIA));
        });
      }
    } catch (e) {
      if (timedOut || !mounted) return;
      timeoutTimer.cancel();
      _uiRefreshTimer?.cancel();
      setState(() {
        _iaEnTrainDEcrire = false;
        _debutAttente = null;
        _messages.add({
          'type_expediteur': 'ia',
          'contenu': 'Désolé, une erreur est survenue. Réessayez.',
          'date_envoi': DateTime.now().toIso8601String(),
        });
      });
    }

    _scrollToBottom();
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
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: _primaryColor, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Loya — Assistant IA',
                style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black54),
              onPressed: () => setState(() => _messages.clear()),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isInitLoading)
            Container(
              color: _primaryColor.withOpacity(0.05),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Connexion à Loya...',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),

          Expanded(
            child: _isInitLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty && !_iaEnTrainDEcrire
                    ? _buildWelcome()
                    : ListView.builder(
                        controller: _scrollController,
                        cacheExtent: 1000,
                        addAutomaticKeepAlives: true,
                        addRepaintBoundaries: true,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length + (_iaEnTrainDEcrire ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) return _buildIaTyping();
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
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: _primaryColor, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bonjour ! Je suis Loya\nvotre assistante immobilière',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            'Posez-moi vos questions sur les logements,\nloyers, cautions et bien plus.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500, height: 1.5),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 10, runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _suggestions.map((s) => GestureDetector(
              onTap: () => _envoyer(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryColor.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
                  ],
                ),
                child: Text(s,
                    style: const TextStyle(fontSize: 13, color: _primaryColor)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> msg) {
    final isUser = msg['type_expediteur'] == 'locataire';
    final contenu = msg['contenu']?.toString() ?? '';
    final heure = _formatDate(msg['date_envoi']?.toString());

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                width: 32, height: 32,
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isUser ? _primaryColor : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contenu,
                      style: TextStyle(
                          fontSize: 14,
                          color: isUser ? Colors.white : Colors.black87,
                          height: 1.5),
                    ),
                    if (heure.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        heure,
                        style: TextStyle(
                            fontSize: 10,
                            color: isUser
                                ? Colors.white70
                                : Colors.grey.shade400),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildIaTyping() {
    final secondes = _debutAttente != null
        ? DateTime.now().difference(_debutAttente!).inSeconds
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome,
                color: _primaryColor, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Loya réfléchit',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500)),
                    const SizedBox(width: 8),
                    _buildDots(),
                  ],
                ),
                if (secondes > 5) ...[
                  const SizedBox(height: 4),
                  Text(
                    secondes > 25
                        ? '⏳ Analyse approfondie en cours...'
                        : '🔍 Recherche dans la base de données...',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
          3, (i) => _AnimatedDot(delay: Duration(milliseconds: i * 200))),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              enabled: !_iaEnTrainDEcrire,
              decoration: InputDecoration(
                hintText: _iaEnTrainDEcrire
                    ? 'Loya réfléchit...'
                    : 'Posez votre question...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: const Color(0xFFF5F6FA),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _envoyer(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _iaEnTrainDEcrire ? null : () => _envoyer(),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _iaEnTrainDEcrire
                    ? Colors.grey.shade300
                    : _primaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _iaEnTrainDEcrire
                    ? Icons.hourglass_empty
                    : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6, height: 6,
        decoration: const BoxDecoration(
            color: Color(0xFF1A3C6E), shape: BoxShape.circle),
      ),
    );
  }
}
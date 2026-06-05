import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_flutter/main.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/service/session_service.dart';
import 'package:mobile_flutter/service/websocket_service.dart';
import 'package:provider/provider.dart';

class SessionWrapper extends StatefulWidget {
  final Widget child;
  const SessionWrapper({super.key, required this.child});

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper>
    with WidgetsBindingObserver {

  bool _sessionExpiredHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ← Initialise et démarre le timer immédiatement
    SessionService.init(_onSessionExpired);
    SessionService.resetTimer();
    Future.microtask(() async {

    final token = await LocalStorage.getToken();

    if (token != null && token.isNotEmpty) {
      print("==> Connexion WebSocket automatique");
      webSocketService.connect();
    }
  });
    print("==> SessionWrapper initialisé, timer démarré");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SessionService.dispose();
    webSocketService.disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("==> Lifecycle : $state");
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        SessionService.onAppBackground();
        break;
      case AppLifecycleState.resumed:
        SessionService.onAppForeground();
        break;
      case AppLifecycleState.inactive:
        break;
    }
  }

  Future<void> _onSessionExpired() async {
    if (_sessionExpiredHandled) return;
    _sessionExpiredHandled = true;
    print("==> Déclenchement expiration session");

    // Vide les données
    await LocalStorage.clearAll();

    final navContext = navigatorKey.currentContext;
    if (navContext != null) {
      try {
        navContext.read<MessageProvider>().clearAll();
        navContext.read<UtilisateurProvider>().logout();
      } catch (_) {}
    }

    // Affiche le dialog sur le thread UI
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final navigator = navigatorKey.currentState;
      if (navigator == null) return;

      await showDialog(
        context: navigator.overlay!.context,
        barrierDismissible: false,
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_outline, color: Color(0xFF1A3C6E)),
                SizedBox(width: 10),
                Flexible(
                  child: Text('Session expirée',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            content: const Text(
              'Vous avez été déconnecté automatiquement pour des raisons de sécurité.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  navigatorKey.currentState
                      ?.pushNamedAndRemoveUntil('/login', (route) => false);
                  _sessionExpiredHandled = false;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3C6E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Se reconnecter',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      // ← Chaque tap ou mouvement remet le timer à zéro
      onPointerDown: (_) {
        print("==> Activité détectée → reset timer");
        SessionService.resetTimer();
      },
      onPointerMove: (_) => SessionService.resetTimer(),
      child: widget.child,
    );
  }
}
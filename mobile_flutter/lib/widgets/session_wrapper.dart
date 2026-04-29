import 'package:flutter/material.dart';
import 'package:mobile_flutter/main.dart';
import 'package:mobile_flutter/provider/auth_provider.dart';
import 'package:mobile_flutter/provider/locataire_provider.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/service/session_service.dart';
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
    SessionService.init(_onSessionExpired);
    SessionService.resetTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SessionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
    // Évite double déclenchement
    if (_sessionExpiredHandled) return;
    _sessionExpiredHandled = true;

    // Vide les données via navigatorKey pour avoir le bon contexte
    final navContext = navigatorKey.currentContext;
    if (navContext != null) {
      try {
        navContext.read<MessageProvider>().clearAll();
        navContext.read<UtilisateurProvider>().logout();
      } catch (_) {}
    }

    // Vide le storage
    await LocalStorage.clearAll();

    // Affiche le dialog via navigatorKey
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    await navigator.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.black54,
        pageBuilder: (ctx, _, __) => AlertDialog(
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
              onPressed: () => navigator.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C6E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Se reconnecter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    // Navigue vers login et vide toutes les routes
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    _sessionExpiredHandled = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => SessionService.resetTimer(),
      onPointerMove: (_) => SessionService.resetTimer(),
      child: widget.child,
    );
  }
}
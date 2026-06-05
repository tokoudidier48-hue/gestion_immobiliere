/*import 'dart:async';

class SessionService {
  static const Duration _timeoutDuration = Duration(minutes: 2);
  static const Duration _backgroundTimeout = Duration(minutes: 2);

  static Timer? _inactivityTimer;
  static Timer? _backgroundTimer;
  static DateTime? _backgroundStartTime;
  static Future<void> Function()? _onSessionExpired; // ← Future<void> au lieu de VoidCallback

  static void init(Future<void> Function() onSessionExpired) {
    _onSessionExpired = onSessionExpired;
  }

  static void resetTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeoutDuration, () => _expireSession());
  }

  static void onAppBackground() {
    _backgroundStartTime = DateTime.now();
    _backgroundTimer?.cancel();
    _backgroundTimer = Timer(_backgroundTimeout, () => _expireSession());
    _inactivityTimer?.cancel();
  }

  static void onAppForeground() {
    _backgroundTimer?.cancel();
    if (_backgroundStartTime != null) {
      final elapsed = DateTime.now().difference(_backgroundStartTime!);
      if (elapsed >= _backgroundTimeout) {
        _expireSession();
        return;
      }
    }
    resetTimer();
  }

  static void _expireSession() {
    _inactivityTimer?.cancel();
    _backgroundTimer?.cancel();
    _onSessionExpired?.call();
  }

  static void dispose() {
    _inactivityTimer?.cancel();
    _backgroundTimer?.cancel();
    _onSessionExpired = null;
  }

  static void stop() {
    _inactivityTimer?.cancel();
    _backgroundTimer?.cancel();
  }
}
*/
import 'dart:async';

class SessionService {
  static const Duration _inactivityTimeout = Duration(minutes: 45);
  static const Duration _backgroundTimeout = Duration(minutes: 40);

  static Timer? _inactivityTimer;
  static DateTime? _backgroundStartTime;
  static Future<void> Function()? _onSessionExpired;
  static bool _isExpired = false;

  static void init(Future<void> Function() onSessionExpired) {
    _isExpired = false;
    _onSessionExpired = onSessionExpired;
  }

  // Appelé à chaque interaction utilisateur
  static void resetTimer() {
    if (_isExpired) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      print("==> Session expirée par inactivité");
      _expireSession();
    });
  }

  // Appelé quand l'app passe en arrière-plan
  static void onAppBackground() {
    if (_isExpired) return;
    _backgroundStartTime = DateTime.now();
    print("==> App en arrière-plan à : $_backgroundStartTime");
    // On garde le timer d'inactivité actif
  }

  // Appelé quand l'app revient au premier plan
  static void onAppForeground() {
    if (_isExpired) return;
    if (_backgroundStartTime != null) {
      final elapsed = DateTime.now().difference(_backgroundStartTime!);
      print("==> Temps en arrière-plan : ${elapsed.inMinutes} minutes");
      if (elapsed >= _backgroundTimeout) {
        print("==> Session expirée après arrière-plan");
        _expireSession();
        return;
      }
      _backgroundStartTime = null;
    }
    resetTimer();
  }

  static void _expireSession() {
    if (_isExpired) return;
    _isExpired = true;
    _inactivityTimer?.cancel();
    _onSessionExpired?.call();
  }

  static void stop() {
    _isExpired = true;
    _inactivityTimer?.cancel();
    _onSessionExpired = null;
  }

  static void dispose() {
    _inactivityTimer?.cancel();
    _onSessionExpired = null;
  }
}
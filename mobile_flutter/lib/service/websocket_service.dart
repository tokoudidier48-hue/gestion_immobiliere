import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mobile_flutter/service/local_storage.dart';
import 'package:mobile_flutter/Config/app_config.dart';

class WebSocketService {
  static const String _wsBaseUrl = '${AppConfig.baseUrl}/ws/notifications/';

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  // Stream public pour écouter les messages
  Stream<Map<String, dynamic>>? get stream => _controller?.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
   print("==> connect() appelé");

  if (_isConnected || _channel != null) {
    print("==> WebSocket déjà connecté");
    return;
  }

    _shouldReconnect = true;
    _controller ??= StreamController<Map<String, dynamic>>.broadcast();

    final token = await LocalStorage.getToken();
    if (token == null || token.isEmpty) {
      print("==> WebSocket : pas de token, connexion annulée");
      return;
    }

    try {
      final wsUrl = '${_wsBaseUrl}?token=$token';
      print("==> URL WebSocket : $wsUrl");


      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
      );

      _isConnected = true;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            print("==> WebSocket reçu : $data");
            if (!(_controller?.isClosed ?? true)) {
              _controller!.add(data);
            }
          } catch (e) {
            print("==> WebSocket erreur parsing : $e");
          }
        },
        onError: (error) {
          print("==> WebSocket erreur : $error");
          _isConnected = false;
          _channel = null;
          _scheduleReconnect();
        },

        onDone: () {
          print("==> WebSocket fermé");
          _isConnected = false;
          _channel = null;
          _scheduleReconnect();
        },
      );

      print("==> WebSocket connecté !");
    } catch (e) {
      print("==> WebSocket échec connexion : $e");
      _isConnected = false;
      _channel = null;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) return;

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    print("==> WebSocket reconnexion dans ${delay.inSeconds}s (tentative $_reconnectAttempts)");

    Future.delayed(delay, () {
      if (_shouldReconnect) connect();
    });
  }

  void disconnect() {
    _shouldReconnect = false;
    _isConnected = false;
    _channel?.sink.close();
    _channel = null;
    _controller?.close();
    _controller = null;
    print("==> WebSocket déconnecté");
  }
}

// Singleton global
final webSocketService = WebSocketService();
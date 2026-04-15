import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_flutter/main.dart';
import 'package:mobile_flutter/service/auth/api.dart';
import 'package:mobile_flutter/service/local_storage.dart';

// Handler pour les messages en arrière-plan
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("==> Message reçu en arrière-plan : ${message.notification?.title}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'loyasmart_channel',
    'LoyaSmart Notifications',
    description: 'Notifications importantes de LoyaSmart',
    importance: Importance.max,
  );

  static Future<void> init() async {
    // Enregistre le handler arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Demande la permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print("==> Permission notifications : ${settings.authorizationStatus}");

    // Initialise les notifications locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
  settings: initSettings,
  onDidReceiveNotificationResponse: (NotificationResponse details) {
    print("==> Notification cliquée : ${details.payload}");
  },
);

    // Crée le canal Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Récupère et sauvegarde le token FCM
    await _saveToken();

    // Écoute les nouveaux tokens
    _messaging.onTokenRefresh.listen((token) async {
      print("==> Nouveau token FCM : $token");
      await LocalStorage.saveFcmToken(token);
      await _sendTokenToBackend(token);
    });

    // Notifications quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("==> Message au premier plan : ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // App ouverte depuis une notification (app en arrière-plan)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("==> App ouverte via notification : ${message.data}");
      _handleNotificationTap(message.data);
    });

    // App démarrée depuis une notification (app fermée)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print("==> App démarrée via notification : ${initialMessage.data}");
      _handleNotificationTap(initialMessage.data);
    }
  }

  static Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        print("==> Token FCM : $token");
        await LocalStorage.saveFcmToken(token);
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      print("==> Erreur récupération token FCM : $e");
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
  try {
    final savedToken = await LocalStorage.getFcmToken();

    if (savedToken == token) {
      print("==> Token déjà envoyé");
      return;
    }

    await ApiService().envoyerTokenFCM(token);
    await LocalStorage.saveFcmToken(token);

    print("==> Token envoyé au backend : $token");
  } catch (e) {
    print("==> Erreur envoi token backend : $e");
  }
}

  /*static void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  if (notification == null) return;
print("==> MESSAGE COMPLET : ${message.data}");
print("==> NOTIFICATION : ${message.notification}");
  _localNotifications.show(
    id: notification.hashCode,
    title: notification.title,
    body: notification.body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.toString(),
  );
}*/
/*
// Remplace _showLocalNotification par ceci
static void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  final data = message.data;

  final title = notification?.title ?? data['title'] ?? "LoyaSmart";
  final body = notification?.body ?? data['message'] ?? "Nouvelle notification";

  _localNotifications.show(
    id: DateTime.now().millisecond, // ← ID unique pour chaque notif
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: data['type'] ?? '',
  );
}*/

static void _showLocalNotification(RemoteMessage message) {
  final notification = message.notification;
  final data = message.data;

  print("==> Message reçu au premier plan");
  print("==> Notification : $notification");
  print("==> Data : $data");

  final title = notification?.title ?? 
                data['titre'] ?? 
                data['title'] ?? 
                'LoyaSmart';
                
  final body = notification?.body ?? 
               data['message'] ?? 
               data['body'] ?? 
               'Nouvelle notification';

  _localNotifications.show(
    id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
    title: title,
    body: body,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.high,
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(body),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: data['type'] ?? '',
  );
}
  static void _handleNotificationTap(Map<String, dynamic> data) {
  final type = data['type'] ?? '';

  Future.delayed(const Duration(milliseconds: 500), () {
    switch (type) {
      case 'message':
        navigatorKey.currentState?.pushNamed('/messages');
        break;
      case 'demande':
      case 'reponse_demande':
        navigatorKey.currentState?.pushNamed('/demandes');
        break;
      case 'paiement':
        navigatorKey.currentState?.pushNamed('/paiements');
        break;
      case 'colocataire':
        navigatorKey.currentState?.pushNamed('/messages');
        break;
      default:
        break;
    }
  });
}
}   
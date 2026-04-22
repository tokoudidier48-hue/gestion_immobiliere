import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:mobile_flutter/firebase_options.dart';
import 'package:mobile_flutter/main.dart';
import 'package:mobile_flutter/service/auth/api.dart';
import 'package:mobile_flutter/service/local_storage.dart';

// Handler pour les messages en arrière-plan
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ← Firebase doit être initialisé ici aussi
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("==> Message reçu en arrière-plan : ${message.notification?.title}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'loyasmart_channel_v3',
    'LoyaSmart Notifications',
    description: 'Notifications importantes de LoyaSmart',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
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
    final authToken = await LocalStorage.getToken();

    // N'envoie que si connecté
    if (authToken == null || authToken.isEmpty) {
      print("==> Non connecté, token FCM gardé pour après login");
      return;
    }

    await ApiService().envoyerTokenFCM(token);
    await LocalStorage.saveFcmToken(token);
    print("==> Token FCM envoyé au backend : $token");
  } catch (e) {
    print("==> Erreur envoi token backend : $e");
  }
}

static Future<void> renvoyerTokenApresLogin() async {
  try {
    final authToken = await LocalStorage.getToken();
    if (authToken == null || authToken.isEmpty) return;

    final fcmToken = await _messaging.getToken();
    if (fcmToken != null) {
      print("==> Renvoi token FCM après login : $fcmToken");
      await ApiService().envoyerTokenFCM(fcmToken);
      await LocalStorage.saveFcmToken(fcmToken);
      print("==> Token FCM renvoyé avec succès");
    }
  } catch (e) {
    print("==> Erreur renvoi token après login : $e");
  }
}

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
    id: DateTime.now().millisecondsSinceEpoch.remainder(10000),
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
        icon: 'ic_notification',
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
  print("==> Navigation depuis notification type : $type");

  Future.delayed(const Duration(milliseconds: 500), () async {
    final role = await LocalStorage.getRole();

    switch (type) {
      case 'message':
        if (role == 'proprietaire') {
          navigatorKey.currentState?.pushNamed('/messages_proprio');
        } else {
          navigatorKey.currentState?.pushNamed('/messages');
        }
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

import firebase_admin
from firebase_admin import messaging
from .firebase_config import initialize_firebase
from comptes.models import FCMToken

# Initialisation silencieuse
FIREBASE_READY = initialize_firebase()


def envoyer_notification_push(token_fcm, titre, message, donnees=None, priority='high'):
    """
    Envoie une notification push via FCM (mode DATA ONLY pour contrôle Flutter)
    """
    if not FIREBASE_READY:
        return False

    if not token_fcm:
        print("❌ Token FCM manquant")
        return False

    try:
        # 🔥 IMPORTANT : DATA ONLY (pas de notification=...)
        data_payload = {
            'title': titre,
            'body': message,
            'type': donnees.get('type', '') if donnees else '',
            'lien': donnees.get('lien', '') if donnees else '',
        }

        message_push = messaging.Message(
            data=data_payload,
            token=token_fcm,

            android=messaging.AndroidConfig(
                priority='high' if priority == 'high' else 'normal',
            ),

            apns=messaging.APNSConfig(
                headers={
                    'apns-priority': '10' if priority == 'high' else '5',
                },
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        sound='default',
                        content_available=True,
                    )
                )
            ),
        )

        # Envoi
        response = messaging.send(message_push)
        print(f"✅ Notification envoyée: {response}")
        return True

    except Exception as e:
        print(f"❌ Erreur d'envoi FCM: {e}")
        return False


def notify_user(user, titre, message, donnees=None, priority='high'):
    """
    Envoie une notification push à un utilisateur
    """
    if not FIREBASE_READY:
        return False

    try:
        # Récupérer le token actif
        token_obj = FCMToken.objects.filter(
            utilisateur=user,
            est_actif=True
        ).first()

        if not token_obj:
            print(f"ℹ️ Aucun token FCM trouvé pour {user.email}")
            return False

        # Envoi notification
        return envoyer_notification_push(
            token_obj.token,
            titre,
            message,
            donnees,
            priority
        )

    except Exception as e:
        print(f"⚠️ Erreur lors de l'envoi de notification à {user.email}: {e}")
        return False

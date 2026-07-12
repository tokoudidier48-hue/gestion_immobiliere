# apps/messagerie/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer
from .models import Message


@receiver(post_save, sender=Message)
def notify_new_message(sender, instance, created, **kwargs):
    """
    Quand un nouveau message est créé, notifier en temps réel
    les autres participants via WebSocket
    """
    if not created:
        return  # Seulement pour les nouveaux messages
    
    message = instance
    conversation = message.conversation
    
    # Récupérer les autres participants (tous sauf l'expéditeur)
    autres_participants = conversation.participants.exclude(id=message.expediteur.id)
    
    # Données du message à envoyer
    message_data = {
        'id': message.id,
        'contenu': message.contenu,
        'expediteur_id': message.expediteur.id,
        'expediteur_nom': message.expediteur.get_full_name(),
        'date_envoi': message.date_envoi.isoformat(),
        'conversation_id': conversation.id,
        'est_lu': message.est_lu,
    }
    
    # Récupérer le channel layer
    channel_layer = get_channel_layer()
    
    # Envoyer la notification à chaque autre participant
    for participant in autres_participants:
        room_name = f'notifications_{participant.id}'
        
        # Envoi synchrone vers le groupe WebSocket
        async_to_sync(channel_layer.group_send)(
            room_name,
            {
                'type': 'send_notification',  # Méthode dans le consumer
                'conversation_id': conversation.id,
                'message_data': message_data,
            }
        )
    
    print(f"📨 Notification WebSocket envoyée à {autres_participants.count()} participant(s)")
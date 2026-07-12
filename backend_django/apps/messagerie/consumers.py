import json
import logging
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from django.contrib.auth import get_user_model

logger = logging.getLogger(__name__)
Utilisateur = get_user_model()


class NotificationConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        """Quand le client Flutter se connecte au WebSocket"""
        self.user = self.scope.get('user')
        
        # Vérifier que l'utilisateur est authentifié
        if not self.user or self.user.is_anonymous:
            logger.warning(f"❌ WebSocket rejeté: utilisateur non authentifié")
            await self.close(code=4001)
            return
        
        # Groupe privé pour cet utilisateur: notif_USERID
        self.room_group_name = f'notifications_{self.user.id}'
        
        try:
            # Ajouter l'utilisateur à son groupe
            await self.channel_layer.group_add(
                self.room_group_name,
                self.channel_name
            )
            
            # Accepter la connexion WebSocket
            await self.accept()
            
            logger.info(f"✅ WebSocket connecté pour {self.user.email} (ID: {self.user.id})")
            
        except Exception as e:
            logger.exception(f"❌ Erreur lors de la connexion WebSocket: {e}")
            await self.close(code=5000)
    
    async def disconnect(self, close_code):
        """Quand le client se déconnecte"""
        if hasattr(self, 'room_group_name'):
            try:
                await self.channel_layer.group_discard(
                    self.room_group_name,
                    self.channel_name
                )
            except Exception as e:
                logger.warning(f"⚠️ Erreur lors de la déconnexion: {e}")
        
        user_info = getattr(self, 'user_email', 'inconnu')
        logger.info(f"❌ WebSocket déconnecté pour {user_info} (code: {close_code})")
    
    async def receive(self, text_data):
        """
        Reçoit un message du client Flutter
        """
        try:
            data = json.loads(text_data)
            message_type = data.get('type')
            
            if message_type == 'mark_read':
                message_id = data.get('message_id')
                if message_id:
                    await self.mark_message_as_read(message_id)
                    await self.send(text_data=json.dumps({
                        'type': 'mark_read_success',
                        'message_id': message_id
                    }))
            
            elif message_type == 'ping':
                await self.send(text_data=json.dumps({'type': 'pong'}))
            
            elif message_type == 'get_unread_count':
                count = await self.get_unread_count()
                await self.send(text_data=json.dumps({
                    'type': 'unread_count',
                    'count': count
                }))
                
        except json.JSONDecodeError as e:
            logger.warning(f"⚠️ JSON invalide reçu: {e}")
        except Exception as e:
            logger.exception(f"❌ Erreur dans receive: {e}")
    
    async def send_notification(self, event):
        """
        Envoie une notification au client Flutter
        Cette méthode est appelée depuis le signal
        """
        try:
            await self.send(text_data=json.dumps({
                'type': 'new_message',
                'conversation_id': event.get('conversation_id'),
                'message': event.get('message_data')
            }))
        except Exception as e:
            logger.exception(f"❌ Erreur lors de l'envoi de notification: {e}")
    
    @database_sync_to_async
    def mark_message_as_read(self, message_id):
        """Marquer un message comme lu"""
        from .models import Message
        try:
            message = Message.objects.get(id=message_id)
            if message.expediteur != self.user and not message.est_lu:
                message.est_lu = True
                from django.utils import timezone
                message.date_lecture = timezone.now()
                message.save()
                return True
        except Message.DoesNotExist:
            logger.warning(f"⚠️ Message {message_id} non trouvé")
        except Exception as e:
            logger.exception(f"❌ Erreur lors du marquage du message: {e}")
        return False
    
    @database_sync_to_async
    def get_unread_count(self):
        """Récupère le nombre de messages non lus pour l'utilisateur"""
        from .models import Message
        try:
            return Message.objects.filter(
                conversation__participants=self.user,
                est_lu=False
            ).exclude(expediteur=self.user).count()
        except Exception as e:
            logger.exception(f"❌ Erreur lors du comptage des messages: {e}")
            return 0
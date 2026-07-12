from rest_framework import serializers
from django.utils import timezone
from .models import Conversation, Message
from comptes.serializers import UtilisateurSerializer


class ConversationSerializer(serializers.ModelSerializer):
    participants = UtilisateurSerializer(many=True, read_only=True)
    dernier_message = serializers.SerializerMethodField()

    class Meta:
        model = Conversation
        fields = ['id', 'participants', 'date_creation', 'date_dernier_message', 'dernier_message']

    def get_dernier_message(self, obj):
        dernier = obj.messages.order_by('-date_envoi').first()
        if dernier:
            from django.utils import timezone
            return {
                'contenu': dernier.contenu[:50],
                'expediteur': dernier.expediteur.get_full_name(),
                'date': timezone.localtime(dernier.date_envoi).strftime('%d/%m/%Y %H:%M')
            }
        return None


class MessageSerializer(serializers.ModelSerializer):
    expediteur_nom = serializers.CharField(source='expediteur.get_full_name', read_only=True)
    date_envoi_formatee = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = ['id', 'conversation', 'expediteur', 'expediteur_nom', 'contenu', 'est_lu', 
                  'date_envoi', 'date_envoi_formatee']  # on garde date_envoi (UTC) pour la logique

    def get_date_envoi_formatee(self, obj):
        from django.utils import timezone
        return timezone.localtime(obj.date_envoi).strftime('%d/%m/%Y %H:%M')


class MessageCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['conversation', 'contenu']
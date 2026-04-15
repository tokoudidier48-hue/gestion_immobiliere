from rest_framework import serializers
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
            return {
                'contenu': dernier.contenu[:50],
                'expediteur': dernier.expediteur.get_full_name(),
                'date': dernier.date_envoi
            }
        return None


class MessageSerializer(serializers.ModelSerializer):
    expediteur_nom = serializers.CharField(source='expediteur.get_full_name', read_only=True)

    class Meta:
        model = Message
        fields = ['id', 'conversation', 'expediteur', 'expediteur_nom', 'contenu', 'est_lu', 'date_envoi']


class MessageCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['conversation', 'contenu']
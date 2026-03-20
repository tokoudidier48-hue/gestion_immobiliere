from rest_framework import serializers
from .models import ConversationIA, MessageIA

class MessageIASerializer(serializers.ModelSerializer):
    class Meta:
        model = MessageIA
        fields = ['id', 'type_expediteur', 'contenu', 'type_message', 'fichier_vocal', 'date_envoi']


class ConversationIASerializer(serializers.ModelSerializer):
    locataire_nom = serializers.CharField(source='locataire.get_full_name', read_only=True)
    messages = MessageIASerializer(many=True, read_only=True)
    
    class Meta:
        model = ConversationIA
        fields = ['id', 'locataire', 'locataire_nom', 'date_debut', 'date_dernier_message', 'est_active', 'messages']
        read_only_fields = ['locataire', 'date_debut', 'date_dernier_message']


class MessageIACreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = MessageIA
        fields = ['contenu', 'type_message', 'fichier_vocal']
    
    def validate(self, attrs):
        request = self.context.get('request')
        user = request.user
        if user.role != 'locataire':
            raise serializers.ValidationError("Seuls les locataires peuvent discuter avec Loya.")
        return attrs
# apps/agent_ia/serializers.py

from rest_framework import serializers
from django.core.exceptions import ValidationError

from .models import ConversationIA, MessageIA, RecommandationIA


# =========================================================
# MESSAGE — LECTURE
# =========================================================

class MessageIASerializer(serializers.ModelSerializer):
    """
    Sérialiseur de lecture des messages.
    Champs limités à ce dont Flutter a besoin.
    """

    class Meta:
        model = MessageIA
        fields = [
            "id",
            "conversation",
            "type_expediteur",
            "contenu",
            "type_message",
            "fichier_vocal",
            "date_envoi",
        ]
        read_only_fields = fields


# =========================================================
# MESSAGE — CRÉATION
# =========================================================

class MessageIACreateSerializer(serializers.ModelSerializer):
    """
    Sérialiseur pour la création d'un message locataire.
    """

    class Meta:
        model = MessageIA
        fields = ["contenu", "type_message"]

    def validate(self, data):
        request = self.context.get("request")
        conversation = self.context.get("conversation")

        if request is None:
            raise ValidationError("Requête manquante.")

        if conversation is None:
            raise ValidationError("Conversation manquante.")

        if conversation.locataire != request.user:
            raise ValidationError(
                "Vous n'êtes pas autorisé à envoyer un message dans cette conversation."
            )

        contenu = data.get("contenu", "")
        if not isinstance(contenu, str) or not contenu.strip():
            raise ValidationError("Le message ne peut pas être vide.")

        data["contenu"] = contenu.strip()
        return data

    def create(self, validated_data):
        conversation = self.context["conversation"]
        return MessageIA.objects.create(
            conversation=conversation,
            type_expediteur="locataire",
            contenu=validated_data["contenu"],
            type_message=validated_data.get("type_message", "texte"),
        )


# =========================================================
# CONVERSATION — LISTE (sans messages)
# =========================================================

# serializers.py
class ConversationIASerializer(serializers.ModelSerializer):

    messages = serializers.SerializerMethodField()
    nombre_messages = serializers.SerializerMethodField()

    class Meta:
        model = ConversationIA
        fields = [
            "id",
            "locataire",
            "date_debut",
            "date_dernier_message",
            "est_active",
            "nombre_messages",
            "messages",
        ]
        read_only_fields = fields

    def get_nombre_messages(self, obj) -> int:
        return obj.messages.count()

    def get_messages(self, obj):
        """30 derniers messages triés par date — persistants en DB."""
        messages = obj.messages.order_by("date_envoi")
        return MessageIASerializer(messages, many=True).data

# =========================================================
# RECOMMANDATION
# =========================================================

class RecommandationIASerializer(serializers.ModelSerializer):

    class Meta:
        model = RecommandationIA
        fields = [
            "id",
            "conversation",
            "criteres_recherche",
            "date_recommandation",
        ]
        read_only_fields = fields
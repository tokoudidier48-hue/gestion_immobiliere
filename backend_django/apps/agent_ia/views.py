# apps/agent_ia/views.py

from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied

from .models import ConversationIA, MessageIA
from .serializers import (
    ConversationIASerializer,
    MessageIASerializer,
    MessageIACreateSerializer,
)
from .rag_engine import RAGChatbot

import logging
import shutil
from pathlib import Path
from django.conf import settings

logger = logging.getLogger(__name__)


# =========================================================
# MESSAGES IA
# =========================================================

class MessageIAViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Lecture des messages uniquement.
    """

    queryset = MessageIA.objects.all()
    serializer_class = MessageIASerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user

        if not hasattr(user, "role") or user.role != "locataire":
            return MessageIA.objects.none()

        conversation_id = self.request.query_params.get("conversation")
        last_id = self.request.query_params.get("last_id")

        queryset = MessageIA.objects.filter(conversation__locataire=user)

        if conversation_id:
            queryset = queryset.filter(conversation_id=conversation_id)

        if last_id:
            queryset = queryset.filter(id__gt=last_id)
            return queryset.order_by("id")

        return queryset.order_by("-id")[:20]


# =========================================================
# CONVERSATIONS IA
# =========================================================

class ConversationIAViewSet(viewsets.ModelViewSet):
    """
    Gestion des conversations avec Loya.
    """

    queryset = ConversationIA.objects.all()
    serializer_class = ConversationIASerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if hasattr(user, "role") and user.role == "locataire":
            return ConversationIA.objects.filter(locataire=user)
        return ConversationIA.objects.none()

    def perform_create(self, serializer):
        serializer.save(locataire=self.request.user)

    # =====================================================
    # RÉCUPÉRATION / CRÉATION CONVERSATION
    # =====================================================

    @action(detail=False, methods=["get"])
    def ma_conversation(self, request):
        """
        Récupère ou crée la conversation active du locataire.
        Retourne uniquement la conversation — Flutter charge
        les messages séparément via MessageIAViewSet.
        """
        if not hasattr(request.user, "role") or request.user.role != "locataire":
            raise PermissionDenied("Seuls les locataires peuvent utiliser Loya.")

        conversation = ConversationIA.objects.filter(
            locataire=request.user,
            est_active=True,
        ).first()

        if not conversation:
            conversation = ConversationIA.objects.create(
                locataire=request.user,
                est_active=True,
            )
            MessageIA.objects.create(
                conversation=conversation,
                type_expediteur="ia",
                contenu=(
                    "Bonjour 😊 Je suis Loya, votre assistant immobilier à Lokossa.\n\n"
                    "Dites-moi ce que vous cherchez : type de logement, budget, quartier... "
                    "Je suis là pour vous aider !"
                ),
                type_message="texte",
            )

        return Response(self.get_serializer(conversation).data)

    # =====================================================
    # ENVOI MESSAGE + RÉPONSE IA
    # =====================================================

    @action(detail=True, methods=["post"])
    def envoyer_message(self, request, pk=None):
        """
        Reçoit le message du locataire, appelle le RAGChatbot,
        sauvegarde et retourne la réponse IA.
        """
        conversation = self.get_object()

        if request.user != conversation.locataire:
            raise PermissionDenied("Cette conversation ne vous appartient pas.")

        contenu = request.data.get("contenu", "").strip()
        type_message = request.data.get("type_message", "texte")

        if not contenu:
            return Response({"error": "Message vide."}, status=400)

        # -------------------------------------------------
        # SAUVEGARDE MESSAGE LOCATAIRE
        # -------------------------------------------------
        message_locataire = MessageIA.objects.create(
            conversation=conversation,
            type_expediteur="locataire",
            contenu=contenu,
            type_message=type_message,
        )
        
        # -------------------------------------------------
        # CHARGEMENT HISTORIQUE DEPUIS LA DB
        # Les 20 derniers messages pour le contexte
        # -------------------------------------------------
        historique_qs = (
            MessageIA.objects.filter(conversation=conversation)
            .order_by("-id")[:20]
        )
        historique = [
            {
                "role": "user" if m.type_expediteur == "locataire" else "assistant",
                "content": m.contenu,
            }
            for m in reversed(list(historique_qs))
        ]

        # -------------------------------------------------
        # APPEL CHATBOT IA
        # -------------------------------------------------
        try:
            chatbot = RAGChatbot(user=request.user)
            resultat = chatbot.repondre(
                message=contenu,
                historique=historique,
            )
            reponse_ia = resultat.get("reponse") or (
                "Je n'ai pas bien compris 😕 "
                "Pouvez-vous reformuler votre demande ?"
            )

        except Exception as e:
            logger.exception(
                "Erreur chatbot IA pour user=%s : %s",
                request.user.id,
                e,
            )
            reponse_ia = (
                "Désolé, j'ai rencontré un problème technique 😕 "
                "Veuillez réessayer dans un instant."
            )

        # -------------------------------------------------
        # SAUVEGARDE RÉPONSE IA
        # -------------------------------------------------
        message_ia = MessageIA.objects.create(
            conversation=conversation,
            type_expediteur="ia",
            contenu=reponse_ia,
            type_message="texte",
        )

        logger.info(
            "Conversation %s | User %s | Message: %s | Intent traité.",
            conversation.id,
            request.user.id,
            contenu[:60],
        )

        return Response(
            {
                "message_locataire": MessageIASerializer(message_locataire).data,
                "message_ia": MessageIASerializer(message_ia).data,
            }
        )

    # =====================================================
    # RESET BASE VECTORIELLE (admin only)
    # =====================================================

    @action(detail=False, methods=["get"])
    def reinitialiser_base(self, request):
        """
        Réinitialise la base vectorielle FAISS (superuser uniquement).
        """
        if not request.user.is_superuser:
            raise PermissionDenied("Action réservée aux administrateurs.")

        vectorstore_path = Path(settings.BASE_DIR) / "data" / "vectorstore"

        if vectorstore_path.exists():
            shutil.rmtree(vectorstore_path)
            logger.warning(
                "Base vectorielle supprimée par admin user=%s",
                request.user.id,
            )

        return Response({"message": "Base vectorielle réinitialisée avec succès."})
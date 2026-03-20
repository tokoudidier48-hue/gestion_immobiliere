from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from .models import ConversationIA, MessageIA
from .serializers import (
    ConversationIASerializer, MessageIASerializer,
    MessageIACreateSerializer
)
from .rag_engine import RAGChatbot
import logging

logger = logging.getLogger(__name__)


class MessageIAViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet pour consulter les messages (lecture seule)
    """
    queryset = MessageIA.objects.all()
    serializer_class = MessageIASerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'locataire':
            return MessageIA.objects.filter(conversation__locataire=user)
        return MessageIA.objects.none()


class ConversationIAViewSet(viewsets.ModelViewSet):
    queryset = ConversationIA.objects.all()
    serializer_class = ConversationIASerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'locataire':
            return ConversationIA.objects.filter(locataire=user)
        return ConversationIA.objects.none()
    
    def perform_create(self, serializer):
        serializer.save(locataire=self.request.user)
    
    @action(detail=False, methods=['get'])
    def ma_conversation(self, request):
        """Récupère ou crée la conversation active du locataire"""
        if request.user.role != 'locataire':
            raise PermissionDenied("Seuls les locataires peuvent discuter avec Loya.")
        
        conversation = ConversationIA.objects.filter(
            locataire=request.user,
            est_active=True
        ).first()
        
        if not conversation:
            conversation = ConversationIA.objects.create(
                locataire=request.user,
                est_active=True
            )
            # Message de bienvenue
            MessageIA.objects.create(
                conversation=conversation,
                type_expediteur='ia',
                contenu="Bonjour ! Je suis Loya, votre assistant intelligent. Je peux vous aider à trouver un logement, répondre à vos questions sur les locations, et vous guider dans vos démarches. Comment puis-je vous aider aujourd'hui ?",
                type_message='texte'
            )
        
        serializer = self.get_serializer(conversation)
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def envoyer_message(self, request, pk=None):
        conversation = self.get_object()
        if request.user != conversation.locataire:
            raise PermissionDenied("Cette conversation ne vous appartient pas.")
        
        # Créer le message du locataire
        message_serializer = MessageIACreateSerializer(
            data=request.data,
            context={'request': request}
        )
        message_serializer.is_valid(raise_exception=True)
        
        contenu = request.data.get('contenu', '')
        type_message = request.data.get('type_message', 'texte')
        
        message_locataire = message_serializer.save(
            conversation=conversation,
            type_expediteur='locataire',
            contenu=contenu,
            type_message=type_message
        )
        
        # Initialiser le chatbot RAG pour cet utilisateur
        try:
            chatbot = RAGChatbot(request.user)
            resultat = chatbot.repondre(contenu)
            reponse_ia = resultat['reponse']
            
        except Exception as e:
            logger.error(f"Erreur chatbot: {e}")
            reponse_ia = "Désolé, j'ai eu un problème technique. Veuillez réessayer dans quelques instants."
        
        # Créer la réponse de l'IA
        message_ia = MessageIA.objects.create(
            conversation=conversation,
            type_expediteur='ia',
            contenu=reponse_ia,
            type_message='texte'
        )
        
        conversation.save()  # Met à jour date_dernier_message
        
        return Response({
            'message_locataire': MessageIASerializer(message_locataire).data,
            'message_ia': MessageIASerializer(message_ia).data
        })
    
    @action(detail=False, methods=['get'])
    def reinitialiser_base(self, request):
        """Réinitialise la base vectorielle (admin seulement)"""
        if not request.user.is_superuser:
            raise PermissionDenied("Action réservée aux administrateurs.")
        
        # Supprimer l'ancienne base et forcer sa recréation
        import shutil
        from pathlib import Path
        from django.conf import settings
        
        vectorstore_path = Path(settings.BASE_DIR) / 'data' / 'vectorstore'
        if vectorstore_path.exists():
            shutil.rmtree(vectorstore_path)
        
        return Response({"message": "Base vectorielle réinitialisée avec succès"})
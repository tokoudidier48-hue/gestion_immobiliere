from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied, ValidationError
from django.contrib.auth import get_user_model
from django.utils import timezone

from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer, MessageCreateSerializer
from notifications.models import Notification
from notifications.fcm_service import notify_user

# ✅ Modèle utilisateur
Utilisateur = get_user_model()


class ConversationViewSet(viewsets.ModelViewSet):
    queryset = Conversation.objects.all()
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Conversation.objects.filter(participants=user).distinct()

    def create(self, request, *args, **kwargs):
        user = request.user
        autre_participant_id = request.data.get('autre_participant')

        # ❌ validation champ obligatoire
        if not autre_participant_id:
            return Response(
                {"error": "Le champ autre_participant est obligatoire"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ❌ vérifier utilisateur
        try:
            autre = Utilisateur.objects.get(id=autre_participant_id)
        except Utilisateur.DoesNotExist:
            return Response(
                {"error": "Utilisateur introuvable"},
                status=status.HTTP_404_NOT_FOUND
            )

        # 🔥 ANTI-DOUBLON CONVERSATION (IMPORTANT)
        conversation = Conversation.objects.filter(participants=user)\
                                           .filter(participants=autre)\
                                           .distinct().first()

        # ✅ si existe déjà → on retourne directement
        if conversation:
            return Response(
                self.get_serializer(conversation).data,
                status=status.HTTP_200_OK
            )

        # ❌ sinon création
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        conversation = serializer.save()

        conversation.participants.add(user, autre)

        return Response(
            self.get_serializer(conversation).data,
            status=status.HTTP_201_CREATED
        )


class MessageViewSet(viewsets.ModelViewSet):
    queryset = Message.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        conversation_id = self.request.query_params.get('conversation')

        queryset = Message.objects.filter(conversation__participants=user)

        # 🔥 filtrer par conversation spécifique
        if conversation_id:
            queryset = queryset.filter(conversation_id=conversation_id)

        return queryset

    def get_object(self):
        obj = super().get_object()

        if self.request.user not in obj.conversation.participants.all():
            raise PermissionDenied("Accès refusé")

        return obj

    def destroy(self, request, *args, **kwargs):
        message = self.get_object()

        if message.expediteur != request.user:
            raise PermissionDenied("Vous ne pouvez pas supprimer ce message")

        return super().destroy(request, *args, **kwargs)

    def update(self, request, *args, **kwargs):
        message = self.get_object()

        if message.expediteur != request.user:
            raise PermissionDenied("Vous ne pouvez pas modifier ce message")

        return super().update(request, *args, **kwargs)

    def get_serializer_class(self):
        if self.action == 'create':
            return MessageCreateSerializer
        return MessageSerializer

    def perform_create(self, serializer):
        message = serializer.save(expediteur=self.request.user)

        # 🔔 Notification à l'autre participant
        conversation = message.conversation
        autre_participant = conversation.participants.exclude(
            id=self.request.user.id
        ).first()

        if autre_participant:
            Notification.objects.create(
                destinataire=autre_participant,
                type='message',
                titre='Nouveau message',
                message=f"Vous avez reçu un message de {self.request.user.get_full_name()} dans la conversation {conversation.id}.",
                lien=f'/conversations/{conversation.id}'
            )

    @action(detail=False, methods=['get'])
    def non_lus(self, request):
        messages = Message.objects.filter(
            conversation__participants=request.user,
            est_lu=False
        ).exclude(expediteur=request.user)

        serializer = self.get_serializer(messages, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='non_lus/count')
    def count_non_lus(self, request):
        """Retourne le nombre de messages non lus pour l'utilisateur"""
        count = Message.objects.filter(
            conversation__participants=request.user,
            est_lu=False
        ).exclude(expediteur=request.user).count()
        return Response({'count': count})

    @action(detail=True, methods=['post'])
    def marquer_lu(self, request, pk=None):
        message = self.get_object()

        if request.user not in message.conversation.participants.all():
            raise PermissionDenied("Vous n'êtes pas participant à cette conversation.")

        message.est_lu = True
        message.date_lecture = timezone.now()  # 🔥 AJOUT IMPORTANT
        message.save()

        return Response({'message': 'Message marqué comme lu'})

    
    def perform_create(self, serializer):
        message = serializer.save(expediteur=self.request.user)
        
        autre_participant = message.conversation.participants.exclude(
            id=self.request.user.id
        ).first()
        
        if autre_participant:
            # ✅ On crée seulement la notification en base
            Notification.objects.create(
                destinataire=autre_participant,
                type='message',
                titre='Nouveau message',
                message=f"{self.request.user.get_full_name()} vous a envoyé un message",
                lien=f'/conversations/{message.conversation.id}'
            )
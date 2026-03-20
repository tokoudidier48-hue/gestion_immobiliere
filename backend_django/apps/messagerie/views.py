from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q
from .models import Conversation, Message
from .serializers import ConversationSerializer, MessageSerializer, MessageCreateSerializer
from notifications.models import Notification

class ConversationViewSet(viewsets.ModelViewSet):
    queryset = Conversation.objects.all()
    serializer_class = ConversationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Conversation.objects.filter(participants=user)

    def perform_create(self, serializer):
        conversation = serializer.save()
        conversation.participants.add(self.request.user)
        # Le deuxième participant doit être fourni dans la requête
        autre_participant_id = self.request.data.get('autre_participant')
        if autre_participant_id:
            try:
                autre = Utilisateur.objects.get(id=autre_participant_id)
                conversation.participants.add(autre)
            except Utilisateur.DoesNotExist:
                pass


class MessageViewSet(viewsets.ModelViewSet):
    queryset = Message.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        return Message.objects.filter(conversation__participants=user)

    def get_serializer_class(self):
        if self.action == 'create':
            return MessageCreateSerializer
        return MessageSerializer

    def perform_create(self, serializer):
        message = serializer.save(expediteur=self.request.user)
        # Notification à l'autre participant
        conversation = message.conversation
        autre_participant = conversation.participants.exclude(id=self.request.user.id).first()
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

    @action(detail=True, methods=['post'])
    def marquer_lu(self, request, pk=None):
        message = self.get_object()
        if request.user not in message.conversation.participants.all():
            raise PermissionDenied("Vous n'êtes pas participant à cette conversation.")
        message.est_lu = True
        message.save()
        return Response({'message': 'Message marqué comme lu'})
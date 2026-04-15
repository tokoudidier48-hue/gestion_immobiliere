from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from .models import DemandeUnite
from .serializers import DemandeUniteSerializer, DemandeUniteCreateSerializer
from notifications.models import Notification  # Ajout de l'import

class DemandeUniteViewSet(viewsets.ModelViewSet):
    queryset = DemandeUnite.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'locataire':
            return DemandeUnite.objects.filter(locataire=user)
        elif user.role == 'proprietaire':
            return DemandeUnite.objects.filter(proprietaire=user)
        return DemandeUnite.objects.none()

    def get_serializer_class(self):
        if self.action == 'create':
            return DemandeUniteCreateSerializer
        return DemandeUniteSerializer

    def perform_create(self, serializer):
        demande = serializer.save()
        # Notification au propriétaire pour nouvelle demande
        Notification.objects.create(
            destinataire=demande.proprietaire,
            type='demande',
            titre='Nouvelle demande de logement',
            message=f"{demande.locataire.get_full_name()} a fait une demande pour {demande.unite.nom}.",
            lien=f'/demandes/{demande.id}'
        )

    @action(detail=True, methods=['post'])
    def accepter(self, request, pk=None):
        demande = self.get_object()
        if request.user != demande.proprietaire:
            raise PermissionDenied("Vous n'êtes pas autorisé à accepter cette demande.")
        if demande.statut != 'en_attente':
            return Response({'error': 'Cette demande n\'est pas en attente.'}, status=status.HTTP_400_BAD_REQUEST)
        if demande.unite.statut != 'libre':
            return Response({'error': 'L\'unité n\'est plus disponible.'}, status=status.HTTP_400_BAD_REQUEST)

        demande.accepter()
        # Notification au locataire pour acceptation
        Notification.objects.create(
            destinataire=demande.locataire,
            type='reponse_demande',
            titre='Demande acceptée',
            message=f"Votre demande pour {demande.unite.nom} a été acceptée par le propriétaire.",
            lien=f'/demandes/{demande.id}'
        )
        return Response({'message': 'Demande acceptée avec succès.'})

    @action(detail=True, methods=['post'])
    def refuser(self, request, pk=None):
        demande = self.get_object()
        if request.user != demande.proprietaire:
            raise PermissionDenied("Vous n'êtes pas autorisé à refuser cette demande.")
        if demande.statut != 'en_attente':
            return Response({'error': 'Cette demande n\'est pas en attente.'}, status=status.HTTP_400_BAD_REQUEST)

        demande.refuser()
        # Notification au locataire pour refus
        Notification.objects.create(
            destinataire=demande.locataire,
            type='reponse_demande',
            titre='Demande refusée',
            message=f"Votre demande pour {demande.unite.nom} a été refusée par le propriétaire.",
            lien=f'/demandes/{demande.id}'
        )
        return Response({'message': 'Demande refusée.'})

    @action(detail=True, methods=['post'])
    def annuler(self, request, pk=None):
        demande = self.get_object()
        if request.user != demande.locataire:
            raise PermissionDenied("Vous n'êtes pas autorisé à annuler cette demande.")
        if demande.statut != 'en_attente':
            return Response({'error': 'Cette demande n\'est pas en attente.'}, status=status.HTTP_400_BAD_REQUEST)

        demande.annuler()
        return Response({'message': 'Demande annulée.'})
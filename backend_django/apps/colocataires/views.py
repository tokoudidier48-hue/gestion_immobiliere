from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q
from .models import RechercheColocataire, CandidatureColocataire
from .serializers import (
    RechercheColocataireSerializer, RechercheColocataireCreateSerializer,
    CandidatureColocataireSerializer, CandidatureColocataireCreateSerializer
)
from notifications.models import Notification


class RechercheColocataireViewSet(viewsets.ModelViewSet):
    queryset = RechercheColocataire.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        # Seulement les locataires peuvent voir les recherches
        if user.role != 'locataire':
            return RechercheColocataire.objects.none()
        
        # Un locataire voit :
        # - les recherches actives (pour postuler)
        # - ses propres recherches (pour gérer)
        return RechercheColocataire.objects.filter(
            Q(est_active=True) | Q(locataire=user)
        ).distinct()
    
    def get_serializer_class(self):
        if self.action == 'create':
            return RechercheColocataireCreateSerializer
        return RechercheColocataireSerializer
    
    def perform_create(self, serializer):
        recherche = serializer.save()
        # Notification au locataire que sa recherche a été lancée (optionnel)
        # Pas obligatoire selon le cahier des charges
    
    @action(detail=True, methods=['post'])
    def desactiver(self, request, pk=None):
        recherche = self.get_object()
        if request.user != recherche.locataire:
            raise PermissionDenied("Vous n'êtes pas autorisé à désactiver cette recherche.")
        recherche.est_active = False
        recherche.save()
        return Response({'message': 'Recherche désactivée avec succès.'})
    
    @action(detail=True, methods=['get'])
    def candidatures(self, request, pk=None):
        recherche = self.get_object()
        if request.user != recherche.locataire:
            raise PermissionDenied("Vous n'êtes pas autorisé à voir ces candidatures.")
        candidatures = recherche.candidatures.all()
        serializer = CandidatureColocataireSerializer(candidatures, many=True)
        return Response(serializer.data)


class CandidatureColocataireViewSet(viewsets.ModelViewSet):
    queryset = CandidatureColocataire.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        # Seulement les locataires
        if user.role != 'locataire':
            return CandidatureColocataire.objects.none()
        
        # Un locataire voit :
        # - les candidatures qu'il a reçues (pour ses recherches)
        # - les candidatures qu'il a envoyées
        return CandidatureColocataire.objects.filter(
            Q(recherche__locataire=user) | Q(candidat=user)
        ).distinct()
    
    def get_serializer_class(self):
        if self.action == 'create':
            return CandidatureColocataireCreateSerializer
        return CandidatureColocataireSerializer
    
    def perform_create(self, serializer):
        candidature = serializer.save()
        # Notification au locataire qui a lancé la recherche
        Notification.objects.create(
            destinataire=candidature.recherche.locataire,
            type='colocataire',
            titre='Nouvelle candidature',
            message=f"{candidature.candidat.get_full_name()} a postulé à votre recherche de colocataire pour {candidature.recherche.unite.nom}.",
            lien=f'/recherches/{candidature.recherche.id}'
        )
    
    @action(detail=True, methods=['post'])
    def accepter(self, request, pk=None):
        candidature = self.get_object()
        if request.user != candidature.recherche.locataire:
            raise PermissionDenied("Vous n'êtes pas autorisé à accepter cette candidature.")
        
        if candidature.est_acceptee:
            return Response({'error': 'Cette candidature est déjà acceptée.'}, status=status.HTTP_400_BAD_REQUEST)
        
        candidature.accepter()
        
        # Notification au candidat
        Notification.objects.create(
            destinataire=candidature.candidat,
            type='colocataire',
            titre='Candidature acceptée',
            message=f"Votre candidature pour la recherche de colocataire de {candidature.recherche.locataire.get_full_name()} a été acceptée.",
            lien=f'/candidatures/{candidature.id}'
        )
        
        return Response({'message': 'Candidature acceptée avec succès.'})
    
    @action(detail=True, methods=['post'])
    def refuser(self, request, pk=None):
        candidature = self.get_object()
        if request.user != candidature.recherche.locataire:
            raise PermissionDenied("Vous n'êtes pas autorisé à refuser cette candidature.")
        
        candidature.refuser()
        
        # Notification au candidat
        Notification.objects.create(
            destinataire=candidature.candidat,
            type='colocataire',
            titre='Candidature refusée',
            message=f"Votre candidature pour la recherche de colocataire de {candidature.recherche.locataire.get_full_name()} a été refusée.",
            lien=f'/candidatures/{candidature.id}'
        )
        
        return Response({'message': 'Candidature refusée.'})
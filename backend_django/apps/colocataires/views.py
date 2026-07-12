from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.db.models import Q
from django.utils import timezone
from datetime import timedelta
from rest_framework.views import APIView
from django.shortcuts import get_object_or_404

from .models import RechercheColocataire, CandidatureColocataire
from .serializers import (
    RechercheColocataireSerializer, RechercheColocataireCreateSerializer,
    CandidatureColocataireSerializer, CandidatureColocataireCreateSerializer
)
from notifications.models import Notification
from unites.models import Unite


class RechercheColocataireViewSet(viewsets.ModelViewSet):
    queryset = RechercheColocataire.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.role != 'locataire':
            return RechercheColocataire.objects.none()
        
        # Utilise 'statut' au lieu de 'est_active'
        return RechercheColocataire.objects.filter(
            Q(statut='active') | Q(locataire=user)
        ).distinct()
    
    def get_serializer_class(self):
        if self.action == 'create':
            return RechercheColocataireCreateSerializer
        return RechercheColocataireSerializer
    
    def create(self, request, *args, **kwargs):
        """Création d'une recherche avec retour du sérializer complet"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Retourner le sérializer de lecture avec toutes les informations
        instance = serializer.instance
        read_serializer = RechercheColocataireSerializer(instance)
        return Response(read_serializer.data, status=status.HTTP_201_CREATED)
    
    def perform_create(self, serializer):
        serializer.save()
    
    @action(detail=True, methods=['post'])
    def desactiver(self, request, pk=None):
        recherche = self.get_object()
        if request.user != recherche.locataire:
            raise PermissionDenied("Vous n'êtes pas autorisé à désactiver cette recherche.")
        # Utilise la méthode 'annuler' du modèle
        recherche.annuler()
        return Response({'message': 'Recherche désactivée avec succès.'})
    
    @action(detail=True, methods=['get'])
    def candidatures(self, request, pk=None):
        recherche = self.get_object()
        if request.user != recherche.locataire:
            raise PermissionDenied("Vous n'êtes pas autorisé à voir ces candidatures.")
        candidatures = recherche.candidatures.all()
        serializer = CandidatureColocataireSerializer(candidatures, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='statistiques-unite/(?P<unite_id>[0-9]+)')
    def statistiques_unite(self, request, unite_id=None):
        """
        Retourne le nombre de personnes recherchant un colocataire 
        et le nombre de candidats pour une unité spécifique.
        """
        # 1. Compter le nombre de locataires ayant publié une annonce active sur cette unité
        nb_recherches_actives = RechercheColocataire.objects.filter(
            unite_id=unite_id,
            statut='active'
        ).count()

        # 2. Compter le nombre de personnes ayant candidaté à ces recherches actives
        # (On compte les candidatures 'en_attente' et 'acceptee')
        nb_candidats = CandidatureColocataire.objects.filter(
            recherche__unite_id=unite_id,
            recherche__statut='active',
            statut__in=['en_attente', 'acceptee']
        ).distinct().count()

        # Total de personnes engagées sur cette chambre (Auteur de la recherche + Candidats)
        total_personnes_interessees = nb_recherches_actives + nb_candidats

        return Response({
            'unite_id': int(unite_id),
            'nombre_recherches_actives': nb_recherches_actives,
            'nombre_candidatures': nb_candidats,
            'total_locataires_interesses': total_personnes_interessees
        }, status=status.HTTP_200_OK)


class CandidatureColocataireViewSet(viewsets.ModelViewSet):
    queryset = CandidatureColocataire.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        user = self.request.user
        if user.role != 'locataire':
            return CandidatureColocataire.objects.none()
        
        return CandidatureColocataire.objects.filter(
            Q(recherche__locataire=user) | Q(candidat=user)
        ).distinct()
    
    def get_serializer_class(self):
        if self.action == 'create':
            return CandidatureColocataireCreateSerializer
        return CandidatureColocataireSerializer
    
    def create(self, request, *args, **kwargs):
        """Création d'une candidature avec retour du sérializer complet"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        # Retourner le sérializer de lecture avec toutes les informations
        instance = serializer.instance
        read_serializer = CandidatureColocataireSerializer(instance)
        return Response(read_serializer.data, status=status.HTTP_201_CREATED)
    
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
        
        # Utilise la méthode 'accepter' du modèle
        if candidature.statut == 'acceptee':
            return Response({'error': 'Cette candidature est déjà acceptée.'}, status=status.HTTP_400_BAD_REQUEST)
        
        candidature.accepter()
        
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
        
        Notification.objects.create(
            destinataire=candidature.candidat,
            type='colocataire',
            titre='Candidature refusée',
            message=f"Votre candidature pour la recherche de colocataire de {candidature.recherche.locataire.get_full_name()} a été refusée.",
            lien=f'/candidatures/{candidature.id}'
        )
        
        return Response({'message': 'Candidature refusée.'})


# =========================================================
# CRÉATION DE RECHERCHE (APIView corrigée)
# =========================================================

class CreerRechercheView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    
    def _count_active_searches(self, locataire):
        """Compte les recherches actives (statut='active')"""
        return RechercheColocataire.objects.filter(
            locataire=locataire,
            statut='active'
        ).count()
    
    def post(self, request):
        locataire = request.user
        
        # Vérifier que l'utilisateur est un locataire
        if locataire.role != 'locataire':
            return Response({
                'error': 'Seuls les locataires peuvent créer une recherche de colocataire.'
            }, status=status.HTTP_403_FORBIDDEN)
        
        # 1. Vérifier limite de 3 recherches actives
        if self._count_active_searches(locataire) >= 3:
            return Response({
                'error': 'Vous avez atteint la limite maximale de 3 recherches de colocataire.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # 2. Récupérer et vérifier l'unité
        unite_id = request.data.get('unite')
        if not unite_id:
            return Response({'error': 'L\'unité est requise.'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            unite = Unite.objects.get(id=unite_id)
        except Unite.DoesNotExist:
            return Response({'error': 'Unité non trouvée.'}, status=status.HTTP_404_NOT_FOUND)
        
        if unite.statut != 'libre':
            return Response({'error': 'Cette unité n\'est pas disponible.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # 3. Créer la recherche avec les données du profil (sans passer 'unite' deux fois)
        recherche = RechercheColocataire.objects.create(
            locataire=locataire,
            unite=unite,
            filiere=getattr(locataire, 'filiere', ''),
            ville=getattr(locataire, 'ville', ''),
            religion=getattr(locataire, 'religion', ''),
            telephone=getattr(locataire, 'telephone_coloc', ''),
            description=getattr(locataire, 'description_coloc', ''),
            date_expiration=timezone.now() + timedelta(days=15)
        )
        
        # Utiliser le sérializer pour la réponse
        from .serializers import RechercheColocataireSerializer
        serializer = RechercheColocataireSerializer(recherche)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
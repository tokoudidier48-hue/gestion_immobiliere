from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django_filters.rest_framework import DjangoFilterBackend
from .models import Locataire
from .serializers import LocataireSerializer, LocataireCreateUpdateSerializer

class LocataireViewSet(viewsets.ModelViewSet):
    queryset = Locataire.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['propriete', 'unite', 'mode_paiement']
    search_fields = ['utilisateur__first_name', 'utilisateur__last_name', 'utilisateur__email']
    ordering_fields = ['date_entree', 'date_creation']
    
    def get_queryset(self):
        user = self.request.user
        if user.role == 'proprietaire':
            # Le propriétaire voit les locataires de ses propriétés
            return Locataire.objects.filter(propriete__proprietaire=user)
        elif user.role == 'locataire':
            # Le locataire ne voit que lui-même
            return Locataire.objects.filter(utilisateur=user)
        return Locataire.objects.none()
    
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return LocataireCreateUpdateSerializer
        return LocataireSerializer
    
    def perform_create(self, serializer):
        serializer.save()
    
    def perform_update(self, serializer):
        locataire = self.get_object()
        # Vérifier que le propriétaire a le droit de modifier
        if self.request.user.role == 'proprietaire' and locataire.propriete.proprietaire != self.request.user:
            raise PermissionDenied("Vous n'êtes pas autorisé à modifier ce locataire.")
        serializer.save()
    
    def perform_destroy(self, instance):
        # Vérifier que le propriétaire a le droit de supprimer
        if self.request.user.role == 'proprietaire' and instance.propriete.proprietaire != self.request.user:
            raise PermissionDenied("Vous n'êtes pas autorisé à supprimer ce locataire.")
        instance.delete()
    
    @action(detail=False, methods=['get'])
    def mes_locataires(self, request):
        """Pour un propriétaire : liste de ses locataires"""
        if request.user.role != 'proprietaire':
            raise PermissionDenied("Seuls les propriétaires ont accès à cette liste.")
        locataires = Locataire.objects.filter(propriete__proprietaire=request.user)
        serializer = self.get_serializer(locataires, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def paiements(self, request, pk=None):
        """Voir l'historique des paiements d'un locataire"""
        locataire = self.get_object()
        if request.user.role == 'proprietaire' and locataire.propriete.proprietaire != request.user:
            raise PermissionDenied("Vous n'êtes pas autorisé à voir ces paiements.")
        if request.user.role == 'locataire' and request.user != locataire.utilisateur:
            raise PermissionDenied("Vous n'êtes pas autorisé à voir ces paiements.")
        
        paiements = locataire.utilisateur.paiements_effectues.all()
        from paiements.serializers import PaiementSerializer
        serializer = PaiementSerializer(paiements, many=True)
        return Response(serializer.data)
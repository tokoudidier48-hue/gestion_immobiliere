from rest_framework import viewsets, permissions, filters
from rest_framework.exceptions import PermissionDenied
from .models import Propriete
from .serializers import ProprieteSerializer

class ProprieteViewSet(viewsets.ModelViewSet):
    serializer_class = ProprieteSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['nom']
    ordering_fields = ['date_creation', 'nom']

    def get_queryset(self):
        user = self.request.user
        # Seuls les propriétaires peuvent voir leurs propriétés
        if user.role == 'proprietaire':
            return Propriete.objects.filter(proprietaire=user)
        # Les locataires ne voient rien (ou peuvent-ils voir les propriétés ? Selon le cahier, non)
        return Propriete.objects.none()

    def perform_create(self, serializer):
        user = self.request.user
        if user.role != 'proprietaire':
            raise PermissionDenied("Seuls les propriétaires peuvent créer une propriété.")
        serializer.save(proprietaire=user)
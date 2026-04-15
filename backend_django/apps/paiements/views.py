from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from .models import Paiement, Recu
from .serializers import PaiementSerializer, PaiementCreateSerializer, RecuSerializer
from notifications.models import Notification  # Ajout de l'import

class PaiementViewSet(viewsets.ModelViewSet):
    queryset = Paiement.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'locataire':
            return Paiement.objects.filter(locataire=user)
        elif user.role == 'proprietaire':
            return Paiement.objects.filter(proprietaire=user)
        return Paiement.objects.none()

    def get_serializer_class(self):
        if self.action == 'create':
            return PaiementCreateSerializer
        return PaiementSerializer

    def perform_create(self, serializer):
        paiement = serializer.save()
        # Notification au propriétaire pour paiement reçu
        Notification.objects.create(
            destinataire=paiement.proprietaire,
            type='paiement',
            titre='Nouveau paiement reçu',
            message=f"{paiement.locataire.get_full_name()} a effectué un paiement de {paiement.montant} FCFA pour {paiement.unite.nom}.",
            lien=f'/paiements/{paiement.id}'
        )

    @action(detail=True, methods=['get'])
    def recu(self, request, pk=None):
        paiement = self.get_object()
        try:
            recu = paiement.recu
            recu.nombre_telechargements += 1
            recu.save()
            serializer = RecuSerializer(recu)
            return Response(serializer.data)
        except Recu.DoesNotExist:
            return Response({'error': 'Reçu non trouvé'}, status=status.HTTP_404_NOT_FOUND)


class RecuViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Recu.objects.all()
    serializer_class = RecuSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'locataire':
            return Recu.objects.filter(paiement__locataire=user)
        elif user.role == 'proprietaire':
            return Recu.objects.filter(paiement__proprietaire=user)
        return Recu.objects.none()

    @action(detail=True, methods=['post'])
    def telecharger(self, request, pk=None):
        recu = self.get_object()
        recu.nombre_telechargements += 1
        recu.save()
        # En pratique, on renverrait le fichier PDF
        return Response({'message': 'Téléchargement comptabilisé', 'url': recu.fichier_pdf.url if recu.fichier_pdf else None})
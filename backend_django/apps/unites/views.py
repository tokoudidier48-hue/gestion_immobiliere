from rest_framework import viewsets, permissions, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from django.db import transaction

from .models import Unite, PhotoUnite
from .serializers import UniteSerializer, UniteCreateUpdateSerializer


class UniteViewSet(viewsets.ModelViewSet):
    queryset = Unite.objects.all()
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['nom', 'adresse', 'ville', 'description']
    ordering_fields = ['loyer', 'date_creation', 'nom']

    # 🔹 QUERYSET
    def get_queryset(self):
        queryset = Unite.objects.all()

        statut = self.request.query_params.get('statut')
        if statut:
            queryset = queryset.filter(statut=statut)

        type_unite = self.request.query_params.get('type')
        if type_unite:
            queryset = queryset.filter(type_unite=type_unite)

        ville = self.request.query_params.get('ville')
        if ville:
            queryset = queryset.filter(ville__icontains=ville)

        prix_min = self.request.query_params.get('prix_min')
        if prix_min:
            queryset = queryset.filter(loyer__gte=prix_min)

        prix_max = self.request.query_params.get('prix_max')
        if prix_max:
            queryset = queryset.filter(loyer__lte=prix_max)

        if self.request.user.role == 'proprietaire':
            queryset = queryset.filter(proprietaire=self.request.user)

        return queryset.distinct()

    # 🔹 SERIALIZER
    def get_serializer_class(self):
        if self.action in ['create', 'update', 'partial_update']:
            return UniteCreateUpdateSerializer
        return UniteSerializer

    # 🔹 CREATE SIMPLE (SANS PHOTO)
    def perform_create(self, serializer):
        if self.request.user.role != 'proprietaire':
            raise PermissionDenied("Seuls les propriétaires peuvent créer des unités.")
        serializer.save(proprietaire=self.request.user)

    # 🔹 UPDATE
    def perform_update(self, serializer):
        unite = self.get_object()
        if self.request.user.role != 'proprietaire' or unite.proprietaire != self.request.user:
            raise PermissionDenied("Vous n'êtes pas autorisé à modifier cette unité.")
        serializer.save()

    # 🔹 DELETE
    def perform_destroy(self, instance):
        if self.request.user.role != 'proprietaire' or instance.proprietaire != self.request.user:
            raise PermissionDenied("Vous n'êtes pas autorisé à supprimer cette unité.")
        instance.delete()

    # 🔥🔥🔥 NOUVEAU ENDPOINT PRO 🔥🔥🔥
    @action(detail=False, methods=['post'], url_path='create-with-photos')
    @transaction.atomic
    def create_with_photos(self, request):
        if request.user.role != 'proprietaire':
            raise PermissionDenied("Seuls les propriétaires peuvent créer des unités.")

        data = request.data

        # 🔹 Validation via serializer
        serializer = UniteCreateUpdateSerializer(data=data, context={'request': request})
        serializer.is_valid(raise_exception=True)

        unite = serializer.save(proprietaire=request.user)

        # 🔹 Récupérer images
        images = request.FILES.getlist('photos')

        # 🔥 Limite max 7 images
        if len(images) > 7:
            return Response(
                {"error": "Vous pouvez ajouter максимум 7 photos."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 🔹 Création des photos
        for index, image in enumerate(images):
            PhotoUnite.objects.create(
                unite=unite,
                image=image,
                ordre=index,
                est_principale=(index == 0)
            )

        return Response({
            "message": "Unité créée avec photos",
            "unite_id": unite.id
        }, status=status.HTTP_201_CREATED)

    # 🔹 CHANGER STATUT
    @action(detail=True, methods=['post'])
    def changer_statut(self, request, pk=None):
        unite = self.get_object()
        if request.user.role != 'proprietaire' or unite.proprietaire != request.user:
            raise PermissionDenied("Action non autorisée.")

        nouveau_statut = request.data.get('statut')

        if nouveau_statut in dict(Unite.STATUT_CHOIX):
            unite.statut = nouveau_statut
            unite.save()
            return Response({'message': f'Statut changé en {nouveau_statut}'})

        return Response({'error': 'Statut invalide'}, status=status.HTTP_400_BAD_REQUEST)

    # 🔹 MES UNITES
    @action(detail=False, methods=['get'])
    def mes_unites(self, request):
        if request.user.role != 'proprietaire':
            raise PermissionDenied("Seuls les propriétaires ont accès à leurs unités.")

        unites = Unite.objects.filter(proprietaire=request.user)
        serializer = self.get_serializer(unites, many=True)
        return Response(serializer.data)

    # 🔹 UNITES DISPONIBLES
    @action(detail=False, methods=['get'])
    def disponibles(self, request):
        unites = Unite.objects.filter(statut='libre')
        serializer = self.get_serializer(unites, many=True)
        return Response(serializer.data)
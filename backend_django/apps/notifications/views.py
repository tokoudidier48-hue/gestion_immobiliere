from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Notification
from .serializers import NotificationSerializer

class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Un utilisateur ne voit que ses propres notifications
        return Notification.objects.filter(destinataire=self.request.user)

    @action(detail=True, methods=['post'])
    def marquer_lue(self, request, pk=None):
        notification = self.get_object()
        notification.est_lue = True
        notification.save()
        return Response({'status': 'notification marquée comme lue'})

    @action(detail=False, methods=['post'])
    def tout_marquer_lue(self, request):
        self.get_queryset().update(est_lue=True)
        return Response({'status': 'toutes les notifications marquées comme lues'})

    @action(detail=False, methods=['get'])
    def non_lues(self, request):
        queryset = self.get_queryset().filter(est_lue=False)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def count_non_lues(self, request):
        count = self.get_queryset().filter(est_lue=False).count()
        return Response({'count': count})
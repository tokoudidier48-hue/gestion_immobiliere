from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Notification
from .serializers import NotificationSerializer
from .fcm_service import notify_user
from comptes.models import Utilisateur


class NotificationViewSet(viewsets.ModelViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
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

    # 🔥 VERSION CORRIGÉE DU TEST PUSH
    @action(detail=False, methods=['post'], url_path='test-push')
    def test_push(self, request):
        """Endpoint de test pour envoyer une notification push"""

        print("==> test_push appelé")

        user_id = request.data.get('user_id')
        titre = request.data.get('titre', 'Test Notification')
        message = request.data.get('message', 'Ceci est un test')

        # Vérification user_id
        if not user_id:
            return Response(
                {'error': 'user_id requis'},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = Utilisateur.objects.get(id=user_id)

            print(f"==> Utilisateur trouvé : {user.email}")

            # Vérifier token
            if not hasattr(user, 'fcm_token'):
                return Response({
                    'success': False,
                    'message': 'Utilisateur sans token FCM'
                }, status=status.HTTP_404_NOT_FOUND)

            print(f"==> Token trouvé : {user.fcm_token.token}")

            success = notify_user(
                user,
                titre,
                message,
                donnees={'type': 'test'}
            )

            if success:
                return Response({
                    'success': True,
                    'message': f'Notification envoyée à {user.email}',
                    'user_id': user_id
                }, status=status.HTTP_200_OK)
            else:
                return Response({
                    'success': False,
                    'message': 'Échec envoi (token invalide ou Firebase)'
                }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        except Utilisateur.DoesNotExist:
            return Response(
                {'error': 'Utilisateur non trouvé'},
                status=status.HTTP_404_NOT_FOUND
            )
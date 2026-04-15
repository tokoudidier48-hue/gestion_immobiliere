from rest_framework import serializers
from .models import Notification

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'type', 'titre', 'message', 'lien', 'est_lue', 'date_creation']
        read_only_fields = ['date_creation']
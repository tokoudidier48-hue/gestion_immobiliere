from django.contrib import admin
from .models import Notification

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('id', 'destinataire', 'type', 'titre', 'est_lue', 'date_creation')
    list_filter = ('type', 'est_lue', 'date_creation')
    search_fields = ('destinataire__email', 'titre', 'message')
    raw_id_fields = ('destinataire',)
    readonly_fields = ('date_creation',)
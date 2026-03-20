from django.contrib import admin
from .models import DemandeUnite

@admin.register(DemandeUnite)
class DemandeUniteAdmin(admin.ModelAdmin):
    list_display = ('id', 'locataire', 'proprietaire', 'unite', 'statut', 'date_demande', 'date_reponse')
    list_filter = ('statut', 'date_demande')
    search_fields = ('locataire__email', 'proprietaire__email', 'unite__nom')
    raw_id_fields = ('locataire', 'proprietaire', 'unite')
    readonly_fields = ('date_demande', 'date_reponse')
    fieldsets = (
        ('Relations', {'fields': ('locataire', 'proprietaire', 'unite')}),
        ('Informations', {'fields': ('message', 'statut')}),
        ('Dates', {'fields': ('date_demande', 'date_reponse')}),
    )
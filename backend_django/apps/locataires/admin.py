from django.contrib import admin
from .models import Locataire

@admin.register(Locataire)
class LocataireAdmin(admin.ModelAdmin):
    list_display = ('utilisateur', 'unite', 'propriete', 'date_entree', 'mode_paiement', 'date_creation')
    list_filter = ('mode_paiement', 'date_entree')
    search_fields = ('utilisateur__first_name', 'utilisateur__last_name', 'utilisateur__email')
    raw_id_fields = ('utilisateur', 'unite', 'propriete')
    readonly_fields = ('date_creation', 'date_modification')
    
    fieldsets = (
        ('Compte utilisateur', {
            'fields': ('utilisateur',)
        }),
        ('Informations de location', {
            'fields': ('unite', 'propriete', 'date_entree')
        }),
        ('Paiement', {
            'fields': ('mode_paiement',)
        }),
        ('Métadonnées', {
            'fields': ('date_creation', 'date_modification'),
            'classes': ('collapse',)
        }),
    )
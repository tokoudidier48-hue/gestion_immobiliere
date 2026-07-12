from django.contrib import admin
from .models import Locataire

@admin.register(Locataire)
class LocataireAdmin(admin.ModelAdmin):
    list_display = ('id', 'utilisateur', 'propriete', 'unite', 'date_entree', 'mode_paiement', 'est_actif', 'date_creation')
    list_filter = ('mode_paiement', 'date_entree', 'est_actif', 'propriete')
    search_fields = ('utilisateur__first_name', 'utilisateur__last_name', 'utilisateur__email', 'propriete__nom')
    raw_id_fields = ('utilisateur', 'unite', 'propriete')
    readonly_fields = ('date_creation', 'date_modification')
    
    fieldsets = (
        ('Compte utilisateur', {
            'fields': ('utilisateur',)
        }),
        ('Informations de location', {
            'fields': ('propriete', 'unite', 'date_entree')
        }),
        ('Statut et paiement', {
            'fields': ('est_actif', 'mode_paiement')
        }),
        ('Métadonnées', {
            'fields': ('date_creation', 'date_modification'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        return super().get_queryset(request).select_related('utilisateur', 'propriete', 'unite')
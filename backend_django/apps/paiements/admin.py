from django.contrib import admin
from django.utils.html import format_html
from .models import Paiement, Recu

class RecuInline(admin.StackedInline):
    model = Recu
    can_delete = False
    readonly_fields = ('numero_recu', 'contenu', 'date_generation', 'nombre_telechargements')

@admin.register(Paiement)
class PaiementAdmin(admin.ModelAdmin):
    list_display = ('id', 'locataire', 'proprietaire', 'unite', 'type_paiement', 'montant', 'mode_paiement', 'statut', 'date_paiement')
    list_filter = ('type_paiement', 'mode_paiement', 'statut', 'date_paiement')
    search_fields = ('locataire__email', 'proprietaire__email', 'unite__nom', 'numero_paiement')
    raw_id_fields = ('locataire', 'proprietaire', 'unite', 'demande')
    readonly_fields = ('date_paiement', 'date_confirmation')
    inlines = [RecuInline]
    fieldsets = (
        ('Relations', {'fields': ('locataire', 'proprietaire', 'unite', 'demande')}),
        ('Informations de paiement', {'fields': ('type_paiement', 'mode_paiement', 'montant', 'numero_paiement', 'statut')}),
        ('Période concernée', {'fields': ('periode_debut', 'periode_fin')}),
        ('Dates', {'fields': ('date_paiement', 'date_confirmation')}),
    )
    actions = ['confirmer_paiements']

    def confirmer_paiements(self, request, queryset):
        for paiement in queryset:
            paiement.confirmer()
        self.message_user(request, f"{queryset.count()} paiement(s) confirmé(s)")
    confirmer_paiements.short_description = "Confirmer les paiements sélectionnés"


@admin.register(Recu)
class RecuAdmin(admin.ModelAdmin):
    list_display = ('numero_recu', 'paiement', 'date_generation', 'nombre_telechargements')
    list_filter = ('date_generation',)
    search_fields = ('numero_recu', 'paiement__locataire__email')
    readonly_fields = ('numero_recu', 'contenu', 'date_generation', 'nombre_telechargements')
    raw_id_fields = ('paiement',)
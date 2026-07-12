from django.contrib import admin
from django.utils.html import format_html
from .models import RechercheColocataire, CandidatureColocataire


class CandidatureInline(admin.TabularInline):
    model = CandidatureColocataire
    extra = 0
    readonly_fields = ('date_candidature', 'date_reponse')
    raw_id_fields = ('candidat',)
    fields = ('candidat', 'statut', 'filiere', 'ville', 'telephone', 'date_candidature', 'date_reponse')


@admin.register(RechercheColocataire)
class RechercheColocataireAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'locataire',
        'unite',
        'ville',
        'filiere',
        'statut_badge',
        'date_creation',
        'date_expiration',
    )
    list_filter = ('statut', 'ville', 'date_creation')  # ← 'statut' au lieu de 'est_active'
    search_fields = ('locataire__email', 'locataire__first_name', 'locataire__last_name', 'unite__nom', 'filiere', 'ville')
    raw_id_fields = ('locataire', 'unite')
    readonly_fields = ('date_creation', 'date_modification')
    inlines = [CandidatureInline]
    actions = ['expirer_recherches', 'annuler_recherches']
    
    def statut_badge(self, obj):
        """Affiche un badge coloré pour le statut."""
        badges = {
            'active': '🟢 Active',
            'annulee': '🔴 Annulée',
            'expiree': '⚫ Expirée',
            'terminee': '🔵 Terminée',
        }
        return badges.get(obj.statut, obj.statut)
    
    statut_badge.short_description = 'Statut'
    
    def expirer_recherches(self, request, queryset):
        """Expire les recherches sélectionnées."""
        count = 0
        for recherche in queryset:
            if recherche.expirer():
                count += 1
        self.message_user(request, f"{count} recherche(s) expirée(s).")
    expirer_recherches.short_description = "Expirer les recherches sélectionnées"
    
    def annuler_recherches(self, request, queryset):
        """Annule les recherches sélectionnées."""
        count = 0
        for recherche in queryset:
            if recherche.annuler():
                count += 1
        self.message_user(request, f"{count} recherche(s) annulée(s).")
    annuler_recherches.short_description = "Annuler les recherches sélectionnées"


@admin.register(CandidatureColocataire)
class CandidatureColocataireAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'candidat',
        'recherche',
        'statut_badge',
        'date_candidature',
        'date_reponse',
    )
    list_filter = ('statut', 'date_candidature')  # ← 'statut' au lieu de 'est_acceptee'
    search_fields = ('candidat__email', 'candidat__first_name', 'candidat__last_name', 'recherche__locataire__email')
    raw_id_fields = ('candidat', 'recherche')
    readonly_fields = ('date_candidature', 'date_reponse')
    actions = ['accepter_candidatures', 'refuser_candidatures']
    
    def statut_badge(self, obj):
        """Affiche un badge coloré pour le statut."""
        badges = {
            'en_attente': '🟡 En attente',
            'acceptee': '🟢 Acceptée',
            'refusee': '🔴 Refusée',
        }
        return badges.get(obj.statut, obj.statut)
    
    statut_badge.short_description = 'Statut'
    
    def accepter_candidatures(self, request, queryset):
        """Accepte les candidatures sélectionnées."""
        count = 0
        for candidature in queryset:
            candidature.accepter()
            count += 1
        self.message_user(request, f"{count} candidature(s) acceptée(s).")
    accepter_candidatures.short_description = "Accepter les candidatures sélectionnées"
    
    def refuser_candidatures(self, request, queryset):
        """Refuse les candidatures sélectionnées."""
        count = 0
        for candidature in queryset:
            candidature.refuser()
            count += 1
        self.message_user(request, f"{count} candidature(s) refusée(s).")
    refuser_candidatures.short_description = "Refuser les candidatures sélectionnées"
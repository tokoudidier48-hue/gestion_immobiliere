from django.contrib import admin
from .models import RechercheColocataire, CandidatureColocataire

class CandidatureInline(admin.TabularInline):
    model = CandidatureColocataire
    extra = 0
    readonly_fields = ('date_candidature', 'date_reponse')
    raw_id_fields = ('candidat',)

@admin.register(RechercheColocataire)
class RechercheColocataireAdmin(admin.ModelAdmin):
    list_display = ('id', 'locataire', 'unite', 'ville', 'filiere', 'est_active', 'date_creation')
    list_filter = ('est_active', 'ville', 'date_creation')
    search_fields = ('locataire__email', 'unite__nom', 'filiere', 'ville')
    raw_id_fields = ('locataire', 'unite')
    inlines = [CandidatureInline]

@admin.register(CandidatureColocataire)
class CandidatureColocataireAdmin(admin.ModelAdmin):
    list_display = ('id', 'candidat', 'recherche', 'est_acceptee', 'date_candidature', 'date_reponse')
    list_filter = ('est_acceptee', 'date_candidature')
    search_fields = ('candidat__email', 'recherche__locataire__email')
    raw_id_fields = ('candidat', 'recherche')
    readonly_fields = ('date_candidature', 'date_reponse')
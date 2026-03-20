from django.contrib import admin
from django.utils.html import format_html
from .models import Unite, PhotoUnite

class PhotoUniteInline(admin.TabularInline):
    model = PhotoUnite
    extra = 3
    max_num = 7
    readonly_fields = ('apercu',)

    def apercu(self, obj):
        if obj.id and obj.image:
            return format_html('<img src="{}" width="50" height="50" style="object-fit: cover;" />', obj.image.url)
        return "Pas d'image"
    apercu.short_description = "Aperçu"

@admin.register(Unite)
class UniteAdmin(admin.ModelAdmin):
    list_display = ('nom', 'type_unite', 'proprietaire', 'propriete', 'loyer', 'statut', 'ville', 'date_creation')
    list_filter = ('type_unite', 'statut', 'ville', 'prepaye', 'garage')
    search_fields = ('nom', 'adresse', 'proprietaire__email')
    raw_id_fields = ('proprietaire', 'propriete')
    inlines = [PhotoUniteInline]
    fieldsets = (
        ('Relations', {'fields': ('proprietaire', 'propriete')}),
        ('Informations de base', {'fields': ('nom', 'type_unite', 'description')}),
        ('Localisation', {'fields': ('adresse', 'ville')}),
        ('Caractéristiques', {'fields': ('type_douche', 'prepaye', 'garage')}),
        ('Financier', {'fields': ('loyer', 'nombre_avances', 'type_caution', 'prix_caution')}),
        ('Contact', {'fields': ('contact_proprietaire',)}),
        ('Statut', {'fields': ('statut',)}),
    )

@admin.register(PhotoUnite)
class PhotoUniteAdmin(admin.ModelAdmin):
    list_display = ('id', 'unite', 'est_principale', 'ordre', 'date_upload')
    list_filter = ('est_principale',)
    raw_id_fields = ('unite',)
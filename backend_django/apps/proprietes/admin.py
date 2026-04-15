from django.contrib import admin
from .models import Propriete

@admin.register(Propriete)
class ProprieteAdmin(admin.ModelAdmin):
    list_display = ('nom', 'proprietaire', 'date_creation')
    list_filter = ('date_creation',)
    search_fields = ('nom', 'proprietaire__email', 'proprietaire__first_name')
    raw_id_fields = ('proprietaire',)
    readonly_fields = ('date_creation', 'date_modification')
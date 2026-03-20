from django.contrib import admin
from .models import ConversationIA, MessageIA, RecommandationIA

class MessageIAInline(admin.TabularInline):
    model = MessageIA
    extra = 0
    readonly_fields = ('date_envoi',)

@admin.register(ConversationIA)
class ConversationIAAdmin(admin.ModelAdmin):
    list_display = ('id', 'locataire', 'date_debut', 'date_dernier_message', 'est_active')
    list_filter = ('est_active', 'date_debut')
    search_fields = ('locataire__email', 'locataire__first_name', 'locataire__last_name')
    raw_id_fields = ('locataire',)
    inlines = [MessageIAInline]

@admin.register(MessageIA)
class MessageIAAdmin(admin.ModelAdmin):
    list_display = ('id', 'conversation', 'type_expediteur', 'type_message', 'date_envoi')
    list_filter = ('type_expediteur', 'type_message', 'date_envoi')
    search_fields = ('conversation__locataire__email', 'contenu')

@admin.register(RecommandationIA)
class RecommandationIAAdmin(admin.ModelAdmin):
    list_display = ('id', 'conversation', 'date_recommandation')
    list_filter = ('date_recommandation',)
    filter_horizontal = ('unites',)
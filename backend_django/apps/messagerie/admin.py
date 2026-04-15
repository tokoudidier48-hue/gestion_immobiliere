from django.contrib import admin
from .models import Conversation, Message

class MessageInline(admin.TabularInline):
    model = Message
    extra = 0
    readonly_fields = ('date_envoi', 'date_lecture')
    raw_id_fields = ('expediteur',)

@admin.register(Conversation)
class ConversationAdmin(admin.ModelAdmin):
    list_display = ('id', 'date_creation', 'date_dernier_message', 'nombre_participants')
    filter_horizontal = ('participants',)
    raw_id_fields = ('unite',)
    inlines = [MessageInline]

    def nombre_participants(self, obj):
        return obj.participants.count()
    nombre_participants.short_description = "Participants"

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'expediteur', 'conversation', 'est_lu', 'date_envoi')
    list_filter = ('est_lu', 'date_envoi')
    search_fields = ('expediteur__email', 'contenu')
    raw_id_fields = ('expediteur', 'conversation')
    readonly_fields = ('date_envoi', 'date_lecture')
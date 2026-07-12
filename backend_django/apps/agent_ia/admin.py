# apps/agent_ia/admin.py

from django.contrib import admin
from django.utils.html import format_html

from .models import ConversationIA, MessageIA, RecommandationIA


# =========================================================
# INLINE MESSAGES (limité pour les performances)
# =========================================================

class MessageIAInline(admin.TabularInline):
    model = MessageIA
    extra = 0
    max_num = 20                          # Limite affichage
    readonly_fields = (
        "type_expediteur",
        "contenu_court",
        "type_message",
        "date_envoi",
    )
    fields = (
        "type_expediteur",
        "contenu_court",
        "type_message",
        "date_envoi",
    )
    ordering = ("-date_envoi",)
    can_delete = False

    def contenu_court(self, obj):
        """Affiche seulement les 80 premiers caractères."""
        return obj.contenu[:80] + ("…" if len(obj.contenu) > 80 else "")

    contenu_court.short_description = "Message"

    def has_add_permission(self, request, obj=None):
        return False


# =========================================================
# CONVERSATION IA
# =========================================================

@admin.register(ConversationIA)
class ConversationIAAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "locataire",
        "nombre_messages",
        "date_debut",
        "date_dernier_message",
        "statut_badge",
    )
    list_filter = ("est_active", "date_debut")
    search_fields = (
        "locataire__email",
        "locataire__first_name",
        "locataire__last_name",
    )
    raw_id_fields = ("locataire",)
    readonly_fields = ("date_debut", "date_dernier_message")
    inlines = [MessageIAInline]

    # Actions admin
    actions = ["desactiver_conversations", "rebuild_faiss"]

    def get_queryset(self, request):
        """Optimise avec annotation pour nombre_messages."""
        from django.db.models import Count
        return (
            super()
            .get_queryset(request)
            .annotate(_nombre_messages=Count("messages"))
        )

    def nombre_messages(self, obj) -> int:
        return getattr(obj, "_nombre_messages", obj.messages.count())

    nombre_messages.short_description = "Messages"
    nombre_messages.admin_order_field = "_nombre_messages"

    def statut_badge(self, obj):
        if obj.est_active:
            return format_html(
                '<span style="color:green;font-weight:bold;">● Active</span>'
            )
        return format_html(
            '<span style="color:gray;">● Inactive</span>'
        )

    statut_badge.short_description = "Statut"

    @admin.action(description="Désactiver les conversations sélectionnées")
    def desactiver_conversations(self, request, queryset):
        updated = queryset.update(est_active=False)
        self.message_user(request, f"{updated} conversation(s) désactivée(s).")

    @admin.action(description="🔄 Reconstruire la base vectorielle FAISS")
    def rebuild_faiss(self, request, queryset):
        """
        Rebuild FAISS depuis l'admin.
        Utile après suppression de logements.
        """
        try:
            from .services.vector_service import rebuild_vectorstore
            rebuild_vectorstore()
            self.message_user(
                request,
                "✅ Base vectorielle FAISS reconstruite avec succès."
            )
        except Exception as e:
            self.message_user(
                request,
                f"❌ Erreur rebuild FAISS : {e}",
                level="error",
            )


# =========================================================
# MESSAGE IA
# =========================================================

@admin.register(MessageIA)
class MessageIAAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "conversation",
        "expediteur_badge",
        "contenu_court",
        "type_message",
        "date_envoi",
    )
    list_filter = ("type_expediteur", "type_message", "date_envoi")
    search_fields = (
        "conversation__locataire__email",
        "contenu",
    )
    readonly_fields = ("date_envoi",)
    ordering = ("-date_envoi",)

    def contenu_court(self, obj) -> str:
        return obj.contenu[:80] + ("…" if len(obj.contenu) > 80 else "")

    contenu_court.short_description = "Message"

    def expediteur_badge(self, obj):
        if obj.type_expediteur == "ia":
            return format_html(
                '<span style="color:#1976D2;font-weight:bold;">🤖 Loya</span>'
            )
        return format_html(
            '<span style="color:#388E3C;">👤 Locataire</span>'
        )

    expediteur_badge.short_description = "Expéditeur"


# =========================================================
# RECOMMANDATION IA
# =========================================================

@admin.register(RecommandationIA)
class RecommandationIAAdmin(admin.ModelAdmin):

    list_display = (
        "id",
        "conversation",
        "nombre_unites",
        "date_recommandation",
    )
    list_filter = ("date_recommandation",)
    filter_horizontal = ("unites",)
    readonly_fields = ("date_recommandation",)

    def nombre_unites(self, obj) -> int:
        return obj.unites.count()

    nombre_unites.short_description = "Logements proposés"
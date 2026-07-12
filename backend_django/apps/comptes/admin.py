from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Utilisateur, CodeOTP, SessionActive, FCMToken

class UtilisateurAdmin(UserAdmin):
    list_display = ('email', 'first_name', 'last_name', 'telephone', 'role', 'est_actif', 'derniere_connexion')
    list_filter = ('role', 'est_actif')
    search_fields = ('email', 'first_name', 'last_name', 'telephone')
    ordering = ('email',)
    
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Informations personnelles', {'fields': ('first_name', 'last_name', 'telephone', 'photo_profil')}),
        ('Rôle et permissions', {'fields': ('role', 'is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')}),
        ('Dates importantes', {'fields': ('last_login', 'date_joined', 'derniere_connexion')}),
    )
    
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'first_name', 'last_name', 'telephone', 'password1', 'password2', 'role'),
        }),
    )


@admin.register(CodeOTP)
class CodeOTPAdmin(admin.ModelAdmin):
    list_display = ('utilisateur', 'code', 'date_creation', 'est_utilise', 'est_valide')
    list_filter = ('est_utilise', 'date_creation')
    search_fields = ('utilisateur__email', 'code')
    readonly_fields = ('date_creation',)
    
    def est_valide(self, obj):
        return obj.est_valide()
    est_valide.boolean = True
    est_valide.short_description = "Valide"


@admin.register(SessionActive)
class SessionActiveAdmin(admin.ModelAdmin):
    list_display = ('utilisateur', 'date_connexion', 'date_expiration', 'ip_adresse', 'est_active', 'est_expiree')
    list_filter = ('est_active', 'date_connexion')
    search_fields = ('utilisateur__email', 'ip_adresse', 'user_agent')
    readonly_fields = ('date_connexion', 'date_expiration', 'token', 'refresh_token')
    
    def est_expiree(self, obj):
        from django.utils import timezone
        return obj.date_expiration < timezone.now()
    est_expiree.boolean = True
    est_expiree.short_description = "Expirée"
    
    fieldsets = (
        ('Utilisateur', {'fields': ('utilisateur',)}),
        ('Tokens', {'fields': ('token', 'refresh_token')}),
        ('Informations de connexion', {'fields': ('date_connexion', 'date_expiration', 'ip_adresse', 'user_agent')}),
        ('Statut', {'fields': ('est_active',)}),
    )


# Enregistrement explicite du modèle Utilisateur
admin.site.register(Utilisateur, UtilisateurAdmin)


# ==================== DÉSACTIVER LES MODÈLES ALLAUTH (pour éviter les doublons) ====================
try:
    from allauth.account.models import EmailAddress, EmailConfirmation
    from allauth.socialaccount.models import SocialApp, SocialAccount, SocialToken
    
    admin.site.unregister(EmailAddress)
    admin.site.unregister(EmailConfirmation)
    admin.site.unregister(SocialApp)
    admin.site.unregister(SocialAccount)
    admin.site.unregister(SocialToken)
except (ImportError, admin.sites.NotRegistered):
    pass


@admin.register(FCMToken)
class FCMTokenAdmin(admin.ModelAdmin):
    list_display = ('id', 'utilisateur', 'token', 'est_actif', 'date_creation')  # ⭐ Supprimer updated_at
    list_filter = ('est_actif', 'date_creation')
    search_fields = ('utilisateur__email', 'token')
    raw_id_fields = ('utilisateur',)
    readonly_fields = ('date_creation',)  # ⭐ Supprimer updated_at
    
    fieldsets = (
        ('Utilisateur', {'fields': ('utilisateur',)}),
        ('Token', {'fields': ('token', 'est_actif')}),
        ('Date de création', {'fields': ('date_creation',)}),  # ⭐ Supprimer updated_at
    )
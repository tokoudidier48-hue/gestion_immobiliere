from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Utilisateur

class UtilisateurAdmin(UserAdmin):
    list_display = ('email', 'first_name', 'last_name', 'telephone', 'role', 'est_actif')
    list_filter = ('role', 'est_actif')
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Informations personnelles', {'fields': ('first_name', 'last_name', 'telephone', 'photo_profil')}),
        ('Rôle et permissions', {'fields': ('role', 'is_active', 'is_staff', 'is_superuser')}),
        ('Dates importantes', {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'first_name', 'last_name', 'telephone', 'password1', 'password2', 'role'),
        }),
    )
    search_fields = ('email', 'first_name', 'last_name', 'telephone')
    ordering = ('email',)

admin.site.register(Utilisateur, UtilisateurAdmin)
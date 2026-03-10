from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import Utilisateur

@admin.register(Utilisateur)
class UtilisateurAdmin(UserAdmin):
    model = Utilisateur
    list_display = ('email', 'telephone', 'nom', 'prenom', 'is_staff', 'is_active')
    list_filter = ('is_staff', 'is_active')
    fieldsets = (
        (None, {'fields': ('email', 'telephone', 'password')}),
        ('Informations personnelles', {'fields': ('nom', 'prenom')}),
        ('Permissions', {'fields': ('is_staff', 'is_active', 'groups', 'user_permissions')}),
        ('Dates importantes', {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'telephone', 'nom', 'prenom', 'password1', 'password2', 'is_staff', 'is_active')}
        ),
    )
    search_fields = ('email', 'telephone', 'nom', 'prenom')
    ordering = ('email',)
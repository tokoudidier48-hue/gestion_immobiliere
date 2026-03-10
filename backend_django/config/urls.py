from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),

    # Routes API Utilisateurs
    path('api/utilisateurs/', include('apps.utilisateurs.urls')),
]
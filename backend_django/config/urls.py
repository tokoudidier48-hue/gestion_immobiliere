from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.views.static import serve
from rest_framework_simplejwt.views import TokenRefreshView

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/comptes/', include('comptes.urls')),
    path('api/proprietes/', include('proprietes.urls')),
    path('api/unites/', include('unites.urls')),
    path('api/locations/', include('locations.urls')),
    path('api/paiements/', include('paiements.urls')),
    path('api/notifications/', include('notifications.urls')),
    path('api/messagerie/', include('messagerie.urls')),
    path('api/colocataires/', include('colocataires.urls')),
    path('api/locataires/', include('locataires.urls')),
    path('api/agent-ia/', include('agent_ia.urls')),
    path('accounts/', include('allauth.urls')),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
]

# ⭐ SERVIRE LES FICHIERS STATIQUES ET MÉDIAS EN DÉVELOPPEMENT ⭐
# Cette configuration est ESSENTIELLE pour que les fichiers CSS/JS de l'admin fonctionnent
if settings.DEBUG:
    # Méthode 1: via static() - pour les fichiers collectés
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    # Méthode 2: via serve() - redondance pour être sûr que tout fonctionne
    urlpatterns += [
        path('static/<path:path>', serve, {'document_root': settings.STATIC_ROOT}),
        path('media/<path:path>', serve, {'document_root': settings.MEDIA_ROOT}),
    ]
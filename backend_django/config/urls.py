from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

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
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
"""
ASGI config for config project.
"""

import os
import sys
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

# Ajouter le chemin du projet
sys.path.append(os.path.dirname(os.path.dirname(__file__)))

# Initialiser Django ASGI d'abord
django_asgi_app = get_asgi_application()

# Importer après l'initialisation de Django
from channels.routing import ProtocolTypeRouter, URLRouter
from channels.security.websocket import AllowedHostsOriginValidator
from django.urls import re_path, path

# Importer directement les classes (pas via un alias)
from apps.messagerie.jwt_auth import JWTAuthMiddleware
from apps.messagerie.consumers import NotificationConsumer

# Configuration du routage
application = ProtocolTypeRouter({
    "http": django_asgi_app,
    "websocket": AllowedHostsOriginValidator(
        JWTAuthMiddleware(
            URLRouter([
                # Utiliser re_path pour plus de flexibilité
                re_path(r"^ws/notifications/$", NotificationConsumer.as_asgi()),
                # Alternative avec path (fonctionne aussi)
                # path("ws/notifications/", NotificationConsumer.as_asgi()),
            ])
        )
    ),
})
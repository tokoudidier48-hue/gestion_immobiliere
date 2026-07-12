import logging
from channels.db import database_sync_to_async
from channels.middleware import BaseMiddleware
from django.contrib.auth import get_user_model
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.tokens import AccessToken
from rest_framework_simplejwt.exceptions import InvalidToken, TokenError
from urllib.parse import parse_qs

logger = logging.getLogger(__name__)
User = get_user_model()


@database_sync_to_async
def get_user_from_token(token):
    try:
        access_token = AccessToken(token)
        user_id = access_token['user_id']
        user = User.objects.get(id=user_id)
        return user
    except (InvalidToken, TokenError) as e:
        logger.warning(f"⚠️ Token invalide: {e}")
        return AnonymousUser()
    except User.DoesNotExist:
        logger.warning(f"⚠️ Utilisateur non trouvé pour le token")
        return AnonymousUser()


class JWTAuthMiddleware(BaseMiddleware):
    """
    Middleware JWT pour authentifier les WebSockets
    Le token peut être passé de 2 façons :
    1. Dans l'URL : ?token=xxx
    2. Dans l'en-tête Authorization (plus sécurisé mais plus complexe en WebSocket)
    """
    
    async def __call__(self, scope, receive, send):
        # Récupérer les query string de l'URL
        query_string = scope.get('query_string', b'').decode()
        query_params = parse_qs(query_string)
        
        # Chercher le token
        token = None
        if 'token' in query_params:
            token = query_params['token'][0]
            logger.debug(f"🔑 Token trouvé dans la query string")
        
        # Alternative : chercher dans les cookies
        if not token:
            cookies = scope.get('cookies', {})
            if 'access_token' in cookies:
                token = cookies['access_token']
                logger.debug(f"🔑 Token trouvé dans les cookies")
        
        # Alternative : chercher dans les headers (sous-optimal en WebSocket)
        if not token:
            headers = dict(scope.get('headers', []))
            if b'authorization' in headers:
                auth_header = headers[b'authorization'].decode()
                if auth_header.startswith('Bearer '):
                    token = auth_header.split(' ')[1]
                    logger.debug(f"🔑 Token trouvé dans Authorization header")
        
        # Authentifier l'utilisateur
        if token:
            scope['user'] = await get_user_from_token(token)
            if scope['user'] and not scope['user'].is_anonymous:
                logger.debug(f"✅ Utilisateur authentifié: {scope['user'].email}")
            else:
                logger.warning(f"⚠️ Authentification échouée pour le token")
        else:
            logger.warning(f"⚠️ Aucun token trouvé pour la connexion WebSocket")
            scope['user'] = AnonymousUser()
        
        # Ajouter le scope à la session si nécessaire
        scope['session'] = {}
        
        return await super().__call__(scope, receive, send)
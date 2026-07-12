# apps/agent_ia/urls.py

from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views

router = SimpleRouter(trailing_slash=True)

router.register(
    "conversations",
    views.ConversationIAViewSet,
    basename="conversation-ia",
)
router.register(
    "messages",
    views.MessageIAViewSet,
    basename="message-ia",
)

urlpatterns = [
    path("", include(router.urls)),
]
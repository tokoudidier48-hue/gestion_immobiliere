from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views

router = SimpleRouter()
router.register('conversations', views.ConversationViewSet, basename='conversation')
router.register('messages', views.MessageViewSet, basename='message')

urlpatterns = [
    path('', include(router.urls)),
]
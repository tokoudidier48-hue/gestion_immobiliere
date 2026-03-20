from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views

router = SimpleRouter()
router.register('demandes', views.DemandeUniteViewSet, basename='demande')

urlpatterns = [
    path('', include(router.urls)),
]
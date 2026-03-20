from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views

router = SimpleRouter()
router.register('paiements', views.PaiementViewSet, basename='paiement')
router.register('recus', views.RecuViewSet, basename='recu')

urlpatterns = [
    path('', include(router.urls)),
]
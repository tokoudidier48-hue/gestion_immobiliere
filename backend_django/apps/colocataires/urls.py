from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views

router = SimpleRouter()
router.register('recherches', views.RechercheColocataireViewSet, basename='recherche')
router.register('candidatures', views.CandidatureColocataireViewSet, basename='candidature')

urlpatterns = [
    path('', include(router.urls)),
]
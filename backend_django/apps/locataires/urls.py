from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views

router = SimpleRouter()
router.register('locataires', views.LocataireViewSet, basename='locataire')

urlpatterns = [
    path('', include(router.urls)),
]
from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views

router = SimpleRouter()
router.register('unites', views.UniteViewSet, basename='unite')

urlpatterns = [
    path('', include(router.urls)),
]
from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views

router = SimpleRouter()
router.register('proprietes', views.ProprieteViewSet, basename='propriete')

urlpatterns = [
    path('', include(router.urls)),
]
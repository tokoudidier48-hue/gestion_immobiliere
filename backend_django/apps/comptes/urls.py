from django.urls import path
from . import views

urlpatterns = [
    path('inscription/', views.InscriptionView.as_view(), name='inscription'),
    path('connexion/', views.ConnexionView.as_view(), name='connexion'),
    path('mot-de-passe-oublie/', views.MotDePasseOublieView.as_view(), name='mot-de-passe-oublie'),
    path('verifier-code/', views.VerifierCodeView.as_view(), name='verifier-code'),
    path('nouveau-mot-de-passe/', views.NouveauMotDePasseView.as_view(), name='nouveau-mot-de-passe'),
    path('profil/', views.ProfilView.as_view(), name='profil'),
]
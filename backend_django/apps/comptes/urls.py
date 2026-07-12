from django.urls import path
from .views import (
    InscriptionView, ConnexionView, MotDePasseOublieView,
    VerifierCodeView, NouveauMotDePasseView, ProfilView,
    DeconnexionView, SessionsView, UtilisateurEnLigneView,
    RevokeSessionView, SocialLoginView,
    VerifyEmailView, EnregistrerFCMTokenView,
    TestSMTPDebugView, CompleterProfilColocataireView, ModifierProfilView, SupprimerCompteView, SoldeView
)

urlpatterns = [
    path('inscription/', InscriptionView.as_view(), name='inscription'),
    path('connexion/', ConnexionView.as_view(), name='connexion'),
    path('mot-de-passe-oublie/', MotDePasseOublieView.as_view(), name='mot-de-passe-oublie'),
    path('verifier-code/', VerifierCodeView.as_view(), name='verifier-code'),
    path('nouveau-mot-de-passe/', NouveauMotDePasseView.as_view(), name='nouveau-mot-de-passe'),
    path('profil/', ProfilView.as_view(), name='profil'),
    path('deconnexion/', DeconnexionView.as_view(), name='deconnexion'),
    path('sessions/', SessionsView.as_view(), name='sessions'),
    path('sessions/revoke/<int:session_id>/', RevokeSessionView.as_view(), name='revoke-session'),
    path('en-ligne/', UtilisateurEnLigneView.as_view(), name='en-ligne'),
    path('en-ligne/<int:user_id>/', UtilisateurEnLigneView.as_view(), name='en-ligne-user'),
    path('social-login/', SocialLoginView.as_view(), name='social-login'),
    path('verify-email/', VerifyEmailView.as_view(), name='verify-email'),
    # path('test-email/', TestEmailView.as_view(), name='test-email'),
    path('fcm-token/', EnregistrerFCMTokenView.as_view(), name='fcm-token'),
    path("test-smtp/", TestSMTPDebugView.as_view()),
    path('completer-profil-colocataire/', CompleterProfilColocataireView.as_view(), name='completer-profil-colocataire'),
    path('supprimer-compte/', SupprimerCompteView.as_view(), name='supprimer-compte'),
    path('solde/', SoldeView.as_view(), name='solde'),
]
from django.urls import path, include
from rest_framework.routers import SimpleRouter
from . import views
from .views import InitierPaiementView, webhook_fedapay

router = SimpleRouter()
router.register('paiements', views.PaiementViewSet, basename='paiement')
router.register('recus', views.RecuViewSet, basename='recu')

urlpatterns = [
    # ⭐ ROUTES PERSONNALISÉES (avant le router)
    path('paiements/avances/', views.ListePaiementsAvecRemboursementView.as_view(), name='liste-avances'),
    path('initier-paiement/', InitierPaiementView.as_view(), name='initier-paiement'),
    path('webhook/', webhook_fedapay, name='webhook-fedapay'),
    path('retrait/', views.DemanderRetraitView.as_view(), name='retrait'),
    path('recus-retrait/<int:pk>/', views.RecuRetraitDetailView.as_view(), name='recu-retrait-detail'),
    path('recus-retrait/<int:pk>/telecharger/', views.TelechargerRecuRetraitView.as_view(), name='telecharger-recu-retrait'),
    path('demandes-remboursement/', views.DemanderRemboursementView.as_view(), name='demander-remboursement'),
    path('demandes-remboursement/<int:pk>/traiter/', views.TraiterDemandeRemboursementView.as_view(), name='traiter-demande-remboursement'),
    path('remboursements/<int:pk>/retirer/', views.RetirerRemboursementView.as_view(), name='retirer-remboursement'),

    # ⭐ INCLUSION DU ROUTEUR (en dernier)
    path('', include(router.urls)),
]
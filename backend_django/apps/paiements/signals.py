# apps/paiements/signals.py

from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Paiement
from colocataires.models import RechercheColocataire


@receiver(post_save, sender=Paiement)
def annuler_recherches_apres_paiement(sender, instance, created, **kwargs):
    """
    Quand un paiement est validé, annuler toutes les autres recherches actives du locataire
    """
    if instance.statut == 'valide' and instance.type_paiement == 'avance':
        # Annuler les recherches actives sauf celle de l'unité payée
        RechercheColocataire.objects.filter(
            locataire=instance.locataire,
            statut='active'
        ).exclude(
            unite=instance.unite
        ).update(statut='terminee')
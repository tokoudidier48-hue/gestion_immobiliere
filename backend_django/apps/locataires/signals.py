from django.db.models.signals import pre_delete, post_delete
from django.dispatch import receiver
from .models import Locataire

@receiver(pre_delete, sender=Locataire)
def avant_suppression_locataire(sender, instance, **kwargs):
    """
    Avant de supprimer un locataire, on libère l'unité (statut = libre)
    mais on ne supprime PAS l'unité
    """
    if instance.unite:
        print(f"🔍 Libération de l'unité {instance.unite.nom} avant suppression du locataire")
        
        # ⭐ CHANGER LE STATUT DE L'UNITÉ EN "libre" ⭐
        unite = instance.unite
        unite.statut = 'libre'
        unite.locataire_actuel = None
        unite.date_debut_location = None
        unite.save()
        
        print(f"✅ Unité {unite.nom} maintenant disponible (statut: {unite.statut})")
from django.db import models
from comptes.models import Utilisateur
from unites.models import Unite
from proprietes.models import Propriete

class Locataire(models.Model):
    """Modèle représentant un locataire dans une propriété"""
    
    MODE_PAIEMENT_CHOIX = [
        ('en_ligne', 'Paiement en ligne'),
        ('especes', 'Espèces (ajout manuel)'),
    ]
    
    # Relation avec le compte utilisateur (le locataire a un compte)
    # ⭐ MODIFICATION : ForeignKey au lieu de OneToOne (un locataire peut louer plusieurs propriétés) ⭐
    utilisateur = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='locations',
        verbose_name="Compte utilisateur",
        limit_choices_to={'role': 'locataire'}
    )
    
    # ⭐ NOUVEAU : Propriété (clé principale pour regrouper les locataires) ⭐
    propriete = models.ForeignKey(
        Propriete,
        on_delete=models.CASCADE,
        related_name='locataires',
        verbose_name="Propriété"
    )
    
    # ⭐ MODIFICATION : OneToOneField pour qu'un locataire soit lié à une seule unité ⭐
    # ⭐ on_delete=models.SET_NULL : suppression du locataire NE supprime PAS l'unité ⭐
    unite = models.OneToOneField(
        Unite,
        on_delete=models.SET_NULL,  # ⭐ CHANGÉ : ne supprime pas l'unité
        null=True,
        blank=True,
        related_name='locataire_associe',
        verbose_name="Unité louée"
    )
    
    # Date d'entrée dans les lieux
    date_entree = models.DateField(
        verbose_name="Date d'entrée"
    )
    
    # Mode de paiement (pour savoir si paiement en ligne ou manuel)
    mode_paiement = models.CharField(
        max_length=20,
        choices=MODE_PAIEMENT_CHOIX,
        default='en_ligne',
        verbose_name="Mode de paiement"
    )
    
    # Statut du locataire
    est_actif = models.BooleanField(
        default=True,
        verbose_name="Locataire actif"
    )
    
    # Métadonnées
    date_creation = models.DateTimeField(auto_now_add=True)
    date_modification = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Locataire"
        verbose_name_plural = "Locataires"
        ordering = ['-date_entree']
        # ⭐ Empêcher un même locataire d'être ajouté deux fois à la même propriété ⭐
        unique_together = ['utilisateur', 'propriete']
    
    def __str__(self):
        return f"{self.utilisateur.get_full_name()} - {self.propriete.nom}"
    
    @property
    def nom(self):
        return self.utilisateur.last_name
    
    @property
    def prenom(self):
        return self.utilisateur.first_name
    
    @property
    def email(self):
        return self.utilisateur.email
    
    @property
    def telephone(self):
        return self.utilisateur.telephone
    
    @property
    def unite_nom(self):
        return self.unite.nom if self.unite else "Non assigné"
    
    @property
    def propriete_nom(self):
        return self.propriete.nom
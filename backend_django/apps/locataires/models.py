from django.db import models
from comptes.models import Utilisateur
from unites.models import Unite
from proprietes.models import Propriete

class Locataire(models.Model):
    """Modèle représentant un locataire (géré par le propriétaire)"""
    
    MODE_PAIEMENT_CHOIX = [
        ('en_ligne', 'Paiement en ligne'),
        ('especes', 'Espèces (ajout manuel)'),
    ]
    
    # Relation avec le compte utilisateur (le locataire a un compte)
    utilisateur = models.OneToOneField(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='profil_locataire',
        verbose_name="Compte utilisateur",
        limit_choices_to={'role': 'locataire'}
    )
    
    # Unité louée
    unite = models.ForeignKey(
        Unite,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='locataires_occupants',
        verbose_name="Unité louée"
    )
    
    # Propriété (pour regrouper les locataires par propriété)
    propriete = models.ForeignKey(
        Propriete,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='locataires',
        verbose_name="Propriété"
    )
    
    # Date d'entrée dans les lieux
    date_entree = models.DateField(
        null=True, 
        blank=True,
        verbose_name="Date d'entrée"
    )
    
    # Mode de paiement (pour savoir si paiement en ligne ou manuel)
    mode_paiement = models.CharField(
        max_length=20,
        choices=MODE_PAIEMENT_CHOIX,
        default='en_ligne',
        verbose_name="Mode de paiement"
    )
    
    # Métadonnées
    date_creation = models.DateTimeField(auto_now_add=True)
    date_modification = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"{self.utilisateur.get_full_name()} - {self.unite.nom if self.unite else 'Aucune unité'}"
    
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
    
    class Meta:
        verbose_name = "Locataire"
        verbose_name_plural = "Locataires"
        ordering = ['-date_entree']
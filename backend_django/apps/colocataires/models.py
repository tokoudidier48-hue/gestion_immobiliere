from django.db import models
from comptes.models import Utilisateur
from unites.models import Unite

class RechercheColocataire(models.Model):
    """Modèle pour les recherches de colocataire lancées par un locataire"""
    
    locataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='recherches_colocataire',
        verbose_name="Locataire",
        limit_choices_to={'role': 'locataire'}  # Seulement les locataires
    )
    unite = models.ForeignKey(
        Unite,
        on_delete=models.CASCADE,
        related_name='recherches_colocataire',
        verbose_name="Unité concernée"
    )
    
    # Critères de recherche
    filiere = models.CharField(
        max_length=200,
        verbose_name="Filière"
    )
    ville = models.CharField(
        max_length=100,
        verbose_name="Ville"
    )
    religion = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Religion (optionnel)"
    )
    telephone = models.CharField(
        max_length=20,
        verbose_name="Téléphone"
    )
    description = models.TextField(
        verbose_name="Description de la recherche"
    )
    
    # Statut
    est_active = models.BooleanField(
        default=True,
        verbose_name="Recherche active"
    )
    
    # Métadonnées
    date_creation = models.DateTimeField(auto_now_add=True)
    date_modification = models.DateTimeField(auto_now=True)
    
    def __str__(self):
        return f"Recherche de {self.locataire.get_full_name()} pour {self.unite.nom}"
    
    class Meta:
        verbose_name = "Recherche de colocataire"
        verbose_name_plural = "Recherches de colocataires"
        ordering = ['-date_creation']


class CandidatureColocataire(models.Model):
    """Modèle pour les candidatures aux annonces de colocataire"""
    
    recherche = models.ForeignKey(
        RechercheColocataire,
        on_delete=models.CASCADE,
        related_name='candidatures',
        verbose_name="Recherche associée"
    )
    candidat = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='candidatures_colocataire',
        verbose_name="Candidat",
        limit_choices_to={'role': 'locataire'}  # Seulement les locataires
    )
    
    # Informations du candidat
    filiere = models.CharField(
        max_length=200,
        verbose_name="Filière"
    )
    ville = models.CharField(
        max_length=100,
        verbose_name="Ville"
    )
    religion = models.CharField(
        max_length=100,
        blank=True,
        verbose_name="Religion (optionnel)"
    )
    telephone = models.CharField(
        max_length=20,
        verbose_name="Téléphone"
    )
    description = models.TextField(
        verbose_name="Description"
    )
    
    # Statut
    est_acceptee = models.BooleanField(
        default=False,
        verbose_name="Acceptée"
    )
    
    # Métadonnées
    date_candidature = models.DateTimeField(auto_now_add=True)
    date_reponse = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name="Date de réponse"
    )
    
    def __str__(self):
        return f"Candidature de {self.candidat.get_full_name()} pour {self.recherche}"
    
    def accepter(self):
        from django.utils import timezone
        self.est_acceptee = True
        self.date_reponse = timezone.now()
        self.save()
    
    def refuser(self):
        from django.utils import timezone
        self.est_acceptee = False
        self.date_reponse = timezone.now()
        self.save()
    
    class Meta:
        verbose_name = "Candidature colocataire"
        verbose_name_plural = "Candidatures colocataires"
        ordering = ['-date_candidature']
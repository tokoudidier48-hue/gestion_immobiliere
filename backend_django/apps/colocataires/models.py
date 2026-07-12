from django.db import models
from django.utils import timezone
from comptes.models import Utilisateur
from unites.models import Unite


class RechercheColocataire(models.Model):
    """
    Modèle pour gérer les recherches de colocataire
    """
    
    STATUT_CHOIX = [
        ('active', 'Active'),
        ('annulee', 'Annulée'),
        ('expiree', 'Expirée'),
        ('terminee', 'Terminée (après paiement)'),
    ]
    
    locataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='recherches_colocataire',
        limit_choices_to={'role': 'locataire'},
        verbose_name="Locataire"
    )
    unite = models.ForeignKey(
        Unite,
        on_delete=models.CASCADE,
        related_name='recherches_colocataire',
        verbose_name="Unité concernée"
    )
    
    # ⭐ Statut de la recherche (remplace est_active)
    statut = models.CharField(
        max_length=20,
        choices=STATUT_CHOIX,
        default='active',
        verbose_name="Statut"
    )
    
    # Données du profil (copie au moment de la création)
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
        blank=True,
        verbose_name="Description"
    )
    
    # ⭐ Dates (ajout de date_expiration)
    date_creation = models.DateTimeField(auto_now_add=True, verbose_name="Date de création")
    date_modification = models.DateTimeField(auto_now=True, verbose_name="Date de modification")
    date_expiration = models.DateTimeField(verbose_name="Date d'expiration")
    
    class Meta:
        verbose_name = "Recherche de colocataire"
        verbose_name_plural = "Recherches de colocataires"
        ordering = ['-date_creation']
        # ⭐ Empêcher les doublons actifs sur la même unité
        unique_together = ['locataire', 'unite', 'statut']
    
    def __str__(self):
        return f"{self.locataire.get_full_name()} - {self.unite.nom} ({self.statut})"
    
    def est_active(self):
        """Vérifie si la recherche est encore active"""
        return self.statut == 'active' and self.date_expiration > timezone.now()
    
    def expirer(self):
        """Expire la recherche si la date d'expiration est dépassée"""
        if self.statut == 'active' and self.date_expiration <= timezone.now():
            self.statut = 'expiree'
            self.save()
            return True
        return False
    
    def annuler(self):
        """Annule manuellement la recherche"""
        if self.statut == 'active':
            self.statut = 'annulee'
            self.save()
            return True
        return False
    
    def terminer(self):
        """Termine la recherche après paiement"""
        if self.statut == 'active':
            self.statut = 'terminee'
            self.save()
            return True
        return False


class CandidatureColocataire(models.Model):
    """Modèle pour les candidatures aux annonces de colocataire"""
    
    STATUT_CHOIX = [
        ('en_attente', 'En attente'),
        ('acceptee', 'Acceptée'),
        ('refusee', 'Refusée'),
    ]
    
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
        limit_choices_to={'role': 'locataire'}
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
    
    # ⭐ Statut de la candidature (plus précis)
    statut = models.CharField(
        max_length=20,
        choices=STATUT_CHOIX,
        default='en_attente',
        verbose_name="Statut"
    )
    
    # Métadonnées
    date_candidature = models.DateTimeField(auto_now_add=True, verbose_name="Date de candidature")
    date_reponse = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name="Date de réponse"
    )
    
    def __str__(self):
        return f"Candidature de {self.candidat.get_full_name()} pour {self.recherche}"
    
    def accepter(self):
        from django.utils import timezone
        self.statut = 'acceptee'
        self.date_reponse = timezone.now()
        self.save()
    
    def refuser(self):
        from django.utils import timezone
        self.statut = 'refusee'
        self.date_reponse = timezone.now()
        self.save()
    
    class Meta:
        verbose_name = "Candidature colocataire"
        verbose_name_plural = "Candidatures colocataires"
        ordering = ['-date_candidature']
        # ⭐ Empêcher un candidat de postuler deux fois à la même recherche
        unique_together = ['recherche', 'candidat']
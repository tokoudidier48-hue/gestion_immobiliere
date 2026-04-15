from django.db import models
from comptes.models import Utilisateur
from unites.models import Unite

class DemandeUnite(models.Model):
    STATUT_CHOIX = [
        ('en_attente', 'En attente'),
        ('acceptee', 'Acceptée'),
        ('refusee', 'Refusée'),
        ('annulee', 'Annulée'),
    ]

    locataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='demandes_effectuees',
        verbose_name="Locataire",
        limit_choices_to={'role': 'locataire'}
    )
    proprietaire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='demandes_recues',
        verbose_name="Propriétaire",
        limit_choices_to={'role': 'proprietaire'}
    )
    unite = models.ForeignKey(
        Unite,
        on_delete=models.CASCADE,
        related_name='demandes',
        verbose_name="Unité concernée"
    )
    message = models.TextField(
        blank=True,
        verbose_name="Message du locataire (optionnel)"
    )
    statut = models.CharField(
        max_length=20,
        choices=STATUT_CHOIX,
        default='en_attente',
        verbose_name="Statut"
    )
    date_demande = models.DateTimeField(auto_now_add=True)
    date_reponse = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name="Date de réponse"
    )

    class Meta:
        verbose_name = "Demande d'unité"
        verbose_name_plural = "Demandes d'unités"
        ordering = ['-date_demande']
        # Empêcher un locataire d'avoir plusieurs demandes en attente pour la même unité
        unique_together = ('locataire', 'unite', 'statut')

    def __str__(self):
        return f"Demande de {self.locataire.get_full_name()} pour {self.unite.nom} ({self.get_statut_display()})"

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

    def annuler(self):
        self.statut = 'annulee'
        self.save()
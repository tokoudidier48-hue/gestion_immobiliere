from django.db import models
from comptes.models import Utilisateur

class Notification(models.Model):
    TYPE_CHOIX = [
        ('message', 'Nouveau message'),
        ('demande', 'Nouvelle demande d\'unité'),
        ('reponse_demande', 'Réponse à une demande'),
        ('paiement', 'Paiement reçu'),
        ('colocataire', 'Candidature colocataire'),
        ('systeme', 'Information système'),
    ]

    destinataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name="Destinataire"
    )
    type = models.CharField(
        max_length=20,
        choices=TYPE_CHOIX,
        verbose_name="Type de notification"
    )
    titre = models.CharField(
        max_length=200,
        verbose_name="Titre"
    )
    message = models.TextField(
        verbose_name="Message"
    )
    lien = models.CharField(
        max_length=255,
        blank=True,
        verbose_name="Lien (URL ou route)"
    )
    est_lue = models.BooleanField(
        default=False,
        verbose_name="Lue"
    )
    date_creation = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Date de création"
    )

    class Meta:
        verbose_name = "Notification"
        verbose_name_plural = "Notifications"
        ordering = ['-date_creation']

    def __str__(self):
        return f"{self.get_type_display()} - {self.titre} ({self.destinataire.email})"
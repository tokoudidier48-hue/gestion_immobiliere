from django.db import models
from comptes.models import Utilisateur
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
        ('demande_remboursement', 'Demande de remboursement'),
        ('remboursement_approuve', 'Remboursement approuvé'),
        ('remboursement_retire', 'Remboursement retiré'),
    ]

    destinataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name="Destinataire"
    )
    type = models.CharField(
        max_length=25,
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

    
    def envoyer_push(self):
        """Envoie une notification push à l'utilisateur"""
        from .fcm_service import notify_user
        
        # Préparer les données personnalisées
        donnees = {
            'notification_id': str(self.id),
            'type': self.type,
            'lien': self.lien or '',
        }
        
        # Envoyer la notification push
        notify_user(
            self.destinataire,
            self.titre,
            self.message,
            donnees
        )
    
    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        
        # Envoyer la notification push après sauvegarde
        # Pour éviter les envois en boucle, vérifiez que ce n'est pas un test
        try:
            self.envoyer_push()
        except Exception as e:
            print(f"Erreur d'envoi push: {e}")
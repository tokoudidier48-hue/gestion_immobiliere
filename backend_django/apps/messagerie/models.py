from django.db import models
from comptes.models import Utilisateur
from unites.models import Unite

class Conversation(models.Model):
    participants = models.ManyToManyField(
        Utilisateur,
        related_name='conversations',
        verbose_name="Participants"
    )
    unite = models.ForeignKey(
        Unite,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='conversations',
        verbose_name="Unité concernée (optionnel)"
    )
    date_creation = models.DateTimeField(auto_now_add=True)
    date_dernier_message = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Conversation"
        verbose_name_plural = "Conversations"
        ordering = ['-date_dernier_message']

    def __str__(self):
        return f"Conversation {self.id} - {self.participants.count()} participants"


class Message(models.Model):
    conversation = models.ForeignKey(
        Conversation,
        on_delete=models.CASCADE,
        related_name='messages',
        verbose_name="Conversation"
    )
    expediteur = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='messages_envoyes',
        verbose_name="Expéditeur"
    )
    contenu = models.TextField(
        verbose_name="Contenu du message"
    )
    est_lu = models.BooleanField(
        default=False,
        verbose_name="Lu"
    )
    date_envoi = models.DateTimeField(auto_now_add=True)
    date_lecture = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name="Date de lecture"
    )

    class Meta:
        verbose_name = "Message"
        verbose_name_plural = "Messages"
        ordering = ['date_envoi']

    def __str__(self):
        return f"Message de {self.expediteur.email} - {self.date_envoi}"
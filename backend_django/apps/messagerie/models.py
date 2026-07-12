from django.db import models
from django.db.models import Q
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

        # 🔥 Empêche les doublons (important logique métier)
        constraints = [
            models.UniqueConstraint(
                fields=['unite'],
                name='unique_conversation_par_unite'
            )
        ]

    def __str__(self):
        participants = ", ".join([str(p) for p in self.participants.all()])
        return f"Conversation ({participants})"


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
        return f"{self.expediteur} → Conversation {self.conversation.id}"
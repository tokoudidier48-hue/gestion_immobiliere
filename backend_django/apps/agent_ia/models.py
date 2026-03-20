from django.db import models
from comptes.models import Utilisateur
from unites.models import Unite

class ConversationIA(models.Model):
    """Modèle pour les conversations avec l'agent IA Loya"""
    
    locataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='conversations_ia',
        verbose_name="Locataire",
        limit_choices_to={'role': 'locataire'}  # Seulement les locataires
    )
    
    date_debut = models.DateTimeField(auto_now_add=True)
    date_dernier_message = models.DateTimeField(auto_now=True)
    est_active = models.BooleanField(default=True)
    
    def __str__(self):
        return f"Conversation IA - {self.locataire.get_full_name()} - {self.date_debut}"
    
    class Meta:
        verbose_name = "Conversation IA"
        verbose_name_plural = "Conversations IA"
        ordering = ['-date_dernier_message']


class MessageIA(models.Model):
    """Modèle pour les messages échangés avec l'agent IA"""
    
    TYPE_EXPEDITEUR_CHOIX = [
        ('locataire', 'Locataire'),
        ('ia', 'Agent IA Loya'),
    ]
    
    TYPE_MESSAGE_CHOIX = [
        ('texte', 'Texte'),
        ('vocal', 'Vocal'),
    ]
    
    conversation = models.ForeignKey(
        ConversationIA,
        on_delete=models.CASCADE,
        related_name='messages',
        verbose_name="Conversation"
    )
    
    type_expediteur = models.CharField(
        max_length=20,
        choices=TYPE_EXPEDITEUR_CHOIX,
        verbose_name="Expéditeur"
    )
    
    contenu = models.TextField(
        verbose_name="Message"
    )
    
    type_message = models.CharField(
        max_length=20,
        choices=TYPE_MESSAGE_CHOIX,
        default='texte',
        verbose_name="Type de message"
    )
    
    fichier_vocal = models.FileField(
        upload_to='messages_vocaux/',
        null=True,
        blank=True,
        verbose_name="Fichier vocal"
    )
    
    date_envoi = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Message {self.get_type_expediteur_display()} - {self.date_envoi}"
    
    class Meta:
        verbose_name = "Message IA"
        verbose_name_plural = "Messages IA"
        ordering = ['date_envoi']


class RecommandationIA(models.Model):
    """Modèle pour les recommandations de logement faites par l'IA"""
    
    conversation = models.ForeignKey(
        ConversationIA,
        on_delete=models.CASCADE,
        related_name='recommandations',
        verbose_name="Conversation"
    )
    
    unites = models.ManyToManyField(
        Unite,
        related_name='recommandations_ia',
        verbose_name="Unités recommandées"
    )
    
    criteres_recherche = models.TextField(
        verbose_name="Critères de recherche"
    )
    
    date_recommandation = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"Recommandation - {self.date_recommandation}"
    
    class Meta:
        verbose_name = "Recommandation IA"
        verbose_name_plural = "Recommandations IA"
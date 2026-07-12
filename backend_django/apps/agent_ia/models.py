# apps/agent_ia/models.py

from django.db import models
from django.utils import timezone

from comptes.models import Utilisateur
from unites.models import Unite


# =========================================================
# CONVERSATION IA
# =========================================================

class ConversationIA(models.Model):
    """
    Conversation entre un locataire et l'IA Loya.
    Une conversation = un fil de messages continus.
    """

    locataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name="conversations_ia",
        verbose_name="Locataire",
    )

    date_debut = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Date de début",
    )

    date_dernier_message = models.DateTimeField(
        default=timezone.now,
        verbose_name="Dernier message",
        db_index=True,       # Indexé : trié fréquemment
    )

    est_active = models.BooleanField(
        default=True,
        db_index=True,       # Indexé : filtré à chaque requête
        verbose_name="Active",
    )

    def touch(self) -> None:
        """
        Met à jour manuellement date_dernier_message.
        Utile pour forcer la mise à jour sans sauvegarder
        tout l'objet (ex: après sauvegarde d'un MessageIA).
        """
        self.date_dernier_message = timezone.now()
        self.save(update_fields=["date_dernier_message"])

    def __str__(self) -> str:
        nom = getattr(self.locataire, "get_full_name", None)
        nom = nom() if callable(nom) else str(self.locataire)
        return f"Conversation IA — {nom} — {self.date_debut:%d/%m/%Y %H:%M}"

    class Meta:
        verbose_name = "Conversation IA"
        verbose_name_plural = "Conversations IA"
        ordering = ["-date_dernier_message"]


# =========================================================
# MESSAGE IA
# =========================================================

class MessageIA(models.Model):
    """
    Message échangé entre le locataire et Loya.
    Chaque envoi produit deux messages :
      - un message locataire
      - un message ia
    """

    TYPE_EXPEDITEUR_CHOIX = [
        ("locataire", "Locataire"),
        ("ia", "Agent IA Loya"),
    ]

    TYPE_MESSAGE_CHOIX = [
        ("texte", "Texte"),
        ("vocal", "Vocal"),
    ]

    conversation = models.ForeignKey(
        ConversationIA,
        on_delete=models.CASCADE,
        related_name="messages",
        verbose_name="Conversation",
    )

    type_expediteur = models.CharField(
        max_length=20,
        choices=TYPE_EXPEDITEUR_CHOIX,
        verbose_name="Expéditeur",
        db_index=True,
    )

    contenu = models.TextField(verbose_name="Message")

    type_message = models.CharField(
        max_length=20,
        choices=TYPE_MESSAGE_CHOIX,
        default="texte",
        verbose_name="Type de message",
    )

    fichier_vocal = models.FileField(
        upload_to="messages_vocaux/",
        null=True,
        blank=True,
        verbose_name="Fichier vocal",
    )

    date_envoi = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Date d'envoi",
    )

    def __str__(self) -> str:
        return (
            f"[{self.get_type_expediteur_display()}] "
            f"{self.contenu[:50]} — {self.date_envoi:%d/%m/%Y %H:%M}"
        )

    class Meta:
        verbose_name = "Message IA"
        verbose_name_plural = "Messages IA"
        ordering = ["date_envoi"]
        indexes = [
            # Index composé pour les requêtes fréquentes :
            # MessageIA.objects.filter(conversation=x).order_by("date_envoi")
            models.Index(
                fields=["conversation", "date_envoi"],
                name="idx_message_conv_date",
            ),
            # Index pour pagination par ID
            models.Index(
                fields=["conversation", "id"],
                name="idx_message_conv_id",
            ),
        ]


# =========================================================
# RECOMMANDATION IA
# =========================================================

class RecommandationIA(models.Model):
    """
    Recommandations de logements générées par Loya.

    Permet de tracer quels logements ont été proposés
    lors d'une conversation, pour analyse future
    ou réaffichage sans refaire la recherche.

    Note : non utilisé activement dans le chatbot v1.
    Prévu pour la v2 (historique des recommandations).
    """

    conversation = models.ForeignKey(
        ConversationIA,
        on_delete=models.CASCADE,
        related_name="recommandations",
        verbose_name="Conversation",
    )

    unites = models.ManyToManyField(
        Unite,
        related_name="recommandations_ia",
        verbose_name="Unités recommandées",
        blank=True,
    )

    criteres_recherche = models.JSONField(
        verbose_name="Critères de recherche",
        help_text=(
            "Ex: {'type': 'chambre_salon', 'budget': 15000, "
            "'sanitaire': 'sanitaire'}"
        ),
    )

    date_recommandation = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Date",
        db_index=True,
    )

    def __str__(self) -> str:
        return f"Recommandation — {self.date_recommandation:%d/%m/%Y %H:%M}"

    class Meta:
        verbose_name = "Recommandation IA"
        verbose_name_plural = "Recommandations IA"
        ordering = ["-date_recommandation"]
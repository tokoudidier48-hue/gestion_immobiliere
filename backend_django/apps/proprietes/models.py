from django.db import models
from comptes.models import Utilisateur

class Propriete(models.Model):
    proprietaire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='proprietes',
        limit_choices_to={'role': 'proprietaire'}
    )
    nom = models.CharField(
        max_length=200,
        verbose_name="Nom de la propriété",
        unique=True  # Nom unique dans toute la base
    )
    date_creation = models.DateTimeField(auto_now_add=True)
    date_modification = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Propriété"
        verbose_name_plural = "Propriétés"
        ordering = ['-date_creation']

    def __str__(self):
        return f"{self.nom} - {self.proprietaire.get_full_name()}"
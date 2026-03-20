import random
import string
from django.db import models
from django.utils import timezone
from comptes.models import Utilisateur
from unites.models import Unite
from locations.models import DemandeUnite

class Paiement(models.Model):
    TYPE_PAIEMENT_CHOIX = [
        ('avance', "Paiement d'avance (entrée)"),
        ('loyer', 'Paiement de loyer mensuel'),
    ]

    MODE_PAIEMENT_CHOIX = [
        ('mtn', 'MTN MoMo'),
        ('moov', 'Moov Money'),
        ('celtis', 'Celtis'),
        ('especes', 'Espèces'),
    ]

    STATUT_CHOIX = [
        ('en_attente', 'En attente'),
        ('reussi', 'Réussi'),
        ('echoue', 'Échoué'),
        ('rembourse', 'Remboursé'),
    ]

    locataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='paiements_effectues',
        verbose_name="Locataire",
        limit_choices_to={'role': 'locataire'}
    )
    proprietaire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='paiements_recus',
        verbose_name="Propriétaire",
        limit_choices_to={'role': 'proprietaire'}
    )
    unite = models.ForeignKey(
        Unite,
        on_delete=models.CASCADE,
        related_name='paiements',
        verbose_name="Unité"
    )
    demande = models.ForeignKey(
        DemandeUnite,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='paiements',
        verbose_name="Demande associée"
    )

    type_paiement = models.CharField(
        max_length=20,
        choices=TYPE_PAIEMENT_CHOIX,
        verbose_name="Type de paiement"
    )
    mode_paiement = models.CharField(
        max_length=20,
        choices=MODE_PAIEMENT_CHOIX,
        verbose_name="Mode de paiement"
    )
    montant = models.DecimalField(
        max_digits=10,
        decimal_places=0,
        verbose_name="Montant (FCFA)"
    )
    numero_paiement = models.CharField(
        max_length=50,
        verbose_name="Numéro de paiement"
    )
    statut = models.CharField(
        max_length=20,
        choices=STATUT_CHOIX,
        default='en_attente',
        verbose_name="Statut"
    )

    periode_debut = models.DateField(
        verbose_name="Début de période"
    )
    periode_fin = models.DateField(
        verbose_name="Fin de période"
    )

    date_paiement = models.DateTimeField(auto_now_add=True)
    date_confirmation = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name="Date de confirmation"
    )

    class Meta:
        verbose_name = "Paiement"
        verbose_name_plural = "Paiements"
        ordering = ['-date_paiement']

    def __str__(self):
        return f"Paiement {self.get_type_paiement_display()} - {self.montant} FCFA"

    def confirmer(self):
        self.statut = 'reussi'
        self.date_confirmation = timezone.now()
        self.save()
        Recu.objects.create(paiement=self)


class Recu(models.Model):
    paiement = models.OneToOneField(
        Paiement,
        on_delete=models.CASCADE,
        related_name='recu',
        verbose_name="Paiement associé"
    )
    numero_recu = models.CharField(
        max_length=50,
        unique=True,
        verbose_name="Numéro de reçu"
    )
    contenu = models.TextField(
        verbose_name="Contenu du reçu"
    )
    fichier_pdf = models.FileField(
        upload_to='recus/',
        null=True,
        blank=True,
        verbose_name="Fichier PDF"
    )
    date_generation = models.DateTimeField(auto_now_add=True)
    nombre_telechargements = models.IntegerField(
        default=0,
        verbose_name="Nombre de téléchargements"
    )

    class Meta:
        verbose_name = "Reçu"
        verbose_name_plural = "Reçus"

    def __str__(self):
        return f"Reçu {self.numero_recu}"

    def generer_numero(self):
        lettres = ''.join(random.choices(string.ascii_uppercase, k=2))
        chiffres = ''.join(random.choices(string.digits, k=6))
        return f"RCP-{lettres}{chiffres}"

    def generer_contenu(self):
        p = self.paiement
        prepaye_str = "Avec prépayé" if p.unite.prepaye else "Sans prépayé"
        # Utilisation correcte des champs du modèle Utilisateur
        proprietaire_nom = f"{p.proprietaire.first_name} {p.proprietaire.last_name}" if p.proprietaire else "Inconnu"
        locataire_nom = f"{p.locataire.first_name} {p.locataire.last_name}" if p.locataire else "Inconnu"
        unite_nom = p.unite.nom if p.unite else "Inconnue"
        unite_adresse = p.unite.adresse if p.unite else ""
        unite_ville = p.unite.ville if p.unite else ""
        unite_type = p.unite.get_type_unite_display() if p.unite else ""

        return f"""
LOYASMART
=========
Reçu de paiement N°: {self.numero_recu}
Date: {p.date_paiement.strftime('%d/%m/%Y %H:%M') if p.date_paiement else 'Date inconnue'}

PROPRIÉTAIRE
------------
Nom: {proprietaire_nom}
Email: {p.proprietaire.email if p.proprietaire else ''}
Téléphone: {p.proprietaire.telephone if p.proprietaire else ''}

LOCATAIRE
---------
Nom: {locataire_nom}
Email: {p.locataire.email if p.locataire else ''}
Téléphone: {p.locataire.telephone if p.locataire else ''}

UNITÉ
-----
Type: {unite_type}
Nom: {unite_nom}
Adresse: {unite_adresse}, {unite_ville}
Loyer mensuel: {p.unite.loyer if p.unite else 0} FCFA
Nombre d'avances: {p.unite.nombre_avances if p.unite else 0}
Caution: {p.unite.prix_caution if p.unite else 0} FCFA
Prépayé: {prepaye_str}

PAIEMENT
--------
Type: {p.get_type_paiement_display()}
Montant: {p.montant} FCFA
Mode: {p.get_mode_paiement_display()}
Numéro de transaction: {p.numero_paiement}
Période: du {p.periode_debut} au {p.periode_fin}
        """

    def save(self, *args, **kwargs):
        if not self.numero_recu:
            self.numero_recu = self.generer_numero()
        if not self.contenu:
            self.contenu = self.generer_contenu()
        super().save(*args, **kwargs)
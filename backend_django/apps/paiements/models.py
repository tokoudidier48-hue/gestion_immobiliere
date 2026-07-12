import random
import string
import io
import os
from django.db import models
from django.utils import timezone
from django.core.files.base import ContentFile
from django.conf import settings
from comptes.models import Utilisateur
from unites.models import Unite
from locations.models import DemandeUnite

# Essayer d'importer reportlab, si non disponible, utiliser une alternative
try:
    from reportlab.lib.pagesizes import A4
    from reportlab.pdfgen import canvas
    from reportlab.lib.utils import simpleSplit
    REPORTLAB_AVAILABLE = True
except ImportError:
    REPORTLAB_AVAILABLE = False
    print("⚠️ reportlab non installé. Installez-le avec: pip install reportlab")


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

    # ⭐ NOUVEAUX STATUTS POUR GÉRER LES ESPÈCES ⭐
    STATUT_CHOIX = [
        ('en_attente', 'En attente de validation (espèces)'),  # Pour les espèces en attente
        ('valide', 'Validé'),                                 # Pour les mobiles et espèces acceptées
        ('refuse', 'Refusé'),                                 # Pour les espèces refusées
        ('echoue', 'Échoué'),                                 # Pour les mobiles échoués
        ('rembourse', 'Remboursé'),                           # Remboursement
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
        """Confirme un paiement (devient 'valide')"""
        self.statut = 'valide'
        self.date_confirmation = timezone.now()
        self.save()
        if not hasattr(self, 'recu'):
            Recu.objects.create(paiement=self)

    def accepter(self):
        """Accepte un paiement en espèces"""
        self.statut = 'valide'
        self.date_confirmation = timezone.now()
        self.save()
        if not hasattr(self, 'recu'):
            Recu.objects.create(paiement=self)

    def refuser(self):
        """Refuse un paiement en espèces"""
        self.statut = 'refuse'
        self.save()

    def est_en_attente(self):
        return self.statut == 'en_attente'

    def est_valide(self):
        return self.statut == 'valide'

    def est_refuse(self):
        return self.statut == 'refuse'


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

    def generer_fichier_pdf(self):
        """Génère un vrai fichier PDF à partir du contenu texte"""
        if not REPORTLAB_AVAILABLE:
            print("⚠️ reportlab non disponible, création d'un fichier texte simple")
            self._generer_fichier_texte()
            return
        
        try:
            buffer = io.BytesIO()
            c = canvas.Canvas(buffer, pagesize=A4)
            width, height = A4
            
            # Titre
            c.setFont("Helvetica-Bold", 18)
            c.drawString(50, height - 50, "LOYASMART")
            c.setFont("Helvetica-Bold", 14)
            c.drawString(50, height - 80, "Reçu de paiement")
            
            # Ligne de séparation
            c.line(50, height - 90, width - 50, height - 90)
            
            # Numéro de reçu
            c.setFont("Helvetica", 10)
            c.drawString(50, height - 110, f"N°: {self.numero_recu}")
            
            # Date
            c.drawString(width - 150, height - 110, f"Date: {self.date_generation.strftime('%d/%m/%Y')}")
            
            # Contenu du reçu (lignes)
            y = height - 140
            for line in self.contenu.split('\n'):
                if y < 50:
                    c.showPage()
                    y = height - 50
                c.setFont("Helvetica", 9)
                # Tronquer les lignes trop longues
                if len(line) > 100:
                    line = line[:97] + "..."
                c.drawString(50, y, line)
                y -= 14
            
            c.save()
            
            # Sauvegarder le PDF
            pdf_content = buffer.getvalue()
            filename = f"recu_{self.id}.pdf"
            self.fichier_pdf.save(filename, ContentFile(pdf_content), save=False)
            print(f"✅ PDF généré: {filename} ({len(pdf_content)} bytes)")
            
        except Exception as e:
            print(f"❌ Erreur génération PDF: {e}")
            self._generer_fichier_texte()

    # Dans la classe Recu, ajoutez cette méthode

    def generer_pdf_en_memoire(self):
        """Génère le PDF en mémoire sans le sauvegarder sur le disque"""
        from reportlab.lib.pagesizes import A4
        from reportlab.pdfgen import canvas
        from io import BytesIO
        
        buffer = BytesIO()
        c = canvas.Canvas(buffer, pagesize=A4)
        width, height = A4
        
        # En-tête
        c.setFont("Helvetica-Bold", 18)
        c.drawString(50, height - 50, "LOYASMART")
        c.setFont("Helvetica-Bold", 14)
        c.drawString(50, height - 80, "Reçu de paiement")
        c.line(50, height - 90, width - 50, height - 90)
        
        # Informations
        c.setFont("Helvetica", 10)
        c.drawString(50, height - 110, f"N°: {self.numero_recu}")
        c.drawString(width - 150, height - 110, f"Date: {self.date_generation.strftime('%d/%m/%Y')}")
        
        # Contenu du reçu
        y = height - 140
        for line in self.contenu.split('\n'):
            if y < 50:
                c.showPage()
                y = height - 50
            if len(line) > 100:
                line = line[:97] + "..."
            c.drawString(50, y, line)
            y -= 14
        
        c.save()
        buffer.seek(0)
        return buffer

    def _generer_fichier_texte(self):
        """Génère un fichier texte simple si reportlab n'est pas disponible"""
        filename = f"recu_{self.id}.txt"
        self.fichier_pdf.save(filename, ContentFile(self.contenu.encode('utf-8')), save=False)
        print(f"✅ Fichier texte généré: {filename}")

    def save(self, *args, **kwargs):
        if not self.numero_recu:
            self.numero_recu = self.generer_numero()
        if not self.contenu:
            self.contenu = self.generer_contenu()
        super().save(*args, **kwargs)
        # Générer le fichier PDF après la première sauvegarde
        if not self.fichier_pdf:
            self.generer_fichier_pdf()
            super().save(update_fields=['fichier_pdf'])


class RecuRetrait(models.Model):
    """
    Reçu généré lors d'un retrait de fonds par un propriétaire.
    """
    OPERATEUR_CHOIX = [
        ('mtn', 'MTN MoMo'),
        ('moov', 'Moov Money'),
        ('celtis', 'Celtis'),
    ]

    proprietaire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='recus_retrait',
        verbose_name="Propriétaire"
    )
    montant = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        verbose_name="Montant retiré (FCFA)"
    )
    telephone = models.CharField(
        max_length=20,
        verbose_name="Numéro de téléphone"
    )
    operateur = models.CharField(
        max_length=10,
        choices=OPERATEUR_CHOIX,
        verbose_name="Opérateur"
    )
    reference = models.CharField(
        max_length=100,
        unique=True,
        verbose_name="Référence FedaPay"
    )
    date_generation = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Date de génération"
    )
    fichier_pdf = models.FileField(
        upload_to='recus_retrait/',
        null=True,
        blank=True,
        verbose_name="Fichier PDF"
    )

    class Meta:
        verbose_name = "Reçu de retrait"
        verbose_name_plural = "Reçus de retrait"
        ordering = ['-date_generation']

    def __str__(self):
        return f"Retrait {self.proprietaire.email} - {self.montant} FCFA"

    def generer_pdf(self):
        """Génère un PDF pour le reçu de retrait"""
        from reportlab.lib.pagesizes import A4
        from reportlab.pdfgen import canvas
        from io import BytesIO
        from django.core.files.base import ContentFile

        buffer = BytesIO()
        c = canvas.Canvas(buffer, pagesize=A4)
        width, height = A4

        # Titre
        c.setFont("Helvetica-Bold", 18)
        c.drawString(50, height - 50, "LOYASMART")
        c.setFont("Helvetica-Bold", 14)
        c.drawString(50, height - 80, "Reçu de retrait")
        c.line(50, height - 90, width - 50, height - 90)

        # Informations
        c.setFont("Helvetica", 10)
        c.drawString(50, height - 110, f"N°: {self.reference}")
        c.drawString(width - 150, height - 110, f"Date: {self.date_generation.strftime('%d/%m/%Y %H:%M')}")

        c.drawString(50, height - 140, f"Propriétaire: {self.proprietaire.get_full_name()}")
        c.drawString(50, height - 160, f"Montant: {self.montant} FCFA")
        c.drawString(50, height - 180, f"Opérateur: {self.get_operateur_display()}")
        c.drawString(50, height - 200, f"Numéro: {self.telephone}")

        c.save()
        buffer.seek(0)

        filename = f"recu_retrait_{self.id}.pdf"
        self.fichier_pdf.save(filename, ContentFile(buffer.getvalue()), save=True)


class TransactionJournal(models.Model):
    """
    Journal des transactions financières (crédits/débits) pour traçabilité.
    """
    TYPE_CHOIX = [
        ('credit', 'Crédit'),
        ('debit', 'Débit'),
    ]

    proprietaire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='transactions',
        verbose_name="Propriétaire"
    )
    locataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='transactions_locataire',
        verbose_name="Locataire"
    )
    unite = models.ForeignKey(
        'unites.Unite',
        on_delete=models.CASCADE,
        verbose_name="Unité"
    )
    type = models.CharField(
        max_length=10,
        choices=TYPE_CHOIX,
        verbose_name="Type de transaction"
    )
    montant = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        verbose_name="Montant (FCFA)"
    )
    commission = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        default=0,
        verbose_name="Commission prélevée"
    )
    paiement = models.ForeignKey(
        'paiements.Paiement',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name="Paiement associé"
    )
    date_creation = models.DateTimeField(
        auto_now_add=True,
        verbose_name="Date de création"
    )

    class Meta:
        verbose_name = "Journal de transaction"
        verbose_name_plural = "Journaux de transactions"
        ordering = ['-date_creation']

    def __str__(self):
        return f"{self.get_type_display()} - {self.proprietaire.email} - {self.montant} FCFA"


class DemandeRemboursement(models.Model):
    STATUT_CHOIX = [
        ('en_attente', 'En attente'),
        ('approuvee', 'Approuvée'),
        ('refusee', 'Refusée'),
        ('remboursee', 'Remboursée'),
    ]

    locataire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='demandes_remboursement',
        limit_choices_to={'role': 'locataire'}
    )
    proprietaire = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='demandes_remboursement_recues',
        limit_choices_to={'role': 'proprietaire'}
    )
    paiement = models.ForeignKey(
        Paiement,
        on_delete=models.CASCADE,
        related_name='demandes_remboursement',
        limit_choices_to={'type_paiement': 'avance'}
    )
    message = models.TextField(verbose_name="Message du locataire")
    montant_demande = models.DecimalField(max_digits=12, decimal_places=0, verbose_name="Montant demandé")
    montant_approuve = models.DecimalField(max_digits=12, decimal_places=0, null=True, blank=True, verbose_name="Montant approuvé")
    statut = models.CharField(max_length=20, choices=STATUT_CHOIX, default='en_attente')
    date_demande = models.DateTimeField(auto_now_add=True)
    date_traitement = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ['-date_demande']
        verbose_name = "Demande de remboursement"
        verbose_name_plural = "Demandes de remboursement"

    def __str__(self):
        return f"Demande de {self.locataire.email} - {self.paiement.montant} FCFA"
    
class Remboursement(models.Model):
    demande = models.OneToOneField(
        DemandeRemboursement,
        on_delete=models.CASCADE,
        related_name='remboursement'
    )
    montant = models.DecimalField(max_digits=12, decimal_places=0, verbose_name="Montant remboursé")
    date_remboursement = models.DateTimeField(auto_now_add=True)
    reference = models.CharField(max_length=100, unique=True, verbose_name="Référence")
    statut = models.CharField(max_length=20, choices=[('en_attente', 'En attente'), ('effectue', 'Effectué')], default='effectue')
    fichier_pdf = models.FileField(upload_to='remboursements/', null=True, blank=True)

    def __str__(self):
        return f"Remboursement {self.reference} - {self.montant} FCFA"
from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
from datetime import timedelta
import secrets


class Utilisateur(AbstractUser):
    """Modèle utilisateur personnalisé pour LoyaSmart"""
    
    ROLE_CHOICES = [
        ('proprietaire', 'Propriétaire'),
        ('locataire', 'Locataire'),
        ('non_defini', 'Non défini'),
    ]
    
    # Champs supplémentaires
    telephone = models.CharField(max_length=20, unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='locataire')
    photo_profil = models.ImageField(upload_to='profils/', null=True, blank=True)
    date_inscription = models.DateTimeField(auto_now_add=True)
    derniere_connexion = models.DateTimeField(null=True, blank=True)
    est_actif = models.BooleanField(default=False)
    is_email_verified = models.BooleanField(default=False)
    email_confirmation_token = models.CharField(max_length=128, null=True, blank=True)
    
    # Pour permettre la connexion avec email
    email = models.EmailField(unique=True)
    
    # ⭐ NOUVEAUX CHAMPS POUR LE PROFIL COLOCATAIRE ⭐
    profil_colocataire_complet = models.BooleanField(default=False, verbose_name="Profil colocataire complété")
    filiere = models.CharField(max_length=200, blank=True, null=True, verbose_name="Filière")
    ville = models.CharField(max_length=100, blank=True, null=True, verbose_name="Ville")
    religion = models.CharField(max_length=100, blank=True, null=True, verbose_name="Religion")
    telephone_coloc = models.CharField(max_length=20, blank=True, null=True, verbose_name="Téléphone (colocation)")
    description_coloc = models.TextField(blank=True, null=True, verbose_name="Description (colocation)")

    solde = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        default=0,
        verbose_name="Solde disponible"
    )
    
    # ⭐ NOUVEAUX CHAMPS À AJOUTER ⭐
    fumeur = models.BooleanField(default=False, verbose_name="Fumeur")
    brutal = models.BooleanField(default=False, verbose_name="Brutal")
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name', 'last_name', 'telephone']
    
    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.get_role_display()})"
    
    class Meta:
        verbose_name = "Utilisateur"
        verbose_name_plural = "Utilisateurs"
    
    def generate_email_token(self):
        token = secrets.token_urlsafe(32)
        self.email_confirmation_token = token
        self.save(update_fields=['email_confirmation_token'])
        return token


class CodeOTP(models.Model):
    """Modèle pour stocker les codes OTP avec expiration de 5 minutes"""
    
    utilisateur = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='codes_otp',
        verbose_name="Utilisateur"
    )
    code = models.CharField(max_length=6, verbose_name="Code OTP")
    date_creation = models.DateTimeField(auto_now_add=True)
    est_utilise = models.BooleanField(default=False)
    
    def est_valide(self):
        """Vérifie si le code est valide (moins de 5 minutes et non utilisé)"""
        if self.est_utilise:
            return False
        expiration = self.date_creation + timedelta(minutes=5)
        return timezone.now() <= expiration
    
    def __str__(self):
        return f"Code OTP pour {self.utilisateur.email} - {self.code}"
    
    class Meta:
        verbose_name = "Code OTP"
        verbose_name_plural = "Codes OTP"
        ordering = ['-date_creation']


class SessionActive(models.Model):
    """Modèle pour suivre les sessions actives (connexions avec JWT)"""
    
    utilisateur = models.ForeignKey(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='sessions_actives',
        verbose_name="Utilisateur"
    )
    token = models.TextField(verbose_name="Token JWT")
    refresh_token = models.TextField(verbose_name="Refresh Token", null=True, blank=True)
    date_connexion = models.DateTimeField(auto_now_add=True)
    date_expiration = models.DateTimeField(verbose_name="Date d'expiration du token")
    ip_adresse = models.GenericIPAddressField(null=True, blank=True, verbose_name="Adresse IP")
    user_agent = models.TextField(null=True, blank=True, verbose_name="Navigateur/Appareil")
    est_active = models.BooleanField(default=True, verbose_name="Session active")
    
    def __str__(self):
        return f"Session de {self.utilisateur.email} - {self.date_connexion}"
    
    class Meta:
        verbose_name = "Session active"
        verbose_name_plural = "Sessions actives"
        ordering = ['-date_connexion']
        

class FCMToken(models.Model):
    utilisateur = models.OneToOneField(
        Utilisateur,
        on_delete=models.CASCADE,
        related_name='fcm_token'
    )

    token = models.CharField(max_length=255)

    est_actif = models.BooleanField(default=True)

    date_creation = models.DateTimeField(auto_now_add=True)

    date_modification = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Token FCM"
        verbose_name_plural = "Tokens FCM"

    def __str__(self):
        return f"{self.utilisateur.email} - {self.token[:20]}..."
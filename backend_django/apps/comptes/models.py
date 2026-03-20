from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
from datetime import timedelta

class Utilisateur(AbstractUser):
    """Modèle utilisateur personnalisé pour LoyaSmart"""
    
    ROLE_CHOICES = [
        ('proprietaire', 'Propriétaire'),
        ('locataire', 'Locataire'),
        # 'les_deux' retiré comme demandé
    ]
    
    # Champs supplémentaires
    telephone = models.CharField(max_length=20, unique=True)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='locataire')
    photo_profil = models.ImageField(upload_to='profils/', null=True, blank=True)
    date_inscription = models.DateTimeField(auto_now_add=True)
    derniere_connexion = models.DateTimeField(null=True, blank=True)
    est_actif = models.BooleanField(default=True)
    
    # Pour permettre la connexion avec email
    email = models.EmailField(unique=True)
    
    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name', 'last_name', 'telephone']
    
    def __str__(self):
        return f"{self.first_name} {self.last_name} ({self.get_role_display()})"
    
    class Meta:
        verbose_name = "Utilisateur"
        verbose_name_plural = "Utilisateurs"


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
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, PermissionsMixin
from django.utils import timezone
from datetime import timedelta
from .managers import UtilisateurManager


class Utilisateur(AbstractBaseUser, PermissionsMixin):

    # ======================
    # INFORMATIONS PRINCIPALES
    # ======================

    email = models.EmailField(
        unique=True,
        blank=True,
        null=True
    )

    telephone = models.CharField(
        max_length=20,
        unique=True,
        blank=False,
        null=False
    )

    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)

    # ======================
    # ROLE UTILISATEUR
    # ======================

    ROLE_CHOICES = [
        ("Locataire", "Locataire"),
        ("Proprietaire", "Propriétaire"),
    ]

    role = models.CharField(
        max_length=20,
        choices=ROLE_CHOICES,
        default="Locataire"
    )

    # ======================
    # SYSTEME OTP
    # ======================

    otp_code = models.CharField(
        max_length=6,
        blank=True,
        null=True
    )

    otp_created_at = models.DateTimeField(
        blank=True,
        null=True
    )

    otp_attempts = models.IntegerField(
        default=0
    )

    # ======================
    # STATUTS
    # ======================

    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)

    # ======================
    # DATE INSCRIPTION
    # ======================

    date_joined = models.DateTimeField(auto_now_add=True)

    # ======================
    # CONFIG AUTHENTIFICATION
    # ======================

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['nom', 'prenom', 'telephone']

    objects = UtilisateurManager()

    # ======================
    # METHODES UTILES
    # ======================

    def otp_is_expired(self):
        """
        Vérifie si l'OTP est expiré (5 minutes)
        """
        if not self.otp_created_at:
            return True

        expiration_time = self.otp_created_at + timedelta(minutes=5)

        return timezone.now() > expiration_time

    def reset_otp(self):
        """
        Réinitialise le code OTP
        """
        self.otp_code = None
        self.otp_attempts = 0
        self.otp_created_at = None
        self.save()

    def __str__(self):
        return self.email if self.email else self.telephone
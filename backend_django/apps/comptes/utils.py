from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
#from django.utils.http import urlsafe_base64_encode
#from django.utils.encoding import force_bytes
#from django.contrib.auth.tokens import default_token_generator
from datetime import timedelta
import random

from .models import CodeOTP

def envoyer_email_confirmation(user):
    """
    Envoie un email avec lien de vérification via token Django
    """

    # ✅ Générer le token (ton modèle le fait déjà)
    token = user.generate_email_token()

    # ✅ Lien vers DJANGO (IMPORTANT)
    lien_confirmation = f"{settings.SITE_URL}/api/comptes/verify-email/?token={token}"

    subject = "✅ Confirmez votre compte LoyaSmart"
    message = f"""
Bonjour {user.first_name},

Merci de vous être inscrit sur LoyaSmart 🚀

Cliquez sur le lien ci-dessous pour vérifier votre email :
{lien_confirmation}

Si vous n'êtes pas à l'origine de cette inscription, ignorez cet email.
"""

    send_mail(
        subject,
        message,
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        fail_silently=False
    )


def envoyer_email_bienvenue(user):
    """
    Envoie un email de bienvenue après confirmation du compte
    """
    subject = "🎉 Bienvenue sur LoyaSmart !"
    message = f"""
Bonjour {user.first_name},

Votre compte LoyaSmart a été créé avec succès ! 🎉

Vous pouvez maintenant accéder à toutes les fonctionnalités de notre application de gestion locative.

Nous sommes ravis de vous compter parmi nous !

LoyaSmart 🚀
    """
    send_mail(
        subject,
        message,
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        fail_silently=False
    )


def envoyer_email_mot_de_passe_modifie(user):
    """
    Envoie un email de confirmation après modification du mot de passe
    """
    subject = "🔐 Votre mot de passe a été modifié - LoyaSmart"
    message = f"""
Bonjour {user.first_name},

Votre mot de passe a été modifié avec succès sur LoyaSmart. ✅

Si vous n'êtes pas à l'origine de cette modification, veuillez contacter notre support immédiatement.

Si c'était bien vous, ignorez cet email.

LoyaSmart - Gestion locative intelligente 🚀
    """
    
    send_mail(
        subject,
        message,
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        fail_silently=False
    )


def generer_code_otp():
    """
    Génère un code OTP à 6 chiffres
    """
    return ''.join([str(random.randint(0, 9)) for _ in range(6)])


def envoyer_code_otp(user, otp_code, duree_minutes=2):
    """
    Envoie un code OTP par email avec mention de la durée d'expiration
    """
    message = f"""
Bonjour {user.first_name},

Vous avez demandé à réinitialiser votre mot de passe LoyaSmart.

Votre code de vérification est : {otp_code}

⏰ Ce code est valable {duree_minutes} minutes. Passé ce délai, vous devrez faire une nouvelle demande.

Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.

LoyaSmart - Gestion locative intelligente
    """
    
    send_mail(
        "🔐 Code de vérification LoyaSmart",
        message,
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        fail_silently=False
    )


def creer_et_envoyer_otp(user, duree_minutes=2):
    """
    Génère un OTP, l'enregistre dans la table CodeOTP et l'envoie par email
    """
    # Invalider les anciens OTP non utilisés
    CodeOTP.objects.filter(utilisateur=user, est_utilise=False).update(est_utilise=True)
    
    # Générer un nouveau code
    otp_code = generer_code_otp()
    
    # Créer l'objet OTP en DB
    CodeOTP.objects.create(utilisateur=user, code=otp_code)
    
    # Envoyer l'email
    envoyer_code_otp(user, otp_code, duree_minutes=duree_minutes)
    
    return otp_code
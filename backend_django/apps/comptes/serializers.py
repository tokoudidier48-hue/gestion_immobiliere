from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.conf import settings
from .models import Utilisateur, CodeOTP, SessionActive
import random
import requests
from django.contrib.auth import authenticate

class InscriptionSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)
    
    class Meta:
        model = Utilisateur
        fields = ('email', 'first_name', 'last_name', 'telephone', 'role', 'password', 'password2')
    
    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError({"password": "Les mots de passe ne correspondent pas."})
        return attrs
    
    def create(self, validated_data):
        from django.utils.http import urlsafe_base64_encode
        from django.utils.encoding import force_bytes
        from django.contrib.auth.tokens import default_token_generator
        
        validated_data.pop('password2')
        user = Utilisateur.objects.create_user(
            username=validated_data['email'],
            **validated_data
        )
        
        # ⭐ Générer le token et l'uid pour la confirmation
        token = default_token_generator.make_token(user)
        uid = urlsafe_base64_encode(force_bytes(user.pk))
        
        # ⭐ Construire le lien de confirmation
        confirmation_url = f"{settings.FRONTEND_URL}/confirmer-email/{uid}/{token}/"
        
        # ⭐ Envoyer l'email de confirmation
        send_mail(
            subject='✅ Confirmez votre compte LoyaSmart',
            message=f"""
Bonjour {user.first_name},

Merci de vous être inscrit sur LoyaSmart - Gestion locative intelligente !

Pour activer votre compte, cliquez sur le lien ci-dessous :
{confirmation_url}

Si vous n'êtes pas à l'origine de cette inscription, ignorez cet email.

LoyaSmart 🚀
            """,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False,
        )
        
        return user


class ConnexionSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class SocialLoginSerializer(serializers.Serializer):
    access_token = serializers.CharField()
    provider = serializers.CharField()
    
    def validate(self, attrs):
        provider = attrs.get('provider')
        access_token = attrs.get('access_token')
        
        if provider == 'google':
            # Vérifier le token avec Google
            response = requests.get(
                f'https://www.googleapis.com/oauth2/v3/tokeninfo?access_token={access_token}'
            )
            if response.status_code != 200:
                raise serializers.ValidationError("Token Google invalide")
            
            user_data = response.json()
            email = user_data.get('email')
            first_name = user_data.get('given_name', '')
            last_name = user_data.get('family_name', '')
            photo = user_data.get('picture', '')
            
            if not email:
                raise serializers.ValidationError("Email non trouvé")
            
            # Créer ou récupérer l'utilisateur
            user, created = Utilisateur.objects.get_or_create(
                email=email,
                defaults={
                    'first_name': first_name,
                    'last_name': last_name,
                    'username': email,
                    'telephone': '',
                    'role': 'non_defini',   # ← NOUVEAU RÔLE
                    'is_active': True,
                    'est_actif': True,
                }
            )
            
            if not created and not user.photo_profil and photo:
                # Sauvegarder la photo de profil si disponible
                img_response = requests.get(photo)
                if img_response.status_code == 200:
                    from django.core.files.base import ContentFile
                    user.photo_profil.save(f'{user.email}_profile.jpg', ContentFile(img_response.content))
            
            attrs['user'] = user
            
        elif provider == 'facebook':
            raise serializers.ValidationError("Facebook non encore configuré")
        else:
            raise serializers.ValidationError("Fournisseur non supporté")
        
        return attrs


class MotDePasseOublieSerializer(serializers.Serializer):
    email = serializers.EmailField()
    
    def validate_email(self, value):
        try:
            user = Utilisateur.objects.get(email=value)
        except Utilisateur.DoesNotExist:
            raise serializers.ValidationError("Aucun utilisateur avec cet email.")
        return value
    
    def save(self):
        email = self.validated_data['email']
        user = Utilisateur.objects.get(email=email)
        
        # Générer un code OTP à 6 chiffres
        otp_code = ''.join([str(random.randint(0, 9)) for _ in range(6)])
        
        # Invalider les anciens codes non utilisés
        CodeOTP.objects.filter(utilisateur=user, est_utilise=False).update(est_utilise=True)
        
        # Créer un nouveau code OTP
        CodeOTP.objects.create(
            utilisateur=user,
            code=otp_code
        )
        
        # Envoyer l'email
        send_mail(
            '🔐 Code de réinitialisation LoyaSmart',
            f"""
Bonjour {user.first_name},

Vous avez demandé à réinitialiser votre mot de passe LoyaSmart.

Votre code de vérification est : {otp_code}

⏰ Ce code est valable 2 minutes.

Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.

LoyaSmart - Gestion locative intelligente
            """,
            settings.DEFAULT_FROM_EMAIL,
            [email],
            fail_silently=False,
        )
        
        return {"message": "Code envoyé avec succès"}


class VerifierCodeOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)
    
    def validate(self, attrs):
        email = attrs['email']
        code = attrs['code']
        
        try:
            from django.utils import timezone
            from datetime import timedelta
            
            user = Utilisateur.objects.get(email=email)
            otp_code = CodeOTP.objects.filter(
                utilisateur=user, 
                code=code, 
                est_utilise=False,
                date_creation__gte=timezone.now() - timedelta(minutes=2)
            ).last()
            
            if not otp_code:
                raise serializers.ValidationError("Le code a expiré (valable 2 minutes).")
            
            attrs['user'] = user
            attrs['otp_code'] = otp_code
            
        except Utilisateur.DoesNotExist:
            raise serializers.ValidationError("Email invalide.")
        
        return attrs


class NouveauMotDePasseSerializer(serializers.Serializer):
    email = serializers.EmailField(required=False)
    code = serializers.CharField(max_length=6, required=False)
    nouveau_password = serializers.CharField(write_only=True, validators=[validate_password])
    nouveau_password2 = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        if attrs['nouveau_password'] != attrs['nouveau_password2']:
            raise serializers.ValidationError({"nouveau_password": "Les mots de passe ne correspondent pas."})
        
        if 'email' not in attrs or 'code' not in attrs:
            raise serializers.ValidationError("Session expirée. Veuillez recommencer le processus.")
        
        try:
            from django.utils import timezone
            from datetime import timedelta
            
            user = Utilisateur.objects.get(email=attrs['email'])
            otp_code = CodeOTP.objects.filter(
                utilisateur=user, 
                code=attrs['code'], 
                est_utilise=False,
                date_creation__gte=timezone.now() - timedelta(minutes=2)
            ).last()
            
            if not otp_code:
                raise serializers.ValidationError("Le code a expiré (valable 2 minutes).")
            
            attrs['user'] = user
            attrs['otp_code'] = otp_code
            
        except Utilisateur.DoesNotExist:
            raise serializers.ValidationError("Email invalide.")
        
        return attrs
    
    def save(self):
        user = self.validated_data['user']
        otp_code = self.validated_data['otp_code']
        nouveau_password = self.validated_data['nouveau_password']
        
        otp_code.est_utilise = True
        otp_code.save()
        
        user.set_password(nouveau_password)
        user.save()
        
        return user
        

class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = (
            'id', 'email', 'first_name', 'last_name', 'telephone', 'role', 
            'photo_profil', 'derniere_connexion',
            'filiere', 'ville', 'religion', 'telephone_coloc', 'description_coloc',
            'fumeur', 'brutal',  # ← AJOUTER ICI
            'profil_colocataire_complet'
        )
        read_only_fields = ('derniere_connexion', 'profil_colocataire_complet')


class SessionSerializer(serializers.ModelSerializer):
    utilisateur_nom = serializers.CharField(source='utilisateur.get_full_name', read_only=True)
    
    class Meta:
        model = SessionActive
        fields = [
            'id', 'utilisateur', 'utilisateur_nom', 'date_connexion',
            'date_expiration', 'ip_adresse', 'user_agent', 'est_active'
        ]
        read_only_fields = ['id', 'date_connexion', 'date_expiration']


class SupprimerCompteSerializer(serializers.Serializer):
    password = serializers.CharField(write_only=True)

    def validate_password(self, value):
        request = self.context.get('request')
        user = request.user
        if not authenticate(username=user.email, password=value):
            raise serializers.ValidationError("Mot de passe incorrect.")
        return value
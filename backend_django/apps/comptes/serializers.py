from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.mail import send_mail
from django.conf import settings
from .models import Utilisateur, CodeOTP
import random

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
        validated_data.pop('password2')
        user = Utilisateur.objects.create_user(
            username=validated_data['email'],  # On utilise l'email comme username
            **validated_data
        )
        return user


class ConnexionSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


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

Ce code est valable 5 minutes.

Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.

LoyaSmart - Gestion locative intelligente
            """,
            settings.EMAIL_HOST_USER,
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
            user = Utilisateur.objects.get(email=email)
            otp_code = CodeOTP.objects.filter(
                utilisateur=user, 
                code=code, 
                est_utilise=False
            ).latest('date_creation')
            
            if not otp_code.est_valide():
                raise serializers.ValidationError("Le code a expiré (plus de 5 minutes).")
            
            attrs['user'] = user
            attrs['otp_code'] = otp_code
            
        except Utilisateur.DoesNotExist:
            raise serializers.ValidationError("Email invalide.")
        except CodeOTP.DoesNotExist:
            raise serializers.ValidationError("Code invalide.")
        
        return attrs


class NouveauMotDePasseSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)
    nouveau_password = serializers.CharField(write_only=True, validators=[validate_password])
    nouveau_password2 = serializers.CharField(write_only=True)
    
    def validate(self, attrs):
        if attrs['nouveau_password'] != attrs['nouveau_password2']:
            raise serializers.ValidationError({"nouveau_password": "Les mots de passe ne correspondent pas."})
        
        # Vérifier le code
        try:
            user = Utilisateur.objects.get(email=attrs['email'])
            otp_code = CodeOTP.objects.filter(
                utilisateur=user, 
                code=attrs['code'], 
                est_utilise=False
            ).latest('date_creation')
            
            if not otp_code.est_valide():
                raise serializers.ValidationError("Le code a expiré (plus de 5 minutes).")
            
            attrs['user'] = user
            attrs['otp_code'] = otp_code
            
        except Utilisateur.DoesNotExist:
            raise serializers.ValidationError("Email invalide.")
        except CodeOTP.DoesNotExist:
            raise serializers.ValidationError("Code invalide.")
        
        return attrs
    
    def save(self):
        user = self.validated_data['user']
        otp_code = self.validated_data['otp_code']
        nouveau_password = self.validated_data['nouveau_password']
        
        # Marquer le code comme utilisé
        otp_code.est_utilise = True
        otp_code.save()
        
        # Changer le mot de passe
        user.set_password(nouveau_password)
        user.save()
        
        return user


class UtilisateurSerializer(serializers.ModelSerializer):
    class Meta:
        model = Utilisateur
        fields = ('id', 'email', 'first_name', 'last_name', 'telephone', 'role', 'photo_profil')
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.utils import timezone
from django.utils.http import urlsafe_base64_decode
from django.utils.encoding import force_str
from django.contrib.auth.tokens import default_token_generator
from datetime import timedelta
from django.shortcuts import render
from .models import FCMToken
from rest_framework.views import APIView
from django.shortcuts import redirect
from django.conf import settings
from rest_framework import generics
from rest_framework.response import Response
from django.core.mail import EmailMessage
from rest_framework.generics import DestroyAPIView
from django.contrib.auth import authenticate

import uuid
from .serializers import (
    InscriptionSerializer, ConnexionSerializer, 
    MotDePasseOublieSerializer, VerifierCodeOTPSerializer,
    NouveauMotDePasseSerializer, UtilisateurSerializer, SessionSerializer,
    SocialLoginSerializer
)
from .models import Utilisateur, CodeOTP, SessionActive, FCMToken
from .utils import (
    envoyer_email_bienvenue, creer_et_envoyer_otp, envoyer_email_confirmation,
    envoyer_email_mot_de_passe_modifie
)

class InscriptionView(generics.CreateAPIView):
    queryset = Utilisateur.objects.all()
    serializer_class = InscriptionSerializer
    permission_classes = [AllowAny]
    
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Désactiver le compte jusqu'à confirmation email
        user.is_active = False
        user.est_actif = False
        user.save()

        # Pour la confirmation email
        envoyer_email_confirmation(user)
        
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'user': UtilisateurSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }, status=status.HTTP_201_CREATED)
    

class VerifyEmailView(generics.GenericAPIView):
    permission_classes = [AllowAny]

    def get(self, request):
        token = request.query_params.get('token')

        if not token:
            return self._handle_response(request, success=False, message="Token manquant")

        # ⚠️ Supprimer slash éventuel
        token = token.rstrip("/")

        try:
            user = Utilisateur.objects.get(email_confirmation_token=token)

            if user.est_actif:
                return self._handle_response(request, success=True, message="Email déjà vérifié")

            # Activer le compte
            user.is_active = True
            user.est_actif = True
            user.email_confirmation_token = None
            user.save()

            # Envoyer email bienvenue
            envoyer_email_bienvenue(user)

            return self._handle_response(request, success=True, message="Email vérifié avec succès")

        except Utilisateur.DoesNotExist:
            return self._handle_response(request, success=False, message="Utilisateur non trouvé")

    def _handle_response(self, request, success, message):
        user_agent = request.META.get("HTTP_USER_AGENT", "").lower()
        if "postman" in user_agent or "python" in user_agent or "flutter" in user_agent:
            return Response({"success": success, "message": message})

        return render(request, "email_verified.html", {"success": success, "message": message})


class ConnexionView(generics.GenericAPIView):
    serializer_class = ConnexionSerializer
    permission_classes = [AllowAny]
    
    def _get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']
        
        user = authenticate(request, username=email, password=password)
        
        if user is not None:
            if not user.est_actif:
                return Response({
                    'error': 'Veuillez vérifier votre email avant de vous connecter.'
                }, status=status.HTTP_403_FORBIDDEN)
            user.derniere_connexion = timezone.now()
            user.save(update_fields=['derniere_connexion'])
            
            refresh = RefreshToken.for_user(user)
            access_token = str(refresh.access_token)
            refresh_token = str(refresh)
            expiration_date = timezone.now() + timedelta(days=1)
            
            SessionActive.objects.create(
                utilisateur=user,
                token=access_token,
                refresh_token=refresh_token,
                date_expiration=expiration_date,
                ip_adresse=self._get_client_ip(request),
                user_agent=request.META.get('HTTP_USER_AGENT', '')[:500],
                est_active=True
            )
            
            return Response({
                'user': UtilisateurSerializer(user).data,
                'refresh': refresh_token,
                'access': access_token,
            })
        else:
            return Response({'error': 'Email ou mot de passe incorrect'}, 
                          status=status.HTTP_401_UNAUTHORIZED)


class SocialLoginView(generics.GenericAPIView):
    serializer_class = SocialLoginSerializer
    permission_classes = [AllowAny]
    
    def _get_client_ip(self, request):
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR')
        return ip
    
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        user = serializer.validated_data['user']
        user.derniere_connexion = timezone.now()
        user.save(update_fields=['derniere_connexion'])
        
        refresh = RefreshToken.for_user(user)
        access_token = str(refresh.access_token)
        refresh_token = str(refresh)
        expiration_date = timezone.now() + timedelta(days=1)
        
        SessionActive.objects.create(
            utilisateur=user,
            token=access_token,
            refresh_token=refresh_token,
            date_expiration=expiration_date,
            ip_adresse=self._get_client_ip(request),
            user_agent=request.META.get('HTTP_USER_AGENT', '')[:500],
            est_active=True
        )
        
        return Response({
            'user': UtilisateurSerializer(user).data,
            'refresh': refresh_token,
            'access': access_token,
        })


class MotDePasseOublieView(generics.GenericAPIView):
    serializer_class = MotDePasseOublieSerializer
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        email = serializer.validated_data['email']
        user = Utilisateur.objects.filter(email=email).first()
        if not user:
            return Response({'error': 'Utilisateur introuvable'}, status=status.HTTP_404_NOT_FOUND)
        
        # Créer et envoyer OTP (expiration 2 minutes)
        otp_code = creer_et_envoyer_otp(user, duree_minutes=2)
        
        return Response({
            'message': 'Code de vérification envoyé par email',
            'expiration_minutes': 2,
            'otp_code': otp_code
        })


class VerifierCodeView(generics.GenericAPIView):
    serializer_class = VerifierCodeOTPSerializer
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        code = serializer.validated_data['code']
        user = Utilisateur.objects.filter(email=email).first()
        
        # Vérifier l'OTP (valide pendant 2 minutes)
        otp = CodeOTP.objects.filter(
            utilisateur=user, 
            code=code,
            date_creation__gte=timezone.now() - timedelta(minutes=2),
            est_utilise=False
        ).last()
        
        if not otp:
            return Response({'error': 'Code invalide ou expiré (valable 2 minutes)'}, status=status.HTTP_400_BAD_REQUEST)
        
        # STOCKER EN SESSION POUR L'ÉTAPE SUIVANTE
        request.session['reset_email'] = email
        request.session['reset_code'] = code
        
        return Response({'message': 'Code valide'})


class NouveauMotDePasseView(generics.GenericAPIView):
    serializer_class = NouveauMotDePasseSerializer
    permission_classes = [AllowAny]
    
    def post(self, request):
        # RÉCUPÉRER L'EMAIL ET LE CODE DEPUIS LA SESSION
        email = request.session.get('reset_email')
        code = request.session.get('reset_code')
        
        # Vérifier que la session est valide
        if not email or not code:
            return Response({
                'error': 'Session expirée ou invalide. Veuillez recommencer le processus.'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # AJOUTER EMAIL ET CODE AUX DONNÉES REÇUES
        data = request.data.copy()
        data['email'] = email
        data['code'] = code
        
        serializer = self.get_serializer(data=data)
        serializer.is_valid(raise_exception=True)
        
        # Sauvegarder le nouveau mot de passe
        user = serializer.save()
        
        # NETTOYER LA SESSION
        del request.session['reset_email']
        del request.session['reset_code']
        
        # Invalider tous les OTP de l'utilisateur après changement de mot de passe
        if user:
            CodeOTP.objects.filter(utilisateur=user, est_utilise=False).update(est_utilise=True)
            
            # Envoyer email de confirmation de modification du mot de passe
            envoyer_email_mot_de_passe_modifie(user)
        
        return Response({'message': 'Mot de passe modifié avec succès'})
    
import logging
logger = logging.getLogger("comptes")


class TestSMTPDebugView(generics.GenericAPIView):
    permission_classes = [AllowAny]

    def get(self, request):
        try:
            logger.info("SMTP TEST START")

            email = EmailMessage(
                subject="TEST BREVO FULL DEBUG",
                body="Test livraison réelle",
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=["loyasmart26@gmail.com"],
            )

            result = email.send(fail_silently=False)

            logger.info(f"SMTP RESULT = {result}")
            logger.info(f"FROM = {settings.DEFAULT_FROM_EMAIL}")

            return Response({
                "success": True,
                "result": result,
                "from": settings.DEFAULT_FROM_EMAIL
            })

        except Exception as e:
            logger.exception("SMTP ERROR")
            return Response({
                "success": False,
                "error": str(e)
            })
        
class ProfilView(generics.RetrieveUpdateAPIView):
    serializer_class = UtilisateurSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user


class DeconnexionView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        auth_header = request.headers.get('Authorization', '')
        token = auth_header.replace('Bearer ', '')
        
        session = SessionActive.objects.filter(
            utilisateur=request.user,
            token=token,
            est_active=True
        ).first()
        
        if session:
            session.est_active = False
            session.save()
        
        return Response({'message': 'Déconnexion réussie'})


class SessionsView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SessionSerializer
    
    def get_queryset(self):
        return SessionActive.objects.filter(
            utilisateur=self.request.user,
            est_active=True
        )


class UtilisateurEnLigneView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, user_id=None):
        if user_id:
            try:
                user = Utilisateur.objects.get(id=user_id)
                session_active = SessionActive.objects.filter(
                    utilisateur=user,
                    est_active=True,
                    date_expiration__gt=timezone.now()
                ).exists()
                
                return Response({
                    'user_id': user_id,
                    'est_en_ligne': session_active,
                    'derniere_connexion': user.derniere_connexion
                })
            except Utilisateur.DoesNotExist:
                return Response({'error': 'Utilisateur non trouvé'}, status=404)
        else:
            session_active = SessionActive.objects.filter(
                utilisateur=request.user,
                est_active=True,
                date_expiration__gt=timezone.now()
            ).exists()
            
            return Response({
                'est_en_ligne': session_active,
                'derniere_connexion': request.user.derniere_connexion
            })


class RevokeSessionView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request, session_id):
        session = SessionActive.objects.filter(
            utilisateur=request.user,
            id=session_id,
            est_active=True
        ).first()
        
        if session:
            session.est_active = False
            session.save()
            return Response({'message': 'Session révoquée'})
        
        return Response({'error': 'Session non trouvée'}, status=status.HTTP_404_NOT_FOUND)


class EnregistrerFCMTokenView(generics.GenericAPIView):
    permission_classes = [IsAuthenticated]
    
    def post(self, request):
        # Extraire le token correctement
        token = request.data.get('token')
        
        if not token:
            return Response(
                {"error": "Le token FCM est requis"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            obj, created = FCMToken.objects.update_or_create(
                utilisateur=request.user,
                defaults={'token': token, 'est_actif': True}
            )
            
            return Response(
                {"message": "Token enregistré avec succès", "created": created},
                status=status.HTTP_200_OK
            )
        except Exception as e:
            return Response(
                {"error": f"Erreur lors de l'enregistrement: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
            

class CompleterProfilColocataireView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        data = request.data

        # Récupérer les champs
        filiere = data.get('filiere', user.filiere)
        ville = data.get('ville', user.ville)
        religion = data.get('religion', user.religion)
        telephone_coloc = data.get('telephone', '').strip()
        description = data.get('description', user.description_coloc)

        # ⭐ Vérifier que le numéro est fourni
        if not telephone_coloc:
            return Response(
                {'error': 'Le numéro de téléphone est requis.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # ⭐ Mettre à jour les champs (sans validation de correspondance)
        user.filiere = filiere
        user.ville = ville
        user.religion = religion
        user.telephone_coloc = telephone_coloc   # ← le nouveau numéro (ou le même)
        user.description_coloc = description
        user.profil_colocataire_complet = True
        user.save()

        return Response({
            'message': 'Profil colocataire complété avec succès',
            'data': {
                'filiere': user.filiere,
                'ville': user.ville,
                'religion': user.religion,
                'telephone_coloc': user.telephone_coloc,
                'description': user.description_coloc
            }
        }, status=status.HTTP_200_OK)
    
# ⭐ AJOUTER CETTE NOUVELLE VUE POUR LA MODIFICATION DE PROFIL ⭐
class ModifierProfilView(APIView):
    permission_classes = [IsAuthenticated]
    
    def put(self, request):
        user = request.user
        data = request.data
        
        # Champs autorisés pour modification
        allowed_fields = [
            'first_name', 'last_name', 'telephone',
            'filiere', 'ville', 'religion', 'telephone_coloc', 'description_coloc',
            'fumeur', 'brutal'
        ]
        
        for field in allowed_fields:
            if field in data:
                setattr(user, field, data[field])
        
        user.save()
        serializer = UtilisateurSerializer(user)
        return Response(serializer.data, status=status.HTTP_200_OK)


class SupprimerCompteView(DestroyAPIView):
    permission_classes = [IsAuthenticated]

    def destroy(self, request, *args, **kwargs):
        user = self.request.user
        password = request.data.get('password')

        # Vérifier le mot de passe
        if not password:
            return Response({'error': 'Le mot de passe est requis.'}, status=status.HTTP_400_BAD_REQUEST)

        if not authenticate(username=user.email, password=password):
            return Response({'error': 'Mot de passe incorrect.'}, status=status.HTTP_400_BAD_REQUEST)

        # Supprimer le compte
        user.delete()
        return Response({'message': 'Votre compte a été supprimé avec succès.'}, status=status.HTTP_204_NO_CONTENT)


class SoldeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        if user.role != 'proprietaire':
            return Response({'error': 'Seuls les propriétaires peuvent voir leur solde.'}, status=403)
        
        return Response({
            'solde': int(user.solde),
            'devise': 'FCFA'
        })
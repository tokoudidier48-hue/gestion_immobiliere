from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .serializers import (
    InscriptionSerializer, ConnexionSerializer, 
    MotDePasseOublieSerializer, VerifierCodeOTPSerializer,
    NouveauMotDePasseSerializer, UtilisateurSerializer
)
from .models import Utilisateur

class InscriptionView(generics.CreateAPIView):
    queryset = Utilisateur.objects.all()
    serializer_class = InscriptionSerializer
    permission_classes = [AllowAny]
    
    def post(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        
        # Générer token JWT
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'user': UtilisateurSerializer(user).data,
            'refresh': str(refresh),
            'access': str(refresh.access_token),
        }, status=status.HTTP_201_CREATED)


class ConnexionView(generics.GenericAPIView):
    serializer_class = ConnexionSerializer
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        email = serializer.validated_data['email']
        password = serializer.validated_data['password']
        
        user = authenticate(request, username=email, password=password)
        
        if user is not None:
            refresh = RefreshToken.for_user(user)
            return Response({
                'user': UtilisateurSerializer(user).data,
                'refresh': str(refresh),
                'access': str(refresh.access_token),
            })
        else:
            return Response({'error': 'Email ou mot de passe incorrect'}, 
                          status=status.HTTP_401_UNAUTHORIZED)


class MotDePasseOublieView(generics.GenericAPIView):
    serializer_class = MotDePasseOublieSerializer
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Envoyer le code OTP
        resultat = serializer.save()
        
        # Ne pas retourner le code en production !
        return Response({
            'message': 'Code de vérification envoyé par email'
        })


class VerifierCodeView(generics.GenericAPIView):
    serializer_class = VerifierCodeOTPSerializer
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        return Response({'message': 'Code valide'})


class NouveauMotDePasseView(generics.GenericAPIView):
    serializer_class = NouveauMotDePasseSerializer
    permission_classes = [AllowAny]
    
    def post(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        serializer.save()
        return Response({'message': 'Mot de passe modifié avec succès'})


class ProfilView(generics.RetrieveUpdateAPIView):
    serializer_class = UtilisateurSerializer
    permission_classes = [IsAuthenticated]
    
    def get_object(self):
        return self.request.user
from rest_framework import generics, status
from rest_framework.response import Response
from django.contrib.auth import authenticate
from django.utils import timezone
from datetime import timedelta
from django.contrib.auth.hashers import make_password
from rest_framework_simplejwt.tokens import RefreshToken

from .models import Utilisateur
from .serializers import (
    RegisterSerializer,
    LoginSerializer,
    ForgotPasswordSerializer,
    VerifyOTPSerializer,
    ResetPasswordSerializer
)
from .utils import generate_otp, send_email


# ====================
# REGISTER
# ====================
class RegisterView(generics.CreateAPIView):
    serializer_class = RegisterSerializer


# ====================
# LOGIN
# ====================
class LoginView(generics.GenericAPIView):

    serializer_class = LoginSerializer

    def post(self, request):

        email = request.data.get('email')
        password = request.data.get('password')

        user = authenticate(request, email=email, password=password)

        if user:
            refresh = RefreshToken.for_user(user)

            return Response({
                "refresh": str(refresh),
                "access": str(refresh.access_token),
                "user_id": user.id,
                "email": user.email,
                "telephone": user.telephone,
                "role": user.role
            })

        return Response(
            {"detail": "Email ou mot de passe incorrect"},
            status=status.HTTP_401_UNAUTHORIZED
        )


# ====================
# FORGOT PASSWORD
# ====================
class ForgotPasswordView(generics.GenericAPIView):

    serializer_class = ForgotPasswordSerializer

    def post(self, request):

        email = request.data.get("email")

        if not email:
            return Response(
                {"detail": "Email requis"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = Utilisateur.objects.get(email=email)

        except Utilisateur.DoesNotExist:
            return Response(
                {"detail": "Utilisateur introuvable"},
                status=status.HTTP_404_NOT_FOUND
            )

        otp = generate_otp()

        user.otp_code = otp
        user.otp_created_at = timezone.now()
        user.otp_attempts = 0
        user.save()

        try:
            subject = "Code OTP LoyaSmart"
            message = f"Votre code OTP est : {otp}"

            send_email(subject, message, [email])

        except Exception as e:
            return Response(
                {"detail": f"Erreur envoi email : {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        return Response({
            "detail": "OTP envoyé à votre email"
        })


# ====================
# VERIFY OTP
# ====================
class VerifyOTPView(generics.GenericAPIView):

    serializer_class = VerifyOTPSerializer

    def post(self, request):

        email = request.data.get("email")
        otp = request.data.get("otp")

        if not email or not otp:
            return Response(
                {"detail": "Email et OTP requis"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = Utilisateur.objects.get(email=email)

        except Utilisateur.DoesNotExist:
            return Response(
                {"detail": "Utilisateur introuvable"},
                status=status.HTTP_404_NOT_FOUND
            )

        if user.otp_created_at + timedelta(minutes=5) < timezone.now():
            return Response(
                {"detail": "OTP expiré"},
                status=status.HTTP_400_BAD_REQUEST
            )

        if user.otp_attempts >= 5:
            return Response(
                {"detail": "Trop de tentatives"},
                status=status.HTTP_403_FORBIDDEN
            )

        if str(user.otp_code) != str(otp):

            user.otp_attempts += 1
            user.save()

            return Response(
                {"detail": "OTP incorrect"},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.otp_code = None
        user.otp_attempts = 0
        user.save()

        return Response({
            "detail": "OTP vérifié avec succès"
        })


# ====================
# RESET PASSWORD
# ====================
class ResetPasswordView(generics.GenericAPIView):

    serializer_class = ResetPasswordSerializer

    def post(self, request):

        email = request.data.get("email")
        new_password = request.data.get("new_password")

        if not email or not new_password:
            return Response(
                {"detail": "Email et nouveau mot de passe requis"},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            user = Utilisateur.objects.get(email=email)

        except Utilisateur.DoesNotExist:
            return Response(
                {"detail": "Utilisateur introuvable"},
                status=status.HTTP_404_NOT_FOUND
            )

        user.password = make_password(new_password)
        user.otp_code = None
        user.otp_attempts = 0
        user.save()

        return Response({
            "detail": "Mot de passe réinitialisé avec succès"
        })
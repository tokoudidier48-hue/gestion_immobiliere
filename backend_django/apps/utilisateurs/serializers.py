from rest_framework import serializers
from .models import Utilisateur
from django.contrib.auth.password_validation import validate_password


class RegisterSerializer(serializers.ModelSerializer):

    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password]
    )

    class Meta:
        model = Utilisateur
        fields = [
            "email",
            "telephone",
            "nom",
            "prenom",
            "password",
            "role"
        ]

    def create(self, validated_data):

        user = Utilisateur.objects.create_user(
            email=validated_data.get("email"),
            telephone=validated_data.get("telephone"),
            nom=validated_data.get("nom"),
            prenom=validated_data.get("prenom"),
            role=validated_data.get("role"),
            password=validated_data.get("password")
        )

        return user


class LoginSerializer(serializers.Serializer):

    email = serializers.EmailField(required=False)
    telephone = serializers.CharField(required=False)

    password = serializers.CharField(write_only=True)


class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()


class VerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField()
    otp = serializers.CharField()


class ResetPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()
    new_password = serializers.CharField()
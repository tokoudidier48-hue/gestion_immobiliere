from django.contrib.auth.base_user import BaseUserManager

class UtilisateurManager(BaseUserManager):

    def create_user(self, email, password=None, role='Locataire', **extra_fields):
        if not email:
            raise ValueError("L'utilisateur doit avoir un email")

        email = self.normalize_email(email)
        user = self.model(email=email, role=role, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)

        return self.create_user(email, password, role='Proprietaire', **extra_fields)
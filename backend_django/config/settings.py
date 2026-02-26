"""
Django settings for gestion_immobiliere project.
"""

from pathlib import Path
import os

# -------------------------------------------------------------------
# BASE DIRECTORY
# -------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent


# -------------------------------------------------------------------
# SECURITY
# -------------------------------------------------------------------
SECRET_KEY = 'change-moi-en-production'

DEBUG = True

ALLOWED_HOSTS = []


# -------------------------------------------------------------------
# APPLICATIONS
# -------------------------------------------------------------------
INSTALLED_APPS = [

    # Django apps
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third-party apps
    'rest_framework',

    # Local apps
    'apps.utilisateurs',
    'apps.proprietes',
    'apps.reservations',
    'apps.contrats',
    'apps.paiements',
    'apps.messagerie',
    'apps.notifications',
    'apps.intelligence_artificielle',
    'apps.rappels_loyer',
    'apps.administration',
]


# -------------------------------------------------------------------
# MIDDLEWARE
# -------------------------------------------------------------------
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]


# -------------------------------------------------------------------
# URLS & WSGI
# -------------------------------------------------------------------
ROOT_URLCONF = 'config.urls'

WSGI_APPLICATION = 'config.wsgi.application'


# -------------------------------------------------------------------
# DATABASE (POSTGRESQL)
# -------------------------------------------------------------------
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'gestion_immobiliere',
        'USER': 'postgres',
        'PASSWORD': 'ton_mot_de_passe',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}


# -------------------------------------------------------------------
# PASSWORD VALIDATION
# -------------------------------------------------------------------
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# -------------------------------------------------------------------
# INTERNATIONALISATION
# -------------------------------------------------------------------
LANGUAGE_CODE = 'fr-fr'

TIME_ZONE = 'Africa/Porto-Novo'

USE_I18N = True
USE_TZ = True


# -------------------------------------------------------------------
# STATIC & MEDIA FILES
# -------------------------------------------------------------------
STATIC_URL = '/static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')

MEDIA_URL = '/media/'
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')


# -------------------------------------------------------------------
# CUSTOM USER MODEL
# -------------------------------------------------------------------
AUTH_USER_MODEL = 'utilisateurs.Utilisateur'


# -------------------------------------------------------------------
# DJANGO REST FRAMEWORK CONFIGURATION
# -------------------------------------------------------------------
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.AllowAny',
    ),
}


# -------------------------------------------------------------------
# DEFAULT PRIMARY KEY
# -------------------------------------------------------------------
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
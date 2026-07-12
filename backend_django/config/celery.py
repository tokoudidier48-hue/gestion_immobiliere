from __future__ import absolute_import, unicode_literals
import os
from celery import Celery

# Indiquer à Celery où se trouve le fichier de configuration Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('config')

# Charger la configuration depuis les variables Django commençant par CELERY_
app.config_from_object('django.conf:settings', namespace='CELERY')

# Découvrir automatiquement les tâches dans toutes les applications Django installées
app.autodiscover_tasks()
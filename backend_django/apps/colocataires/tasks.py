# apps/colocataires/tasks.py

from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from .models import RechercheColocataire


@shared_task
def expirer_recherches_inactives():
    """
    Tâche planifiée à exécuter quotidiennement pour expirer les recherches inactives.
    Expire les recherches actives de plus de 15 jours.
    """
    date_limite = timezone.now() - timedelta(days=15)
    
    recherches_expirees = RechercheColocataire.objects.filter(
        statut='active',
        date_creation__lte=date_limite
    )
    
    count = recherches_expirees.update(statut='expiree')
    
    print(f"✅ {count} recherches de colocataire expirées")
    
    return f"{count} recherches expirées"
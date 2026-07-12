from celery import shared_task
from django.utils import timezone
from datetime import timedelta
from .models import Paiement
from locataires.models import Locataire
from notifications.models import Notification
from notifications.fcm_service import notify_user

@shared_task
def verifier_echeances_loyer():
    aujourd_hui = timezone.now().date()
    date_rappel = aujourd_hui + timedelta(days=7)

    locations = Locataire.objects.filter(est_actif=True, unite__isnull=False)

    for loc in locations:
        try:
            # 1. Dernier paiement de loyer validé pour cette unité
            dernier_paiement = Paiement.objects.filter(
                unite=loc.unite,
                type_paiement='loyer',
                statut='valide'
            ).order_by('-periode_fin').first()

            if dernier_paiement:
                prochaine_echeance = dernier_paiement.periode_fin + timedelta(days=1)
            else:
                # Premier paiement : échéance = date d'entrée + 30 jours
                prochaine_echeance = loc.date_entree + timedelta(days=30)

            # 2. Notifications (aujourd'hui ou dans 7 jours)
            if prochaine_echeance == aujourd_hui:
                titre = "⏰ Paiement du loyer exigible aujourd'hui"
                message = f"Votre loyer pour {loc.unite.nom} est dû aujourd'hui ({aujourd_hui}). Veuillez procéder au paiement."
                Notification.objects.create(
                    destinataire=loc.utilisateur,
                    type='paiement',
                    titre=titre,
                    message=message,
                    lien='/paiements'
                )
                notify_user(loc.utilisateur, titre, message, {'type': 'payment_due_today'})

            elif prochaine_echeance == date_rappel:
                titre = "🔔 Rappel : paiement du loyer dans 7 jours"
                message = f"Votre loyer pour {loc.unite.nom} sera dû le {prochaine_echeance}. Pensez à prévoir votre paiement."
                Notification.objects.create(
                    destinataire=loc.utilisateur,
                    type='paiement',
                    titre=titre,
                    message=message,
                    lien='/paiements'
                )
                notify_user(loc.utilisateur, titre, message, {'type': 'payment_reminder_7d'})

        except Exception as e:
            # On logue l’erreur pour éviter que la tâche entière échoue
            print(f"Erreur pour le locataire {loc.id} : {e}")
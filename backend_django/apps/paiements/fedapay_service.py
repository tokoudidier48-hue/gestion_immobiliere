# apps/paiements/fedapay_service.py

import requests
import time  # ⭐ AJOUTÉ pour la simulation
from django.conf import settings


class FedaPayService:
    """
    Service d'intégration avec l'API FedaPay.
    Utilise les clés configurées dans settings.py.
    """

    def __init__(self):
        self.api_key = settings.FEDAPAY_SECRET_KEY
        self.mode = settings.FEDAPAY_MODE
        self.base_url = (
            "https://sandbox-api.fedapay.com/v1"
            if self.mode == 'test'
            else "https://api.fedapay.com/v1"
        )
        self.headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }

    def create_transaction(self, amount, description, customer_email, customer_name, callback_url=None):
        """
        Crée une transaction (collecte) sur Fedapay.
        Retourne l'objet transaction complet (y compris payment_token).
        """
        amount_in_cents = int(amount)

        name_parts = customer_name.split() if customer_name else ["Client", "LoyaSmart"]
        firstname = name_parts[0] if name_parts else "Client"
        lastname = " ".join(name_parts[1:]) if len(name_parts) > 1 else "LoyaSmart"

        customer_data = {
            "firstname": firstname,
            "lastname": lastname,
            "email": customer_email
        }

        data = {
            "description": description,
            "amount": amount_in_cents,
            "currency": {"iso": "XOF"},
            "customer": customer_data
        }

        if callback_url:
            data["callback_url"] = callback_url

        response = requests.post(
            f"{self.base_url}/transactions",
            headers=self.headers,
            json=data
        )

        if response.status_code in [200, 201]:
            return response.json()
        else:
            raise Exception(f"Erreur Fedapay: {response.status_code} - {response.text}")

    def verify_transaction(self, transaction_id):
        """
        Vérifie le statut d'une transaction.
        """
        response = requests.get(
            f"{self.base_url}/transactions/{transaction_id}",
            headers=self.headers
        )

        if response.status_code == 200:
            return response.json()
        else:
            raise Exception(f"Erreur Fedapay: {response.status_code} - {response.text}")

    def create_payout(self, amount, customer_email, customer_name, phone_number, mode='mtn'):
        """
        Crée un virement (payout) vers un compte Mobile Money.

        En mode SANDOX (test), la fonction SIMULE le payout
        pour permettre les tests sans attendre l'activation.
        En mode PRODUCTION, elle appelle l'API réelle.

        Args:
            amount (int): Montant en FCFA (doit être un nombre entier)
            customer_email (str): Email du bénéficiaire
            customer_name (str): Nom complet du bénéficiaire
            phone_number (str): Numéro de téléphone Mobile Money (format international)
            mode (str): 'mtn', 'moov' ou 'celtis'

        Returns:
            dict: Données du payout créé (réel ou simulé)
        """
        # ⭐ SIMULATION DU PAYOUT EN MODE TEST ⭐
        if self.mode == 'test':
            return {
                "id": f"payout_simulated_{int(time.time())}",
                "amount": int(amount),
                "status": "pending",
                "message": "Payout simulé en mode test (sandbox)",
                "customer": {
                    "email": customer_email,
                    "phone_number": phone_number
                }
            }

        # ⭐ CODE RÉEL POUR LA PRODUCTION ⭐
        # (sera utilisé quand FEDAPAY_MODE='production')
        amount = int(amount)

        name_parts = customer_name.split() if customer_name else ["Client", "LoyaSmart"]
        firstname = name_parts[0] if name_parts else "Client"
        lastname = " ".join(name_parts[1:]) if len(name_parts) > 1 else "LoyaSmart"

        data = {
            "amount": amount,
            "currency": {"iso": "XOF"},
            "mode": f"{mode}_open",  # ex: "mtn_open", "moov_open", "celtis_open"
            "customer": {
                "firstname": firstname,
                "lastname": lastname,
                "email": customer_email,
                "phone_number": {
                    "number": phone_number,
                    "country": "bj"
                }
            }
        }

        response = requests.post(
            f"{self.base_url}/payouts",
            headers=self.headers,
            json=data
        )

        if response.status_code in [200, 201]:
            return response.json()
        else:
            raise Exception(f"Erreur FedaPay payout: {response.status_code} - {response.text}")
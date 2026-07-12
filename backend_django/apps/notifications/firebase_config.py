import os
import json
import firebase_admin
from decouple import config
from firebase_admin import credentials
from django.conf import settings

def initialize_firebase():
    """Initialise Firebase Admin SDK"""
    
    # Vérifier si déjà initialisé
    if firebase_admin._apps:
        print("Firebase déjà initialisé")
        return True
    
    try:

        firebase_credentials_json = config('FIREBASE_CREDENTIALS', default=None)
        
        if not firebase_credentials_json:
            print("⚠️ Avertissement: FIREBASE_CREDENTIALS non trouvé dans .env")
            print("Les notifications push ne fonctionneront pas sans cette configuration")
            return False
        
        # Convertir le JSON en dictionnaire
        firebase_credentials_dict = json.loads(firebase_credentials_json)
        
        # Créer l'objet credentials
        cred = credentials.Certificate(firebase_credentials_dict)
        
        # Initialiser Firebase
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialisé avec succès")
        return True
        
    except json.JSONDecodeError as e:
        print(f"❌ Erreur de décodage JSON: {e}")
        return False
    except Exception as e:
        print(f"❌ Erreur d'initialisation Firebase: {e}")
        return False

# ⭐ NE PAS initialiser automatiquement au chargement ⭐
# L'initialisation se fera quand la fonction sera appelée
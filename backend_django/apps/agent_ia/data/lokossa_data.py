# apps/agent_ia/data/lokossa_data.py

"""
Données statiques sur Lokossa.
Utilisées pour la géolocalisation et l'enrichissement IA.

IMPORTANT :
  Ces données sont statiques et ne changent pas à l'exécution.
  Pour ajouter un quartier : ajouter une entrée dans QUARTIERS_LOKOSSA
  avec ses coordonnées GPS (lat, lon).
"""

from typing import Dict, Set


# =========================================================
# TYPES DE LOGEMENTS AUTORISÉS EN BASE
# =========================================================
# Ces valeurs doivent correspondre EXACTEMENT
# aux choix du champ type_unite dans unites/models.py

TYPES_AUTORISES: Set[str] = {
    "appartement",
    "boutique",
    "studio",
    "maison",
    "chambre_salon_sanitaire",
    "chambre_salon_ordinaire",
    "deux_chambres_sanitaire",
    "deux_chambres_ordinaire",
    "entree_coucher_sanitaire",
    "entree_coucher_ordinaire",
}


# =========================================================
# COORDONNÉES GPS DE L'INSTI DE LOKOSSA
# Point de référence pour le calcul des distances
# =========================================================

INSTI_LOKOSSA_COORDS: Dict[str, float] = {
    "lat": 6.6333,
    "lon": 1.7167,
}


# =========================================================
# QUARTIERS DE LOKOSSA
# Format : { nom_quartier: { lat: float, lon: float } }
#
# IMPORTANT :
#   - Les noms sont en minuscules sans accents
#   - Ils doivent correspondre à ce qui peut apparaître
#     dans les adresses saisies par les propriétaires
#   - La détection se fait par sous-chaîne (icontains)
# =========================================================

QUARTIERS_LOKOSSA: Dict[str, Dict[str, float]] = {
    "lokossa-centre": {"lat": 6.6333, "lon": 1.7167},
    "agnivedji":      {"lat": 6.6333, "lon": 1.7140},
    "agame":          {"lat": 6.6260, "lon": 1.7100},
    "houin":          {"lat": 6.6380, "lon": 1.7090},
    "koudo":          {"lat": 6.6400, "lon": 1.7220},
    "agolo":          {"lat": 6.6310, "lon": 1.7150},
    "hounsa":         {"lat": 6.6350, "lon": 1.7180},
    "kpinnou":        {"lat": 6.6280, "lon": 1.7200},
    "sahoue":         {"lat": 6.6400, "lon": 1.7120},
    "zoungue":        {"lat": 6.6370, "lon": 1.7140},
    "gbozoume":       {"lat": 6.6300, "lon": 1.7250},
    "dekanme":        {"lat": 6.6340, "lon": 1.7220},
    "zoumon":         {"lat": 6.6320, "lon": 1.7190},
    "tchikponde":     {"lat": 6.6390, "lon": 1.7240},
    "ahota":          {"lat": 6.6270, "lon": 1.7080},
    "djihadji":       {"lat": 6.6360, "lon": 1.7230},
    "atikpeta":       {"lat": 6.6290, "lon": 1.7270},
    "doucanta":       {"lat": 6.6280, "lon": 1.7140},
}


# =========================================================
# NOMS DE QUARTIERS (pour détection rapide dans les messages)
# Utilisé par rag_engine pour détecter un quartier mentionné
# =========================================================

NOMS_QUARTIERS: Set[str] = set(QUARTIERS_LOKOSSA.keys())

# Variantes avec accents ou espaces fréquemment saisies
VARIANTES_QUARTIERS: Dict[str, str] = {
    "lokossa centre":  "lokossa-centre",
    "centre":          "lokossa-centre",
    "agamé":           "agame",
    "agnivèdji":       "agnivedji",
    "gbozomé":         "gbozoume",
    "tchikpondé":      "tchikponde",
    "atikpéta":        "atikpeta",
    "doucanta":        "doucanta",
}


# =========================================================
# INFORMATIONS GÉNÉRALES SUR LOKOSSA
# =========================================================

INFO_LOKOSSA: Dict = {
    "departement": "Mono",
    "arrondissements": [
        "Agamé",
        "Houin",
        "Koudo",
        "Lokossa",
        "Ouèdèmè-Adja",
    ],
    "description": (
        "Lokossa est une ville du sud-ouest du Bénin, "
        "chef-lieu du département du Mono. "
        "Elle abrite l'INSTI et l'UNSTIM."
    ),
    "activites": "Éducation, commerce, agriculture",
    "population": "104 428 habitants (2013)",
}
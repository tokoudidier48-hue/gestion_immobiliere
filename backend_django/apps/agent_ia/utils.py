# apps/agent_ia/utils.py

"""
Fonctions utilitaires pour le chatbot Loya.
Aucune logique IA ici — calculs purs et extraction de données.
"""

import math
import logging
from typing import Optional

from unites.models import Unite
from .data.lokossa_data import QUARTIERS_LOKOSSA, INSTI_LOKOSSA_COORDS

logger = logging.getLogger(__name__)


# =========================================================
# EXTRACTION QUARTIER
# =========================================================

def extraire_quartier_depuis_adresse(adresse: str) -> Optional[str]:
    """
    Extrait un quartier de Lokossa reconnu
    à partir d'une adresse libre.

    Retourne le nom du quartier ou None si non reconnu.
    """
    if not adresse or not isinstance(adresse, str):
        return None

    adresse_lower = adresse.lower()

    for quartier in QUARTIERS_LOKOSSA.keys():
        if quartier.lower() in adresse_lower:
            return quartier

    return None


# =========================================================
# DISTANCE HAVERSINE
# =========================================================

def calculer_distance(
    lat1: float,
    lon1: float,
    lat2: float,
    lon2: float,
) -> Optional[float]:
    """
    Calcule la distance en km entre deux coordonnées GPS
    via la formule de Haversine.

    Retourne la distance arrondie à 1 décimale, ou None si erreur.
    """
    try:
        # Vérification coordonnées valides
        for val in (lat1, lon1, lat2, lon2):
            if val is None or not isinstance(val, (int, float)):
                logger.warning("⚠️ Coordonnée invalide : %s", val)
                return None

        R = 6371.0  # Rayon terrestre en km

        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)

        a = (
            math.sin(dlat / 2) ** 2
            + math.cos(math.radians(lat1))
            * math.cos(math.radians(lat2))
            * math.sin(dlon / 2) ** 2
        )

        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

        return round(R * c, 1)

    except Exception as e:
        logger.warning("⚠️ Erreur calcul distance : %s", e)
        return None


# =========================================================
# DISTANCE LOGEMENT → INSTI LOKOSSA
# =========================================================

def calculer_distance_universite(unite: Unite) -> Optional[float]:
    """
    Calcule la distance entre un logement et l'INSTI de Lokossa.

    Utilise les coordonnées GPS du quartier extrait de l'adresse.
    Retourne None si les coordonnées sont indisponibles.
    """
    if not unite:
        return None

    adresse = getattr(unite, "adresse", None)
    if not adresse:
        return None

    try:
        # Extraire le quartier depuis l'adresse
        quartier = extraire_quartier_depuis_adresse(adresse)
        if not quartier:
            logger.debug(
                "Quartier non reconnu pour unité %s : %s",
                getattr(unite, "id", "?"),
                adresse,
            )
            return None

        # Coordonnées du quartier
        coords_quartier = QUARTIERS_LOKOSSA.get(quartier)
        if not coords_quartier:
            return None

        lat_q = coords_quartier.get("lat")
        lon_q = coords_quartier.get("lon")

        # Coordonnées INSTI
        if not INSTI_LOKOSSA_COORDS:
            logger.error("❌ INSTI_LOKOSSA_COORDS non défini dans lokossa_data.py")
            return None

        lat_insti = INSTI_LOKOSSA_COORDS.get("lat")
        lon_insti = INSTI_LOKOSSA_COORDS.get("lon")

        return calculer_distance(lat_q, lon_q, lat_insti, lon_insti)

    except Exception as e:
        logger.warning(
            "⚠️ Erreur distance université pour unité %s : %s",
            getattr(unite, "id", "?"),
            e,
        )
        return None
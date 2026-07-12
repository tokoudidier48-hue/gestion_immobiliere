# apps/agent_ia/services/search_service.py

"""
Service de recherche dans la base de données Django.
UNIQUEMENT responsable de la récupération des logements.
Aucune logique IA ici.

IMPORTANT :
  - rechercher_unites_db() est la SEULE source de logements
  - Le LLM ne génère JAMAIS de logements
  - Tous les filtres viennent des paramètres reçus
"""

import logging
from typing import List, Optional

from django.db.models import Q

from unites.models import Unite

logger = logging.getLogger(__name__)


# =========================================================
# TYPES ET MAPPINGS (source de vérité unique)
# =========================================================

# Types directement stockés en DB sans mapping sanitaire
TYPES_DIRECTS = {
    "appartement",
    "boutique",
    "studio",
    "maison",
}

# Types génériques qui nécessitent un mapping sanitaire
TYPES_AVEC_SANITAIRE = {
    "chambre_salon",
    "deux_chambres",
    "entree_coucher",
}

# Mapping type_generique + sanitaire → type_unite réel en DB
MAPPING_SANITAIRE = {
    "chambre_salon": {
        "sanitaire": "chambre_salon_sanitaire",
        "ordinaire": "chambre_salon_ordinaire",
    },
    "deux_chambres": {
        "sanitaire": "deux_chambres_sanitaire",
        "ordinaire": "deux_chambres_ordinaire",
    },
    "entree_coucher": {
        "sanitaire": "entree_coucher_sanitaire",
        "ordinaire": "entree_coucher_ordinaire",
    },
}

# Tous les types valides (directs + variantes sanitaire)
TOUS_TYPES_VALIDES = TYPES_DIRECTS | TYPES_AVEC_SANITAIRE | {
    v
    for mapping in MAPPING_SANITAIRE.values()
    for v in mapping.values()
}


# =========================================================
# RECHERCHE PRINCIPALE
# =========================================================

def rechercher_unites_db(
    type_logement: Optional[str] = None,
    budget_max: Optional[int] = None,
    sanitaire: Optional[str] = None,
    quartier: Optional[str] = None,
    limit: int = 10,
) -> List[Unite]:
    """
    Recherche des logements dans la base de données.

    Paramètres :
        type_logement — type générique ou spécifique
                        Ex: "chambre_salon", "appartement"
        budget_max    — loyer maximum en FCFA
        sanitaire     — "sanitaire" | "ordinaire" | None
        quartier      — mot-clé dans l'adresse (optionnel)
        limit         — nombre max de résultats (défaut 10)

    Retourne :
        Liste d'objets Unite (jamais None, liste vide si erreur)
    """
    try:
        # Base : logements libres à Lokossa
        queryset = Unite.objects.filter(
            statut="libre",
            ville__icontains="lokossa",
        )

        logger.debug(
            "🔍 Recherche → type=%s | budget=%s | sanitaire=%s | quartier=%s",
            type_logement, budget_max, sanitaire, quartier,
        )

        # -----------------------------------------------
        # FILTRE TYPE
        # -----------------------------------------------
        if type_logement:

            if type_logement in TYPES_DIRECTS:
                # Type direct : appartement, boutique, studio, maison
                queryset = queryset.filter(type_unite=type_logement)

            elif type_logement in TYPES_AVEC_SANITAIRE:
                # Type avec variante sanitaire
                mapping = MAPPING_SANITAIRE.get(type_logement, {})

                if sanitaire == "sanitaire":
                    vrai_type = mapping.get("sanitaire")
                    if vrai_type:
                        queryset = queryset.filter(type_unite=vrai_type)

                elif sanitaire == "ordinaire":
                    vrai_type = mapping.get("ordinaire")
                    if vrai_type:
                        queryset = queryset.filter(type_unite=vrai_type)

                else:
                    # Pas de préférence sanitaire → retourner les deux variantes
                    tous_types = list(mapping.values())
                    if tous_types:
                        queryset = queryset.filter(type_unite__in=tous_types)

            elif type_logement in TOUS_TYPES_VALIDES:
                # Type complet déjà spécifié (ex: "chambre_salon_sanitaire")
                queryset = queryset.filter(type_unite=type_logement)

            else:
                logger.warning("⚠️ Type inconnu ignoré : %s", type_logement)
                # On ne bloque pas, on retourne ce qu'on peut

        # -----------------------------------------------
        # FILTRE BUDGET
        # -----------------------------------------------
        if budget_max is not None:
            queryset = queryset.filter(loyer__lte=budget_max)

        # -----------------------------------------------
        # FILTRE QUARTIER
        # -----------------------------------------------
        if quartier:
            queryset = queryset.filter(adresse__icontains=quartier)

        # -----------------------------------------------
        # TRI : du moins cher au plus cher
        # -----------------------------------------------
        queryset = queryset.order_by("loyer", "-id")

        results = list(queryset[:limit])

        logger.info("🏠 %d logement(s) trouvé(s)", len(results))
        return results

    except Exception as e:
        logger.exception("❌ Erreur recherche logements : %s", e)
        return []


# =========================================================
# RECHERCHE PAR QUARTIER
# =========================================================

def rechercher_par_quartier(
    quartier: str,
    limit: int = 10,
) -> List[Unite]:
    """Recherche par nom de quartier dans l'adresse."""
    try:
        return list(
            Unite.objects.filter(
                statut="libre",
                ville__icontains="lokossa",
                adresse__icontains=quartier,
            ).order_by("loyer")[:limit]
        )
    except Exception as e:
        logger.exception("❌ Erreur recherche quartier : %s", e)
        return []


# =========================================================
# RECHERCHE PAR BUDGET
# =========================================================

def rechercher_par_budget(
    budget_min: Optional[int] = None,
    budget_max: Optional[int] = None,
    limit: int = 10,
) -> List[Unite]:
    """Recherche par fourchette de budget."""
    try:
        queryset = Unite.objects.filter(
            statut="libre",
            ville__icontains="lokossa",
        )
        if budget_min is not None:
            queryset = queryset.filter(loyer__gte=budget_min)
        if budget_max is not None:
            queryset = queryset.filter(loyer__lte=budget_max)

        return list(queryset.order_by("loyer")[:limit])

    except Exception as e:
        logger.exception("❌ Erreur recherche budget : %s", e)
        return []


# =========================================================
# RECHERCHE MULTI-CHAMPS
# =========================================================

def rechercher_logements_proches(
    mot_cle: str,
    limit: int = 10,
) -> List[Unite]:
    """Recherche par mot-clé dans nom, adresse ou description."""
    try:
        return list(
            Unite.objects.filter(
                Q(nom__icontains=mot_cle)
                | Q(adresse__icontains=mot_cle)
                | Q(description__icontains=mot_cle),
                statut="libre",
                ville__icontains="lokossa",
            ).order_by("loyer")[:limit]
        )
    except Exception as e:
        logger.exception("❌ Erreur recherche multi-champs : %s", e)
        return []
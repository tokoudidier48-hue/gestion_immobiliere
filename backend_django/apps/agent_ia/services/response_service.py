# apps/agent_ia/services/response_service.py

"""
Formatage des réponses textuelles de Loya.
Aucune logique métier ici — uniquement du formatage.
"""

import random
from typing import List, Optional

from unites.models import Unite


# =========================================================
# HELPERS INTERNES
# =========================================================

def _nom_type(type_logement: str) -> str:
    """Retourne le nom lisible d'un type de logement."""
    mapping = {
        "chambre_salon":            "chambre salon",
        "chambre_salon_sanitaire":  "chambre salon sanitaire",
        "chambre_salon_ordinaire":  "chambre salon ordinaire",
        "deux_chambres":            "deux chambres",
        "deux_chambres_sanitaire":  "deux chambres sanitaire",
        "deux_chambres_ordinaire":  "deux chambres ordinaire",
        "entree_coucher":           "entrée coucher",
        "entree_coucher_sanitaire": "entrée coucher sanitaire",
        "entree_coucher_ordinaire": "entrée coucher ordinaire",
        "appartement":              "appartement",
        "boutique":                 "boutique",
        "studio":                   "studio",
        "maison":                   "maison",
    }
    return mapping.get(type_logement, type_logement)


def _formater_loyer(loyer: int) -> str:
    """Formate un loyer avec séparateurs milliers."""
    return f"{loyer:,}".replace(",", " ")


# =========================================================
# DEMANDE DE PRÉCISION SANITAIRE
# =========================================================

def get_reponse_demande_precision(type_logement: str) -> str:
    """
    Demande si le locataire veut sanitaire ou ordinaire.
    Appelé SEULEMENT si l'info n'est pas déjà dans le message.
    """
    nom = _nom_type(type_logement)

    reponses = [
        f"Pour votre {nom}, préférez-vous une version sanitaire ou ordinaire ? 🚿",
        f"D'accord ! Votre {nom} doit-il être sanitaire ou ordinaire ?",
        f"Précisez s'il vous plaît : sanitaire ou ordinaire pour le {nom} ?",
    ]
    return random.choice(reponses)


# =========================================================
# NUMÉRO INVALIDE
# =========================================================

def get_reponse_numero_invalide(max_num: int) -> str:
    """Réponse quand l'utilisateur envoie un numéro hors liste."""
    reponses = [
        f"Ce numéro n'existe pas 😕 Choisissez entre 1 et {max_num}.",
        f"Merci de choisir un numéro entre 1 et {max_num} 📋",
        f"Numéro invalide. Les choix disponibles vont de 1 à {max_num}.",
    ]
    return random.choice(reponses)


# =========================================================
# AUCUN RÉSULTAT
# =========================================================

def get_reponse_aucun_resultat(
    type_logement: Optional[str] = None,
    budget_max: Optional[int] = None,
    sanitaire: Optional[str] = None,
) -> str:
    """
    Message quand aucun logement ne correspond à la recherche.
    Propose toujours une alternative pour ne pas bloquer l'UX.
    """
    parties = []

    if type_logement:
        nom = _nom_type(type_logement)
        parties.append(f"de type {nom}")

    if sanitaire:
        parties.append(sanitaire)

    if budget_max:
        parties.append(f"à moins de {_formater_loyer(budget_max)} FCFA")

    if parties:
        criteres = " ".join(parties)
        return (
            f"😕 Aucun logement {criteres} n'est disponible actuellement à Lokossa.\n\n"
            "Souhaitez-vous :\n"
            "• Augmenter votre budget ?\n"
            "• Changer de type de logement ?\n"
            "• Rechercher sans critère de prix ?"
        )

    return (
        "😕 Aucun logement correspondant à votre recherche n'est disponible.\n\n"
        "Dites-moi si vous voulez modifier vos critères 😊"
    )


# =========================================================
# LISTE DES RÉSULTATS
# =========================================================

def get_reponse_recherche(unites: List[Unite]) -> str:
    """
    Formate la liste des logements trouvés.
    Format optimisé pour affichage mobile (Flutter).
    """
    if not unites:
        return get_reponse_aucun_resultat()

    lignes = [
        f"🏠 {len(unites)} logement(s) disponible(s) à Lokossa :\n"
    ]

    for i, unite in enumerate(unites, start=1):

        # Nom du type lisible
        type_display = (
            unite.get_type_unite_display()
            if hasattr(unite, "get_type_unite_display")
            else _nom_type(unite.type_unite)
        )

        # Distance université
        distance = getattr(unite, "distance", None)
        distance_str = (
            f"🎓 Distance INSTI : {distance} km\n"
            if distance is not None
            else ""
        )

        # Bloc logement
        lignes.append(
            f"━━━━━━━━━━━━━━━━━━━━\n"
            f"📌 Logement {i} — {type_display}\n"
            f"📍 {unite.adresse}\n"
            f"💰 {_formater_loyer(unite.loyer)} FCFA/mois\n"
            f"{distance_str}"
        )

    lignes.append(
        "━━━━━━━━━━━━━━━━━━━━\n"
        "👉 Envoyez le numéro du logement pour voir tous ses détails."
    )

    return "\n".join(lignes)


# =========================================================
# DÉTAILS D'UN LOGEMENT
# =========================================================

def get_reponse_details_unite(unite: Unite) -> str:
    """
    Affiche les détails complets d'un logement.
    """
    distance = getattr(unite, "distance", None)

    type_display = (
        unite.get_type_unite_display()
        if hasattr(unite, "get_type_unite_display")
        else _nom_type(unite.type_unite)
    )

    # Infos optionnelles
    distance_str = (
        f"🎓 Distance INSTI : {distance} km\n"
        if distance is not None else ""
    )
    description_str = (
        f"📖 {unite.description}\n"
        if getattr(unite, "description", None) else ""
    )
    garage_str = "✅ Oui" if getattr(unite, "garage", False) else "❌ Non"
    prepaye_str = "✅ Oui" if getattr(unite, "prepaye", False) else "❌ Non"

    douche_display = (
        unite.get_type_douche_display()
        if hasattr(unite, "get_type_douche_display")
        else "Non spécifiée"
    )

    return (
        f"🏠 Détails du logement\n"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"📌 Type     : {type_display}\n"
        f"🏷️  Nom      : {unite.nom}\n"
        f"📍 Adresse  : {unite.adresse}\n"
        f"💰 Loyer    : {_formater_loyer(unite.loyer)} FCFA/mois\n"
        f"📋 Avances  : {unite.nombre_avances} mois\n"
        f"🔒 Caution  : {_formater_loyer(unite.prix_caution)} FCFA\n"
        f"🚿 Douche   : {douche_display}\n"
        f"🔌 Prépayé  : {prepaye_str}\n"
        f"🚗 Garage   : {garage_str}\n"
        f"📞 Contact  : {unite.contact_proprietaire}\n"
        f"{description_str}"
        f"{distance_str}"
        f"━━━━━━━━━━━━━━━━━━━━\n"
        f"💬 Souhaitez-vous voir un autre logement ?"
    )
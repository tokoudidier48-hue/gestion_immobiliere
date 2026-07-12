# apps/agent_ia/services/llm_service.py

"""
Service de gestion du modèle LLM (Ollama).

Architecture :
  1. Le LLM classifie l'intention (cas ambigus seulement)
  2. Si conversation  → réponse naturelle
  3. Si recherche     → DB uniquement
  Aucun logement n'est jamais inventé par le LLM.

IMPORTANT :
  analyser_intention() n'est appelé que si les règles
  métier du rag_engine n'ont pas déjà tranché.
"""

import json
import logging
import re

from typing import Any, Dict, List, Optional

from langchain_ollama import OllamaLLM

logger = logging.getLogger(__name__)


# =========================================================
# SINGLETON LLM
# =========================================================

_LLM: Optional[OllamaLLM] = None


# =========================================================
# CONSTANTES MÉTIER
# =========================================================

TYPES_LOGEMENTS_VALIDES = {
    "appartement",
    "chambre_salon",
    "entree_coucher",
    "deux_chambres",
    "boutique",
    "studio",
    "maison",
}

INTENTS_VALIDES = {
    "conversation",
    "recherche_logement",
    "hors_domaine",
}

SANITAIRES_VALIDES = {
    "sanitaire",
    "ordinaire",
}

# Normalisation des variantes textuelles vers les clés DB
TYPE_MAP = {
    "entrée coucher":  "entree_coucher",
    "entrée_coucher":  "entree_coucher",
    "entree coucher":  "entree_coucher",
    "chambre salon":   "chambre_salon",
    "chambre_salon":   "chambre_salon",
    "deux chambres":   "deux_chambres",
    "deux_chambres":   "deux_chambres",
    "2 chambres":      "deux_chambres",
    "appartement":     "appartement",
    "boutique":        "boutique",
    "studio":          "studio",
    "maison":          "maison",
}

# =========================================================
# CHARGEMENT LLM (singleton)
# =========================================================

def get_llm() -> OllamaLLM:
    """
    Retourne une instance singleton du modèle Ollama.
    Paramètres optimisés pour qwen2.5:0.5b (plus rapide sur CPU).
    
    Avantages de qwen2.5:0.5b vs llama3.2:1b :
    - 3x à 5x plus rapide sur CPU
    - Consomme moins de RAM (~500 MB au lieu de 1.5 GB)
    - Temps de réponse : 2-5 secondes au lieu de 8-20 secondes
    """
    global _LLM

    if _LLM is None:
        try:
            _LLM = OllamaLLM(
                model="qwen2.5:0.5b",   # ← Changé ici
                temperature=0.0,         # Déterministe → JSON stable
                num_ctx=2048,             # Contexte court (assez pour 1b)
                num_predict=512,          # Suffisant pour un JSON complet
                repeat_penalty=1.1,
                timeout=15,              # Réduit car modèle plus rapide
                keep_alive="15m",
            )
            logger.info("✅ Modèle Ollama qwen2.5:0.5b chargé (plus rapide)")
        except Exception as e:
            logger.exception("❌ Erreur chargement LLM : %s", e)
            raise

    return _LLM


# =========================================================
# EXTRACTION JSON ROBUSTE
# =========================================================

def extraire_json_robuste(texte: str) -> Optional[Dict[str, Any]]:
    """
    Extrait le premier JSON valide trouvé dans la réponse du LLM.
    Gère : JSON brut, blocs markdown ```json```, JSON partiel.
    """
    if not texte:
        return None

    texte = texte.strip()

    # 1. Bloc markdown ```json ... ```
    markdown_match = re.search(
        r"```(?:json)?\s*(\{.*?\})\s*```",
        texte,
        re.DOTALL,
    )
    if markdown_match:
        try:
            data = json.loads(markdown_match.group(1))
            if isinstance(data, dict):
                return data
        except Exception:
            pass

    # 2. Premier { ... } trouvé dans le texte
    matches = re.findall(r"\{[^{}]*\}", texte, re.DOTALL)
    for match in matches:
        try:
            data = json.loads(match)
            if isinstance(data, dict):
                return data
        except Exception:
            continue

    # 3. Fallback : chercher les valeurs clé par clé dans le texte brut
    # Utile quand llama3.2:1b répond en texte au lieu de JSON
    fallback = _extraire_champs_texte(texte)
    if fallback:
        return fallback

    logger.warning("⚠️ Aucun JSON valide trouvé dans : %s", texte[:200])
    return None


def _extraire_champs_texte(texte: str) -> Optional[Dict[str, Any]]:
    """
    Extraction de secours quand le LLM ne produit pas de JSON.
    Cherche les mots-clés directement dans le texte brut.
    """
    texte_lower = texte.lower()
    resultat = {}

    # Intent
    if "recherche_logement" in texte_lower or "recherche logement" in texte_lower:
        resultat["intent"] = "recherche_logement"
    elif "hors_domaine" in texte_lower or "hors domaine" in texte_lower:
        resultat["intent"] = "hors_domaine"
    elif "conversation" in texte_lower:
        resultat["intent"] = "conversation"

    # Type logement
    for variante, cle in TYPE_MAP.items():
        if variante in texte_lower:
            resultat["type_logement"] = cle
            break

    # Sanitaire
    if "sanitaire" in texte_lower:
        resultat["sanitaire"] = "sanitaire"
    elif "ordinaire" in texte_lower:
        resultat["sanitaire"] = "ordinaire"

    return resultat if resultat else None


# =========================================================
# VALIDATION INTENTION
# =========================================================

def valider_intention(intention: Dict[str, Any]) -> Dict[str, Any]:
    """
    Nettoie et valide les données retournées par le LLM.
    Retourne toujours un dict complet et sûr.
    """
    resultat: Dict[str, Any] = {
        "intent": "conversation",
        "type_logement": None,
        "budget_max": None,
        "sanitaire": None,
    }

    # --- Intent ---
    intent = intention.get("intent", "")
    if intent in INTENTS_VALIDES:
        resultat["intent"] = intent

    # --- Type logement (avec normalisation TYPE_MAP) ---
    type_logement_brut = intention.get("type_logement")
    if type_logement_brut:
        type_logement_normalise = TYPE_MAP.get(
            str(type_logement_brut).lower(),
            str(type_logement_brut).lower(),
        )
        if type_logement_normalise in TYPES_LOGEMENTS_VALIDES:
            resultat["type_logement"] = type_logement_normalise

    # --- Budget ---
    budget = intention.get("budget_max")
    if budget is not None:
        try:
            budget_int = int(budget)
            if budget_int > 0:
                resultat["budget_max"] = budget_int
        except (ValueError, TypeError):
            pass

    # --- Sanitaire ---
    sanitaire = intention.get("sanitaire", "")
    if sanitaire in SANITAIRES_VALIDES:
        resultat["sanitaire"] = sanitaire

    return resultat


# =========================================================
# FALLBACK
# =========================================================

def fallback_intention() -> Dict[str, Any]:
    """Retourné en cas d'échec total du LLM."""
    return {
        "intent": "conversation",
        "type_logement": None,
        "budget_max": None,
        "sanitaire": None,
    }


# =========================================================
# ANALYSE INTENTION
# =========================================================

def analyser_intention(
    message: str,
    historique: Optional[List[Dict]] = None,
) -> Dict[str, Any]:
    """
    Analyse l'intention utilisateur via Ollama.

    IMPORTANT :
      Cette fonction est appelée SEULEMENT quand les règles
      métier du rag_engine n'ont pas tranché (cas ambigus).
      Elle n'utilise PAS @lru_cache car le contexte
      conversationnel peut changer la signification
      d'un même message.

    Paramètres :
        message    — texte brut de l'utilisateur
        historique — liste [{role, content}, ...] (optionnel)
    """
    message = message.strip()
    if not message:
        return fallback_intention()

    # =================================================
    # DÉTECTION RAPIDE HORS DOMAINE (avant Ollama)
    # Seulement ce qui n'a ABSOLUMENT rien à voir
    # avec l'immobilier ou Lokossa
    # =================================================
    message_lower = message.lower()
    
    MOTS_HORS_DOMAINE = [
        # Politique
        "politique", "président", "élection", "gouvernement", "parlement",
        # Sports
        "football", "basketball", "tennis", "match", "sport", "joueur",
        # Météo
        "météo", "temps qu'il fait", "pluie", "soleil", "température",
        # Santé (sauf logement)
        "covid", "vaccin", "maladie", "hôpital", "médicament",
        # Divertissement
        "musique", "film", "cinéma", "série", "jeu vidéo", "netflix",
        # Nourriture
        "restaurant", "manger", "cuisine", "recette", "plat",
        # Autres villes (hors Lokossa)
        "paris", "cotonou", "porto-novo", "abidjan", "dakar", "lomé",
        # Sujets généraux sans lien immobilier
        "météo aujourd'hui", "quel temps", "heure", "date", "anniversaire",
    ]
    
    for mot in MOTS_HORS_DOMAINE:
        if mot in message_lower:
            logger.info("🚫 Hors domaine détecté par mots-clés: %s", message[:50])
            return {
                "intent": "hors_domaine",
                "type_logement": None,
                "budget_max": None,
                "sanitaire": None,
            }

    # Contexte conversationnel (2 derniers échanges max pour petit modèle)
    contexte = ""
    if historique:
        derniers = historique[-4:]  # 2 échanges = 4 messages
        lignes = []
        for h in derniers:
            role = "Utilisateur" if h.get("role") == "user" else "Loya"
            lignes.append(f"{role}: {h.get('content', '')[:80]}")
        contexte = "\n".join(lignes)

    # ----------------------------------------------------------
    # PROMPT ULTRA-COURT pour qwen2.5:0.5b / llama3.2:1b
    # Instructions minimalistes pour éviter les hallucinations
    # ----------------------------------------------------------
    prompt = f"""Réponds UNIQUEMENT avec ce JSON. Rien d'autre.

{{"intent": "...", "type_logement": null, "budget_max": null, "sanitaire": null}}

intent = conversation | recherche_logement | hors_domaine
type_logement = appartement | chambre_salon | entree_coucher | deux_chambres | boutique | studio | maison | null
sanitaire = sanitaire | ordinaire | null

EXEMPLES:
"je cherche chambre salon sanitaire" → {{"intent":"recherche_logement","type_logement":"chambre_salon","budget_max":null,"sanitaire":"sanitaire"}}
"bonjour comment ça va" → {{"intent":"conversation","type_logement":null,"budget_max":null,"sanitaire":null}}
"entrée coucher ordinaire 15000" → {{"intent":"recherche_logement","type_logement":"entree_coucher","budget_max":15000,"sanitaire":"ordinaire"}}
"comment payer mon loyer" → {{"intent":"conversation","type_logement":null,"budget_max":null,"sanitaire":null}}
"c'est quoi une caution" → {{"intent":"conversation","type_logement":null,"budget_max":null,"sanitaire":null}}
"météo aujourd'hui" → {{"intent":"hors_domaine","type_logement":null,"budget_max":null,"sanitaire":null}}
{f'CONTEXTE:{chr(10)}{contexte}' if contexte else ''}
MESSAGE: {message}
JSON:"""

    try:
        llm = get_llm()
        response = llm.invoke(prompt)

        if not response:
            raise ValueError("Réponse vide Ollama")

        logger.debug("Réponse brute Ollama : %s", str(response)[:300])

        intention_brute = extraire_json_robuste(str(response))

        if not intention_brute:
            logger.warning("⚠️ JSON non parseable, fallback utilisé")
            return fallback_intention()

        validated = valider_intention(intention_brute)
        
        # Vérification supplémentaire : si le modèle retourne "recherche_logement"
        # mais que le message ne contient AUCUN mot-clé de logement, forcer conversation
        if validated.get("intent") == "recherche_logement":
            mots_cles_logement = ["chambre", "entrée", "entree", "appartement", 
                                  "boutique", "studio", "maison", "logement", "louer",
                                  "location", "sanitaire", "ordinaire"]
            if not any(mot in message_lower for mot in mots_cles_logement):
                logger.warning("⚠️ Modèle a halluciné 'recherche_logement' → forcé 'conversation'")
                validated["intent"] = "conversation"
                validated["type_logement"] = None
        
        logger.info("✅ Intention validée : %s", validated)
        return validated

    except Exception as e:
        logger.exception("❌ Erreur analyse intention : %s", e)
        return fallback_intention()

# =========================================================
# RÉPONSE CONVERSATIONNELLE NATURELLE
# =========================================================

def generer_reponse_conversation(
    message: str,
    historique: Optional[List[Dict]] = None,
) -> str:
    """
    Génère une réponse conversationnelle naturelle via Ollama.

    Paramètres :
        message    — texte brut de l'utilisateur
        historique — liste [{role, content}, ...] (optionnel)
    """

    # Contexte (2 derniers échanges max)
    contexte = ""
    if historique:
        derniers = historique[-4:]
        lignes = []
        for h in derniers:
            role = "Utilisateur" if h.get("role") == "user" else "Loya"
            lignes.append(f"{role}: {h.get('content', '')[:100]}")
        contexte = "\n".join(lignes)

    prompt = f"""Tu es Loya, assistant immobilier à Lokossa (Bénin).
Réponds naturellement en français, max 3 phrases.
Ne refuse jamais. Ne dis jamais "je ne peux pas".
Si on te demande un logement, demande des précisions.
{f"Contexte:{chr(10)}{contexte}" if contexte else ""}
Utilisateur: {message}
Loya:"""

    try:
        llm = get_llm()
        response = llm.invoke(prompt)

        if not response:
            raise ValueError("Réponse vide")

        reponse = str(response).strip()

        # Nettoyer les artefacts fréquents de llama3.2:1b
        reponse = re.sub(r"^Loya\s*:\s*", "", reponse, flags=re.IGNORECASE)
        reponse = re.sub(r"\n{3,}", "\n\n", reponse)

        logger.info("✅ Réponse conversation générée")
        return reponse

    except Exception as e:
        logger.exception("❌ Erreur génération conversation : %s", e)
        return (
            "Bonjour 😊 Je suis Loya, votre assistant immobilier à Lokossa. "
            "Dites-moi ce que vous recherchez comme logement !"
        )
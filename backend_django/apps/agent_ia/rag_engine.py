# apps/agent_ia/rag_engine.py

"""
Moteur RAG principal du chatbot Loya.

Architecture en couches (priorité ordre décroissant) :

  COUCHE 0 — Numéro logement (sélection depuis résultats)
  COUCHE 1 — Règles métier absolues (0ms, aucun LLM)
  COUCHE 2 — Salutations / conversations simples (0ms)
  COUCHE 3 — Ollama (seulement si ambiguïté réelle)
  COUCHE 4 — Recherche DB (toujours données réelles)
"""

import logging
import re
from typing import Dict, Any, List, Optional

from django.core.cache import cache

from .services.cache_service import ChatMemory, cache_result
from .services.llm_service import (
    analyser_intention,
    generer_reponse_conversation,
)
from .services.search_service import rechercher_unites_db
from .services.response_service import (
    get_reponse_demande_precision,
    get_reponse_aucun_resultat,
    get_reponse_recherche,
    get_reponse_details_unite,
)
from .utils import calculer_distance_universite

logger = logging.getLogger(__name__)


# =========================================================
# CONSTANTES GLOBALES
# =========================================================

MOTS_CLES_LOGEMENT = {
    "chambre",
    "entrée",
    "entree",
    "appartement",
    "boutique",
    "logement",
    "maison",
    "studio",
    "louer",
    "location",
    "deux chambres",
    "deux chambre",
    "2 chambres",
    "2 chambre",
}

MOTS_CLES_HORS_DOMAINE = {
    "météo", "meteo", "musique", "film", "sport",
    "football", "politique", "religion", "recette",
    "cuisine", "médecin", "medecin", "hôpital", "hopital",
    "voiture", "moto", "téléphone", "telephone",
    "ordinateur", "crypto", "bitcoin", "animaux",
    "chien", "chat", "animal",
}

SALUTATIONS = {
    "salut", "bonjour", "bonsoir", "cc",
    "coucou", "hello", "hi", "bjr", "slt",
    "bonne nuit", "bonne journée",
}

PREFIXES_SALUTATION = (
    "bonjour ",
    "bonsoir ",
    "salut ",
    "hello ",
    "bonne ",
)

CONVERSATIONS_SIMPLES = {
    "merci", "merci beaucoup", "ça va", "ca va",
    "yo", "ok", "d'accord", "dacord", "super",
    "bien", "parfait", "nickel", "oui", "non",
}

TYPES_LOGEMENT_REGLES = [
    # deux_chambres DOIT être avant chambre_salon
    ("deux_chambres", lambda m: (
        "deux chambres" in m
        or "2 chambres" in m
        or "deux chambre" in m
        or "2 chambre" in m
    )),
    ("chambre_salon",  lambda m: "chambre" in m and "salon" in m),
    ("entree_coucher", lambda m: ("entrée" in m or "entree" in m) and "coucher" in m),
    ("appartement",    lambda m: "appartement" in m),
    ("boutique",       lambda m: "boutique" in m),
    ("studio",         lambda m: "studio" in m),
    ("maison",         lambda m: "maison" in m),
]

PATTERN_NUMERO = re.compile(
    r"^(?:le\s+)?(?:num[eé]ro\s+)?(\d+)$|"
    r"^(?:je\s+(?:veux|prends|choisis)\s+le\s+)?(\d+)$|"
    r"^logement\s+(\d+)$|"
    r"^option\s+(\d+)$|"
    r"^num[eé]ro\s+(\d+)$",
    re.IGNORECASE,
)


# =========================================================
# CLASSE RAGChatbot
# =========================================================

class RAGChatbot:

    def __init__(self, user):
        self.user = user
        self.memory = ChatMemory(user.id) if user and user.id else None
        self._derniers_resultats: List = []
        logger.info("✅ Chatbot initialisé pour user=%s", user.id if user else "anonyme")

    # =====================================================
    # DÉTECTIONS MÉTIER
    # =====================================================

    def _detecter_intent_metier(self, message_lower: str) -> bool:
        return any(mot in message_lower for mot in MOTS_CLES_LOGEMENT)

    def _detecter_hors_domaine(self, message_lower: str) -> bool:
        return any(mot in message_lower for mot in MOTS_CLES_HORS_DOMAINE)

    def _detecter_type_logement(self, message_lower: str) -> Optional[str]:
        for type_logement, condition in TYPES_LOGEMENT_REGLES:
            if condition(message_lower):
                return type_logement
        return None

    def _detecter_sanitaire(self, message_lower: str) -> Optional[str]:
        if "sanitaire" in message_lower:
            return "sanitaire"
        if "ordinaire" in message_lower:
            return "ordinaire"
        return None

    def _detecter_budget(self, message_lower: str) -> Optional[int]:
        """
        Extrait un budget du message.
        Supporte : "15000", "15k", "entre 15000 et 25000",
                   "15000f", "15 000", "18000f à 25000f"
        """
        # Cas "15k"
        match_k = re.search(r"(\d+)\s*k", message_lower)
        if match_k:
            return int(match_k.group(1)) * 1000

        # Cas fourchette "X à Y" ou "entre X et Y" → prendre le max
        match_fourchette = re.search(
            r"(\d[\d\s]*)\s*(?:f|fcfa)?\s*[àa]\s*(\d[\d\s]*)\s*(?:f|fcfa)?",
            message_lower,
        )
        if match_fourchette:
            try:
                budget_max = int(match_fourchette.group(2).replace(" ", ""))
                if budget_max > 0:
                    return budget_max
            except ValueError:
                pass

        # Cas nombre seul "15000" ou "15 000"
        match_num = re.search(r"\b(\d[\d\s]{3,})\b", message_lower)
        if match_num:
            try:
                return int(match_num.group(1).replace(" ", ""))
            except ValueError:
                pass

        return None

    def _detecter_numero_selection(self, message_lower: str) -> Optional[int]:
        message_clean = message_lower.strip()
        if message_clean.isdigit():
            return int(message_clean)
        match = PATTERN_NUMERO.match(message_clean)
        if match:
            for group in match.groups():
                if group:
                    return int(group)
        return None

    # =====================================================
    # CACHE RÉSULTATS
    # =====================================================

    def _sauvegarder_resultats(self, unites: List) -> None:
        if not self.user or not self.user.id:
            return
        try:
            cache.set(
                f"last_results_{self.user.id}",
                [u.id for u in unites],
                timeout=1800,
            )
        except Exception as e:
            logger.exception("❌ Erreur sauvegarde résultats : %s", e)

    def _charger_resultats(self) -> List:
        if not self.user or not self.user.id:
            return []
        try:
            ids = cache.get(f"last_results_{self.user.id}")
            if not ids:
                return []
            from unites.models import Unite
            return list(Unite.objects.filter(id__in=ids))
        except Exception as e:
            logger.exception("❌ Erreur chargement résultats : %s", e)
            return []

    def _sauvegarder_dernier_type(self, type_logement: str) -> None:
        """Sauvegarde le dernier type recherché pour contexte conversationnel."""
        if not self.user or not self.user.id:
            return
        try:
            cache.set(
                f"last_type_{self.user.id}",
                type_logement,
                timeout=1800,
            )
        except Exception:
            pass

    def _charger_dernier_type(self) -> Optional[str]:
        """Recharge le dernier type recherché."""
        if not self.user or not self.user.id:
            return None
        try:
            return cache.get(f"last_type_{self.user.id}")
        except Exception:
            return None

    @cache_result(key_prefix="recherche_db", timeout=300)
    def _rechercher_avec_cache(
        self,
        type_logement: str,
        budget_max: Optional[int],
        sanitaire: Optional[str],
    ) -> List:
        return rechercher_unites_db(type_logement, budget_max, sanitaire)

    def _reponse_rapide(self, message: str, reponse: str) -> Dict[str, Any]:
        if self.memory:
            self.memory.add_exchange(message, reponse)
        return {"reponse": reponse, "sources": []}

    # =====================================================
    # POINT D'ENTRÉE PRINCIPAL
    # =====================================================

    def repondre(
        self,
        message: str,
        historique: Optional[List[Dict]] = None,
    ) -> Dict[str, Any]:

        message = message.strip()
        if not message:
            return self._reponse_rapide(
                message,
                "Bonjour 😊 Comment puis-je vous aider "
                "dans votre recherche de logement à Lokossa ?",
            )

        message_lower = message.lower().strip()
        logger.info("📨 Message reçu : %s", message[:100])

        # =================================================
        # COUCHE 0 — SÉLECTION PAR NUMÉRO
        # =================================================

        numero = self._detecter_numero_selection(message_lower)
        if numero is not None:
            derniers = self._charger_resultats()
            if derniers and 1 <= numero <= len(derniers):
                unite = derniers[numero - 1]
                unite.distance = calculer_distance_universite(unite)
                reponse = get_reponse_details_unite(unite)
                logger.info("📋 Détails logement #%d demandés", numero)
                return self._reponse_rapide(message, reponse)
            elif derniers:
                return self._reponse_rapide(
                    message,
                    f"❌ Numéro invalide. Choisissez entre 1 et {len(derniers)}.",
                )

        # =================================================
        # COUCHE 1A — HORS DOMAINE PAR MOTS-CLÉS (0ms)
        # =================================================

        if self._detecter_hors_domaine(message_lower):
            logger.info("🚫 Hors domaine : %s", message)
            return self._reponse_rapide(
                message,
                "Je suis spécialisé uniquement dans la recherche de logements "
                "à Lokossa 😊 Dites-moi quel type de logement vous cherchez !",
            )

        # =================================================
        # COUCHE 1B — SALUTATIONS EXACTES (0ms)
        # =================================================

        if message_lower in SALUTATIONS:
            logger.info("⚡ Salutation exacte")
            reponses = {
                "bonjour": "Bonjour 😊 Je suis Loya ! Dites-moi ce que vous cherchez comme logement à Lokossa.",
                "bonsoir": "Bonsoir 😊 Je suis Loya ! Comment puis-je vous aider ce soir ?",
                "salut":   "Salut 😊 Je suis Loya, votre assistant immobilier à Lokossa !",
                "hello":   "Hello 😊 Je suis Loya ! Quel logement cherchez-vous à Lokossa ?",
            }
            reponse = reponses.get(
                message_lower,
                "Bonjour 😊 Je suis Loya, votre assistant immobilier à Lokossa. Comment puis-je vous aider ?",
            )
            return self._reponse_rapide(message, reponse)

        # =================================================
        # COUCHE 1C — SALUTATIONS AVEC SUITE (0ms)
        # =================================================

        if any(message_lower.startswith(p) for p in PREFIXES_SALUTATION):
            logger.info("⚡ Salutation avec suite")
            return self._reponse_rapide(
                message,
                "Bonjour 😊 Je suis Loya, votre assistant immobilier à Lokossa. "
                "Dites-moi ce que vous recherchez comme logement !",
            )

        # =================================================
        # COUCHE 1D — CONVERSATIONS SIMPLES (0ms)
        # =================================================

        if message_lower in CONVERSATIONS_SIMPLES:
            logger.info("⚡ Conversation simple")
            reponses_simples = {
                "merci":          "Avec plaisir 😊 Puis-je vous aider pour autre chose ?",
                "merci beaucoup": "De rien ! N'hésitez pas si vous avez d'autres questions 😊",
                "ok":             "D'accord 😊 Souhaitez-vous affiner votre recherche ?",
                "oui":            "D'accord 😊 Précisez votre demande et je vous aide !",
                "non":            "Pas de souci 😊 Je peux vous proposer autre chose ?",
                "parfait":        "Super ! 😊 Autre chose ?",
                "super":          "Super ! 😊 Je peux vous aider à trouver un logement.",
            }
            reponse = reponses_simples.get(
                message_lower,
                "D'accord 😊 Comment puis-je vous aider ?",
            )
            return self._reponse_rapide(message, reponse)

        # =================================================
        # COUCHE 2 — DÉTECTION MÉTIER (règles absolues)
        # =================================================

        force_recherche    = self._detecter_intent_metier(message_lower)
        type_logement_metier = self._detecter_type_logement(message_lower)
        sanitaire_metier   = self._detecter_sanitaire(message_lower)
        budget_metier      = self._detecter_budget(message_lower)

        logger.info(
            "🔍 Règles métier → force=%s | type=%s | sanitaire=%s | budget=%s",
            force_recherche, type_logement_metier, sanitaire_metier, budget_metier,
        )

        # Sauvegarder le type détecté pour les échanges suivants
        if type_logement_metier:
            self._sauvegarder_dernier_type(type_logement_metier)

        # Si seulement sanitaire fourni (ex: "Ordinaire", "Sanitaire")
        # → récupérer le type du message précédent depuis le cache
        if sanitaire_metier and not type_logement_metier and not force_recherche:
            dernier_type = self._charger_dernier_type()
            if dernier_type:
                logger.info("🔄 Type récupéré du contexte : %s", dernier_type)
                type_logement_metier = dernier_type
                force_recherche = True

        # =================================================
        # COUCHE 3 — OLLAMA (seulement si cas ambigu)
        # =================================================

        type_logement = type_logement_metier
        sanitaire     = sanitaire_metier
        budget_max    = budget_metier
        intent        = "recherche_logement" if force_recherche else None

        if not force_recherche:
            try:
                intention_llm = analyser_intention(message, historique=historique)
                intent = intention_llm.get("intent", "conversation")

                if not type_logement:
                    type_logement = intention_llm.get("type_logement")
                if not sanitaire:
                    sanitaire = intention_llm.get("sanitaire")
                if not budget_max:
                    budget_max = intention_llm.get("budget_max")

            except Exception as e:
                logger.exception("❌ Erreur Ollama : %s", e)
                intent = "conversation"

        logger.info("🧠 Intent final : %s", intent)

        # =================================================
        # HORS DOMAINE (via Ollama)
        # =================================================

        if intent == "hors_domaine":
            return self._reponse_rapide(
                message,
                "Je suis spécialisé dans la recherche de logements à Lokossa 😊 "
                "Dites-moi quel type de logement vous cherchez !",
            )

        # =================================================
        # CONVERSATION GÉNÉRALE
        # =================================================

        if intent == "conversation":
            try:
                reponse = generer_reponse_conversation(message, historique=historique)
            except Exception as e:
                logger.exception("❌ Erreur génération réponse : %s", e)
                reponse = "Comment puis-je vous aider pour un logement à Lokossa ? 😊"
            return self._reponse_rapide(message, reponse)

        # =================================================
        # RECHERCHE LOGEMENT — UX INTELLIGENTE
        # =================================================

        if not type_logement:
            return self._reponse_rapide(
                message,
                "🏠 Quel type de logement recherchez-vous ?\n\n"
                "• Entrée coucher\n"
                "• Chambre salon\n"
                "• Deux chambres salon\n"
                "• Appartement\n"
                "• Boutique",
            )

        types_necessitant_sanitaire = {"chambre_salon", "entree_coucher", "deux_chambres"}
        if type_logement in types_necessitant_sanitaire and not sanitaire:
            return self._reponse_rapide(
                message,
                get_reponse_demande_precision(type_logement),
            )

        # =================================================
        # RECHERCHE BASE DE DONNÉES
        # =================================================

        logger.info(
            "🏠 Recherche DB → type=%s | budget=%s | sanitaire=%s",
            type_logement, budget_max, sanitaire,
        )

        unites = self._rechercher_avec_cache(type_logement, budget_max, sanitaire)
        logger.info("📦 %d unité(s) trouvée(s)", len(unites))

        for unite in unites:
            unite.distance = calculer_distance_universite(unite)

        self._derniers_resultats = unites
        self._sauvegarder_resultats(unites)

        if not unites:
            reponse = get_reponse_aucun_resultat(type_logement, budget_max, sanitaire)
            return self._reponse_rapide(message, reponse)

        reponse = get_reponse_recherche(unites)
        return self._reponse_rapide(message, reponse)
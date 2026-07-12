# apps/agent_ia/services/cache_service.py

"""
Service de cache pour optimiser les performances.

Utilise Django cache :
  - Redis (recommandé production)
  - Memcached
  - LocMem (développement)

Architecture :
  - cache_result   : décorateur cache pour fonctions pures
  - ChatMemory     : mémoire conversationnelle par utilisateur
"""

import hashlib
import json
import logging

from functools import wraps
from typing import Any, Callable, Dict, List, Optional

from django.core.cache import cache

logger = logging.getLogger(__name__)


# =========================================================
# DÉCORATEUR CACHE
# =========================================================

def cache_result(key_prefix: str, timeout: int = 3600):
    """
    Décorateur de mise en cache générique.

    IMPORTANT : exclut `self` des args pour éviter
    des clés de cache énormes et inutiles.

    Args:
        key_prefix : préfixe de la clé cache
        timeout    : durée en secondes (défaut 1h)
    """

    def decorator(func: Callable) -> Callable:

        @wraps(func)
        def wrapper(*args, **kwargs) -> Any:

            # Exclure self (args[0]) de la clé de cache
            # self n'est pas sérialisable et ne change pas le résultat
            args_for_key = args[1:] if args else args

            try:
                args_str = json.dumps(
                    args_for_key,
                    sort_keys=True,
                    default=str,
                    ensure_ascii=False,
                    separators=(",", ":"),
                )
                kwargs_str = json.dumps(
                    sorted(kwargs.items()),
                    sort_keys=True,
                    default=str,
                    ensure_ascii=False,
                    separators=(",", ":"),
                )
            except Exception:
                args_str = str(args_for_key)
                kwargs_str = str(sorted(kwargs.items()))

            hash_input = f"{args_str}|{kwargs_str}"
            cache_hash = hashlib.md5(
                hash_input.encode("utf-8")
            ).hexdigest()

            cache_key = f"{key_prefix}_{cache_hash}"

            # --- Lecture cache ---
            try:
                cached_value = cache.get(cache_key)
            except Exception:
                cached_value = None

            if cached_value is not None:
                logger.debug("✅ Cache hit : %s", cache_key)
                return cached_value

            # --- Exécution fonction ---
            result = func(*args, **kwargs)

            # --- Sauvegarde cache ---
            try:
                cache.set(cache_key, result, timeout)
                logger.debug("💾 Cache set : %s (timeout=%ds)", cache_key, timeout)
            except Exception as e:
                logger.warning("⚠️ Cache set échoué : %s", e)

            return result

        return wrapper

    return decorator


# =========================================================
# INVALIDATION CACHE
# =========================================================

def invalidate_cache(pattern: str) -> None:
    """
    Supprime les clés cache correspondant à un pattern.
    Fonctionne principalement avec django-redis.
    """
    try:
        if hasattr(cache, "delete_pattern"):
            cache.delete_pattern(f"*{pattern}*")
            logger.info("🗑️ Cache invalidé : pattern=%s", pattern)
    except Exception as e:
        logger.warning("⚠️ Invalidation cache échouée : %s", e)


# =========================================================
# MÉMOIRE CONVERSATIONNELLE
# =========================================================

class ChatMemory:
    """
    Mémoire conversationnelle par utilisateur.

    Format unifié {role, content} compatible avec :
      - llm_service.py (historique Ollama)
      - views.py (historique chargé depuis DB)
      - LangChain / OpenAI message format

    Stockage : Django cache (Redis recommandé).
    Durée    : 24h par défaut.
    """

    def __init__(self, user_id: int, max_history: int = 10):
        self.user_id = user_id
        self.max_history = max_history
        self.cache_key = f"chat_memory_{user_id}"

    # =====================================================
    # RÉCUPÉRATION HISTORIQUE
    # =====================================================

    def get_history(self) -> List[Dict[str, str]]:
        """
        Retourne l'historique au format List[{role, content}].
        Compatible avec llm_service et views.py.
        """
        try:
            history = cache.get(self.cache_key)

            if not history or not isinstance(history, list):
                return []

            # Normaliser les anciens formats {user, bot} si présents
            normalized = []
            for entry in history:
                if not isinstance(entry, dict):
                    continue
                # Nouveau format {role, content} → garder tel quel
                if "role" in entry and "content" in entry:
                    normalized.append(entry)
                # Ancien format {user, bot} → convertir
                elif "user" in entry or "bot" in entry:
                    if entry.get("user"):
                        normalized.append({
                            "role": "user",
                            "content": str(entry["user"])[:500],
                        })
                    if entry.get("bot"):
                        normalized.append({
                            "role": "assistant",
                            "content": str(entry["bot"])[:800],
                        })

            return normalized

        except Exception as e:
            logger.warning("⚠️ Erreur lecture mémoire : %s", e)
            return []

    # =====================================================
    # AJOUT ÉCHANGE
    # =====================================================

    def add_exchange(self, user_message: str, bot_response: str) -> None:
        """
        Ajoute un échange au format {role, content}.

        Les deux messages sont ajoutés séparément pour
        être directement compatibles avec le format
        attendu par Ollama / LangChain.
        """
        user_message = str(user_message).strip()[:500]
        bot_response = str(bot_response).strip()[:800]

        if not user_message or not bot_response:
            return

        history = self.get_history()

        history.append({"role": "user",      "content": user_message})
        history.append({"role": "assistant", "content": bot_response})

        # Limiter : max_history échanges = max_history * 2 messages
        max_messages = self.max_history * 2
        if len(history) > max_messages:
            history = history[-max_messages:]

        try:
            cache.set(self.cache_key, history, timeout=86400)
        except Exception as e:
            logger.warning("⚠️ Erreur sauvegarde mémoire : %s", e)

    # =====================================================
    # EFFACEMENT MÉMOIRE
    # =====================================================

    def clear(self) -> None:
        """Supprime toute la mémoire de l'utilisateur."""
        try:
            cache.delete(self.cache_key)
            logger.info("🗑️ Mémoire effacée pour user=%s", self.user_id)
        except Exception as e:
            logger.warning("⚠️ Erreur effacement mémoire : %s", e)

    # =====================================================
    # FORMATAGE POUR LLM (liste de dicts)
    # =====================================================

    def get_history_for_llm(self, max_exchanges: int = 4) -> List[Dict[str, str]]:
        """
        Retourne les N derniers échanges pour le LLM.
        Format : List[{role: str, content: str}]

        Optimisé pour llama3.2:1b :
          - Limité à 4 échanges (8 messages) max
          - Contenu tronqué pour rester dans num_ctx=512
        """
        history = self.get_history()

        if not history:
            return []

        # Garder les N derniers messages
        max_messages = max_exchanges * 2
        recent = history[-max_messages:]

        # Tronquer le contenu pour le petit modèle
        return [
            {
                "role": msg["role"],
                "content": msg["content"][:200],
            }
            for msg in recent
        ]
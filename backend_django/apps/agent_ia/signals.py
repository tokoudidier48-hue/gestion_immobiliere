# apps/agent_ia/signals.py

"""
Signals Django pour synchronisation FAISS.

RÈGLE IMPORTANTE :
  - post_save avec created=True  → ajout dans FAISS (asynchrone) ✅
  - post_save avec created=False → NE PAS ajouter (évite doublons) ⚠️
  - post_delete                  → log seulement (FAISS ne supporte pas
                                   la suppression fine) → rebuild manuel
"""

import logging
import threading
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver

logger = logging.getLogger(__name__)


# =========================================================
# AJOUT NOUVEAU LOGEMENT → FAISS (ASYNCHRONE)
# =========================================================

@receiver(post_save, sender="unites.Unite")
def sync_unite_to_vectorstore(sender, instance, created, **kwargs):
    """
    Synchronise FAISS uniquement lors de la CRÉATION d'une unité.
    L'indexation est lancée dans un thread séparé pour ne pas bloquer
    la requête HTTP.
    """
    if not created:
        # Mise à jour → on ne touche pas FAISS pour éviter les doublons
        logger.debug(
            "ℹ️ Unité %s mise à jour — FAISS non modifié (rebuild manuel si nécessaire)",
            instance.id,
        )
        return

    # Seulement les logements libres à Lokossa
    if not (
        instance.statut == "libre"
        and instance.ville
        and "lokossa" in instance.ville.lower()
    ):
        logger.debug(
            "ℹ️ Unité %s ignorée (statut=%s, ville=%s)",
            instance.id, instance.statut, instance.ville,
        )
        return

    # ⭐ Lancer l'indexation en arrière-plan (thread séparé)
    def _indexer():
        try:
            from .services.vector_service import add_unite_to_vectorstore
            add_unite_to_vectorstore(instance)
            logger.info("➕ Unité %s ajoutée dans FAISS (asynchrone)", instance.id)
        except Exception as e:
            logger.exception("❌ Erreur sync FAISS unité %s : %s", instance.id, e)

    threading.Thread(target=_indexer, daemon=True).start()
    logger.info("🚀 Indexation FAISS lancée en arrière-plan pour l'unité %s", instance.id)


# =========================================================
# SUPPRESSION LOGEMENT → LOG UNIQUEMENT
# =========================================================

@receiver(post_delete, sender="unites.Unite")
def remove_unite_from_vectorstore(sender, instance, **kwargs):
    """
    FAISS ne supporte pas la suppression fine d'un document.
    On loggue uniquement pour alerter l'admin qu'un rebuild
    manuel est recommandé.
    """
    logger.warning(
        "⚠️ Unité %s supprimée — FAISS contient encore l'entrée. "
        "Rebuild recommandé via /api/agent-ia/conversations/reinitialiser_base/",
        instance.id,
    )
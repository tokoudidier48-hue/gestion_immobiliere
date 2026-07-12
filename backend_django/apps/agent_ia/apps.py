# apps/agent_ia/apps.py

from django.apps import AppConfig
import logging

logger = logging.getLogger(__name__)


class AgentIaConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "agent_ia"
    verbose_name = "🤖 Agent IA Loya"

    def ready(self):
        """
        Chargement des signals au démarrage.
        Import différé pour éviter les problèmes
        si la DB n'est pas encore prête.
        """
        try:
            from . import signals  # noqa: F401
            logger.info("✅ Signals agent_ia chargés")
        except Exception as e:
            logger.warning("⚠️ Erreur chargement signals agent_ia : %s", e)
# apps/agent_ia/services/vector_service.py

"""
Service de gestion de la base vectorielle FAISS.

RÔLE :
  - Recherche sémantique sur les logements et infos Lokossa
  - NE remplace PAS la DB Django pour les logements réels
  - Utilisé en complément de rechercher_unites_db()

IMPORTANT :
  FAISS ne supporte pas la suppression fine.
  En cas de suppression de logement → rebuild manuel via admin.
"""

import logging
import threading
import shutil
from pathlib import Path
from typing import List, Optional

from django.conf import settings
from django.apps import apps

from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS
from langchain_core.documents import Document

from ..data.lokossa_data import QUARTIERS_LOKOSSA, INFO_LOKOSSA

logger = logging.getLogger(__name__)


# =========================================================
# SINGLETONS THREAD-SAFE
# =========================================================

_vectorstore_lock = threading.Lock()
_embeddings_lock = threading.Lock()
_faiss_lock = threading.Lock()  # 🔒 Verrou pour les opérations FAISS (évite Already borrowed)

_VECTORSTORE: Optional[FAISS] = None
_EMBEDDINGS: Optional[HuggingFaceEmbeddings] = None

VECTORSTORE_PATH = None  # Initialisé à la première utilisation


def _get_vectorstore_path() -> Path:
    """Retourne le chemin du vectorstore (calculé une seule fois)."""
    global VECTORSTORE_PATH
    if VECTORSTORE_PATH is None:
        VECTORSTORE_PATH = Path(settings.BASE_DIR) / "data" / "vectorstore_lokossa"
    return VECTORSTORE_PATH


# =========================================================
# EMBEDDINGS
# =========================================================

def get_embeddings() -> HuggingFaceEmbeddings:
    """Singleton thread-safe pour les embeddings HuggingFace."""
    global _EMBEDDINGS

    if _EMBEDDINGS is None:
        with _embeddings_lock:
            if _EMBEDDINGS is None:
                try:
                    _EMBEDDINGS = HuggingFaceEmbeddings(
                        model_name="sentence-transformers/all-MiniLM-L6-v2",
                        model_kwargs={"device": "cpu"},
                        encode_kwargs={"normalize_embeddings": True},
                        show_progress=False,  # ⭐ Désactive la barre de progression (gagne du temps)
                    )
                    logger.info("✅ Embeddings HuggingFace chargés")
                except Exception as e:
                    logger.exception("❌ Erreur chargement embeddings : %s", e)
                    raise

    return _EMBEDDINGS


# =========================================================
# CONSTRUCTION DOCUMENT LOGEMENT
# =========================================================

def _document_depuis_unite(unite) -> Document:
    """
    Construit un Document FAISS depuis une Unite Django.
    Fonction centralisée pour éviter la duplication de code.
    """
    type_display = (
        unite.get_type_unite_display()
        if hasattr(unite, "get_type_unite_display")
        else unite.type_unite
    )
    douche_display = (
        unite.get_type_douche_display()
        if hasattr(unite, "get_type_douche_display")
        else "Non spécifiée"
    )

    contenu = (
        f"Logement disponible à Lokossa.\n"
        f"Type : {type_display}\n"
        f"Nom : {unite.nom}\n"
        f"Adresse : {unite.adresse}\n"
        f"Prix : {unite.loyer} FCFA par mois\n"
        f"Description : {unite.description or 'Non spécifiée'}\n"
        f"Douche : {douche_display}\n"
        f"Garage : {'Oui' if unite.garage else 'Non'}\n"
        f"Prépayé : {'Oui' if unite.prepaye else 'Non'}"
    )

    return Document(
        page_content=contenu,
        metadata={
            "type": "logement",
            "unite_id": unite.id,
            "type_code": unite.type_unite,
            "prix": float(unite.loyer),
        },
    )


# =========================================================
# CRÉATION DES DOCUMENTS (avec limitation)
# =========================================================

def _creer_documents() -> List[Document]:
    """
    Crée tous les documents à indexer dans FAISS.
    Utilise select_related pour éviter les requêtes N+1.
    Limite le nombre d'unités à 100 pour éviter la lenteur.
    """
    # Import différé pour éviter les problèmes au démarrage Django
    Unite = apps.get_model("unites", "Unite")

    documents: List[Document] = []

    # --- Logements disponibles (limités à 100 pour éviter la lenteur) ---
    unites = Unite.objects.filter(
        statut="libre",
        ville__icontains="lokossa",
    ).select_related()[:100]  # ⭐ Limite à 100 unités

    for unite in unites:
        documents.append(_document_depuis_unite(unite))

    # --- Informations générales Lokossa ---
    documents.append(
        Document(
            page_content=(
                f"Lokossa est une ville du Bénin.\n"
                f"Description : {INFO_LOKOSSA['description']}\n"
                f"Département : {INFO_LOKOSSA['departement']}\n"
                f"Population : {INFO_LOKOSSA['population']}"
            ),
            metadata={"type": "info_lokossa"},
        )
    )

    # --- Quartiers ---
    for quartier, coords in QUARTIERS_LOKOSSA.items():
        documents.append(
            Document(
                page_content=(
                    f"Quartier {quartier} situé à Lokossa. "
                    f"Ce quartier peut contenir des logements étudiants."
                ),
                metadata={
                    "type": "quartier",
                    "nom": quartier,
                    "lat": coords.get("lat"),
                    "lon": coords.get("lon"),
                },
            )
        )

    logger.info("✅ %d documents créés pour FAISS", len(documents))
    return documents


# =========================================================
# CHARGEMENT / CRÉATION VECTORSTORE
# =========================================================

def get_vectorstore(force_recreate: bool = False) -> FAISS:
    """
    Charge ou crée la base vectorielle FAISS (thread-safe).

    - Si déjà en mémoire → retour immédiat
    - Si index sur disque → chargement
    - Sinon → création depuis la DB
    """
    global _VECTORSTORE

    if _VECTORSTORE is not None and not force_recreate:
        return _VECTORSTORE

    with _vectorstore_lock:
        # Double-check après acquisition du verrou
        if _VECTORSTORE is not None and not force_recreate:
            return _VECTORSTORE

        vectorstore_path = _get_vectorstore_path()
        vectorstore_path.mkdir(parents=True, exist_ok=True)

        embeddings = get_embeddings()
        index_file = vectorstore_path / "index.faiss"

        try:
            if index_file.exists() and not force_recreate:
                logger.info("📂 Chargement FAISS depuis disque")
                _VECTORSTORE = FAISS.load_local(
                    str(vectorstore_path),
                    embeddings,
                    allow_dangerous_deserialization=True,
                )
            else:
                logger.info("🔄 Création base vectorielle FAISS")
                documents = _creer_documents()

                if not documents:
                    raise ValueError("Aucun document à indexer dans FAISS")

                _VECTORSTORE = FAISS.from_documents(documents, embeddings)
                _VECTORSTORE.save_local(str(vectorstore_path))
                logger.info(
                    "✅ FAISS créé avec %d documents", len(documents)
                )

            return _VECTORSTORE

        except Exception as e:
            logger.exception("❌ Erreur vectorstore : %s", e)
            raise


# =========================================================
# REBUILD COMPLET
# =========================================================

def rebuild_vectorstore() -> None:
    """
    Reconstruit totalement FAISS depuis la DB.
    À appeler manuellement depuis l'admin ou une commande Django.
    """
    global _VECTORSTORE

    with _vectorstore_lock:
        _VECTORSTORE = None
        vectorstore_path = _get_vectorstore_path()

        try:
            if vectorstore_path.exists():
                shutil.rmtree(vectorstore_path)
                logger.info("🗑️ Ancien vectorstore supprimé")

        except Exception as e:
            logger.exception("❌ Erreur suppression vectorstore : %s", e)

    # Recréation hors verrou pour ne pas bloquer trop longtemps
    try:
        get_vectorstore(force_recreate=True)
        logger.info("✅ Base vectorielle reconstruite avec succès")
    except Exception as e:
        logger.exception("❌ Erreur reconstruction FAISS : %s", e)


# =========================================================
# AJOUT UNITAIRE (avec verrou)
# =========================================================

def add_unite_to_vectorstore(unite) -> None:
    """
    Ajoute une nouvelle unité dans FAISS sans tout reconstruire.

    ATTENTION : FAISS ne supporte pas la mise à jour.
    Cette fonction ne doit être appelée que pour les nouvelles unités
    (created=True dans le signal post_save).
    Pour les mises à jour → rebuild manuel recommandé.
    """
    try:
        # 🔒 Verrou global pour éviter les accès concurrents (Already borrowed)
        with _faiss_lock:
            vectorstore = get_vectorstore()
            vectorstore_path = _get_vectorstore_path()

            doc = _document_depuis_unite(unite)
            vectorstore.add_documents([doc])
            vectorstore.save_local(str(vectorstore_path))

            logger.info("✅ Unité %s ajoutée dans FAISS", unite.id)

    except Exception as e:
        logger.exception("❌ Erreur ajout unité FAISS %s : %s", unite.id, e)


# =========================================================
# RECHERCHE SÉMANTIQUE
# =========================================================

def rechercher_similarite(
    message: str,
    k: int = 3,
    type_filtre: Optional[str] = None,
    score_threshold: float = 1.2,
) -> List[Document]:
    """
    Recherche sémantique dans FAISS.

    Retourne les documents les plus proches sémantiquement.
    NE retourne PAS de logements inventés — seulement des
    documents indexés depuis la DB réelle.

    Args:
        message         — texte de recherche
        k               — nombre max de résultats
        type_filtre     — "logement" | "quartier" | "info_lokossa" | None
        score_threshold — seuil max de distance (plus petit = plus strict)
    """
    # Ignorer les petits messages sans intérêt sémantique
    MESSAGES_IGNORES = {
        "bonjour", "salut", "merci", "ok",
        "au revoir", "bye", "ça va", "ca va",
        "comment ça va", "bonsoir", "hello",
    }
    if message.lower().strip() in MESSAGES_IGNORES:
        return []

    if not message.strip():
        return []

    try:
        vectorstore = get_vectorstore()

        docs_with_scores = vectorstore.similarity_search_with_score(
            message, k=k * 2
        )

        filtered: List[Document] = []
        for doc, score in docs_with_scores:
            logger.debug("📄 Score FAISS=%.3f | %s", score, doc.page_content[:80])
            if score <= score_threshold:
                filtered.append(doc)

        # Filtre par type si demandé
        if type_filtre:
            filtered = [
                d for d in filtered
                if d.metadata.get("type") == type_filtre
            ]

        result = filtered[:k]
        logger.debug("🔍 FAISS : %d document(s) retenus", len(result))
        return result

    except Exception as e:
        logger.exception("❌ Erreur recherche similarité : %s", e)
        return []
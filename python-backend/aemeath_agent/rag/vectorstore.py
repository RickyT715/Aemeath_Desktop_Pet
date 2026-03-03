"""ChromaDB vector store with configurable embeddings."""

import logging
from pathlib import Path

from langchain_community.vectorstores import Chroma
from langchain_core.embeddings import Embeddings

from aemeath_agent.config import get_settings

logger = logging.getLogger(__name__)

_vectorstore: Chroma | None = None


def _create_embeddings(model: str) -> Embeddings:
    """Create an embedding function based on the configured model.

    Tries gemini-embedding-001 first (free, high quality), falls back to
    local all-MiniLM-L6-v2 if the API key is missing or the call fails.
    """
    if model == "gemini":
        settings = get_settings()
        if settings.google_api_key:
            try:
                from langchain_google_genai import GoogleGenerativeAIEmbeddings

                return GoogleGenerativeAIEmbeddings(
                    model="models/gemini-embedding-001",
                    google_api_key=settings.google_api_key,
                )
            except Exception:
                logger.warning("Gemini embeddings failed, falling back to local model")

    # Fallback: local sentence-transformers model
    from langchain_community.embeddings import HuggingFaceEmbeddings

    return HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")


def get_vectorstore() -> Chroma | None:
    """Get or create the singleton ChromaDB vector store.

    Returns:
        A Chroma vector store instance, or None if initialization fails.
    """
    global _vectorstore

    if _vectorstore is not None:
        return _vectorstore

    try:
        settings = get_settings()
        persist_dir = settings.chromadb_path
        Path(persist_dir).mkdir(parents=True, exist_ok=True)

        embeddings = _create_embeddings(settings.embedding_model)

        _vectorstore = Chroma(
            collection_name="user_knowledge",
            embedding_function=embeddings,
            persist_directory=persist_dir,
        )
        logger.info("ChromaDB vector store initialized at %s", persist_dir)
        return _vectorstore
    except Exception:
        logger.exception("Failed to initialize vector store")
        return None

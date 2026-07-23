"""ChromaDB collection for Aemeath's episodic memories.

Separate from the user_knowledge RAG collection.  Reuses the same
ChromaDB persist directory and embedding function for consistency.
"""

import logging
from pathlib import Path

from langchain_community.vectorstores import Chroma
from langchain_core.embeddings import Embeddings

from aemeath_agent.config import get_settings

logger = logging.getLogger(__name__)

_memory_vectorstore: Chroma | None = None

COLLECTION_NAME = "aemeath_memories"


def _create_embeddings(model: str) -> Embeddings:
    """Create an embedding function (same logic as rag/vectorstore.py)."""
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

    from langchain_community.embeddings import HuggingFaceEmbeddings

    return HuggingFaceEmbeddings(model_name="all-MiniLM-L6-v2")


def get_memory_vectorstore() -> Chroma | None:
    """Get or create the singleton episodic memory vector store.

    Returns:
        A Chroma vector store for the ``aemeath_memories`` collection,
        or ``None`` if initialization fails.
    """
    global _memory_vectorstore

    if _memory_vectorstore is not None:
        return _memory_vectorstore

    try:
        settings = get_settings()
        persist_dir = settings.chromadb_path
        Path(persist_dir).mkdir(parents=True, exist_ok=True)

        embeddings = _create_embeddings(settings.embedding_model)

        _memory_vectorstore = Chroma(
            collection_name=COLLECTION_NAME,
            embedding_function=embeddings,
            persist_directory=persist_dir,
        )
        logger.info(
            "Memory vector store (%s) initialized at %s",
            COLLECTION_NAME,
            persist_dir,
        )
        return _memory_vectorstore
    except Exception:
        logger.exception("Failed to initialize memory vector store")
        return None


def reset_memory_vectorstore() -> None:
    """Force re-creation of the memory vector store."""
    global _memory_vectorstore
    _memory_vectorstore = None

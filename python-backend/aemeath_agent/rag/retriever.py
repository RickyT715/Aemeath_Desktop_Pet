"""Hybrid retriever with BM25 + semantic search and cross-encoder reranking."""

import logging

from langchain_core.retrievers import BaseRetriever

from aemeath_agent.rag.vectorstore import get_vectorstore

logger = logging.getLogger(__name__)

_retriever: BaseRetriever | None = None


def _build_retriever() -> BaseRetriever | None:
    """Build the hybrid retriever pipeline.

    Pipeline:
    1. EnsembleRetriever (BM25 weight=0.4, semantic weight=0.6)
    2. CrossEncoderReranker (retrieve 20, return top 5)
    """
    vectorstore = get_vectorstore()
    if vectorstore is None:
        return None

    try:
        # Semantic retriever from ChromaDB
        vector_retriever = vectorstore.as_retriever(search_kwargs={"k": 20})

        # BM25 sparse retriever — needs existing documents
        try:
            docs = vectorstore.get()
            if not docs or not docs.get("documents"):
                logger.info("No documents in vector store yet; using vector-only retriever")
                return vector_retriever

            from langchain_community.retrievers import BM25Retriever
            from langchain_core.documents import Document

            bm25_docs = [
                Document(
                    page_content=text,
                    metadata=meta if meta else {},
                )
                for text, meta in zip(docs["documents"], docs.get("metadatas", [{}] * len(docs["documents"])))
            ]
            bm25_retriever = BM25Retriever.from_documents(bm25_docs)
            bm25_retriever.k = 20
        except Exception:
            logger.warning("BM25 retriever initialization failed; using vector-only")
            return vector_retriever

        # Ensemble: combine BM25 + semantic with reciprocal rank fusion
        from langchain.retrievers import EnsembleRetriever

        ensemble = EnsembleRetriever(
            retrievers=[bm25_retriever, vector_retriever],
            weights=[0.4, 0.6],
        )

        # Cross-encoder reranker for precision
        try:
            from langchain.retrievers import ContextualCompressionRetriever
            from langchain.retrievers.document_compressors import CrossEncoderReranker
            from sentence_transformers import CrossEncoder

            compressor = CrossEncoderReranker(
                model=CrossEncoder("cross-encoder/ms-marco-MiniLM-L-6-v2"),
                top_n=5,
            )
            return ContextualCompressionRetriever(
                base_compressor=compressor,
                base_retriever=ensemble,
            )
        except Exception:
            logger.warning("Cross-encoder reranker unavailable; using ensemble without reranking")
            return ensemble

    except Exception:
        logger.exception("Failed to build retriever")
        return None


def get_retriever() -> BaseRetriever | None:
    """Get or create the singleton hybrid retriever.

    Returns None if the vector store is not initialized or has no documents.
    """
    global _retriever

    if _retriever is not None:
        return _retriever

    _retriever = _build_retriever()
    return _retriever


def reset_retriever() -> None:
    """Force re-creation of the retriever (e.g., after new document ingestion)."""
    global _retriever
    _retriever = None

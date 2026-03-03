"""RAG retrieval tool — searches the user's personal knowledge base."""

import json
import logging

from langchain_core.tools import tool

logger = logging.getLogger(__name__)

_retriever = None


def configure(retriever: object | None) -> None:
    """Set the RAG retriever instance (called once RAG module is initialized)."""
    global _retriever
    _retriever = retriever


@tool
def rag_retrieve(query: str) -> str:
    """Search the user's personal knowledge base for relevant information.

    Use this when the user asks about their documents, notes, or saved content.
    Returns relevant passages from ingested documents.

    Args:
        query: The search query to find relevant documents.
    """
    if _retriever is None:
        return json.dumps({
            "status": "error",
            "message": "RAG not initialized. No documents have been ingested yet.",
        })

    try:
        docs = _retriever.invoke(query)
        results = []
        for doc in docs:
            results.append({
                "source": doc.metadata.get("source", "unknown"),
                "content": doc.page_content[:500],
            })

        if not results:
            return json.dumps({"status": "success", "message": "No relevant documents found.", "results": []})

        return json.dumps({"status": "success", "results": results})
    except Exception as e:
        logger.exception("RAG retrieval failed")
        return json.dumps({"status": "error", "message": str(e)})

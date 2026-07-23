"""Retrieve memory tool — searches long-term memory for relevant facts."""

import json
import logging

from langchain_core.tools import tool

logger = logging.getLogger(__name__)


@tool
def retrieve_memory(query: str, category: str = "all") -> str:
    """Search my long-term memory for facts related to a query.

    Use when the user references something from the past, or when
    I want to recall relevant context before responding.

    Args:
        query: The search query to find relevant memories.
        category: Filter by category — 'facts', 'episodes', 'preferences', or 'all'.
    """
    results: list[dict[str, str]] = []

    # 1. Search ChromaDB episodic memories (semantic search)
    try:
        from aemeath_agent.rag.memory_vectorstore import get_memory_vectorstore

        vs = get_memory_vectorstore()
        if vs is not None:
            docs_with_scores = vs.similarity_search_with_relevance_scores(query, k=5)
            for doc, score in docs_with_scores:
                doc_type = doc.metadata.get("type", "memory")
                if category != "all" and doc_type != category:
                    continue
                results.append({
                    "content": doc.page_content,
                    "type": doc_type,
                    "source": "episodic",
                    "score": f"{score:.2f}",
                    "created_at": doc.metadata.get("created_at", ""),
                })
    except Exception:
        logger.exception("ChromaDB memory search failed")

    # 2. Search persistent JSON store (keyword matching)
    try:
        from aemeath_agent.agent.memory_store import (
            NAMESPACE_EPISODES,
            NAMESPACE_FACTS,
            NAMESPACE_PREFERENCES,
            get_memory_store,
        )

        store = get_memory_store()
        query_lower = query.lower()

        namespace_map = {
            "facts": [NAMESPACE_FACTS],
            "episodes": [NAMESPACE_EPISODES],
            "preferences": [NAMESPACE_PREFERENCES],
            "all": [NAMESPACE_FACTS, NAMESPACE_EPISODES, NAMESPACE_PREFERENCES],
        }
        namespaces = namespace_map.get(category, namespace_map["all"])

        for ns in namespaces:
            for _key, item in store._data.get(ns, {}).items():
                content = item.value.get("content", "")
                if query_lower in content.lower():
                    # Avoid duplicates — skip if this content already appears in results
                    if any(r["content"] == content for r in results):
                        continue
                    ns_name = ns[-1] if ns else "unknown"
                    results.append({
                        "content": content,
                        "type": ns_name,
                        "source": "store",
                        "created_at": item.updated_at.isoformat() if item.updated_at else "",
                    })
    except Exception:
        logger.exception("Persistent store memory search failed")

    if not results:
        return json.dumps({
            "status": "success",
            "message": "No relevant memories found.",
            "results": [],
        })

    # Limit to top 5
    results = results[:5]

    return json.dumps({"status": "success", "results": results})

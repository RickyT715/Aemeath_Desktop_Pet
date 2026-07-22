"""Save memory tool — persists facts about the user to LangGraph Store + ChromaDB."""

import json
import logging
import uuid
from datetime import datetime, timezone

from langchain_core.tools import tool

from aemeath_agent.agent.memory_store import (
    NAMESPACE_EPISODES,
    NAMESPACE_FACTS,
    NAMESPACE_PREFERENCES,
    get_memory_store,
)

logger = logging.getLogger(__name__)


@tool
def save_memory(content: str, category: str = "facts", tags: str = "") -> str:
    """Save an important fact, preference, or memorable moment about the user.

    Use this when you learn something worth remembering for future conversations,
    such as the user's name, occupation, interests, or a significant event.

    Args:
        content: The information to remember.
        category: One of 'facts', 'episodes', 'preferences'.
        tags: Comma-separated topic tags for easier retrieval (e.g. "name,personal").
    """
    try:
        store = get_memory_store()

        namespace_map = {
            "facts": NAMESPACE_FACTS,
            "episodes": NAMESPACE_EPISODES,
            "preferences": NAMESPACE_PREFERENCES,
        }
        namespace = namespace_map.get(category, NAMESPACE_FACTS)

        tag_list = [t.strip() for t in tags.split(",") if t.strip()] if tags else []

        key = str(uuid.uuid4())
        store.put(namespace, key, {"content": content, "tags": tag_list})

        logger.info("Saved memory [%s]: %s", category, content[:80])

        # Also upsert into ChromaDB for semantic retrieval
        _upsert_to_chromadb(content, category, tag_list)

        return json.dumps({"status": "success", "message": f"Remembered: {content[:100]}"})
    except Exception as e:
        logger.exception("Save memory failed")
        return json.dumps({"status": "error", "message": str(e)})


def _upsert_to_chromadb(content: str, category: str, tags: list[str]) -> None:
    """Store the memory in ChromaDB for semantic search, with basic dedup."""
    try:
        from aemeath_agent.rag.memory_vectorstore import get_memory_vectorstore

        vs = get_memory_vectorstore()
        if vs is None:
            return

        # Basic conflict resolution: check if a very similar memory exists
        try:
            existing = vs.similarity_search_with_relevance_scores(content, k=1)
            if existing:
                _doc, score = existing[0]
                if score > 0.85:
                    logger.info("Skipping ChromaDB upsert — similar memory exists (score=%.2f)", score)
                    return
        except Exception:
            pass  # If dedup check fails, just insert anyway

        now_iso = datetime.now(timezone.utc).isoformat()
        metadata = {
            "type": category,
            "importance": 0.6,
            "created_at": now_iso,
            "source": "agent_save",
            "tags": ",".join(tags) if tags else "",
        }
        vs.add_texts(
            texts=[content],
            metadatas=[metadata],
            ids=[str(uuid.uuid4())],
        )
    except Exception:
        logger.exception("ChromaDB upsert failed (non-fatal)")

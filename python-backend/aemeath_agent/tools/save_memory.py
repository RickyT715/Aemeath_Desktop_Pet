"""Save memory tool — persists facts about the user to LangGraph Store."""

import json
import logging
import uuid

from langchain_core.tools import tool

from aemeath_agent.agent.memory_store import (
    NAMESPACE_EPISODES,
    NAMESPACE_FACTS,
    NAMESPACE_PREFERENCES,
    get_memory_store,
)

logger = logging.getLogger(__name__)


@tool
def save_memory(content: str, category: str = "facts") -> str:
    """Save an important fact, preference, or memorable moment about the user.

    Use this when you learn something worth remembering for future conversations,
    such as the user's name, occupation, interests, or a significant event.

    Args:
        content: The information to remember.
        category: One of 'facts', 'episodes', 'preferences'.
    """
    try:
        store = get_memory_store()

        namespace_map = {
            "facts": NAMESPACE_FACTS,
            "episodes": NAMESPACE_EPISODES,
            "preferences": NAMESPACE_PREFERENCES,
        }
        namespace = namespace_map.get(category, NAMESPACE_FACTS)
        key = str(uuid.uuid4())

        store.put(namespace, key, {"content": content})

        logger.info("Saved memory [%s]: %s", category, content[:80])
        return json.dumps({"status": "success", "message": f"Remembered: {content[:100]}"})
    except Exception as e:
        logger.exception("Save memory failed")
        return json.dumps({"status": "error", "message": str(e)})

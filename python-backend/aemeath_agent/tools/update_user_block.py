"""Update user block tool — MemGPT-style agent-editable user summary."""

import json
import logging

from langchain_core.tools import tool

logger = logging.getLogger(__name__)

_MAX_BLOCK_LENGTH = 1200


@tool
def update_user_block(new_content: str) -> str:
    """Rewrite the summary of what I know about the user.

    This text appears in my system prompt every turn so I never forget.
    Keep it concise (<1200 characters).
    Include: name, key facts, current interests, communication preferences.
    Call this when you learn something important about the user.

    Args:
        new_content: The new user summary text to save.
    """
    try:
        from aemeath_agent.agent.memory_store import get_memory_blocks

        if len(new_content) > _MAX_BLOCK_LENGTH:
            new_content = new_content[:_MAX_BLOCK_LENGTH]

        blocks = get_memory_blocks()
        blocks.put("user", new_content)

        logger.info("User block updated (%d chars)", len(new_content))
        return json.dumps({
            "status": "success",
            "message": f"User block updated ({len(new_content)} chars).",
        })
    except Exception as e:
        logger.exception("Failed to update user block")
        return json.dumps({"status": "error", "message": str(e)})

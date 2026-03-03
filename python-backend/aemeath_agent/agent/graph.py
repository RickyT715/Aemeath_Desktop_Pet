"""LangGraph agent factory — creates the Aemeath ReAct agent."""

import logging
import os
from typing import Any

from langgraph.prebuilt import create_react_agent

from aemeath_agent.agent.checkpointer import create_checkpointer
from aemeath_agent.agent.memory_store import get_memory_store
from aemeath_agent.agent.prompts import build_system_prompt
from aemeath_agent.config import Settings

logger = logging.getLogger(__name__)


def _get_model_string(settings: Settings) -> str:
    """Return the LangGraph model string based on configured provider."""
    if settings.ai_provider == "gemini":
        return "google-genai:gemini-2.0-flash"
    if settings.ai_provider == "proxy":
        os.environ["ANTHROPIC_BASE_URL"] = f"{settings.proxy_base_url}/v1"
        return "anthropic:claude-sonnet-4-5-20250929"
    return "anthropic:claude-sonnet-4-20250514"


async def create_aemeath_agent(settings: Settings) -> Any:
    """Create and return a fully configured LangGraph ReAct agent.

    The agent is configured with:
    - Model selection based on ai_provider setting
    - All 9 tools + save_memory
    - SQLite checkpointer for conversation persistence
    - InMemoryStore for long-term cross-session memory
    - Aemeath's character system prompt

    Args:
        settings: Application settings with API keys and paths.

    Returns:
        A compiled LangGraph agent ready for invoke/astream.
    """
    from aemeath_agent.tools import get_all_tools

    model = _get_model_string(settings)
    logger.info("Creating agent with model: %s", model)

    checkpointer = await create_checkpointer(settings.agent_db_path)
    store = get_memory_store()
    tools = get_all_tools(settings)
    system_prompt = build_system_prompt()

    agent = create_react_agent(
        model,
        tools=tools,
        prompt=system_prompt,
        checkpointer=checkpointer,
        store=store,
    )

    logger.info("Agent created with %d tools", len(tools))
    return agent

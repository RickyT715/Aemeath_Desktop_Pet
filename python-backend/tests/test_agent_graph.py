"""Tests for the LangGraph agent factory (agent/graph.py)."""

import sys
from types import ModuleType
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


# The langgraph.checkpoint.sqlite package is optional and may not be installed.
# We need to mock it so that importing aemeath_agent.agent.graph (which imports
# checkpointer, which imports AsyncSqliteSaver) doesn't fail at collection time.

def _ensure_checkpoint_mock():
    """Insert a fake langgraph.checkpoint.sqlite.aio module if missing."""
    key = "langgraph.checkpoint.sqlite"
    key_aio = "langgraph.checkpoint.sqlite.aio"
    if key not in sys.modules:
        fake_sqlite = ModuleType(key)
        fake_aio = ModuleType(key_aio)
        fake_aio.AsyncSqliteSaver = MagicMock(name="AsyncSqliteSaver")
        fake_sqlite.aio = fake_aio
        sys.modules[key] = fake_sqlite
        sys.modules[key_aio] = fake_aio


_ensure_checkpoint_mock()

from aemeath_agent.config import Settings


def _make_settings(**overrides) -> Settings:
    return Settings(_env_file=None, **overrides)  # type: ignore[call-arg]


# ---- _get_model_string -------------------------------------------------------

def test_model_string_defaults_to_claude():
    from aemeath_agent.agent.graph import _get_model_string

    settings = _make_settings(ai_provider="claude")
    assert _get_model_string(settings) == "anthropic:claude-sonnet-4-20250514"


def test_model_string_gemini():
    from aemeath_agent.agent.graph import _get_model_string

    settings = _make_settings(ai_provider="gemini")
    assert _get_model_string(settings) == "google-genai:gemini-2.0-flash"


def test_model_string_proxy_sets_base_url_and_returns_anthropic():
    import os
    from aemeath_agent.agent.graph import _get_model_string

    settings = _make_settings(ai_provider="proxy", proxy_base_url="http://localhost:42069")
    result = _get_model_string(settings)
    assert result == "anthropic:claude-sonnet-4-5-20250929"
    assert os.environ.get("ANTHROPIC_BASE_URL") == "http://localhost:42069/v1"

    # Clean up
    os.environ.pop("ANTHROPIC_BASE_URL", None)


def test_model_string_unknown_provider_falls_back_to_claude():
    from aemeath_agent.agent.graph import _get_model_string

    settings = _make_settings(ai_provider="openai")
    # Any non-"gemini"/"proxy" provider defaults to Claude
    assert "anthropic" in _get_model_string(settings)


# ---- create_aemeath_agent ----------------------------------------------------

@pytest.mark.asyncio
async def test_create_agent_calls_create_react_agent():
    """Verify the factory wires tools, checkpointer, store, and prompt."""
    fake_agent = MagicMock(name="compiled_agent")
    fake_checkpointer = MagicMock(name="checkpointer")
    fake_tools = [MagicMock(name=f"tool_{i}") for i in range(9)]

    with (
        patch(
            "aemeath_agent.agent.graph.create_react_agent",
            return_value=fake_agent,
        ) as mock_create,
        patch(
            "aemeath_agent.agent.graph.create_checkpointer",
            new_callable=AsyncMock,
            return_value=fake_checkpointer,
        ),
        patch(
            "aemeath_agent.tools.get_all_tools",
            return_value=fake_tools,
        ),
    ):
        from aemeath_agent.agent.graph import create_aemeath_agent

        settings = _make_settings()
        result = await create_aemeath_agent(settings)

        assert result is fake_agent
        mock_create.assert_called_once()

        call_kwargs = mock_create.call_args
        assert call_kwargs.kwargs["tools"] is fake_tools
        assert call_kwargs.kwargs["checkpointer"] is fake_checkpointer


@pytest.mark.asyncio
async def test_create_agent_passes_system_prompt():
    """Verify the system prompt from build_system_prompt is forwarded."""
    with (
        patch(
            "aemeath_agent.agent.graph.create_react_agent",
            return_value=MagicMock(),
        ) as mock_create,
        patch(
            "aemeath_agent.agent.graph.create_checkpointer",
            new_callable=AsyncMock,
            return_value=MagicMock(),
        ),
        patch(
            "aemeath_agent.tools.get_all_tools",
            return_value=[],
        ),
        patch(
            "aemeath_agent.agent.graph.build_system_prompt",
            return_value="test-prompt",
        ),
    ):
        from aemeath_agent.agent.graph import create_aemeath_agent

        await create_aemeath_agent(_make_settings())

        call_kwargs = mock_create.call_args
        assert call_kwargs.kwargs["prompt"] == "test-prompt"

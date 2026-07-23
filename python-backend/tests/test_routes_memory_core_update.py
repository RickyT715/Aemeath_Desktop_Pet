"""Tests for the /memory/core/update endpoint."""

from unittest.mock import MagicMock, patch

import pytest

import aemeath_agent.agent.memory_store as ms


class TestCoreUpdateEndpoint:
    """Tests for update_core_memory route function."""

    @pytest.fixture(autouse=True)
    def _reset_singletons(self):
        """Reset memory store singletons before each test."""
        ms._store = None
        ms._blocks = None
        yield
        ms._store = None
        ms._blocks = None

    async def test_update_with_facts(self):
        from aemeath_agent.api.routes_memory import update_core_memory
        from aemeath_agent.api.models import MemoryCoreUpdateRequest

        mock_store = MagicMock()
        with patch.dict("sys.modules", {
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(return_value=mock_store),
                NAMESPACE_FACTS=("memory", "facts"),
                NAMESPACE_EPISODES=("memory", "episodes"),
                NAMESPACE_PREFERENCES=("memory", "preferences"),
            ),
        }):
            req = MemoryCoreUpdateRequest(
                user_facts=[{"fact": "User is a student", "category": "occupation"}],
                preferences=[],
            )
            resp = await update_core_memory(req)

        assert "User is a student" in resp.updated
        assert mock_store.put.called

    async def test_update_with_preferences(self):
        from aemeath_agent.api.routes_memory import update_core_memory
        from aemeath_agent.api.models import MemoryCoreUpdateRequest

        mock_store = MagicMock()
        with patch.dict("sys.modules", {
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(return_value=mock_store),
                NAMESPACE_FACTS=("memory", "facts"),
                NAMESPACE_EPISODES=("memory", "episodes"),
                NAMESPACE_PREFERENCES=("memory", "preferences"),
            ),
        }):
            req = MemoryCoreUpdateRequest(
                user_facts=[],
                preferences=[{"preference": "Likes dark mode"}],
            )
            resp = await update_core_memory(req)

        assert "Likes dark mode" in resp.updated

    async def test_empty_lists_noop(self):
        from aemeath_agent.api.routes_memory import update_core_memory
        from aemeath_agent.api.models import MemoryCoreUpdateRequest

        mock_store = MagicMock()
        with patch.dict("sys.modules", {
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(return_value=mock_store),
                NAMESPACE_FACTS=("memory", "facts"),
                NAMESPACE_EPISODES=("memory", "episodes"),
                NAMESPACE_PREFERENCES=("memory", "preferences"),
            ),
        }):
            req = MemoryCoreUpdateRequest(user_facts=[], preferences=[])
            resp = await update_core_memory(req)

        assert len(resp.updated) == 0
        mock_store.put.assert_not_called()

    async def test_skips_empty_fact_text(self):
        from aemeath_agent.api.routes_memory import update_core_memory
        from aemeath_agent.api.models import MemoryCoreUpdateRequest

        mock_store = MagicMock()
        with patch.dict("sys.modules", {
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(return_value=mock_store),
                NAMESPACE_FACTS=("memory", "facts"),
                NAMESPACE_EPISODES=("memory", "episodes"),
                NAMESPACE_PREFERENCES=("memory", "preferences"),
            ),
        }):
            req = MemoryCoreUpdateRequest(
                user_facts=[
                    {"fact": "", "category": "general"},
                    {"fact": "Real fact", "category": "general"},
                ],
                preferences=[],
            )
            resp = await update_core_memory(req)

        assert len(resp.updated) == 1
        assert "Real fact" in resp.updated

    async def test_skips_empty_preference(self):
        from aemeath_agent.api.routes_memory import update_core_memory
        from aemeath_agent.api.models import MemoryCoreUpdateRequest

        mock_store = MagicMock()
        with patch.dict("sys.modules", {
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(return_value=mock_store),
                NAMESPACE_FACTS=("memory", "facts"),
                NAMESPACE_EPISODES=("memory", "episodes"),
                NAMESPACE_PREFERENCES=("memory", "preferences"),
            ),
        }):
            req = MemoryCoreUpdateRequest(
                user_facts=[],
                preferences=[{"preference": ""}, {"preference": "Real pref"}],
            )
            resp = await update_core_memory(req)

        assert len(resp.updated) == 1

    async def test_store_error_returns_gracefully(self):
        from aemeath_agent.api.routes_memory import update_core_memory
        from aemeath_agent.api.models import MemoryCoreUpdateRequest

        with patch.dict("sys.modules", {
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(side_effect=RuntimeError("broken")),
                NAMESPACE_FACTS=("memory", "facts"),
                NAMESPACE_EPISODES=("memory", "episodes"),
                NAMESPACE_PREFERENCES=("memory", "preferences"),
            ),
        }):
            req = MemoryCoreUpdateRequest(
                user_facts=[{"fact": "Will fail", "category": "general"}],
                preferences=[],
            )
            resp = await update_core_memory(req)

        # Should return gracefully, not crash
        assert isinstance(resp.updated, list)

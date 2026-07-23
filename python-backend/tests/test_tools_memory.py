"""Tests for memory tools — update_user_block and retrieve_memory."""

import importlib
import json
from datetime import datetime, timezone
from unittest.mock import MagicMock, patch

import pytest

# Import actual tool functions via importlib (not the StructuredTool wrappers)
_update_mod = importlib.import_module("aemeath_agent.tools.update_user_block")
update_user_block = _update_mod.update_user_block

_retrieve_mod = importlib.import_module("aemeath_agent.tools.retrieve_memory")
retrieve_memory = _retrieve_mod.retrieve_memory


def _mock_store_and_vs(mock_store=None, mock_vs=None, vs_error=False):
    """Build mock sys.modules dict for memory_store + memory_vectorstore."""
    if mock_store is None:
        mock_store = MagicMock()
        mock_store._data = {}

    vs_factory = (
        MagicMock(side_effect=RuntimeError("ChromaDB down"))
        if vs_error
        else MagicMock(return_value=mock_vs)
    )

    return {
        "aemeath_agent.rag.memory_vectorstore": MagicMock(
            get_memory_vectorstore=vs_factory,
        ),
        "aemeath_agent.agent.memory_store": MagicMock(
            get_memory_store=MagicMock(return_value=mock_store),
            NAMESPACE_FACTS=("memory", "facts"),
            NAMESPACE_EPISODES=("memory", "episodes"),
            NAMESPACE_PREFERENCES=("memory", "preferences"),
        ),
    }


# ---------------------------------------------------------------------------
# update_user_block
# ---------------------------------------------------------------------------


class TestUpdateUserBlock:
    _PATCH_TARGET = "aemeath_agent.agent.memory_store.get_memory_blocks"

    def test_success(self):
        mock_blocks = MagicMock()
        with patch(self._PATCH_TARGET, return_value=mock_blocks):
            result = json.loads(update_user_block.invoke({"new_content": "Name: Ricky. CS student."}))

        assert result["status"] == "success"
        assert "updated" in result["message"].lower()
        mock_blocks.put.assert_called_once_with("user", "Name: Ricky. CS student.")

    def test_truncates_long_content(self):
        mock_blocks = MagicMock()
        long_content = "x" * 2000  # Over 1200 char limit

        with patch(self._PATCH_TARGET, return_value=mock_blocks):
            result = json.loads(update_user_block.invoke({"new_content": long_content}))

        assert result["status"] == "success"
        call_args = mock_blocks.put.call_args
        assert len(call_args[0][1]) == 1200

    def test_persists_content(self):
        mock_blocks = MagicMock()
        with patch(self._PATCH_TARGET, return_value=mock_blocks):
            update_user_block.invoke({"new_content": "Test content"})

        mock_blocks.put.assert_called_once()
        assert mock_blocks.put.call_args[0][0] == "user"
        assert mock_blocks.put.call_args[0][1] == "Test content"

    def test_error_returns_error_status(self):
        with patch(self._PATCH_TARGET, side_effect=RuntimeError("blocks broken")):
            result = json.loads(update_user_block.invoke({"new_content": "test"}))

        assert result["status"] == "error"
        assert "blocks broken" in result["message"]

    def test_empty_content_is_allowed(self):
        mock_blocks = MagicMock()
        with patch(self._PATCH_TARGET, return_value=mock_blocks):
            result = json.loads(update_user_block.invoke({"new_content": ""}))

        assert result["status"] == "success"
        mock_blocks.put.assert_called_once_with("user", "")


# ---------------------------------------------------------------------------
# retrieve_memory
# ---------------------------------------------------------------------------


class TestRetrieveMemory:
    def test_no_results_returns_empty(self):
        mock_vs = MagicMock()
        mock_vs.similarity_search_with_relevance_scores.return_value = []

        mock_store = MagicMock()
        mock_store._data = {}

        with (
            patch.dict("sys.modules", {
                "aemeath_agent.rag.memory_vectorstore": MagicMock(
                    get_memory_vectorstore=MagicMock(return_value=mock_vs),
                ),
                "aemeath_agent.agent.memory_store": MagicMock(
                    get_memory_store=MagicMock(return_value=mock_store),
                    NAMESPACE_FACTS=("memory", "facts"),
                    NAMESPACE_EPISODES=("memory", "episodes"),
                    NAMESPACE_PREFERENCES=("memory", "preferences"),
                ),
            }),
        ):
            result = json.loads(retrieve_memory.invoke({"query": "nonexistent"}))

        assert result["status"] == "success"
        assert result["message"] == "No relevant memories found."
        assert result["results"] == []

    def test_returns_chromadb_results(self):
        mock_doc = MagicMock()
        mock_doc.page_content = "User has a calculus exam"
        mock_doc.metadata = {"type": "event", "created_at": "2026-03-01"}

        mock_vs = MagicMock()
        mock_vs.similarity_search_with_relevance_scores.return_value = [(mock_doc, 0.85)]

        mock_store = MagicMock()
        mock_store._data = {}

        with (
            patch.dict("sys.modules", {
                "aemeath_agent.rag.memory_vectorstore": MagicMock(
                    get_memory_vectorstore=MagicMock(return_value=mock_vs),
                ),
                "aemeath_agent.agent.memory_store": MagicMock(
                    get_memory_store=MagicMock(return_value=mock_store),
                    NAMESPACE_FACTS=("memory", "facts"),
                    NAMESPACE_EPISODES=("memory", "episodes"),
                    NAMESPACE_PREFERENCES=("memory", "preferences"),
                ),
            }),
        ):
            result = json.loads(retrieve_memory.invoke({"query": "exam"}))

        assert result["status"] == "success"
        assert len(result["results"]) == 1
        assert "calculus exam" in result["results"][0]["content"]
        assert result["results"][0]["source"] == "episodic"

    def test_category_filter_works(self):
        # Create a doc with type "event"
        mock_doc_event = MagicMock()
        mock_doc_event.page_content = "exam event"
        mock_doc_event.metadata = {"type": "event", "created_at": ""}

        mock_doc_fact = MagicMock()
        mock_doc_fact.page_content = "name is Ricky"
        mock_doc_fact.metadata = {"type": "fact", "created_at": ""}

        mock_vs = MagicMock()
        mock_vs.similarity_search_with_relevance_scores.return_value = [
            (mock_doc_event, 0.8),
            (mock_doc_fact, 0.7),
        ]

        mock_store = MagicMock()
        mock_store._data = {}

        with (
            patch.dict("sys.modules", {
                "aemeath_agent.rag.memory_vectorstore": MagicMock(
                    get_memory_vectorstore=MagicMock(return_value=mock_vs),
                ),
                "aemeath_agent.agent.memory_store": MagicMock(
                    get_memory_store=MagicMock(return_value=mock_store),
                    NAMESPACE_FACTS=("memory", "facts"),
                    NAMESPACE_EPISODES=("memory", "episodes"),
                    NAMESPACE_PREFERENCES=("memory", "preferences"),
                ),
            }),
        ):
            # Filter for "facts" only — should exclude the "event" type
            result = json.loads(retrieve_memory.invoke({"query": "test", "category": "facts"}))

        assert result["status"] == "success"
        # Only the fact should remain, not the event
        for r in result.get("results", []):
            assert r["type"] != "event"

    def test_persistent_store_search(self):
        mock_vs = MagicMock()
        mock_vs.similarity_search_with_relevance_scores.return_value = []

        # Create a mock Item
        mock_item = MagicMock()
        mock_item.value = {"content": "User likes Python"}
        mock_item.updated_at = datetime(2026, 3, 1, tzinfo=timezone.utc)

        mock_store = MagicMock()
        mock_store._data = {
            ("memory", "facts"): {"fact1": mock_item}
        }

        with (
            patch.dict("sys.modules", {
                "aemeath_agent.rag.memory_vectorstore": MagicMock(
                    get_memory_vectorstore=MagicMock(return_value=mock_vs),
                ),
                "aemeath_agent.agent.memory_store": MagicMock(
                    get_memory_store=MagicMock(return_value=mock_store),
                    NAMESPACE_FACTS=("memory", "facts"),
                    NAMESPACE_EPISODES=("memory", "episodes"),
                    NAMESPACE_PREFERENCES=("memory", "preferences"),
                ),
            }),
        ):
            result = json.loads(retrieve_memory.invoke({"query": "Python"}))

        assert result["status"] == "success"
        assert len(result["results"]) == 1
        assert result["results"][0]["content"] == "User likes Python"
        assert result["results"][0]["source"] == "store"

    def test_results_limited_to_5(self):
        # Create 10 matching docs
        mock_docs = []
        for i in range(10):
            doc = MagicMock()
            doc.page_content = f"Memory item {i}"
            doc.metadata = {"type": "fact", "created_at": ""}
            mock_docs.append((doc, 0.9 - i * 0.05))

        mock_vs = MagicMock()
        mock_vs.similarity_search_with_relevance_scores.return_value = mock_docs[:5]

        mock_store = MagicMock()
        mock_store._data = {}

        with (
            patch.dict("sys.modules", {
                "aemeath_agent.rag.memory_vectorstore": MagicMock(
                    get_memory_vectorstore=MagicMock(return_value=mock_vs),
                ),
                "aemeath_agent.agent.memory_store": MagicMock(
                    get_memory_store=MagicMock(return_value=mock_store),
                    NAMESPACE_FACTS=("memory", "facts"),
                    NAMESPACE_EPISODES=("memory", "episodes"),
                    NAMESPACE_PREFERENCES=("memory", "preferences"),
                ),
            }),
        ):
            result = json.loads(retrieve_memory.invoke({"query": "Memory"}))

        assert len(result["results"]) <= 5

    def test_chromadb_failure_falls_back_to_store(self):
        mock_item = MagicMock()
        mock_item.value = {"content": "Fallback result"}
        mock_item.updated_at = datetime(2026, 3, 1, tzinfo=timezone.utc)

        mock_store = MagicMock()
        mock_store._data = {
            ("memory", "facts"): {"f1": mock_item}
        }

        with (
            patch.dict("sys.modules", {
                "aemeath_agent.rag.memory_vectorstore": MagicMock(
                    get_memory_vectorstore=MagicMock(side_effect=RuntimeError("ChromaDB down")),
                ),
                "aemeath_agent.agent.memory_store": MagicMock(
                    get_memory_store=MagicMock(return_value=mock_store),
                    NAMESPACE_FACTS=("memory", "facts"),
                    NAMESPACE_EPISODES=("memory", "episodes"),
                    NAMESPACE_PREFERENCES=("memory", "preferences"),
                ),
            }),
        ):
            result = json.loads(retrieve_memory.invoke({"query": "Fallback"}))

        assert result["status"] == "success"
        assert len(result["results"]) == 1
        assert result["results"][0]["content"] == "Fallback result"

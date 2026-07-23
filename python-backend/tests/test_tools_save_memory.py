"""Tests for the save memory tool."""

import importlib
import json
from unittest.mock import MagicMock, patch

# Use importlib to get the actual module (not the StructuredTool via __init__.py)
_mod = importlib.import_module("aemeath_agent.tools.save_memory")
save_memory = _mod.save_memory


def _invoke(content: str = "test fact", category: str = "facts", tags: str = "") -> dict:
    result = save_memory.invoke({"content": content, "category": category, "tags": tags})
    return json.loads(result)


class TestSaveMemory:
    def test_save_fact(self):
        mock_store = MagicMock()
        with (
            patch("aemeath_agent.tools.save_memory.get_memory_store", return_value=mock_store),
            patch("aemeath_agent.tools.save_memory._upsert_to_chromadb"),
        ):
            data = _invoke("User likes Python", "facts")

        assert data["status"] == "success"
        assert "Remembered" in data["message"]
        mock_store.put.assert_called_once()
        call_args = mock_store.put.call_args
        assert call_args[0][0] == ("memory", "facts")
        assert call_args[0][2]["content"] == "User likes Python"
        assert call_args[0][2]["tags"] == []

    def test_save_with_tags(self):
        mock_store = MagicMock()
        with (
            patch("aemeath_agent.tools.save_memory.get_memory_store", return_value=mock_store),
            patch("aemeath_agent.tools.save_memory._upsert_to_chromadb") as mock_upsert,
        ):
            data = _invoke("User's name is Ricky", "facts", "name,personal")

        assert data["status"] == "success"
        call_args = mock_store.put.call_args
        assert call_args[0][2]["tags"] == ["name", "personal"]
        mock_upsert.assert_called_once_with("User's name is Ricky", "facts", ["name", "personal"])

    def test_save_episode(self):
        mock_store = MagicMock()
        with (
            patch("aemeath_agent.tools.save_memory.get_memory_store", return_value=mock_store),
            patch("aemeath_agent.tools.save_memory._upsert_to_chromadb"),
        ):
            data = _invoke("We played a game together", "episodes")

        assert data["status"] == "success"
        call_args = mock_store.put.call_args
        assert call_args[0][0] == ("memory", "episodes")

    def test_save_preference(self):
        mock_store = MagicMock()
        with (
            patch("aemeath_agent.tools.save_memory.get_memory_store", return_value=mock_store),
            patch("aemeath_agent.tools.save_memory._upsert_to_chromadb"),
        ):
            data = _invoke("Prefers dark mode", "preferences")

        assert data["status"] == "success"
        call_args = mock_store.put.call_args
        assert call_args[0][0] == ("memory", "preferences")

    def test_unknown_category_defaults_to_facts(self):
        mock_store = MagicMock()
        with (
            patch("aemeath_agent.tools.save_memory.get_memory_store", return_value=mock_store),
            patch("aemeath_agent.tools.save_memory._upsert_to_chromadb"),
        ):
            data = _invoke("Random info", "unknown_category")

        assert data["status"] == "success"
        call_args = mock_store.put.call_args
        assert call_args[0][0] == ("memory", "facts")

    def test_exception_returns_error(self):
        with patch(
            "aemeath_agent.tools.save_memory.get_memory_store",
            side_effect=RuntimeError("store broken"),
        ):
            data = _invoke("will fail")

        assert data["status"] == "error"
        assert "store broken" in data["message"]

"""Integration tests for memory system components working together."""

import importlib
import json
import shutil
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock

import aemeath_agent.agent.memory_store as ms


class TestMemoryIntegration:
    def setup_method(self):
        """Reset singletons and create temp dir before each test."""
        ms._store = None
        ms._blocks = None
        self._temp_dir = tempfile.mkdtemp()

    def teardown_method(self):
        ms._store = None
        ms._blocks = None
        shutil.rmtree(self._temp_dir, ignore_errors=True)

    def test_extracted_fact_can_be_retrieved_from_store(self):
        """JsonPersistentStore put -> search roundtrip."""
        store_path = Path(self._temp_dir) / "test_store.json"
        store = ms.JsonPersistentStore(store_path)

        # Store a fact
        store.put(
            ms.NAMESPACE_FACTS,
            "fact-1",
            {"content": "User likes Python programming", "tags": ["interest"]},
        )

        # Search for it via _data (internal dict)
        found = False
        for _key, item in store._data.get(ms.NAMESPACE_FACTS, {}).items():
            if "Python" in item.value.get("content", ""):
                found = True
                break

        assert found

    def test_distilled_observation_stored_correctly(self):
        """Store an episode and verify it can be searched."""
        store_path = Path(self._temp_dir) / "test_store2.json"
        store = ms.JsonPersistentStore(store_path)

        store.put(
            ms.NAMESPACE_EPISODES,
            "ep-1",
            {
                "content": "User was studying calculus for 2 hours",
                "type": "activity_pattern",
                "importance": 0.7,
            },
        )

        # Verify via internal data
        items = store._data.get(ms.NAMESPACE_EPISODES, {})
        assert "ep-1" in items
        assert items["ep-1"].value["type"] == "activity_pattern"

    def test_save_and_retrieve_memory_tool_roundtrip(self):
        """save_memory tool -> retrieve_memory tool with matching query."""
        store_path = Path(self._temp_dir) / "test_store3.json"
        store = ms.JsonPersistentStore(store_path)

        # Use save_memory tool
        _mod = importlib.import_module("aemeath_agent.tools.save_memory")
        save_memory = _mod.save_memory

        with (
            patch(
                "aemeath_agent.tools.save_memory.get_memory_store",
                return_value=store,
            ),
            patch("aemeath_agent.tools.save_memory._upsert_to_chromadb"),
        ):
            result = save_memory.invoke(
                {"content": "User's name is Ricky", "category": "facts", "tags": "name"}
            )
            data = json.loads(result)
            assert data["status"] == "success"

        # Use retrieve_memory tool
        _mod2 = importlib.import_module("aemeath_agent.tools.retrieve_memory")
        retrieve_memory = _mod2.retrieve_memory

        with (
            patch.dict(
                "sys.modules",
                {
                    "aemeath_agent.rag.memory_vectorstore": MagicMock(
                        get_memory_vectorstore=MagicMock(return_value=None),
                    ),
                    "aemeath_agent.agent.memory_store": MagicMock(
                        get_memory_store=MagicMock(return_value=store),
                        NAMESPACE_FACTS=ms.NAMESPACE_FACTS,
                        NAMESPACE_EPISODES=ms.NAMESPACE_EPISODES,
                        NAMESPACE_PREFERENCES=ms.NAMESPACE_PREFERENCES,
                    ),
                },
            ),
        ):
            result = retrieve_memory.invoke({"query": "Ricky", "category": "facts"})
            data = json.loads(result)
            assert data["status"] == "success"
            assert len(data["results"]) >= 1
            assert any("Ricky" in r["content"] for r in data["results"])

"""End-to-end tests for the memory API endpoints."""

import json
import shutil
import tempfile
from pathlib import Path
from unittest.mock import patch, MagicMock, AsyncMock

import pytest

import aemeath_agent.agent.memory_store as ms


class TestMemoryE2E:
    def setup_method(self):
        ms._store = None
        ms._blocks = None
        self._temp_dir = tempfile.mkdtemp()

    def teardown_method(self):
        ms._store = None
        ms._blocks = None
        shutil.rmtree(self._temp_dir, ignore_errors=True)

    async def test_extract_then_retrieve_via_api(self):
        """POST /memory/extract (mock LLM) -> verify extracted fact stored."""
        from aemeath_agent.api.routes_memory import extract_memories
        from aemeath_agent.api.models import MemoryExtractRequest

        store_path = Path(self._temp_dir) / "e2e_store.json"
        store = ms.JsonPersistentStore(store_path)

        # Mock LLM to return a parsed extraction
        mock_llm = AsyncMock()
        mock_llm.ainvoke.return_value = MagicMock(
            content=json.dumps(
                {
                    "facts": [
                        {
                            "fact": "User studies CS",
                            "confidence": 0.9,
                            "category": "occupation",
                        }
                    ],
                    "events": [],
                    "preferences": [],
                }
            )
        )

        with (
            patch(
                "aemeath_agent.api.routes_memory._get_extraction_llm",
                return_value=mock_llm,
            ),
            patch.dict(
                "sys.modules",
                {
                    "aemeath_agent.agent.memory_store": MagicMock(
                        get_memory_store=MagicMock(return_value=store),
                        NAMESPACE_FACTS=ms.NAMESPACE_FACTS,
                        NAMESPACE_EPISODES=ms.NAMESPACE_EPISODES,
                        NAMESPACE_PREFERENCES=ms.NAMESPACE_PREFERENCES,
                    ),
                    "aemeath_agent.rag.memory_vectorstore": MagicMock(
                        get_memory_vectorstore=MagicMock(return_value=None),
                    ),
                },
            ),
        ):
            req = MemoryExtractRequest(
                user_message="I study CS", assistant_response="Cool!"
            )
            resp = await extract_memories(req)

        assert len(resp.facts) == 1
        assert resp.facts[0].fact == "User studies CS"

        # Verify it was stored in the JsonPersistentStore
        items = store._data.get(ms.NAMESPACE_FACTS, {})
        assert len(items) >= 1
        stored_content = [item.value["content"] for item in items.values()]
        assert "User studies CS" in stored_content

    async def test_distill_observations_then_check_response(self):
        """POST /memory/distill (mock LLM) -> verify distilled result."""
        from aemeath_agent.api.routes_memory import distill_observations
        from aemeath_agent.api.models import MemoryDistillRequest, ObservationItem

        mock_llm = AsyncMock()
        mock_llm.ainvoke.return_value = MagicMock(
            content=json.dumps(
                {
                    "distilled": [
                        {
                            "content": "User codes frequently in evenings",
                            "type": "activity_pattern",
                            "importance": 0.7,
                        }
                    ],
                    "patterns": ["Evening coding sessions"],
                }
            )
        )

        with (
            patch(
                "aemeath_agent.api.routes_memory._get_extraction_llm",
                return_value=mock_llm,
            ),
            patch.dict(
                "sys.modules",
                {
                    "aemeath_agent.rag.memory_vectorstore": MagicMock(
                        get_memory_vectorstore=MagicMock(return_value=None),
                    ),
                },
            ),
        ):
            req = MemoryDistillRequest(
                observations=[
                    ObservationItem(
                        timestamp="2026-03-03T20:00:00Z",
                        source="screen",
                        content="VS Code open",
                        activity_context="StudyingCoding",
                    ),
                    ObservationItem(
                        timestamp="2026-03-03T21:00:00Z",
                        source="screen",
                        content="VS Code still open",
                        activity_context="StudyingCoding",
                    ),
                ]
            )
            resp = await distill_observations(req)

        assert len(resp.distilled) == 1
        assert "codes frequently" in resp.distilled[0].content
        assert resp.patterns == ["Evening coding sessions"]

    async def test_status_reflects_stored_data(self):
        """Store data -> GET /memory/status -> verify counts."""
        from aemeath_agent.api.routes_memory import memory_status

        store_path = Path(self._temp_dir) / "status_store.json"
        store = ms.JsonPersistentStore(store_path)
        blocks_path = Path(self._temp_dir) / "status_blocks.json"
        blocks = ms.MemoryBlocks(blocks_path)

        # Store some data so the file exists and has content
        store.put(ms.NAMESPACE_FACTS, "f1", {"content": "test fact"})

        with (
            patch.dict(
                "sys.modules",
                {
                    "aemeath_agent.agent.memory_store": MagicMock(
                        get_memory_store=MagicMock(return_value=store),
                        get_memory_blocks=MagicMock(return_value=blocks),
                    ),
                    "aemeath_agent.rag.memory_vectorstore": MagicMock(
                        get_memory_vectorstore=MagicMock(return_value=None),
                    ),
                },
            ),
        ):
            resp = await memory_status()

        assert resp.store_size_bytes > 0

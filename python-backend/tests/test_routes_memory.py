"""Tests for memory API endpoints (api/routes_memory.py)."""

import json
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from aemeath_agent.api.routes_memory import router, _parse_llm_json


def _make_app():
    app = FastAPI()
    app.include_router(router)
    return app


def _make_client():
    return TestClient(_make_app(), raise_server_exceptions=False)


# ---------------------------------------------------------------------------
# _parse_llm_json
# ---------------------------------------------------------------------------


class TestParseLlmJson:
    def test_plain_json(self):
        result = _parse_llm_json('{"facts": []}')
        assert result == {"facts": []}

    def test_json_with_markdown_fences(self):
        text = '```json\n{"facts": [{"fact": "test"}]}\n```'
        result = _parse_llm_json(text)
        assert result["facts"][0]["fact"] == "test"

    def test_json_with_bare_fences(self):
        text = '```\n{"key": "value"}\n```'
        result = _parse_llm_json(text)
        assert result["key"] == "value"


# ---------------------------------------------------------------------------
# POST /memory/extract
# ---------------------------------------------------------------------------


class TestExtractEndpoint:
    def test_extract_no_llm_returns_empty(self):
        with patch("aemeath_agent.api.routes_memory._get_extraction_llm", return_value=None):
            client = _make_client()
            resp = client.post(
                "/memory/extract",
                json={"user_message": "My name is Ricky", "assistant_response": "Nice to meet you!"},
            )
        assert resp.status_code == 200
        data = resp.json()
        assert data["facts"] == []
        assert data["events"] == []
        assert data["preferences"] == []

    def test_extract_with_llm_returns_facts(self):
        llm_response = MagicMock()
        llm_response.content = json.dumps({
            "facts": [{"fact": "User's name is Ricky", "confidence": 0.95, "category": "name"}],
            "events": [],
            "preferences": [{"preference": "Likes Python", "confidence": 0.7}]
        })

        mock_llm = AsyncMock()
        mock_llm.ainvoke.return_value = llm_response

        mock_store = MagicMock()

        with (
            patch("aemeath_agent.api.routes_memory._get_extraction_llm", return_value=mock_llm),
            patch.dict("sys.modules", {
                "aemeath_agent.agent.memory_store": MagicMock(
                    get_memory_store=MagicMock(return_value=mock_store),
                    NAMESPACE_FACTS=("memory", "facts"),
                    NAMESPACE_EPISODES=("memory", "episodes"),
                    NAMESPACE_PREFERENCES=("memory", "preferences"),
                ),
                "aemeath_agent.rag.memory_vectorstore": MagicMock(
                    get_memory_vectorstore=MagicMock(return_value=None),
                ),
            }),
        ):
            client = _make_client()
            resp = client.post(
                "/memory/extract",
                json={"user_message": "My name is Ricky", "assistant_response": "Nice!"},
            )

        assert resp.status_code == 200
        data = resp.json()
        assert len(data["facts"]) == 1
        assert data["facts"][0]["fact"] == "User's name is Ricky"
        assert data["facts"][0]["confidence"] == 0.95

    def test_extract_llm_failure_returns_empty(self):
        mock_llm = AsyncMock()
        mock_llm.ainvoke.side_effect = RuntimeError("LLM exploded")

        with patch("aemeath_agent.api.routes_memory._get_extraction_llm", return_value=mock_llm):
            client = _make_client()
            resp = client.post(
                "/memory/extract",
                json={"user_message": "test", "assistant_response": "test"},
            )

        assert resp.status_code == 200
        data = resp.json()
        assert data["facts"] == []


# ---------------------------------------------------------------------------
# GET /memory/retrieve
# ---------------------------------------------------------------------------


class TestRetrieveEndpoint:
    def test_retrieve_empty_query_returns_empty(self):
        client = _make_client()
        resp = client.get("/memory/retrieve?q=&top_k=3")

        assert resp.status_code == 200
        data = resp.json()
        assert data["memories"] == []

    def test_retrieve_no_vectorstore_returns_empty(self):
        with patch.dict("sys.modules", {
            "aemeath_agent.rag.memory_vectorstore": MagicMock(
                get_memory_vectorstore=MagicMock(return_value=None),
            ),
        }):
            client = _make_client()
            resp = client.get("/memory/retrieve?q=exam&top_k=3")

        assert resp.status_code == 200
        data = resp.json()
        assert data["memories"] == []

    def test_retrieve_with_results(self):
        mock_doc = MagicMock()
        mock_doc.page_content = "User has a calculus exam on March 10"
        mock_doc.metadata = {"type": "event", "created_at": "2026-03-01", "importance": 0.8}

        mock_vs = MagicMock()
        mock_vs.similarity_search_with_relevance_scores.return_value = [(mock_doc, 0.85)]

        with patch.dict("sys.modules", {
            "aemeath_agent.rag.memory_vectorstore": MagicMock(
                get_memory_vectorstore=MagicMock(return_value=mock_vs),
            ),
        }):
            client = _make_client()
            resp = client.get("/memory/retrieve?q=exam&top_k=3")

        assert resp.status_code == 200
        data = resp.json()
        assert len(data["memories"]) == 1
        assert "calculus exam" in data["memories"][0]["content"]
        assert data["memories"][0]["type"] == "event"


# ---------------------------------------------------------------------------
# POST /memory/distill
# ---------------------------------------------------------------------------


class TestDistillEndpoint:
    def test_distill_empty_observations_returns_empty(self):
        client = _make_client()
        resp = client.post("/memory/distill", json={"observations": []})

        assert resp.status_code == 200
        data = resp.json()
        assert data["distilled"] == []
        assert data["patterns"] == []

    def test_distill_no_llm_returns_empty(self):
        with patch("aemeath_agent.api.routes_memory._get_extraction_llm", return_value=None):
            client = _make_client()
            resp = client.post(
                "/memory/distill",
                json={
                    "observations": [
                        {"timestamp": "2026-03-03T14:30:00Z", "source": "screen", "content": "VS Code open"}
                    ]
                },
            )

        assert resp.status_code == 200
        data = resp.json()
        assert data["distilled"] == []

    def test_distill_with_llm_returns_results(self):
        llm_response = MagicMock()
        llm_response.content = json.dumps({
            "distilled": [
                {"content": "User coding in VS Code", "type": "activity_pattern", "importance": 0.6}
            ],
            "patterns": ["afternoon coding sessions"]
        })

        mock_llm = AsyncMock()
        mock_llm.ainvoke.return_value = llm_response

        with (
            patch("aemeath_agent.api.routes_memory._get_extraction_llm", return_value=mock_llm),
            patch.dict("sys.modules", {
                "aemeath_agent.rag.memory_vectorstore": MagicMock(
                    get_memory_vectorstore=MagicMock(return_value=None),
                ),
            }),
        ):
            client = _make_client()
            resp = client.post(
                "/memory/distill",
                json={
                    "observations": [
                        {"timestamp": "2026-03-03T14:30:00Z", "source": "screen", "content": "VS Code open"}
                    ]
                },
            )

        assert resp.status_code == 200
        data = resp.json()
        assert len(data["distilled"]) == 1
        assert data["distilled"][0]["content"] == "User coding in VS Code"
        assert data["patterns"] == ["afternoon coding sessions"]


# ---------------------------------------------------------------------------
# DELETE /memory/forget
# ---------------------------------------------------------------------------


class TestForgetEndpoint:
    def test_forget_no_query_returns_zero(self):
        client = _make_client()
        resp = client.request("DELETE", "/memory/forget", json={})

        assert resp.status_code == 200
        data = resp.json()
        assert data["deleted_count"] == 0

    def test_forget_with_query_searches_and_deletes(self):
        # Mock vectorstore search returning matches
        mock_doc = MagicMock()
        mock_doc.metadata = {"id": "doc1"}
        mock_vs = MagicMock()
        mock_vs.similarity_search_with_relevance_scores.return_value = [(mock_doc, 0.8)]

        # Mock persistent store
        mock_store = MagicMock()
        mock_store._data = {}  # No items in persistent store

        with patch.dict("sys.modules", {
            "aemeath_agent.rag.memory_vectorstore": MagicMock(
                get_memory_vectorstore=MagicMock(return_value=mock_vs),
            ),
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(return_value=mock_store),
            ),
        }):
            client = _make_client()
            resp = client.request("DELETE", "/memory/forget", json={"query": "calculus exam"})

        assert resp.status_code == 200
        data = resp.json()
        assert data["deleted_count"] == 1
        mock_vs.delete.assert_called_once()


# ---------------------------------------------------------------------------
# GET /memory/status
# ---------------------------------------------------------------------------


class TestStatusEndpoint:
    def test_status_returns_structure(self):
        mock_collection = MagicMock()
        mock_collection.count.return_value = 5
        mock_vs = MagicMock()
        mock_vs._collection = mock_collection

        mock_store = MagicMock()
        mock_store._json_path = MagicMock()
        mock_store._json_path.exists.return_value = False

        mock_blocks = MagicMock()
        mock_blocks.get_all.return_value = {"user": "test block"}

        with patch.dict("sys.modules", {
            "aemeath_agent.rag.memory_vectorstore": MagicMock(
                get_memory_vectorstore=MagicMock(return_value=mock_vs),
            ),
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(return_value=mock_store),
                get_memory_blocks=MagicMock(return_value=mock_blocks),
            ),
        }):
            client = _make_client()
            resp = client.get("/memory/status")

        assert resp.status_code == 200
        data = resp.json()
        assert data["episodic_count"] == 5
        assert "user" in data["blocks"]

    def test_status_handles_errors_gracefully(self):
        with patch.dict("sys.modules", {
            "aemeath_agent.rag.memory_vectorstore": MagicMock(
                get_memory_vectorstore=MagicMock(side_effect=RuntimeError("boom")),
            ),
            "aemeath_agent.agent.memory_store": MagicMock(
                get_memory_store=MagicMock(side_effect=RuntimeError("boom")),
                get_memory_blocks=MagicMock(side_effect=RuntimeError("boom")),
            ),
        }):
            client = _make_client()
            resp = client.get("/memory/status")

        assert resp.status_code == 200
        data = resp.json()
        assert data["episodic_count"] == 0

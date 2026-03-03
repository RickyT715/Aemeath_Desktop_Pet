"""Tests for the RAG retrieval tool."""

import json
from unittest.mock import MagicMock

import aemeath_agent.tools.rag_retrieval as rag_mod


def _invoke(query: str = "test") -> dict:
    result = rag_mod.rag_retrieve.invoke({"query": query})
    return json.loads(result)


def _make_doc(page_content: str, source: str = "test.pdf"):
    doc = MagicMock()
    doc.page_content = page_content
    doc.metadata = {"source": source}
    return doc


class TestRagRetrieve:
    def setup_method(self):
        rag_mod._retriever = None

    def test_not_initialized_returns_error(self):
        data = _invoke("search something")
        assert data["status"] == "error"
        assert "not initialized" in data["message"].lower()

    def test_success_with_docs(self):
        mock_retriever = MagicMock()
        mock_retriever.invoke.return_value = [
            _make_doc("First document content", "doc1.pdf"),
            _make_doc("Second document content", "doc2.txt"),
        ]
        rag_mod._retriever = mock_retriever

        data = _invoke("find docs")

        assert data["status"] == "success"
        assert len(data["results"]) == 2
        assert data["results"][0]["source"] == "doc1.pdf"
        assert data["results"][0]["content"] == "First document content"
        assert data["results"][1]["source"] == "doc2.txt"

    def test_empty_results(self):
        mock_retriever = MagicMock()
        mock_retriever.invoke.return_value = []
        rag_mod._retriever = mock_retriever

        data = _invoke("nothing here")

        assert data["status"] == "success"
        assert "No relevant documents" in data["message"]
        assert data["results"] == []

    def test_content_truncated_to_500_chars(self):
        long_content = "a" * 800
        mock_retriever = MagicMock()
        mock_retriever.invoke.return_value = [_make_doc(long_content, "big.pdf")]
        rag_mod._retriever = mock_retriever

        data = _invoke("long doc")

        assert len(data["results"][0]["content"]) == 500

    def test_exception_returns_error(self):
        mock_retriever = MagicMock()
        mock_retriever.invoke.side_effect = RuntimeError("retrieval failed")
        rag_mod._retriever = mock_retriever

        data = _invoke("error query")

        assert data["status"] == "error"
        assert "retrieval failed" in data["message"]

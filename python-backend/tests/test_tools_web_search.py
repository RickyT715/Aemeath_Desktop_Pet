"""Tests for the web search tool."""

import json
import sys
from unittest.mock import MagicMock, patch

import importlib

# The module is importable, but 'tavily' (a dependency) may not be installed in test env.
_mod = importlib.import_module("aemeath_agent.tools.web_search")
search_web = _mod.search_web


def _invoke(query: str = "test", num_results: int = 5) -> dict:
    result = search_web.invoke({"query": query, "num_results": num_results})
    return json.loads(result)


class TestSearchWeb:
    def setup_method(self):
        _mod._tavily_api_key = ""

    def test_no_api_key_returns_error(self):
        # When tavily is installed, returns "not configured"; when not installed,
        # the import fails and the generic exception handler returns the error.
        # Either way, status should be "error".
        tavily_mock = MagicMock()
        with patch.dict(sys.modules, {"tavily": tavily_mock}):
            data = _invoke("hello")
        assert data["status"] == "error"
        assert "not configured" in data["message"]

    def test_success_response_formatting(self):
        _mod._tavily_api_key = "test-key"
        mock_client = MagicMock()
        mock_client.search.return_value = {
            "results": [
                {"title": "Title 1", "url": "https://example.com/1", "content": "Snippet 1"},
                {"title": "Title 2", "url": "https://example.com/2", "content": "Snippet 2"},
            ]
        }
        # tavily is imported inside the function; inject a mock module into sys.modules
        tavily_mock = MagicMock()
        tavily_mock.TavilyClient.return_value = mock_client
        with patch.dict(sys.modules, {"tavily": tavily_mock}):
            data = _invoke("test query", num_results=2)

        assert data["status"] == "success"
        assert len(data["results"]) == 2
        assert data["results"][0]["title"] == "Title 1"
        assert data["results"][0]["url"] == "https://example.com/1"
        assert data["results"][0]["snippet"] == "Snippet 1"

    def test_snippet_truncated_to_300_chars(self):
        _mod._tavily_api_key = "test-key"
        long_content = "x" * 500
        mock_client = MagicMock()
        mock_client.search.return_value = {
            "results": [{"title": "T", "url": "https://example.com", "content": long_content}]
        }
        tavily_mock = MagicMock()
        tavily_mock.TavilyClient.return_value = mock_client
        with patch.dict(sys.modules, {"tavily": tavily_mock}):
            data = _invoke("query")

        assert len(data["results"][0]["snippet"]) == 300

    def test_empty_results(self):
        _mod._tavily_api_key = "test-key"
        mock_client = MagicMock()
        mock_client.search.return_value = {"results": []}
        tavily_mock = MagicMock()
        tavily_mock.TavilyClient.return_value = mock_client
        with patch.dict(sys.modules, {"tavily": tavily_mock}):
            data = _invoke("nothing")

        assert data["status"] == "success"
        assert data["results"] == []

    def test_exception_returns_error(self):
        _mod._tavily_api_key = "test-key"
        mock_client = MagicMock()
        mock_client.search.side_effect = RuntimeError("network down")
        tavily_mock = MagicMock()
        tavily_mock.TavilyClient.return_value = mock_client
        with patch.dict(sys.modules, {"tavily": tavily_mock}):
            data = _invoke("fail")

        assert data["status"] == "error"
        assert "network down" in data["message"]

    def test_configure_sets_api_key(self):
        _mod.configure("my-api-key")
        assert _mod._tavily_api_key == "my-api-key"

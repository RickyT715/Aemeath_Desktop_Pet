"""Tests for the screen reader tool."""

import json
from unittest.mock import MagicMock, patch

import httpx

import aemeath_agent.tools.screen_reader as screen_mod


def _invoke() -> dict:
    result = screen_mod.read_screen.invoke({})
    return json.loads(result)


class TestReadScreen:
    def setup_method(self):
        screen_mod._wpf_port = 18901

    def test_success(self):
        mock_resp = MagicMock()
        mock_resp.json.return_value = {"description": "VS Code with Python file open"}
        mock_resp.raise_for_status = MagicMock()

        with patch("aemeath_agent.tools.screen_reader.httpx.get", return_value=mock_resp):
            data = _invoke()

        assert data["status"] == "success"
        assert data["data"]["description"] == "VS Code with Python file open"

    def test_connect_error(self):
        with patch(
            "aemeath_agent.tools.screen_reader.httpx.get",
            side_effect=httpx.ConnectError("Connection refused"),
        ):
            data = _invoke()

        assert data["status"] == "error"
        assert "Cannot connect" in data["message"]

    def test_timeout(self):
        with patch(
            "aemeath_agent.tools.screen_reader.httpx.get",
            side_effect=httpx.TimeoutException("request timed out"),
        ):
            data = _invoke()

        assert data["status"] == "error"
        assert "timed out" in data["message"]

    def test_generic_error(self):
        with patch(
            "aemeath_agent.tools.screen_reader.httpx.get",
            side_effect=RuntimeError("something broke"),
        ):
            data = _invoke()

        assert data["status"] == "error"
        assert "something broke" in data["message"]

    def test_configure_sets_port(self):
        screen_mod.configure(wpf_port=9999)
        assert screen_mod._wpf_port == 9999

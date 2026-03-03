"""Tests for the pet stats tool."""

import json
from unittest.mock import MagicMock, patch

import httpx

import aemeath_agent.tools.pet_stats as stats_mod


def _invoke() -> dict:
    result = stats_mod.get_pet_stats.invoke({})
    return json.loads(result)


class TestGetPetStats:
    def setup_method(self):
        stats_mod._wpf_port = 18901

    def test_success_with_stats(self):
        mock_resp = MagicMock()
        mock_resp.json.return_value = {
            "mood": 85.0,
            "energy": 70.0,
            "affection": 92.0,
            "state": "Happy",
        }
        mock_resp.raise_for_status = MagicMock()

        with patch("aemeath_agent.tools.pet_stats.httpx.get", return_value=mock_resp):
            data = _invoke()

        assert data["status"] == "success"
        assert data["data"]["mood"] == 85.0
        assert data["data"]["energy"] == 70.0
        assert data["data"]["affection"] == 92.0
        assert data["data"]["state"] == "Happy"

    def test_connect_error(self):
        with patch(
            "aemeath_agent.tools.pet_stats.httpx.get",
            side_effect=httpx.ConnectError("Connection refused"),
        ):
            data = _invoke()

        assert data["status"] == "error"
        assert "Cannot connect" in data["message"]

    def test_timeout(self):
        with patch(
            "aemeath_agent.tools.pet_stats.httpx.get",
            side_effect=httpx.TimeoutException("request timed out"),
        ):
            data = _invoke()

        assert data["status"] == "error"
        assert "timed out" in data["message"]

    def test_generic_error(self):
        with patch(
            "aemeath_agent.tools.pet_stats.httpx.get",
            side_effect=RuntimeError("unexpected error"),
        ):
            data = _invoke()

        assert data["status"] == "error"
        assert "unexpected error" in data["message"]

    def test_configure_sets_port(self):
        stats_mod.configure(wpf_port=5555)
        assert stats_mod._wpf_port == 5555

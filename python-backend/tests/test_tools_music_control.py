"""Tests for the music control tool."""

import json
from unittest.mock import MagicMock, patch

import httpx

import aemeath_agent.tools.music_control as music_mod


def _invoke(action: str = "play", value: str = "") -> dict:
    result = music_mod.control_music.invoke({"action": action, "value": value})
    return json.loads(result)


class TestControlMusic:
    def setup_method(self):
        music_mod._wpf_port = 18901

    def test_success(self):
        mock_resp = MagicMock()
        mock_resp.json.return_value = {"action": "play", "result": "ok"}
        mock_resp.raise_for_status = MagicMock()

        with patch("aemeath_agent.tools.music_control.httpx.post", return_value=mock_resp) as mock_post:
            data = _invoke("play")

        assert data["status"] == "success"
        assert data["data"]["action"] == "play"
        # Verify the payload sent
        call_kwargs = mock_post.call_args
        assert call_kwargs.kwargs["json"] == {"action": "play"}

    def test_payload_with_value(self):
        mock_resp = MagicMock()
        mock_resp.json.return_value = {"action": "volume", "result": "ok"}
        mock_resp.raise_for_status = MagicMock()

        with patch("aemeath_agent.tools.music_control.httpx.post", return_value=mock_resp) as mock_post:
            data = _invoke("volume", "80")

        assert data["status"] == "success"
        call_kwargs = mock_post.call_args
        assert call_kwargs.kwargs["json"] == {"action": "volume", "value": "80"}

    def test_connect_error(self):
        with patch(
            "aemeath_agent.tools.music_control.httpx.post",
            side_effect=httpx.ConnectError("Connection refused"),
        ):
            data = _invoke("pause")

        assert data["status"] == "error"
        assert "Cannot connect" in data["message"]

    def test_timeout(self):
        with patch(
            "aemeath_agent.tools.music_control.httpx.post",
            side_effect=httpx.TimeoutException("timed out"),
        ):
            data = _invoke("next")

        assert data["status"] == "error"
        assert "timed out" in data["message"]

    def test_configure_sets_port(self):
        music_mod.configure(wpf_port=7777)
        assert music_mod._wpf_port == 7777

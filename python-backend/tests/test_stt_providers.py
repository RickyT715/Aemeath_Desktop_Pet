"""Tests for speech-to-text providers (Whisper and Gemini)."""

import base64

import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from aemeath_agent.stt.whisper_provider import transcribe_whisper
from aemeath_agent.stt.gemini_provider import transcribe_gemini

# Minimal valid audio data for base64 encoding (doesn't need to be real audio)
FAKE_AUDIO_B64 = base64.b64encode(b"fake audio data").decode()


def _mock_async_client(mock_response):
    """Create a properly-mocked httpx.AsyncClient for async with context."""
    mock_client = AsyncMock()
    mock_client.post.return_value = mock_response

    mock_cm = MagicMock()
    mock_cm.__aenter__ = AsyncMock(return_value=mock_client)
    mock_cm.__aexit__ = AsyncMock(return_value=False)
    return mock_cm, mock_client


# --- Whisper STT ---

class TestWhisperProvider:
    @pytest.mark.asyncio
    async def test_success(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {"text": "Hello, world!"}
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.stt.whisper_provider.httpx.AsyncClient", return_value=mock_cm):
            result = await transcribe_whisper(FAKE_AUDIO_B64, "openai-key")

        assert result == "Hello, world!"

    @pytest.mark.asyncio
    async def test_http_error_propagates(self):
        import httpx

        mock_error_resp = MagicMock()
        mock_error_resp.status_code = 401
        error = httpx.HTTPStatusError("Unauthorized", request=MagicMock(), response=mock_error_resp)

        mock_client = AsyncMock()
        mock_client.post = AsyncMock(side_effect=error)

        mock_cm = MagicMock()
        mock_cm.__aenter__ = AsyncMock(return_value=mock_client)
        mock_cm.__aexit__ = AsyncMock(return_value=False)

        with patch("aemeath_agent.stt.whisper_provider.httpx.AsyncClient", return_value=mock_cm):
            with pytest.raises(httpx.HTTPStatusError):
                await transcribe_whisper(FAKE_AUDIO_B64, "bad-key")

    @pytest.mark.asyncio
    async def test_language_parameter_passed(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {"text": "Bonjour"}
        mock_response.raise_for_status = MagicMock()
        mock_cm, mock_client = _mock_async_client(mock_response)

        with patch("aemeath_agent.stt.whisper_provider.httpx.AsyncClient", return_value=mock_cm):
            result = await transcribe_whisper(FAKE_AUDIO_B64, "key", language="fr")

        assert result == "Bonjour"
        # Verify the language was passed in the data
        call_kwargs = mock_client.post.call_args
        assert call_kwargs.kwargs["data"]["language"] == "fr"


# --- Gemini STT ---

class TestGeminiSttProvider:
    @pytest.mark.asyncio
    async def test_success(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "candidates": [
                {"content": {"parts": [{"text": "Hello from Gemini"}]}}
            ]
        }
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.stt.gemini_provider.httpx.AsyncClient", return_value=mock_cm):
            result = await transcribe_gemini(FAKE_AUDIO_B64, "google-key")

        assert result == "Hello from Gemini"

    @pytest.mark.asyncio
    async def test_empty_candidates_returns_empty(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {"candidates": []}
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.stt.gemini_provider.httpx.AsyncClient", return_value=mock_cm):
            result = await transcribe_gemini(FAKE_AUDIO_B64, "key")

        assert result == ""

    @pytest.mark.asyncio
    async def test_empty_parts_returns_empty(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "candidates": [{"content": {"parts": []}}]
        }
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.stt.gemini_provider.httpx.AsyncClient", return_value=mock_cm):
            result = await transcribe_gemini(FAKE_AUDIO_B64, "key")

        assert result == ""

    @pytest.mark.asyncio
    async def test_language_included_in_prompt(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "candidates": [
                {"content": {"parts": [{"text": "Hola mundo"}]}}
            ]
        }
        mock_response.raise_for_status = MagicMock()
        mock_cm, mock_client = _mock_async_client(mock_response)

        with patch("aemeath_agent.stt.gemini_provider.httpx.AsyncClient", return_value=mock_cm):
            result = await transcribe_gemini(FAKE_AUDIO_B64, "key", language="es")

        assert result == "Hola mundo"
        # Verify the language is included in the payload
        call_kwargs = mock_client.post.call_args
        payload = call_kwargs.kwargs["json"]
        text_part = payload["contents"][0]["parts"][1]["text"]
        assert "es" in text_part

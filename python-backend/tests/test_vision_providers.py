"""Tests for vision providers (Gemini, Claude, Ollama, Hybrid) and analyzer dispatcher."""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from aemeath_agent.config import Settings
from aemeath_agent.vision.gemini_vision import analyze_gemini
from aemeath_agent.vision.claude_vision import analyze_claude
from aemeath_agent.vision.ollama_vision import analyze_ollama
from aemeath_agent.vision.hybrid_vision import analyze_hybrid
from aemeath_agent.vision.analyzer import analyze


def _mock_async_client(mock_response):
    """Create a properly-mocked httpx.AsyncClient for async with context."""
    mock_client = AsyncMock()
    mock_client.post.return_value = mock_response

    mock_cm = MagicMock()
    mock_cm.__aenter__ = AsyncMock(return_value=mock_client)
    mock_cm.__aexit__ = AsyncMock(return_value=False)
    return mock_cm, mock_client


# --- Gemini Vision ---

class TestGeminiVision:
    @pytest.mark.asyncio
    async def test_success(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "candidates": [
                {"content": {"parts": [{"text": "A cat sitting on a desk"}]}}
            ]
        }
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.vision.gemini_vision.httpx.AsyncClient", return_value=mock_cm):
            result = await analyze_gemini("base64data", "Describe this", "api-key")

        assert result == "A cat sitting on a desk"

    @pytest.mark.asyncio
    async def test_empty_candidates(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {"candidates": []}
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.vision.gemini_vision.httpx.AsyncClient", return_value=mock_cm):
            result = await analyze_gemini("base64data", "Describe", "key")

        assert result == "Unable to analyze the image."

    @pytest.mark.asyncio
    async def test_missing_parts(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "candidates": [{"content": {"parts": []}}]
        }
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.vision.gemini_vision.httpx.AsyncClient", return_value=mock_cm):
            result = await analyze_gemini("base64data", "Describe", "key")

        assert result == "Unable to analyze the image."


# --- Claude Vision ---

class TestClaudeVision:
    @pytest.mark.asyncio
    async def test_success(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "content": [{"type": "text", "text": "A browser with code"}]
        }
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.vision.claude_vision.httpx.AsyncClient", return_value=mock_cm):
            result = await analyze_claude("base64data", "Describe", "api-key")

        assert result == "A browser with code"

    @pytest.mark.asyncio
    async def test_empty_content(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {"content": []}
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.vision.claude_vision.httpx.AsyncClient", return_value=mock_cm):
            result = await analyze_claude("base64data", "Describe", "key")

        assert result == "Unable to analyze the image."


# --- Ollama Vision ---

class TestOllamaVision:
    @pytest.mark.asyncio
    async def test_success(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {
            "message": {"content": "Desktop with file manager open"}
        }
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.vision.ollama_vision.httpx.AsyncClient", return_value=mock_cm):
            result = await analyze_ollama("base64data", "Describe", "http://localhost:11434", "llava")

        assert result == "Desktop with file manager open"

    @pytest.mark.asyncio
    async def test_missing_message_content(self):
        mock_response = MagicMock()
        mock_response.json.return_value = {"message": {}}
        mock_response.raise_for_status = MagicMock()
        mock_cm, _ = _mock_async_client(mock_response)

        with patch("aemeath_agent.vision.ollama_vision.httpx.AsyncClient", return_value=mock_cm):
            result = await analyze_ollama("base64data", "Describe")

        assert result == "Unable to analyze the image."


# --- Hybrid Vision ---

class TestHybridVision:
    @pytest.mark.asyncio
    async def test_hybrid_with_gemini_cloud(self):
        settings = Settings(
            _env_file=None,
            ai_provider="gemini",
            google_api_key="gkey",
            anthropic_api_key="",
            ollama_base_url="http://localhost:11434",
            ollama_model_name="llava",
        )

        with patch(
            "aemeath_agent.vision.hybrid_vision.analyze_ollama",
            new_callable=AsyncMock,
            return_value="A desktop showing code editor",
        ) as mock_ollama, patch(
            "aemeath_agent.vision.hybrid_vision._cloud_gemini",
            new_callable=AsyncMock,
            return_value="The user is editing Python code in VS Code",
        ) as mock_cloud:
            result = await analyze_hybrid("base64data", "What is the user doing?", settings)

        assert result == "The user is editing Python code in VS Code"
        mock_ollama.assert_called_once()
        mock_cloud.assert_called_once()

    @pytest.mark.asyncio
    async def test_hybrid_with_claude_cloud(self):
        settings = Settings(
            _env_file=None,
            ai_provider="claude",
            google_api_key="",
            anthropic_api_key="ckey",
            ollama_base_url="http://localhost:11434",
            ollama_model_name="llava",
        )

        with patch(
            "aemeath_agent.vision.hybrid_vision.analyze_ollama",
            new_callable=AsyncMock,
            return_value="A browser window",
        ), patch(
            "aemeath_agent.vision.hybrid_vision._cloud_claude",
            new_callable=AsyncMock,
            return_value="The user is browsing the web",
        ):
            result = await analyze_hybrid("base64data", "What is happening?", settings)

        assert result == "The user is browsing the web"

    @pytest.mark.asyncio
    async def test_hybrid_no_cloud_keys_returns_local(self):
        settings = Settings(
            _env_file=None,
            ai_provider="claude",
            google_api_key="",
            anthropic_api_key="",
            ollama_base_url="http://localhost:11434",
            ollama_model_name="llava",
        )

        with patch(
            "aemeath_agent.vision.hybrid_vision.analyze_ollama",
            new_callable=AsyncMock,
            return_value="Local description only",
        ):
            result = await analyze_hybrid("base64data", "Describe", settings)

        assert result == "Local description only"


# --- Analyzer Dispatcher ---

class TestAnalyzerDispatch:
    @pytest.mark.asyncio
    async def test_dispatches_to_gemini(self):
        settings = Settings(_env_file=None, google_api_key="gkey")

        with patch(
            "aemeath_agent.vision.gemini_vision.analyze_gemini",
            new_callable=AsyncMock,
            return_value="gemini result",
        ):
            result = await analyze("img", "prompt", "gemini", settings)
        assert result == "gemini result"

    @pytest.mark.asyncio
    async def test_dispatches_to_claude(self):
        settings = Settings(_env_file=None, anthropic_api_key="ckey")

        with patch(
            "aemeath_agent.vision.claude_vision.analyze_claude",
            new_callable=AsyncMock,
            return_value="claude result",
        ):
            result = await analyze("img", "prompt", "claude", settings)
        assert result == "claude result"

    @pytest.mark.asyncio
    async def test_unknown_provider_raises(self):
        settings = Settings(_env_file=None)
        with pytest.raises(ValueError, match="Unknown vision provider"):
            await analyze("img", "prompt", "nonexistent", settings)

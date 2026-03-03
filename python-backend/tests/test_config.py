"""Tests for application configuration."""

from aemeath_agent.config import Settings, get_settings


def test_settings_defaults():
    settings = Settings(
        _env_file=None,  # type: ignore[call-arg]
    )
    assert settings.ai_provider == "claude"
    assert settings.port == 18900
    assert settings.wpf_internal_port == 18901
    assert settings.embedding_model == "gemini"
    assert settings.vision_provider == "gemini"
    assert settings.host == "127.0.0.1"


def test_settings_api_keys_default_empty():
    settings = Settings(
        _env_file=None,  # type: ignore[call-arg]
    )
    assert settings.anthropic_api_key == ""
    assert settings.google_api_key == ""
    assert settings.tavily_api_key == ""
    assert settings.openweather_api_key == ""


def test_settings_chromadb_path():
    settings = Settings(
        _env_file=None,  # type: ignore[call-arg]
    )
    assert settings.chromadb_path == "data/chromadb"


def test_get_settings_returns_settings():
    settings = get_settings()
    assert isinstance(settings, Settings)

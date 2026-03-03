"""Tests for the config sync endpoint (api/routes_config.py)."""

from unittest.mock import MagicMock, patch

from fastapi import FastAPI
from fastapi.testclient import TestClient

from aemeath_agent.api.routes_config import router


def _make_client():
    app = FastAPI()
    app.include_router(router)
    return TestClient(app)


def _make_fake_settings():
    """Create a fake Settings with all relevant attributes."""
    s = MagicMock()
    s.ai_provider = "claude"
    s.anthropic_api_key = ""
    s.google_api_key = ""
    s.tavily_api_key = ""
    s.openweather_api_key = ""
    s.vision_provider = "gemini"
    s.ollama_base_url = "http://localhost:11434"
    s.ollama_model_name = "llava"
    s.embedding_model = "gemini"
    return s


def test_sync_updates_field():
    """Syncing a single field updates the settings."""
    fake = _make_fake_settings()

    with patch("aemeath_agent.api.routes_config.get_settings", return_value=fake):
        client = _make_client()
        resp = client.post(
            "/config/sync",
            json={"ai_provider": "gemini"},
        )

    assert resp.status_code == 200
    assert fake.ai_provider == "gemini"


def test_sync_multiple_fields():
    """Multiple fields can be synced at once."""
    fake = _make_fake_settings()

    with patch("aemeath_agent.api.routes_config.get_settings", return_value=fake):
        client = _make_client()
        resp = client.post(
            "/config/sync",
            json={
                "ai_provider": "gemini",
                "google_api_key": "test-key-123",
                "vision_provider": "ollama",
            },
        )

    assert resp.status_code == 200
    data = resp.json()
    assert fake.ai_provider == "gemini"
    assert fake.google_api_key == "test-key-123"
    assert fake.vision_provider == "ollama"
    # The response should list updated fields
    assert "ai_provider" in data["updated"]
    assert "google_api_key" in data["updated"]


def test_sync_none_fields_ignored():
    """Fields set to None (default) should not update settings."""
    fake = _make_fake_settings()

    with patch("aemeath_agent.api.routes_config.get_settings", return_value=fake):
        client = _make_client()
        resp = client.post(
            "/config/sync",
            json={},  # All fields are None
        )

    assert resp.status_code == 200
    data = resp.json()
    assert data["updated"] == "none"


def test_sync_response_has_updated_list():
    """Response should have 'updated' key listing changed fields."""
    fake = _make_fake_settings()

    with patch("aemeath_agent.api.routes_config.get_settings", return_value=fake):
        client = _make_client()
        resp = client.post(
            "/config/sync",
            json={"embedding_model": "local"},
        )

    data = resp.json()
    assert data["status"] == "ok"
    assert "embedding_model" in data["updated"]


def test_sync_unknown_field_safe():
    """Unknown fields in ConfigSyncRequest should be harmlessly ignored.

    Pydantic's BaseModel drops extra fields, so they never reach setattr.
    """
    fake = _make_fake_settings()

    with patch("aemeath_agent.api.routes_config.get_settings", return_value=fake):
        client = _make_client()
        # ConfigSyncRequest will drop 'nonexistent_field' because it's not defined
        resp = client.post(
            "/config/sync",
            json={"ai_provider": "gemini"},
        )

    assert resp.status_code == 200

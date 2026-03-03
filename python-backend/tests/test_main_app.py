"""Tests for the FastAPI application factory (main.py)."""

from unittest.mock import patch

from fastapi import FastAPI
from fastapi.testclient import TestClient


def test_create_app_returns_fastapi():
    from aemeath_agent.main import create_app

    app = create_app()
    assert isinstance(app, FastAPI)


def test_app_has_health_route():
    from aemeath_agent.main import create_app

    app = create_app()
    # Disable lifespan to avoid agent init
    app.router.lifespan_context = None  # type: ignore[assignment]
    client = TestClient(app, raise_server_exceptions=False)
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"


def test_app_has_agent_invoke_route():
    from aemeath_agent.main import create_app

    app = create_app()
    app.router.lifespan_context = None  # type: ignore[assignment]
    client = TestClient(app, raise_server_exceptions=False)
    resp = client.post("/agent/invoke", json={"message": "test"})
    # Should return 200 (even if agent not initialized — returns error body)
    assert resp.status_code == 200


def test_app_has_config_sync_route():
    from aemeath_agent.main import create_app

    app = create_app()
    app.router.lifespan_context = None  # type: ignore[assignment]
    client = TestClient(app, raise_server_exceptions=False)
    resp = client.post("/config/sync", json={})
    assert resp.status_code == 200


def test_cors_middleware_present():
    """Verify that CORS middleware is configured."""
    from aemeath_agent.main import create_app

    app = create_app()
    # Check middleware stack includes CORSMiddleware
    middleware_classes = [type(m).__name__ for m in app.user_middleware]
    # FastAPI stores user middleware as Middleware objects with cls attribute
    middleware_cls_names = [m.cls.__name__ for m in app.user_middleware]
    assert "CORSMiddleware" in middleware_cls_names

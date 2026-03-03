"""Tests for the health endpoint."""

from fastapi.testclient import TestClient

from aemeath_agent.api.routes_health import router


def _make_client() -> TestClient:
    from fastapi import FastAPI

    app = FastAPI()
    app.include_router(router)
    return TestClient(app)


def test_health_returns_ok():
    client = _make_client()
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"


def test_health_has_version():
    client = _make_client()
    resp = client.get("/health")
    data = resp.json()
    assert "version" in data
    assert data["version"] == "0.1.0"


def test_health_has_uptime():
    client = _make_client()
    resp = client.get("/health")
    data = resp.json()
    assert "uptime" in data
    assert isinstance(data["uptime"], float)
    assert data["uptime"] >= 0

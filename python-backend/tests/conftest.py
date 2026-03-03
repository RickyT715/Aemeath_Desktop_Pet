"""Shared test fixtures."""

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def test_client():
    """Create a FastAPI test client with lifespan disabled for unit tests."""
    from aemeath_agent.main import create_app

    # Create app without lifespan to avoid LLM initialization
    app = create_app()
    app.router.lifespan_context = None  # type: ignore[assignment]
    return TestClient(app, raise_server_exceptions=False)

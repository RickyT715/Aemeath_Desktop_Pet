"""Tests for agent invoke and stream endpoints (api/routes_agent.py)."""

import json
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from aemeath_agent.api.routes_agent import router, set_agent, _build_config


def _make_app():
    """Create a minimal FastAPI app with only the agent router."""
    app = FastAPI()
    app.include_router(router)
    return app


def _make_client():
    return TestClient(_make_app(), raise_server_exceptions=False)


# ---- set_agent ---------------------------------------------------------------

def test_set_agent_sets_global():
    """set_agent stores the agent in the module-level global."""
    import aemeath_agent.api.routes_agent as mod

    old = mod._agent
    try:
        fake = MagicMock(name="agent")
        set_agent(fake)
        assert mod._agent is fake
    finally:
        mod._agent = old


# ---- _build_config -----------------------------------------------------------

def test_build_config_structure():
    config = _build_config("thread-42")
    assert config == {
        "configurable": {
            "thread_id": "thread-42",
            "user_id": "owner",
        }
    }


# ---- POST /agent/invoke ------------------------------------------------------

def test_invoke_no_agent_returns_not_initialized():
    """When no agent is set, invoke returns 'Agent not initialized'."""
    import aemeath_agent.api.routes_agent as mod

    old = mod._agent
    try:
        mod._agent = None
        client = _make_client()
        resp = client.post(
            "/agent/invoke",
            json={"message": "hello"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "not initialized" in data["reply"].lower()
    finally:
        mod._agent = old


def test_invoke_success():
    """A successful invoke returns the agent's reply."""
    import aemeath_agent.api.routes_agent as mod

    fake_msg = MagicMock()
    fake_msg.content = "Hello from Aemeath!"
    fake_msg.tool_calls = []

    fake_agent = AsyncMock()
    fake_agent.ainvoke.return_value = {"messages": [fake_msg]}

    old = mod._agent
    try:
        mod._agent = fake_agent
        client = _make_client()
        resp = client.post(
            "/agent/invoke",
            json={"message": "hi", "thread_id": "t1"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["reply"] == "Hello from Aemeath!"
        assert data["thread_id"] == "t1"
    finally:
        mod._agent = old


def test_invoke_exception_returns_error():
    """When the agent raises, invoke returns an error message gracefully."""
    import aemeath_agent.api.routes_agent as mod

    fake_agent = AsyncMock()
    fake_agent.ainvoke.side_effect = RuntimeError("LLM exploded")

    old = mod._agent
    try:
        mod._agent = fake_agent
        client = _make_client()
        resp = client.post(
            "/agent/invoke",
            json={"message": "hi"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "error" in data["reply"].lower()
    finally:
        mod._agent = old


def test_invoke_passes_thread_id_in_config():
    """Verify that thread_id from the request is forwarded to agent config."""
    import aemeath_agent.api.routes_agent as mod

    fake_agent = AsyncMock()
    fake_msg = MagicMock()
    fake_msg.content = "ok"
    fake_msg.tool_calls = []
    fake_agent.ainvoke.return_value = {"messages": [fake_msg]}

    old = mod._agent
    try:
        mod._agent = fake_agent
        client = _make_client()
        client.post(
            "/agent/invoke",
            json={"message": "hi", "thread_id": "custom-thread"},
        )

        call_args = fake_agent.ainvoke.call_args
        config = call_args.kwargs.get("config") or call_args[1].get("config")
        assert config["configurable"]["thread_id"] == "custom-thread"
    finally:
        mod._agent = old


def test_invoke_passes_context():
    """Verify that context from request is forwarded to input_messages."""
    import aemeath_agent.api.routes_agent as mod

    fake_agent = AsyncMock()
    fake_msg = MagicMock()
    fake_msg.content = "ok"
    fake_msg.tool_calls = []
    fake_agent.ainvoke.return_value = {"messages": [fake_msg]}

    old = mod._agent
    try:
        mod._agent = fake_agent
        client = _make_client()
        client.post(
            "/agent/invoke",
            json={"message": "hi", "context": {"mood": 80}},
        )

        call_args = fake_agent.ainvoke.call_args
        input_messages = call_args[0][0] if call_args[0] else call_args.kwargs.get("input")
        assert input_messages.get("context") == {"mood": 80}
    finally:
        mod._agent = old


# ---- POST /agent/stream ------------------------------------------------------

def test_stream_no_agent_returns_error_sse():
    """When no agent is set, stream emits an error SSE event."""
    import aemeath_agent.api.routes_agent as mod

    old = mod._agent
    try:
        mod._agent = None
        client = _make_client()
        resp = client.post(
            "/agent/stream",
            json={"message": "hello"},
        )
        assert resp.status_code == 200
        # SSE body should contain an error event
        body = resp.text
        assert "error" in body.lower()
    finally:
        mod._agent = old


def test_stream_returns_event_source_response():
    """Verify the stream endpoint returns a streaming response (status 200)."""
    import aemeath_agent.api.routes_agent as mod

    # Agent that yields nothing — just to verify the endpoint works
    async def fake_astream(*args, **kwargs):
        return
        yield  # make it an async generator

    fake_agent = MagicMock()
    fake_agent.astream = fake_astream

    old = mod._agent
    try:
        mod._agent = fake_agent
        client = _make_client()
        resp = client.post(
            "/agent/stream",
            json={"message": "hello"},
        )
        assert resp.status_code == 200
        # Should contain the done event at minimum
        assert "done" in resp.text
    finally:
        mod._agent = old

"""Tests for Pydantic request/response schemas."""

from aemeath_agent.api.models import (
    AgentRequest,
    AgentResponse,
    ConfigSyncRequest,
    HealthResponse,
    RagIngestRequest,
    RagQueryRequest,
    RagStatusResponse,
    StreamEvent,
    SttRequest,
    VisionRequest,
)


def test_agent_request_defaults():
    req = AgentRequest(message="Hello")
    assert req.message == "Hello"
    assert req.thread_id == "default"
    assert req.context == {}


def test_agent_request_with_context():
    req = AgentRequest(
        message="Hi", thread_id="abc", context={"mood": 80}
    )
    assert req.thread_id == "abc"
    assert req.context["mood"] == 80


def test_agent_response():
    resp = AgentResponse(reply="Hi!", thread_id="t1")
    assert resp.reply == "Hi!"
    assert resp.tool_calls == []
    assert resp.thread_id == "t1"


def test_stream_event_token():
    evt = StreamEvent(type="token", content="Hello")
    assert evt.type == "token"
    assert evt.content == "Hello"
    assert evt.data is None


def test_stream_event_tool_call():
    evt = StreamEvent(type="tool_call", data={"name": "weather"})
    assert evt.type == "tool_call"
    assert evt.data == {"name": "weather"}


def test_health_response_defaults():
    resp = HealthResponse()
    assert resp.status == "ok"
    assert resp.version == "0.1.0"
    assert resp.uptime == 0.0


def test_config_sync_all_none():
    req = ConfigSyncRequest()
    assert req.ai_provider is None
    assert req.anthropic_api_key is None


def test_rag_ingest_request():
    req = RagIngestRequest(path="/docs")
    assert req.path == "/docs"
    assert req.is_directory is False
    assert req.glob_pattern == "**/*.*"


def test_rag_query_request():
    req = RagQueryRequest(query="what is AI?")
    assert req.query == "what is AI?"
    assert req.top_k == 5


def test_rag_status_response():
    resp = RagStatusResponse()
    assert resp.initialized is False
    assert resp.document_count == 0


def test_stt_request():
    req = SttRequest(audio_base64="abc123")
    assert req.provider == "whisper"
    assert req.language == "en"


def test_vision_request():
    req = VisionRequest(image_base64="base64data")
    assert req.prompt == "Describe what you see in this image."
    assert req.provider is None

"""Tests for SSE event formatting."""

import json

from aemeath_agent.api.sse import format_sse_done, format_sse_error, format_sse_event


def test_format_sse_event_token():
    result = format_sse_event("token", content="Hello")
    assert result.startswith("data: ")
    assert result.endswith("\n\n")
    payload = json.loads(result[len("data: "):].strip())
    assert payload["type"] == "token"
    assert payload["content"] == "Hello"


def test_format_sse_event_tool_call():
    result = format_sse_event("tool_call", data={"name": "weather"})
    payload = json.loads(result[len("data: "):].strip())
    assert payload["type"] == "tool_call"
    assert payload["data"]["name"] == "weather"


def test_format_sse_event_no_content():
    result = format_sse_event("done")
    payload = json.loads(result[len("data: "):].strip())
    assert payload["type"] == "done"
    assert "content" not in payload


def test_format_sse_done():
    result = format_sse_done()
    payload = json.loads(result[len("data: "):].strip())
    assert payload["type"] == "done"


def test_format_sse_error():
    result = format_sse_error("something broke")
    payload = json.loads(result[len("data: "):].strip())
    assert payload["type"] == "error"
    assert payload["content"] == "something broke"

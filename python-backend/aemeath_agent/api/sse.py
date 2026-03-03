"""SSE event formatting helpers."""

import json
from typing import Any


def format_sse_event(event_type: str, content: str = "", data: dict[str, Any] | None = None) -> str:
    """Format a server-sent event as a JSON data line.

    Args:
        event_type: One of token, tool_call, tool_result, done, error.
        content: Text content for the event.
        data: Optional structured data payload.

    Returns:
        A formatted SSE data line ending with double newline.
    """
    payload: dict[str, Any] = {"type": event_type}
    if content:
        payload["content"] = content
    if data is not None:
        payload["data"] = data
    return f"data: {json.dumps(payload)}\n\n"


def format_sse_done() -> str:
    """Format a terminal 'done' SSE event."""
    return format_sse_event("done")


def format_sse_error(message: str) -> str:
    """Format an error SSE event."""
    return format_sse_event("error", content=message)

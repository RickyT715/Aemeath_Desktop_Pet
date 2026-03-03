"""Agent invoke and stream endpoints."""

import json
import logging
from typing import Any

from fastapi import APIRouter
from sse_starlette.sse import EventSourceResponse

from aemeath_agent.api.models import AgentRequest, AgentResponse
from aemeath_agent.api.sse import format_sse_done, format_sse_error, format_sse_event

router = APIRouter(prefix="/agent", tags=["agent"])
logger = logging.getLogger(__name__)

# The agent is injected at startup via set_agent()
_agent: Any = None
_agent_kwargs: dict[str, Any] = {}


def set_agent(agent: Any, **kwargs: Any) -> None:
    """Set the global agent instance (called during app lifespan)."""
    global _agent, _agent_kwargs
    _agent = agent
    _agent_kwargs = kwargs


def _build_config(thread_id: str) -> dict[str, Any]:
    return {"configurable": {"thread_id": thread_id, "user_id": "owner"}}


@router.post("/stream")
async def stream_agent(request: AgentRequest) -> EventSourceResponse:
    """Stream agent responses as Server-Sent Events.

    Event types: token, tool_call, tool_result, done, error.
    """

    async def event_generator():
        if _agent is None:
            yield format_sse_error("Agent not initialized")
            yield format_sse_done()
            return

        config = _build_config(request.thread_id)
        input_messages = {"messages": [{"role": "user", "content": request.message}]}

        if request.context:
            input_messages["context"] = request.context

        try:
            async for mode, chunk in _agent.astream(
                input_messages,
                config=config,
                stream_mode=["messages", "updates"],
            ):
                if mode == "messages":
                    token, metadata = chunk
                    if hasattr(token, "content") and token.content:
                        yield format_sse_event("token", content=token.content)
                    if hasattr(token, "tool_calls") and token.tool_calls:
                        for tc in token.tool_calls:
                            yield format_sse_event(
                                "tool_call",
                                content=tc.get("name", ""),
                                data={"args": tc.get("args", {})},
                            )
                elif mode == "updates":
                    for source, update in chunk.items():
                        if source == "tools":
                            yield format_sse_event(
                                "tool_result",
                                data={"result": str(update)},
                            )
        except Exception:
            logger.exception("Agent stream error")
            yield format_sse_error("Internal agent error")

        yield format_sse_done()

    return EventSourceResponse(event_generator())


@router.post("/invoke", response_model=AgentResponse)
async def invoke_agent(request: AgentRequest) -> AgentResponse:
    """One-shot agent invocation (non-streaming)."""
    if _agent is None:
        return AgentResponse(reply="Agent not initialized", tool_calls=[], thread_id=request.thread_id)

    config = _build_config(request.thread_id)
    input_messages = {"messages": [{"role": "user", "content": request.message}]}

    if request.context:
        input_messages["context"] = request.context

    try:
        result = await _agent.ainvoke(input_messages, config=config)
        messages = result.get("messages", [])
        reply = ""
        tool_calls: list[dict[str, Any]] = []

        for msg in reversed(messages):
            if hasattr(msg, "content") and msg.content and not reply:
                reply = msg.content if isinstance(msg.content, str) else json.dumps(msg.content)
            if hasattr(msg, "tool_calls") and msg.tool_calls:
                tool_calls.extend(
                    {"name": tc.get("name", ""), "args": tc.get("args", {})}
                    for tc in msg.tool_calls
                )

        return AgentResponse(reply=reply, tool_calls=tool_calls, thread_id=request.thread_id)
    except Exception:
        logger.exception("Agent invoke error")
        return AgentResponse(
            reply="I ran into an error processing your request.",
            tool_calls=[],
            thread_id=request.thread_id,
        )

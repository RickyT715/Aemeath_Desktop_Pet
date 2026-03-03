"""Screen reader tool — reads screen content via WPF internal API."""

import json
import logging

import httpx
from langchain_core.tools import tool

logger = logging.getLogger(__name__)

_wpf_port: int = 18901


def configure(wpf_port: int) -> None:
    """Set the WPF internal API port."""
    global _wpf_port
    _wpf_port = wpf_port


@tool
def read_screen() -> str:
    """Analyze what's currently visible on the user's screen.

    Use when the user asks what they're looking at, needs help with something
    on screen, or you need visual context. Returns a text description of the
    screen contents.
    """
    try:
        response = httpx.get(
            f"http://localhost:{_wpf_port}/internal/screen",
            timeout=15.0,
        )
        response.raise_for_status()
        data = response.json()
        return json.dumps({"status": "success", "data": data})
    except httpx.ConnectError:
        return json.dumps({"status": "error", "message": "Cannot connect to WPF app. Is it running?"})
    except httpx.TimeoutException:
        return json.dumps({"status": "error", "message": "Screen capture timed out."})
    except Exception as e:
        logger.exception("Screen reader failed")
        return json.dumps({"status": "error", "message": str(e)})

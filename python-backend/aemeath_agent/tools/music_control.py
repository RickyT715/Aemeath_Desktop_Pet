"""Music control tool — controls music playback via WPF internal API."""

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
def control_music(action: str, value: str = "") -> str:
    """Control music playback on the desktop pet.

    Args:
        action: One of 'play', 'pause', 'next', 'previous', 'volume'.
        value: Volume level (0-100) when action is 'volume', or song name for 'play'.
    """
    try:
        payload = {"action": action}
        if value:
            payload["value"] = value

        response = httpx.post(
            f"http://localhost:{_wpf_port}/internal/music/control",
            json=payload,
            timeout=10.0,
        )
        response.raise_for_status()
        data = response.json()
        return json.dumps({"status": "success", "data": data})
    except httpx.ConnectError:
        return json.dumps({"status": "error", "message": "Cannot connect to WPF app. Is it running?"})
    except httpx.TimeoutException:
        return json.dumps({"status": "error", "message": "Music control timed out."})
    except Exception as e:
        logger.exception("Music control failed")
        return json.dumps({"status": "error", "message": str(e)})

"""Pet stats tool — reads pet mood/energy/affection via WPF internal API."""

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
def get_pet_stats() -> str:
    """Check the pet's current mood, energy, and affection levels.

    Returns the desktop pet's emotional and energy state. Use this when
    you need to know how Aemeath is feeling or when the user asks about
    pet status.
    """
    try:
        response = httpx.get(
            f"http://localhost:{_wpf_port}/internal/stats",
            timeout=10.0,
        )
        response.raise_for_status()
        data = response.json()
        return json.dumps({"status": "success", "data": data})
    except httpx.ConnectError:
        return json.dumps({"status": "error", "message": "Cannot connect to WPF app. Is it running?"})
    except httpx.TimeoutException:
        return json.dumps({"status": "error", "message": "Stats request timed out."})
    except Exception as e:
        logger.exception("Pet stats failed")
        return json.dumps({"status": "error", "message": str(e)})

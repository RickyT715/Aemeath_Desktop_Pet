"""HTTP client for the C# WPF internal API.

The WPF desktop pet app runs an internal HTTP server on a configurable port
(default 18901). This client provides async methods for all internal endpoints.
"""

import logging
from typing import Any

import httpx

logger = logging.getLogger(__name__)


class WpfBridgeClient:
    """Async HTTP client for the WPF internal API."""

    def __init__(self, base_url: str = "http://localhost:18901", timeout: float = 10.0):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    async def _get(self, path: str) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(f"{self.base_url}{path}")
            response.raise_for_status()
            return response.json()

    async def _post(self, path: str, data: dict[str, Any] | None = None) -> dict[str, Any]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(f"{self.base_url}{path}", json=data or {})
            response.raise_for_status()
            return response.json()

    async def get_stats(self) -> dict[str, Any]:
        """Get pet mood, energy, and affection stats."""
        return await self._get("/internal/stats")

    async def get_screen(self) -> dict[str, Any]:
        """Capture and analyze the current screen."""
        return await self._get("/internal/screen")

    async def control_music(self, action: str, value: str = "") -> dict[str, Any]:
        """Control music playback."""
        return await self._post("/internal/music/control", {"action": action, "value": value})

    async def send_speech_bubble(self, text: str) -> dict[str, Any]:
        """Display a speech bubble on the pet."""
        return await self._post("/internal/speech", {"text": text})

    async def trigger_animation(self, animation: str) -> dict[str, Any]:
        """Trigger a specific pet animation."""
        return await self._post("/internal/animation", {"name": animation})

    async def health_check(self) -> bool:
        """Check if the WPF internal API is reachable."""
        try:
            await self._get("/internal/health")
            return True
        except Exception:
            return False

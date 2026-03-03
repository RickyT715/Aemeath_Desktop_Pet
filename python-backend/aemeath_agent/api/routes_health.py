"""Health check endpoint."""

import time

from fastapi import APIRouter

from aemeath_agent.api.models import HealthResponse

router = APIRouter(tags=["health"])

_start_time = time.monotonic()


@router.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Return service health status, version, and uptime."""
    return HealthResponse(
        status="ok",
        version="0.1.0",
        uptime=round(time.monotonic() - _start_time, 2),
    )

"""Configuration sync endpoint — accepts runtime config updates from WPF app."""

import logging

from fastapi import APIRouter

from aemeath_agent.api.models import ConfigSyncRequest
from aemeath_agent.config import get_settings

router = APIRouter(prefix="/config", tags=["config"])
logger = logging.getLogger(__name__)


@router.post("/sync")
async def sync_config(request: ConfigSyncRequest) -> dict[str, str]:
    """Update backend configuration at runtime.

    The WPF app calls this after startup or when the user changes settings
    to push API keys and provider preferences to the Python backend.
    """
    settings = get_settings()
    updated_fields: list[str] = []

    for field_name, value in request.model_dump(exclude_none=True).items():
        if hasattr(settings, field_name):
            setattr(settings, field_name, value)
            updated_fields.append(field_name)

    logger.info("Config sync: updated fields %s", updated_fields)
    return {"status": "ok", "updated": ", ".join(updated_fields) if updated_fields else "none"}

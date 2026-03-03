"""Vision / image analysis endpoint."""

import logging

from fastapi import APIRouter

from aemeath_agent.api.models import VisionRequest
from aemeath_agent.config import get_settings

router = APIRouter(prefix="/vision", tags=["vision"])
logger = logging.getLogger(__name__)


@router.post("/analyze")
async def analyze_image(request: VisionRequest) -> dict[str, str]:
    """Analyze an image using the configured vision provider."""
    settings = get_settings()
    provider = request.provider or settings.vision_provider

    try:
        from aemeath_agent.vision.analyzer import analyze

        result = await analyze(
            image_base64=request.image_base64,
            prompt=request.prompt,
            provider=provider,
            settings=settings,
        )
        return {"status": "ok", "analysis": result}
    except Exception:
        logger.exception("Vision analysis error (provider=%s)", provider)
        return {"status": "error", "analysis": "Vision analysis failed."}

"""Speech-to-text transcription endpoint."""

import logging

from fastapi import APIRouter

from aemeath_agent.api.models import SttRequest, SttResponse
from aemeath_agent.config import get_settings

router = APIRouter(prefix="/stt", tags=["stt"])
logger = logging.getLogger(__name__)


@router.post("/transcribe", response_model=SttResponse)
async def transcribe(request: SttRequest) -> SttResponse:
    """Transcribe audio to text using the specified provider."""
    settings = get_settings()

    try:
        if request.provider == "whisper":
            from aemeath_agent.stt.whisper_provider import transcribe_whisper

            text = await transcribe_whisper(
                request.audio_base64,
                api_key=settings.anthropic_api_key,
                language=request.language,
            )
        elif request.provider == "gemini":
            from aemeath_agent.stt.gemini_provider import transcribe_gemini

            text = await transcribe_gemini(
                request.audio_base64,
                api_key=settings.google_api_key,
                language=request.language,
            )
        else:
            return SttResponse(text="", language=request.language, confidence=0.0)

        return SttResponse(text=text, language=request.language, confidence=1.0)
    except Exception:
        logger.exception("STT transcription error (provider=%s)", request.provider)
        return SttResponse(text="", language=request.language, confidence=0.0)

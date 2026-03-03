"""OpenAI Whisper API transcription provider."""

import base64
import logging
import tempfile
from pathlib import Path

import httpx

logger = logging.getLogger(__name__)

WHISPER_API_URL = "https://api.openai.com/v1/audio/transcriptions"


async def transcribe_whisper(
    audio_base64: str,
    api_key: str,
    language: str = "en",
    model: str = "whisper-1",
) -> str:
    """Transcribe audio using OpenAI's Whisper API.

    Args:
        audio_base64: Base64-encoded audio data.
        api_key: OpenAI API key.
        language: Language code (default "en").
        model: Whisper model name (default "whisper-1").

    Returns:
        Transcribed text string.
    """
    audio_bytes = base64.b64decode(audio_base64)

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp.write(audio_bytes)
        tmp_path = Path(tmp.name)

    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            with open(tmp_path, "rb") as f:
                response = await client.post(
                    WHISPER_API_URL,
                    headers={"Authorization": f"Bearer {api_key}"},
                    files={"file": ("audio.wav", f, "audio/wav")},
                    data={"model": model, "language": language},
                )
            response.raise_for_status()
            return response.json().get("text", "")
    finally:
        tmp_path.unlink(missing_ok=True)

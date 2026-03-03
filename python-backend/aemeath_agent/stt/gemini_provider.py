"""Gemini STT transcription provider."""

import base64
import logging

import httpx

logger = logging.getLogger(__name__)

GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"


async def transcribe_gemini(
    audio_base64: str,
    api_key: str,
    language: str = "en",
) -> str:
    """Transcribe audio using Google Gemini's multimodal API.

    Sends audio as inline data to Gemini with a transcription prompt.

    Args:
        audio_base64: Base64-encoded audio data.
        api_key: Google API key.
        language: Language hint (default "en").

    Returns:
        Transcribed text string.
    """
    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": "audio/wav",
                            "data": audio_base64,
                        }
                    },
                    {
                        "text": f"Transcribe this audio to text. The language is {language}. "
                        "Return only the transcription, nothing else."
                    },
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.0,
            "maxOutputTokens": 2048,
        },
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            GEMINI_API_URL,
            params={"key": api_key},
            json=payload,
        )
        response.raise_for_status()
        data = response.json()

    candidates = data.get("candidates", [])
    if candidates:
        parts = candidates[0].get("content", {}).get("parts", [])
        if parts:
            return parts[0].get("text", "")

    return ""

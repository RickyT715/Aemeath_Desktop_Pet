"""Gemini Flash vision analysis provider."""

import logging

import httpx

logger = logging.getLogger(__name__)

GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"


async def analyze_gemini(image_base64: str, prompt: str, api_key: str) -> str:
    """Analyze an image using Gemini Flash's multimodal capabilities.

    Args:
        image_base64: Base64-encoded image (JPEG or PNG).
        prompt: What to analyze or describe.
        api_key: Google API key.

    Returns:
        Text analysis of the image.
    """
    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": image_base64,
                        }
                    },
                    {"text": prompt},
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.4,
            "maxOutputTokens": 1024,
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

    return "Unable to analyze the image."

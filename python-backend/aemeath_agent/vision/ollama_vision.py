"""Ollama local vision analysis provider."""

import logging

import httpx

logger = logging.getLogger(__name__)


async def analyze_ollama(
    image_base64: str,
    prompt: str,
    base_url: str = "http://localhost:11434",
    model: str = "llava",
) -> str:
    """Analyze an image using a local Ollama vision model.

    Sends a base64 image to Ollama's /api/chat endpoint with a vision-capable model.

    Args:
        image_base64: Base64-encoded image (JPEG or PNG).
        prompt: What to analyze or describe.
        base_url: Ollama server URL (default localhost:11434).
        model: Vision model name (default "llava").

    Returns:
        Text analysis of the image.
    """
    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": prompt,
                "images": [image_base64],
            }
        ],
        "stream": False,
    }

    async with httpx.AsyncClient(timeout=60.0) as client:
        response = await client.post(
            f"{base_url}/api/chat",
            json=payload,
        )
        response.raise_for_status()
        data = response.json()

    message = data.get("message", {})
    return message.get("content", "Unable to analyze the image.")

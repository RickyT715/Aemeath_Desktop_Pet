"""Claude vision analysis provider."""

import logging

import httpx

logger = logging.getLogger(__name__)

CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"


async def analyze_claude(image_base64: str, prompt: str, api_key: str) -> str:
    """Analyze an image using Claude's vision capabilities.

    Args:
        image_base64: Base64-encoded image (JPEG or PNG).
        prompt: What to analyze or describe.
        api_key: Anthropic API key.

    Returns:
        Text analysis of the image.
    """
    payload = {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": image_base64,
                        },
                    },
                    {
                        "type": "text",
                        "text": prompt,
                    },
                ],
            }
        ],
    }

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            CLAUDE_API_URL,
            headers={
                "x-api-key": api_key,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json=payload,
        )
        response.raise_for_status()
        data = response.json()

    content = data.get("content", [])
    if content:
        return content[0].get("text", "Unable to analyze the image.")

    return "Unable to analyze the image."

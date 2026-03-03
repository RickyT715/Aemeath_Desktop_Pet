"""Hybrid vision provider — local Ollama for image description, cloud for text-only analysis.

This ensures raw pixels never leave the user's device. Ollama generates a text
description of the image locally, then a cloud model receives only that text
description for higher-quality reasoning.
"""

import logging

import httpx

from aemeath_agent.config import Settings
from aemeath_agent.vision.ollama_vision import analyze_ollama

logger = logging.getLogger(__name__)


async def analyze_hybrid(
    image_base64: str,
    prompt: str,
    settings: Settings,
) -> str:
    """Analyze an image using hybrid local+cloud approach.

    Step 1: Ollama generates a text description locally (pixels stay on device).
    Step 2: A cloud model receives the text description for deeper analysis.

    Args:
        image_base64: Base64-encoded image.
        prompt: Analysis prompt.
        settings: Application settings with API keys and Ollama config.

    Returns:
        Text analysis of the image.
    """
    # Step 1: Local description via Ollama
    local_description = await analyze_ollama(
        image_base64,
        prompt="Describe what you see in this image in detail. Include any text, UI elements, "
        "application names, and layout information.",
        base_url=settings.ollama_base_url,
        model=settings.ollama_model_name,
    )

    # Step 2: Cloud analysis of text description only (no pixels)
    cloud_prompt = (
        f"Based on this description of a screenshot, {prompt}\n\n"
        f"Image description:\n{local_description}"
    )

    if settings.ai_provider == "gemini" and settings.google_api_key:
        return await _cloud_gemini(cloud_prompt, settings.google_api_key)
    elif settings.anthropic_api_key:
        return await _cloud_claude(cloud_prompt, settings.anthropic_api_key)

    # Fallback: return local description if no cloud keys
    return local_description


async def _cloud_gemini(prompt: str, api_key: str) -> str:
    url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.4, "maxOutputTokens": 1024},
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(url, params={"key": api_key}, json=payload)
        response.raise_for_status()
        data = response.json()

    candidates = data.get("candidates", [])
    if candidates:
        parts = candidates[0].get("content", {}).get("parts", [])
        if parts:
            return parts[0].get("text", "")
    return ""


async def _cloud_claude(prompt: str, api_key: str) -> str:
    url = "https://api.anthropic.com/v1/messages"
    payload = {
        "model": "claude-sonnet-4-20250514",
        "max_tokens": 1024,
        "messages": [{"role": "user", "content": prompt}],
    }
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            url,
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
        return content[0].get("text", "")
    return ""

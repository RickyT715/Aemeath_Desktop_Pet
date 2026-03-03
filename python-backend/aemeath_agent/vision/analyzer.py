"""Vision analysis dispatcher — routes to the correct provider."""

import logging

from aemeath_agent.config import Settings

logger = logging.getLogger(__name__)


async def analyze(
    image_base64: str,
    prompt: str,
    provider: str,
    settings: Settings,
) -> str:
    """Analyze an image using the specified vision provider.

    Args:
        image_base64: Base64-encoded image data.
        prompt: Analysis prompt describing what to look for.
        provider: One of "gemini", "claude", "ollama", "hybrid".
        settings: Application settings with API keys.

    Returns:
        Text description/analysis of the image.
    """
    if provider == "gemini":
        from aemeath_agent.vision.gemini_vision import analyze_gemini

        return await analyze_gemini(image_base64, prompt, api_key=settings.google_api_key)

    elif provider == "claude":
        from aemeath_agent.vision.claude_vision import analyze_claude

        return await analyze_claude(image_base64, prompt, api_key=settings.anthropic_api_key)

    elif provider == "ollama":
        from aemeath_agent.vision.ollama_vision import analyze_ollama

        return await analyze_ollama(
            image_base64,
            prompt,
            base_url=settings.ollama_base_url,
            model=settings.ollama_model_name,
        )

    elif provider == "hybrid":
        from aemeath_agent.vision.hybrid_vision import analyze_hybrid

        return await analyze_hybrid(
            image_base64,
            prompt,
            settings=settings,
        )

    else:
        raise ValueError(f"Unknown vision provider: {provider}")

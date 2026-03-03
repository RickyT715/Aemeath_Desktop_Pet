"""Tests for vision provider dispatcher."""

import pytest

from aemeath_agent.config import Settings
from aemeath_agent.vision.analyzer import analyze


@pytest.mark.asyncio
async def test_analyze_unknown_provider_raises():
    """Unknown provider should raise ValueError."""
    settings = Settings(_env_file=None)  # type: ignore[call-arg]
    with pytest.raises(ValueError, match="Unknown vision provider"):
        await analyze(
            image_base64="fake",
            prompt="test",
            provider="nonexistent",
            settings=settings,
        )

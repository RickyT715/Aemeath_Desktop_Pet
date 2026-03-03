"""Tests for the WPF bridge client."""

import pytest

from aemeath_agent.bridge.wpf_client import WpfBridgeClient


def test_client_default_base_url():
    client = WpfBridgeClient()
    assert "18901" in client.base_url


def test_client_custom_base_url():
    client = WpfBridgeClient(base_url="http://localhost:9999")
    assert "9999" in client.base_url


@pytest.mark.asyncio
async def test_get_stats_connection_refused():
    """get_stats should raise when WPF app is not running."""
    client = WpfBridgeClient(base_url="http://localhost:19999")
    with pytest.raises(Exception):
        await client.get_stats()


@pytest.mark.asyncio
async def test_health_check_returns_false_when_offline():
    """health_check should return False when WPF app is not running."""
    client = WpfBridgeClient(base_url="http://localhost:19999")
    result = await client.health_check()
    assert result is False

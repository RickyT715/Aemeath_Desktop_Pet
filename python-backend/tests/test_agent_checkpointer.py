"""Tests for the SQLite checkpointer factory (agent/checkpointer.py)."""

import sys
from types import ModuleType
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


# Mock the optional langgraph.checkpoint.sqlite package if not installed.
def _ensure_checkpoint_mock():
    key = "langgraph.checkpoint.sqlite"
    key_aio = "langgraph.checkpoint.sqlite.aio"
    if key not in sys.modules:
        fake_sqlite = ModuleType(key)
        fake_aio = ModuleType(key_aio)
        fake_aio.AsyncSqliteSaver = MagicMock(name="AsyncSqliteSaver")
        fake_sqlite.aio = fake_aio
        sys.modules[key] = fake_sqlite
        sys.modules[key_aio] = fake_aio


_ensure_checkpoint_mock()


@pytest.mark.asyncio
async def test_parent_dirs_created(tmp_path):
    """Verify that parent directories are created if they don't exist."""
    nested = tmp_path / "a" / "b" / "c" / "agent.db"

    fake_saver = MagicMock()
    fake_saver.setup = AsyncMock()

    with patch(
        "aemeath_agent.agent.checkpointer.AsyncSqliteSaver"
    ) as mock_cls:
        mock_cls.from_conn_string.return_value = fake_saver

        from aemeath_agent.agent.checkpointer import create_checkpointer

        await create_checkpointer(str(nested))

    assert nested.parent.exists()


@pytest.mark.asyncio
async def test_returns_async_sqlite_saver(tmp_path):
    """Verify the returned object is the AsyncSqliteSaver from from_conn_string."""
    db_path = str(tmp_path / "test.db")
    fake_saver = MagicMock(name="saver")
    fake_saver.setup = AsyncMock()

    with patch(
        "aemeath_agent.agent.checkpointer.AsyncSqliteSaver"
    ) as mock_cls:
        mock_cls.from_conn_string.return_value = fake_saver

        from aemeath_agent.agent.checkpointer import create_checkpointer

        result = await create_checkpointer(db_path)

    assert result is fake_saver
    mock_cls.from_conn_string.assert_called_once_with(db_path)


@pytest.mark.asyncio
async def test_setup_called(tmp_path):
    """Verify checkpointer.setup() is awaited after creation."""
    db_path = str(tmp_path / "test.db")
    fake_saver = MagicMock()
    fake_saver.setup = AsyncMock()

    with patch(
        "aemeath_agent.agent.checkpointer.AsyncSqliteSaver"
    ) as mock_cls:
        mock_cls.from_conn_string.return_value = fake_saver

        from aemeath_agent.agent.checkpointer import create_checkpointer

        await create_checkpointer(db_path)

    fake_saver.setup.assert_awaited_once()

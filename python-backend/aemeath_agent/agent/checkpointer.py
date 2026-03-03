"""SQLite checkpointer factory for LangGraph agent persistence."""

import os
from pathlib import Path

from langgraph.checkpoint.sqlite.aio import AsyncSqliteSaver


async def create_checkpointer(db_path: str) -> AsyncSqliteSaver:
    """Create an AsyncSqliteSaver that persists agent conversation state.

    Args:
        db_path: Path to the SQLite database file.
                 Parent directories are created if they don't exist.

    Returns:
        An initialized AsyncSqliteSaver ready for use with a LangGraph agent.
    """
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    checkpointer = AsyncSqliteSaver.from_conn_string(db_path)
    await checkpointer.setup()
    return checkpointer

"""Todo list management tool with SQLite persistence."""

import json
import logging
import sqlite3
from datetime import datetime
from pathlib import Path

from langchain_core.tools import tool

logger = logging.getLogger(__name__)

_db_path: str = "data/todos.db"


def configure(db_path: str = "data/todos.db") -> None:
    """Set the todo database path."""
    global _db_path
    _db_path = db_path


def _get_connection() -> sqlite3.Connection:
    Path(_db_path).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(_db_path)
    conn.row_factory = sqlite3.Row
    conn.execute("""
        CREATE TABLE IF NOT EXISTS todos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task TEXT NOT NULL,
            due_date TEXT DEFAULT '',
            completed INTEGER DEFAULT 0,
            created_at TEXT DEFAULT (datetime('now'))
        )
    """)
    conn.commit()
    return conn


@tool
def manage_todo(action: str, task: str = "", task_id: int = 0, due_date: str = "") -> str:
    """Manage the user's todo list. Actions: 'add', 'complete', 'delete', 'list'.

    Use when the user wants to track tasks, set reminders, or manage their schedule.

    Args:
        action: One of 'add', 'complete', 'delete', 'list'.
        task: Task description (required for 'add').
        task_id: Task ID (required for 'complete' and 'delete').
        due_date: Optional due date in YYYY-MM-DD format (for 'add').
    """
    try:
        conn = _get_connection()

        if action == "add":
            if not task:
                return json.dumps({"status": "error", "message": "Task description is required."})
            conn.execute(
                "INSERT INTO todos (task, due_date) VALUES (?, ?)",
                (task, due_date),
            )
            conn.commit()
            return json.dumps({"status": "success", "message": f"Added task: {task}"})

        elif action == "complete":
            if task_id <= 0:
                return json.dumps({"status": "error", "message": "Valid task_id is required."})
            cursor = conn.execute(
                "UPDATE todos SET completed = 1 WHERE id = ?", (task_id,)
            )
            conn.commit()
            if cursor.rowcount == 0:
                return json.dumps({"status": "error", "message": f"Task {task_id} not found."})
            return json.dumps({"status": "success", "message": f"Completed task {task_id}."})

        elif action == "delete":
            if task_id <= 0:
                return json.dumps({"status": "error", "message": "Valid task_id is required."})
            cursor = conn.execute("DELETE FROM todos WHERE id = ?", (task_id,))
            conn.commit()
            if cursor.rowcount == 0:
                return json.dumps({"status": "error", "message": f"Task {task_id} not found."})
            return json.dumps({"status": "success", "message": f"Deleted task {task_id}."})

        elif action == "list":
            rows = conn.execute(
                "SELECT id, task, due_date, completed, created_at FROM todos ORDER BY completed, id"
            ).fetchall()
            tasks = [
                {
                    "id": r["id"],
                    "task": r["task"],
                    "due_date": r["due_date"],
                    "completed": bool(r["completed"]),
                    "created_at": r["created_at"],
                }
                for r in rows
            ]
            return json.dumps({"status": "success", "tasks": tasks})

        else:
            return json.dumps({"status": "error", "message": f"Unknown action: {action}"})

    except Exception as e:
        logger.exception("Todo tool failed")
        return json.dumps({"status": "error", "message": str(e)})
    finally:
        if "conn" in locals():
            conn.close()

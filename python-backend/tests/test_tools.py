"""Tests for agent tools."""

import json
from unittest.mock import patch


def test_system_info_returns_json():
    from aemeath_agent.tools.system_info import get_system_info

    result = get_system_info.invoke({})
    data = json.loads(result)
    assert data["status"] == "success"
    assert "data" in data
    info = data["data"]
    assert "os" in info
    assert "cpu_percent" in info
    assert "memory_total_gb" in info
    assert "memory_used_percent" in info
    assert "disk_total_gb" in info


def test_todo_add_and_list(tmp_path):
    """Test todo tool CRUD operations with a temp database."""
    import aemeath_agent.tools.todo as todo_mod

    # Configure with temp path
    db_path = str(tmp_path / "test_todos.db")
    todo_mod.configure(db_path)

    # Add a task
    result = todo_mod.manage_todo.invoke({"action": "add", "task": "Buy groceries"})
    data = json.loads(result)
    assert data["status"] == "success"

    # List tasks
    result = todo_mod.manage_todo.invoke({"action": "list"})
    data = json.loads(result)
    assert data["status"] == "success"
    assert len(data["tasks"]) >= 1
    assert any("Buy groceries" in str(t) for t in data["tasks"])


def test_todo_complete(tmp_path):
    """Test completing a todo task."""
    import aemeath_agent.tools.todo as todo_mod

    db_path = str(tmp_path / "test_todos.db")
    todo_mod.configure(db_path)

    # Add then complete
    result = todo_mod.manage_todo.invoke({"action": "add", "task": "Test task"})
    data = json.loads(result)
    task_id = 1  # First inserted task gets id=1

    result = todo_mod.manage_todo.invoke({"action": "complete", "task_id": task_id})
    data = json.loads(result)
    assert data["status"] == "success"

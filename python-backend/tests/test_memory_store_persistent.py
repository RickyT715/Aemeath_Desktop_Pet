"""Tests for the JSON-persistent memory store and memory blocks."""

import json
import tempfile
from pathlib import Path

import pytest

from aemeath_agent.agent.memory_store import (
    JsonPersistentStore,
    MemoryBlocks,
    NAMESPACE_FACTS,
    NAMESPACE_EPISODES,
    NAMESPACE_PREFERENCES,
    _DEFAULT_USER_BLOCK,
)


class TestJsonPersistentStore:
    """Tests for JsonPersistentStore — persistent InMemoryStore subclass."""

    def test_creates_file_on_first_put(self, tmp_path):
        json_path = tmp_path / "store.json"
        store = JsonPersistentStore(json_path)

        assert not json_path.exists()  # No file until first write

        store.put(NAMESPACE_FACTS, "key1", {"content": "test"})

        assert json_path.exists()

    def test_put_and_search_work(self, tmp_path):
        store = JsonPersistentStore(tmp_path / "store.json")
        store.put(NAMESPACE_FACTS, "user_name", {"content": "Ricky"})

        items = store.search(NAMESPACE_FACTS)
        assert len(items) == 1
        assert items[0].value["content"] == "Ricky"
        assert items[0].key == "user_name"

    def test_put_overwrites_existing_key(self, tmp_path):
        store = JsonPersistentStore(tmp_path / "store.json")
        store.put(NAMESPACE_FACTS, "name", {"content": "Alice"})
        store.put(NAMESPACE_FACTS, "name", {"content": "Ricky"})

        items = store.search(NAMESPACE_FACTS)
        assert len(items) == 1
        assert items[0].value["content"] == "Ricky"

    def test_multiple_namespaces(self, tmp_path):
        store = JsonPersistentStore(tmp_path / "store.json")
        store.put(NAMESPACE_FACTS, "fact1", {"content": "User likes Python"})
        store.put(NAMESPACE_EPISODES, "ep1", {"content": "Talked about exam"})
        store.put(NAMESPACE_PREFERENCES, "pref1", {"content": "Dark mode"})

        assert len(store.search(NAMESPACE_FACTS)) == 1
        assert len(store.search(NAMESPACE_EPISODES)) == 1
        assert len(store.search(NAMESPACE_PREFERENCES)) == 1

    def test_delete_removes_item(self, tmp_path):
        store = JsonPersistentStore(tmp_path / "store.json")
        store.put(NAMESPACE_FACTS, "to_delete", {"content": "temporary"})
        assert len(store.search(NAMESPACE_FACTS)) == 1

        store.delete(NAMESPACE_FACTS, "to_delete")
        assert len(store.search(NAMESPACE_FACTS)) == 0

    def test_persistence_across_instances(self, tmp_path):
        json_path = tmp_path / "store.json"

        # Write with first instance
        store1 = JsonPersistentStore(json_path)
        store1.put(NAMESPACE_FACTS, "name", {"content": "Ricky"})
        store1.put(NAMESPACE_PREFERENCES, "mode", {"content": "dark"})

        # Read with second instance
        store2 = JsonPersistentStore(json_path)
        facts = store2.search(NAMESPACE_FACTS)
        prefs = store2.search(NAMESPACE_PREFERENCES)

        assert len(facts) == 1
        assert facts[0].value["content"] == "Ricky"
        assert len(prefs) == 1
        assert prefs[0].value["content"] == "dark"

    def test_handles_empty_file(self, tmp_path):
        json_path = tmp_path / "store.json"
        json_path.write_text("")

        # Should not crash, starts fresh
        store = JsonPersistentStore(json_path)
        assert len(store.search(NAMESPACE_FACTS)) == 0

    def test_handles_corrupt_json(self, tmp_path):
        json_path = tmp_path / "store.json"
        json_path.write_text("{ broken json!!!")

        # Should not crash, starts fresh
        store = JsonPersistentStore(json_path)
        assert len(store.search(NAMESPACE_FACTS)) == 0

    def test_handles_missing_file(self, tmp_path):
        json_path = tmp_path / "store.json"
        # File doesn't exist
        store = JsonPersistentStore(json_path)
        assert len(store.search(NAMESPACE_FACTS)) == 0

    def test_creates_parent_directories(self, tmp_path):
        json_path = tmp_path / "sub" / "dir" / "store.json"
        store = JsonPersistentStore(json_path)
        store.put(NAMESPACE_FACTS, "test", {"content": "value"})
        assert json_path.exists()

    def test_json_file_format(self, tmp_path):
        json_path = tmp_path / "store.json"
        store = JsonPersistentStore(json_path)
        store.put(NAMESPACE_FACTS, "name", {"content": "Ricky"})

        raw = json.loads(json_path.read_text(encoding="utf-8"))
        assert "memory::facts" in raw
        assert "name" in raw["memory::facts"]
        entry = raw["memory::facts"]["name"]
        assert entry["value"]["content"] == "Ricky"
        assert "created_at" in entry
        assert "updated_at" in entry

    def test_delete_flushes_to_disk(self, tmp_path):
        json_path = tmp_path / "store.json"
        store = JsonPersistentStore(json_path)
        store.put(NAMESPACE_FACTS, "to_delete", {"content": "temp"})
        store.delete(NAMESPACE_FACTS, "to_delete")

        # Verify the file no longer has the key
        raw = json.loads(json_path.read_text(encoding="utf-8"))
        assert "to_delete" not in raw.get("memory::facts", {})


class TestMemoryBlocks:
    """Tests for MemoryBlocks — key-value block store for MemGPT-style USER BLOCK."""

    def test_default_user_block(self, tmp_path):
        mb = MemoryBlocks(tmp_path / "blocks.json")
        user_block = mb.get("user")
        assert user_block == _DEFAULT_USER_BLOCK

    def test_put_and_get(self, tmp_path):
        mb = MemoryBlocks(tmp_path / "blocks.json")
        mb.put("user", "Name: Ricky. Occupation: CS student.")
        assert mb.get("user") == "Name: Ricky. Occupation: CS student."

    def test_get_nonexistent_block_returns_empty(self, tmp_path):
        mb = MemoryBlocks(tmp_path / "blocks.json")
        assert mb.get("nonexistent") == ""

    def test_get_all(self, tmp_path):
        mb = MemoryBlocks(tmp_path / "blocks.json")
        mb.put("user", "test user block")
        mb.put("custom", "custom block")

        all_blocks = mb.get_all()
        assert "user" in all_blocks
        assert "custom" in all_blocks
        assert all_blocks["user"] == "test user block"

    def test_persistence_across_instances(self, tmp_path):
        json_path = tmp_path / "blocks.json"

        mb1 = MemoryBlocks(json_path)
        mb1.put("user", "Updated user info")

        mb2 = MemoryBlocks(json_path)
        assert mb2.get("user") == "Updated user info"

    def test_creates_file_on_first_init(self, tmp_path):
        json_path = tmp_path / "blocks.json"
        assert not json_path.exists()

        mb = MemoryBlocks(json_path)
        assert json_path.exists()

    def test_handles_corrupt_json(self, tmp_path):
        json_path = tmp_path / "blocks.json"
        json_path.write_text("{ broken json!!!")

        mb = MemoryBlocks(json_path)
        assert mb.get("user") == _DEFAULT_USER_BLOCK

    def test_creates_parent_directories(self, tmp_path):
        json_path = tmp_path / "sub" / "dir" / "blocks.json"
        mb = MemoryBlocks(json_path)
        mb.put("test", "value")
        assert json_path.exists()

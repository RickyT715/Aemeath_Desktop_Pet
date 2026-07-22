"""Long-term memory store for cross-session knowledge about the user.

Wraps LangGraph's InMemoryStore with JSON file persistence so that
memories survive backend restarts. This is a drop-in replacement:
the store is still an InMemoryStore (compatible with create_react_agent),
but every mutation is flushed to disk.
"""

import json
import logging
import os
from datetime import datetime
from pathlib import Path
from typing import Any, Literal

from langgraph.store.base import Item
from langgraph.store.memory import InMemoryStore

logger = logging.getLogger(__name__)

# Memory namespaces
NAMESPACE_FACTS = ("memory", "facts")  # Facts about the user
NAMESPACE_EPISODES = ("memory", "episodes")  # Memorable interactions
NAMESPACE_PREFERENCES = ("memory", "preferences")  # User preferences


def _default_memory_dir() -> Path:
    """Return the default directory for memory JSON files."""
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if local_app_data:
        return Path(local_app_data) / "AemeathDesktopPet"
    return Path.home() / ".aemeath"


def _default_store_path() -> Path:
    return _default_memory_dir() / "memory_store.json"


def _default_blocks_path() -> Path:
    return _default_memory_dir() / "memory_blocks.json"


# ---------------------------------------------------------------------------
# Persistent JSON-backed InMemoryStore
# ---------------------------------------------------------------------------

class JsonPersistentStore(InMemoryStore):
    """InMemoryStore subclass that persists data to a JSON file.

    On creation, loads existing data from ``json_path``. After every
    ``put`` or ``delete`` call the full state is flushed back to disk.

    Because this *is* an InMemoryStore, it can be passed directly to
    ``create_react_agent(..., store=store)`` with zero compatibility issues.
    """

    def __init__(self, json_path: str | Path | None = None) -> None:
        super().__init__()
        self._json_path = Path(json_path) if json_path else _default_store_path()
        self._json_path.parent.mkdir(parents=True, exist_ok=True)
        self._load()

    # -- persistence helpers ------------------------------------------------

    def _load(self) -> None:
        """Load previously persisted items into the in-memory store."""
        if not self._json_path.exists():
            logger.info("No existing memory file at %s — starting fresh", self._json_path)
            return

        try:
            raw = json.loads(self._json_path.read_text(encoding="utf-8"))
            count = 0
            for ns_key, items in raw.items():
                namespace = tuple(ns_key.split("::"))
                for key, entry in items.items():
                    created = datetime.fromisoformat(entry["created_at"])
                    updated = datetime.fromisoformat(entry["updated_at"])
                    self._data[namespace][key] = Item(
                        value=entry["value"],
                        key=key,
                        namespace=namespace,
                        created_at=created,
                        updated_at=updated,
                    )
                    count += 1
            logger.info("Loaded %d memory items from %s", count, self._json_path)
        except Exception:
            logger.exception("Failed to load memory store from %s", self._json_path)

    def _flush(self) -> None:
        """Write the full in-memory state to the JSON file."""
        try:
            serializable: dict[str, dict[str, Any]] = {}
            for namespace, items in self._data.items():
                ns_key = "::".join(namespace)
                serializable[ns_key] = {}
                for key, item in items.items():
                    serializable[ns_key][key] = {
                        "value": item.value,
                        "created_at": item.created_at.isoformat(),
                        "updated_at": item.updated_at.isoformat(),
                    }
            self._json_path.write_text(
                json.dumps(serializable, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
        except Exception:
            logger.exception("Failed to flush memory store to %s", self._json_path)

    # -- override mutation methods to auto-flush ----------------------------

    def put(  # type: ignore[override]
        self,
        namespace: tuple[str, ...],
        key: str,
        value: dict[str, Any],
        index: Literal[False] | list[str] | None = None,
        **kwargs: Any,
    ) -> None:
        super().put(namespace, key, value, index, **kwargs)
        self._flush()

    def delete(self, namespace: tuple[str, ...], key: str) -> None:
        super().delete(namespace, key)
        self._flush()


# ---------------------------------------------------------------------------
# Memory Blocks — MemGPT-style self-editing user summary
# ---------------------------------------------------------------------------

_DEFAULT_USER_BLOCK = (
    "No information about the user yet. "
    "As you learn things, use update_user_block to save them here."
)


class MemoryBlocks:
    """Simple key-value block store persisted to JSON.

    Used for the MemGPT-inspired USER BLOCK that the agent can rewrite.
    Each block is a named text string injected into the system prompt.
    """

    def __init__(self, json_path: str | Path | None = None) -> None:
        self._json_path = Path(json_path) if json_path else _default_blocks_path()
        self._json_path.parent.mkdir(parents=True, exist_ok=True)
        self._blocks: dict[str, str] = {}
        self._load()

    def _load(self) -> None:
        if not self._json_path.exists():
            self._blocks = {"user": _DEFAULT_USER_BLOCK}
            self._flush()
            return
        try:
            self._blocks = json.loads(self._json_path.read_text(encoding="utf-8"))
            logger.info("Loaded %d memory blocks from %s", len(self._blocks), self._json_path)
        except Exception:
            logger.exception("Failed to load memory blocks from %s", self._json_path)
            self._blocks = {"user": _DEFAULT_USER_BLOCK}

    def _flush(self) -> None:
        try:
            self._json_path.write_text(
                json.dumps(self._blocks, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
        except Exception:
            logger.exception("Failed to flush memory blocks to %s", self._json_path)

    def get(self, block_name: str) -> str:
        """Read a named block (returns empty string if not found)."""
        return self._blocks.get(block_name, "")

    def put(self, block_name: str, content: str) -> None:
        """Write a named block and persist to disk."""
        self._blocks[block_name] = content
        self._flush()

    def get_all(self) -> dict[str, str]:
        """Return a copy of all blocks."""
        return dict(self._blocks)


# ---------------------------------------------------------------------------
# Singletons
# ---------------------------------------------------------------------------

_store: JsonPersistentStore | None = None
_blocks: MemoryBlocks | None = None


def get_memory_store(json_path: str | Path | None = None) -> JsonPersistentStore:
    """Get or create the singleton persistent memory store.

    Uses a JSON-backed InMemoryStore with semantic namespaces:
    - facts: things the agent learns about the user (name, occupation, etc.)
    - episodes: memorable interactions worth recalling
    - preferences: user preferences (communication style, interests, etc.)

    Args:
        json_path: Optional override for the JSON file location.
                   Only used on first call (when creating the store).
    """
    global _store
    if _store is None:
        _store = JsonPersistentStore(json_path)
    return _store


def get_memory_blocks(json_path: str | Path | None = None) -> MemoryBlocks:
    """Get or create the singleton MemoryBlocks store.

    Args:
        json_path: Optional override for the JSON file location.
                   Only used on first call (when creating the store).
    """
    global _blocks
    if _blocks is None:
        _blocks = MemoryBlocks(json_path)
    return _blocks

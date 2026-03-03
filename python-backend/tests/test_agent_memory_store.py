"""Tests for the long-term memory store (agent/memory_store.py)."""

import importlib


def _reload_module():
    """Reload memory_store to reset the singleton _store."""
    import aemeath_agent.agent.memory_store as mod
    mod._store = None
    return mod


def test_returns_in_memory_store():
    mod = _reload_module()
    store = mod.get_memory_store()
    from langgraph.store.memory import InMemoryStore
    assert isinstance(store, InMemoryStore)


def test_singleton_returns_same_instance():
    mod = _reload_module()
    store1 = mod.get_memory_store()
    store2 = mod.get_memory_store()
    assert store1 is store2


def test_reset_creates_new_instance():
    mod = _reload_module()
    store1 = mod.get_memory_store()
    mod._store = None
    store2 = mod.get_memory_store()
    assert store1 is not store2


def test_namespace_facts_constant():
    from aemeath_agent.agent.memory_store import NAMESPACE_FACTS
    assert NAMESPACE_FACTS == ("memory", "facts")


def test_namespace_episodes_constant():
    from aemeath_agent.agent.memory_store import NAMESPACE_EPISODES
    assert NAMESPACE_EPISODES == ("memory", "episodes")


def test_namespace_preferences_constant():
    from aemeath_agent.agent.memory_store import NAMESPACE_PREFERENCES
    assert NAMESPACE_PREFERENCES == ("memory", "preferences")

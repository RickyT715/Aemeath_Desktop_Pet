"""Long-term memory store for cross-session knowledge about the user."""

from langgraph.store.memory import InMemoryStore

# Memory namespaces
NAMESPACE_FACTS = ("memory", "facts")         # Facts about the user
NAMESPACE_EPISODES = ("memory", "episodes")   # Memorable interactions
NAMESPACE_PREFERENCES = ("memory", "preferences")  # User preferences

_store: InMemoryStore | None = None


def get_memory_store() -> InMemoryStore:
    """Get or create the singleton long-term memory store.

    Uses LangGraph's InMemoryStore with semantic namespaces:
    - facts: things the agent learns about the user (name, occupation, etc.)
    - episodes: memorable interactions worth recalling
    - preferences: user preferences (communication style, interests, etc.)
    """
    global _store
    if _store is None:
        _store = InMemoryStore()
    return _store

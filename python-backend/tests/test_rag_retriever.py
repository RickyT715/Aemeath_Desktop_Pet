"""Tests for the hybrid retriever (rag/retriever.py)."""

from unittest.mock import MagicMock, patch


def _reset_retriever():
    """Reset the singleton _retriever so each test starts clean."""
    import aemeath_agent.rag.retriever as mod
    mod._retriever = None
    return mod


def test_none_vectorstore_returns_none():
    """If get_vectorstore returns None, get_retriever returns None."""
    mod = _reset_retriever()

    with patch.object(mod, "get_vectorstore", return_value=None):
        result = mod.get_retriever()

    assert result is None


def test_reset_clears_singleton():
    """reset_retriever() sets _retriever back to None."""
    mod = _reset_retriever()

    # Manually set a fake retriever
    mod._retriever = MagicMock(name="fake_retriever")
    assert mod._retriever is not None

    mod.reset_retriever()
    assert mod._retriever is None


def test_empty_docs_returns_vector_only_retriever():
    """When vectorstore has no documents, return the vector retriever directly."""
    mod = _reset_retriever()

    fake_vectorstore = MagicMock()
    fake_vector_retriever = MagicMock(name="vector_retriever")
    fake_vectorstore.as_retriever.return_value = fake_vector_retriever
    # Return empty documents
    fake_vectorstore.get.return_value = {"documents": []}

    with patch.object(mod, "get_vectorstore", return_value=fake_vectorstore):
        result = mod.get_retriever()

    assert result is fake_vector_retriever


def test_singleton_behavior():
    """Second call returns cached retriever without rebuilding."""
    mod = _reset_retriever()

    fake_vectorstore = MagicMock()
    fake_retriever = MagicMock(name="vector_retriever")
    fake_vectorstore.as_retriever.return_value = fake_retriever
    fake_vectorstore.get.return_value = {"documents": []}

    with patch.object(mod, "get_vectorstore", return_value=fake_vectorstore):
        first = mod.get_retriever()
        second = mod.get_retriever()

    assert first is second
    # as_retriever should only be called once (singleton)
    fake_vectorstore.as_retriever.assert_called_once()

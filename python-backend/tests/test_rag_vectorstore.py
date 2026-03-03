"""Tests for the ChromaDB vector store factory (rag/vectorstore.py)."""

from unittest.mock import MagicMock, patch


def _reset_vectorstore():
    """Reset the singleton _vectorstore so each test starts clean."""
    import aemeath_agent.rag.vectorstore as mod
    mod._vectorstore = None
    return mod


def test_no_google_key_falls_back_to_huggingface(tmp_path):
    """When google_api_key is empty and embedding_model is 'gemini', use HuggingFace."""
    mod = _reset_vectorstore()

    fake_settings = MagicMock()
    fake_settings.google_api_key = ""
    fake_settings.chromadb_path = str(tmp_path / "chroma")
    fake_settings.embedding_model = "gemini"

    fake_hf = MagicMock(name="hf_embeddings")
    fake_chroma = MagicMock(name="chroma_store")

    with (
        patch.object(mod, "get_settings", return_value=fake_settings),
        patch(
            "langchain_community.embeddings.HuggingFaceEmbeddings",
            return_value=fake_hf,
        ) as mock_hf,
        patch.object(
            mod, "Chroma",
            return_value=fake_chroma,
        ),
    ):
        result = mod.get_vectorstore()

    mock_hf.assert_called_once_with(model_name="all-MiniLM-L6-v2")
    assert result is fake_chroma


def test_local_model_selection(tmp_path):
    """When embedding_model is 'local', use HuggingFace directly."""
    mod = _reset_vectorstore()

    fake_settings = MagicMock()
    fake_settings.google_api_key = "some-key"
    fake_settings.chromadb_path = str(tmp_path / "chroma")
    fake_settings.embedding_model = "local"  # not "gemini"

    fake_hf = MagicMock()
    fake_chroma = MagicMock()

    with (
        patch.object(mod, "get_settings", return_value=fake_settings),
        patch(
            "langchain_community.embeddings.HuggingFaceEmbeddings",
            return_value=fake_hf,
        ) as mock_hf,
        patch.object(
            mod, "Chroma",
            return_value=fake_chroma,
        ),
    ):
        result = mod.get_vectorstore()

    mock_hf.assert_called_once()
    assert result is fake_chroma


def test_init_failure_returns_none(tmp_path):
    """If embeddings initialization fails, return None."""
    mod = _reset_vectorstore()

    fake_settings = MagicMock()
    fake_settings.google_api_key = ""
    fake_settings.chromadb_path = str(tmp_path / "chroma")
    fake_settings.embedding_model = "local"

    with (
        patch.object(mod, "get_settings", return_value=fake_settings),
        patch(
            "langchain_community.embeddings.HuggingFaceEmbeddings",
            side_effect=RuntimeError("model download failed"),
        ),
    ):
        result = mod.get_vectorstore()

    assert result is None


def test_persist_dir_created(tmp_path):
    """Verify chromadb_path directory is created."""
    mod = _reset_vectorstore()

    chroma_dir = tmp_path / "nested" / "chroma"
    fake_settings = MagicMock()
    fake_settings.google_api_key = ""
    fake_settings.chromadb_path = str(chroma_dir)
    fake_settings.embedding_model = "local"

    with (
        patch.object(mod, "get_settings", return_value=fake_settings),
        patch(
            "langchain_community.embeddings.HuggingFaceEmbeddings",
            return_value=MagicMock(),
        ),
        patch.object(
            mod, "Chroma",
            return_value=MagicMock(),
        ),
    ):
        mod.get_vectorstore()

    assert chroma_dir.exists()

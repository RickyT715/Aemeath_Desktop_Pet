"""Tests for RAG ingestion and chunking."""

import sys
from types import ModuleType
from unittest.mock import MagicMock, patch

import pytest

# The source uses `from langchain.text_splitter import RecursiveCharacterTextSplitter`
# but the installed package exposes it via `langchain_text_splitters`.
# Shim the old import path if it doesn't exist.
if "langchain.text_splitter" not in sys.modules:
    try:
        from langchain_text_splitters import RecursiveCharacterTextSplitter as _RTS
        fake_mod = ModuleType("langchain.text_splitter")
        fake_mod.RecursiveCharacterTextSplitter = _RTS  # type: ignore[attr-defined]
        sys.modules["langchain.text_splitter"] = fake_mod
    except ImportError:
        pass

# Also shim langgraph.checkpoint.sqlite if missing (ingestion imports vectorstore chain)
if "langgraph.checkpoint.sqlite" not in sys.modules:
    _fake_sqlite = ModuleType("langgraph.checkpoint.sqlite")
    _fake_aio = ModuleType("langgraph.checkpoint.sqlite.aio")
    _fake_aio.AsyncSqliteSaver = MagicMock(name="AsyncSqliteSaver")  # type: ignore[attr-defined]
    _fake_sqlite.aio = _fake_aio  # type: ignore[attr-defined]
    sys.modules["langgraph.checkpoint.sqlite"] = _fake_sqlite
    sys.modules["langgraph.checkpoint.sqlite.aio"] = _fake_aio

from aemeath_agent.rag.ingestion import _splitter, _LOADER_MAP


def test_splitter_has_correct_chunk_size():
    assert _splitter._chunk_size == 1000


def test_splitter_has_correct_overlap():
    assert _splitter._chunk_overlap == 200


def test_splitter_splits_text():
    text = "This is a test sentence. " * 80  # ~2000 chars
    chunks = _splitter.split_text(text)
    assert len(chunks) > 1


def test_supported_formats():
    assert ".pdf" in _LOADER_MAP
    assert ".docx" in _LOADER_MAP
    assert ".txt" in _LOADER_MAP
    assert ".md" in _LOADER_MAP
    assert ".py" in _LOADER_MAP


# ---- _load_text with real .txt file ------------------------------------------

def test_load_text_with_real_file(tmp_path):
    """_load_text should load a real .txt file and return Document(s)."""
    from aemeath_agent.rag.ingestion import _load_text

    txt_file = tmp_path / "sample.txt"
    txt_file.write_text("Hello world! This is a test document.", encoding="utf-8")

    docs = _load_text(str(txt_file))
    assert len(docs) >= 1
    assert "Hello world" in docs[0].page_content


# ---- _load_file with unsupported extension -----------------------------------

def test_unsupported_extension_returns_empty():
    """_load_file returns [] for unsupported file types."""
    from aemeath_agent.rag.ingestion import _load_file

    result = _load_file("somefile.xyz")
    assert result == []


# ---- ingest_documents with empty list ----------------------------------------

@pytest.mark.asyncio
async def test_ingest_empty_list_returns_zero():
    """ingest_documents([]) should return 0 without touching vectorstore."""
    from aemeath_agent.rag.ingestion import ingest_documents

    result = await ingest_documents([])
    assert result == 0


# ---- ingest_directory with non-existent dir -----------------------------------

@pytest.mark.asyncio
async def test_ingest_nonexistent_dir_returns_zero():
    """ingest_directory with a path that doesn't exist returns 0."""
    from aemeath_agent.rag.ingestion import ingest_directory

    result = await ingest_directory("/nonexistent/path/definitely/not/here")
    assert result == 0


# ---- ingest_directory with dir containing no supported files ------------------

@pytest.mark.asyncio
async def test_ingest_dir_no_supported_files(tmp_path):
    """A directory with only unsupported files returns 0 chunks."""
    from aemeath_agent.rag.ingestion import ingest_directory

    (tmp_path / "image.png").write_bytes(b"\x89PNG")
    (tmp_path / "video.mp4").write_bytes(b"\x00")

    result = await ingest_directory(str(tmp_path))
    assert result == 0


# ---- ingest_documents with real txt file and mocked vectorstore --------------

@pytest.mark.asyncio
async def test_ingest_real_txt_file(tmp_path):
    """Ingest a real .txt file with mocked vectorstore."""
    txt_file = tmp_path / "doc.txt"
    txt_file.write_text("Some content for ingestion testing.", encoding="utf-8")

    fake_vs = MagicMock()
    fake_vs.add_documents = MagicMock()

    with patch("aemeath_agent.rag.vectorstore.get_vectorstore", return_value=fake_vs):
        from aemeath_agent.rag.ingestion import ingest_documents

        result = await ingest_documents([str(txt_file)])

    assert result >= 1
    fake_vs.add_documents.assert_called_once()


# ---- ingest_documents when vectorstore is None --------------------------------

@pytest.mark.asyncio
async def test_ingest_no_vectorstore_returns_zero(tmp_path):
    """If get_vectorstore() returns None, ingestion returns 0."""
    txt_file = tmp_path / "doc.txt"
    txt_file.write_text("content", encoding="utf-8")

    with patch("aemeath_agent.rag.vectorstore.get_vectorstore", return_value=None):
        from aemeath_agent.rag.ingestion import ingest_documents

        result = await ingest_documents([str(txt_file)])

    assert result == 0

"""Document ingestion pipeline — load, chunk, and store documents."""

import logging
from pathlib import Path

from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

logger = logging.getLogger(__name__)

_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=200,
    separators=["\n\n", "\n", ".", "?", "!", " ", ""],
    length_function=len,
)

# Supported file extensions and their loaders
_LOADER_MAP = {
    ".pdf": "_load_pdf",
    ".docx": "_load_docx",
    ".txt": "_load_text",
    ".md": "_load_text",
    ".py": "_load_text",
    ".json": "_load_text",
    ".csv": "_load_text",
}


def _load_pdf(path: str) -> list[Document]:
    from langchain_community.document_loaders import PyPDFLoader

    loader = PyPDFLoader(path)
    return list(loader.lazy_load())


def _load_docx(path: str) -> list[Document]:
    from langchain_community.document_loaders import Docx2txtLoader

    loader = Docx2txtLoader(path)
    return loader.load()


def _load_text(path: str) -> list[Document]:
    from langchain_community.document_loaders import TextLoader

    loader = TextLoader(path, encoding="utf-8")
    return loader.load()


def _load_file(path: str) -> list[Document]:
    """Load a single file using the appropriate loader."""
    ext = Path(path).suffix.lower()
    loader_name = _LOADER_MAP.get(ext)
    if loader_name is None:
        logger.warning("Unsupported file type: %s", ext)
        return []

    loader_func = globals()[loader_name]
    return loader_func(path)


async def ingest_documents(file_paths: list[str]) -> int:
    """Ingest a list of files into the RAG vector store.

    Args:
        file_paths: List of absolute file paths to ingest.

    Returns:
        Number of chunks stored.
    """
    from aemeath_agent.rag.vectorstore import get_vectorstore

    all_docs: list[Document] = []
    for path in file_paths:
        try:
            docs = _load_file(path)
            all_docs.extend(docs)
            logger.info("Loaded %d pages/docs from %s", len(docs), path)
        except Exception:
            logger.exception("Failed to load %s", path)

    if not all_docs:
        return 0

    chunks = _splitter.split_documents(all_docs)
    logger.info("Split %d documents into %d chunks", len(all_docs), len(chunks))

    vectorstore = get_vectorstore()
    if vectorstore is None:
        logger.error("Vector store not available")
        return 0

    vectorstore.add_documents(chunks)
    logger.info("Stored %d chunks in vector store", len(chunks))
    return len(chunks)


async def ingest_directory(directory: str, glob_pattern: str = "**/*.*") -> int:
    """Ingest all supported files from a directory.

    Args:
        directory: Path to the directory.
        glob_pattern: Glob pattern for file matching.

    Returns:
        Number of chunks stored.
    """
    dir_path = Path(directory)
    if not dir_path.is_dir():
        logger.error("Not a directory: %s", directory)
        return 0

    supported_extensions = set(_LOADER_MAP.keys())
    file_paths = [
        str(p)
        for p in dir_path.glob(glob_pattern)
        if p.is_file() and p.suffix.lower() in supported_extensions
    ]

    if not file_paths:
        logger.info("No supported files found in %s", directory)
        return 0

    logger.info("Found %d supported files in %s", len(file_paths), directory)
    return await ingest_documents(file_paths)

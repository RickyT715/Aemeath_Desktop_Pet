"""RAG ingestion, query, and status endpoints."""

import logging

from fastapi import APIRouter

from aemeath_agent.api.models import (
    RagIngestRequest,
    RagQueryRequest,
    RagQueryResult,
    RagStatusResponse,
)

router = APIRouter(prefix="/rag", tags=["rag"])
logger = logging.getLogger(__name__)

# Initialized lazily when the RAG module is ready
_rag_initialized = False


@router.post("/ingest")
async def ingest_documents(request: RagIngestRequest) -> dict[str, str]:
    """Ingest documents into the RAG vector store."""
    try:
        from aemeath_agent.rag.ingestion import ingest_directory, ingest_documents as _ingest

        if request.is_directory:
            count = await ingest_directory(request.path, glob_pattern=request.glob_pattern)
        else:
            count = await _ingest([request.path])

        # Reset retriever so it rebuilds with new documents
        from aemeath_agent.rag.retriever import reset_retriever

        reset_retriever()

        return {"status": "ok", "documents_ingested": str(count)}
    except Exception:
        logger.exception("RAG ingestion error")
        return {"status": "error", "message": "Ingestion failed."}


@router.post("/query")
async def query_rag(request: RagQueryRequest) -> dict[str, list[RagQueryResult] | str]:
    """Query the RAG store for relevant documents."""
    try:
        from aemeath_agent.rag.retriever import get_retriever

        retriever = get_retriever()
        if retriever is None:
            return {"status": "error", "results": []}

        docs = await retriever.ainvoke(request.query)
        results = [
            RagQueryResult(
                content=doc.page_content,
                source=doc.metadata.get("source", ""),
                score=doc.metadata.get("score", 0.0),
            )
            for doc in docs[: request.top_k]
        ]
        return {"status": "ok", "results": results}
    except Exception:
        logger.exception("RAG query error")
        return {"status": "error", "results": []}


@router.get("/status", response_model=RagStatusResponse)
async def rag_status() -> RagStatusResponse:
    """Return the current status of the RAG store."""
    try:
        from aemeath_agent.rag.vectorstore import get_vectorstore

        vs = get_vectorstore()
        if vs is None:
            return RagStatusResponse(initialized=False)

        collection = vs._collection
        return RagStatusResponse(
            initialized=True,
            document_count=collection.count(),
            collection_name=collection.name,
        )
    except Exception:
        logger.exception("RAG status check error")
        return RagStatusResponse(initialized=False)

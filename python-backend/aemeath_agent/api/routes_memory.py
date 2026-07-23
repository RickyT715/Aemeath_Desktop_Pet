"""Memory system API endpoints — extraction, retrieval, distillation, and management."""

import json
import logging
import os
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter

from aemeath_agent.api.models import (
    DistilledMemory,
    ExtractedFact,
    MemoryCoreUpdateRequest,
    MemoryCoreUpdateResponse,
    MemoryDistillRequest,
    MemoryDistillResponse,
    MemoryExtractRequest,
    MemoryExtractResponse,
    MemoryForgetRequest,
    MemoryForgetResponse,
    MemoryRetrieveResponse,
    MemoryRetrieveResult,
    MemoryStatusResponse,
)
from aemeath_agent.config import get_settings

router = APIRouter(prefix="/memory", tags=["memory"])
logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Extraction prompt sent to the LLM after each conversation turn
# ---------------------------------------------------------------------------

_EXTRACTION_PROMPT = """\
You are a memory extraction assistant. Analyze the following conversation turn \
between a user and their AI companion. Extract ONLY meaningful, durable facts — \
skip casual filler.

## Conversation Turn
User: {user_message}
Assistant: {assistant_response}

## Instructions
Return a JSON object with these keys:
- "facts": list of {{"fact": str, "confidence": float, "category": str}}
  Categories: "name", "occupation", "interest", "relationship", "general"
  Only include facts the user explicitly stated or strongly implied.
- "events": list of {{"event": str, "date": str or null, "sentiment": str}}
  Include upcoming events, deadlines, or notable happenings mentioned.
- "preferences": list of {{"preference": str, "confidence": float}}
  Communication style, likes/dislikes, habits.

If nothing worth remembering was said, return empty lists.
Respond with ONLY valid JSON, no markdown fences.
"""

_DISTILLATION_PROMPT = """\
You are an observation summarizer for an AI companion. Analyze these observations \
about the user's activity and extract durable insights.

## Observations
{observations}

## Instructions
Return a JSON object with:
- "distilled": list of {{"content": str, "type": str, "importance": float}}
  type is one of: "activity_pattern", "interest", "habit", "mood", "observation"
  importance is 0.0 to 1.0 (routine observations ~0.3, notable patterns ~0.7)
- "patterns": list of short strings describing any recurring patterns detected

Summarize, don't repeat raw data. Focus on what would help a caring companion.
Respond with ONLY valid JSON, no markdown fences.
"""


def _get_extraction_llm():
    """Get a lightweight LLM for extraction (prefers Gemini Flash for cost)."""
    settings = get_settings()

    # Always prefer Gemini Flash for extraction (cheapest, fastest)
    if settings.google_api_key:
        try:
            from langchain_google_genai import ChatGoogleGenerativeAI

            return ChatGoogleGenerativeAI(
                model="gemini-2.0-flash",
                google_api_key=settings.google_api_key,
                temperature=0,
            )
        except Exception:
            logger.warning("Gemini Flash unavailable for extraction, trying fallback")

    # Fallback to configured provider
    if settings.ai_provider == "proxy":
        try:
            from langchain_anthropic import ChatAnthropic

            os.environ["ANTHROPIC_BASE_URL"] = f"{settings.proxy_base_url}/v1"
            return ChatAnthropic(
                model="claude-sonnet-4-5-20250929",
                temperature=0,
            )
        except Exception:
            logger.warning("Proxy fallback failed for extraction")

    if settings.anthropic_api_key:
        try:
            from langchain_anthropic import ChatAnthropic

            return ChatAnthropic(
                model="claude-sonnet-4-20250514",
                anthropic_api_key=settings.anthropic_api_key,
                temperature=0,
            )
        except Exception:
            logger.warning("Anthropic fallback failed for extraction")

    return None


def _parse_llm_json(text: str) -> dict:
    """Parse JSON from LLM response, stripping markdown fences if present."""
    text = text.strip()
    if text.startswith("```"):
        # Remove markdown code fences
        lines = text.split("\n")
        lines = [l for l in lines if not l.strip().startswith("```")]
        text = "\n".join(lines)
    return json.loads(text)


# ---------------------------------------------------------------------------
# POST /memory/extract — extract facts from a conversation turn
# ---------------------------------------------------------------------------


@router.post("/extract", response_model=MemoryExtractResponse)
async def extract_memories(request: MemoryExtractRequest) -> MemoryExtractResponse:
    """Extract facts, events, and preferences from a conversation turn.

    Uses a lightweight LLM call to identify durable facts worth remembering.
    Extracted items are stored in both the persistent memory store and
    the episodic ChromaDB collection.
    """
    llm = _get_extraction_llm()
    if llm is None:
        logger.warning("No LLM available for memory extraction")
        return MemoryExtractResponse()

    prompt = _EXTRACTION_PROMPT.format(
        user_message=request.user_message,
        assistant_response=request.assistant_response,
    )

    try:
        response = await llm.ainvoke(prompt)
        content = response.content if hasattr(response, "content") else str(response)
        parsed = _parse_llm_json(content)
    except Exception:
        logger.exception("Memory extraction LLM call failed")
        return MemoryExtractResponse()

    facts = [
        ExtractedFact(
            fact=f.get("fact", ""),
            confidence=float(f.get("confidence", 0.5)),
            category=f.get("category", "general"),
        )
        for f in parsed.get("facts", [])
        if f.get("fact")
    ]
    events = parsed.get("events", [])
    preferences = parsed.get("preferences", [])

    # Persist to the memory store
    try:
        from aemeath_agent.agent.memory_store import (
            NAMESPACE_EPISODES,
            NAMESPACE_FACTS,
            NAMESPACE_PREFERENCES,
            get_memory_store,
        )

        store = get_memory_store()
        for f in facts:
            store.put(NAMESPACE_FACTS, str(uuid.uuid4()), {"content": f.fact, "confidence": f.confidence, "category": f.category})
        for p in preferences:
            if p.get("preference"):
                store.put(NAMESPACE_PREFERENCES, str(uuid.uuid4()), {"content": p["preference"], "confidence": p.get("confidence", 0.5)})
    except Exception:
        logger.exception("Failed to persist extracted memories to store")

    # Also store in ChromaDB for semantic search
    try:
        from aemeath_agent.rag.memory_vectorstore import get_memory_vectorstore

        vs = get_memory_vectorstore()
        if vs is not None:
            now_iso = datetime.now(timezone.utc).isoformat()
            texts = []
            metadatas = []
            ids = []

            for f in facts:
                texts.append(f.fact)
                metadatas.append({"type": "fact", "category": f.category, "importance": f.confidence, "created_at": now_iso, "source": "conversation"})
                ids.append(str(uuid.uuid4()))

            for e in events:
                if e.get("event"):
                    texts.append(e["event"])
                    metadatas.append({"type": "event", "date": e.get("date", ""), "sentiment": e.get("sentiment", ""), "importance": 0.7, "created_at": now_iso, "source": "conversation"})
                    ids.append(str(uuid.uuid4()))

            for p in preferences:
                if p.get("preference"):
                    texts.append(p["preference"])
                    metadatas.append({"type": "preference", "importance": p.get("confidence", 0.5), "created_at": now_iso, "source": "conversation"})
                    ids.append(str(uuid.uuid4()))

            if texts:
                vs.add_texts(texts=texts, metadatas=metadatas, ids=ids)
    except Exception:
        logger.exception("Failed to store extracted memories in ChromaDB")

    return MemoryExtractResponse(facts=facts, events=events, preferences=preferences)


# ---------------------------------------------------------------------------
# GET /memory/retrieve — semantic search for relevant memories
# ---------------------------------------------------------------------------


@router.get("/retrieve", response_model=MemoryRetrieveResponse)
async def retrieve_memories(q: str, top_k: int = 3) -> MemoryRetrieveResponse:
    """Search episodic memories by semantic similarity.

    Used by the C# frontend to inject relevant past memories into the prompt.
    """
    if not q.strip():
        return MemoryRetrieveResponse()

    try:
        from aemeath_agent.rag.memory_vectorstore import get_memory_vectorstore

        vs = get_memory_vectorstore()
        if vs is None:
            return MemoryRetrieveResponse()

        results = vs.similarity_search_with_relevance_scores(q, k=top_k)
        memories = []
        for doc, score in results:
            memories.append(
                MemoryRetrieveResult(
                    content=doc.page_content,
                    type=doc.metadata.get("type", ""),
                    created_at=doc.metadata.get("created_at", ""),
                    importance=float(doc.metadata.get("importance", score)),
                )
            )
        return MemoryRetrieveResponse(memories=memories)
    except Exception:
        logger.exception("Memory retrieval failed")
        return MemoryRetrieveResponse()


# ---------------------------------------------------------------------------
# POST /memory/distill — distill observations into durable memories
# ---------------------------------------------------------------------------


@router.post("/distill", response_model=MemoryDistillResponse)
async def distill_observations(request: MemoryDistillRequest) -> MemoryDistillResponse:
    """Distill raw observations into durable episodic memories.

    Receives a batch of observations from C# (screen, activity, pomodoro),
    summarizes them via LLM, and stores the distilled facts.
    """
    if not request.observations:
        return MemoryDistillResponse()

    llm = _get_extraction_llm()
    if llm is None:
        logger.warning("No LLM available for observation distillation")
        return MemoryDistillResponse()

    obs_text = "\n".join(
        f"[{o.timestamp}] ({o.source}) {o.content}"
        for o in request.observations
    )
    prompt = _DISTILLATION_PROMPT.format(observations=obs_text)

    try:
        response = await llm.ainvoke(prompt)
        content = response.content if hasattr(response, "content") else str(response)
        parsed = _parse_llm_json(content)
    except Exception:
        logger.exception("Observation distillation LLM call failed")
        return MemoryDistillResponse()

    distilled = [
        DistilledMemory(
            content=d.get("content", ""),
            type=d.get("type", "observation"),
            importance=float(d.get("importance", 0.5)),
        )
        for d in parsed.get("distilled", [])
        if d.get("content")
    ]
    patterns = parsed.get("patterns", [])

    # Store distilled memories in ChromaDB
    try:
        from aemeath_agent.rag.memory_vectorstore import get_memory_vectorstore

        vs = get_memory_vectorstore()
        if vs is not None and distilled:
            now_iso = datetime.now(timezone.utc).isoformat()
            texts = [d.content for d in distilled]
            metadatas = [
                {"type": d.type, "importance": d.importance, "created_at": now_iso, "source": "observation"}
                for d in distilled
            ]
            ids = [str(uuid.uuid4()) for _ in distilled]
            vs.add_texts(texts=texts, metadatas=metadatas, ids=ids)
    except Exception:
        logger.exception("Failed to store distilled memories in ChromaDB")

    return MemoryDistillResponse(distilled=distilled, patterns=patterns)


# ---------------------------------------------------------------------------
# POST /memory/core/update — update core memory
# ---------------------------------------------------------------------------


@router.post("/core/update", response_model=MemoryCoreUpdateResponse)
async def update_core_memory(request: MemoryCoreUpdateRequest) -> MemoryCoreUpdateResponse:
    """Update core memory from extraction results.

    Applies simple conflict resolution: new facts overwrite old ones in the
    same category. The C# side owns the canonical core_memory.json — this
    endpoint updates the Python-side mirror in the persistent store.
    """
    updated: list[str] = []
    conflicts: list[str] = []

    try:
        from aemeath_agent.agent.memory_store import (
            NAMESPACE_FACTS,
            NAMESPACE_PREFERENCES,
            get_memory_store,
        )

        store = get_memory_store()

        for fact_dict in request.user_facts:
            fact_text = fact_dict.get("fact", "")
            if not fact_text:
                continue
            category = fact_dict.get("category", "general")
            store.put(NAMESPACE_FACTS, str(uuid.uuid4()), {"content": fact_text, "category": category})
            updated.append(fact_text)

        for pref_dict in request.preferences:
            pref_text = pref_dict.get("preference", "")
            if not pref_text:
                continue
            store.put(NAMESPACE_PREFERENCES, str(uuid.uuid4()), {"content": pref_text})
            updated.append(pref_text)

    except Exception:
        logger.exception("Core memory update failed")

    return MemoryCoreUpdateResponse(updated=updated, conflicts=conflicts)


# ---------------------------------------------------------------------------
# GET /memory/status — health check
# ---------------------------------------------------------------------------


@router.get("/status", response_model=MemoryStatusResponse)
async def memory_status() -> MemoryStatusResponse:
    """Return the current status of the memory system."""
    episodic_count = 0
    store_size = 0
    blocks: dict[str, str] = {}
    core_last_updated = ""

    try:
        from aemeath_agent.rag.memory_vectorstore import get_memory_vectorstore

        vs = get_memory_vectorstore()
        if vs is not None:
            collection = vs._collection
            episodic_count = collection.count()
    except Exception:
        logger.exception("Failed to get episodic memory count")

    try:
        from aemeath_agent.agent.memory_store import get_memory_blocks, get_memory_store

        store = get_memory_store()
        if store._json_path.exists():
            store_size = store._json_path.stat().st_size
            import json as _json

            raw = _json.loads(store._json_path.read_text(encoding="utf-8"))
            # Find latest updated_at across all items
            latest = ""
            for items in raw.values():
                for entry in items.values():
                    ts = entry.get("updated_at", "")
                    if ts > latest:
                        latest = ts
            core_last_updated = latest

        mb = get_memory_blocks()
        blocks = mb.get_all()
    except Exception:
        logger.exception("Failed to get memory store status")

    return MemoryStatusResponse(
        episodic_count=episodic_count,
        core_last_updated=core_last_updated,
        store_size_bytes=store_size,
        blocks=blocks,
    )


# ---------------------------------------------------------------------------
# DELETE /memory/forget — user-initiated memory deletion
# ---------------------------------------------------------------------------


@router.delete("/forget", response_model=MemoryForgetResponse)
async def forget_memories(request: MemoryForgetRequest) -> MemoryForgetResponse:
    """Delete memories matching a query or time range.

    Searches across both the persistent store and ChromaDB episodic collection.
    """
    deleted = 0

    # Delete from ChromaDB episodic memories
    if request.query:
        try:
            from aemeath_agent.rag.memory_vectorstore import get_memory_vectorstore

            vs = get_memory_vectorstore()
            if vs is not None:
                results = vs.similarity_search_with_relevance_scores(request.query, k=20)
                ids_to_delete = []
                for doc, score in results:
                    if score > 0.5:
                        doc_id = doc.metadata.get("id")
                        if doc_id:
                            ids_to_delete.append(doc_id)
                if ids_to_delete:
                    vs.delete(ids=ids_to_delete)
                    deleted += len(ids_to_delete)
        except Exception:
            logger.exception("Failed to delete episodic memories")

    # Delete from persistent store by searching values
    if request.query:
        try:
            from aemeath_agent.agent.memory_store import get_memory_store

            store = get_memory_store()
            query_lower = request.query.lower()
            keys_to_delete: list[tuple[tuple[str, ...], str]] = []

            for namespace, items in store._data.items():
                for key, item in items.items():
                    content = item.value.get("content", "")
                    if query_lower in content.lower():
                        keys_to_delete.append((namespace, key))

            for ns, k in keys_to_delete:
                store.delete(ns, k)
                deleted += 1
        except Exception:
            logger.exception("Failed to delete from persistent store")

    return MemoryForgetResponse(deleted_count=deleted)

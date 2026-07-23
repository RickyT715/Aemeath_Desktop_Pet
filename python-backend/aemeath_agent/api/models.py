"""Pydantic request/response schemas for the API."""

from typing import Any

from pydantic import BaseModel, Field


class AgentRequest(BaseModel):
    """Request body for agent invoke/stream endpoints."""

    message: str
    thread_id: str = "default"
    context: dict[str, Any] = Field(default_factory=dict)


class AgentResponse(BaseModel):
    """Response from one-shot agent invocation."""

    reply: str
    tool_calls: list[dict[str, Any]] = Field(default_factory=list)
    thread_id: str


class StreamEvent(BaseModel):
    """A single SSE event from the agent stream.

    Types: token, tool_call, tool_result, done, error
    """

    type: str
    content: str = ""
    data: dict[str, Any] | None = None


class HealthResponse(BaseModel):
    """Health check response."""

    status: str = "ok"
    version: str = "0.1.0"
    uptime: float = 0.0


class ConfigSyncRequest(BaseModel):
    """Request to sync configuration from WPF app at runtime."""

    ai_provider: str | None = None
    anthropic_api_key: str | None = None
    google_api_key: str | None = None
    tavily_api_key: str | None = None
    openweather_api_key: str | None = None
    vision_provider: str | None = None
    ollama_base_url: str | None = None
    ollama_model_name: str | None = None
    embedding_model: str | None = None
    proxy_base_url: str | None = None


class RagIngestRequest(BaseModel):
    """Request to ingest documents into the RAG store."""

    path: str
    is_directory: bool = False
    glob_pattern: str = "**/*.*"


class RagQueryRequest(BaseModel):
    """Request to query the RAG store."""

    query: str
    top_k: int = 5


class RagQueryResult(BaseModel):
    """A single result from RAG query."""

    content: str
    source: str = ""
    score: float = 0.0


class RagStatusResponse(BaseModel):
    """Status of the RAG store."""

    initialized: bool = False
    document_count: int = 0
    collection_name: str = ""


class SttRequest(BaseModel):
    """Request for speech-to-text transcription."""

    audio_base64: str
    provider: str = "whisper"
    language: str = "en"


class SttResponse(BaseModel):
    """Response from speech-to-text transcription."""

    text: str
    language: str = ""
    confidence: float = 0.0


class VisionRequest(BaseModel):
    """Request for vision/image analysis."""

    image_base64: str
    prompt: str = "Describe what you see in this image."
    provider: str | None = None


# ---------------------------------------------------------------------------
# Memory endpoints
# ---------------------------------------------------------------------------


class MemoryExtractRequest(BaseModel):
    """Request to extract facts from a conversation turn."""

    user_message: str
    assistant_response: str
    thread_id: str = "default"


class ExtractedFact(BaseModel):
    """A single fact extracted from conversation."""

    fact: str
    confidence: float = 0.5
    category: str = "general"


class MemoryExtractResponse(BaseModel):
    """Response from memory extraction."""

    facts: list[ExtractedFact] = Field(default_factory=list)
    events: list[dict[str, Any]] = Field(default_factory=list)
    preferences: list[dict[str, Any]] = Field(default_factory=list)


class MemoryRetrieveResult(BaseModel):
    """A single result from memory retrieval."""

    content: str
    type: str = ""
    created_at: str = ""
    importance: float = 0.0


class MemoryRetrieveResponse(BaseModel):
    """Response from memory retrieval."""

    memories: list[MemoryRetrieveResult] = Field(default_factory=list)


class ObservationItem(BaseModel):
    """A single raw observation to distill."""

    timestamp: str
    source: str
    content: str
    activity_context: str = ""


class MemoryDistillRequest(BaseModel):
    """Request to distill observations into durable memories."""

    observations: list[ObservationItem]


class DistilledMemory(BaseModel):
    """A single distilled memory from observations."""

    content: str
    type: str = "observation"
    importance: float = 0.5


class MemoryDistillResponse(BaseModel):
    """Response from observation distillation."""

    distilled: list[DistilledMemory] = Field(default_factory=list)
    patterns: list[str] = Field(default_factory=list)


class MemoryCoreUpdateRequest(BaseModel):
    """Request to update core memory from extraction results."""

    user_facts: list[dict[str, Any]] = Field(default_factory=list)
    events: list[dict[str, Any]] = Field(default_factory=list)
    preferences: list[dict[str, Any]] = Field(default_factory=list)


class MemoryCoreUpdateResponse(BaseModel):
    """Response from core memory update."""

    updated: list[str] = Field(default_factory=list)
    conflicts: list[str] = Field(default_factory=list)


class MemoryStatusResponse(BaseModel):
    """Memory system health status."""

    episodic_count: int = 0
    core_last_updated: str = ""
    store_size_bytes: int = 0
    blocks: dict[str, str] = Field(default_factory=dict)


class MemoryForgetRequest(BaseModel):
    """Request to forget/delete memories."""

    query: str | None = None
    time_range: dict[str, str] | None = None


class MemoryForgetResponse(BaseModel):
    """Response from memory forget operation."""

    deleted_count: int = 0

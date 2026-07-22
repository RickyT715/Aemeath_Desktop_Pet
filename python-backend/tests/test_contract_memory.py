"""Contract tests verifying Python<->C# JSON compatibility for memory endpoints."""

import json

import pytest
from pydantic import ValidationError

from aemeath_agent.api.models import (
    MemoryExtractRequest,
    MemoryDistillRequest,
    MemoryRetrieveResponse,
    MemoryRetrieveResult,
    MemoryCoreUpdateRequest,
    ObservationItem,
)


class TestExtractionContract:
    def test_snake_case_fields_deserialize(self):
        """C# sends snake_case fields -- Pydantic should parse them."""
        data = {
            "user_message": "Hello there",
            "assistant_response": "Hi! How are you?",
            "thread_id": "test-thread",
        }
        req = MemoryExtractRequest(**data)
        assert req.user_message == "Hello there"
        assert req.assistant_response == "Hi! How are you?"
        assert req.thread_id == "test-thread"

    def test_camel_case_raises_validation_error(self):
        """If C# sent camelCase (the old bug), required fields would be missing."""
        data = {
            "userMessage": "Hello",
            "assistantResponse": "Hi!",
        }
        # user_message and assistant_response are required fields.
        # Pydantic v2 ignores unknown fields and raises for missing required ones.
        with pytest.raises(ValidationError):
            MemoryExtractRequest(**data)

    def test_thread_id_defaults(self):
        """thread_id should default to 'default' when not provided."""
        req = MemoryExtractRequest(user_message="hi", assistant_response="hey")
        assert req.thread_id == "default"


class TestDistillationContract:
    def test_observation_items_deserialize(self):
        """C# sends observation items with snake_case fields."""
        data = {
            "observations": [
                {
                    "timestamp": "2026-03-03T10:00:00Z",
                    "source": "screen",
                    "content": "VS Code open",
                    "activity_context": "StudyingCoding",
                }
            ]
        }
        req = MemoryDistillRequest(**data)
        assert len(req.observations) == 1
        assert req.observations[0].activity_context == "StudyingCoding"

    def test_camel_case_activity_context_not_populated(self):
        """Old bug: C# sent activityContext instead of activity_context."""
        data = {
            "observations": [
                {
                    "timestamp": "2026-03-03T10:00:00Z",
                    "source": "screen",
                    "content": "test",
                    "activityContext": "StudyingCoding",
                }
            ]
        }
        req = MemoryDistillRequest(**data)
        assert req.observations[0].activity_context == ""  # Default

    def test_missing_optional_fields_default(self):
        """activity_context is optional and defaults to empty."""
        data = {
            "observations": [{"timestamp": "t", "source": "s", "content": "c"}]
        }
        req = MemoryDistillRequest(**data)
        assert req.observations[0].activity_context == ""


class TestRetrievalResponseContract:
    def test_response_serializes_with_memories_array(self):
        """Verify the response JSON structure matches what C# expects."""
        resp = MemoryRetrieveResponse(
            memories=[
                MemoryRetrieveResult(
                    content="User likes coding", type="fact", importance=0.8
                )
            ]
        )
        json_str = resp.model_dump_json()
        parsed = json.loads(json_str)
        assert "memories" in parsed
        assert len(parsed["memories"]) == 1
        assert parsed["memories"][0]["content"] == "User likes coding"

    def test_result_fields_present(self):
        result = MemoryRetrieveResult(
            content="test", type="fact", created_at="2026-03-01", importance=0.7
        )
        data = result.model_dump()
        assert "content" in data
        assert "type" in data
        assert "created_at" in data
        assert "importance" in data

    def test_empty_memories_list_serializes(self):
        resp = MemoryRetrieveResponse(memories=[])
        parsed = json.loads(resp.model_dump_json())
        assert parsed["memories"] == []


class TestCoreUpdateContract:
    def test_facts_and_preferences_deserialize(self):
        data = {
            "user_facts": [{"fact": "Student", "category": "occupation"}],
            "preferences": [{"preference": "Dark mode"}],
        }
        req = MemoryCoreUpdateRequest(**data)
        assert len(req.user_facts) == 1
        assert req.user_facts[0]["fact"] == "Student"
        assert len(req.preferences) == 1

    def test_empty_request_defaults(self):
        req = MemoryCoreUpdateRequest()
        assert req.user_facts == []
        assert req.preferences == []

    def test_events_field_defaults_to_empty(self):
        req = MemoryCoreUpdateRequest()
        assert req.events == []

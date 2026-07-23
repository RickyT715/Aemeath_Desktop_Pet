"""Tests for the system prompt builder."""

from unittest.mock import patch, MagicMock
from aemeath_agent.agent.prompts import (
    build_system_prompt,
    _get_time_of_day,
    _get_user_block,
    CHARACTER_PROMPT,
    TOOL_INSTRUCTIONS,
)


class TestBuildSystemPrompt:
    def test_returns_string(self):
        result = build_system_prompt()
        assert isinstance(result, str)

    def test_contains_character_prompt(self):
        result = build_system_prompt()
        assert "Aemeath" in result
        assert "digital ghost" in result

    def test_injects_mood_energy_affection(self):
        ctx = {"mood": 90, "energy": 40, "affection": 60}
        result = build_system_prompt(ctx)
        assert "Mood: 90/100" in result
        assert "Energy: 40/100" in result
        assert "Affection: 60/100" in result

    def test_uses_defaults_when_no_context(self):
        result = build_system_prompt()
        assert "Mood: 75/100" in result
        assert "Energy: 75/100" in result
        assert "Affection: 50/100" in result

    def test_includes_time_of_day(self):
        result = build_system_prompt()
        # Should contain one of: Morning, Afternoon, Evening, Late Night
        assert any(t in result for t in ["Morning", "Afternoon", "Evening", "Late Night"])

    def test_includes_tool_instructions(self):
        result = build_system_prompt()
        assert "Available Tools" in result
        assert "search_web" in result

    def test_injects_memory_context(self):
        ctx = {"memory_context": "User's name is Ricky. Enjoys programming."}
        result = build_system_prompt(ctx)
        assert "What I Remember" in result
        assert "User's name is Ricky" in result

    def test_injects_activity(self):
        ctx = {"activity": "Currently browsing Stack Overflow"}
        result = build_system_prompt(ctx)
        assert "Current User Activity" in result
        assert "Stack Overflow" in result

    def test_injects_pomodoro_status(self):
        ctx = {"pomodoro_status": "Work session: 15 minutes remaining"}
        result = build_system_prompt(ctx)
        assert "Pomodoro Status" in result
        assert "15 minutes remaining" in result

    def test_injects_screen_context(self):
        ctx = {"screen_context": "User has VS Code open with Python file"}
        result = build_system_prompt(ctx)
        assert "What's On Screen" in result
        assert "VS Code open" in result

    def test_injects_days_together(self):
        ctx = {"days_together": 45}
        result = build_system_prompt(ctx)
        assert "Days together with user: 45" in result

    def test_no_memory_section_when_no_memory_context(self):
        result = build_system_prompt()
        assert "What I Remember" not in result

    def test_no_activity_section_when_no_activity(self):
        result = build_system_prompt()
        assert "Current User Activity" not in result

    def test_no_pomodoro_section_when_no_pomodoro(self):
        result = build_system_prompt()
        assert "Pomodoro Status" not in result

    def test_no_screen_section_when_no_screen_context(self):
        result = build_system_prompt()
        assert "What's On Screen" not in result

    def test_all_context_fields_combined(self):
        ctx = {
            "mood": 80,
            "energy": 60,
            "affection": 70,
            "days_together": 10,
            "memory_context": "Remembers user likes Python",
            "activity": "Writing code",
            "pomodoro_status": "Break time",
            "screen_context": "IDE open",
        }
        result = build_system_prompt(ctx)
        assert "Mood: 80/100" in result
        assert "What I Remember" in result
        assert "Current User Activity" in result
        assert "Pomodoro Status" in result
        assert "What's On Screen" in result

    def test_user_block_injected_when_available(self):
        mock_blocks = MagicMock()
        mock_blocks.get.return_value = "User's name is Ricky. CS student."
        with patch("aemeath_agent.agent.memory_store.get_memory_blocks", return_value=mock_blocks):
            result = build_system_prompt()
        assert "What I Know About the User" in result
        assert "Ricky" in result

    def test_user_block_not_injected_when_default_placeholder(self):
        mock_blocks = MagicMock()
        mock_blocks.get.return_value = (
            "No information about the user yet. "
            "As you learn things, use update_user_block to save them here."
        )
        with patch("aemeath_agent.agent.memory_store.get_memory_blocks", return_value=mock_blocks):
            result = build_system_prompt()
        assert "What I Know About the User" not in result


class TestGetUserBlock:
    def test_returns_empty_when_blocks_unavailable(self):
        with patch(
            "aemeath_agent.agent.memory_store.get_memory_blocks",
            side_effect=Exception("no store"),
        ):
            result = _get_user_block()
            assert result == ""

    def test_returns_empty_for_default_placeholder(self):
        mock_blocks = MagicMock()
        mock_blocks.get.return_value = (
            "No information about the user yet. "
            "As you learn things, use update_user_block to save them here."
        )
        with patch("aemeath_agent.agent.memory_store.get_memory_blocks", return_value=mock_blocks):
            result = _get_user_block()
            assert result == ""

    def test_returns_content_when_real_data(self):
        mock_blocks = MagicMock()
        mock_blocks.get.return_value = "User's name is Ricky. CS student. Loves WuWa."
        with patch("aemeath_agent.agent.memory_store.get_memory_blocks", return_value=mock_blocks):
            result = _get_user_block()
            assert "Ricky" in result

    def test_handles_exception_gracefully(self):
        with patch(
            "aemeath_agent.agent.memory_store.get_memory_blocks",
            side_effect=RuntimeError("broken"),
        ):
            result = _get_user_block()
            assert result == ""


class TestGetTimeOfDay:
    def test_morning(self):
        for h in [5, 8, 11]:
            assert _get_time_of_day(h) == "Morning"

    def test_afternoon(self):
        for h in [12, 14, 16]:
            assert _get_time_of_day(h) == "Afternoon"

    def test_evening(self):
        for h in [17, 19, 20]:
            assert _get_time_of_day(h) == "Evening"

    def test_late_night(self):
        for h in [0, 3, 4, 21, 23]:
            assert _get_time_of_day(h) == "Late Night"

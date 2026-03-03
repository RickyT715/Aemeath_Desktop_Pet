"""Tests for the system prompt builder."""

from aemeath_agent.agent.prompts import build_system_prompt


def test_build_system_prompt_contains_character_name():
    prompt = build_system_prompt()
    assert "Aemeath" in prompt


def test_build_system_prompt_contains_personality():
    prompt = build_system_prompt()
    assert "bubbly" in prompt or "optimistic" in prompt


def test_build_system_prompt_contains_tools():
    prompt = build_system_prompt()
    assert "search_web" in prompt
    assert "get_weather" in prompt


def test_build_system_prompt_includes_stats():
    prompt = build_system_prompt({"mood": 42, "energy": 88, "affection": 15})
    assert "42" in prompt
    assert "88" in prompt
    assert "15" in prompt


def test_build_system_prompt_includes_activity():
    prompt = build_system_prompt({"activity": "Coding in VS Code"})
    assert "Coding in VS Code" in prompt


def test_build_system_prompt_includes_pomodoro():
    prompt = build_system_prompt({"pomodoro_status": "Work session (22 min remaining)"})
    assert "Work session" in prompt


def test_build_system_prompt_includes_screen_context():
    prompt = build_system_prompt({"screen_context": "User is viewing a YouTube video"})
    assert "YouTube" in prompt


def test_build_system_prompt_default_stats():
    prompt = build_system_prompt()
    assert "75" in prompt  # Default mood/energy


def test_build_system_prompt_time_of_day():
    prompt = build_system_prompt()
    # Should contain one of the time-of-day labels
    assert any(t in prompt for t in ["Morning", "Afternoon", "Evening", "Late Night"])

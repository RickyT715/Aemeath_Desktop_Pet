"""Tests for the tools init module (tools/__init__.py)."""

from unittest.mock import MagicMock, patch

from aemeath_agent.config import Settings


def _make_settings(**overrides) -> Settings:
    return Settings(_env_file=None, **overrides)  # type: ignore[call-arg]


def test_get_all_tools_returns_list():
    settings = _make_settings()
    from aemeath_agent.tools import get_all_tools

    tools = get_all_tools(settings)
    assert isinstance(tools, list)


def test_get_all_tools_has_9_tools():
    settings = _make_settings()
    from aemeath_agent.tools import get_all_tools

    tools = get_all_tools(settings)
    assert len(tools) == 9


def test_tool_names_correct():
    settings = _make_settings()
    from aemeath_agent.tools import get_all_tools

    tools = get_all_tools(settings)
    names = [t.name for t in tools]
    expected = [
        "search_web",
        "get_weather",
        "manage_todo",
        "read_screen",
        "control_music",
        "get_pet_stats",
        "rag_retrieve",
        "get_system_info",
        "save_memory",
    ]
    assert names == expected


def test_configure_functions_called():
    """Verify that configure functions are called with correct settings."""
    settings = _make_settings(
        tavily_api_key="tavily-key",
        openweather_api_key="weather-key",
        wpf_internal_port=19000,
    )

    with (
        patch("aemeath_agent.tools.configure_search") as mock_search,
        patch("aemeath_agent.tools.configure_weather") as mock_weather,
        patch("aemeath_agent.tools.configure_todo") as mock_todo,
        patch("aemeath_agent.tools.configure_screen") as mock_screen,
        patch("aemeath_agent.tools.configure_music") as mock_music,
        patch("aemeath_agent.tools.configure_stats") as mock_stats,
    ):
        from aemeath_agent.tools import get_all_tools

        get_all_tools(settings)

        mock_search.assert_called_once_with(api_key="tavily-key")
        mock_weather.assert_called_once_with(api_key="weather-key")
        mock_todo.assert_called_once_with(db_path="data/todos.db")
        mock_screen.assert_called_once_with(wpf_port=19000)
        mock_music.assert_called_once_with(wpf_port=19000)
        mock_stats.assert_called_once_with(wpf_port=19000)


def test_tools_are_callable():
    """Each tool should be callable (LangChain tools have .invoke)."""
    settings = _make_settings()
    from aemeath_agent.tools import get_all_tools

    tools = get_all_tools(settings)
    for tool in tools:
        assert hasattr(tool, "invoke"), f"Tool {tool.name} missing invoke method"

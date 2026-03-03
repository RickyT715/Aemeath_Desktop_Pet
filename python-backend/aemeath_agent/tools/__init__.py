"""Agent tools — all tools registered with the LangGraph agent."""

from typing import Any

from aemeath_agent.config import Settings
from aemeath_agent.tools.music_control import configure as configure_music
from aemeath_agent.tools.music_control import control_music
from aemeath_agent.tools.pet_stats import configure as configure_stats
from aemeath_agent.tools.pet_stats import get_pet_stats
from aemeath_agent.tools.rag_retrieval import rag_retrieve
from aemeath_agent.tools.save_memory import save_memory
from aemeath_agent.tools.screen_reader import configure as configure_screen
from aemeath_agent.tools.screen_reader import read_screen
from aemeath_agent.tools.system_info import get_system_info
from aemeath_agent.tools.todo import configure as configure_todo
from aemeath_agent.tools.todo import manage_todo
from aemeath_agent.tools.weather import configure as configure_weather
from aemeath_agent.tools.weather import get_weather
from aemeath_agent.tools.web_search import configure as configure_search
from aemeath_agent.tools.web_search import search_web


def get_all_tools(settings: Settings) -> list[Any]:
    """Return all agent tools, configured with the given settings.

    Args:
        settings: Application settings with API keys and ports.

    Returns:
        List of LangChain tool objects ready for agent registration.
    """
    # Configure tools that need API keys or ports
    configure_search(api_key=settings.tavily_api_key)
    configure_weather(api_key=settings.openweather_api_key)
    configure_todo(db_path="data/todos.db")
    configure_screen(wpf_port=settings.wpf_internal_port)
    configure_music(wpf_port=settings.wpf_internal_port)
    configure_stats(wpf_port=settings.wpf_internal_port)

    return [
        search_web,
        get_weather,
        manage_todo,
        read_screen,
        control_music,
        get_pet_stats,
        rag_retrieve,
        get_system_info,
        save_memory,
    ]

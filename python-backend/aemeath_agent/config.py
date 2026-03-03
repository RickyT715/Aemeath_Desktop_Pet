"""Application configuration via environment variables and .env file."""

import os
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


def _default_agent_db_path() -> str:
    local_app_data = os.environ.get("LOCALAPPDATA", "")
    if local_app_data:
        return str(Path(local_app_data) / "AemeathDesktopPet" / "agent_state.db")
    return str(Path.home() / ".aemeath" / "agent_state.db")


class Settings(BaseSettings):
    """Backend configuration loaded from environment variables and .env file."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="AEMEATH_",
        extra="ignore",
    )

    # AI provider: "claude", "gemini", or "proxy"
    ai_provider: str = "claude"

    # API keys
    anthropic_api_key: str = ""
    google_api_key: str = ""
    tavily_api_key: str = ""
    openweather_api_key: str = ""

    # WPF internal API
    wpf_internal_port: int = 18901

    # Agent persistence
    agent_db_path: str = _default_agent_db_path()

    # RAG / ChromaDB
    chromadb_path: str = "data/chromadb"

    # Embedding model: "gemini" or "local"
    embedding_model: str = "gemini"

    # Vision provider: "gemini", "claude", "ollama", "hybrid"
    vision_provider: str = "gemini"

    # Ollama settings
    ollama_base_url: str = "http://localhost:11434"
    ollama_model_name: str = "llava"

    # Proxy settings (claude-code-proxy)
    proxy_base_url: str = "http://localhost:42069"

    # Server
    host: str = "127.0.0.1"
    port: int = 18900


def get_settings() -> Settings:
    """Create and return a Settings instance."""
    return Settings()

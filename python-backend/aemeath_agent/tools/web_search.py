"""Web search tool using Tavily API."""

import json
import logging

from langchain_core.tools import tool

logger = logging.getLogger(__name__)

_tavily_api_key: str = ""


def configure(api_key: str) -> None:
    """Set the Tavily API key."""
    global _tavily_api_key
    _tavily_api_key = api_key


@tool
def search_web(query: str, num_results: int = 5) -> str:
    """Search the internet for current information, news, or facts.

    Use this when the user asks about recent events, needs factual information
    you're unsure about, or anything requiring up-to-date data.

    Args:
        query: The search query string.
        num_results: Number of results to return (default 5).
    """
    try:
        from tavily import TavilyClient

        if not _tavily_api_key:
            return json.dumps({"status": "error", "message": "Tavily API key not configured."})

        client = TavilyClient(api_key=_tavily_api_key)
        results = client.search(query=query, max_results=num_results)

        formatted = []
        for r in results.get("results", []):
            formatted.append({
                "title": r.get("title", ""),
                "url": r.get("url", ""),
                "snippet": r.get("content", "")[:300],
            })

        return json.dumps({"status": "success", "results": formatted})
    except Exception as e:
        logger.exception("Web search failed")
        return json.dumps({"status": "error", "message": str(e)})

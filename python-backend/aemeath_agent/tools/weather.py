"""Weather tool using OpenWeatherMap API."""

import json
import logging

import httpx
from langchain_core.tools import tool

logger = logging.getLogger(__name__)

_api_key: str = ""


def configure(api_key: str) -> None:
    """Set the OpenWeatherMap API key."""
    global _api_key
    _api_key = api_key


@tool
def get_weather(location: str, units: str = "metric") -> str:
    """Get current weather and forecast for a location.

    Use when the user asks about weather or you need weather context for conversation.

    Args:
        location: City name, e.g. "Tokyo" or "London,UK".
        units: Temperature units — "metric" (Celsius) or "imperial" (Fahrenheit).
    """
    try:
        if not _api_key:
            return json.dumps({"status": "error", "message": "OpenWeatherMap API key not configured."})

        response = httpx.get(
            "https://api.openweathermap.org/data/2.5/weather",
            params={"q": location, "units": units, "appid": _api_key},
            timeout=10.0,
        )
        response.raise_for_status()
        data = response.json()

        unit_symbol = "C" if units == "metric" else "F"
        weather = {
            "location": data.get("name", location),
            "description": data["weather"][0]["description"],
            "temperature": f"{data['main']['temp']}°{unit_symbol}",
            "feels_like": f"{data['main']['feels_like']}°{unit_symbol}",
            "humidity": f"{data['main']['humidity']}%",
            "wind_speed": f"{data['wind']['speed']} m/s",
        }
        return json.dumps({"status": "success", "data": weather})
    except httpx.HTTPStatusError as e:
        logger.warning("Weather API HTTP error: %s", e.response.status_code)
        return json.dumps({"status": "error", "message": f"Weather API error: {e.response.status_code}"})
    except Exception as e:
        logger.exception("Weather tool failed")
        return json.dumps({"status": "error", "message": str(e)})

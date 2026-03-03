"""Tests for the weather tool."""

import json
from unittest.mock import MagicMock, patch

import httpx

import aemeath_agent.tools.weather as weather_mod


def _invoke(location: str = "Tokyo", units: str = "metric") -> dict:
    result = weather_mod.get_weather.invoke({"location": location, "units": units})
    return json.loads(result)


def _mock_weather_response():
    return {
        "name": "Tokyo",
        "weather": [{"description": "clear sky"}],
        "main": {"temp": 22.5, "feels_like": 21.0, "humidity": 55},
        "wind": {"speed": 3.2},
    }


class TestGetWeather:
    def setup_method(self):
        weather_mod._api_key = ""

    def test_no_api_key_returns_error(self):
        data = _invoke("London")
        assert data["status"] == "error"
        assert "not configured" in data["message"]

    def test_success_metric(self):
        weather_mod._api_key = "test-key"
        mock_resp = MagicMock()
        mock_resp.json.return_value = _mock_weather_response()
        mock_resp.raise_for_status = MagicMock()

        with patch("aemeath_agent.tools.weather.httpx.get", return_value=mock_resp):
            data = _invoke("Tokyo", "metric")

        assert data["status"] == "success"
        w = data["data"]
        assert w["location"] == "Tokyo"
        assert w["description"] == "clear sky"
        assert "22.5" in w["temperature"]
        assert "C" in w["temperature"]
        assert "55%" == w["humidity"]

    def test_success_imperial(self):
        weather_mod._api_key = "test-key"
        resp_data = _mock_weather_response()
        resp_data["main"]["temp"] = 72.5
        resp_data["main"]["feels_like"] = 70.0
        mock_resp = MagicMock()
        mock_resp.json.return_value = resp_data
        mock_resp.raise_for_status = MagicMock()

        with patch("aemeath_agent.tools.weather.httpx.get", return_value=mock_resp):
            data = _invoke("Tokyo", "imperial")

        assert "F" in data["data"]["temperature"]

    def test_http_status_error(self):
        weather_mod._api_key = "test-key"
        mock_response = MagicMock(spec=httpx.Response)
        mock_response.status_code = 404

        with patch(
            "aemeath_agent.tools.weather.httpx.get",
            side_effect=httpx.HTTPStatusError("Not Found", request=MagicMock(), response=mock_response),
        ):
            data = _invoke("Nowhere")

        assert data["status"] == "error"
        assert "404" in data["message"]

    def test_timeout_returns_error(self):
        weather_mod._api_key = "test-key"
        with patch(
            "aemeath_agent.tools.weather.httpx.get",
            side_effect=httpx.TimeoutException("timed out"),
        ):
            data = _invoke("Slow City")

        assert data["status"] == "error"
        assert "timed out" in data["message"]

    def test_generic_exception(self):
        weather_mod._api_key = "test-key"
        with patch(
            "aemeath_agent.tools.weather.httpx.get",
            side_effect=RuntimeError("unexpected"),
        ):
            data = _invoke("Broken")

        assert data["status"] == "error"
        assert "unexpected" in data["message"]

    def test_configure_sets_key(self):
        weather_mod.configure("owm-key-123")
        assert weather_mod._api_key == "owm-key-123"

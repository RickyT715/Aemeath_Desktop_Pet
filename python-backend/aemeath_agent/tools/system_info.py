"""System information tool using psutil."""

import json
import logging
import platform

import psutil
from langchain_core.tools import tool

logger = logging.getLogger(__name__)


@tool
def get_system_info() -> str:
    """Get current computer system information including OS, CPU, memory, disk, and battery.

    Use when the user asks about their computer status, performance, or system resources.
    """
    try:
        info: dict[str, object] = {
            "os": f"{platform.system()} {platform.release()}",
            "cpu_percent": psutil.cpu_percent(interval=0.5),
            "memory_total_gb": round(psutil.virtual_memory().total / (1024**3), 1),
            "memory_used_percent": psutil.virtual_memory().percent,
            "disk_total_gb": round(psutil.disk_usage("/").total / (1024**3), 1),
            "disk_used_percent": psutil.disk_usage("/").percent,
        }

        battery = psutil.sensors_battery()
        if battery is not None:
            info["battery_percent"] = battery.percent
            info["battery_plugged_in"] = battery.power_plugged

        return json.dumps({"status": "success", "data": info})
    except Exception as e:
        logger.exception("System info failed")
        return json.dumps({"status": "error", "message": str(e)})

"""FastAPI application entry point for Aemeath AI backend."""

import argparse
import logging
import sys
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from aemeath_agent.config import get_settings

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator[None, None]:
    """Application lifespan: initialize agent on startup, cleanup on shutdown."""
    settings = get_settings()
    logger.info("Initializing Aemeath AI backend...")

    try:
        from aemeath_agent.agent.graph import create_aemeath_agent
        from aemeath_agent.api.routes_agent import set_agent

        agent = await create_aemeath_agent(settings)
        set_agent(agent)
        logger.info("Agent initialized successfully")
    except Exception:
        logger.exception("Failed to initialize agent — running in degraded mode")

    # Signal to the WPF parent process that the backend is ready
    print(f"READY:{settings.port}", flush=True)

    yield

    logger.info("Shutting down Aemeath AI backend")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    app = FastAPI(
        title="Aemeath AI Backend",
        version="0.1.0",
        lifespan=lifespan,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=[
            "http://localhost",
            "http://127.0.0.1",
            "http://localhost:18901",
            "http://127.0.0.1:18901",
        ],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    from aemeath_agent.api.routes_agent import router as agent_router
    from aemeath_agent.api.routes_config import router as config_router
    from aemeath_agent.api.routes_health import router as health_router
    from aemeath_agent.api.routes_rag import router as rag_router
    from aemeath_agent.api.routes_stt import router as stt_router
    from aemeath_agent.api.routes_vision import router as vision_router

    app.include_router(health_router)
    app.include_router(config_router)
    app.include_router(agent_router)
    app.include_router(stt_router)
    app.include_router(vision_router)
    app.include_router(rag_router)

    return app


app = create_app()


def cli() -> None:
    """CLI entry point: run uvicorn with configurable host/port."""
    parser = argparse.ArgumentParser(description="Aemeath AI Backend")
    parser.add_argument("--host", default="127.0.0.1", help="Bind host (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=18900, help="Bind port (default: 18900)")
    args = parser.parse_args()

    import uvicorn

    uvicorn.run(
        "aemeath_agent.main:app",
        host=args.host,
        port=args.port,
        log_level="info",
    )


if __name__ == "__main__":
    cli()

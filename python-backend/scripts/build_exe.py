"""PyInstaller build script for Aemeath AI Backend.

Builds a single-folder distribution at dist/aemeath-agent/.
Uses console mode so stdout can be captured by the C# parent process.

Usage:
    python scripts/build_exe.py
"""

import subprocess
import sys
from pathlib import Path


def build() -> None:
    """Run PyInstaller to build the aemeath-agent executable."""
    project_root = Path(__file__).resolve().parent.parent
    entry_point = project_root / "aemeath_agent" / "main.py"
    dist_dir = project_root / "dist"

    if not entry_point.exists():
        print(f"Entry point not found: {entry_point}", file=sys.stderr)
        sys.exit(1)

    cmd = [
        sys.executable,
        "-m",
        "PyInstaller",
        str(entry_point),
        "--name", "aemeath-agent",
        "--distpath", str(dist_dir),
        "--workpath", str(project_root / "build"),
        "--specpath", str(project_root),
        # Single-folder mode (not single-file — faster startup, easier debugging)
        "--noconfirm",
        "--clean",
        # Console mode so the WPF app can read READY:18900 from stdout
        "--console",
        # Hidden imports that PyInstaller misses
        "--hidden-import", "langchain",
        "--hidden-import", "langchain.agents",
        "--hidden-import", "langchain.text_splitter",
        "--hidden-import", "langchain.retrievers",
        "--hidden-import", "langchain_core",
        "--hidden-import", "langchain_core.tools",
        "--hidden-import", "langchain_core.documents",
        "--hidden-import", "langchain_core.embeddings",
        "--hidden-import", "langchain_core.retrievers",
        "--hidden-import", "langchain_anthropic",
        "--hidden-import", "langchain_google_genai",
        "--hidden-import", "langchain_community",
        "--hidden-import", "langchain_community.vectorstores",
        "--hidden-import", "langchain_community.embeddings",
        "--hidden-import", "langchain_community.retrievers",
        "--hidden-import", "langchain_community.document_loaders",
        "--hidden-import", "langgraph",
        "--hidden-import", "langgraph.prebuilt",
        "--hidden-import", "langgraph.checkpoint.sqlite",
        "--hidden-import", "langgraph.checkpoint.sqlite.aio",
        "--hidden-import", "langgraph.store.memory",
        "--hidden-import", "chromadb",
        "--hidden-import", "chromadb.config",
        "--hidden-import", "sentence_transformers",
        "--hidden-import", "sentence_transformers.cross_encoder",
        "--hidden-import", "rank_bm25",
        "--hidden-import", "pypdf",
        "--hidden-import", "docx2txt",
        "--hidden-import", "tavily",
        "--hidden-import", "psutil",
        "--hidden-import", "httpx",
        "--hidden-import", "sse_starlette",
        "--hidden-import", "pydantic_settings",
        "--hidden-import", "uvicorn",
        "--hidden-import", "uvicorn.logging",
        "--hidden-import", "uvicorn.loops",
        "--hidden-import", "uvicorn.loops.auto",
        "--hidden-import", "uvicorn.protocols",
        "--hidden-import", "uvicorn.protocols.http",
        "--hidden-import", "uvicorn.protocols.http.auto",
        "--hidden-import", "uvicorn.protocols.websockets",
        "--hidden-import", "uvicorn.protocols.websockets.auto",
        "--hidden-import", "uvicorn.lifespan",
        "--hidden-import", "uvicorn.lifespan.on",
        # Collect all data files for these packages
        "--collect-data", "chromadb",
        "--collect-data", "sentence_transformers",
        "--collect-data", "langchain",
        "--collect-data", "langchain_core",
        # Copy metadata for packages that need it
        "--copy-metadata", "langchain",
        "--copy-metadata", "langchain-core",
        "--copy-metadata", "langchain-community",
        "--copy-metadata", "langchain-anthropic",
        "--copy-metadata", "langchain-google-genai",
        "--copy-metadata", "chromadb",
        "--copy-metadata", "sentence-transformers",
        "--copy-metadata", "pydantic",
    ]

    print(f"Building aemeath-agent from {entry_point}")
    print(f"Output: {dist_dir / 'aemeath-agent'}")
    print()

    result = subprocess.run(cmd, cwd=str(project_root))
    if result.returncode != 0:
        print("Build failed!", file=sys.stderr)
        sys.exit(result.returncode)

    print()
    print(f"Build successful! Output at: {dist_dir / 'aemeath-agent'}")
    print("Run with: dist/aemeath-agent/aemeath-agent.exe")


if __name__ == "__main__":
    build()

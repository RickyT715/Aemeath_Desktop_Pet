# Repository Guidelines

## Project Structure & Module Organization

The Windows desktop application lives in `src/AemeathDesktopPet/`. It follows a WPF/MVVM-style layout: UI markup and code-behind are in `Views/`, presentation logic in `ViewModels/`, domain data in `Models/`, integrations in `Services/`, and animation/behavior code in `Engine/`. Runtime sprites, icons, and themes belong under `Resources/` and `Themes/`.

The optional FastAPI/LangGraph sidecar is in `python-backend/aemeath_agent/`, organized by capabilities such as `agent/`, `api/`, `rag/`, `stt/`, and `vision/`. C# tests mirror production areas under `tests/AemeathDesktopPet.Tests/`; Python tests are in `python-backend/tests/`. Design notes are kept in `docs/` and root-level Markdown files.

## Build, Test, and Development Commands

- `run.bat` starts the application on Windows with the repository's standard launcher.
- `dotnet run --project src/AemeathDesktopPet` builds and launches the WPF app directly.
- `dotnet build AemeathDesktopPet.sln -c Release` validates the full .NET solution.
- `dotnet test tests/AemeathDesktopPet.Tests/` runs the xUnit suite.
- `dotnet format --verify-no-changes` checks C# and project-file formatting as CI does.
- From `python-backend/`, run `pip install -e ".[dev]"`. The current manifest omits the imported `langgraph-checkpoint-sqlite` package, so also run `pip install langgraph-checkpoint-sqlite` until the manifest is corrected, then use `python -m aemeath_agent.main` to start the sidecar.
- From `python-backend/`, run `pytest -v --cov=aemeath_agent` and `ruff check .` for Python validation.
- Do not use `/health` alone to validate agent startup: FastAPI can report healthy while the agent is running in degraded mode. Exercise `/agent/invoke` or the relevant agent tests as well.

## Coding Style & Naming Conventions

Follow `.editorconfig`: CRLF endings, UTF-8, four-space indentation for C# and Python, and two spaces for XAML, XML, JSON, and YAML. Use file-scoped C# namespaces, braces, nullable-safe code, `PascalCase` for types and members, `I` prefixes for interfaces, and `_camelCase` for private fields. Python uses four spaces, snake_case identifiers, and Ruff's 100-character line limit. Keep UI logic out of code-behind when it fits a view model or service.

## Testing Guidelines

Use xUnit for .NET and pytest (including `pytest-asyncio`) for Python. Name C# test classes `*Tests` and test methods after observable behavior; name Python files `test_*.py`. Place tests beside the matching architectural area. Add unit tests for behavior changes and integration tests for cross-service flows. Coverage is collected in CI, but no fixed percentage threshold is enforced.

## Commit & Pull Request Guidelines

Recent commits use concise, imperative subjects such as `Fix CI coverage` or `Add polyglot AI backend`. Keep each commit focused and never add `Co-Authored-By` or Codex attribution. Pull requests should explain the change and verification performed, link relevant issues, and include screenshots or GIFs for visible WPF changes. Call out configuration, API-key, privacy, or compatibility impacts explicitly.

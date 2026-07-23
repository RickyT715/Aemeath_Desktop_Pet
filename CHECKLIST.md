# Aemeath Desktop Pet — Implementation Ledger

**Verified:** 2026-07-22

**Evidence base:** current working tree, project manifests, startup/runtime wiring, tests, and CI workflows

**Requirement source:** `REQUIREMENTS.md`

**Future implementation checklist:**
[`docs/plans/20260722-jarvis-assistant-tdd-checklist.md`](docs/plans/20260722-jarvis-assistant-tdd-checklist.md)

This file remains the evidence ledger for the current working application. The linked future
checklist is authoritative for the trusted-assistant migration, independent preservation Gate 0,
test-driven step order, and per-commit CI gates. Planned work must not be checked off here until the
production path and current requirement acceptance evidence actually change.

This ledger replaces the former phase checklist, which marked many interfaces, engines, and placeholders as complete before they were connected to a user-visible runtime path. It preserves the useful milestone history while recording current evidence and remaining gaps.

## Status and Evidence Rules

- `[x]` **Implemented** — implementation and normal runtime wiring are present. The item includes evidence paths.
- `[ ]` **Partial** — a substantive foundation exists, but required wiring, behavior, assets, or end-to-end verification is missing.
- `[ ]` **Planned** — accepted scope without a usable implementation.
- `[ ]` **External dependency** — repository-side adapter/wiring exists, but success depends on an external key, service, model, executable, or data source.
- `[ ]` **Asset placeholder** — final art/audio is missing or a shared/Unicode asset is used.

Do not check an item merely because a class, interface, route, setting, test double, or unit test exists. Completion requires the production execution path and the acceptance check in `REQUIREMENTS.md`. Test counts are intentionally omitted because they change; use dated command output instead.

## Milestone 1 — WPF Foundation and Desktop Shell

- [x] **Implemented — .NET 8 WPF solution and MVVM-style project layout.** Evidence: `AemeathDesktopPet.sln`, `src/AemeathDesktopPet/AemeathDesktopPet.csproj`, `Views/`, `ViewModels/`, `Models/`, `Services/`, `Engine/`.
- [x] **Implemented — transparent topmost pet window, hidden taskbar entry, and Alt+Tab tool-window behavior.** Evidence: `Views/PetWindow.xaml`, `Interop/Win32Api.cs`.
- [x] **Implemented — Per-Monitor V2 DPI declaration and Win32 environment helpers.** Evidence: `app.manifest`, `Engine/EnvironmentDetector.cs`, `Interop/Win32Api.cs`.
- [x] **Implemented — system tray icon/menu and application icon.** Evidence: `Resources/Icons/tray_icon.ico`, `AemeathDesktopPet.csproj`, `Views/PetWindow.xaml.cs`.
- [x] **Implemented — global click-through mode with visible indicator and tray/context controls.** Evidence: `Win32Api.SetClickThrough`, `Views/PetWindow.xaml`, `Views/PetWindow.xaml.cs`.
- [ ] **Planned — per-pixel hit testing.** Transparent pixels do not independently pass input while opaque pixels receive it; current click-through applies to the window.
- [x] **Implemented — JSON configuration, first-run defaults, position persistence, and startup companion launching.** Evidence: `Models/AppConfig.cs`, `Services/ConfigService.cs`, `App.xaml.cs`.
- [x] **Implemented — configurable pet size and opacity.** Evidence: `AppConfig`, `SettingsWindow`, `PetViewModel.ApplySettings`.

## Milestone 2 — Animation, Behavior, Physics, and Effects

- [x] **Implemented — GIF decoding, frame caching, source-rate playback, looping/one-shot behavior, and horizontal mirroring.** Evidence: `Engine/AnimationEngine.cs`, `Engine/BehaviorEngine.cs`.
- [x] **Implemented — 26-value pet FSM and state-to-animation mapping.** Evidence: `Models/PetState.cs`, `Engine/BehaviorEngine.cs`.
- [ ] **Asset placeholder — state-specific animation coverage.** Several states reuse `normal`, `laugh`, `sign`, `happy_jumping`, or other existing GIFs rather than purpose-built art.
- [x] **Implemented — weighted idle behavior informed by time, mood, and energy.** Evidence: `BehaviorEngine.SetStatsContext`, `Engine/TimeAwareness.cs`, `PetViewModel` event wiring.
- [x] **Implemented — gravity, flying, screen bounds, ground collision, bounce, and drag positioning engines.** Evidence: `Engine/PhysicsEngine.cs`, `PetViewModel.HandleStatePhysics`.
- [ ] **Partial — throw physics.** The physics engine exposes velocity/throw concepts, but `PetViewModel.OnDragEnd` does not calculate release velocity or enter `PetState.Thrown`.
- [x] **Implemented — primary click, hover, sing, chat, cat, stats, settings, paper-plane request, tray, and menu handlers.** Evidence: `Views/PetWindow.xaml.cs`, `ViewModels/PetViewModel.cs`.
- [x] **Implemented — glitch overlay is connected to WPF rendering and cat reaction.** Evidence: `Engine/GlitchEffect.cs`, `PetWindow.OnGlitchFrame`, `PetViewModel.WireUpEvents`.
- [x] **Implemented — particle engine and WPF particle canvas rendering.** Evidence: `Engine/ParticleSystem.cs`, `PetWindow.OnParticlesChanged`.
- [x] **Implemented — themed speech bubble, timed messages, and streamed chat UI text.** Evidence: `Views/SpeechBubble.xaml(.cs)`, `Views/ChatWindow.xaml`, `ViewModels/ChatViewModel.cs`.
- [x] **Implemented — local music-folder playback and sing-state integration.** Evidence: `Services/MusicService.cs`, `PetViewModel.HandleStateMusic`, Music settings tab.

## Milestone 3 — Companion and Environment Interaction

- [x] **Implemented — separate cat window and 12-value cat behavior engine.** Evidence: `Views/CatWindow.xaml(.cs)`, `Models/CatState.cs`, `Engine/CatBehaviorEngine.cs`.
- [x] **Implemented — cat follow, user-click, drag/land/glitch, and plane-landing reactions are wired.** Evidence: `PetViewModel.WireUpEvents`, `CatWindow`, `CatBehaviorEngine`.
- [ ] **Asset placeholder — black-cat visuals.** The cat window uses Unicode glyphs; state-specific sprite animation/loading is not implemented.
- [x] **Implemented — paper-plane trajectory, ambient scheduling, click/spin state, landing event, and cat-chase engine logic.** Evidence: `Engine/PaperPlaneSystem.cs` and its tests.
- [ ] **Partial — paper-plane production rendering.** Menus call `ThrowPlane`, but no WPF visual subscribes to and renders active plane instances.
- [ ] **Asset placeholder — paper-plane artwork.** No plane PNG/GIF is present.
- [x] **Implemented — Win32 window enumeration, DWM bounds/cloaking checks, and edge-manager tracking foundation.** Evidence: `Interop/Win32Api.cs`, `Engine/EnvironmentDetector.cs`, `Engine/WindowEdgeManager.cs`.
- [ ] **Partial — window-edge poses and subscriptions.** Edge-state enum values and manager events exist, but nearby/perch events do not drive full runtime transitions, clipping, or position tracking for `PeekEdge`, `LieOnWindow`, `HideTaskbar`, and `ClingEdge`.
- [x] **Implemented — fullscreen detection helper and TTS fullscreen auto-mute.** Evidence: `EnvironmentDetector.IsFullscreenAppActive`, `TtsVoiceService`.
- [ ] **Partial — fullscreen pet behavior.** Pet-window auto-hide/reposition is not connected to the detector.

## Milestone 4 — Stats, Settings, Persistence, and Local Integrations

- [x] **Implemented — mood, energy, affection, lifetime counters, offline decay, interaction effects, and stats persistence.** Evidence: `Models/AemeathStats.cs`, `Services/StatsService.cs`, `Services/JsonPersistenceService.cs`.
- [x] **Implemented — stats popup and behavior-context updates.** Evidence: `Views/StatsPopup.xaml(.cs)`, `PetViewModel` stats event.
- [x] **Implemented — bounded chat-history persistence in `messages.json`.** Evidence: `Services/MemoryService.cs`, `JsonPersistenceService.cs`, `ChatViewModel`.
- [x] **Implemented — exactly eight settings tabs: General, Appearance, Music, AI, Voice, Screen, Backend, and MCP.** Evidence: `Views/SettingsWindow.xaml`.
- [x] **Implemented — settings load/save and immediate reconfiguration for core appearance, chat provider, TTS, STT, hotkey, and screen awareness.** Evidence: `SettingsWindow.xaml.cs`, `PetViewModel.ApplySettings`.
- [ ] **Partial — credential disclosure/storage.** Provider keys are persisted in plaintext `config.json`; the settings UI does not warn users and Windows protected credential storage is not used.
- [ ] **External dependency — Pomodoro named-pipe integration.** Adapter and UI behavior exist; verification requires the configured companion process. Evidence: `Services/PomodoroIntegrationService.cs`.
- [ ] **External dependency — activity-monitor integration.** It is disabled by default and reads a configured external SQLite database when enabled. Evidence: `Services/ActivityMonitorService.cs`, General settings tab.
- [ ] **External dependency — optional companion launchers.** Paths are user/environment-specific. Evidence: `Services/CompanionLauncherService.cs`, `CompanionAppsConfig`.

## Milestone 5 — Chat, Voice, and Screen Awareness

### Chat and fallback

- [x] **Implemented — direct Claude and Gemini chat adapters plus configurable local proxy adapter.** Evidence: `ClaudeApiService.cs`, `GeminiApiService.cs`, `ProxyApiService.cs`.
- [x] **Implemented — themed chat window, SSE/direct streaming display, saved history, screenshot-capable request overloads, and TTS response handoff.** Evidence: `ChatViewModel.cs`, `ChatWindow.xaml(.cs)`, `IChatService.cs`.
- [x] **Implemented — contextual offline responses when no selected service is available or a request fails.** Evidence: `Models/OfflineResponses.cs` and chat services.
- [ ] **Partial — complete three-tier failover.** When the sidecar is ready it is selected before direct providers; if that sidecar request then fails, `BackendAgentService` returns offline output instead of retrying a direct provider.

### TTS (five providers)

- [x] **Implemented — provider factory, queued playback, cancellation, volume, and fullscreen auto-mute.** Evidence: `Services/TtsVoiceService.cs`, `ITtsProvider.cs`, NAudio manifest entry.
- [ ] **External dependency — Edge TTS provider.** Production wiring exists; synthesis requires the Edge TTS service/network. Evidence: `EdgeTtsProvider.cs`.
- [ ] **External dependency — GPT-SoVITS provider and profiles.** Production wiring exists; synthesis requires a compatible local server and selected model/reference assets. Evidence: `GptSovitsTtsProvider.cs`, `GptSovitsProfile`.
- [ ] **External dependency — ElevenLabs provider.** Requires key, voice/model availability, and network. Evidence: `ElevenLabsTtsProvider.cs`.
- [ ] **External dependency — Fish Audio provider.** Requires key/model and network. Evidence: `FishAudioTtsProvider.cs`.
- [ ] **External dependency — OpenAI TTS provider.** Requires an OpenAI key and network. Evidence: `OpenAiTtsProvider.cs`.
- [x] **Implemented — Voice settings expose all five TTS choices and provider-specific configuration.** Evidence: `SettingsWindow.xaml(.cs)`.

### STT and voice input

- [x] **Implemented — microphone capture, global hotkey flow, direct Whisper STT, and direct Gemini STT.** Evidence: `VoiceInputService.cs`, `GlobalHotkeyService.cs`, `WhisperSttService.cs`, `GeminiSttService.cs`.
- [ ] **Partial — WPF-to-sidecar STT contract.** `BackendSttService` sends multipart `file`/`language` fields, while `/stt/transcribe` validates a JSON `SttRequest` containing `audio_base64`, `provider`, and `language`; normal backend transcription therefore fails before provider execution.
- [ ] **Partial — sidecar Whisper credential/config path.** The route passes `anthropic_api_key` to the OpenAI Whisper provider, `Settings` has no `openai_api_key`, and WPF exposes no effective sidecar OpenAI-key synchronization.
- [ ] **Partial — live backend config synchronization.** WPF posts only `{status: "sync"}` and the route mutates a newly created Settings instance, so running agent/provider objects do not receive changed keys/preferences. Process launch also uses unprefixed Tavily/OpenWeather variables and `AEMEATH_INTERNAL_PORT`, which do not match the sidecar's `AEMEATH_` field names.

### Screen and activity awareness (four modes)

- [x] **Implemented — opt-in periodic screen capture, active indicator, protected-window checks, configurable interval, commentary, and observation buffering.** Evidence: `ScreenAwarenessService.cs`, `ScreenCaptureService.cs`, Screen settings tab, `PetWindow` badge/timer.
- [x] **Implemented — Gemini, Claude, Ollama, and local/cloud hybrid dispatch paths.** WPF names hybrid `local_hybrid`; Python names it `hybrid`. Evidence: `ScreenAwarenessService.cs`, `python-backend/aemeath_agent/vision/`.
- [ ] **External dependency — cloud/local vision execution.** Gemini/Claude require keys/network; Ollama and hybrid require a compatible local model server, with hybrid also requiring a cloud provider for the second stage.
- [x] **Implemented — wired periodic privacy/cost pipeline.** Protected-window and configured app/title blacklist gates, fullscreen skip, configurable downscale, perceptual-change deduplication, approximate monthly budget tracking/gating, and response PII scanning are consumed by `ScreenAwarenessService`.
- [ ] **Partial — dormant screen-privacy settings.** `PrivacyTier`, `UseLocalPreFilter`, `BlurTaskbar`, and `BlurAddressBar` are persisted but are not read by the capture/analysis pipeline; do not claim local prefiltering or taskbar/address-bar blur until they affect runtime behavior.
- [x] **Implemented — Activity Monitor and screen observations can influence opt-in idle commentary and enter the short-lived observation buffer.** Evidence: `PetWindow.xaml.cs`, `ActivityMonitorService.cs`.

## Milestone 6 — Optional Python Agent, RAG, and MCP

### Sidecar lifecycle and APIs

- [x] **Implemented — FastAPI application, loopback default, lifespan startup, and READY signal.** Evidence: `python-backend/aemeath_agent/main.py`.
- [x] **Implemented — health, config, agent REST/SSE, STT, vision, RAG, and memory routers.** Evidence: `python-backend/aemeath_agent/api/`.
- [ ] **Partial — WPF process-manager lifecycle and port selection.** Development/bundled discovery, health polling, retries, and shutdown exist at the default port, but the manager sets `AEMEATH_PORT` without passing `--port`; argparse ignores that environment value and starts on 18900, so a non-default `Backend.Port` fails health checks.
- [x] **Implemented — WPF internal loopback API for stats, screen, music, and pet state.** Evidence: `Services/InternalApiServer.cs`.
- [ ] **Partial — loopback security.** Both API surfaces are unauthenticated; local callers are not authorized with a token or operating-system identity.
- [ ] **Partial — bundled sidecar mode.** A PyInstaller build script and discovery convention exist, but the normal release does not build or include the sidecar.

### LangGraph and 11 tools

- [x] **Implemented — LangGraph agent creation, character/tool prompts, checkpointer, and persistent JSON-backed store.** Evidence: `agent/graph.py`, `agent/prompts.py`, `agent/checkpointer.py`, `agent/memory_store.py`.
- [x] **Implemented — 11 tools are registered:** `search_web`, `get_weather`, `manage_todo`, `read_screen`, `control_music`, `get_pet_stats`, `rag_retrieve`, `get_system_info`, `save_memory`, `update_user_block`, and `retrieve_memory`. Evidence: `tools/__init__.py`.
- [ ] **External dependency — web search and weather.** Tavily/OpenWeatherMap need valid keys and network.
- [ ] **External dependency — WPF bridge tools.** Screen, music, and stats tools require the running internal WPF API.
- [x] **Implemented — to-do CRUD and system-information tools have local implementations.** Evidence: `tools/todo.py`, `tools/system_info.py`.
- [ ] **Partial — RAG agent tool startup.** `rag_retrieve` is registered but its retriever is not configured by `get_all_tools`, so normal agent calls cannot rely on it.

### RAG

- [x] **Implemented — PDF, DOCX, text, and directory ingestion plus chunking.** Evidence: `rag/ingestion.py`.
- [x] **Implemented — Gemini or local embeddings and persistent Chroma vector store.** Evidence: `rag/vectorstore.py`, `config.py`.
- [x] **Implemented — BM25/semantic ensemble retrieval and cross-encoder reranking.** Evidence: `rag/retriever.py`.
- [x] **Implemented — `/rag/ingest`, `/rag/query`, and `/rag/status` routes.** Evidence: `api/routes_rag.py`.
- [ ] **Partial — production RAG integration.** Complete the agent-tool configuration, packaged model/dependency verification, and a user-facing ingestion workflow.

### MCP

- [x] **Implemented — stdio JSON-RPC MCP client class supporting initialize, list tools, and call tool.** Evidence: `Services/McpClientService.cs`.
- [x] **Implemented — pet MCP tool definitions for status, feed, animation, and message.** Evidence: `Services/McpServer/AemeathPetTools.cs`.
- [x] **Implemented — MCP settings tab and persisted client/server definitions.** Evidence: `SettingsWindow.xaml(.cs)`, `McpConfig`.
- [ ] **Partial — MCP runtime wiring.** No application startup/shutdown path creates configured clients, exposes the server, or forwards live external MCP tools to chat/agent execution.
- [ ] **Partial — MCP end-to-end verification.** Connect a real stdio server/client and prove a live tool invocation changes/reads pet state.

## Milestone 7 — Memory System

### Implemented foundation

- [x] **Implemented — C# core-memory, procedural-memory, observation, and assembled-context models.** Evidence: `Models/CoreMemory.cs`, `ProceduralMemory.cs`, `ObservationEntry.cs`, `MemoryContext.cs`.
- [x] **Implemented — local JSON services for core, procedural, and observation memory.** Evidence: `CoreMemoryService.cs`, `ProceduralMemoryService.cs`, `ObservationBufferService.cs`.
- [x] **Implemented — observation buffer persistence and 24-hour expiry.** Evidence: `ObservationEntry.IsExpired`, `ObservationBufferService.PurgeExpired`.
- [x] **Implemented — screen/activity observations enter the buffer and a 30-minute WPF timer submits them for distillation.** Evidence: `PetWindow.xaml.cs`, `MemoryBridgeService.SubmitObservationsAsync`.
- [x] **Implemented — completed chat turns are submitted to `/memory/extract`.** Evidence: `ChatViewModel.SendCoreAsync`, `MemoryBridgeService.SubmitForExtraction`.
- [x] **Implemented — Python JSON-persistent semantic namespaces and USER BLOCK.** Evidence: `agent/memory_store.py`.
- [x] **Implemented — episodic Chroma collection `aemeath_memories`.** Evidence: `rag/memory_vectorstore.py`.
- [x] **Implemented — six memory routes:** extract, retrieve, distill, core update, status, and forget. Evidence: `api/routes_memory.py`.
- [x] **Implemented — memory tools for save, USER BLOCK update, and retrieval.** Evidence: `tools/save_memory.py`, `update_user_block.py`, `retrieve_memory.py`.
- [x] **Implemented — memory-aware C# prompt builder overload and bridge context assembler.** Evidence: `ChatPromptBuilder.cs`, `MemoryBridgeService.GetMemoryContextAsync`.

### Integration and correctness gaps

- [ ] **Partial — direct-provider memory injection.** `ChatViewModel` does not call `GetMemoryContextAsync`; Claude, Gemini, and proxy paths do not use the memory-aware prompt overload.
- [ ] **Partial — C# core synchronization.** `/memory/extract` and `/memory/core/update` write Python stores but do not automatically update canonical `core_memory.json`.
- [ ] **Partial — procedural persistence workflow.** Models and JSON persistence exist, but recurring patterns, preferences, and scheduled events are not learned and written through a complete runtime path.
- [ ] **Partial — observation distillation results.** Distilled memories reach Chroma, but returned patterns do not update procedural memory.
- [ ] **Partial — session summarization and consolidation.** No complete lifecycle summarizes long sessions, merges duplicates/conflicts, or ages memories.
- [ ] **Partial — live USER BLOCK refresh.** The block is injected when the agent is built; updating it does not refresh the active system prompt until agent recreation.
- [ ] **Partial — retrieval completeness.** The bridge retrieval route searches Chroma only; it does not combine the Python JSON fact/preference store with episodic results.
- [ ] **Partial — core update semantics.** The route appends new fact/preference records and ignores event synchronization instead of performing documented category conflict resolution/mirroring.
- [ ] **Partial — forget correctness.** `time_range` is ignored, and Chroma deletion likely cannot find IDs because stored document metadata does not include the ID read by the deletion code.
- [ ] **Planned — user memory UI and commands.** Add inspect, correct, delete/forget, privacy explanation, and storage reset controls.
- [ ] **Planned — end-to-end direct and sidecar memory acceptance tests.** Prove a fact learned in one session is retrieved after restart, used by each provider path, corrected, and deleted from every store.

## Milestone 8 — Quality, CI, Release, and Documentation

- [x] **Implemented — xUnit test project mirrors model, engine, service, contract, and view-model areas.** Evidence: `tests/AemeathDesktopPet.Tests/` and its `.csproj`.
- [x] **Implemented — pytest suites cover APIs, tools, providers, RAG, bridge, graph, and memory layers.** Evidence: `python-backend/tests/` and `pyproject.toml`.
- [x] **Implemented — CI runs .NET Release restore/build/tests with coverage on Windows.** Evidence: `.github/workflows/ci.yml`.
- [x] **Implemented — CI runs Python tests with coverage on Ubuntu and Python 3.12.** Evidence: `.github/workflows/ci.yml`.
- [ ] **Partial — formatting gate.** `dotnet format --verify-no-changes` runs with `continue-on-error: true`; Python Ruff is documented locally but is not run by CI.
- [ ] **Partial — coverage policy.** Coverage artifacts are generated/uploaded, but no minimum threshold is enforced.
- [x] **Implemented — tag release builds/tests and publishes a self-contained single-file win-x64 WPF archive.** Evidence: `.github/workflows/release.yml`.
- [ ] **Partial — complete release packaging.** The release archive contains only WPF output; it does not build/bundle/verify the optional Python sidecar or its heavyweight models.
- [x] **Implemented — package membership/version authority resides in `.csproj` and `pyproject.toml`.** Documentation should reference manifests instead of duplicating dependency versions as facts.
- [ ] **Partial — non-functional evidence.** CPU, memory, startup, drag FPS, disk footprint, and Z-order goals remain unmeasured targets; follow the methods in `REQUIREMENTS.md`.
- [ ] **Partial — Windows manual acceptance matrix.** Still required for DPI/multi-monitor behavior, fullscreen, tray lifecycle, global hotkeys, audio devices, external providers, local model servers, edge poses, and loopback exposure.
- [x] **Implemented — requirements and ledger reconciled to the current working tree.** Evidence: `REQUIREMENTS.md` and this file, dated 2026-07-22.

## Future Product Work

- [ ] **Planned — mini-games:** rock-paper-scissors, catch-the-star, and deeper focus/Pomodoro play.
- [ ] **Asset placeholder — special animations:** sleep, edge poses, speaking, cat-lap/pet-cat, transformation, dance, morning/night, and plane-specific sequences.
- [ ] **Planned — optional sound effects:** interaction sounds, humming, and cat sounds with mute/volume integration.

## Change History

- **2026-07-22:** Rebuilt the checklist as an evidence-based implementation ledger. Corrected the eight settings tabs, five TTS providers, four vision modes, 11 agent tools, icon/assets, CI/release behavior, and engine-versus-runtime distinctions. Added the Memory milestone and left paper-plane rendering, edge poses, throw physics, fullscreen behavior, MCP wiring, RAG tool configuration, sidecar packaging, STT/config synchronization, and memory lifecycle gaps explicitly partial or planned.
- **2026-07-22 (verification revision):** Marked backend STT and non-default app-managed sidecar ports nonfunctional, removed completion claims for dormant local-prefilter/blur settings, and enumerated only the privacy/cost layers used by the periodic screen pipeline.

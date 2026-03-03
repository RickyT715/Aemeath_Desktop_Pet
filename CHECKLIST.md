# Aemeath Desktop Pet - Implementation Checklist

## Phase 1: Core Pet
> Transparent window, sprite rendering, physics, drag/drop, system tray

### 1.1 Project Setup
- [x] Create .NET 8 WPF solution (`AemeathDesktopPet.sln`)
- [x] Create main project (`AemeathDesktopPet.csproj`)
- [x] Create folder structure (Views, ViewModels, Models, Engine, Services, Interop, Resources)
- [x] Add NuGet packages: `Hardcodet.NotifyIcon.Wpf`, `Microsoft.Data.Sqlite`, `System.Drawing.Common`
- [x] Add `app.manifest` with `PerMonitorV2` DPI awareness
- [x] Organize existing GIF assets into `Resources/Sprites/Aemeath/`
- [x] Create `AemeathTheme.xaml` resource dictionary with color palette

### 1.2 Win32 Interop
- [x] `Win32Api.cs` — P/Invoke: `SetWindowLong`, `GetWindowLong`, `WS_EX_TRANSPARENT`, `WS_EX_TOOLWINDOW`
- [ ] Hit-test based click-through (transparent pixels pass through, opaque pixels receive input)
- [x] `EnumWindows`, `GetWindowRect`, `DwmGetWindowAttribute` for environment detection
- [x] Screen bounds and taskbar detection

### 1.3 Pet Window
- [x] `PetWindow.xaml` — `AllowsTransparency`, `WindowStyle=None`, `Topmost`, `ShowInTaskbar=False`
- [x] Remove from Alt+Tab via `WS_EX_TOOLWINDOW`
- [x] 200x200 default size, configurable (150/200/250)
- [x] Opacity binding

### 1.4 Animation Engine
- [x] `AnimationEngine.cs` — GIF frame decoder (extract frames from GIF to `BitmapSource[]`)
- [x] Frame index tracker, FPS timer, loop/one-shot modes (combined into AnimationEngine)
- [x] Pre-load all GIF assets on startup (cache `BitmapSource` arrays)
- [x] Support 9 FPS standard and 25 FPS premium (`listening_music`)
- [x] Horizontal mirror for `FLY_LEFT` (flip `normal_flying` frames)
- [x] Dirty-flag rendering — skip frame swap when nothing changes
- [x] Graceful fallback for missing GIFs (use `normal.gif` as default)

### 1.5 Behavior Engine (FSM)
- [x] `PetState` enum — `IDLE`, `FLY_LEFT`, `FLY_RIGHT`, `FALL`, `DRAG`, `THROWN`, `LANDING`, `WAVE`, `LAUGH`, `SIGH`, `PET_HAPPY`
- [x] `BehaviorEngine.cs` — FSM with weighted-random idle transitions
- [x] Behavior cycle timer (every 5-10 seconds, pick next state)
- [x] State-to-animation mapping table
- [x] State duration tracking (min/max duration per state)

### 1.6 Physics Engine
- [x] `PhysicsEngine.cs` — gravity constant, velocity, position
- [x] Screen edge collision (bounce off left/right/bottom screen edges)
- [x] Landing detection (bottom of screen = "ground" surface)
- [x] Bounce on impact with configurable restitution
- [x] Hover height offset (default 50px above taskbar for flying idle)

### 1.7 Drag & Drop
- [x] Mouse down on pet → enter `DRAG` state, capture mouse
- [x] Track mouse velocity during drag (for throw calculation)
- [x] Mouse up → `THROWN` if velocity > threshold, else `FALL`
- [x] `FALL` → gravity until landing → `LANDING` → `IDLE`

### 1.8 Basic Interactions
- [x] Left-click → `WAVE` (play `happy_hand_waving.gif`, return to previous state)
- [x] Mouse hover > 2s → `PET_HAPPY` (play `happy_jumping.gif`)
- [x] Right-click → context menu (basic: Settings, Minimize to Tray, Quit)

### 1.9 System Tray
- [ ] Tray icon (placeholder .ico — Aemeath chibi face) *(needs .ico file)*
- [x] Tray menu: Show/Hide, Settings, Quit
- [x] Minimize to tray on close (configurable)
- [x] Double-click tray icon → show pet

### 1.10 Configuration
- [x] `AppConfig` model class matching `config.json` schema
- [x] `ConfigService.cs` — load/save JSON from `%LOCALAPPDATA%\AemeathDesktopPet\`
- [x] Create default config on first run
- [x] Remember pet position between sessions

### 1.11 Environment Detector
- [x] `EnvironmentDetector.cs` — screen bounds, taskbar position/height
- [x] Fullscreen detection (hide pet when fullscreen app is active)
- [x] Basic `EnumWindows` for window list (used later by WindowEdgeManager)

---

## Phase 2: Black Cat Companion
> Independent cat FSM, following behavior, user interaction

### 2.1 Cat Sprite System
- [ ] Separate sprite layer/window for cat
- [ ] Cat animation loading (placeholder until cat GIFs are created)
- [ ] Cat size: ~80x80 rendered (40% of 200px Aemeath)

### 2.2 Cat Behavior Engine
- [ ] `CatBehaviorEngine.cs` — independent FSM
- [ ] `CatState` enum: `CAT_IDLE`, `CAT_WALK`, `CAT_NAP`, `CAT_GROOM`, `CAT_WATCH`, `CAT_STARTLED`, `CAT_PURR`, `CAT_RUB`
- [ ] Cat follows Aemeath with 40-80px offset and 0.3-0.5s delay
- [ ] Cat wanders within 200px radius when Aemeath is idle
- [ ] Cat stays grounded (doesn't fly with Aemeath during drag/fall)
- [ ] Cat watches Aemeath during drag/fall with big eyes

### 2.3 Cat Interactions
- [ ] Click on cat → `CAT_PURR` with heart particles
- [ ] Cat reacts to Aemeath's glitch → `CAT_STARTLED`
- [ ] Cat rubs against Aemeath after she lands hard
- [ ] Enable/disable cat in settings

---

## Phase 2b: Window Edge Interaction
> Win32 window detection, edge behaviors, visual clipping

### 2b.1 Window Edge Manager
- [ ] `WindowEdgeManager.cs` — accurate window bounds via `DwmGetWindowAttribute(DWMWA_EXTENDED_FRAME_BOUNDS)`
- [ ] `SetWinEventHook(EVENT_OBJECT_LOCATIONCHANGE)` for real-time window tracking
- [ ] Polling fallback: 100ms when on window, 500ms otherwise
- [ ] Filter invisible windows via `DWMWA_CLOAKED` (virtual desktops)
- [ ] DPI-aware coordinates (`PerMonitorV2`)

### 2b.2 Edge Behaviors
- [ ] `LIE_ON_WINDOW` — pet sits on window title bar, position tracks window
- [ ] `PEEK_EDGE` — half-body hidden behind screen edge, `RectangleGeometry.Clip`
- [ ] `HIDE_TASKBAR` — only head/halo visible above taskbar
- [ ] `CLING_EDGE` — clinging to vertical screen edge
- [ ] Fall-on-minimize: detect window minimize/close → trigger `FALL`
- [ ] Fullscreen detection → hide pet or move to edge

---

## Phase 3: Paper Planes
> Thrown planes, ambient planes, cat chases

### 3.1 Paper Plane System
- [ ] `PaperPlaneSystem.cs` — manages active paper planes
- [ ] Thrown plane: parabolic trajectory + sinusoidal wobble, 300-600px range
- [ ] Throw action: Aemeath fold animation → throw animation → plane launches
- [ ] Plane despawns after 2-3s with fade
- [ ] Cat reacts: ears perk → chase → pounce at landing spot

### 3.2 Ambient Planes
- [ ] Timer-based spawn (every 3-8 min, configurable)
- [ ] Enter from random screen edge, drift across with sinusoidal path
- [ ] Semi-transparent (70% opacity), white with blue fold lines
- [ ] Max 1 ambient plane active at a time
- [ ] Cat has 40% chance of chasing if idle and plane is nearby (<150px)
- [ ] Click on ambient plane → spin + trajectory change (easter egg)

### 3.3 Context Menu Integration
- [ ] "Throw a Paper Plane" menu item triggers throw action

---

## Phase 4: Personality & Effects
> Singing, glitch, sleep, speech bubbles, time awareness

### 4.1 Aemeath Personality Behaviors
- [ ] `SING` state with `listening_music.gif` (premium 25 FPS)
- [ ] `SIGH` state with `sign.gif` (low mood/energy)
- [ ] `SLEEP` state (placeholder animation until new art)
- [ ] `LOOK_AT_USER` state — "Did you see me?" speech bubble
- [ ] `PET_CAT` state — Aemeath pets the cat
- [ ] `CAT_LAP` state — combined cat-in-lap idle

### 4.2 Glitch Effect
- [ ] Random trigger: 2-5% chance per behavior cycle
- [ ] Duration: 300-800ms
- [ ] Horizontal slice displacement (4-8 bands, 2-6px offset)
- [ ] RGB channel offset (R/G/B at 1-2px different directions)
- [ ] Opacity flicker (100% → 40% → 100%)
- [ ] Scanline overlay sweep
- [ ] Cat reacts with `CAT_STARTLED`

### 4.3 Particle System
- [ ] `ParticleSystem.cs` — object pool, max 12 particles
- [ ] Music notes (♪) — float upward during singing
- [ ] Sparkle stars (✦) — on wave, happy, etc.
- [ ] Hearts (♡) — pet reaction, cat purr
- [ ] Sleep bubbles (Zzz)
- [ ] Cat paw prints — appear/fade behind walking cat

### 4.4 Speech Bubbles
- [ ] `SpeechBubble.xaml` — themed bubble with holographic blue border
- [ ] Semi-transparent white background, 12px corner radius
- [ ] Paper plane silhouette watermark in top-right corner
- [ ] Cat speech variant (thought bubble with paw print)
- [ ] Auto-fade: 4s normal, 8s AI responses
- [ ] Digital scanline overlay (2% opacity)

### 4.5 Time-of-Day Awareness
- [ ] Morning greeting behavior (6-10 AM)
- [ ] Night yawn/sleep behavior (10 PM - 6 AM)
- [ ] Halo/wing brightness adjusts with time of day

---

## Phase 5: AI Chat
> Claude API, chat window, streaming, memory

### 5.1 Claude API Integration
- [ ] `ClaudeApiService.cs` — Messages endpoint with streaming
- [ ] Aemeath system prompt (Section 6.1 of design doc)
- [ ] Dynamic state injection (mood, energy, affection, time)
- [ ] Model selection: Haiku (quick reactions), Sonnet (deep conversations)
- [ ] API key configuration in settings

### 5.2 Chat Window
- [ ] `ChatWindow.xaml` — dark theme (`#1E1E2E`), 380x520
- [ ] Custom title bar with star icon + cat silhouette
- [ ] Aemeath message bubbles (`#2A2A4A`, blue border)
- [ ] User message bubbles (`#3D2D4A`, pink border)
- [ ] Streaming text display with typing effect
- [ ] Paper plane send button with hover micro-animation
- [ ] Background star-field + faint paper plane drifts
- [ ] Empty state: cat batting paper plane illustration
- [ ] Scrollbar styling

### 5.3 Conversation Memory
- [ ] `MemoryService.cs` — SQLite conversation storage
- [ ] Session summaries for long-term context
- [ ] Persist across app restarts

### 5.4 Offline Fallback
- [ ] 80+ pre-scripted responses (greetings, idle, happy, sleepy, lonely, cat, planes)
- [ ] Categorized by trigger type and mood level
- [ ] Used when no API key or no internet

### 5.5 Chat Interaction
- [ ] Double-click pet → open chat window
- [ ] Chat window anchored near pet position
- [ ] `CHAT` state animation during conversation
- [ ] Speech bubbles for short AI replies

---

## Phase 5b: TTS Voice
> GPT-SoVITS, audio playback, voice settings

### 5b.1 TTS Voice Service
- [ ] `TtsVoiceService.cs` — HttpClient POST to GPT-SoVITS (`localhost:9880`)
- [ ] WAV stream response handling
- [ ] NAudio `WaveOutEvent` playback
- [ ] Queue system: one utterance at a time, new cancels current
- [ ] Speak AI chat responses aloud
- [ ] Speak scripted reactions (greetings, idle chatter)

### 5b.2 Cloud TTS Fallback
- [ ] ElevenLabs REST API integration
- [ ] Azure Neural Voice C# SDK integration (alternative)
- [ ] Provider selection in settings

### 5b.3 Voice Settings
- [ ] Voice tab in settings panel
- [ ] Enable/disable toggle
- [ ] Volume slider + mute toggle
- [ ] Per-trigger enable (chat replies, idle chatter)
- [ ] Auto-mute during fullscreen/meetings
- [ ] Voice reference file browser (for SoVITS training)

### 5b.4 Speaking Animation
- [ ] `SPEAKING` state — mouth animation synced to audio
- [ ] Transition from `CHAT` when TTS starts playing

---

## Phase 5c: Screen Awareness
> Screenshot capture, privacy pipeline, commentary

### 5c.1 Screenshot Capture
- [ ] `ScreenAwarenessService.cs` — `Graphics.CopyFromScreen()`
- [ ] Resize to 1280x720
- [ ] Configurable interval (default 60s)
- [ ] In-memory only, never saved to disk

### 5c.2 Tier 1: Application Blacklist
- [ ] Get foreground window title + process name
- [ ] Default blacklist: banking, password managers, medical, messaging
- [ ] User-defined blacklist in settings
- [ ] Skip during fullscreen apps
- [ ] Blocked → generic idle comment instead

### 5c.3 Tier 2: Local Vision Pre-Filter
- [ ] Ollama integration (Phi-3 Vision or Qwen2.5-VL-7B)
- [ ] Classify: "safe" / "contains sensitive data"
- [ ] Optional: generate text-only description locally
- [ ] Unsafe → skip cloud API

### 5c.4 Tier 3: Cloud Vision API
- [ ] Claude Sonnet 4.5 vision API call
- [ ] GPT-4o-mini vision as alternative
- [ ] Privacy prompt: comment on activity, never repeat text/numbers
- [ ] Optional blur of taskbar/address bar regions
- [ ] Response cache (perceptual hash dedup)

### 5c.5 Privacy & UX
- [ ] Opt-in only, disabled by default
- [ ] "Aemeath can see your screen" indicator badge
- [ ] One-click disable (context menu + tray)
- [ ] First-run warning modal
- [ ] Cost budget cap (daily/monthly)
- [ ] Screen Awareness tab in settings

### 5c.6 Commentary Integration
- [ ] `SCREEN_COMMENT` state — speech bubble with commentary
- [ ] Personality-driven commentary (fun, not surveillance-like)
- [ ] Rate limiting display (don't spam bubbles)

---

## Phase 6: Stats & Polish
> Stats system, stats popup, settings panel, offline decay

### 6.1 Stats System
- [ ] `AemeathStats` model — Mood, Energy, Affection (0-100)
- [ ] `StatsService.cs` — stat tracking, interaction boosts
- [ ] Offline decay with diminishing returns (floor: 30/20/40)
- [ ] Cat closeness stat
- [ ] Paper plane counter (lifetime stat)
- [ ] Stats affect behavior weights and animations

### 6.2 Stats Popup
- [ ] `StatsPopup.xaml` — dark theme, 320x420
- [ ] Gradient stat bars (Mood=pink, Energy=yellow, Affection=blue)
- [ ] Cat status line (current activity)
- [ ] Aemeath portrait + comment based on stats
- [ ] Time together counter, chat count, planes thrown

### 6.3 Settings Panel
- [ ] `SettingsWindow.xaml` — tabbed interface (General, Appearance, AI, Voice, Screen Awareness, About)
- [ ] General: start with Windows, close to tray, behavior frequency
- [ ] Appearance: pet size, opacity, glitch toggle
- [ ] Black Cat: enable toggle, cat name input
- [ ] Paper Planes: enable toggle, frequency slider
- [ ] AI: API key, model selection, singing bubbles
- [ ] Voice: all TTS settings (see Phase 5b)
- [ ] Screen Awareness: all SA settings (see Phase 5c)

### 6.4 Persistence
- [ ] `PersistenceService.cs` — SQLite for stats, conversations, memory
- [ ] JSON config save/load
- [ ] Return bonuses (affection boost after absence)
- [ ] Batch SQLite writes (every 60s)

---

## Phase 7: Extras
> Mini-games, special animations, sound effects

### 7.1 Mini-Games
- [ ] Rock-Paper-Scissors with Aemeath
- [ ] "Catch the Star" — click falling stars
- [ ] "Cat & Paper Plane" — cat chases planes
- [ ] Pomodoro focus timer with encouragement

### 7.2 Special Animations (when art available)
- [ ] Starlight transformation (dissolve into particles, reform)
- [ ] Morning greeting + stretch
- [ ] Night yawn
- [ ] Dance (idol moves)
- [ ] Exostrider figurine summon
- [ ] Cat brings gift (paper plane in mouth)
- [ ] Seal + cat interaction

### 7.3 Sound Effects (Optional)
- [ ] Humming/singing audio clips
- [ ] Click/interaction sounds
- [ ] Cat purr/meow sounds

---

## Non-Functional Verification
- [ ] CPU idle < 0.5%
- [ ] CPU animation < 2%
- [ ] Memory < 50 MB
- [ ] Startup < 3 seconds
- [ ] No Z-order flickering
- [ ] Graceful offline mode
- [ ] Battery mode detection (reduce activity)

---

## AI Architecture Overhaul

### AO-1: CI/CD + Code Quality Foundation

#### AO-1.1 Code Quality Files
- [x] `.editorconfig` — C# naming, indentation, formatting, Python section
- [x] `Directory.Build.props` — shared MSBuild: `EnableNETAnalyzers`, `AnalysisLevel=latest-recommended`, `Deterministic`, conditional `ContinuousIntegrationBuild`
- [x] Simplify both `.csproj` by removing duplicated props (TargetFramework, UseWPF, Nullable, ImplicitUsings)

#### AO-1.2 Enhanced CI Workflow
- [x] Concurrency group (cancel in-progress)
- [x] `dotnet format --verify-no-changes` step
- [x] Code coverage: `--collect:"XPlat Code Coverage"` + `ReportGenerator` + `CodeCoverageSummary`
- [x] Coverage artifact upload
- [x] Python pytest job (python-backend with Python 3.12)

#### AO-1.3 Release Workflow
- [x] `.github/workflows/release.yml` — trigger on `v*.*.*` tags
- [x] `dotnet publish` self-contained single-file win-x64
- [x] `softprops/action-gh-release@v2` with artifact upload

#### AO-1.4 README Badges
- [x] Build, .NET, Python, Platform, License badges

---

### AO-2: Python FastAPI Sidecar Backend

#### AO-2.1 Python Project Skeleton
- [x] `python-backend/pyproject.toml` + `requirements.txt`
- [x] `aemeath_agent/main.py` — FastAPI app, lifespan, `READY:{port}` stdout signal
- [x] `aemeath_agent/config.py` — Pydantic Settings (`AEMEATH_` env prefix)
- [x] `aemeath_agent/api/models.py` — Pydantic request/response schemas
- [x] `aemeath_agent/api/sse.py` — SSE event formatting helpers
- [x] `aemeath_agent/api/routes_health.py` — `GET /health`
- [x] `aemeath_agent/api/routes_config.py` — `POST /config/sync`
- [x] `aemeath_agent/api/routes_agent.py` — `POST /agent/stream` (SSE), `POST /agent/invoke`
- [x] `aemeath_agent/api/routes_stt.py` — `POST /stt/transcribe`
- [x] `aemeath_agent/api/routes_vision.py` — `POST /vision/analyze`
- [x] `aemeath_agent/api/routes_rag.py` — `POST /rag/ingest`, `POST /rag/query`, `GET /rag/status`

#### AO-2.2 C# BackendProcessManager
- [x] `Services/BackendProcessManager.cs` — auto-detect bundled exe vs dev mode
- [x] Watch stdout for `READY:{port}` signal
- [x] Health poll with exponential backoff (max 10s)
- [x] Crash recovery: `Process.Exited` → 3 retries with 5s delay
- [x] Events: `BackendReady`, `BackendCrashed`

#### AO-2.3 C# InternalApiServer
- [x] `Services/InternalApiServer.cs` using `HttpListener` on port 18901
- [x] `GET /internal/stats` — pet stats JSON
- [x] `GET /internal/screen` — screenshot base64
- [x] `POST /internal/music/control` — play/stop/next
- [x] `GET /internal/pet/state` — FSM state, pomodoro mode

#### AO-2.4 LangGraph Agent Core
- [x] `agent/graph.py` — `create_aemeath_agent()` with `create_react_agent`, model selection, 9 tools
- [x] `agent/prompts.py` — ported from C# `ChatPromptBuilder`, CHARACTER_PROMPT + TOOL_INSTRUCTIONS
- [x] `agent/checkpointer.py` — `AsyncSqliteSaver` at `%LOCALAPPDATA%`
- [x] `agent/memory_store.py` — LangGraph Store wrapper

#### AO-2.5 C# BackendAgentService
- [x] `Services/BackendAgentService.cs` implementing `IChatService`
- [x] `StreamMessageAsync()` — POST `/agent/stream`, SSE parsing (token/tool_call/tool_result/done)
- [x] `SendMessageAsync()` — POST `/agent/invoke`
- [x] Three-tier fallback: Python → Direct API → Offline

#### AO-2.6 Agent Tools (9+1 tools)
- [x] `tools/web_search.py` — Tavily search
- [x] `tools/weather.py` — OpenWeatherMap
- [x] `tools/todo.py` — SQLite CRUD
- [x] `tools/screen_reader.py` — calls C# `/internal/screen`
- [x] `tools/music_control.py` — calls C# `/internal/music/control`
- [x] `tools/pet_stats.py` — calls C# `/internal/stats`
- [x] `tools/rag_retrieval.py` — ChromaDB search
- [x] `tools/system_info.py` — psutil system info
- [x] `tools/save_memory.py` — LangGraph Store write
- [x] `tools/__init__.py` — `get_all_tools()` factory

#### AO-2.7 STT + Vision Migration
- [x] `stt/whisper_provider.py` + `stt/gemini_provider.py`
- [x] `vision/analyzer.py` (dispatcher), `gemini_vision.py`, `claude_vision.py`, `ollama_vision.py`, `hybrid_vision.py`
- [x] `Services/BackendSttService.cs` — `ISpeechToTextService` via Python
- [x] `Services/BackendVisionService.cs` — vision analysis via Python

#### AO-2.8 PetViewModel Integration
- [x] `PetViewModel.cs` — BackendProcessManager + InternalApiServer fields
- [x] `Initialize()` — start internal API, spawn Python in background
- [x] `CreateChatService()` — three-tier fallback (Backend → Direct API → Offline)
- [x] `Shutdown()` — stop Python, stop internal API

#### AO-2.9 Config + Settings UI
- [x] `AppConfig.cs` — `BackendConfig` (Enabled, Mode, Port, PythonPath, TavilyApiKey, etc.)
- [x] `SettingsWindow.xaml/.cs` — Backend tab with toggle, mode, ports, tool API keys, status indicator

#### AO-2.10 PyInstaller Build
- [x] `scripts/build_exe.py` — single-folder dist packaging

---

### AO-3: RAG Module

#### AO-3.1 Document Ingestion
- [x] `rag/ingestion.py` — `PyPDFLoader`, `Docx2txtLoader`, `TextLoader`, `DirectoryLoader`
- [x] `RecursiveCharacterTextSplitter` (1000 chars, 200 overlap)

#### AO-3.2 Embedding + Vector Store
- [x] `rag/vectorstore.py` — `gemini-embedding-001` (free), `all-MiniLM-L6-v2` offline fallback
- [x] ChromaDB persistent at `data/chromadb/`

#### AO-3.3 Hybrid Search + Reranking
- [x] `rag/retriever.py` — `EnsembleRetriever` (BM25 0.4 + semantic 0.6)
- [x] `CrossEncoderReranker` with `cross-encoder/ms-marco-MiniLM-L-6-v2` (retrieve 20 → top 5)

#### AO-3.4 RAG API
- [x] `POST /rag/ingest`, `POST /rag/query`, `GET /rag/status` routes

#### AO-3.5 RAG Agent Tool
- [x] `tools/rag_retrieval.py` — agent decides when to search knowledge base

---

### AO-4: MCP Integration

#### AO-4.1 MCP Client
- [x] `Services/McpClientService.cs` — JSON-RPC 2.0 over stdio (raw protocol, no SDK client)
- [x] `ConnectAsync` — launch process, send `initialize` + `notifications/initialized`
- [x] `ListToolsAsync` — `tools/list` request
- [x] `CallToolAsync` — `tools/call` request with parameter forwarding

#### AO-4.2 MCP Server
- [x] `Services/McpServer/AemeathPetTools.cs` — `[McpServerToolType]` with 4 tools
- [x] `GetPetStatus` — mood, energy, affection, lifetime stats
- [x] `FeedPet` — boost mood (1-100)
- [x] `PlayAnimation` — wave, laugh, sing, fly, sleep, happy, sigh
- [x] `SendMessage` — send message to pet chat
- [x] `ModelContextProtocol` NuGet 0.9.0-preview.2 (server SDK)

#### AO-4.3 Config + UI
- [x] `AppConfig.cs` — `McpConfig` (Enabled, ExposeAsServer, Servers list with `McpServerDefinition`)
- [x] `SettingsWindow.xaml/.cs` — MCP tab for server management (add/remove/connect)

---

### AO-5: Testing + Documentation

#### AO-5.1 Python Tests (pytest)
- [x] `tests/test_health.py` — health endpoint (status ok, version, uptime)
- [x] `tests/test_config.py` — Settings defaults, empty keys, factory
- [x] `tests/test_models.py` — all Pydantic schemas
- [x] `tests/test_sse.py` — SSE event formatting
- [x] `tests/test_prompts.py` — system prompt builder with context injection
- [x] `tests/test_tools.py` — system_info, todo CRUD
- [x] `tests/test_bridge.py` — WpfBridgeClient default/custom URL, offline behavior
- [x] `tests/test_vision.py` — unknown provider validation
- [x] `tests/test_rag.py` — splitter config, text splitting, supported formats

#### AO-5.2 C# Tests for New Services
- [x] `BackendProcessManagerTests.cs` — port config, IsReady, LastError, dispose, events
- [x] `InternalApiServerTests.cs` — constructor, dispose idempotent
- [x] `BackendAgentServiceTests.cs` — IsAvailable, offline fallback, streaming
- [x] `BackendSttServiceTests.cs` — IsAvailable, offline transcription
- [x] `BackendVisionServiceTests.cs` — IsAvailable, offline analysis
- [x] `BackendConfigTests.cs` — default values for BackendConfig, McpConfig, McpServerDefinition
- [x] `McpClientServiceTests.cs` — empty init, IsConnected, dispose, disconnect, list/call nonexistent

#### AO-5.3 CI Update
- [x] `ci.yml` — pytest job for Python backend tests
- [x] Coverage collection and reporting for C# tests

#### AO-5.4 README Updates
- [x] Architecture section with Mermaid C4 diagram
- [x] Three-tier fallback documentation
- [x] Python AI Backend section (tools table, RAG module, dev mode)
- [x] MCP Integration section (exposed tools, consuming external servers)
- [x] Badges (Build, .NET, Python, Platform, License)

#### AO-5.5 CHECKLIST.md Update
- [x] All AI Architecture Overhaul items documented and checked off

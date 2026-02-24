# Aemeath Desktop Pet - Requirements Document

## 1. Product Overview

**Aemeath Desktop Pet** is a Windows desktop companion application featuring Aemeath (爱弥斯) from Wuthering Waves. The pet lives on the user's desktop as a transparent, always-on-top animated character that idles, flies, reacts to interaction, and optionally converses via AI.

**Target Platform:** Windows 10/11 (x64)
**Framework:** .NET 8.0 WPF
**License:** Fan-made project. Character rights belong to Kuro Games.

---

## 2. Functional Requirements

### 2.1 Core Pet (Phase 1)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-1.1 | Transparent always-on-top window with no taskbar entry | Must | Done |
| FR-1.2 | GIF-based animation engine with frame caching and horizontal mirroring | Must | Done |
| FR-1.3 | 26-state finite state machine with weighted-random idle transitions | Must | Done |
| FR-1.4 | Physics engine: gravity, velocity, bounce, screen-edge collision | Must | Done |
| FR-1.5 | Drag-and-drop with throw velocity tracking | Must | Done |
| FR-1.6 | Left-click wave, hover happy jump reactions | Must | Done |
| FR-1.7 | Right-click context menu (Sing, Chat, Paper Plane, Call Cat, Stats, Settings, Quit) | Must | Done |
| FR-1.8 | System tray icon with menu (Show, Chat, Paper Plane, Settings, Quit) | Must | Done |
| FR-1.9 | Position and configuration persistence (JSON to %LOCALAPPDATA%) | Must | Done |
| FR-1.10 | Fullscreen app detection (auto-hide pet) | Should | Done |
| FR-1.11 | DPI awareness (PerMonitorV2) | Should | Done |
| FR-1.12 | Configurable pet size (150/200/250px) and opacity | Should | Done |

### 2.2 Black Cat Companion (Phase 2)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-2.1 | Independent cat character in separate transparent window (~80x80px) | Must | Done (emoji placeholder) |
| FR-2.2 | Cat FSM with 12 states (idle, walk, nap, groom, pounce, watch, rub, startled, purr, perch, chase, bat) | Must | Done |
| FR-2.3 | Cat follows Aemeath with 40-80px offset and lerp delay | Must | Done |
| FR-2.4 | Cat reacts to Aemeath events (drag, land, glitch, paper plane) | Must | Done |
| FR-2.5 | Click on cat triggers purr reaction | Should | Done |
| FR-2.6 | Enable/disable cat in settings | Should | Done |

### 2.3 Window Edge Interaction (Phase 2b)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-2b.1 | Detect nearby window title bars using EnumWindows + DWM APIs | Must | Done |
| FR-2b.2 | Pet can perch on window edges (position tracks window) | Must | Done |
| FR-2b.3 | Detect window close/minimize while perched, trigger fall | Must | Done |
| FR-2b.4 | Screen edge and taskbar proximity detection | Should | Done |
| FR-2b.5 | SetWinEventHook for real-time window tracking | Should | Done |

### 2.4 Paper Planes (Phase 3)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-3.1 | Throw paper plane from Aemeath position (parabolic + sinusoidal trajectory) | Must | Done |
| FR-3.2 | Ambient paper planes spawn every 3-8 minutes from random screen edge | Should | Done |
| FR-3.3 | Click on plane triggers spin + trajectory change | Should | Done |
| FR-3.4 | Cat chases landed planes | Should | Done |
| FR-3.5 | Configurable ambient plane frequency, enable/disable | Should | Done |

### 2.5 Personality & Effects (Phase 4)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-4.1 | Digital ghost glitch effect (opacity flicker, horizontal displacement, RGB split) | Must | Done |
| FR-4.2 | 2-5% trigger chance per 5-10 second behavior cycle, 300-800ms duration | Must | Done |
| FR-4.3 | Particle system: music notes, hearts, sparkles, sleep Z, paw prints (max 12) | Must | Done |
| FR-4.4 | Speech bubble with themed styling, auto-dismiss (4s normal, 8s AI) | Must | Done |
| FR-4.5 | Streaming text display in speech bubble (typing effect) | Should | Done |
| FR-4.6 | Time-of-day awareness: 5 periods (Morning, Day, Evening, Night, LateNight) | Should | Done |
| FR-4.7 | Conditional behavior weights (sleep at night, sigh when low mood, laugh when happy) | Should | Done |

### 2.6 AI Chat (Phase 5)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-5.1 | Claude API integration with SSE streaming | Must | Done (needs API key) |
| FR-5.2 | Aemeath-specific system prompt with dynamic state injection | Must | Done |
| FR-5.3 | Chat window: dark theme, 380x520, resizable, themed message bubbles | Must | Done |
| FR-5.4 | Conversation memory with JSON persistence (200-message cap) | Must | Done |
| FR-5.5 | Offline fallback with 75+ pre-scripted character responses | Must | Done |
| FR-5.6 | Contextual offline responses based on stats, time, and absence | Should | Done |
| FR-5.7 | Double-click pet to open chat window | Should | Done |

### 2.7 TTS Voice (Phase 5b)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-5b.1 | ITtsService interface for pluggable TTS providers | Must | Done (interface) |
| FR-5b.2 | GPT-SoVITS local TTS support | Should | Stub |
| FR-5b.3 | Cloud TTS fallback (ElevenLabs / Azure) | Could | Stub |
| FR-5b.4 | Voice settings tab in settings panel | Should | Done (UI only) |

### 2.8 Screen Awareness (Phase 5c)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-5c.1 | IScreenAwarenessService interface for pluggable vision providers | Must | Done (interface) |
| FR-5c.2 | Screenshot capture + privacy pipeline (3 tiers) | Should | Stub |
| FR-5c.3 | Screen awareness settings tab with privacy controls | Should | Done (UI only) |

### 2.9 Stats & Polish (Phase 6)

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-6.1 | Stats model: Mood, Energy, Affection (0-100) with offline decay | Must | Done |
| FR-6.2 | Interaction effects (chat +3 mood, pet +5 mood, sing +8 mood/-5 energy) | Must | Done |
| FR-6.3 | Stats popup with gradient bars and lifetime counters | Must | Done |
| FR-6.4 | 6-tab settings panel (General, Appearance, Music, AI, Voice, Screen) | Must | Done |
| FR-6.5 | Stats influence behavior weights via SetStatsContext() | Should | Done |

### 2.10 Extras (Phase 7) - Future

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-7.1 | Mini-games (Rock-Paper-Scissors, Catch the Star, Pomodoro) | Could | Not started |
| FR-7.2 | Special animations (transformation, dance, morning greeting) | Could | Not started |
| FR-7.3 | Sound effects (humming, click sounds, cat purr) | Could | Not started |

---

## 3. Non-Functional Requirements

| ID | Requirement | Target | Priority |
|----|-------------|--------|----------|
| NFR-1 | CPU usage while idle | < 0.5% | Must |
| NFR-2 | CPU usage during animation | < 2% | Must |
| NFR-3 | Memory usage | < 50 MB | Must |
| NFR-4 | Application startup time | < 3 seconds | Should |
| NFR-5 | No Z-order flickering with other windows | Zero flicker | Must |
| NFR-6 | Graceful offline mode (no API = offline responses) | Full offline | Must |
| NFR-7 | No data written outside %LOCALAPPDATA%\AemeathDesktopPet\ | Strict | Must |
| NFR-8 | Screen awareness screenshots never saved to disk | In-memory only | Must |
| NFR-9 | Smooth 60 FPS drag movement | 60 FPS | Should |
| NFR-10 | Animation frame rate matches source GIF (9-25 FPS) | Match source | Must |

---

## 4. System Requirements

### 4.1 Minimum

| Component | Requirement |
|-----------|-------------|
| OS | Windows 10 version 1903 or later |
| Runtime | .NET 8.0 Desktop Runtime |
| RAM | 4 GB (application uses < 50 MB) |
| Disk | ~30 MB (application + sprites) |
| Display | 1280x720 minimum, any DPI |

### 4.2 Recommended

| Component | Requirement |
|-----------|-------------|
| OS | Windows 11 |
| Runtime | .NET 8.0 Desktop Runtime |
| RAM | 8 GB |
| Display | 1920x1080, 100-150% DPI scaling |

### 4.3 For AI Chat Feature

| Component | Requirement |
|-----------|-------------|
| Internet | Required for Claude API |
| API Key | Anthropic API key (configured in Settings > AI) |

### 4.4 For TTS Feature (Future)

| Component | Requirement |
|-----------|-------------|
| Local TTS | GPT-SoVITS running on localhost:9880 |
| Cloud TTS | ElevenLabs or Azure API key |

### 4.5 For Screen Awareness Feature (Future)

| Component | Requirement |
|-----------|-------------|
| Local Vision | Ollama with Qwen2.5-VL-7B (8GB+ VRAM) |
| Cloud Vision | Claude/GPT-4o API key |

---

## 5. Dependencies

### 5.1 NuGet Packages

| Package | Version | Purpose |
|---------|---------|---------|
| Hardcodet.NotifyIcon.Wpf | 1.1.0 | System tray icon and notification |
| System.Drawing.Common | 8.0.0 | GIF frame extraction via System.Drawing.Imaging |

### 5.2 Framework Dependencies (included in .NET 8)

| Component | Purpose |
|-----------|---------|
| System.Text.Json | Configuration and persistence serialization |
| System.Net.Http | Claude API HTTP requests + SSE streaming |
| WindowsBase | WPF rendering, DispatcherTimer |
| PresentationCore | BitmapSource, WriteableBitmap, transforms |
| PresentationFramework | Window, UserControl, data binding |

### 5.3 Win32 APIs (P/Invoke)

| API | Purpose |
|-----|---------|
| SetWindowLong / GetWindowLong | WS_EX_TOOLWINDOW (hide from Alt+Tab) |
| EnumWindows / GetWindowRect | Window enumeration for edge detection |
| DwmGetWindowAttribute | Accurate window bounds, cloaked detection |
| SetWinEventHook | Real-time window move/resize tracking |
| SHAppBarMessage | Taskbar position and size |

---

## 6. Data & Privacy

### 6.1 Local Storage

All data stored in `%LOCALAPPDATA%\AemeathDesktopPet\`:

| File | Content | Sensitive |
|------|---------|-----------|
| config.json | User preferences, pet size, toggles | No |
| stats.json | Mood/Energy/Affection values, lifetime counters | No |
| messages.json | Chat conversation history (up to 200 messages) | Low |

### 6.2 Network Communication

| Destination | When | Data Sent |
|-------------|------|-----------|
| api.anthropic.com | AI chat (user-initiated) | Chat messages + system context (mood, time) |
| localhost:9880 | TTS (if configured) | Text to speak |
| Vision API (if configured) | Screen awareness (if enabled) | Screenshot (in-memory, not saved) |

### 6.3 Privacy Guarantees

- No telemetry or analytics
- No data collection without explicit user action
- API key stored locally in plaintext config (user responsibility)
- Screen awareness is opt-in only, disabled by default
- Screenshots are processed in-memory and immediately discarded
- Chat history stored locally only, never sent to third parties beyond the configured AI provider

---

## 7. Sprite Assets

### 7.1 Included (9 Aemeath GIFs + 1 Seal GIF)

| File | Canvas | FPS | Type |
|------|--------|-----|------|
| normal.gif | 200x200 | 9 | Idle loop |
| normal_flying.gif | 200x200 | 9 | Movement loop |
| happy_hand_waving.gif | 200x200 | 9 | One-shot |
| happy_jumping.gif | 200x200 | 9 | One-shot |
| laugh.gif | 200x200 | 9 | One-shot |
| laugh_flying.gif | 200x200 | 9 | One-shot |
| sign.gif | 200x200 | 9 | One-shot |
| listening_music.gif | 1000x1000 | 25 | Premium loop |
| seal.gif | 200x200 | 9 | Loop |

### 7.2 Missing (Needed for Full Experience)

| Asset | Current Workaround | Spec |
|-------|-------------------|------|
| Black cat sprite set (12 states) | Unicode emoji placeholder | ~80x80px GIFs, matching art style |
| Paper plane sprite | Unicode ✈ character | ~32x32px PNG or GIF |
| System tray icon | Missing (build warning) | .ico file, 16x16 to 256x256 multi-res |
| App icon | Missing | .ico file for window/taskbar |

---

## 8. Testing

### 8.1 Unit Tests

- **Framework:** xUnit 2.6.6 + Microsoft.NET.Test.Sdk 17.8.0
- **Test project:** `tests/AemeathDesktopPet.Tests/`
- **Test count:** ~80 tests across 18 test classes

| Area | Test Classes | Coverage |
|------|-------------|----------|
| Models | AemeathStatsTests, ChatMessageTests, CatStateTests, OfflineResponsesTests, PetStateTests, AnimationInfoTests, AppConfigTests | Defaults, clamp, decay math, enums, constructors |
| Engine | BehaviorEngineTests, PhysicsEngineTests, AnimationEngineTests, TimeAwarenessTests | FSM transitions, state mappings, physics bounds, time periods |
| Services | ConfigServiceTests, MusicServiceTests, JsonPersistenceServiceTests, StatsServiceTests, MemoryServiceTests | Round-trip persistence, interaction effects, context window |
| ViewModels | PetViewModelTests | Property changes, state transitions, public API no-throw |

### 8.2 Manual Testing Checklist

- [ ] Pet appears on screen, animates, flies around
- [ ] Drag and throw with physics bounce
- [ ] Context menu items all function
- [ ] Double-click opens chat window
- [ ] Chat window sends/receives messages (offline mode)
- [ ] Stats popup shows correct values
- [ ] Settings changes apply immediately
- [ ] Cat companion appears and follows pet
- [ ] Paper planes throw and fly
- [ ] Glitch effect triggers periodically
- [ ] Speech bubbles appear during idle
- [ ] System tray icon and menu work
- [ ] Minimize to tray on close
- [ ] Fullscreen detection hides pet
- [ ] Settings persist across restart
- [ ] Stats persist across restart

---

## 9. Glossary

| Term | Definition |
|------|-----------|
| Aemeath (爱弥斯) | Character from Wuthering Waves; digital ghost, virtual idol "Fleet Snowfluff" |
| FSM | Finite State Machine — behavior engine pattern |
| Glitch Effect | Signature visual: digital ghost artifact (opacity flicker, RGB split, displacement) |
| Exostrider | Aemeath's mechanical wings, always visible in sprites |
| GPT-SoVITS | Open-source voice cloning + TTS system |
| SSE | Server-Sent Events — streaming protocol used by Claude API |
| Shimeji | Genre of desktop pet applications that inspired this project's behavior engine |

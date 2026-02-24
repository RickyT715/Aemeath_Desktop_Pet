# Building a full-featured desktop pet for Windows

**C# with WPF or WinForms backed by Win32 interop is the proven, optimal tech stack** for a desktop pet application—delivering transparent click-through windows, smooth sprite animation at under 50 MB RAM, and native system tray integration. This conclusion is validated by eSheep64bit (~1,000 GitHub stars, available on the Microsoft Store), which uses exactly this approach. Combined with a data-driven animation state machine, Claude API for personality-rich chat, SQLite persistence, and a plugin architecture via .NET's Managed Extensibility Framework, a full-featured desktop pet can be built that runs all day at less than 1% CPU.

This report synthesizes findings across existing projects, tech stacks, animation systems, AI integration, UX patterns, plugin architecture, persistence, and performance—providing the foundation for SRS, SDD, and UI/UX design documents.

---

## Lessons from existing desktop pet projects

The desktop pet genre spans three decades, from the 1995 eSheep screen mate to 2025's AI-powered companions. Each generation reveals architectural patterns worth adopting—and pitfalls to avoid.

**Shimeji-ee** (Java AWT/Swing) remains the most influential open-source desktop pet. Its architecture separates behavior definitions (`behaviors.xml` with frequency-weighted random selection) from action definitions (`actions.xml` with pose sequences), creating a fully data-driven system. Each mascot runs as a `Mascot` object in a behavior loop, checking environmental conditions (floor, wall, ceiling, active windows) before selecting the next action. Shimeji pioneered window interaction—pets walk on title bars, climb window edges, and even "steal" windows. However, its Java dependency, **60%+ memory consumption** with many image sets loaded, and lack of a plugin system are significant weaknesses.

**eSheep64bit** (C# WPF, ~1,000 GitHub stars) proved that a single portable `.exe` can deliver a polished desktop pet experience. It uses sprite sheets with XML-defined animation state machines, WPF's built-in transparency (`AllowsTransparency="True"`), and supports multi-monitor setups with fullscreen detection. Its visual editor for creating custom pet animations is a standout feature. The codebase demonstrates that **WPF's DirectX-accelerated rendering pipeline handles sprite animation efficiently** while maintaining low resource usage.

**Desktop Mate** (Unity, commercial, released January 2025 on Steam) pushed desktop pets into 3D with VRM model support, but its Unity foundation creates GPU requirements and higher resource consumption. The modding community reverse-engineered it using MelonLoader, spawning **Mate Engine** (open-source, AGPL v3, 98% positive Steam reviews) which supports custom VRM models, Spotify-reactive dancing, and head tracking at ~200 MB RAM. This demonstrates strong user demand for extensibility.

**Desktop Goose** (C# WinForms, viral hit) validated that simple, personality-driven interactions—grabbing the mouse cursor, spawning notepad windows with messages, tracking mud across the screen—create memorable experiences. Its GDI+ rendering on a transparent overlay proves WinForms remains viable for lightweight 2D pets.

The most architecturally interesting modern project is **Desktop Homunculus** (Rust/Bevy ECS), which integrates ChatGPT conversations, VoiceVox speech synthesis, and a TypeScript SDK for building extensions via an HTTP API on `localhost:3100`. Its entity-component-system architecture and plugin model offer a glimpse of next-generation desktop pet design, though Windows transparency issues with the wgpu renderer limit its practicality. **CrabNebula's Koi Pond** (Tauri v2 + SolidJS) demonstrated that Tauri makes transparent, always-on-top, frameless windows trivial via configuration, but per-pixel click-through remains an open issue.

| Project | Stack | Animation | Behavior | RAM | Plugin System |
|---------|-------|-----------|----------|-----|---------------|
| Shimeji-ee | Java AWT | Individual PNGs | XML state machine | High (60%+) | None |
| eSheep64bit | C# WPF | Sprite sheets | XML state machine | Low (~20 MB) | XML customization |
| Desktop Mate | Unity | 3D VRM | Built-in | ~200 MB | Community mods |
| Desktop Goose | C# WinForms | Sprites/GDI+ | Hardcoded | Low | None |
| Koi Pond | Tauri/SolidJS | Frame animation | Click-follow | 30–50 MB | None |
| Homunculus | Rust/Bevy | 3D VRM + LLM | TypeScript SDK | Moderate | HTTP API + TS SDK |

---

## Why C# WPF wins the tech stack comparison

Every Windows desktop pet ultimately relies on the same Win32 API primitives: **`WS_EX_LAYERED`** for per-pixel alpha transparency, **`UpdateLayeredWindow`** for efficient sprite rendering, and **`WS_EX_TOPMOST`** for always-on-top behavior. The critical differentiator is how well each framework wraps these APIs—and at what resource cost.

**C# WPF** is the recommended primary stack for several reasons. It provides hardware-accelerated rendering via DirectX, built-in `AllowsTransparency` and `WindowStyle="None"` for frameless transparent windows, and the `Topmost` property for always-on-top behavior. For click-through, WPF requires Win32 P/Invoke (`SetWindowLong` with `WS_EX_TRANSPARENT`), but this is well-documented and straightforward. The animation system supports both `DispatcherTimer`-based frame updates and `CompositionTarget.Rendering` for physics-driven animation. Memory footprint sits at **20–40 MB** for a sprite-based pet, and the .NET ecosystem provides MEF for plugin architecture, SQLite via `Microsoft.Data.Sqlite`, and excellent Visual Studio tooling.

**C# WinForms with Win32 interop** is the alternative if absolute minimum memory is the priority. WinForms baseline is just **6–7 MB**, and eSheep64bit proves this works in production. The `TransparencyKey` approach is simpler than WPF's `AllowsTransparency`, and `UpdateLayeredWindow` with 32-bit ARGB bitmaps gives the best possible sprite rendering performance. The trade-off is no GPU acceleration (GDI+ only) and a less sophisticated UI toolkit for settings panels.

**Tauri** (Rust + WebView2) deserves mention for teams with web development experience. At **30–50 MB** memory and a **3–10 MB** installer, it's dramatically lighter than Electron. Transparent frameless windows work via simple configuration. However, **per-pixel click-through is not natively supported** (open GitHub issues #13070 and #2090), requiring workarounds like polygon-based hit regions via `tauri-plugin-polygon`. This is a dealbreaker for polished desktop pet interaction.

**Electron** should be avoided. Its **150–300 MB** baseline memory consumption (bundling full Chromium + Node.js) is unjustifiable for a sprite animation app. Discord, built on Electron, regularly hits 1–4 GB RAM. Click-through requires manual `setIgnoreMouseEvents` toggling, and transparent areas no longer auto-pass clicks after Electron v6.1.9.

**Godot** offers excellent animation tools (purpose-built for 2D sprites) and multi-window creativity, but transparency "sometimes works and sometimes doesn't" with intermittent black backgrounds—unacceptable for a 24/7 desktop utility. **Flutter Desktop** lacks native transparent window support entirely (labeled P3 "less important" in Flutter's issue tracker).

| Capability | WPF | WinForms+Win32 | Tauri | Electron |
|------------|-----|----------------|-------|----------|
| Transparent window | Native | Native | Config-based | Config-based |
| Per-pixel click-through | Win32 interop | Native layered | Missing | Workaround |
| Idle memory | 20–40 MB | 10–20 MB | 30–50 MB | 150–300 MB |
| GPU-accelerated animation | Yes (DirectX) | No (GDI+) | Yes (WebView2) | Yes (Chromium) |
| System tray | Via Hardcodet lib | Built-in NotifyIcon | Plugin | Built-in Tray |
| Plugin ecosystem | MEF/.NET | MEF/.NET | Rust traits + JS | npm packages |
| Installer size | 5–15 MB | 1–5 MB | 3–10 MB | 50–150 MB |

---

## Sprite animation architecture and state machines

Desktop pet animation combines two systems: a **rendering pipeline** that displays sprite frames, and a **behavior engine** that decides which animation to play and when.

**Pixel art sprite sheets** are the industry standard for desktop pets. A single PNG atlas contains all animation frames, with a JSON metadata file specifying each frame's source rectangle, duration, and anchor point. Aseprite ($20) is the standard creation tool, exporting sprite sheets with frame tags that map directly to animation states. The Aseprite JSON format includes per-frame `duration` in milliseconds, `frameTags` with named sequences (idle, walk, sleep), and `spriteSourceSize` for trimmed sprites. Frame rates of **8–15 FPS** are standard for pixel art charm—eSheep uses 100–250 ms per frame (4–10 FPS), while Shimeji specifies duration per pose in milliseconds.

The recommended animation data format for a desktop pet:

```json
{
  "spriteSheet": "pet_sprites.png",
  "frameWidth": 64, "frameHeight": 64,
  "animations": {
    "idle": { "frames": [0,1,2,3], "durations": [200,200,200,200], "loop": true },
    "walk_right": { "frames": [4,5,6,7,8,9], "durations": [100,100,100,100,100,100], "loop": true, "velocity": {"x":2,"y":0} },
    "fall": { "frames": [20,21], "durations": [150,150], "loop": true },
    "drag": { "frames": [22,23], "durations": [200,200], "loop": true }
  }
}
```

For the behavior engine, a **finite state machine (FSM) combined with weighted-random behavior selection** is the proven approach. Shimeji's architecture—which separates "what animations exist" (actions) from "when to trigger them" (behaviors with frequency weights and environmental conditions)—has been replicated across virtually every successful desktop pet. The FSM handles animation states (idle, walk, fall, drag) with `OnEnter`/`OnUpdate`/`OnExit` callbacks, while the behavior selector uses probability weights and condition checks (Is the pet on the floor? Near a screen edge? On a window border?) to choose the next action.

**Mandatory states** every desktop pet must implement, following Shimeji convention: **idle, walk, fall, drag, and thrown**. Additional states—sit, sleep, eat, happy, sad, pet_reaction, climb_wall, chase_mouse—add personality. Transitions between states can be immediate or use bridging animations (a "turn" sprite between walk_left and walk_right). Priority ordering ensures drag always overrides idle, and fall always overrides walk.

Skeletal animation systems like Spine 2D offer smooth interpolation and require fewer art assets, but benchmarks show **Spine at 7–10 FPS with 300 objects versus 60 FPS for sprite sheets**. For a desktop pet where charm matters more than smoothness, pixel art sprite sheets win decisively.

The physics system is intentionally simple: a gravity constant (~2 pixels/frame) applied when the pet lacks ground support, surface detection checking whether the pet's anchor point sits on the screen floor/taskbar/window edge, and bounce dampening (velocity × 0.5–0.7 on impact) when dropped. Shimeji's environment model tracks named boundaries—`floor`, `ceiling`, `workArea`, `activeIE.leftBorder`—enabling condition-based behavior selection.

---

## How to integrate Claude API for pet personality

The AI chat system transforms a desktop pet from a novelty into a companion. The architecture uses a **three-tier approach**: Claude API for rich conversations, an optional local LLM for offline fallback, and pre-scripted responses as the final safety net.

**Claude API integration** centers on the system prompt, which defines the pet's entire personality. The `system` parameter in the Messages API (`POST https://api.anthropic.com/v1/messages`) establishes character traits, speaking style, behavioral boundaries, and dynamic state injection. A well-crafted system prompt includes personality definition (playful, curious, speaks in short sentences), behavioral rules (never breaks character, uses asterisk emotes like `*wags tail*`), and the pet's current state (mood, hunger, energy levels) injected dynamically with each API call.

**Prompt caching** is critical for cost management. Since the persona definition is static, caching the system prompt yields **90% savings** on input tokens (cache hits cost 0.1× base rate). Only the dynamic state section changes between calls. For a pet making ~100 short exchanges per day with **Claude Haiku** (~200 input + 100 output tokens each), estimated daily cost is **$0.02–$0.05**. Model routing—Haiku for greetings and quick reactions, Sonnet for complex conversations—further optimizes spend.

Streaming responses via the API's `stream: true` parameter enables a natural typing effect in speech bubbles, with `content_block_delta` events feeding text character-by-character to the UI.

**Memory architecture** uses three tiers. Short-term memory keeps the last 10–15 messages in the active context window. Medium-term memory generates session summaries via the LLM after each conversation, storing them with timestamps in SQLite. Long-term memory uses vector embeddings (via a local embedding model like `nomic-embed-text` through Ollama, or a lightweight library like `hnswlib`) for semantic retrieval of relevant past facts. Before each API call, the system searches semantic memory for context relevant to the current message and includes it in the prompt.

**Emotional state awareness** is achieved by formatting the pet's current stats into the system prompt with behavioral guidelines: when hungry (hunger < 30), the pet mentions food and acts less playful; when tired (energy < 30), it yawns and speaks sleepily; when happy (mood > 70), it's bouncy and suggests games. Combined emotional states create nuanced behavior—happy + tired yields content but sleepy warmth, while sad + hungry produces plaintive neediness.

For **offline fallback**, the recommended hybrid architecture routes through three layers: (1) check internet connectivity → cloud API with Claude, (2) if offline and local model available → Ollama with Phi-3 Mini or Llama 3.2 3B (~2 GB model, runs on 4–6 GB RAM), (3) if no model available → pre-scripted responses categorized by emotional state and trigger type. Fifty to one hundred pre-written responses per category provides sufficient variety for offline operation. All offline interactions queue for memory extraction when connectivity returns.

**Safety** relies on Claude's built-in Constitutional AI guardrails, reinforced by system prompt rules (family-friendly, no character breaks, confused-pet response to inappropriate requests) and lightweight output validation (length checks, character consistency detection, keyword scanning).

---

## Desktop pet UX patterns that work

The pet's desktop interaction defines its personality more than any other system. Five interaction patterns are essential.

**Walking and environmental awareness** requires the pet to recognize and traverse screen surfaces. The pet walks along the screen bottom (taskbar), climbs left/right screen borders, and walks on the upper boundaries of open windows. Window detection uses Win32's `EnumWindows` and `GetWindowRect` APIs, throttled to every 500 ms–1 second for performance. Each surface is represented as a boundary object with position and type (floor, wall, ceiling), enabling condition-based behavior selection. Multi-monitor support uses `System.Windows.Forms.Screen.AllScreens` with virtual screen coordinates, and the pet should detect fullscreen applications to hide itself during movies and presentations.

**Drag-and-drop with physics** creates the most memorable interactions. On mouse-down over the pet sprite, the animation switches to a "grabbed" state (surprised/dangling expression), and the window follows cursor position. During the drag, mouse velocity is tracked. On release, the pet enters a thrown/fall state with velocity derived from the drag gesture—horizontal momentum plus downward gravity acceleration of ~2 pixels/frame. Bouncing on impact uses `velocity_y = -velocity_y × 0.6` dampening, and friction (`velocity_x × 0.9`) decelerates horizontal movement until the pet settles and transitions to a landing animation.

**Right-click context menus** should include: Feed (select food items), Pet/Touch, Play (start mini-game), Sleep, Chat (open AI interface), Stats (mood/hunger/energy display), Settings, and Quit. On transparent windows, spawn either a native Win32 `PopupMenu` or a custom-rendered menu on a secondary transparent window, positioned relative to the cursor and clamped within screen work area bounds.

**Speech and thought bubbles** render on a secondary transparent window anchored above the pet's head position, flipping horizontally near screen edges. Auto-sizing based on content with a max-width of 200–300 px, readable 12–14 px font, and auto-dismiss timing of 3–5 seconds for short messages (5–8 seconds for longer ones) with a 300–500 ms fade-out. The speech bubble pointer (CSS triangle or sprite overlay) anchors to the pet's head. For AI conversations, streaming responses create a character-by-character typing effect.

**Mini-games** should be quick (30 seconds to 2 minutes), render in small overlay windows (200×300 to 400×400 px), and reward the pet with stat boosts (happiness, XP). Effective mini-game types include fetch/throw (throw a ball, pet retrieves it), rock-paper-scissors, memory card matching, idle digging/farming, and Pomodoro focus timers with pet rewards. Each game should be closable at any time and feed results back into the pet's stat system.

**Notifications** follow a severity escalation: subtle expression changes (droopy eyes for sleepy) → small speech bubbles for moderate needs → bouncing animation plus speech bubble for urgent states. Maximum one notification every 15–30 minutes, with Do Not Disturb detection for fullscreen applications and user-configurable frequency controls.

---

## Designing a plugin system for third-party extensibility

The plugin architecture should expose four extension points, each with a clear API contract: **skins** (sprite sheets + animation definitions), **behaviors** (new states and transition rules), **mini-games** (game UI and logic with reward hooks), and **AI capabilities** (custom providers, personality modules, conversation tools).

For a C#/.NET stack, **Managed Extensibility Framework (MEF)** provides the most natural plugin loading mechanism. Plugins are compiled as .NET DLL assemblies placed in a `plugins/` directory, discovered and loaded at runtime via `Assembly.LoadFrom()` or MEF's catalog system. Each plugin includes a `plugin.json` manifest declaring its name, version, type, required permissions, and minimum app version compatibility.

```json
{
  "name": "CatSkin",
  "version": "1.0.0",
  "type": "skin",
  "author": "PluginDev",
  "main": "CatSkin.dll",
  "permissions": ["filesystem"],
  "minAppVersion": "2.0.0"
}
```

**Sandboxing** is critical for third-party code. Use `AssemblyLoadContext` (modern .NET) for isolation, a permission system declared in the manifest and approved by the user before granting, and resource limits (CPU/memory caps per plugin). Plugins should only access the core through defined interfaces—never directly reference internal classes.

**Skin plugins** package sprite sheets, animation JSON, and metadata. The core validates that required animations (idle, walk, fall, drag, thrown) exist before loading. **Behavior plugins** register new states and transitions with the FSM, receiving callbacks for `OnEnter`, `OnUpdate`, `OnExit`, and condition checks. **Mini-game plugins** implement a `IMiniGamePlugin` interface with `Render()`, `Start()`, `End()`, and `GetRewards()` methods, rendering into a provided overlay panel. **AI plugins** can supply custom LLM providers, personality overlays, or conversation tools (e.g., weather lookup, timer setting).

For distribution, start with manual installation from ZIP files, then consider a simple plugin registry with versioning, ratings, and automated security scanning once the user community grows.

---

## State persistence across sessions

A **SQLite + JSON combination** provides the optimal persistence strategy. SQLite handles all structured, frequently-updated data (pet stats, interaction history, AI conversation memory, plugin data) with ACID-compliant transactions that prevent corruption on unexpected shutdowns. JSON files handle user preferences and app configuration where human readability and simplicity matter.

The SQLite database stores pet stats (mood, hunger, energy, experience, level), interaction timestamps, conversation logs, session summaries for AI memory, mini-game scores, and plugin-specific key-value data. A `schema_version` table enables forward-only migrations with backup-before-upgrade safety.

**Offline stat decay** calculates changes when the app restarts: `time_elapsed = current_time - last_save_timestamp`, then applies decay rates per stat. Critical design decisions: use **diminishing returns** (logarithmic, not linear decay) so the pet doesn't starve during a week-long vacation, enforce **minimum stat floors** (hunger never below 10%) to prevent "dead pet" scenarios, grant a **grace period** of 1–2 hours with no decay for quick restarts, and provide **return bonuses** ("Your pet missed you!") to reward returning users.

File locations follow Windows conventions: `%APPDATA%\{AppName}\config.json` for roamable preferences, `%LOCALAPPDATA%\{AppName}\pet.db` for the SQLite database, and `%LOCALAPPDATA%\{AppName}\plugins\` for plugin storage.

---

## Keeping CPU under 1% and RAM under 50 MB

A desktop pet runs continuously for 8–16 hours per day. Performance discipline is non-negotiable.

The primary optimization is **rendering only on frame changes**. At 10 FPS animation rate (100 ms per frame), the app performs 10 paint operations per second—not the 60+ that game loops typically target. When the pet is truly idle (no animation change, no position change), **skip rendering entirely** using a dirty flag. This alone keeps CPU below 0.5% during idle states.

For WPF, pre-load all sprite frames as `BitmapSource` objects during initialization, then swap `Image.Source` each timer tick—avoiding per-frame bitmap decoding. Use `DispatcherTimer` at the animation frame rate rather than `CompositionTarget.Rendering` (which fires at vsync rate) unless physics-driven animation is active.

**Battery impact reduction** uses Windows' `GetSystemPowerStatus()` API to detect AC/battery mode. On battery: reduce animation framerate from 10 to 5 FPS, extend stat update intervals from 1 minute to 5 minutes, disable complex behaviors like window climbing, and batch database writes. Windows 11's EcoQoS API allows the app to signal itself as low-priority, reducing CPU frequency and power draw.

**Memory leak prevention** for long-running apps requires disciplined cleanup: remove all event listeners when components are destroyed, cap collection sizes (conversation history limited to N messages), use `WeakReference` for caches, and dereference old sprite objects when switching animation states. During development, run 24–48 hour stress tests monitoring `Process.WorkingSet64` for steady growth that indicates leaks.

**Startup** should register via `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` with a 5–10 second delayed initialization to avoid competing with other startup applications. Show the pet immediately with an idle animation while loading settings, plugins, and AI systems asynchronously in the background.

| Metric | Target | Acceptable Max | Achieving It |
|--------|--------|----------------|--------------|
| CPU (idle) | <0.5% | <1% | Render only on frame changes |
| CPU (animating) | <2% | <5% | 10 FPS timer, pre-loaded sprites |
| RAM | 30–50 MB | <100 MB | WPF baseline + sprite atlas + SQLite |
| Startup time | <2 s | <5 s | Deferred plugin/AI loading |
| Battery impact | Negligible | <3%/hr | Power-state-adaptive framerate |
| Installer size | <10 MB | <15 MB | .NET self-contained trimmed publish |

---

## Conclusion

This research establishes a clear architectural foundation for a production-quality desktop pet. **C# WPF with Win32 interop** provides the best balance of rendering performance, transparent window quality, and development productivity—validated by eSheep64bit's success. The animation system should be entirely data-driven: pixel art sprite sheets with JSON metadata, processed through a finite state machine with weighted-random behavior selection inspired by Shimeji's proven architecture. AI integration via Claude API with Haiku-tier cost optimization, three-tier memory (context window → session summaries → semantic retrieval), and Ollama-based offline fallback creates a companion that remembers and adapts. The plugin system via MEF, SQLite persistence with offline decay formulas, and power-state-adaptive performance tuning complete the technical picture.

The key insight across all research is that **simplicity and data-driven design** consistently outperform complex architectures in this domain. Shimeji's XML behavior files, eSheep's sprite sheet editor, and Desktop Goose's personality-first approach all succeeded not through technical sophistication but through charm, extensibility, and restraint in resource consumption. The emerging trend of LLM integration—seen in Desktop Homunculus and several 2024–2025 GitHub projects—represents the primary innovation frontier, where persistent memory and emotional state awareness can transform a screen decoration into a genuine digital companion.
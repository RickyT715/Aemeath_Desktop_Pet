# Aemeath Desktop Pet

A desktop pet application featuring **Aemeath** (爱弥斯) from Wuthering Waves. She flies around your screen, reacts to your mouse, chats with you, and keeps you company while you work — accompanied by her black cat and paper planes.

![.NET 8](https://img.shields.io/badge/.NET-8.0-purple) ![WPF](https://img.shields.io/badge/WPF-Windows-blue) ![License](https://img.shields.io/badge/license-MIT-green)

English | [中文](README_CN.md)

---

## Table of Contents

- [Quick Start](#quick-start)
- [Controls & Interactions](#controls--interactions)
- [Features](#features)
  - [Behavior System (26-State FSM)](#behavior-system-26-state-fsm)
  - [Stats System](#stats-system)
  - [AI Chat](#ai-chat)
  - [Speech Bubbles & Idle Chatter](#speech-bubbles--idle-chatter)
    - [Speech Frequency (Per-Context)](#speech-frequency-per-context)
  - [Text-to-Speech (TTS)](#text-to-speech-tts)
  - [Voice Input (Push-to-Talk)](#voice-input-push-to-talk)
  - [Screenshot Support](#screenshot-support)
  - [Screen Awareness](#screen-awareness)
  - [Black Cat Companion](#black-cat-companion)
  - [Paper Plane System](#paper-plane-system)
  - [Particle System](#particle-system)
  - [Digital Glitch Effect](#digital-glitch-effect)
  - [Window Edge Perching](#window-edge-perching)
  - [Time Awareness](#time-awareness)
  - [Fullscreen Detection](#fullscreen-detection)
  - [Click-Through Mode](#click-through-mode)
  - [System Tray](#system-tray)
  - [Pomodoro / To-Do List Integration](#pomodoro--to-do-list-integration)
  - [Activity Monitor Integration](#activity-monitor-integration)
  - [Companion App Auto-Launch](#companion-app-auto-launch)
  - [Start with Windows](#start-with-windows)
- [Settings Panel](#settings-panel)
- [Sprites](#sprites)
- [Configuration & Data Files](#configuration--data-files)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Missing Assets & Stubbed Features](#missing-assets--stubbed-features)
- [About Aemeath](#about-aemeath)

---

## Quick Start

### Prerequisites

- **Windows 10/11** (x64)
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) (for building) or [.NET 8 Desktop Runtime](https://dotnet.microsoft.com/download/dotnet/8.0) (for running published builds)

### Install .NET 8 SDK

Download from: https://dotnet.microsoft.com/download/dotnet/8.0

Or install via winget:
```
winget install Microsoft.DotNet.SDK.8
```

Verify installation:
```
dotnet --version
```

### Build & Run

**Windows (batch):**
```
run.bat
```

**Manual:**
```
dotnet run --project src/AemeathDesktopPet
```

### Build Only

```
dotnet build src/AemeathDesktopPet/AemeathDesktopPet.csproj
```

### Run Tests

```
dotnet test tests/AemeathDesktopPet.Tests/
```

### Publish (Self-Contained)

```
dotnet publish src/AemeathDesktopPet/AemeathDesktopPet.csproj -c Release -r win-x64 --self-contained
```

Output will be in `src/AemeathDesktopPet/bin/Release/net8.0-windows/win-x64/publish/`.

---

## Controls & Interactions

### Mouse Controls

| Input | Action | Details |
|-------|--------|---------|
| **Left-click** | Wave animation | Aemeath plays a hand-waving greeting |
| **Hover 2 seconds** | Happy jump | Hold the cursor over Aemeath without clicking — she jumps happily (+5 Mood, +3 Affection) |
| **Left-drag** | Pick up and move | Click and hold to drag Aemeath anywhere on screen |
| **Fast drag + release** | Throw | Drag quickly and release — Aemeath flies with velocity, bounces off screen edges, then lands with gravity |
| **Double-click** | Open chat window | Opens the AI chat window to talk with Aemeath |
| **Right-click** | Context menu | Opens the action menu (see below) |

### Context Menu

Right-click Aemeath to open the context menu:

| Item | Action | Details |
|------|--------|---------|
| **Sing** | Singing animation | Aemeath sings with music note particles. Requires a music folder set in Settings for audio playback (+8 Mood, -5 Energy) |
| **Chat with Aemeath** | Open chat window | Same as double-click — opens the AI chat window |
| **Throw a Paper Plane** | Launch paper plane | Aemeath throws a paper plane that arcs across the screen. The cat may chase it (+2 Mood, -2 Energy) |
| **Call Cat** | Summon companion | The black cat runs to Aemeath's position (only visible if cat is enabled in Settings) |
| **How's Aemeath?** | Stats popup | Shows mood, energy, and affection bars with gradient colors and lifetime counters |
| **Settings** | Settings panel | Opens the 6-tab settings window |
| **See you later!** | Hide pet | Hides Aemeath (and cat) from screen. She stays in the system tray — double-click the tray icon to bring her back |
| **Quit** | Exit application | Closes the application entirely. If "Close to tray" is enabled, use this to truly quit |

### System Tray Controls

| Input | Action |
|-------|--------|
| **Double-click tray icon** | Show/hide pet |
| **Right-click tray icon** | Tray context menu (Show, Toggle Click-Through, Settings, Quit) |

### Keyboard Controls

| Input | Action | Details |
|-------|--------|---------|
| **Push-to-talk hotkey** (default: `Ctrl+F2`) | Voice input | Hold to record, release to send. Requires voice input enabled in Settings |

---

## Features

### Behavior System (26-State FSM)

Aemeath's behavior is driven by a **26-state finite state machine** with weighted random transitions. Every ~1 second, the engine evaluates whether to transition to a new state based on:

- **Base weights** — Each state has a default likelihood (e.g., flying: 15, singing: 5, sleep: 1)
- **Stats modifiers** — Mood, energy, and time of day dynamically adjust weights
- **Conditions** — Some states only trigger under specific circumstances

#### All 26 States

| Category | States | Description |
|----------|--------|-------------|
| **Core** | Idle, FlyLeft, FlyRight, Fall, Landing | Basic movement and rest |
| **Interaction** | Drag, Thrown, Wave, PetHappy, Laugh | User-triggered reactions |
| **Personality** | Sing, PlayGame, Sigh, LookAtUser, Sleep | Autonomous behaviors |
| **Social** | Chat, PaperPlane, CatLap, PetCat | Interactive and companion states |
| **Window** | PeekEdge, LieOnWindow, HideTaskbar, ClingEdge | Window edge interactions |
| **Special** | Glitch, Speaking, ScreenComment | Digital effects and voice |

#### Dynamic Weight Examples

| Condition | Effect |
|-----------|--------|
| Mood < 50 | Sigh weight doubles (more melancholy) |
| Mood > 70 | Laugh weight increases 1.5x |
| Energy < 30 | Sleep weight increases to 5; PlayGame and Sing disabled |
| Energy < 20 | PlayGame disabled |
| Energy < 15 | Sing disabled |
| Night (21:00–5:59) | Sleep becomes available |
| Mood < 20 | Sing disabled (too sad to sing) |
| Pomodoro work mode | Sing suppressed (no auto-singing during focus) |
| No music folder set | Sing suppressed (nothing to play) |

Each state has a randomized duration (e.g., Sing: 5–15 seconds, Sleep: 8–20 seconds). States like Drag, Chat, and Sleep are user-driven and don't auto-transition.

---

### Stats System

Aemeath has three core stats that track her emotional state. They affect her behavior, dialogue, and animations.

#### Stats Overview

| Stat | Range | Default | What It Affects |
|------|-------|---------|-----------------|
| **Mood** | 0–100 | 70 | Behavior weights (more laughs when high, more sighs when low), dialogue tone |
| **Energy** | 0–100 | 80 | Available activities (singing, games disabled when low), sleep tendency |
| **Affection** | 0–100 | 50 | Long-term bond indicator, greeting warmth |

#### How Stats Change

**Interactions (immediate effects):**

| Action | Mood | Energy | Affection |
|--------|------|--------|-----------|
| Chat with Aemeath | +3 | — | +2 |
| Pet (hover 2s) | +5 | — | +3 |
| Sing | +8 | -5 | — |
| Throw paper plane | +2 | -2 | — |
| Play game | +6 | -8 | — |
| Pomodoro work finished | +3 | — | — |

**Active session decay (every 5 minutes while running):**
- Energy: -1
- Mood: Drifts toward 50 (±0.5 per tick)

**Offline decay (when app is closed):**

| Stat | First hours | After that | Floor |
|------|-------------|------------|-------|
| Mood | -5/hr (first 4 hrs) | -2/hr | 30 |
| Energy | -3/hr (first 6 hrs) | -1/hr | 20 |
| Affection | -1/hr (first 12 hrs) | -0.5/hr | 40 |

**Lifetime counters** tracked: Total Chats, Total Pets, Total Songs, Total Paper Planes, Total Games, Days Together.

#### Viewing Stats

Right-click Aemeath > **"How's Aemeath?"** to see gradient progress bars for each stat and lifetime counters.

---

### AI Chat

Double-click Aemeath or use the context menu to open the chat window. Two AI providers are supported:

#### Claude (Anthropic)

1. Get an API key from [console.anthropic.com](https://console.anthropic.com/)
2. Open **Settings** (right-click > Settings) > **AI** tab
3. Select **Claude** as the provider
4. Enter your API key

#### Gemini (Google)

1. Get an API key from [aistudio.google.com](https://aistudio.google.com/)
2. Open **Settings** > **AI** tab
3. Select **Gemini** as the provider
4. Enter your API key

#### Offline Fallback

Without an API key, the chat uses **75+ pre-scripted character responses** that are context-aware:
- **Time of day** — morning greetings, night sleepy responses
- **Mood** — happy reactions vs. melancholy lines
- **Energy** — sleepy responses when low
- **Absence duration** — "Where were you?" when returning after a long time

#### Chat Features

- **Streaming responses** — AI text appears word-by-word in the chat window
- **Character personality** — The system prompt maintains Aemeath's personality (bubbly, digital ghost, loves singing)
- **Chat history** — Last 200 messages are saved and loaded between sessions
- **TTS integration** — AI responses are spoken aloud when TTS is enabled
- **Screenshot support** — Attach a screenshot to your message for visual context

---

### Speech Bubbles & Idle Chatter

Aemeath periodically shows speech bubbles with themed dialogue while idle.

- **Configurable per-context frequency**: Each activity context has its own speech frequency preset
- **Streaming text effect**: Text appears character-by-character
- **Duration**: Each bubble stays for ~5 seconds

Speech bubbles are **suppressed** during: Drag, Thrown, Fall, Chat, Sleep, and Speaking states.

#### Speech Frequency (Per-Context)

Aemeath's idle chatter frequency automatically adapts to what you're doing. Six activity contexts are detected, each configurable with four frequency presets.

**Activity Contexts:**

| Context | Default Preset | Detection Method |
|---------|---------------|-----------------|
| Pomodoro Work | Silent | Pomodoro timer work mode active |
| Pomodoro Break | Chatty | Pomodoro timer break mode active |
| Gaming | Rare | Process names (Steam, Epic, Genshin, etc.) + domains |
| Watching Videos | Rare | Domains (YouTube, Twitch, Bilibili, Netflix, etc.) |
| Studying / Coding | Normal | Process names (VS Code, DevEnv, etc.) + domains (GitHub, StackOverflow, etc.) |
| Default / Idle | Normal | Fallback when no specific activity detected |

**Frequency Presets:**

| Preset | Interval | Description |
|--------|----------|-------------|
| Silent | — | No idle chatter |
| Rare | 2–4 minutes | Minimal interruptions |
| Normal | 45–90 seconds | Standard chatter |
| Chatty | 15–30 seconds | Frequent conversation |

**Priority:** Pomodoro state > Activity detection > Default

**Configuration:** Settings > General > Speech Frequency. Each context has a dropdown to select its preset.

> **Note:** Gaming, Videos, and Study/Coding detection requires Activity Monitor to be enabled with a valid database path.

---

### Text-to-Speech (TTS)

Five TTS providers are available. Configure in **Settings** > **Voice** tab.

#### Edge TTS (Default — Free)

Uses Microsoft Edge's neural TTS voices via WebSocket. **No API key needed.**

- Default voice: `en-US-AvaMultilingualNeural`
- 300+ voices across many languages
- Popular Chinese voices: `zh-CN-XiaoxiaoNeural`, `zh-CN-YunxiNeural`, `zh-CN-YunyangNeural`
- English voices: `en-US-AvaMultilingualNeural`, `en-US-JennyNeural`, etc.

**How to use:** Select "Edge TTS" in Settings > Voice tab. Type the exact voice name.

> **Note:** `Edge_tts.Await = true` is bugged in Edge_tts_sharp v1.1.7 — the library's callback never fires. The provider uses `Await = false` with `ManualResetEventSlim` to wait correctly.

#### GPT-SoVITS (Local)

Connects to a local [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) server for custom voice cloning.
Supports **model profiles** for switching between multiple trained models.

**Prerequisites:**
- Python 3.9+ installed
- NVIDIA GPU recommended (CUDA); CPU inference works but is slow
- A trained GPT-SoVITS model (`.ckpt` + `.pth` weight files) and a short reference audio clip

**Server Setup:**
1. Clone or download [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS)
2. Install dependencies: `pip install -r requirements.txt`
3. Start the **API server** (not the WebUI):
   ```bash
   python api_v2.py -a 127.0.0.1 -p 9880
   ```
   The server listens on `http://localhost:9880` by default.
   > **Tip:** Use `-a 0.0.0.0` if the server runs on a different machine on your LAN.

**Desktop Pet Setup:**
1. Open **Settings** > **Voice** tab
2. Select **GPT-SoVITS** as the TTS provider
3. Verify the server URL (default: `http://localhost:9880`)

**Model Profiles:**
1. Click **Add** to create a profile
2. Configure:
   - **GPT Weights Path** (`.ckpt`) — full path **on the server machine**
   - **SoVITS Weights Path** (`.pth`) — full path **on the server machine**
   - **Reference Audio** — a short (3-10s) clear speech clip of the target voice
   - **Prompt Text** — exact transcription of the reference audio
   - **Prompt / Text Language** — Auto, Chinese, English, Japanese, or Korean
   - **Speed** — 0.5x to 2.0x
3. Select the profile from the dropdown to activate it

> All file paths (weights, reference audio) are resolved **on the GPT-SoVITS server**, not on the desktop pet machine.
> If both run on the same PC, use absolute paths like `D:\GPT-SoVITS\models\my_model.ckpt`.

When a profile is active, the provider automatically calls `/set_gpt_weights` and `/set_sovits_weights` to load the model before synthesis. Select *"(No profile - legacy mode)"* to use the server's currently loaded default model.

#### ElevenLabs (Cloud)

High-quality cloud TTS with many voice options.

1. Get an API key from [elevenlabs.io](https://elevenlabs.io/)
2. Enter your API key and voice ID in Settings
3. Select "ElevenLabs" as the TTS provider

#### Fish Audio (Cloud)

Cloud voice cloning and TTS via [Fish Audio](https://fish.audio/). Supports zero-shot voice cloning with a short reference audio clip — no model training required.

1. Get an API key from [fish.audio](https://fish.audio/)
2. **(Optional)** Upload a reference audio clip on Fish Audio to create a voice model and copy its Model ID
3. Enter your API key and Model ID in **Settings** > **Voice** tab
4. Select "Fish Audio" as the TTS provider

> The API Base URL defaults to `https://api.fish.audio`. Change it only if you self-host the Fish Speech server.

#### OpenAI TTS (Cloud)

Simple cloud TTS via the OpenAI API. 13 preset voices, no voice cloning.

1. Get an API key from [platform.openai.com](https://platform.openai.com/)
2. Enter your API key in **Settings** > **Voice** tab
3. Select a model (`tts-1`, `tts-1-hd`, or `gpt-4o-mini-tts`) and voice
4. Select "OpenAI TTS" as the TTS provider

Available voices: `alloy`, `ash`, `coral`, `echo`, `fable`, `onyx`, `nova`, `sage`, `shimmer`.
Speed adjustable from 0.25x to 4.0x.

#### TTS Features

| Feature | Description |
|---------|-------------|
| **Auto-speak chat** | AI chat responses are spoken aloud when TTS is enabled |
| **Auto-speak idle chatter** | Speech bubbles can optionally be spoken (off by default) |
| **Auto-mute fullscreen** | TTS silenced when a fullscreen app is active (configurable) |
| **Queue system** | Utterances queued and played one at a time via NAudio |
| **Stop on new message** | Sending a new chat message cancels current speech |
| **Format detection** | Handles MP3 (Edge TTS, ElevenLabs, OpenAI) and WAV (GPT-SoVITS, Fish Audio) |
| **Volume control** | Adjustable 0–100% in Settings |

#### Testing TTS

A standalone integration test console app is included:

```
dotnet run --project tests/TtsIntegrationTest
```

This tests all 5 providers sequentially. Set API key environment variables to include cloud providers.

---

### Voice Input (Push-to-Talk)

Record voice messages and send them to the AI chat.

**Setup:**
1. Enable voice input in **Settings** > **Voice** tab
2. Choose STT provider: **Whisper** (OpenAI) or **Gemini** (Google)
3. Enter the API key for your chosen provider
4. Set the push-to-talk hotkey (default: `Ctrl+F2`)
5. Optionally enable screenshot attachment

**How to use:**
1. Press and hold the hotkey to start recording (microphone icon appears)
2. Speak your message
3. Release the hotkey — audio is transcribed and sent as a chat message
4. If screenshot is enabled, a screen capture is attached automatically

**STT Providers:**

| Provider | API Key Required | Notes |
|----------|-----------------|-------|
| Whisper (OpenAI) | Yes (OpenAI key) | Accurate, supports many languages |
| Gemini (Google) | Uses Gemini key | Reuses the AI chat Gemini key |

**Language options:** English, Chinese, Japanese, Korean, Spanish, French, German.

---

### Screenshot Support

Capture and include screenshots in your chat messages for visual context.

- **With voice input**: Enable "Include screenshot" in Voice settings — a screenshot is automatically captured when you release the push-to-talk key
- **With text chat**: Use the screenshot button in the chat window to capture and attach

Screenshots are captured as JPEG with downscaling for efficient API transmission.

---

### Screen Awareness

Aemeath can periodically capture screenshots of your screen and comment on what you're doing via speech bubbles, powered by a vision AI.

#### How It Works

1. A background timer captures a screenshot every 60 seconds (configurable)
2. **Tier 1 privacy check**: If the foreground app is blacklisted (e.g., KeePass, banking sites), the screenshot is skipped
3. **Change detection**: A perceptual hash compares the current screenshot with the previous one. If the screen hasn't changed meaningfully (Hamming distance < 10), the screenshot is skipped
4. **Budget check**: If the monthly spending estimate exceeds the configured cap, screenshots are skipped
5. The screenshot is sent to the configured vision AI (Gemini Flash or Claude) with a privacy-focused analysis prompt
6. The AI generates a brief, in-character observation (1-2 sentences)
7. The next idle chatter tick picks up the cached commentary and shows it as a speech bubble

#### Privacy Pipeline

| Tier | Protection | Description |
|------|-----------|-------------|
| **Tier 1** | App Blacklist | Configurable list of apps/title patterns that block screenshots (e.g., `keepass.exe`, `chrome.exe:*bank*`) |
| **Tier 3** | Privacy Prompt | The AI is explicitly instructed to never read or repeat specific text, numbers, names, passwords, or identifiable information |

The analysis prompt instructs the AI to only comment on the **general activity** (e.g., "looks like you're coding" or "watching a video?"), never quoting specific on-screen content.

#### Cost Estimates

| Provider | Cost per 1,000 screenshots | Monthly (8hr/day, 1/min) |
|----------|---------------------------|--------------------------|
| **Gemini 2.5 Flash** | ~$0.04 | ~$0.38/month (with dedup) |
| Claude Haiku 4.5 | ~$1.33 | ~$12/month |

Default provider is Gemini Flash for cost efficiency. A configurable monthly budget cap (default: $5) prevents runaway spending.

#### Visual Indicator

When screen awareness is active, a small badge appears near Aemeath: **"👁 Aemeath can see"**. This can be toggled off in Settings.

#### Setup

1. Open **Settings** > **Screen** tab
2. Check "Enable screen awareness"
3. Select a vision provider (Gemini Flash recommended)
4. Enter the vision API key
5. Optionally adjust interval, budget cap, and blacklist

### Black Cat Companion

A black cat follows Aemeath around the screen in its own independent window.

#### Cat Behavior

The cat has its own **12-state FSM** that runs independently:

| State | Description |
|-------|-------------|
| **CatIdle** | Sitting still, watching |
| **CatWalk** | Walking toward Aemeath |
| **CatNap** | Taking a nap |
| **CatGroom** | Grooming itself |
| **CatPounce** | Pouncing at something |
| **CatWatch** | Alert, watching Aemeath |
| **CatRub** | Rubbing against Aemeath |
| **CatStartled** | Startled reaction |
| **CatPurr** | Content purring |
| **CatPerch** | Sitting on a perch |
| **CatChase** | Chasing a paper plane |
| **CatBat** | Batting at something |

**Behavior details:**
- **Follows Aemeath** with a 40–80px horizontal offset and 10–30px vertical offset
- **Smooth movement** — lerps toward target position
- **Reacts to events** — gets startled by drag, chases paper planes, purrs during petting
- **Independent window** — separate transparent WPF window for independent movement

**Customization** (Settings > Appearance):
- Enable/disable the cat companion
- Set the cat's name (default: "Kuro")

> **Note:** Currently uses a Unicode emoji placeholder. GIF sprites for 12 states are planned but not yet created.

---

### Paper Plane System

Paper planes appear in two ways:

#### Ambient Planes (Automatic)

- Spawn at random intervals from screen edges
- **Default frequency**: Every 5 minutes (randomized 3–8 minutes)
- **Configurable**: 3, 5, 8, or 10 minutes in Settings > Appearance
- **Trajectory**: Slow horizontal drift + gentle downward float + sinusoidal wobble
- **Lifetime**: Auto-removed after 20 seconds

#### Thrown Planes (User-Triggered)

- Right-click > **"Throw a Paper Plane"**
- Aemeath enters the PaperPlane state and throws a plane
- **Physics**: Parabolic trajectory with gravity (20 px/s²) + wobble
- **Speed**: 80–140 px/s horizontal, upward arc
- **Cat reaction**: The cat chases landed planes (triggers CatChase state)

> **Note:** Currently uses a Unicode plane symbol (✈). A sprite asset is planned.

---

### Particle System

Visual particle effects that appear during various interactions:

| Particle | Symbol | When It Appears |
|----------|--------|-----------------|
| **Music Note** | ♪ | During singing |
| **Heart** | ♥ | When petted (hover 2s) |
| **Sparkle** | ✦ | Pomodoro work completion, special events |
| **Sleep Z** | Z | During sleep state |
| **Paw Print** | 🐾 | Cat-related interactions |
| **Fur Puff** | • | Cat grooming/startled |

**Physics**: Particles spawn with random offset, float upward with slight gravity, and fade out over ~1–2 seconds. Maximum 12 particles on screen at once.

---

### Digital Glitch Effect

Aemeath is a digital ghost, and her image occasionally glitches — a subtle visual reminder of her nature.

- **Trigger**: Random 2–5% chance every 5–10 seconds
- **Duration**: 300–800 milliseconds
- **Visual effects**:
  - **RGB channel split** — color channels separate horizontally
  - **Horizontal slice displacement** — image slices shift randomly
  - **Opacity flicker** — transparency modulates rapidly
- **Toggle**: Enable/disable in Settings > Appearance
- **Can be forced**: Certain events (like special interactions) trigger a glitch

---

### Window Edge Perching

Aemeath can interact with other windows on your desktop.

- **Detection**: Every 500ms, checks for nearby window title bars (within 30px)
- **Perch states**: `PeekEdge`, `LieOnWindow`, `HideTaskbar`, `ClingEdge`
- **Screen edges**: Detects proximity to left/right/top edges (20px) and taskbar (10px)
- **Window tracking**: When Aemeath perches on a window and that window closes, she reacts (falls or flies away)
- **Works with**: Any visible, non-cloaked window on the desktop

---

### Time Awareness

Aemeath knows what time it is and behaves accordingly.

| Time Period | Hours | Effect |
|-------------|-------|--------|
| **Morning** | 6:00–11:59 | Morning-specific greetings on launch |
| **Day** | 12:00–16:59 | Normal behavior |
| **Evening** | 17:00–20:59 | Normal behavior |
| **Night** | 21:00–23:59 | Sleep state available, sleepy greetings |
| **Late Night** | 0:00–5:59 | Sleep state available, concerned "you're still up?" lines |

- **Greeting selection**: Launch greetings match the time of day
- **Sleep behavior**: Only triggers during Night/LateNight, or when energy < 30
- **Idle chatter**: Lines are contextual to the current time period

---

### Fullscreen Detection

Aemeath knows when you're watching a video or playing a game.

- **Auto-hide**: Aemeath (and cat) hide when a fullscreen application is detected
- **Auto-show**: Reappears when you exit fullscreen
- **TTS muting**: When "Auto-mute fullscreen" is enabled, TTS is silenced during fullscreen apps
- **Detection method**: Checks if the foreground window covers the entire screen (excluding the Windows shell/desktop)

---

### Click-Through Mode

Make Aemeath purely visual — mouse clicks pass through her to the window below.

- **Toggle**: Right-click the **system tray icon** > "Toggle Click-Through"
- **Effect**: Both Aemeath and cat windows become non-interactive
- **Visual indicator**: A ghost-like reduced opacity overlay appears as a reminder
- **Tray notification**: A balloon tip reminds you how to toggle back
- **Implementation**: Uses Win32 `WS_EX_TRANSPARENT` window style

> **Tip**: To restore interaction, right-click the **system tray icon** and toggle click-through off.

---

### System Tray

Aemeath lives in your system tray for easy access.

- **Minimize to tray**: When "Close to tray" is enabled (default), closing the window hides Aemeath to the tray instead of quitting
- **Double-click tray icon**: Show/hide the pet
- **Right-click tray icon**: Menu with Show, Toggle Click-Through, Settings, and Quit
- **Always available**: Even when hidden, Aemeath is one click away

---

### Pomodoro / To-Do List Integration

Aemeath reacts to events from the companion **To-Do List / Pomodoro Timer** (Electron app) via Windows Named Pipes.

#### LLM-Powered Responses

When an AI provider (Claude or Gemini) is configured, pomodoro event messages are **generated by the LLM** in real-time — Aemeath says something unique and contextual each time instead of repeating pre-scripted lines. If no API key is configured or the LLM call fails, the system gracefully falls back to the pre-written offline responses.

- LLM calls use empty chat history (standalone reactions, not part of ongoing conversation)
- Responses are not saved to chat memory
- Prompts include event context (task title, duration, break type) for relevant messages
- **Prompt templates are fully customizable** in Settings > General > LLM Prompt Templates
- Templates support `{taskTitle}`, `{duration}`, and `{breakType}` placeholders
- A "Reset to Defaults" button restores the original prompts

#### Event Reactions

| Event | Pet Reaction |
|-------|-------------|
| **Work session starts** | LLM-generated encouragement (or offline fallback) + happy animation |
| **Work session ends** | LLM-generated celebration (or offline fallback) + sparkle particles + mood boost (+3) + TTS |
| **Break starts** | LLM-generated relaxation chat (or offline fallback) + TTS, idle chatter becomes more frequent |
| **Break ends** | LLM-generated motivation (or offline fallback) |
| **Task added** | LLM-generated reaction mentioning the task title (or offline fallback) |
| **During work** | Idle chatter is completely suppressed (quiet focus mode) |

#### Setup

Enabled by default. Both apps detect each other automatically — just start them.

- **Toggle**: Settings > General > Integrations > "Connect to To-Do List / Pomodoro Timer"
- **Requires restart**: Changing this setting requires restarting the desktop pet
- **No configuration needed**: The pipe name is fixed (`AemeathDesktopPet`)

#### How It Works

- **Protocol**: One-way Named Pipe (`\\.\pipe\AemeathDesktopPet`), newline-delimited JSON
- **Desktop Pet**: Runs the pipe server (always listening)
- **To-Do List**: Connects as a client with auto-reconnect (5-second retry)
- **Direction**: One-way (To-Do List → Desktop Pet)

---

### Activity Monitor Integration

Aemeath can read your recent computer activity from the **Computer & Chrome Monitor** app's SQLite database, making her idle chatter and pomodoro reactions contextually aware of what you've been doing.

#### How It Works

- Reads `window_sessions` and `chrome_sessions` tables from the monitor's SQLite database (read-only access)
- Groups activity by application/domain, sorted by duration
- Generates a compact summary like: *"You spent 12 min in VS Code, 8 min on github.com, 5 min on stackoverflow.com"*
- **Camera-based commentary**: Also reads `attention_sessions` for face detection, emotion recognition, attention scoring, and mind wandering detection — generating a user state summary like: *"Dominant emotion: happy. Attention: 0.72. Looking at screen: 85%. 2 mind-wandering events."*
- Both summaries are included in AI prompts so Aemeath can comment on your activity and physical state

#### Integration Points

| Context | Behavior |
|---------|----------|
| **Idle chatter** | When AI is available, idle speech bubbles reference what you've been doing and how you look/feel (emotion, attention, etc.) |
| **Pomodoro work finished** | AI prompt includes what you worked on and your physical state during the entire session |
| **Other pomodoro events** | AI prompt includes last 5 minutes of activity and camera data as context |
| **No data / DB unavailable** | Gracefully falls back to normal offline responses |

#### Setup

1. Install and run the [Computer & Chrome Monitor](https://github.com/user/Computer_and_Chrome_Monitor_with_AI_Analysis) app
2. Open **Settings** > **General** > **Activity Monitor**
3. Check "Include recent activity in Aemeath's speech"
4. Set the database path (default: `D:\Study\Project\Computer_and_Chrome_Monitor_with_AI_Analysis\data\monitor.db`)
5. Ensure an AI provider (Claude or Gemini) is configured in the AI tab

> **Note:** The database is opened in read-only mode — the desktop pet never modifies monitor data.

---

### Companion App Auto-Launch

The desktop pet can automatically launch its two companion programs when it starts, so you don't have to open them manually each time.

#### Supported Companions

| Program | Description | Default Path |
|---------|-------------|-------------|
| **Computer & Chrome Monitor** | Activity tracking (window/browser sessions, camera attention data) | `...\run.bat` |
| **To-Do List / Pomodoro Timer** | Task management and pomodoro timer with pet integration | `...\run.bat` |

#### Setup

1. Open **Settings** > **General** > **Companion Apps**
2. Check the boxes for the programs you want to auto-launch
3. Verify or browse to the correct executable/batch file paths
4. Save — next time the pet starts, companions launch automatically

#### Behavior

- **Duplicate prevention** (exe files): If the companion is already running, a second instance won't be launched
- **Batch file support**: `.bat` files are launched via `UseShellExecute` (supports `run.bat` → `npm start` chains)
- **Silent failure**: If a companion fails to launch (wrong path, missing file), the pet continues normally
- **Launch order**: Companions are launched before the main pet window, giving them time to initialize

---

### Start with Windows

Enable "Start with Windows" in **Settings** > **General** to have the desktop pet launch automatically at login.

- Uses the Windows Registry (`HKCU\Software\Microsoft\Windows\CurrentVersion\Run`) — no admin rights needed
- The setting is applied immediately when you save
- When combined with companion auto-launch, all three apps start together at login

---

## Settings Panel

Open via right-click > **Settings** or the system tray menu. Six tabs organized by category:

### Tab 1: General

| Setting | Default | Description |
|---------|---------|-------------|
| Start with Windows | Off | Launch on Windows startup (writes to registry on save) |
| Close to system tray | On | Closing the window hides to tray instead of quitting |
| Launch Monitor on startup | Off | Auto-launch Computer & Chrome Monitor when pet starts |
| Monitor Path | (default) | Path to run.bat (or ComputerMonitor.exe) |
| Launch To-Do List on startup | Off | Auto-launch To-Do List / Pomodoro Timer when pet starts |
| To-Do List Path | (default) | Path to the To-Do List run.bat or executable |
| Behavior Frequency | Normal | How active Aemeath is: Calm, Normal, or Active |
| Pomodoro Integration | On | Connect to To-Do List / Pomodoro Timer (requires restart) |
| LLM Prompt Templates | (defaults) | Customize 5 prompt templates for pomodoro events (visible when integration is enabled). Supports `{taskTitle}`, `{duration}`, `{breakType}` placeholders |
| Activity Monitor | Off | Include recent computer activity in Aemeath's AI-generated speech |
| Activity Monitor DB Path | (default path) | Path to the Computer & Chrome Monitor SQLite database |
| Speech Frequency | (per-context defaults) | Configure how often Aemeath speaks during 6 activity contexts: Pomodoro Work (Silent), Pomodoro Break (Chatty), Gaming (Rare), Videos (Rare), Study/Coding (Normal), Default (Normal) |

### Tab 2: Appearance

| Setting | Default | Description |
|---------|---------|-------------|
| Pet Size | Normal (200px) | Small (150px), Normal (200px), or Large (250px) |
| Opacity | 100% | Pet transparency (30–100%) |
| Enable digital glitch effect | On | Random RGB split/flicker effect |
| Enable black cat companion | On | Show the cat companion |
| Cat Name | "Kuro" | The cat's display name |
| Enable ambient paper planes | On | Planes drift in from screen edges |
| Paper plane frequency | 5 minutes | How often ambient planes appear (3, 5, 8, or 10 min) |

### Tab 3: Music

| Setting | Default | Description |
|---------|---------|-------------|
| Music Folder | (empty) | Path to a folder of songs. Aemeath plays random songs when singing |
| Song count | Auto | Displays how many songs were found in the folder |

Browse to select a folder. Aemeath will scan it for audio files and play a random one during the Sing state.

### Tab 4: AI

| Setting | Default | Description |
|---------|---------|-------------|
| AI Provider | Claude | Choose between Claude (Anthropic) or Gemini (Google) |
| Claude API Key | (empty) | Your Anthropic API key |
| Gemini API Key | (empty) | Your Google AI Studio API key |

API keys are stored locally in `config.json`. Without a key, chat falls back to offline scripted responses.

### Tab 5: Voice

**Voice Input (STT):**

| Setting | Default | Description |
|---------|---------|-------------|
| Enable voice input | Off | Activate push-to-talk functionality |
| STT Provider | Whisper | Whisper (OpenAI) or Gemini (Google) |
| Whisper API Key | (empty) | OpenAI API key (only when Whisper selected) |
| Language | English | Recognition language (en, zh, ja, ko, es, fr, de) |
| Include screenshot | Off | Attach a screenshot with each voice message |
| Push-to-Talk Hotkey | Ctrl+F2 | Click the field and press your desired key combination |

**Text-to-Speech:**

| Setting | Default | Description |
|---------|---------|-------------|
| Enable TTS | Off | Activate text-to-speech |
| Provider | Edge TTS | Edge TTS (free), GPT-SoVITS (local), or ElevenLabs (cloud) |
| Edge TTS Voice | en-US-AvaMultilingualNeural | Voice name (300+ available) |
| GPT-SoVITS URL | http://localhost:9880 | Local server address |
| GPT-SoVITS Profiles | — | Manage model profiles (Add/Delete, with weights/audio/language) |
| ElevenLabs API Key | (empty) | ElevenLabs API key |
| ElevenLabs Voice ID | 21m00Tcm4TlvDq8ikWAM | Voice to use |
| Volume | 70% | Playback volume (0–100%) |
| Speak chat responses | On | Read AI replies aloud |
| Speak idle chatter | Off | Read speech bubbles aloud |
| Auto-mute fullscreen | On | Silence TTS during fullscreen apps |

### Tab 6: Screen Awareness

| Setting | Default | Description |
|---------|---------|-------------|
| Enable screen awareness | Off | Periodic screenshot analysis for contextual comments |
| Show indicator | On | Display "👁 Aemeath can see" badge when active |
| Vision provider | Gemini Flash | Gemini Flash (cheap) or Claude (higher quality) |
| Vision API key | (empty) | API key for the vision provider |
| Check interval | 60s | How often to capture (30/60/120 seconds) |
| Monthly budget cap | $5.00 | Spending limit for cloud vision API calls |
| Analysis prompt | (default) | Customizable prompt for the vision AI. Reset button available |
| Blacklisted apps | (4 defaults) | Apps/title patterns that block screenshots (one per line) |

---

## Sprites

9 hand-crafted chibi GIF animations:

| Animation | File | Size | FPS | When Used |
|-----------|------|------|-----|-----------|
| Idle | `normal.gif` | 200x200 | ~9 | Default standing pose |
| Fly | `normal_flying.gif` | 200x200 | ~9 | Flying movement (mirrored for left) |
| Wave | `happy_hand_waving.gif` | 200x200 | ~9 | Greeting on click |
| Happy | `happy_jumping.gif` | 200x200 | ~9 | Jumping on hover |
| Laugh | `laugh.gif` | 200x200 | ~9 | Random idle laugh |
| Laugh (flying) | `laugh_flying.gif` | 200x200 | ~9 | Laughing while airborne |
| Sigh | `sign.gif` | 200x200 | ~9 | Melancholy moment |
| Sing | `listening_music.gif` | 1000x1000 | 25 | Premium singing animation |
| Seal | `seal.gif` | 200x200 | ~9 | Seal transformation |

Sprite assets are located at `src/AemeathDesktopPet/Resources/Sprites/Aemeath/` and `.../Seal/`.

States without a dedicated sprite fall back to the closest matching animation (e.g., `normal.gif` for most idle-like states).

---

## Configuration & Data Files

All data is stored in `%LOCALAPPDATA%\AemeathDesktopPet\`:

| File | Purpose |
|------|---------|
| `config.json` | All user preferences and settings |
| `stats.json` | Mood, Energy, Affection values + lifetime counters |
| `messages.json` | Chat conversation history (up to 200 messages) |

### Example config.json

```json
{
  "petSize": 200,
  "opacity": 1.0,
  "closeToTray": true,
  "behaviorFrequency": "normal",
  "enableGlitchEffect": true,
  "enableSinging": true,
  "enableBlackCat": true,
  "catName": "Kuro",
  "enableAmbientPaperPlanes": true,
  "ambientPlaneFrequency": "normal",
  "musicFolder": "",
  "aiProvider": "claude",
  "claudeApiKey": "",
  "geminiApiKey": "",
  "tts": {
    "enabled": false,
    "provider": "edgetts",
    "edgeTtsVoice": "en-US-AvaMultilingualNeural",
    "gptsovitsUrl": "http://localhost:9880",
    "gptsovitsProfiles": [],
    "gptsovitsActiveProfile": "",
    "elevenLabsApiKey": "",
    "elevenLabsVoiceId": "21m00Tcm4TlvDq8ikWAM",
    "elevenLabsModelId": "eleven_multilingual_v2",
    "volume": 0.7,
    "speakChatResponses": true,
    "speakIdleChatter": false,
    "autoMuteFullscreen": true
  },
  "voiceInput": {
    "enabled": false,
    "sttProvider": "whisper",
    "sttApiKey": "",
    "language": "en",
    "includeScreenshot": false,
    "hotkey": "Ctrl+F2"
  },
  "pomodoroIntegration": {
    "enabled": true,
    "pipeName": "AemeathDesktopPet",
    "workStartedPrompt": "[Pomodoro Timer] I just started a {duration}-minute work session on \"{taskTitle}\". Say something short (1-2 sentences) to encourage me and remind me to focus.",
    "workFinishedPrompt": "[Pomodoro Timer] I just finished my pomodoro work session on \"{taskTitle}\"! Say something short (1-2 sentences) to celebrate and congratulate me.",
    "breakStartedPrompt": "[Pomodoro Timer] I'm starting a {breakType} break ({duration} minutes). Say something short (1-2 sentences) to help me relax or chat with me.",
    "breakFinishedPrompt": "[Pomodoro Timer] My break is over, time to get back to work. Say something short (1-2 sentences) to motivate me.",
    "taskAddedPrompt": "[Pomodoro Timer] I just added a new task to my to-do list: \"{taskTitle}\". React briefly (1 sentence)."
  },
  "activityMonitor": {
    "enabled": false,
    "databasePath": "D:\\Study\\Project\\Computer_and_Chrome_Monitor_with_AI_Analysis\\data\\monitor.db"
  },
  "companionApps": {
    "launchMonitor": false,
    "monitorPath": "D:\\Study\\Project\\Computer_and_Chrome_Monitor_with_AI_Analysis\\run.bat",
    "launchTodoList": false,
    "todoListPath": "D:\\Study\\Project\\To_Do_List\\run.bat"
  }
}
```

---

## Project Structure

```
AemeathDesktopPet/
├── AemeathDesktopPet.sln           # Solution file
├── run.bat / run.sh                # Launcher scripts
├── REQUIREMENTS.md                 # Full requirements document
├── CHECKLIST.md                    # Implementation checklist
├── aemeath_desktop_pet_design.md   # Detailed design document
│
├── src/AemeathDesktopPet/
│   ├── AemeathDesktopPet.csproj
│   ├── App.xaml / App.xaml.cs
│   ├── app.manifest                # DPI awareness (PerMonitorV2)
│   │
│   ├── Models/
│   │   ├── PetState.cs             # 26-state enum + AnimationInfo
│   │   ├── AppConfig.cs            # Config schema (TTS, STT, screen awareness, pomodoro)
│   │   ├── AemeathStats.cs         # Mood/Energy/Affection + offline decay
│   │   ├── ChatMessage.cs          # Chat message model
│   │   ├── CatState.cs             # 12-state cat enum
│   │   ├── PomodoroEvent.cs        # Pomodoro pipe message model
│   │   └── OfflineResponses.cs     # 100+ scripted character lines
│   │
│   ├── Engine/
│   │   ├── AnimationEngine.cs      # GIF frame decoder & playback
│   │   ├── BehaviorEngine.cs       # 26-state FSM, conditional weights
│   │   ├── PhysicsEngine.cs        # Gravity, collision, drag/throw
│   │   ├── EnvironmentDetector.cs  # Screen bounds & fullscreen detection
│   │   ├── GlitchEffect.cs         # Digital ghost visual effect
│   │   ├── ParticleSystem.cs       # 6 particle types, Canvas rendering
│   │   ├── PaperPlaneSystem.cs     # Thrown + ambient paper planes
│   │   ├── CatBehaviorEngine.cs    # Independent cat FSM
│   │   ├── WindowEdgeManager.cs    # Window title bar detection & perch
│   │   └── TimeAwareness.cs        # Time-of-day periods & conditions
│   │
│   ├── Services/
│   │   ├── ConfigService.cs        # JSON config load/save
│   │   ├── MusicService.cs         # Audio folder scan & playback
│   │   ├── StatsService.cs         # Stat tracking & interaction effects
│   │   ├── MemoryService.cs        # Chat history persistence
│   │   ├── JsonPersistenceService.cs  # Stats + messages JSON storage
│   │   ├── ClaudeApiService.cs     # Claude API with SSE streaming
│   │   ├── GeminiApiService.cs     # Gemini API with streaming
│   │   ├── ChatPromptBuilder.cs    # Shared system prompt for AI chat
│   │   ├── IChatService.cs         # Chat provider interface
│   │   ├── ITtsService.cs          # TTS service interface
│   │   ├── ITtsProvider.cs         # Internal TTS provider interface
│   │   ├── TtsVoiceService.cs      # Main TTS service (NAudio playback, queue)
│   │   ├── EdgeTtsProvider.cs      # Edge TTS (free, no API key)
│   │   ├── GptSovitsTtsProvider.cs # GPT-SoVITS (local server)
│   │   ├── ElevenLabsTtsProvider.cs # ElevenLabs (cloud API)
│   │   ├── VoiceInputService.cs    # NAudio microphone recording
│   │   ├── GlobalHotkeyService.cs  # Low-level keyboard hook for PTT
│   │   ├── WhisperSttService.cs    # OpenAI Whisper STT
│   │   ├── GeminiSttService.cs     # Gemini STT
│   │   ├── ISpeechToTextService.cs # STT provider interface
│   │   ├── ScreenCaptureService.cs # Screenshot capture + JPEG downscale
│   │   ├── IScreenAwarenessService.cs # Screen awareness interface
│   │   ├── ScreenAwarenessService.cs # Screen awareness (vision AI + privacy pipeline)
│   │   ├── PomodoroIntegrationService.cs # Named pipe server for To-Do List
│   │   ├── ActivityMonitorService.cs # Read-only SQLite access for activity data
│   │   ├── CompanionLauncherService.cs # Auto-launch companion programs
│   │   └── StartupService.cs         # Start with Windows registry management
│   │
│   ├── ViewModels/
│   │   ├── PetViewModel.cs         # Main orchestrator
│   │   └── ChatViewModel.cs        # Chat window logic + streaming + TTS
│   │
│   ├── Views/
│   │   ├── PetWindow.xaml/.cs      # Main transparent pet window
│   │   ├── ChatWindow.xaml/.cs     # AI chat window (dark theme)
│   │   ├── SettingsWindow.xaml/.cs # 6-tab settings panel
│   │   ├── StatsPopup.xaml/.cs     # Stats display with gradient bars
│   │   ├── SpeechBubble.xaml/.cs   # Themed speech bubble
│   │   └── CatWindow.xaml/.cs      # Cat companion window
│   │
│   ├── Interop/
│   │   └── Win32Api.cs             # P/Invoke (GetWindowLong, SetWindowPos, click-through)
│   │
│   ├── Themes/
│   │   └── AemeathTheme.xaml       # Color palette (11 named colors)
│   │
│   └── Resources/Sprites/
│       ├── Aemeath/                # 8 character GIF animations
│       └── Seal/                   # Seal transformation sprite
│
├── tests/AemeathDesktopPet.Tests/  # 532 tests across 37 classes
│   ├── Models/                    # 8 test classes
│   ├── Engine/                    # 8 test classes
│   ├── Services/                  # 15 test classes
│   ├── ViewModels/                # 2 test classes
│   └── Interop/                   # 1 test class
│
└── tests/TtsIntegrationTest/      # Console app for live TTS testing
```

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [Hardcodet.NotifyIcon.Wpf](https://github.com/hardcodet/wpf-notifyicon) | 1.1.0 | System tray icon |
| [System.Drawing.Common](https://www.nuget.org/packages/System.Drawing.Common) | 8.0.0 | GIF frame extraction |
| [NAudio](https://github.com/naudio/NAudio) | 2.2.1 | Audio recording (voice input) and TTS playback |
| [Edge_tts_sharp](https://www.nuget.org/packages/Edge_tts_sharp) | 1.1.7 | Free Edge TTS via WebSocket |
| [Microsoft.Data.Sqlite](https://www.nuget.org/packages/Microsoft.Data.Sqlite) | 8.0.0 | Read-only SQLite access for activity monitor |
| [xUnit](https://xunit.net/) | 2.6.6 | Unit testing (test project only) |

---

## Missing Assets & Stubbed Features

### Missing Assets

| Asset | Current Workaround | What's Needed |
|-------|-------------------|---------------|
| Black cat GIFs | Unicode emoji placeholder | ~80x80px sprite set (12 states) matching art style |
| Paper plane sprite | Unicode plane (✈) | ~32x32px PNG or small GIF |
| Tray icon | Build warning | `.ico` multi-resolution (16–256px) |
| App icon | None | `.ico` for window titlebar/taskbar |

---

## Tech Stack

- **C# / .NET 8** — WPF with `AllowsTransparency`
- **Win32 Interop** — `SetWindowLong`, `SetWindowPos`, `DwmGetWindowAttribute`, `EnumWindows`, `SetWinEventHook`
- **Hardcodet.NotifyIcon.Wpf** — System tray integration
- **NAudio** — Audio recording and TTS playback
- **Edge_tts_sharp** — Free Edge TTS synthesis
- **Microsoft.Data.Sqlite** — Read-only SQLite access for activity monitor integration
- **System.Text.Json** — Configuration and persistence
- **xUnit** — 532 unit tests across 37 test classes (5 categories)

---

## About Aemeath

Aemeath (爱弥斯) is a character from Wuthering Waves. A digital ghost who lost her physical body, she exists as a virtual idol known as "Fleet Snowfluff" (@fltsnflf). Bubbly and optimistic on the surface, with an underlying melancholy captured in her signature line: *"Did you see me?"*

This project is a fan-made desktop companion. All character rights belong to Kuro Games.

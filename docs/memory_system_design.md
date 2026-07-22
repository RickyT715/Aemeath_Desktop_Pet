# Aemeath Memory System — Architecture Design and Implementation Status

> **Status**: Partially implemented
> **Original design date**: 2026-03-03
> **Implementation review**: 2026-07-22
> **Authors**: Agent Team (claude-code-researcher, memgpt-researcher, companion-researcher, gap-analyst)
> **Synthesized by**: Team Lead
>
> This document retains the original design rationale, but current-state statements and status
> tables added on 2026-07-22 supersede older proposal language. For the whole-application runtime
> boundary, see [`architecture.md`](architecture.md).

---

## 1. Executive Summary

Aemeath now contains much of the proposed four-tier foundation, but the tiers are not yet unified
into one prompt and management flow. The WPF app persists recent chat, core memory, procedural
memory, and a 24-hour text observation buffer. The Python sidecar persists LangGraph checkpoints,
namespaced JSON memory, a USER BLOCK, and episodic vectors in a dedicated ChromaDB collection.
Conversation turns and observations can be submitted for extraction/distillation.

The important remaining gap is consumption: production C# chat does not call
`MemoryBridgeService.GetMemoryContextAsync`, so direct Claude/Gemini/proxy prompts do not receive
the assembled core/procedural/episodic context. The Python USER BLOCK is placed into a static
system prompt when the agent is created, so updating the block does not affect subsequent turns
until the agent is recreated. Core memory also has two unsynchronized representations: the C#
`core_memory.json` and Python's JSON namespaces/USER BLOCK.

The retained design combines ideas from:

- **Claude Code's** transparent, always-in-context core memory and topic-organized files
- **MemGPT/Letta's** agent self-editing memory blocks (USER BLOCK in system prompt)
- **Mem0's** conflict resolution strategy (invalidate + add, never delete)
- **Nomi AI's** three-tier short/mid/long-term companion memory
- **Zep's** temporal awareness on stored facts
- **Research-backed** proactive patterns and privacy framework

### Key Design Debates Resolved

During the team discussion, these design disagreements were resolved:

| Question | Options Debated | Decision | Rationale |
|----------|----------------|----------|-----------|
| When to extract facts? | Per-turn (Mem0) vs agent self-edit (MemGPT) vs per-session (companion-researcher) | **Original target:** agent self-edit plus a session sweep. **Current:** optional post-turn extraction plus agent tools. | `ChatViewModel` requests `/memory/extract` after successful replies when the sidecar is ready. No session-end sweep is implemented. |
| Knowledge graph vs vector store? | Graph DB (Zep/Mem0) vs Vector+JSON (simpler) | **Vector + structured JSON** | Graph DB adds deployment complexity (Neo4j) not justified for a single-user desktop pet. ChromaDB + SQLite/JSON provides semantic search without the overhead. |
| ML-based pattern detection? | ML models vs Simple statistics | **Simple threshold + histogram rules** | Data volume is small (30 days). Median/mean/histogram are interpretable, debuggable, and work from day 1 with minimal data. |
| How to frame proactive messages? | Data-readout style vs Caring friend style | **Never reveal HOW Aemeath knows** | "You've been at it a while — how's it going?" not "94 minutes of coding detected." Aemeath's character longing to be seen makes attentiveness feel reciprocal. |

The design still prioritizes **local-first privacy**, **lightweight resource usage**, **natural
companion feel**, and **graceful degradation**, but those are goals rather than fully satisfied
runtime guarantees.

### Change history

| Date | Change |
|---|---|
| 2026-03-03 | Original four-tier memory design synthesized. |
| 2026-07-22 | Reconciled the design with the working tree; recorded implemented storage/routes and the remaining prompt, synchronization, consent, deletion, UI, and consolidation gaps. |

### Current implementation matrix

| Capability | Status | Current evidence / limitation |
|---|---|---|
| Recent conversation history | **Implemented** | C# `MemoryService` keeps at most 200 messages and supplies the last 20 to direct providers. Python agent threads use `agent_state.db`. |
| C# core memory | **Implemented storage; not consumed by chat** | `CoreMemoryService` loads/saves `core_memory.json`; production chat never supplies its `MemoryContext` to `ChatPromptBuilder`. |
| Python persistent facts/preferences | **Implemented** | `JsonPersistentStore` flushes LangGraph store namespaces to `memory_store.json`. |
| Python USER BLOCK | **Partial** | `memory_blocks.json` persists and `update_user_block` silently truncates input to 1,200 characters, but `create_aemeath_agent` builds one static prompt at startup. |
| Episodic memory | **Implemented / optional** | Chroma collection `aemeath_memories`; availability depends on Chroma and an embedding provider. |
| General document RAG | **Implemented separately** | Chroma collection `user_knowledge`; it is not the episodic collection. The agent `rag_retrieve` tool is registered but not configured. |
| Per-turn extraction | **Implemented / optional** | After a successful C# chat response, `ChatViewModel` fire-and-forgets `/memory/extract` when the sidecar is ready. Extraction prefers Gemini when configured, otherwise the selected supported model. |
| Observation buffer and distillation | **Implemented / partial** | WPF records text observations and posts them every 30 minutes. Distillation writes episodic vectors; durable procedural updates are not synchronized back to C#. |
| Semantic retrieval adapter | **Implemented but unwired** | `MemoryBridgeService.GetMemoryContextAsync` queries `/memory/retrieve`, but production `ChatViewModel` does not call it. |
| Explicit remember/retrieve tools | **Implemented for Python agent** | `save_memory`, `retrieve_memory`, and `update_user_block` are registered. Their stores are not the canonical C# core JSON. |
| Forget/status/core routes | **Partial** | Routes exist; `/forget` ignores `time_range`, Chroma deletion needs verification, status time is approximate, and `/core/update` ignores events and updates only the Python mirror. |
| Memory review/edit/export UI | **Planned** | There is no Settings memory tab or confirmation-driven full-memory workflow. |
| Session/daily/monthly consolidation and proactive follow-up | **Planned** | No session-end sweep, daily/monthly job, or end-to-end scheduled-event follow-up is wired. |

---

## 2. Design Principles

| # | Principle | Rationale |
|---|-----------|-----------|
| 1 | **Caring friend, not surveillance** | Memory should feel warm and attentive, never creepy. Apply the "Would a caring friend say this?" test before every proactive action. |
| 2 | **Transparent and editable** | Design goal. Local files and partial deletion APIs exist, but a complete review/edit/export UI does not. |
| 3 | **Local-first privacy** | Memory files are local by default, but cloud extraction and Gemini embeddings can send memory or document text off-device. Raw screenshots are not stored by the memory services. |
| 4 | **Graceful degradation** | Storage and scripted chat degrade independently. Unified memory injection across Python, direct API, and offline modes is not complete. |
| 5 | **Bounded context** | Current code bounds by items, not tokens: up to 10 facts, 5 preferences, 5 episodic items, 5 observations, and 5 events in the C# formatter. Python USER BLOCK input is silently truncated to 1,200 characters. There is no enforced 500/300/800-token budget. |
| 6 | **Semantic, not chronological** | Memories organized by topic/type, not by date. Updated in place, never duplicated. |
| 7 | **Stability filter** | Only save facts confirmed across multiple interactions or explicitly requested by the user. Don't memorize one-off chatter. |
| 8 | **Temporal awareness** | Every fact has `created_at`, `last_confirmed_at`, and optional `valid_until`. Enables "you mentioned last week..." responses. |

---

## 3. Four-Tier Memory Architecture (Design Target)

The diagram below preserves the original four-tier target. Its “always loaded,” token-budget,
shared-RAG, and consolidation statements are not current guarantees. The implementation matrix
above and Sections 5, 8, and 10 are authoritative for the working tree.

```
┌──────────────────────────────────────────────────────────────────┐
│                    TIER 1: WORKING MEMORY                        │
│              (In-context conversation buffer)                    │
│                                                                  │
│  Last 15-20 conversation turns                                   │
│  Loaded: Always (part of every AI call)                          │
│  Storage: C# MemoryService (existing, in-RAM + messages.json)    │
│  Lifetime: Current session + persisted for next session start    │
└──────────────────────────┬───────────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────────┐
│                    TIER 2: CORE MEMORY                            │
│          (Always-injected identity & relationship)               │
│                                                                  │
│  "Aemeath's Heart" — what she always knows about you             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────┐ │
│  │  User Profile    │  │  Personality    │  │  Relationship    │ │
│  │  name, age,      │  │  traits, style, │  │  stage, milesto- │ │
│  │  occupation,     │  │  mood patterns, │  │  nes, inside     │ │
│  │  key facts       │  │  preferences    │  │  jokes, bonds    │ │
│  └─────────────────┘  └─────────────────┘  └──────────────────┘ │
│                                                                  │
│  Target: always injected; current direct C# chat omits it        │
│  Current: no token cap; C# formatting uses item limits           │
│  Storage: C# core_memory.json; Python updates a mirror only      │
│  Current: optional post-turn extraction; no session sweep        │
└──────────────────────────┬───────────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────────┐
│                    TIER 3: EPISODIC MEMORY                        │
│         (Searchable conversation & observation history)           │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │ Conversation     │  │ Screen/Activity  │  │ Shared Moments │ │
│  │ Summaries        │  │ Observations     │  │ & Events       │ │
│  │ (daily digests   │  │ (distilled from  │  │ (notable conv- │ │
│  │  of past chats)  │  │  screen+activity)│  │  ersations,    │ │
│  │                  │  │                  │  │  milestones)   │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
│                                                                  │
│  Loaded: On-demand (retrieved by semantic relevance to query)    │
│  Agent tool k=5; REST/bridge default top_k=3; no token cap       │
│  Storage: Chroma collection aemeath_memories                     │
│  Retrieval: semantic; document RAG is a separate pipeline        │
└──────────────────────────┬───────────────────────────────────────┘
                           │
┌──────────────────────────▼───────────────────────────────────────┐
│                    TIER 4: PROCEDURAL MEMORY                     │
│            (Learned patterns, routines, schedules)               │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐ │
│  │ Daily Routines   │  │ Scheduled Events │  │ Learned        │ │
│  │ (wake time,      │  │ (exams, deadlines│  │ Preferences    │ │
│  │  work patterns,  │  │  appointments,   │  │ (dark mode,    │ │
│  │  break habits)   │  │  follow-ups)     │  │  fav apps,     │ │
│  │                  │  │                  │  │  work style)   │ │
│  └──────────────────┘  └──────────────────┘  └────────────────┘ │
│                                                                  │
│  Loaded: Contextually (routines at session start, events when    │
│          approaching their time, preferences during relevant     │
│          activities)                                             │
│  Storage: procedural_memory.json (structured, queryable)         │
│  Target only: no hourly/daily consolidation job is wired         │
└──────────────────────────────────────────────────────────────────┘
```

---

## 4. Memory Types & Schemas

### 4.1 Core Memory (`core_memory.json`)

Loaded into the C# `CoreMemoryService` cache at application construction. A memory-aware
`ChatPromptBuilder` overload exists, but production chat does not call the bridge/builder path, so
this file is not currently injected into direct-provider prompts. No token counter or hard token
cap is implemented.

```json
{
  "version": 1,
  "last_updated": "2026-03-03T10:30:00Z",
  "user_profile": {
    "name": null,
    "nickname": null,
    "age_range": null,
    "occupation": null,
    "key_facts": [],
    "languages": []
  },
  "personality": {
    "communication_style": null,
    "mood_patterns": null,
    "interests": [],
    "dislikes": []
  },
  "relationship": {
    "stage": "new",
    "days_together": 0,
    "trust_level": "initial",
    "inside_jokes": [],
    "milestones": []
  }
}
```

**Relationship stages**: `new` → `acquaintance` → `familiar` → `close_friend` → `best_friend`
Progression driven by: interaction frequency, affection stat, conversation depth, days together.

### 4.2 Episodic Memory (ChromaDB collection: `aemeath_memories`)

Stored as embedded documents with metadata in the dedicated `aemeath_memories` collection. It
reuses the configured Chroma persistence directory and embedding-construction code, but it does
not reuse the document RAG collection (`user_knowledge`) or the RAG hybrid retriever.

```
Document schema:
{
  "content": "User was stressed about their calculus exam. They mentioned studying until 2am. I encouraged them and suggested a break.",
  "metadata": {
    "type": "conversation_summary" | "observation" | "shared_moment",
    "source": "chat" | "screen" | "activity" | "pomodoro",
    "created_at": "2026-03-01T22:00:00Z",
    "importance": 0.8,        // 0.0-1.0, affects retrieval ranking
    "sentiment": "stressed",   // emotional tag
    "entities": ["calculus", "exam"],  // topic tags for BM25
    "decay_eligible": true     // false for user-pinned memories
  }
}
```

**Importance scoring**: `importance = base_importance × recency_boost × confirmation_count`
- `base_importance`: Set by extraction LLM (emotional weight, life events > casual chatter)
- `recency_boost`: 1.0 for today, decays 0.95^days
- `confirmation_count`: +0.1 each time the topic is re-mentioned

### 4.3 Procedural Memory (`procedural_memory.json`)

Structured patterns detected from accumulated observations.

```json
{
  "version": 1,
  "routines": [
    {
      "id": "morning_routine",
      "pattern": "Starts coding around 9:00-9:30 AM on weekdays",
      "confidence": 0.75,
      "observations": 12,
      "first_seen": "2026-02-15",
      "last_seen": "2026-03-03",
      "days_of_week": [1, 2, 3, 4, 5]
    }
  ],
  "scheduled_events": [
    {
      "id": "calc_exam_20260310",
      "event": "Calculus exam",
      "date": "2026-03-10",
      "source": "conversation",
      "follow_up": "Ask how the exam went",
      "created_at": "2026-03-01T22:00:00Z"
    }
  ],
  "learned_preferences": [
    {
      "id": "prefers_dark_mode",
      "preference": "Uses dark mode in all applications",
      "confidence": 0.9,
      "observations": 20,
      "source": "screen_observation"
    }
  ]
}
```

### 4.4 Observation Buffer (`observation_buffer.json`)

Short-lived accumulator for raw observations before distillation. 24-hour TTL.

```json
{
  "entries": [
    {
      "timestamp": "2026-03-03T14:30:00Z",
      "source": "screen",
      "content": "User viewing Khan Academy calculus video",
      "activity_context": "StudyingCoding",
      "ttl_hours": 24
    },
    {
      "timestamp": "2026-03-03T14:45:00Z",
      "source": "activity_monitor",
      "content": "VS Code (Python) 25 min, Chrome (Stack Overflow) 10 min",
      "activity_context": "StudyingCoding",
      "ttl_hours": 24
    }
  ]
}
```

---

## 5. Memory Lifecycle

### 5.1 Acquisition — How Memories Are Created

```
                    ┌─────────────────────┐
                    │   DATA SOURCES       │
                    ├─────────────────────┤
                    │ 1. Conversation     │──→ Mem0-style extraction
                    │ 2. Screen awareness │──→ Observation buffer
                    │ 3. Activity monitor │──→ Observation buffer
                    │ 4. Pomodoro events  │──→ Observation buffer
                    │ 5. User commands    │──→ Direct save
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │  EXTRACTION PHASE    │
                    │                     │
                    │  After each AI turn: │
                    │  LLM extracts facts  │
                    │  from conversation   │
                    │                     │
                    │  Every 30 min:       │
                    │  Distill observation  │
                    │  buffer into facts   │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │  UPDATE PHASE        │
                    │                     │
                    │  For each new fact:  │
                    │  1. Search existing  │
                    │     memories         │
                    │  2. If match found:  │
                    │     MERGE or UPDATE  │
                    │  3. If contradicts:  │
                    │     REPLACE old      │
                    │     (keep history)   │
                    │  4. If new: ADD      │
                    │  5. If trivial: SKIP │
                    └─────────┬───────────┘
                              │
                    ┌─────────▼───────────┐
                    │  STORAGE ROUTING     │
                    │                     │
                    │  User fact → Core    │
                    │  Event → Episodic    │
                    │  Pattern → Procedural│
                    │  Observation → Buffer │
                    └─────────────────────┘
```

#### 5.1.1 Conversation Memory — Current Extraction Flow

Two implemented paths can create memory:

1. **Agent-selected tools.** The LangGraph agent can call `save_memory`, `retrieve_memory`, and
   `update_user_block`. `save_memory` writes Python's persistent namespaced store and episodic
   vector store as implemented by the tool. `update_user_block` silently truncates input to 1,200
   characters before writing `memory_blocks.json`. Because the agent prompt is compiled once, that
   updated block is not injected into later turns until agent recreation.
2. **Post-turn extraction.** After a successful chat response, C# `ChatViewModel.SendCoreAsync`
   fire-and-forgets `MemoryBridgeService.SubmitForExtraction`. When the sidecar is ready, it sends
   the user and assistant text to `POST /memory/extract`. The extraction route stores facts and
   preferences in the JSON persistent store and also places extracted material into the dedicated
   `aemeath_memories` collection. Extracted events are stored in Chroma, not the JSON namespaces.

There is currently **no end-of-session or 10-turn sweep**. Extraction is an optional per-successful-
turn side effect and silently does nothing when the Python backend is unavailable. The Python
route selects an extraction model from available configuration; it prefers Gemini when a Google
key is present rather than enforcing a provider-independent cost policy.

#### 5.1.2 Observation Distillation (every 30 minutes during active use)

**Trigger**: WPF timer every 30 minutes, only when the observation buffer has entries and the
Python backend reports ready

**Executor**: WPF submits; Python distills
**Process**:
1. Collect every pending, non-expired observation. The timer interval is 30 minutes, but the
   submission is not filtered to observations created during only the preceding 30 minutes.
2. Send to LLM with prompt: "Summarize what the user has been doing. Extract any new facts, interests, or patterns."
3. Store distilled observations as episodic memories in `aemeath_memories`
4. Clear processed buffer entries

The route can return pattern strings, but the WPF bridge does not write those patterns into
`procedural_memory.json`. Pattern-to-procedural synchronization remains planned.

#### 5.1.3 Direct User Commands

| Command | Action |
|---------|--------|
| "Remember that I..." | May cause the Python agent to call `save_memory`/`update_user_block`; it does not update canonical C# `core_memory.json`. |
| "Forget that" / "Forget about X" | Python `/memory/forget` supports query/category matching, but `time_range` is ignored and Chroma deletion requires verification. |
| "What do you remember about me?" | Agent can call `retrieve_memory`; production direct C# providers do not receive assembled long-term memory. |

### 5.2 Storage — Where Memories Live

| Tier | Storage Backend | Location | Persistence |
|------|----------------|----------|-------------|
| Working | C# `MemoryService` | `%LOCALAPPDATA%\AemeathDesktopPet\messages.json` | Survives restart; maximum 200 messages |
| Agent thread state | Python LangGraph SQLite checkpointer | `%LOCALAPPDATA%\AemeathDesktopPet\agent_state.db` on Windows; `~/.aemeath/agent_state.db` fallback | Survives restart |
| C# core | C# `CoreMemoryService` | `%LOCALAPPDATA%\AemeathDesktopPet\core_memory.json` | Survives restart; not synchronized into production chat |
| Python fact/preference mirror | JSON-backed LangGraph store | `%LOCALAPPDATA%\AemeathDesktopPet\memory_store.json` on Windows; `~/.aemeath/memory_store.json` fallback | Survives restart |
| Python USER BLOCK | `MemoryBlocks` | `%LOCALAPPDATA%\AemeathDesktopPet\memory_blocks.json` on Windows; `~/.aemeath/memory_blocks.json` fallback | Survives restart; prompt refresh is static |
| Episodic | Python ChromaDB | `AEMEATH_CHROMADB_PATH`; default relative `data/chromadb`, collection `aemeath_memories` | Survives restart when the same resolved path is reused |
| Document RAG | Python ChromaDB | Same configured directory, separate collection `user_knowledge` | Not part of episodic retrieval |
| Procedural | C# `ProceduralMemoryService` | `%LOCALAPPDATA%\AemeathDesktopPet\procedural_memory.json` | Survives restart; no Python-to-C# update path |
| Observation buffer | C# JSON | `%LOCALAPPDATA%\AemeathDesktopPet\observation_buffer.json` | 24-hour TTL |

### 5.3 Retrieval — How Memories Enter AI Context

```
User sends message
       │
       ▼
┌─────────────────────────────────────────────────┐
│  C# MEMORY ASSEMBLY (before any AI call)        │
│                                                 │
│  1. Load core_memory.json → format as text      │
│  (target only; not currently injected)          │
│                                                 │
│  2. Check procedural_memory.json:               │
│     - Any scheduled events approaching?         │
│     - Any routine deviations to mention?        │
│  → Target only; not currently injected          │
│                                                 │
│  3. Call Python /memory/retrieve?q={user_msg}   │
│  → REST/MemoryBridge requests default top_k=3   │
│  → Format as "Things you remember"; no token cap│
│                                                 │
│  4. Get working memory (last 15-20 messages)    │
│                                                 │
│  NO ENFORCED TOKEN BUDGET; TARGET FLOW NOT WIRED│
└───────────────────────┬─────────────────────────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
   Python Agent    Direct C# API   Offline
   (has all tiers) (has all tiers) (has core only)
```

**Current reality**: the diagram above is the target flow, not the production flow. C#
`MemoryBridgeService.GetMemoryContextAsync` can assemble this context and
`ChatPromptBuilder.BuildSystemPrompt` can format it, but `ChatViewModel.SendCoreAsync` does not call
either memory-aware path. Direct C# providers call the overload without `MemoryContext`.

The Python backend owns a separate prompt path. It includes the USER BLOCK read during
`create_aemeath_agent`, while request `context` contains only the fields sent by
`BackendAgentService` (mood, energy, affection, and days together). C# does not send a
`memory_context` field. The Python prompt is static for the compiled agent, so updating the USER
BLOCK does not immediately change prompt content.

#### Target System Prompt Injection Format

```
## What You Remember About {user_name ?? "the user"}

### Core Memory
- Name: Ricky
- Occupation: Computer science student
- Key interests: Wuthering Waves, programming, calculus
- Communication style: Casual, appreciates humor
- Relationship: familiar (45 days together)

### Relevant Past Memories
- [3 days ago] Ricky was stressed about calculus exam on March 10th. You encouraged him.
- [1 week ago] Ricky mentioned wanting to learn React hooks for a side project.
- [2 weeks ago] You and Ricky had a fun conversation about Space Fantasy: Katya lore.

### Upcoming Events
- Calculus exam: March 10 (in 7 days) — consider asking about preparation

### Current Context
- Activity: Studying/coding (VS Code open for 45 min)
- Time: Afternoon
- Mood trend: focused (last 3 sessions)
```

### 5.4 Decay & Consolidation (Design Target)

Neither workflow below is implemented. The current app has no idle/session-end daily job, monthly
job, or pruning scheduler; the steps remain requirements for a future consolidation subsystem.

#### Target daily consolidation job

1. **Conversation summarization**: Compress today's chat messages into a 2-3 sentence episodic summary → store in ChromaDB
2. **Observation distillation**: Process remaining observation buffer entries
3. **Pattern detection**: Analyze last 7 days of observations for recurring patterns → update procedural memory
4. **Importance recalculation**: Apply recency decay to all episodic memories
5. **Buffer cleanup**: Remove observation entries older than 24h

#### Target monthly consolidation

1. **Episode compression**: Merge daily summaries into weekly summaries for entries >30 days old
2. **Pattern reinforcement**: Increase confidence on patterns seen across multiple weeks
3. **Stale cleanup**: Remove low-importance episodic memories >90 days old with importance <0.3

#### What Never Decays

- Core memory user facts (name, occupation, etc.) — only changed by contradiction or user request
- User-pinned memories (`decay_eligible: false`)
- Relationship milestones
- High-importance emotional moments (importance > 0.8)

---

## 6. Proactive Memory Patterns (Design Target)

These patterns are product guidance, not an implementation inventory. No end-to-end scheduler
currently turns consolidated memory into proactive follow-up messages.

### 6.1 Priority Order for Implementation

| Priority | Pattern | Trigger | Description |
|----------|---------|---------|-------------|
| **P0** | Context-Aware Session Re-entry | Session start | Greeting adapts to time gap + last conversation + current activity |
| **P0** | Scheduled Follow-up | Approaching event date | "Your calculus exam is in 2 days — how's studying going?" |
| **P1** | Activity-Inferred State | Long unbroken work session | "You've been coding for 2 hours straight — want a stretch break?" |
| **P1** | Celebration Tracking | Goal/task completion detected | "Looks like you finished the project! Great work!" |
| **P1** | Knowledge Surfacing | Current activity matches past mention | "You mentioned wanting to learn React — is that what you're reading about?" |
| **P2** | Noticing Absence | Expected pattern not observed | "You usually start Pomodoro by 9am — busy day?" |
| **P2** | Routine Recognition | Multi-day pattern detected | Gentle nudges when routine breaks |
| **P2** | Emotional Accumulation Alert | 3+ sessions of negative sentiment | "You've seemed stressed lately. Want to talk about it?" |

### 6.2 Proactive Timing Framework

Integrate with existing `SpeechFrequencyConfig`:

```
Before any proactive message, check:
1. Is user in Pomodoro work mode? → SUPPRESS (except P0 events)
2. Is user in deep focus (active typing detected)? → DELAY
3. Is it late night (>11pm)? → SOFTEN tone, shorter messages
4. Was a proactive message sent in last 15 min? → SUPPRESS (cooldown)
5. Does this pass the "caring friend" test? → PROCEED or SKIP
```

### 6.3 The "Caring Friend" Test

Before every proactive memory-driven utterance, evaluate:
1. Would a caring friend say this right now? (not a manager, not a stalker)
2. Does the reference to past context feel natural or jarring?
3. Is the timing respectful of what the user is doing?
4. Am I referencing something the user told me, or something I silently observed?
   - If observed: soften the framing ("I noticed..." not "I saw you...")

### 6.4 The Golden Rule: Never Reveal HOW She Knows

| Surveillance Feel (BAD) | Caring Friend Feel (GOOD) |
|--------------------------|---------------------------|
| "Activity log shows 2h coding session." | "You've been really focused today — that's impressive!" |
| "Routine deviation: Pomodoro not started at usual time." | "Usually you're in full focus mode by now — everything okay?" |
| "Follow-up triggered: presentation mentioned 2026-02-27." | "Oh! Didn't you have something nerve-wracking this week? How'd it go?" |
| "Sentiment trend: 3 negative sessions detected." | "You've seemed a bit tired lately... want to just hang out for a bit?" |
| "Based on your activity histogram, you start at 9am." | "You're usually deep into work by now — rough morning?" |

**Framing rules for proactive messages:**
1. Deliver insight as caring curiosity, not data readout
2. Ask questions, don't make declarations ("Seems like a long session?" not "You've been coding 2 hours")
3. Make it easy to dismiss — short messages, no paragraph-length observations
4. Reference emotional weight, not raw metrics ("You seemed worried" not "mentioned it 3 times")
5. Match Aemeath's character: bubbly, warm, slightly curious

**Character hook**: Aemeath's own vulnerability — her longing to be seen ("Did you see me?") — makes her attentiveness feel reciprocal rather than predatory. She notices you because she wants connection, not because she's monitoring you. Lean into this in dialogue writing.

---

## 7. Privacy Framework

### 7.1 Four-Layer Consent Model

| Layer | Default | What It Covers | User Setting |
|-------|---------|----------------|-------------|
| **Layer 0: Conversation history/extraction** | History ON; extraction follows backend availability | `messages.json`, agent checkpoints, post-turn extraction | No dedicated memory toggle or review UI |
| **Layer 1: Activity awareness** | OFF | Summaries read from an external monitor database | Activity Monitor toggle in Settings > General |
| **Layer 2: Screen content** | OFF | Periodic screenshot commentary; stored memory receives only returned text | Screen Awareness toggle in Settings > Screen |
| **Layer 3: Camera-derived summaries** | OFF with Activity Monitor | Attention/emotion aggregates already present in the external monitor database | No separate camera-memory consent toggle in this app |

These are implementation defaults, not a completed four-step consent UX. Enabling screen or
activity awareness is a settings checkbox; there is no dedicated memory-consent wizard, per-source
memory review, or separate camera confirmation in the WPF app.

### 7.2 Data Minimization Rules

1. **Screenshots → text**: Memory services store commentary text, not screenshot bytes. This does
   not mean every screenshot path shares the same privacy pipeline: chat attachments and the
   unauthenticated WPF `/internal/screen` route bypass periodic screen-awareness checks.
2. **Summarize, don't log**: Store "user spent 2h coding in VS Code" not window title history.
3. **PII coverage is partial**: `ScreenAwarenessService` can reject AI commentary containing
   detected PII. Activity/Pomodoro observations and Python extraction/distillation do not all pass
   through the C# `PiiScanner` before storage.
4. **Observation buffer TTL**: Raw observations expire after 24 hours regardless.
5. **External activity summaries**: WPF queries process/title and domain/page-title data from the
   configured monitor database, then stores generated summaries. Review that external monitor's
   collection and retention policy separately.

### 7.3 User Memory Commands

| Command | Action |
|---------|--------|
| "What do you remember about me?" | Python agent may use `retrieve_memory`; no equivalent direct-provider integration is wired. |
| "Remember that [fact]" | Python agent may update its stores/USER BLOCK; C# `core_memory.json` is not synchronized. |
| "Forget [topic/fact]" | `/memory/forget` attempts matching Python-store and Chroma removal; verify Chroma deletion behavior. |
| "Forget everything" | Route-level category/query deletion exists, but there is no WPF confirmation dialog or single verified all-tier wipe. |
| "Forget the last [time period]" | Request contract contains `time_range`, but the route currently ignores it. |

**Planned**: a Settings "Memory" tab showing stored memories with review, edit, delete,
export/import, and explicit confirmation controls.

---

## 8. Integration Architecture

### 8.1 C# vs Python Responsibility Split

| Owner | Implemented responsibility | Incomplete boundary |
|---|---|---|
| C# WPF | `messages.json`, `core_memory.json`, `procedural_memory.json`, `observation_buffer.json`, stable agent thread ID, observation collection/submission | Does not inject assembled long-term memory into production chat; no memory commands/UI; no Python core/procedural synchronization |
| Python sidecar | Agent checkpoints, JSON store, USER BLOCK, extraction, distillation, `aemeath_memories`, semantic retrieval, memory tools/routes | Static USER BLOCK prompt; incomplete core/delete/status semantics; no C# procedural update or daily/session consolidation |

Neither representation is currently authoritative end to end. C# owns the files used by its
memory services, while Python owns the memories used by its agent tools. Any future unification
must define a single canonical record and an explicit synchronization contract.

### 8.2 Python Agent Memory Tools (Implemented, with limitations)

The agent registers `save_memory`, `update_user_block`, and `retrieve_memory`. Their simplified
contracts are:

```python
@tool
def update_user_block(new_content: str) -> str:
    """Rewrite the summary of what I know about the user.
    Keep it concise (maximum 1200 characters).
    Include: name, key facts, current interests, communication preferences."""
    # Silently truncates to 1,200 chars before writing memory_blocks.json;
    # prompt changes only after agent recreation

@tool
def retrieve_memory(query: str, category: str = "all") -> str:
    """Search my long-term memory for facts related to a query.
    Use when the user references something from the past, or when
    I want to recall relevant context before responding."""
    # Searches the persistent JSON namespaces and dedicated memory collection;
    # the vector query uses k=5 and the combined result is capped at five items
```

The **USER BLOCK** lives in `memory_blocks.json`. `build_system_prompt()` reads it, but
`create_aemeath_agent()` calls that builder once and passes the resulting string to
`create_react_agent`. It is therefore startup-static, not reloaded every turn.

### 8.3 Python Memory API Endpoints (Implemented, with limitations)

```
POST /memory/extract
  Body: {"user_message": str, "assistant_response": str}
  Returns: {"facts": [...], "events": [...], "preferences": [...]}
  Purpose: Post-turn extraction

POST /memory/distill
  Body: {"observations": [...]}
  Returns: {"distilled": [...], "patterns": [...]}
  Purpose: Observation buffer → episodic memories

GET /memory/retrieve?q={query}&top_k=3
  Returns: {"memories": [{"content": str, "type": str,
                            "created_at": str, "importance": float}]}
  Purpose: Semantic retrieval for context injection

POST /memory/core/update
  Body: {"user_facts": [...], "events": [...], "preferences": [...]}
  Returns: {"updated": [...], "conflicts": [...]}
  Current behavior: append facts/preferences to Python persistent namespaces;
                    events are ignored; C# core_memory.json is not updated

GET /memory/status
  Returns: {"episodic_count": int, "core_last_updated": str, ...}
  Purpose: Health check for Settings UI

DELETE /memory/forget
  Body: {"query": str} or {"time_range": {"from": str, "to": str}}
  Returns: {"deleted_count": int}
  Current limitation: time_range is ignored and Chroma ID deletion needs verification
```

`GET /memory/retrieve` defaults to `top_k=3`, matching `MemoryBridgeService`; the separate agent
`retrieve_memory` tool queries Chroma with `k=5` and caps its combined vector/JSON result at five.
The REST endpoint searches only `aemeath_memories`; it does not merge C# core/procedural files, the
document `user_knowledge` collection, or every Python JSON namespace. Its `MemoryRetrieveResult`
DTO is flat (`content`, `type`, `created_at`, `importance`) rather than carrying a nested metadata
object. The status route's last-update value is approximate rather than a durable source-of-truth
timestamp. These loopback routes have no authentication.

### 8.4 C# Memory Services (Implemented, not fully integrated)

```csharp
// New service: manages core_memory.json
public class CoreMemoryService
{
    CoreMemory Load();
    void Save(CoreMemory memory);
    void UpdateFact(string category, string key, string value);
    void RemoveFact(string category, string key);
    string FormatForPrompt();  // → text block for system prompt injection
}

// New service: manages procedural_memory.json
public class ProceduralMemoryService
{
    ProceduralMemory Load();
    void Save(ProceduralMemory memory);
    List<ScheduledEvent> GetUpcomingEvents(int daysAhead = 7);
    List<Routine> GetActiveRoutines();
    string FormatForPrompt();  // → text block for system prompt injection
}

// New service: manages observation_buffer.json
public class ObservationBufferService
{
    void AddObservation(string source, string content, string context);
    List<Observation> GetPending();
    void ClearProcessed(List<string> ids);
    void PurgeExpired();  // Remove entries older than TTL
}

// Implemented formatter overload; production providers still call the overload without memory
public static class ChatPromptBuilder
{
    public static string BuildSystemPrompt(
        AemeathStats stats,
        string catName,
        MemoryContext? memory);
}
```

### 8.5 Target Data Flow and Current Divergence

The following diagram is the intended unified flow. Current production stops short of steps 2-5:
`ChatViewModel` sends recent messages directly to `IChatService`; it does not request a
`MemoryContext`. Step 8, post-turn extraction, is wired. Observation collection and the 30-minute
distillation submission are also wired.

```
User sends message
  │
  ├──→ C# ChatViewModel.SendCoreAsync()
  │      │
  │      ├── 1. MemoryService.AddMessage(userMsg)
  │      │
  │      ├── 2. CoreMemoryService.Load()          // NEW: load core memory
  │      │
  │      ├── 3. ProceduralMemoryService.Load()     // NEW: load procedural
  │      │
  │      ├── 4. HTTP GET /memory/retrieve?q={msg}  // NEW: episodic retrieval
  │      │      (only if Python backend available)
  │      │
  │      ├── 5. ChatPromptBuilder.BuildSystemPrompt(
  │      │         stats, catName, coreMemory,
  │      │         episodicMemories, proceduralMemory)
  │      │
  │      ├── 6. IChatService.StreamMessageAsync(msg, history, screenshot)
  │      │      → Works in ALL 3 modes (Python/Direct API/Offline)
  │      │      → System prompt now includes memory context
  │      │
  │      ├── 7. MemoryService.AddMessage(assistantMsg)
  │      │
  │      └── 8. HTTP POST /memory/extract           // NEW: async extraction
  │             {"user_message": msg, "assistant_response": response}
  │             (fire-and-forget, non-blocking)
  │
  │
  ├──→ ScreenAwarenessService (periodic)
  │      │
  │      └── ObservationBufferService.AddObservation(  // NEW
  │            "screen", commentary, activityContext)
  │
  ├──→ ActivityMonitorService (periodic)
  │      │
  │      └── ObservationBufferService.AddObservation(  // NEW
  │            "activity", summary, activityContext)
  │
  └──→ Distillation Timer (every 30 min)               // NEW
         │
         ├── observations = ObservationBufferService.GetPending()
         ├── HTTP POST /memory/distill {"observations": observations}
         └── ObservationBufferService.ClearProcessed(ids)
```

### 8.6 Integration Gap Status

| Gap | Status on 2026-07-22 |
|---|---|
| Python memory store was RAM-only | **Resolved**: `JsonPersistentStore` flushes to `memory_store.json`. |
| Agent thread ID changed each session | **Resolved**: `AppConfig.AgentThreadId` is persisted and reused. |
| No memory-capable C# prompt format | **Partially resolved**: formatter and bridge exist; production chat does not call them. |
| Screen/activity/Pomodoro observations discarded | **Resolved for buffering**: WPF adds text observations and submits them for distillation. |
| C# core/procedural state not synchronized | **Open**: Python routes update Python stores only; WPF does not reload after extraction. |
| USER BLOCK updates not reflected next turn | **Open**: agent prompt is a startup-time string. |
| User control and complete deletion | **Open**: no WPF memory UI; route semantics are incomplete. |

---

## 9. Remaining Integration Work

The original phased migration is no longer accurate because storage classes, routes, extraction,
distillation, and the dedicated collection already exist. Remaining work should be treated as
integration and user-control work:

1. Call `MemoryBridgeService.GetMemoryContextAsync` from the production chat flow and propagate the
   result through a provider contract that works for direct C# and Python paths.
2. Choose a canonical core/procedural representation and implement bidirectional or single-owner
   synchronization. Do not silently maintain conflicting C# and Python user profiles.
3. Make USER BLOCK prompt refresh dynamic or explicitly rebuild the agent after an update.
4. Define and test deletion across JSON namespaces and Chroma IDs, including `time_range`, then add
   confirmation and review controls in WPF.
5. Persist distilled patterns/events into the chosen procedural store and implement only the
   proactive behaviors that have explicit consent and suppression rules.
6. Add memory export/import and per-source retention controls before describing memory as fully
   transparent or editable.
7. Authenticate or otherwise constrain loopback mutation/read surfaces before treating localhost
   as trusted.

## 10. Verifiable Limits and Verification

No storage-size, monthly-cost, token-count, or latency guarantee is enforced by the current code.
Actual values depend on conversation text, model/provider pricing, embedding downloads, Chroma
growth, machine performance, and network conditions. The enforceable limits visible in code are:

| Limit | Current implementation |
|---|---|
| C# chat history | Maximum 200 persisted messages; last 20 returned by the default context window |
| Observation retention | `TtlHours` defaults to 24 and expired entries are purged on load/timer flow |
| C# prompt formatting | Item caps: 10 facts; 5 preferences; 5 episodic topics; 5 observations; 5 upcoming events |
| Episodic retrieval | REST and C# `MemoryBridgeService` default to `top_k=3`; the agent tool queries Chroma with `k=5` and caps combined results at five; REST accepts caller-supplied `top_k` without a documented cap |
| USER BLOCK | `update_user_block` silently truncates content beyond 1,200 characters |
| Extraction/distillation calls | Fire-and-forget/background with handled failures; no delivery guarantee |

Verify the implementation from the repository root:

```powershell
dotnet test tests/AemeathDesktopPet.Tests/ --filter "FullyQualifiedName~Memory"
dotnet test tests/AemeathDesktopPet.Tests/ --filter "FullyQualifiedName~ChatPromptBuilder"
Set-Location python-backend
python -m pytest tests/test_contract_memory.py tests/test_routes_memory.py tests/test_memory_integration.py -v
ruff check .
```

Also run the full configured suites before release:

```powershell
dotnet test tests/AemeathDesktopPet.Tests/
Set-Location python-backend
python -m pytest tests/ -v
```

Route tests and mocked HTTP tests do not prove cloud credentials, embedding downloads, Chroma
deletion, packaged-sidecar startup, or live C#/Python prompt integration. Those require explicit
integration checks in the target Windows environment.

---

## 11. Historical Design Comparison

The original proposal compared Claude Code, MemGPT/Letta, Mem0, and Zep to motivate a lightweight,
local-first design. It chose structured JSON for compact relationship data, optional vector search
for episodic recall, and no graph database. That rationale still explains the direction, but the
old comparison table mixed design goals with completed behavior and included unverified token,
storage, and dependency estimates, so it has been retired. Use the implementation matrix in
Section 1 for current status.

---

## 12. Remaining Design Decisions

1. **Canonical memory authority and synchronization**: Decide whether C# JSON or the Python stores
   own facts, preferences, events, and relationship state, then define conflict resolution and
   migration rules.
2. **Prompt refresh strategy**: Decide whether USER BLOCK changes rebuild the LangGraph agent,
   become request-scoped context, or use another safe refresh mechanism.
3. **Consent and visibility**: Define memory-specific opt-in controls plus review, edit, export, and
   deletion UX for each source.
4. **Retention and deletion semantics**: Define enforceable limits, stable Chroma identifiers,
   time-range deletion, and validation across every store.
5. **Sidecar packaging**: Decide how the Python runtime, model dependencies, Chroma, and the missing
   checkpoint dependency are installed and upgraded with the desktop release.
6. **Multilingual extraction quality**: Validate fact and preference extraction in English and
   Chinese before treating the current language-agnostic prompt as sufficient.

---

## Appendix A: Research Sources

### Memory System Research
- Claude Code Memory Docs — code.claude.com/docs/en/memory
- MemGPT Paper — arxiv.org/abs/2310.08560
- Letta Memory Blocks — docs.letta.com/guides/agents/memory-blocks/
- Mem0 Paper — arxiv.org/abs/2504.19413
- Zep Temporal KG Paper — arxiv.org/abs/2501.13956
- A-Mem (Zettelkasten) Paper — arxiv.org/abs/2502.12110
- AI Memory Survey — arxiv.org/html/2504.15965v2
- LangMem Conceptual Guide — langchain-ai.github.io/langmem/concepts/conceptual_guide/

### Companion Systems Research
- Replika Memory — help.replika.com
- Nomi AI Memory — companionguide.ai
- Character.AI Guide — autoppt.com/blog/character-ai-evolution-complete-guide/
- Windows Recall — learn.microsoft.com/en-us/windows/ai/recall/
- Rewind AI Teardown — kevinchen.co/blog/rewind-ai-app-teardown/

### Academic Research
- CHI 2025: Proactive AI for Programming — dl.acm.org/doi/10.1145/3706598.3714002
- Memoria Framework — arxiv.org/html/2512.12686v1
- ProactiveAgent Library — github.com/leomariga/ProactiveAgent

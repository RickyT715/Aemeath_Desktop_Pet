# Personal Assistant Landscape and Product Direction

**Status:** Proposed research baseline  
**Date:** 2026-07-22  
**Audience:** Maintainers, product designers, contributors, and future implementation agents  
**Decision supported:** Whether and how Aemeath should evolve from a desktop pet into a trusted personal AI assistant

## 1. Executive conclusion

Aemeath should become a **local-first, characterful Windows assistant that can understand context,
prepare actions, execute approved work, remember user-controlled facts, and remain pleasant when no
task is active**. It should not attempt to imitate a fictional, unconstrained Jarvis system. The
useful interpretation of “Jarvis-like” is:

- one consistent relationship and voice across sessions;
- fast access through text, push-to-talk, and an optional wake word;
- awareness of explicitly granted desktop and personal context;
- reliable completion of bounded workflows, not just conversational answers;
- proactive help that respects focus, privacy, and interruption budgets;
- visible plans, approvals, receipts, and recovery for consequential actions;
- a clear ability to work locally when hardware and chosen models permit it.

The current WPF pet is an asset, not legacy to discard. It gives the assistant presence, immediate
status feedback, and an unusually strong identity. The recommended change is a staged modular
refactor around that shell, with a separately visible Command Center for tasks, memory, permissions,
activity, and troubleshooting.

The strongest cross-project lesson is that an assistant becomes useful through **grounded tools,
bounded context, durable state, and trust controls**. Adding a stronger model without those layers
would make Aemeath more impressive in demos but less dependable in daily use.

## 2. Research question and method

This review asked five questions:

1. Which capabilities distinguish a personal assistant from a chatbot or animated companion?
2. How do mature open assistant projects divide voice, skills, tools, context, and memory?
3. What safety controls are needed before an assistant can operate a desktop?
4. Which parts of Aemeath should be preserved, refactored, or replaced?
5. Which proposed capabilities can be proven incrementally without a high-risk rewrite?

Only primary sources were used for technical claims: official project repositories, official
documentation, protocol specifications, and Microsoft platform documentation. Popularity metrics
were intentionally not used as evidence of architecture quality. Several compared systems remain
under active development; their patterns are inspiration, not proof that every implementation
choice is production-ready.

## 3. Current Aemeath baseline

The current working tree already contains more than a pet animation:

- a .NET 8 WPF desktop shell with pet behavior, animation, chat, settings, tray integration, voice,
  text-to-speech, screen awareness, activity monitoring, and companion-app integrations;
- direct Claude, Gemini, and proxy chat paths with an offline fallback;
- an optional FastAPI/LangGraph sidecar with streaming, tools, RAG, vision, memory, and persistence;
- initial MCP client/server types;
- layered C# and Python memory implementations;
- privacy controls for screen analysis and local data storage.

However, the repository's current-state documents identify structural blockers:

- composition is performed manually across windows and services rather than through a single host;
- two runtimes can own overlapping chat, memory, configuration, and tool behavior;
- loopback APIs are unauthenticated and their contracts are not consistently versioned;
- several declared capabilities are partial or unwired, including MCP, agent RAG, backend STT, and
  cross-runtime memory synchronization;
- provider fallback semantics, backend health, port configuration, and packaging are unreliable;
- API credentials are stored as ordinary configuration values;
- there is no unified permission system, action review surface, or durable execution receipt;
- automated quality gates have known environment, formatting, and lint debt.

This means the next step is not primarily “add more AI.” It is to create a coherent product and
execution substrate on which additional capabilities can be trusted.

## 4. Comparable projects and transferable lessons

### 4.1 Leon

[Leon](https://github.com/leon-ai/leon) describes its current direction around tools, context,
memory, agentic execution, deterministic native skills, provider flexibility, and a bounded
proactive pulse. Its repository also separates the server runtime, UI, skills, bridges, and Python
services.

**Useful lessons for Aemeath**

- Offer execution modes rather than treating every request as an open-ended agent problem.
- Keep deterministic skills for known workflows and use agent planning only when necessary.
- Make context a named subsystem instead of appending arbitrary observations to prompts.
- Keep provider selection behind a stable abstraction so local and remote models can coexist.
- Bound proactive behavior; continuous LLM reflection is expensive, interruptive, and difficult to
  reason about.
- Treat project context documents as operational source-of-truth artifacts, not promotional copy.

**Caution**

Leon 2.0 is explicitly a developer preview and its public documentation lags its source tree.
Aemeath should borrow concepts, not copy a changing package layout or take unverified feature claims
as evidence.

### 4.2 Open Interpreter

[Open Interpreter](https://github.com/openinterpreter/openinterpreter) demonstrates the value of a
natural-language interface that can use a local computer. Its safety documentation separates
[execution policies](https://www.openinterpreter.com/docs/terminal/execpolicy),
[sandboxing](https://www.openinterpreter.com/docs/terminal/sandbox), and user confirmation.

**Useful lessons for Aemeath**

- A policy engine and a sandbox solve different problems and should not be conflated.
- Every executable capability needs a risk classification before it is shown to a model.
- Users need to see the exact proposed action, not just an assistant summary.
- “Approve this action” must not silently authorize later or nested actions.
- Policy should be testable independently of model output.

**Caution**

General code or shell execution creates a very large attack and error surface. Aemeath should not
expose arbitrary terminal execution in its initial assistant releases. High-value operations should
be implemented as typed capabilities with narrow inputs, allow-listed targets, and explicit undo or
recovery semantics.

### 4.3 Home Assistant voice

Home Assistant models voice as a composition of separate integrations through an
[Assist pipeline](https://developers.home-assistant.io/docs/voice/overview/): speech-to-text,
conversation processing, intents, and text-to-speech. Its
[fully local assistant guidance](https://www.home-assistant.io/voice_control/voice_remote_local_assistant)
shows that these stages can be replaced independently and that speech can remain on the local
network.

**Useful lessons for Aemeath**

- Define a voice session state machine; do not embed microphone, transcription, reasoning, and
  playback into a single view model.
- Treat push-to-talk, wake word, VAD, STT, agent execution, and TTS as replaceable stages.
- Surface which stages are local and which use cloud services before a session begins.
- Support interruption (“barge-in”) and cancellation as first-class states.
- Validate the pipeline end-to-end; individual provider health is not enough.

### 4.4 OpenVoiceOS

[OpenVoiceOS](https://www.openvoiceos.org/) emphasizes plugins for wake words, STT, TTS, skills,
and local/offline configurations.

**Useful lessons for Aemeath**

- Provider plugins need explicit capability metadata and health, not string-based selection alone.
- Voice hardware and model availability vary widely, so graceful degradation is a feature.
- Timers, alarms, reminders, and media controls are high-frequency assistant skills that do not
  require an LLM for their core behavior.
- A skills ecosystem needs compatibility rules and lifecycle management before it needs a
  marketplace.

### 4.5 Letta

Letta's official documentation distinguishes persistent, always-visible
[memory blocks](https://docs.letta.com/guides/core-concepts/memory/memory-blocks) from files,
archival memory, and external RAG in a
[context hierarchy](https://docs.letta.com/guides/core-concepts/memory/context-hierarchy).

**Useful lessons for Aemeath**

- Small, critical facts and policies should remain in bounded core blocks; large histories and
  documents should be retrieved only when relevant.
- Read-only policy/persona memory should be distinct from agent-editable user memory.
- Memory descriptions, provenance, ownership, and size limits are part of the contract.
- Different memory tiers should have different write, retrieval, expiration, and deletion rules.
- Memory must be inspectable from the product UI. Invisible personalization cannot be trusted.

**Caution**

Autonomous memory writing can create false or overly confident profiles. Aemeath should attach
evidence, confidence, and sensitivity to proposed memories; sensitive or identity-defining facts
should require confirmation.

### 4.6 LangGraph

LangGraph documents
[durable execution and persistence](https://docs.langchain.com/oss/python/langgraph/persistence) and
[human-in-the-loop interrupts](https://docs.langchain.com/oss/python/langchain/human-in-the-loop).
It can checkpoint workflow state, pause for approve/edit/reject decisions, resume after failure, and
support replay or debugging.

**Useful lessons for Aemeath**

- Consequential workflows must be resumable across a UI close, sidecar restart, or network failure.
- Approval is a state transition, not a modal dialog wrapped around a live in-memory call.
- Tool side effects must be idempotent or carry idempotency keys.
- Each workflow step should have a trace ID, status, retry policy, and sanitized result.
- Deterministic workflow nodes provide better observability than a single large ReAct loop.

**Caution**

Durability in the orchestration engine does not make an external side effect safe. A retry can still
send a duplicate message or create a duplicate calendar event unless the capability adapter and
external service contract support deduplication.

### 4.7 Model Context Protocol

The official MCP
[security guidance](https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices)
calls out local server compromise, token passthrough, session hijacking, SSRF, consent, sandboxing,
and least-privilege scopes. The
[client best practices](https://modelcontextprotocol.io/docs/develop/clients/client-best-practices)
also make clear that generated-code execution and individual tool authorization remain the host's
responsibility.

**Useful lessons for Aemeath**

- MCP is an external capability adapter, not Aemeath's internal application architecture.
- Prefer `stdio` for local MCP servers; if HTTP is used, require authentication or restricted IPC.
- Show the exact server command and requested permissions before first launch.
- Keep credentials in the host; never expose them to generated code or model context.
- Request narrow scopes progressively and evaluate every tool call against the active grant.
- Record server identity, version, tool schema hash, and origin in execution receipts.

### 4.8 Microsoft Windows platform guidance

Microsoft's [.NET Generic Host for WPF](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/app-development/how-to-use-host-builder)
provides a supported route to dependency injection, configuration, logging, hosted background
services, startup, and graceful shutdown. Microsoft
[UI Automation](https://learn.microsoft.com/en-us/dotnet/framework/ui-automation/ui-automation-overview)
provides structured access to desktop UI elements and control patterns. Windows also provides
[Credential Locker](https://learn.microsoft.com/en-us/windows/apps/develop/security/credential-locker)
and [.NET DPAPI](https://learn.microsoft.com/en-us/dotnet/standard/security/how-to-use-data-protection)
for protecting credentials and user-bound data.

**Useful lessons for Aemeath**

- A Generic Host can modernize the existing WPF application without replacing WPF.
- UI Automation should be preferred over coordinate clicks when an application exposes accessible
  controls; input simulation is a fallback, not the primary contract.
- UI Automation cannot bypass Windows integrity boundaries by default, which is a desirable safety
  limit rather than a defect to work around casually.
- Secrets should move out of JSON configuration before more integrations are added.
- Aemeath's own custom controls must expose accessible names, roles, patterns, keyboard navigation,
  scaling, and high-contrast behavior.

## 5. Comparative capability matrix

| Concern | Aemeath today | Observed pattern | Recommended Aemeath direction |
|---|---|---|---|
| Identity | Strong animated character and persona | Leon emphasizes persistent identity/context | Preserve pet as embodiment; version persona separately from user memory |
| Voice | Multiple providers, coupled orchestration, partial backend path | Home Assistant and OVOS use replaceable stages | Introduce a voice pipeline state machine and provider capability registry |
| Skills | Python tools, C# services, partial MCP | Leon separates deterministic and agent skills | Use typed capabilities plus deterministic workflows; MCP only at the edge |
| Planning | Direct chat or general ReAct agent | LangGraph uses explicit durable nodes and interrupts | Route simple commands deterministically; reserve planner for ambiguous goals |
| Memory | Duplicate/partial stores across runtimes | Letta uses bounded core and retrieved archival tiers | One canonical store with tier, provenance, confidence, expiry, and user controls |
| Context | Chat history, optional screenshot/activity | Leon treats context as an explicit subsystem | Create consented context snapshots with source, age, sensitivity, and budget |
| Desktop action | Narrow integrations and unwired MCP | Open Interpreter separates policy, approval, sandbox | Add risk policy, previews, approval, receipts, idempotency, and undo |
| Proactivity | Idle chatter, activity/screen signals, Pomodoro | Leon uses a bounded pulse | Event/rule scheduler with focus modes and daily interruption budgets |
| Local-first | Direct/cloud paths and optional local vision | Home Assistant/OVOS compose local stages | Offer Local, Hybrid, and Cloud profiles with clear per-stage disclosure |
| Extensibility | Provider classes and preliminary MCP | Plugin manifests and compatibility metadata | Versioned manifests, health probes, permission scopes, and signed provenance |
| Operations | Health endpoints and tests, known contract/quality gaps | Durable runtimes expose traceable state | Unified diagnostics, trace IDs, scenario evaluation, and readiness gates |

## 6. Product opportunities, prioritized

### 6.1 Foundation opportunities

These are prerequisites, not optional polish:

1. **Unified composition and lifecycle:** host all WPF services through the .NET Generic Host.
2. **Secure runtime boundary:** authenticate and version WPF-sidecar communication, align health and
   configuration, and package or explicitly install the sidecar.
3. **Capability and permission registry:** describe what an action reads, writes, transmits, and can
   undo before it is model-visible.
4. **Durable task ledger:** persist plans, step status, approvals, receipts, retries, and cancellation.
5. **Canonical memory:** remove split ownership and add inspect/edit/delete/export behavior.
6. **Quality baseline:** make build, unit tests, contract tests, formatting, lint, and release smoke
   tests dependable.

### 6.2 High-value assistant loops

The first product release should prove four complete loops:

1. **Daily brief:** summarize upcoming events, reminders, timers, selected tasks, and optional local
   weather; let the user act on each item.
2. **Context question:** answer “what am I working on?” or “summarize this window” from a visible,
   explicit context snapshot with source citations.
3. **Reviewed desktop action:** turn a request into a narrow action preview, obtain approval when
   needed, execute it, and show a receipt or recovery path.
4. **Memory correction:** show what Aemeath remembers, why it remembers it, and let the user confirm,
   edit, forget, or expire it.

These loops exercise scheduling, integrations, context, planning, permissions, durability, and
memory without requiring arbitrary computer control.

### 6.3 Follow-on capabilities

After the four loops meet reliability and trust thresholds:

- meeting preparation and post-meeting notes;
- natural-language search over selected files and personal notes;
- clipboard transformations with preview and provenance;
- email and message drafting, with sending always separately approved initially;
- user-defined routines composed from typed steps;
- accessible UI Automation for selected applications;
- optional wake word, VAD, and barge-in;
- time-aware follow-up such as “remind me if this is still unfinished at 4 PM”;
- plugin/MCP installation with explicit permissions and compatibility checks;
- multi-device sync only after a clear identity, encryption, and conflict model exists.

### 6.4 Explicitly deferred capabilities

The following should not be in the first assistant milestone:

- arbitrary shell or PowerShell execution;
- unrestricted browser or coordinate-based desktop control;
- continuous camera or full-resolution screen capture;
- autonomous sending, purchasing, posting, deleting, or account changes;
- a marketplace for unreviewed third-party skills;
- a multi-agent swarm presented as a product feature;
- smart-home control without a separate threat model and supported integration boundary;
- autonomous self-modification or silent prompt/permission changes.

## 7. Strategic architecture options

### Option A: Full rewrite

Replace the WPF application and sidecar with a new unified stack.

**Advantages:** clean conceptual model; freedom to choose a new UI/runtime; fewer migration adapters.  
**Disadvantages:** loses working pet behavior and Windows integration; creates a long feature-parity
period; invalidates much of the test suite; combines product discovery with platform migration;
delays user-visible value.  
**Assessment:** reject unless WPF itself becomes an evidenced product blocker.

### Option B: Continue adding services to the current structure

Keep the current composition and add more Python tools, C# services, and UI controls.

**Advantages:** smallest immediate change; fast demos; minimal structural work.  
**Disadvantages:** worsens duplicate ownership, implicit dependencies, security gaps, and
untraceable execution; each new tool raises regression and trust risk.  
**Assessment:** reject for consequential capabilities; acceptable only for isolated bug fixes.

### Option C: Evolutionary modular refactor with an optional agent sidecar

Keep WPF and the pet engine, introduce host-based composition and bounded modules, define one typed
local protocol to the Python AI runtime, and migrate capabilities one vertical slice at a time.

**Advantages:** preserves differentiated value; produces benefits incrementally; supports local and
cloud models; contains the Python ecosystem behind a contract; enables rollback and parallel
migration.  
**Disadvantages:** temporary adapters and duplicate paths are required; boundaries must be enforced
carefully; packaging remains multi-runtime.  
**Assessment:** recommended.

## 8. Reflection and challenge of the recommendation

### 8.1 Does a more capable assistant fit the desktop-pet identity?

Yes, if the pet represents the assistant's state rather than becoming a tiny control panel. Listening,
thinking, waiting for approval, executing, succeeding, and recovering are naturally expressive pet
states. Dense information belongs in a separate Command Center. This division preserves charm while
making serious work legible.

It would fail if every proactive event becomes speech or animation. The pet must respect focus mode,
full-screen applications, quiet hours, rate limits, and the user's explicit availability state.

### 8.2 Will a hybrid C#/Python design remain too complex?

It is more operationally complex than one runtime, but the existing product already depends on both
Windows-native APIs and a fast-moving Python AI ecosystem. The complexity becomes manageable if:

- WPF owns product state, permissions, UI, Windows integrations, and user-visible receipts;
- Python owns model orchestration, retrieval, and model-specific adapters;
- only versioned DTOs cross the boundary;
- one runtime is authoritative for every persisted entity;
- either side can report degraded capabilities without claiming whole-system health.

If packaging, startup reliability, or contract maintenance remains unacceptable after the first two
vertical slices, the decision should be revisited with real measurements.

### 8.3 Is local-first realistic?

Fully local voice, embeddings, and language models can require substantial disk, memory, GPU, and
setup effort. “Local-first” therefore should mean **local control and transparent routing**, not a
promise that all users will run every model locally. Aemeath should offer three profiles:

- **Local:** no content leaves the machine; unavailable stages degrade clearly.
- **Hybrid:** local wake word/context filtering/memory with selected cloud inference.
- **Cloud:** remote providers allowed, with per-capability disclosure and redaction policy.

No profile should silently fall back from local to cloud.

### 8.4 Could a deterministic-first approach feel less intelligent?

Possibly in demos, but it should feel more competent in daily use. The user cares that “remind me at
three” produces exactly one correct reminder more than whether an agent generated an elaborate plan.
The planner remains valuable for ambiguity, composition, explanation, and recovery. Intelligence is
expressed by choosing the simplest reliable execution path.

### 8.5 Could approvals create excessive friction?

Yes. A prompt for every read or harmless local action would train users to approve blindly. The risk
model should support:

- automatic low-risk reads within already granted scopes;
- session or workflow grants for repeated bounded operations;
- mandatory per-action approval for external communication, destructive change, credential use,
  and expanded scope;
- clear revocation and “always ask” overrides;
- approval cards that show the exact effect, target, data leaving the device, and undo path.

Approval frequency and rejection/edit rates must be measured and used to refine categories.

### 8.6 What is the biggest risk to the proposal?

The biggest risk is trying to implement the whole architecture horizontally before proving one useful
workflow. The roadmap must deliver vertical slices, each including UI, policy, execution, persistence,
diagnostics, tests, and user feedback. Architecture work that cannot be connected to one of the four
initial assistant loops should be challenged.

## 9. Evidence-based success and stop conditions

The proposal is working if, during a controlled pilot:

- at least 90% of the four initial assistant-loop attempts reach a correct terminal state;
- at least 99% of approved consequential actions produce one and only one external side effect;
- every side effect has a traceable receipt and every supported undo succeeds at least 95% of the
  time in test scenarios;
- users can identify when screen, microphone, memory, or cloud data is in use;
- fewer than 5% of proactive suggestions are dismissed as irrelevant after tuning;
- memory correction and deletion propagate to all retrieval paths within one minute;
- degraded sidecar or provider states do not prevent pet, settings, reminders, or offline behavior.

Pause or redesign the initiative if:

- the first vertical slice exceeds twice its planned effort without producing an end-to-end pilot;
- contract drift repeatedly breaks WPF-sidecar compatibility despite contract tests;
- startup time, idle memory, or crash rate regresses beyond the budgets in the design document;
- privacy controls cannot be made understandable in usability testing;
- users approve prompts without reading them or cannot predict what an action will do;
- the assistant's proactive behavior cannot meet the interruption target without being disabled.

## 10. Recommended decision

Adopt Option C and sequence work as follows:

1. stabilize quality, secrets, process lifecycle, and the local contract;
2. add capability policy, task ledger, and Command Center foundations;
3. deliver daily brief and reminder management;
4. deliver explicit context questions with source visibility;
5. consolidate memory and deliver inspection/correction;
6. deliver reviewed desktop actions for a narrow allow-list;
7. expand voice, routines, and external capabilities only from measured demand.

The accompanying PRD, ADR, UI specification, technical design, and work plan turn this direction into
testable product and engineering commitments.

## 11. Primary sources

- [Leon repository and current architecture overview](https://github.com/leon-ai/leon)
- [Open Interpreter repository](https://github.com/openinterpreter/openinterpreter)
- [Open Interpreter execution policy](https://www.openinterpreter.com/docs/terminal/execpolicy)
- [Open Interpreter sandbox and approval guidance](https://www.openinterpreter.com/docs/terminal/sandbox)
- [Home Assistant voice pipeline](https://developers.home-assistant.io/docs/voice/overview/)
- [Home Assistant fully local voice assistant](https://www.home-assistant.io/voice_control/voice_remote_local_assistant)
- [OpenVoiceOS](https://www.openvoiceos.org/)
- [Letta memory blocks](https://docs.letta.com/guides/core-concepts/memory/memory-blocks)
- [Letta context hierarchy](https://docs.letta.com/guides/core-concepts/memory/context-hierarchy)
- [LangGraph persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
- [LangChain human-in-the-loop middleware](https://docs.langchain.com/oss/python/langchain/human-in-the-loop)
- [MCP security best practices](https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices)
- [MCP client best practices](https://modelcontextprotocol.io/docs/develop/clients/client-best-practices)
- [.NET Generic Host in WPF](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/app-development/how-to-use-host-builder)
- [Microsoft UI Automation overview](https://learn.microsoft.com/en-us/dotnet/framework/ui-automation/ui-automation-overview)
- [Windows Credential Locker](https://learn.microsoft.com/en-us/windows/apps/develop/security/credential-locker)
- [.NET Data Protection API](https://learn.microsoft.com/en-us/dotnet/standard/security/how-to-use-data-protection)


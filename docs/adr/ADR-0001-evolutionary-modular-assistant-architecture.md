# ADR-0001: Evolve Aemeath Through a Modular WPF Host and Optional Agent Sidecar

**Status:** Accepted  
**Date:** 2026-07-22  
**Decision owners:** Aemeath maintainers  
**Related documents:** [Research](../research/jarvis_assistant_landscape.md),
[PRD](../prd/jarvis_assistant_prd.md), [Design](../design/jarvis_assistant_design.md),
[ADR-0002](ADR-0002-test-driven-verification-and-exact-sha-delivery.md)

## Context

Aemeath is currently a .NET 8 WPF desktop pet with chat, animation, voice, TTS, screen awareness,
activity monitoring, integrations, and local persistence. It optionally launches a Python
FastAPI/LangGraph sidecar for model orchestration, tools, RAG, vision, memory, and streaming.

The architecture has accumulated overlapping responsibilities:

- WPF windows and view models manually construct many concrete services.
- Both C# and Python can participate in chat, memory, configuration, and provider selection.
- WPF calls the sidecar over loopback HTTP while the sidecar calls an unauthenticated WPF loopback
  API for pet functions.
- MCP, RAG, backend STT, memory synchronization, port configuration, packaging, and readiness are
  incomplete or inconsistent.
- Secrets, approvals, capability scopes, execution receipts, and durable tasks do not share a
  unified model.

The desired product is more capable: a personal assistant that can use explicitly granted context,
prepare and execute bounded actions, remember user-controlled facts, and offer restrained proactive
help. That direction increases the consequences of architectural ambiguity. A chat failure can be
annoying; a duplicated, unauthorized, or opaque desktop action can be harmful.

This ADR determines whether to rewrite the application, continue extending the current structure, or
evolve it through explicit modules and a hardened runtime boundary.

## Decision drivers

The selected approach must:

1. preserve the pet's identity, animation engine, Windows-native behavior, and existing test value;
2. permit incremental, user-visible delivery rather than a long feature-parity rewrite;
3. support Windows APIs and the Python AI ecosystem without ambiguous data ownership;
4. work without the sidecar for pet, settings, reminders, and supported offline functions;
5. provide durable, inspectable, and cancellable workflows for consequential actions;
6. put permissions and user approval outside model control;
7. support local, hybrid, and cloud execution profiles without silent routing changes;
8. make packaging, health, version compatibility, and diagnostics testable;
9. constrain contributor complexity through stable contracts and bounded modules;
10. independently qualify every retained behavior before restructuring its implementation;
11. advance each migration step only after test-first evidence and exact-commit CI verification;
12. allow the architecture to be revisited using measured kill criteria.

## Considered options

### Option A: Full rewrite into a single new runtime

Rebuild the product in a new desktop framework and/or move all AI and application behavior into one
language and process.

**Potential variants**

- C#-only WPF or WinUI with direct model SDKs;
- Python-first application with a web or Qt UI;
- a cross-platform web shell such as Electron or Tauri with a service runtime.

**Advantages**

- clean boundaries can be designed without compatibility layers;
- one runtime may simplify packaging and inter-process communication;
- a new UI framework could enable cross-platform delivery.

**Disadvantages**

- discards or ports working animation, window behavior, tray, audio, hotkey, and Windows integration;
- combines an unproven product expansion with a complete platform migration;
- creates a long interval in which the rewrite has fewer features and less test coverage;
- a C#-only solution loses convenient access to much of the agent/RAG ecosystem, while a
  Python/web solution weakens native Windows integration;
- cross-platform scope is not an evidenced user requirement;
- migration progress is difficult to expose as small, valuable releases.

**Conclusion:** Not selected. A rewrite is justified only if measured WPF/runtime constraints later
block required outcomes.

### Option B: Extend the current architecture in place

Continue adding concrete C# services, Python tools, settings fields, and view-model wiring without a
new composition, capability, permission, or protocol layer.

**Advantages**

- lowest up-front engineering cost;
- fastest route to individual demonstrations;
- minimal movement of existing files.

**Disadvantages**

- reinforces duplicate data and behavior ownership;
- expands an unauthenticated and weakly versioned local attack surface;
- makes action approval inconsistent across tools;
- increases startup, shutdown, configuration, and error-handling paths;
- leaves the model-facing tool surface disconnected from a central policy engine;
- raises long-term maintenance cost for every new provider and integration.

**Conclusion:** Not selected for the assistant initiative. It remains acceptable for isolated fixes
that do not widen architecture or security scope.

### Option C: Evolutionary modular WPF host with an optional Python agent sidecar

Retain WPF and the current pet engine. Move application composition to the .NET Generic Host, define
bounded product modules and authoritative data ownership, introduce a typed and authenticated local
protocol, and migrate capabilities through complete vertical slices. Keep Python as an optional
model/orchestration runtime behind that protocol.

**Advantages**

- preserves the working, differentiated product experience;
- delivers architecture improvements alongside user-visible features;
- provides natural ownership: WPF for Windows, policy, product state, and UI; Python for models,
  retrieval, and graph orchestration;
- supports local and remote model providers without coupling them to view models;
- allows the sidecar to degrade independently;
- provides rollback points and contract tests during migration;
- makes future replacement of either runtime possible behind stable interfaces.

**Disadvantages**

- multi-runtime packaging and process supervision remain necessary;
- temporary adapters and duplicate paths exist during migration;
- module boundaries can erode unless enforced through projects, namespaces, and dependency tests;
- a local protocol and capability schema must be maintained deliberately.

**Conclusion:** Selected.

## Decision

Aemeath will use an **evolutionary modular architecture** with the following ownership rules and
boundaries.

### 0. Independent preservation qualification precedes architectural migration

The first implementation gate is **Gate 0: Retained behavior independently qualified** from the
[PRD](../prd/jarvis_assistant_prd.md). Before production structure or behavior changes, the project
must inventory the current requirements and retained surfaces, freeze independently derived
characterization oracles, and pass the required unit, integration, WPF UI, Windows UI Automation,
fixture end-to-end, and real-boundary end-to-end lanes against the unmodified baseline. Additional
contract, security/privacy, accessibility, performance/reliability, packaging, and static-analysis
lanes are required wherever the frozen risk map assigns them.

That unchanged-source qualification is Gate 0A. The pre-existing tests remain valuable but become a
separate legacy-regression input only after Gate 0A oracles freeze. Gate 0B then repairs blocking
testability, accessibility, product, dependency, static-analysis, and legacy gaps under the full
Gate 0A suite. Architectural migration remains locked until final Gate 0 is green. The legacy tests
do not supply code, fixtures, data, helpers, snapshots, expected values, or pass/fail oracles to
the independent preservation suite.
A current requirement is preserved by default. Replacing,
changing, deferring, or removing one requires the explicit disposition and approval defined in the
PRD; architecture acceptance does not approve those exceptions implicitly.

[ADR-0002](ADR-0002-test-driven-verification-and-exact-sha-delivery.md) is a prerequisite for this
decision. It governs preservation provenance, test topology, valid TDD evidence, deterministic test
boundaries, exact-SHA CI gates, Windows runner responsibilities, and evidence retention. Gate 0 must
pass under ADR-0002 before the modular migration below begins, and every later checklist step must
continue to satisfy its advancement rule.

### 1. WPF remains the product host

The .NET application owns:

- the pet, windows, tray, hotkeys, accessibility, and all user interaction;
- configuration excluding raw secrets, execution-profile selection, and feature flags;
- credential references and Windows-protected secret storage;
- capability registration, permission grants, approval policy, and revocation;
- the durable task ledger and user-visible action receipts;
- reminders, schedules, notification budgets, and proactive mode;
- Windows integrations, screen/context acquisition, and UI Automation adapters;
- canonical user memory metadata and all memory management UI;
- sidecar process lifecycle, compatibility negotiation, and degraded-state reporting.

### 2. Python remains an optional intelligence runtime

The sidecar owns:

- model adapters and model-selection logic requested by the WPF execution profile;
- planning and orchestration graphs;
- prompt assembly from supplied, policy-filtered context references;
- document ingestion, embedding, retrieval, and reranking;
- model-assisted memory proposals, summarization, and extraction;
- evaluation hooks for planner/tool selection and retrieval quality.

Python does not own permissions, secret display, approval decisions, Windows actions, or authoritative
task completion.

### 3. A single typed local protocol separates the runtimes

The preferred boundary is a generated, versioned contract over loopback HTTP during the initial
migration, protected by an ephemeral bearer token created by the WPF host and passed to the child
process through a protected launch mechanism. The API binds to loopback only. The token is never
written to normal configuration or logs.

The protocol includes:

- semantic protocol version and minimum compatible version;
- capability and model readiness, not only process liveness;
- trace, task, thread, and idempotency identifiers;
- discriminated event types for streaming;
- structured errors with retry and user-action guidance;
- schemas for plan proposals, context references, memory proposals, tool requests, approvals, and
  results;
- maximum message sizes and timeouts;
- cancellation and graceful shutdown.

Named pipes or gRPC over named pipes may replace loopback HTTP later if measurements show a material
security, performance, or packaging benefit. This is not required for the first migration because
contract clarity and authentication address the immediate defects with lower change risk.

### 4. Capabilities are the sole route to side effects

Every action visible to a model or workflow is registered as a typed capability with:

- stable ID and version;
- owner module and implementation adapter;
- input/output JSON schema;
- data categories read, written, or transmitted;
- risk class and required scope;
- approval policy;
- supported preview, dry-run, cancellation, idempotency, and undo behavior;
- availability and health;
- timeout, retry, and concurrency policy;
- origin and signature/provenance for external extensions.

The planner may propose capability calls but cannot bypass the WPF capability broker. MCP servers are
adapted into this registry and receive no special trust.

### 5. Execution uses deterministic-first routing

Requests follow the simplest reliable path:

1. parse and classify locally when feasible;
2. select a deterministic skill for known commands;
3. use a predefined durable workflow for multi-step known tasks;
4. use model planning for ambiguous or novel composition;
5. require the same policy, validation, and receipt path regardless of how the call was proposed.

General arbitrary shell execution is excluded from the initial architecture.

### 6. Persistent entities have one authoritative owner

| Entity | Authoritative owner | Notes |
|---|---|---|
| User settings | WPF | Secret values replaced by credential references |
| Secrets | Windows-protected store | Never copied into normal settings or logs |
| Tasks, steps, approvals, receipts | WPF durable task store | Python receives task-scoped views |
| Reminders and schedules | WPF | Work without sidecar |
| User/core memory records | WPF memory store | Python proposes and queries through contract |
| Large document indexes | Python retrieval store | WPF owns source grants and catalog metadata |
| Conversation checkpoints | Python while sidecar is used | Linked to WPF thread and task IDs |
| Pet state and statistics | WPF | Exposed as read-only or bounded capabilities |
| Permission grants | WPF | Model and extensions cannot edit grants |

### 7. The UI separates embodiment from administration

The pet surface communicates immediate assistant state and lightweight interaction. A Command Center
window owns dense views for conversations, tasks, approvals, memory, capabilities, privacy, activity,
and diagnostics. The same state store drives both; the pet never becomes the only place to inspect a
consequential operation.

## Consequences

### Positive

- Existing animation and Windows integration are retained.
- Startup, shutdown, background services, configuration, DI, and logging gain a supported host.
- Permissions and approval become consistent across native, Python, and MCP capabilities.
- Sidecar failure can be represented as partial degradation rather than total product failure.
- New features can be delivered and evaluated one complete workflow at a time.
- Canonical ownership reduces split-brain memory and task state.
- A generated contract reduces multipart/JSON, port, and streaming drift.
- Receipts, idempotency, and durable checkpoints reduce duplicate and invisible side effects.

### Negative

- The repository will temporarily include legacy adapters and new module interfaces.
- Contract generation and compatibility testing add build steps.
- Contributors must understand two runtimes for cross-boundary work.
- Local authentication is necessary but does not eliminate compromise by processes running as the
  same user; capability policy and OS protections still matter.
- Migrating persistence requires careful backup, schema versioning, and rollback behavior.

### Neutral or operational

- WPF is a deliberate Windows-only product decision, not an accidental limitation.
- Python remains optional for core pet and deterministic functions but required for advanced agent
  and RAG features.
- MCP support is postponed until the internal capability broker and permission UI exist.
- A future UI rewrite remains possible because product modules and contracts are separated from view
  construction.

## Enforcement rules

The decision is considered implemented only when these rules are enforced:

1. No view or view model directly constructs provider, persistence, process, or integration services.
2. No model-facing code calls Windows or external side effects except through the capability broker.
3. No persisted entity is independently writable by both runtimes.
4. No secret value is serialized into normal application configuration.
5. No consequential capability can run without a persisted policy decision.
6. No external tool is trusted solely because it uses MCP.
7. No health endpoint reports “ready” when required model or storage initialization has failed.
8. No retryable side-effecting call lacks an idempotency design.
9. No proactive suggestion bypasses focus mode, quiet hours, or interruption budgets.
10. No legacy path remains after its replacement has passed migration and rollback gates.
11. No production migration starts before independent Gate 0 evidence passes at the exact pushed
    commit under ADR-0002.
12. No implementation step advances on skipped, advisory, zero-test, reduced-matrix, synthetic
    merge-SHA-only, or otherwise incomplete CI evidence.

These should be checked through architecture tests, contract tests, static analysis where practical,
and pull-request review.

## Migration outline

0. Pass the independent preservation Gate 0 and exact-SHA verification defined by ADR-0002.
1. Introduce Generic Host composition without changing visible behavior.
2. Add protected secret storage and migrate secret-bearing configuration.
3. Define protocol v1, compatibility negotiation, authenticated health, and process lifecycle.
4. Add task ledger, capability registry, policy engine, and receipt schema.
5. Deliver the daily brief/reminder vertical slice through the new modules.
6. Add explicit context snapshots and context-question flow.
7. Migrate memory to the canonical WPF store with Python proposal/query adapters.
8. Add reviewed desktop actions for a narrow allow-list.
9. Adapt MCP servers only after install consent, scope, provenance, and sandbox policies exist.
10. Delete superseded direct paths after feature parity, tests, migration, and rollback proof.

## Known unknowns

- Whether a packaged Python distribution, embedded environment, or separately installed sidecar gives
  the best release size, update, and antivirus experience.
- Whether loopback HTTP plus ephemeral auth is sufficient for the threat model or named pipes are
  worth the added implementation cost.
- Which local STT, TTS, embedding, and language models meet acceptable latency on representative
  user hardware.
- How much UI Automation coverage the first target applications expose reliably.
- Whether SQLite alone is sufficient for task, memory, and event volume over multi-year use.
- Which proactive suggestion types users consistently value rather than disable.
- Whether users understand risk-based grants or need a simpler trust-level model.
- How much of conversation checkpoint state should be retained when the user deletes related memory.

Each unknown must be resolved by a time-boxed spike or pilot before it blocks an implementation
phase. It must not be filled with a silent assumption.

## Kill criteria and reconsideration triggers

Reopen this ADR if any of the following is observed:

- two end-to-end slices each require more than twice their estimate primarily because of the
  two-runtime boundary;
- packaged sidecar startup succeeds in fewer than 99% of release smoke tests;
- median warm boundary overhead exceeds 100 ms for non-model calls or becomes user-visible;
- contract changes routinely require coordinated breaking releases despite compatibility policy;
- WPF prevents required accessibility, rendering, or interaction outcomes with no bounded workaround;
- baseline idle memory increases by more than 150 MB or cold startup by more than 2 seconds because
  of the new host and infrastructure;
- canonical ownership cannot prevent memory or task divergence;
- security review identifies an unmitigable local protocol flaw.

Reconsidering does not imply an automatic rewrite. The team must compare measured failure against
focused alternatives such as replacing only the sidecar transport, only the orchestration runtime,
or only the Command Center UI.

## Validation plan

ADR-0002 is authoritative for the provenance, sequencing, execution environments, exact-SHA gate
manifest, failure semantics, and retention of the following evidence. These checks supplement, and
do not replace, the independently authored Gate 0 suite.

- Create an architecture dependency test that rejects forbidden module references.
- Generate C# and Python protocol clients/models from one schema and run bidirectional compatibility
  fixtures in CI.
- Run a process lifecycle matrix: missing runtime, wrong version, port collision, slow startup,
  model failure, crash, restart, shutdown, and upgrade.
- Run policy tests for every risk class and scope transition.
- Run idempotency tests that inject timeouts before and after external commit.
- Run persistence recovery tests across application and sidecar restarts.
- Run end-to-end scenarios for each initial assistant loop with local, hybrid, cloud, and degraded
  profiles where applicable.
- Conduct usability testing for permission comprehension and proactive interruption.

## References

- [Personal Assistant Landscape and Product Direction](../research/jarvis_assistant_landscape.md)
- [Current architecture](../architecture.md)
- [Current requirements](../../REQUIREMENTS.md)
- [ADR-0002: Test-Driven Verification and Exact-SHA Delivery](ADR-0002-test-driven-verification-and-exact-sha-delivery.md)
- [.NET Generic Host in WPF](https://learn.microsoft.com/en-us/dotnet/desktop/wpf/app-development/how-to-use-host-builder)
- [LangGraph persistence](https://docs.langchain.com/oss/python/langgraph/persistence)
- [MCP security best practices](https://modelcontextprotocol.io/docs/tutorials/security/security_best_practices)

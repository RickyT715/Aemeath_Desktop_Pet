# P0A.1 Clean-Room Preservation Review v1

## Decision

- Reviewer assignment: `clean-room-preservation-reviewer-01`
- Review date: 2026-08-20 (Asia/Shanghai)
- Specification: `docs/verification/preservation-spec-v1.yml`
- Observed specification SHA-256: `fa29076f523de5fff1a339b0c36498ff490f9e2ed7220ced29f82dfb500ff7d0`
- Expected specification SHA-256: `fa29076f523de5fff1a339b0c36498ff490f9e2ed7220ced29f82dfb500ff7d0`
- Hash result: MATCH
- Verdict: **BLOCK**
- Finding census: **C=1, I=5, M=0**

The document is structurally coherent, but it is not factually complete enough to freeze. Two protocol
records assert compatible SSE token/done wire behavior that the current producer/consumer path does
not provide, and the specification omits additional protocol, current-requirement, lane, fixture,
and source-identity gaps. Under the assignment rule, any Critical or Important finding blocks.

## Clean-room exposure record

### Allowed repository material reviewed

- `REQUIREMENTS.md`
- `docs/prd/jarvis_assistant_prd.md`
- `docs/design/jarvis_assistant_design.md`
- `docs/ui-spec/jarvis_assistant_ui_spec.md`
- `docs/plans/20260722-jarvis-assistant-tdd-checklist.md`
- public production contracts/source under `src/AemeathDesktopPet/`
- public production contracts/source under `python-backend/aemeath_agent/`
- `docs/verification/manifests/P0A.1-v1.yml`
- `tests/fixtures/preservation/v1/data-v1.json`
- `tests/fixtures/preservation/v1/oracles-v1.json`
- `tests/fixtures/preservation/v1/protocol-v1.json`
- `tests/fixtures/preservation/v1/resources-v1.json`
- `docs/verification/preservation-spec-v1.yml`

### Forbidden repository material not read or searched

- `tests/AemeathDesktopPet.Tests/`
- `python-backend/tests/`
- legacy fixtures, snapshots, generated expectations, results, and evidence
- `.superpowers/`
- prior review/evidence contents
- any repository file outside the assignment allowlist

No product, test, Git, or network command was executed. Checks were limited to file enumeration,
SHA-256, JSON parsing/inspection, text/source inspection, reference-census checks, and read-only GIF
metadata inspection. The only file created is this report; the preservation specification and its
fixtures were not modified.

A coordination message received after the source-only review reported an independent read-only
reproduction of installed `sse-starlette` 3.2.0 framing. It contained no legacy-test information.
This is disclosed rather than presented as a repository source. Before that message, the independent
source-only review had already found the separate `tool_call` producer/consumer mismatch below.

## Structural and factual census

| Area | Declared | Review result |
|---|---:|---|
| Components | 20 | IDs unique; source categories cover the current WPF host, UI/engines, data, integrations, sidecar, memory, MCP, privacy, packaging, and Windows surface. |
| Public behaviors | 18 | `PB-001` through `PB-018` each occur once; all boundary references are internally reciprocal and non-dangling. Material omissions are recorded below. |
| Persisted-data stores | 11 | Paths agree with the allowed requirements/source set. |
| Integration boundaries | 13 | The represented boundaries are factual; runtime configuration/protocol defects are under-described. |
| Windows journeys | 5 | The three fixture and two real-boundary intents agree with the Gate 0A plan; the keyboard journey is honestly marked as a gap. |
| Qualification lanes | 14 | All 14 IDs exist, are required, have owner steps/test IDs, and have reciprocal PB links. The substantive PB/environment mappings are incomplete (I-03). |
| Known gaps | 21 | All 21 written statements are supported and all correctly set `countsAsPassingBaseline: false`; the list is not complete (I-02). |
| Data records | 6 | JSON parses and the declared shapes are accepted by the public models. The deliberately partial config canary is honestly labeled, but it omits a required restart canary (I-04). |
| Oracles | 28 | The 28 recorded geometry/stat/time/literal/gap payloads match their cited allowed production sources. Their coverage is incomplete for PB-009 (I-04). |
| Protocol contracts | 13 | Eleven records are supported. `PROTOCOL-SSE-TOKEN` and `PROTOCOL-SSE-DONE` are not compatible on the actual producer path (C-01), and `tool_call` drift has no record (I-01). |
| Resources | 11 | Every byte length and SHA-256 matched. All ten image dimensions/frame counts matched; packaging/preload/mapping statuses match the project/resource loader/state map. |

Fixture hashes all match both the specification and governing manifest:

- `data-v1.json`: `4b84f1bcf862b26d486af8fab87b9a250e52617ea1da5c89e1440025f3421e48`
- `oracles-v1.json`: `3f3d1c561325a09741e1b7d158d79c159e4f8f66c07cce38886c2804169b9be6`
- `protocol-v1.json`: `15fa05e2f5588ee88c84a930291f651b8ef732fffb7bde4f85fa892c43d7cd3c`
- `resources-v1.json`: `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8`
- governing manifest: `2c373ca1671c65cd7c4bed70af3aa10de08df0f9450ed8b2d7c4d2eeb1c25dbd`

The production-root file counts also match: 94 under `src/AemeathDesktopPet` and 46 under
`python-backend/aemeath_agent` using the allowed source inventory.

## Positive gap checks

The reminder and daily-brief absence is represented honestly and must remain blocking:

- `GAP-REMINDER-LOOP-MISSING` correctly states that `ScheduledEvent` has a serialized/read shape but
  no production writer, scheduler, due-time reconciliation, or notification loop. The only
  `ScheduledEvents` production uses in the allowed source are the model and read/format path.
- `GAP-DAILY-BRIEF-MISSING` correctly states that no source aggregation, ranking, delivery, or
  follow-up surface exists. `manage_todo` has a `due_date` field but no clock/reconciliation or
  notification mechanism and is not a daily brief.
- `ORACLE-REMINDER-GAP` correctly sets all four capability claims to absent and
  `countsAsPassingBaseline: false`.

The other 19 authored known-gap statements were also supported by the allowed requirements and
production contracts. None was found to be falsely marked passing.

## Findings

### C-01 — SSE token and done contracts are falsely marked compatible

`protocol-v1.json` marks `PROTOCOL-SSE-TOKEN` and `PROTOCOL-SSE-DONE` compatible and provides
single-framed `data: {json}\n\n` wire values. Production `routes_agent.py` passes strings already
formatted by `format_sse_event`/`format_sse_done` to `EventSourceResponse`. The independently
reported read-only reproduction of the installed `sse-starlette` 3.2.0 path showed those strings are
wrapped again, producing a first payload equivalent to
`data: data: {...}\r\ndata: \r\ndata: \r\n\r\n`. `BackendAgentService.cs` strips only the first
`data: ` and then calls `JsonDocument.Parse`; parsing fails and its inner catch silently drops the
event. This invalidates both compatible records and the PB-005/PB-012 streaming preservation claim.

Required correction: represent the current framing defect as an explicit non-passing protocol/gap
record, remove the false compatibility claims, and map it to a later RED repair. A semantic compact
JSON fixture is not evidence of the producer's actual wire.

### I-01 — The streaming `tool_call` schema mismatch is omitted

In `python-backend/aemeath_agent/api/routes_agent.py:63-66`, the producer puts the tool name in top-level
`content` and puts only `args` in `data`. In
`src/AemeathDesktopPet/Services/BackendAgentService.cs:132-133`, the consumer reads `data.name`.
The resulting `KeyNotFoundException` is swallowed by the malformed-event catch, so tool-call status
is silently lost. `protocol-v1.json` has token and done canaries but no `tool_call` canary, and none of
the 21 gaps records this drift.

Required correction: add an incompatible `tool_call` protocol fixture and an explicit PB-005/
PB-012/PB-013 non-passing gap with a later RED owner.

### I-02 — The 21-gap census omits required current-status gaps

The existing 21 entries are truthful but do not satisfy the plan's rule that every unimplemented
portion of a Partial item and every Planned promise be traced to a later RED step. At minimum the
following distinct gaps are absent:

1. AR-004 deterministic tier failover/silent fallback ambiguity (`REQUIREMENTS.md:91`, plan line 178).
2. FR-VISION-004 stored-but-unconsumed `PrivacyTier`, `UseLocalPreFilter`, `BlurTaskbar`, and
   `BlurAddressBar` controls (`REQUIREMENTS.md:138`, plan line 213). These fields occur in
   `AppConfig.cs:117,120,131-132` and are not consumed by `ScreenAwarenessService`.
3. Runtime configuration synchronization and environment-name drift from current release-gap item 8:
   WPF posts only `{ "status": "sync" }`; `ConfigSyncRequest` ignores it; `routes_config.py` mutates a
   newly created `Settings` instance; and the launcher uses `AEMEATH_INTERNAL_PORT`, `TAVILY_API_KEY`,
   and `OPENWEATHERMAP_API_KEY` while `Settings` applies the `AEMEATH_` prefix to
   `wpf_internal_port`, `tavily_api_key`, and `openweather_api_key`.
4. FR-MEM-005's startup USER BLOCK snapshot (`REQUIREMENTS.md:148`, plan line 218):
   `graph.py:51` builds one prompt string at agent creation, so later block updates do not refresh the
   active prompt.
5. FR-MEM-007 evidence-based procedural learning/session consolidation (plan line 220) and the
   accepted `MemoryForgetRequest.time_range` that `routes_memory.py` never applies.

Required correction: version the gap list and manifest threshold, add one precise non-passing record
per independently repairable defect/promise, and map each affected PB and later RED step.

### I-03 — The 14 lanes exist, but their PB/environment intent is under-mapped

The reciprocal references are mechanically valid but omit directly required coverage:

- P0A.6 explicitly observes Pet, Speech Bubble, Cat, Stats, Chat, and all eight Settings tabs. The
  `V-WPF` map includes PB-004/PB-008/PB-016/PB-017/PB-018 but omits at least PB-002, PB-003, PB-005,
  and PB-009.
- P0A.7 explicitly drives Chat input/output and Settings persistence. `V-UIA` omits PB-005 and PB-008.
- The UI specification says Gate 0 UI directly covers PB-001 through PB-008, PB-010, and PB-016
  through PB-018. `V-ACCESS` maps only PB-016/PB-017/PB-018, leaving the current pet/input/chat/
  voice/screen/settings accessibility boundaries unowned by that lane.
- `supportedEnvironments` lists only a Windows 11 development environment and `ubuntu-latest`, both
  targeting P0A.1. It does not freeze the `windows-latest` fixture/UIA environment or the interactive
  Windows 10/11 real-boundary matrix required by P0A.2 and P0A.8.

Required correction: expand the PB mappings and declare the future hosted/interactive Windows
environment identities/statuses without claiming unavailable environments ready.

### I-04 — Frozen fixture/oracle coverage omits required restart and stat literals

- The Gate 0A restart journey requires config/position/stats/history continuity, and PB-003 preserves
  position restore. `DATA-CONFIG-DEFAULTS` intentionally omits `lastX`/`lastY`, its artifact boundary
  list omits PB-003, and no other frozen fixture supplies a position restart canary.
- P0A.4 requires PB-009 offline decay. `ORACLE-STATS-BOUNDS` freezes only floors, omitting the public
  production cutoff and decay schedule in `AemeathStats.cs:37-42`: 0.1-hour skip; mood 5/2 with a
  four-hour fast period; energy 3/1 with a six-hour fast period; affection 1/0.5 with a twelve-hour
  fast period.
- `ORACLE-STATS-TIMER` freezes the five-minute interval and energy `-1` but omits the same observable
  tick's mood drift in `StatsService.cs:106-109`: above 55, `-0.5`; below 45, `+0.5`.

Required correction: add a non-secret position round-trip canary and complete the PB-009 literal
oracle without freezing wall-clock instants.

### I-05 — Source identity/provenance is not closed

The spec's canonical LF hashes match the current allowed files for `REQUIREMENTS.md`, the PRD, design,
and UI specification. They do not match the current plan:

- recorded `CURRENT:LOCATORS`: `0d20daf50ef166b78805f170972b517e1533a0b69afc274a44c8e0ef5628ad58`
- current LF-normalized plan: `7e4de8424f9f17d3d1e0ef63784483f59058db45f47eb5b849336980246b649c`

This is not CRLF drift; the same LF normalization reproduces every other recorded allowed-document
hash. The spec also cites an ADR and traceability artifact that this review assignment did not permit
the clean-room reviewer to inspect, and its reviewer `forbiddenSources` records only the two legacy
test directories rather than the plan's full forbidden categories (helpers, fixtures, snapshots,
generated expected values, assertions, and prior results/evidence).

Required correction: update or explicitly version-pin the locator identity, make the aggregate/root
hash method reproducible, and align the reviewer allow/deny declaration with the actual clean-room
contract. Until then P0A.1-R02 and P0A.1-R05 are not independently closed.

## Final verdict

**BLOCK.** The specification SHA and all four fixture hashes are stable, the 18 PB namespace is
structurally complete, all 21 written gaps are non-passing, and the reminder/daily-brief absence is
honestly represented. Nevertheless, the false SSE compatibility records (C-01) and five Important
completeness findings prevent this revision from serving as the frozen independent preservation
oracle.

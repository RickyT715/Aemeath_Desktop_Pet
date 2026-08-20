# P0A.1 preservation-spec-v2 clean-room review v4

## Decision

BLOCK.

Severity notation in this report is C = critical, I = important, and M = minor.
The final census is C1 / I5 / M1. The admissible PASS condition is C0 / I0 / M0,
so this review cannot issue PASS.

The current artifacts are unusually strong on raw identity, inventory counts, source-span
traceability, resource metadata, and explicit known-gap treatment. The blocking result is caused
by a clean-room provenance closure failure, one out-of-allowlist locator, one missing production
dependency gap, two non-reproducible exact claims, an unauditable portability/readiness claim, and
one environment-status documentation conflict.

## Formal findings

### C-01 — The exact-source clean-room contract is not closed over its own bound claims

Manifest risk P0A.1-R05 requires the clean-room reviewer to verify every bound claim from the exact
allowlist (docs/verification/manifests/P0A.1-v5.yml:37), and the assigned reviewer has
defaultDenyUnlistedSources=true (docs/verification/preservation-spec-v2.yml:3272-3299). Several
claims require sources or authorities that this reviewer is expressly forbidden to use:

- previousSpecification binds spec-v1 path, revision, status, and SHA
  (docs/verification/preservation-spec-v2.yml:7-12);
- previousTraceability binds traceability-v1 path and SHA
  (docs/verification/preservation-spec-v2.yml:168-171);
- DATA-V5 binds data-v1 through data-v4 lineage/predecessor hashes and counts and asserts that seven
  v1 payload spans were copied byte-for-byte
  (tests/fixtures/preservation/v1/data-v5.json:4-35,42,50);
- baseline and source revision Git identities are asserted, while Git inspection is prohibited
  (docs/verification/preservation-spec-v2.yml:19-21,61-103); and
- the manifest red oracle itself depends on immutable traceability-v1, frozen spec-v1, and successor
  validator behavior (docs/verification/manifests/P0A.1-v5.yml:54).

The currently allowed files can show that some of these values are repeated consistently; they
cannot independently establish their truth. This is a critical contract defect, not a request to
read a forbidden predecessor. The claims must be removed from the required clean-room proof,
materialized in an allowlisted independently checkable form, or explicitly labeled unreviewed
historical metadata.

### I-01 — CMP-BUILD-PACKAGE has an out-of-allowlist source locator

CMP-BUILD-PACKAGE names .github/workflows as a source locator
(docs/verification/preservation-spec-v2.yml:335-342), but the exact reviewer allowlist contains
only .github/workflows/release.yml (docs/verification/preservation-spec-v2.yml:3297-3298). Of 93
unique preservation-spec source locators, 92 are inside the allowed source closure and this one is
not. It must be narrowed to the exact release file or every intended workflow must be separately
allowlisted and bound.

### I-02 — The undeclared checkpoint dependency is not one of the 34 known gaps

Production imports langgraph.checkpoint.sqlite.aio.AsyncSqliteSaver
(python-backend/aemeath_agent/agent/checkpointer.py:6), while the complete project dependency list
does not declare langgraph-checkpoint-sqlite (python-backend/pyproject.toml:10-29). The plan
explicitly calls this a missing declaration and assigns its repair to Gate 0B / P0B.1
(docs/plans/20260722-jarvis-assistant-tdd-checklist.md:376-383,535-543).

The nearest frozen gap, GAP-SIDECAR-RELEASE-PACKAGE, says only that the sidecar and dependency set
are not bundled or qualified in the Windows release artifact and assigns P2.5
(docs/verification/preservation-spec-v2.yml:2858-2870). That does not preserve the distinct
production-manifest defect or its actual P0B.1 repair owner. This violates PB-011 and PB-017
replace-or-gap language about missing/undeclared dependencies.

### I-03 — recordsSha256 is an opaque repeated value, not an independently reproducible binding

The spec binds trace recordsSha256 at docs/verification/preservation-spec-v2.yml:105-111, and the
trace repeats it in dispositionMaps on its single physical line. No allowed source defines the
record selection, field selection, ordering, serialization, separator, encoding, or trailing
delimiter used to derive that digest. Independent attempts using the full 114 CURRENT records as a
JSON array, per-record compact JSON joined by LF, and obvious disposition-record field subsets did
not produce the bound digest. Raw trace SHA, entry counts, every source-span hash, and all references
were independently verified, but this additional digest cannot be.

### I-04 — The exact SSE wire bytes depend on an unpinned, non-allowlisted formatter implementation

Production proves that the sidecar yields already framed strings
(python-backend/aemeath_agent/api/sse.py:7-23) to EventSourceResponse
(python-backend/aemeath_agent/api/routes_agent.py:8,32-81). The fixture goes further and freezes exact
CRLF wire strings produced by sse-starlette
(tests/fixtures/preservation/v1/protocol-v1.json:9-10,12). The only allowed dependency authority is
sse-starlette>=2.0.0 with no upper bound or lock (python-backend/pyproject.toml:21); the dependency
implementation and installed environment are outside the allowlist. The framing-risk conclusion is
supported, but the exact wire bytes are neither stable nor independently derivable from allowed
production sources.

### I-05 — Validator portability and ready-environment claims are not auditable from allowed inputs

The manifest pins only the invocation
./tools/verification/Test-PreservationSpecification.ps1 and requires Windows PowerShell 5.1 plus a
pinned Python jsonschema fallback and PowerShell 7.4+ on Ubuntu
(docs/verification/manifests/P0A.1-v5.yml:49-54,99-104). The validator implementation and existing
evidence are forbidden to this reviewer, and execution is prohibited. The command spelling is
lexically usable from PowerShell with the repository root as current directory, but implementation
compatibility, fallback pinning, discovery behavior, and the ready statuses of ENV-WINDOWS-LOCAL and
ENV-GHA-UBUNTU cannot be independently verified. A portable command contract or allowlisted,
source-bound capability record is required.

### M-01 — D0.4 completion conflicts with the conservative interactive-environment statuses

The plan marks D0.4 complete and says resettable interactive Windows 10/11 workers and their
capabilities were provisioned and proved
(docs/plans/20260722-jarvis-assistant-tdd-checklist.md:364-374). The spec instead marks both
interactive environments blocked-not-provisioned
(docs/verification/preservation-spec-v2.yml:2729-2755). The spec is appropriately conservative and
does not count them as ready, but the allowed normative documents disagree and should be reconciled.

## Exact clean-review bindings

The following are the eleven exact bindings produced by this reviewer. No other line in this report
begins with BINDING.

BINDING 01 | kind=raw-file | path=docs/verification/preservation-spec-v2.yml | sha256=44a256a79cfb6b4c127aa79a7ae2f0c89b8f94a487e75a71797460bf0dcd4cd5 | bytes=158127
BINDING 02 | kind=raw-file | path=docs/verification/manifests/P0A.1-v5.yml | sha256=17f262ff6f2e9c038ce3001b554080b5e39c3e6bb4428ee02b5d47e890c8da91 | bytes=10224
BINDING 03 | kind=raw-file | path=docs/verification/traceability-v2.yml | sha256=28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415 | bytes=478168
BINDING 04 | kind=raw-file | path=tests/fixtures/preservation/v1/data-v5.json | sha256=4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0 | bytes=41016
BINDING 05 | kind=raw-file | path=tests/fixtures/preservation/v1/oracles-v1.json | sha256=4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d | bytes=7954
BINDING 06 | kind=raw-file | path=tests/fixtures/preservation/v1/protocol-v1.json | sha256=95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312 | bytes=7334
BINDING 07 | kind=raw-file | path=tests/fixtures/preservation/v1/resources-v1.json | sha256=63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8 | bytes=3167
BINDING 08 | kind=production-root | path=src/AemeathDesktopPet | fileCount=94 | sha256=28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb | recordBytes=9274
BINDING 09 | kind=production-root | path=python-backend/aemeath_agent | fileCount=46 | sha256=98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae | recordBytes=4091
BINDING 10 | kind=raw-file | path=python-backend/pyproject.toml | sha256=7cb128bcda68eb2b5e890c0c390c0c4f46f6a24c474d8753ce904416ef10463d | bytes=1266
BINDING 11 | kind=raw-file | path=.github/workflows/release.yml | sha256=066dd7244e6ac12bd350500cbe6ee1f7dd34eee40ef5b7b851e67abf161f7fe9 | bytes=1324

## Structural census and identity verification

| Surface | Independently observed | Frozen expectation | Result |
|---|---:|---:|---|
| Components | 20 | 20 | exact |
| Public behaviors | 18 | 18 | exact |
| Persisted atomic targets | 16 | 16 | exact |
| Data fixture records | 17 | 17 | exact |
| Application-owned targets | 12 | 12 | exact |
| External read-only targets | 4 | 4 | exact |
| Current production-writable targets | 10 | 10 | exact |
| Latent writable/currently read-only targets | 2 | 2 | exact |
| Integration boundaries | 13 | 13 | exact |
| Windows journeys | 5 | 5 | exact |
| Preservation boundaries | 18 | 18 | exact |
| Qualification lanes | 14 | 14 | exact |
| Supported environments | 5 | 5 | exact |
| Artifacts | 4 | 4 | exact |
| Known gaps | 34 unique | 34 | exact count; completeness fails I-02 |
| Scope requirement IDs | 34 (17 CURRENT, 17 PRD) | 34 | exact |
| Trace entries | 352 (114 CURRENT, 238 PRD) | 352 / 114 CURRENT | exact |
| Oracle records | 28 | 28 | exact |
| Protocol contracts | 15 | 15 | exact |
| Resources | 11 | 11 | exact |
| Production files | 140 (94 + 46) | 140 | exact |

The six normalized source hashes were recomputed using UTF-8 without BOM, CRLF/CR-to-LF
normalization, and checkbox normalization only for the plan. All matched:

| Source | Mode | Recomputed SHA-256 |
|---|---|---|
| REQUIREMENTS.md | normalized-text | 94c8c95a75ca7f6f417e4b6358042ed727656cd58074213f878ddbaaeff37cbc |
| TDD checklist | normalized-checkbox-text | 0d20daf50ef166b78805f170972b517e1533a0b69afc274a44c8e0ef5628ad58 |
| PRD | normalized-text | b2ee8dfaffdfa27e22f820f5bf7f6a065a360933a5c4b1789b4cd1ea27d791b2 |
| Design | normalized-text | f280cdbd89946d934888cd91ef2c7fafa0478126f58ec2e4365f7be23481f12b |
| UI spec | normalized-text | 806d37aa63a719dda7de7446c2e6ff6bbc55243eb0ce6478d6464ad7ca68b1c1 |
| ADR-0002 | normalized-text | 21ac1e7df434b37d4a8fe596d8dcceab9f26eb386f5d77cf88b052473253f9e9 |

The production-root digest algorithm was independently reimplemented from the spec: excluded
directories/suffixes and reparse points, slash-normalized relative path, raw byte length and
lowercase SHA-256 records, ordinal sort, LF join without trailing delimiter, UTF-8 without BOM.
Both root counts and digests match BINDING 08 and BINDING 09.

## PB-by-PB review

| PB | Reviewed production/normative surface | Result |
|---|---|---|
| PB-001 | startup, one host/window, owned cleanup, offline data root | verified |
| PB-002 | pet window, included sprites, behavior/physics constants, randomness boundary | verified |
| PB-003 | drag/click/tray/click-through/position restore and recovery surfaces | verified |
| PB-004 | bubble, particles, plane and optional-cat current behavior plus disclosed gaps | verified |
| PB-005 | text conversation/history/offline paths and response/SSE/failover gaps | verified except I-04 exact wire |
| PB-006 | voice/STT/TTS/hotkey/audio surfaces and STT gap | verified |
| PB-007 | screen capture/privacy controls and screenshot/privacy gaps | verified |
| PB-008 | eight settings tabs, config persistence, plaintext/control gaps | verified |
| PB-009 | stats, messages and local-data lifecycle | verified |
| PB-010 | optional Pomodoro/music/activity integration and absence behavior | verified |
| PB-011 | sidecar supervision/offline behavior/port/release gaps | incomplete: I-02 and I-05 |
| PB-012 | WPF-sidecar request/result/stream/STT/reverse-route contracts | verified except I-04 |
| PB-013 | agent/tools/RAG behavior and retrieval/daily-brief gaps | verified |
| PB-014 | C# and Python memory authorities, persistence and missing loops | verified |
| PB-015 | MCP shape, disabled default, lifecycle/auth gaps | verified |
| PB-016 | secrets, loopback authorization, redaction and privacy gap ownership | verified |
| PB-017 | build/package/dependency/release surface | incomplete: I-01, I-02 and I-05 |
| PB-018 | Windows UI/DPI/accessibility/performance/reliability scope | qualified, subject to I-05 and M-01 |

No preserve statement was treated as proof of a future behavior. Every partial or absent current
behavior had to be false-as-baseline and linked to a later RED step or pending approval.

## Persisted-data audit

The 17 records map to exactly these 16 atomic targets:

| Target | Fixture record(s) | Ownership/access |
|---|---|---|
| DATA-CONFIG | DATA-CONFIG-DEFAULTS; DATA-CONFIG-POSITION-RESTART | application/read-write |
| DATA-STATS | DATA-STATS-BASELINE | application/read-write |
| DATA-MESSAGES | DATA-MESSAGES-TURN | application/read-write |
| DATA-CORE-MEMORY | DATA-CORE-MEMORY | application/read-write-api, latent |
| DATA-PROCEDURAL-MEMORY | DATA-PROCEDURAL-MEMORY | application/read-write-api, latent |
| DATA-OBSERVATION-BUFFER | DATA-OBSERVATION-BUFFER | application/read-write |
| DATA-STARTUP-RUN-REGISTRY | DATA-STARTUP-RUN-REGISTRY | application/read-write |
| DATA-AGENT-CHECKPOINT | DATA-AGENT-CHECKPOINT | application/read-write |
| DATA-PYTHON-MEMORY-STORE | DATA-PYTHON-MEMORY-STORE | application/read-write |
| DATA-PYTHON-MEMORY-BLOCKS | DATA-PYTHON-MEMORY-BLOCKS | application/read-write |
| DATA-CHROMA | DATA-CHROMA | application/read-write |
| DATA-TODO | DATA-TODO | application/read-write |
| DATA-ACTIVITY-SQLITE | DATA-ACTIVITY-SQLITE-READONLY | external-user/read-only |
| DATA-SIDECAR-ENVFILE | DATA-SIDECAR-ENVFILE-READONLY | external-operator/read-only |
| DATA-MUSIC-LIBRARY | DATA-MUSIC-LIBRARY-READONLY | external-user/read-only |
| DATA-RAG-SOURCE-DOCUMENTS | DATA-RAG-SOURCE-FILE-OR-DIRECTORY-READONLY | external-user/read-only |

For every target, ownership, access, lifecycle, path/path semantics, production locators, PB links,
and the union of its fixture records matched the preservation spec. Production scans found no
additional durable target. Temporary STT WAV handling was correctly excluded as temporary rather
than durable. The current/latent writable split is 10/2. The historical byte-copy and predecessor
claims remain blocked by C-01.

## Trace, requirements, locators, and gaps

- All 352 trace source ranges were re-read from the UTF-8 normative source and all 352
  sourceTextSha256 values matched.
- CURRENT has 114 entries: 59 numbered requirements, 44 acceptance criteria, and 11 locators.
  Their disposition census is 96 preserve/preserve/not-required, 12 preserve/change/pending, and
  6 preserve/defer/pending.
- PRD has 238 entries: 144 acceptance criteria, 8 NFR parents, 44 NFR leaves, 28 gates, and 14 risks.
- All 100 unique plan/design/UI Markdown heading references resolved to independently computed
  GitHub-style anchors.
- Cross-reference checks found no orphan PB, component, behavior, data, integration, journey, lane,
  artifact, environment, fixture, oracle, protocol, requirement, trace-entry, or future-test ID.
- All 34 scope requirements are present in the trace and exactly equal the manifest set.
- All 34 gap objects are unique, have countsAsPassingBaseline=false, and provide requirement IDs,
  PB IDs, and a later step or explicit pending-approval token. All referenced requirement IDs and
  later-step/approval tokens exist.
- Source-locator closure is 92 of 93 because of I-01.
- The CURRENT records digest remains unreproducible because of I-03.

The 34 frozen gaps and their owners were individually checked:

| Gap | Later RED / decision | Source assessment |
|---|---|---|
| GAP-PET-THROW-RELEASE | P4.5a | accurate |
| GAP-PET-EDGE-SUBSCRIPTIONS | P4.5b | accurate |
| GAP-PAPER-PLANE-RENDERER | P4.5c | accurate |
| GAP-FULLSCREEN-PET-POLICY | P4.5d | accurate |
| GAP-KEYBOARD-COMPANION-SURFACE | P4.5e | accurate |
| GAP-STATE-CAT-ASSETS | pending APP-008 | accurate |
| GAP-SIDECAR-CONFIGURED-PORT | P2.2 | accurate |
| GAP-SIDECAR-RELEASE-PACKAGE | P2.5 | accurate but does not cover I-02 |
| GAP-AGENT-SCREENSHOT-SHAPE | P2.1 | accurate |
| GAP-AGENT-RESPONSE-FIELD | P2.1 | accurate |
| GAP-STT-CONTRACT | P9.1b | accurate |
| GAP-RAG-LIVE-CONFIG | P9.2 | accurate |
| GAP-MCP-LIFECYCLE | P10.1 | accurate |
| GAP-MEMORY-AUTHORITIES | P7.2/P7.5 | accurate |
| GAP-MEMORY-CONTROL-UI | P7.4 | accurate |
| GAP-PLAINTEXT-SECRETS | P1.4/P0B.3c | accurate |
| GAP-LOOPBACK-AUTH | P2.2/P2.4 | accurate |
| GAP-WPF-BRIDGE-ROUTE-DRIFT | P2.1/P2.4 | accurate |
| GAP-UI-AUTOMATION-SEMANTICS | P0B.3 | accurate |
| GAP-REMINDER-LOOP-MISSING | P5.1/P5.2 | accurate |
| GAP-DAILY-BRIEF-MISSING | P5.3/P5.4 | accurate |
| GAP-AGENT-SSE-FRAMING | P2.1 | semantic risk accurate; exact wire blocked by I-04 |
| GAP-AGENT-SSE-TOOL-CALL | P2.1 | accurate |
| GAP-AGENT-SSE-ERROR-VISIBILITY | P2.1 | accurate |
| GAP-CHAT-TIER-FAILOVER | P2.3/P3.3 | accurate |
| GAP-VISION-SAVED-PRIVACY-CONTROLS | P6.3 | accurate |
| GAP-RUNTIME-CONFIG-SYNC-NOOP | P2.1/P2.2 | accurate |
| GAP-SIDECAR-ENV-PREFIX-DRIFT | P2.2 | accurate |
| GAP-USER-BLOCK-STARTUP-SNAPSHOT | P7.3 | accurate |
| GAP-PROCEDURAL-LEARNING-CONSOLIDATION | P7.3 | accurate |
| GAP-MEMORY-FORGET-TIME-RANGE | P7.2/P7.4 | accurate |
| GAP-MEMORY-DISTILLATION-FALSE-SUCCESS | P7.3 | accurate |
| GAP-MINIGAMES-MISSING | pending APP-007 | accurate |
| GAP-INTERACTION-SOUNDS-MISSING | pending APP-009 | accurate |

The omitted dependency-manifest gap in I-02 is a 35th distinct production truth even though the
frozen required gap count is 34.

## Fixture and oracle audit

### Literal, geometry, stat, time, property, and gap oracles

All 28 oracle IDs were checked against production:

- geometry/literal: ORACLE-WINDOW-PET, ORACLE-WINDOW-CAT, ORACLE-WINDOW-CHAT,
  ORACLE-WINDOW-SETTINGS, ORACLE-WINDOW-STATS, ORACLE-BUBBLE-GEOMETRY, ORACLE-DPI;
- stats: ORACLE-STATS-DEFAULTS, ORACLE-STATS-CHAT, ORACLE-STATS-PET, ORACLE-STATS-SING,
  ORACLE-STATS-PLANE, ORACLE-STATS-GAME, ORACLE-STATS-BOUNDS, ORACLE-STATS-TIMER;
- physics/animation/time: ORACLE-PHYSICS, ORACLE-ANIMATION-RATE,
  ORACLE-OBSERVATION-TTL, ORACLE-DISTILLATION-TIMER, ORACLE-BUBBLE-TIMING;
- memory/speech/ports/MCP: ORACLE-MEMORY-LIMITS, ORACLE-SPEECH-RANGES,
  ORACLE-BACKEND-PORTS, ORACLE-MCP-PROTOCOL; and
- declared negative boundaries: ORACLE-AUTOMATION-GAP, ORACLE-REMINDER-GAP,
  ORACLE-PROTOCOL-GAP, ORACLE-RANDOMNESS-BOUNDARY.

Window sizes/minima, transparency/topmost/taskbar/resize flags, eight Settings tabs, PerMonitorV2,
stat defaults/deltas/bounds/decay, physics constants, 9/25 FPS values, storage/context limits,
24-hour observation TTL, 30-minute distillation interval, 4-second/30-ms bubble timing, speech
ranges, ports 18900/18901, unauthenticated loopback, MCP version/defaults, and all four negative
boundaries matched production. Exact random sequences and GIF delay metadata are correctly not
claimed.

### Protocol contracts

All 15 contracts were inspected:

- compatible/current shapes: PROTOCOL-AGENT-REQUEST, PROTOCOL-HEALTH, PROTOCOL-VISION,
  PROTOCOL-RAG, PROTOCOL-MEMORY, PROTOCOL-INTERNAL-WPF-SERVER, and PROTOCOL-MCP;
- accurately declared incompatible shapes: PROTOCOL-AGENT-REQUEST-SCREENSHOT-GAP,
  PROTOCOL-AGENT-RESPONSE-GAP, PROTOCOL-SSE-TOOL-CALL-GAP,
  PROTOCOL-SSE-ERROR-GAP, and PROTOCOL-INTERNAL-WPF-BRIDGE-GAP;
- PROTOCOL-STT accurately records the JSON-versus-multipart contract difference; and
- PROTOCOL-SSE-TOKEN and PROTOCOL-SSE-DONE accurately identify already-framed producer strings,
  but their exact wire values are blocked by I-04.

No contract was changed from incompatible to compatible by this review.

### Resources

Raw bytes and SHA-256 were independently recomputed for all 11 resources. GIF logical dimensions
and frame counts were independently parsed from raw GIF structure. Runtime status was cross-checked
against the project file, AnimationEngine, BehaviorEngine, PetWindow, and App.xaml.

| Resource | Bytes | GIF metadata | SHA-256 | Runtime status |
|---|---:|---|---|---|
| tray_icon.ico | 80963 | n/a | 5f8767540b2480d47d2fd6b52c2c70469544a2af9bd24d53950cc0330c4c6c8c | packaged-and-used |
| happy_hand_waving.gif | 124893 | 200x200, 8 | b5da3d7e7bbfa655142fa98d335eb5ad7e96c0da469df7a797be2033046c81d5 | preloaded-and-mapped |
| happy_jumping.gif | 117433 | 200x200, 7 | 7a3e368164f06cedf53f19ad9a3ae5d9382fec2089ee5172f48e56ba61703433 | preloaded-and-mapped |
| laugh.gif | 127935 | 200x200, 7 | dd00df434bd9022f7e754600addefdc5c1dee565ff70491b0e04038754d62fa2 | preloaded-and-mapped |
| laugh_flying.gif | 124762 | 200x200, 8 | 7d123a4a686000d0091a66f96e44e04974d1c825d89378edcb74dff400ae1b98 | preloaded-but-unmapped |
| listening_music.gif | 4458762 | 1000x1000, 37 | 53eaed43551bb78b5b8a6886d5e0fc7e9bcf7b8025f624fdc6b63f181560bec2 | preloaded-and-mapped |
| normal.gif | 231230 | 200x200, 16 | f9618f963bb5a8ef3b1e1cd54487e28ea1d4e24eebd236691bdef81245ce420a | preloaded-mapped-and-fallback |
| normal_flying.gif | 135292 | 200x200, 8 | 56edf4df3bbffa2eaf9e735eed19f1e738025e792b681001bde85c3cd52d974e | preloaded-and-mapped |
| sign.gif | 368696 | 200x200, 25 | 12d7165ef2e05c173307abf7f98ae9b9c1da64de89b8b78fc5aa1eb323443ae8 | preloaded-and-mapped |
| seal.gif | 11971 | 300x250, 4 | cc1032a88b51877c83320624a940c64be8724b5457e5ab6fee6f528f09c26433 | packaged-but-not-preloaded |
| AemeathTheme.xaml | 4117 | n/a | ebcf2b748ce58731c5b488f2a2b2c60260646b552d8a96c478ed86097891dd10 | merged-at-application-startup |

## Lane and environment audit

All 14 lanes are required. Every listed owner step exists, every test ID exists in the
traceability-v2 testCatalog, and the PB coverage is internally closed:

| Lane | PB count | Future test IDs | Result |
|---|---:|---:|---|
| V-UNIT | 18 | 5 | closed |
| V-COMPONENT | 13 | 6 | closed |
| V-CONTRACT | 13 | 2 | closed |
| V-WPF | 9 | 1 | closed |
| V-UIA | 10 | 2 | closed |
| V-FIXTURE-E2E | 18 | 3 | closed |
| V-REAL-E2E | 18 | 2 | closed |
| V-SECURITY | 11 | 3 | closed |
| V-ACCESS | 12 | 2 | closed |
| V-PERF | 8 | 2 | closed |
| V-PACKAGE | 11 | 1 | closed |
| V-STATIC | 18 | 4 | closed |
| V-MANUAL-WIN | 4 | 1 | closed |
| V-LEGACY | 18 | 1 | closed |

The five environment declarations are:

| Environment | Frozen status | Target steps | Review result |
|---|---|---|---|
| ENV-WINDOWS-LOCAL | ready | P0A.1 | declaration consistent; proof unavailable under I-05 |
| ENV-GHA-UBUNTU | ready | P0A.1 | declaration consistent; proof unavailable under I-05 |
| ENV-GHA-WINDOWS | capability-observed-qualification-pending | P0A.2/P0A.6/P0A.7 | conservative |
| ENV-INTERACTIVE-WIN10 | blocked-not-provisioned | P0A.2/P0A.8 | conservative; conflicts with plan under M-01 |
| ENV-INTERACTIVE-WIN11 | blocked-not-provisioned | P0A.2/P0A.7/P0A.8 | conservative; conflicts with plan under M-01 |

The release workflow independently confirms a Windows-only WPF self-contained publish and no
Python-sidecar package, supporting GAP-SIDECAR-RELEASE-PACKAGE. It does not establish validator
portability.

## Sources actually read and exposure record

Repository content read was limited to the exact 17 entries below. For the two production roots,
all included files were read as raw bytes for the root digest, and relevant files were semantically
inspected:

1. REQUIREMENTS.md
2. docs/prd/jarvis_assistant_prd.md
3. docs/design/jarvis_assistant_design.md
4. docs/ui-spec/jarvis_assistant_ui_spec.md
5. docs/plans/20260722-jarvis-assistant-tdd-checklist.md
6. docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md
7. docs/verification/traceability-v2.yml
8. docs/verification/manifests/P0A.1-v5.yml
9. src/AemeathDesktopPet recursively
10. python-backend/aemeath_agent recursively
11. python-backend/pyproject.toml
12. .github/workflows/release.yml
13. tests/fixtures/preservation/v1/data-v5.json
14. tests/fixtures/preservation/v1/oracles-v1.json
15. tests/fixtures/preservation/v1/protocol-v1.json
16. tests/fixtures/preservation/v1/resources-v1.json
17. docs/verification/preservation-spec-v2.yml

No legacy test, helper, snapshot, result, existing evidence file, validator/generator source,
spec-v1, trace-v1, Git object, or network resource was read. No project, validator, test, Git, or
network command was executed. A path-existence check was made for the spec-claimed locator
.github/workflows; no non-allowlisted workflow file was enumerated or read.

Before repository work, the platform required reading the external skill file
C:/Users/Ricky/.codex/plugins/cache/openai-curated-remote/superpowers/6.3.0/skills/using-superpowers/SKILL.md.
This was disclosed immediately. It is outside the repository, contained process instructions only,
and supplied no product fact, expected value, oracle, or review conclusion. No other external source
was used.

## Final census

| Severity | Count | IDs |
|---|---:|---|
| Critical | 1 | C-01 |
| Important | 5 | I-01, I-02, I-03, I-04, I-05 |
| Minor | 1 | M-01 |

Final decision: BLOCK. PASS is prohibited because the census is not C0 / I0 / M0.

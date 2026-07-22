# Execution Checklist: Aemeath Trusted-Assistant Evolution

**Status:** Ready for Delivery Preflight; Gate 0 remains locked behind it, and affected exception
cutovers remain blocked until item-specific disposition decisions exist  
**Checklist version:** 1.0  
**Source plan:** [Aemeath Trusted-Assistant Evolution](20260722-jarvis-assistant-evolution.md)  
**PRD:** [Aemeath Personal Assistant Evolution](../prd/jarvis_assistant_prd.md)  
**Architecture decisions:** [ADR-0001](../adr/ADR-0001-evolutionary-modular-assistant-architecture.md)
and [ADR-0002](../adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md)  
**Canonical current requirements:** [REQUIREMENTS.md](../../REQUIREMENTS.md)

This is the authoritative execution checklist. It turns the roadmap into independently verifiable,
commit-sized gates. The first implementation work is qualification of the current behavior that will
be retained. No architectural migration or new assistant capability may start until Gate 0 passes.

## 1. Non-negotiable execution contract

- [ ] Work on exactly one numbered execution step at a time.
- [ ] Freeze that step's risk map and lane manifest before running its first test or probe.
- [ ] For changed or new behavior, write and run a focused executable test/probe first and retain a
  valid RED result at the intended oracle.
- [ ] For a pure behavior-preserving refactor, write an independent characterization test first,
  prove it is GREEN on the unchanged baseline, and prove a representative mutation makes it fail.
- [ ] Make the smallest GREEN change, refactor while green, then run every required lane.
- [ ] Run the independently authored preservation suite and the pre-existing legacy suite separately.
- [ ] Update requirement, architecture, operator, privacy, and user documentation when truth changes.
- [ ] Commit only the focused step. Never include unrelated working-tree changes.
- [ ] Never add `Co-Authored-By` or Codex attribution to a commit.
- [ ] Push the focused commit and record its head SHA.
- [ ] Wait for every required GitHub Actions job and matrix entry for that exact head SHA.
- [ ] Treat missing, zero-test, skipped, neutral, cancelled, timed-out, advisory, quarantined,
  path-filtered, reduced-matrix, or merge-SHA-only results as failures.
- [ ] Diagnose and fix failures inside the same step. Push the correction and replace the evidence
  SHA. Do not begin the next step until the final exact-SHA manifest is completely green.

Deliberately broken RED work is retained as a local test result/artifact or an intermediate local
commit. A step is pushed as complete only after GREEN, REFACTOR, and VERIFY succeed.

## 2. Status and evidence format

Allowed checklist statuses are `NOT STARTED`, `RED`, `GREEN`, `VERIFYING`, `BLOCKED`, and `DONE`.
`DONE` requires every field in this packet:

```yaml
step: P0A.1
status: DONE
current_requirements: [CURRENT:AR-001]
prd_acceptance: [PRD:AC-FR-021-01]
prd_nfr: [PRD:NFR-JA-005-01]
gate_criteria: [PRD:GATE-0-01]
risks: [PRD:RISK-010]
dispositions: [REQMAP-AR-001]
baseline_sha: <40-character SHA>
risk_manifest: docs/verification/manifests/P0A.1-v1.yml
tests_and_probes: [PB-001-V-UNIT-001]
red:
  command: <exact command>
  expected_oracle: <behavioral diagnostic>
  result_artifact: <path or link>
green:
  command: <exact command>
  result_artifact: <path or link>
verify:
  commands: [<all required lane commands>]
  discovered: {unit: 1, integration: 1}
  result_artifacts: [<paths or links>]
legacy_regression: <separate result link>
commit_sha: <40-character SHA>
push_branch: agent/project-documentation-sync
github:
  workflow: <workflow path>
  event: <pull_request, push, or workflow_dispatch>
  run_id: <run ID>
  head_sha: <must equal commit_sha>
  required_jobs: [<job names and full matrix>]
  artifacts: [<artifact names and retention>]
rollback: <tested rollback or no-data-change statement>
documentation: [<updated truth sources>]
review: <reviewer and disposition>
```

Evidence lives under `docs/verification/` for compact manifests/reports and in GitHub Actions
artifacts for raw TRX, JUnit, logs, dumps, screenshots, UI Automation trees, performance traces, and
package inspection. Evidence must contain no credentials, captured personal content, or user-profile
paths.

### 2.1 Mandatory commit-size decomposition

The following headings are parent groups and are never executed as one commit. Every listed child
has its own frozen manifest, test-first cycle, focused commit, push, and exact-SHA CI wait. Further
split a child before RED if its owner/risk/write set is still not reviewable as one change.

| Parent | Executable child steps |
|---|---|
| P0A.3 test-only harness | P0A.3a external isolation guards; P0A.3b known-bad detection fixtures; P0A.3c real-executable/test-only launcher and cleanup |
| P0A.4 domain/engine | P0A.4a resources/animation; P0A.4b behavior/physics/input; P0A.4c stats/time; P0A.4d bubble/effects/plane/cat; P0A.4e optional integrations |
| P0A.5 composition/data | P0A.5a lifecycle/offline; P0A.5b chat/history; P0A.5c config/stats/memory inventory; P0A.5d voice/screen privacy; P0A.5e Python/protocol/MCP/security characterization |
| P0B.1 baseline repair | P0B.1a admit/classify legacy; P0B.1b .NET defects/tests/format; P0B.1c Python defects/tests/Ruff; P0B.1d dependency manifests/locks/import smoke |
| P0B.2 deterministic seams | P0B.2a clock/random/scheduler; P0B.2b data root/atomic files; P0B.2c Windows/screen/DPI; P0B.2d process/network/sidecar; P0B.2e audio/registry/provider/index; P0B.2f dispatcher/readiness/shutdown/TestHost |
| P0B.3 accessibility | P0B.3a Pet/tray; P0B.3b Chat/voice; P0B.3c Settings/secrets; P0B.3d stats/bubble/cat; P0B.3e semantic theme/contrast/motion/scale; P0B.3f process UIA journeys |
| P3.1 task ledger | P3.1a schema/events; P3.1b reducer/property rules; P3.1c repository/concurrency; P3.1d restart/recovery/retention |
| P4.1 Command Center shell | P4.1a window/nav/layout; P4.1b Today/Conversation routes; P4.1c Tasks/Activity routes; P4.1d Memory/Capabilities routes; P4.1e Settings/Diagnostics routes |
| P4.5 retained pet gaps | P4.5a drag-release/throw; P4.5b edge subscriptions/poses; P4.5c plane renderer; P4.5d fullscreen policy; P4.5e keyboard/access recovery |
| P7.2 canonical memory | P7.2a schema/provenance; P7.2b repository/query; P7.2c correction/forget/retention; P7.2d protection/audit; P7.2e derived-index boundary |
| P9.1 voice | P9.1a capture/audio state; P9.1b STT contracts/providers; P9.1c transcript/confidence/routing UI; P9.1d TTS queue/cancel/barge/mute; P9.1e real-device evidence |
| P11.1 packaging | P11.1a WPF package; P11.1b selected sidecar package; P11.1c clean install/upgrade/rollback; P11.1d signing/SBOM/licenses; P11.1e offline/first-run matrix |

## 3. Frozen preservation source and authorship rule

Gate 0's independent specification is derived from current requirements, documented user behavior,
public production contracts, separately calculated literals, runtime observation, and approved
fixtures—not from existing tests.

| Field | Frozen value |
|---|---|
| Current requirements source commit | `c2e3dbfd5e90bb40ea5006b702bbbc32d24a1ae7` |
| `REQUIREMENTS.md` SHA-256 | `94c8c95a75ca7f6f417e4b6358042ed727656cd58074213f878ddbaaeff37cbc` |
| Independent behavior namespace | `PB-001` through `PB-018` |
| Legacy .NET project | `tests/AemeathDesktopPet.Tests/`—regression only |
| Legacy Python directory | `python-backend/tests/`—regression only |
| Forbidden dependencies | Legacy test projects, helpers, fixtures, snapshots, generated expected values, and assertions |

- [ ] Freeze `docs/verification/preservation-spec-v1.yml`, its fixture hashes, literal oracles, source
  locators, and author exposure declarations before any unexposed author reads legacy test code.
- [ ] Record that repository analysis has already exposed current participants to legacy test names,
  counts/results, and potentially selected implementation areas. For every affected oracle, obtain
  specification/oracle review from a contributor without that exposure or obtain explicit user
  approval of a separately derived external oracle. Do not make a false clean-room chronology claim.
- [ ] After the independent suite is frozen, enforce dependency checks proving it cannot reference or
  copy a legacy test assembly/module or fixture path.
- [ ] Run legacy tests only after the independent suite result is fixed. A discrepancy opens a
  versioned review; legacy expectations never silently rewrite the independent oracle.

### 3.1 Preservation-boundary inventory

These stable IDs are shared with the design and UI specification. They classify boundaries, not
individual test cases; each boundary expands into the risk-mapped lanes in Gate 0.

| ID | Current boundary | Preserve | Replace rather than freeze |
|---|---|---|---|
| PB-001 | Application startup/lifecycle/shutdown | One pet per application instance, owned cleanup, compatible data root | Direct construction and unbounded background effects |
| PB-002 | Pet window, sprites, behavior, physics | Transparent topmost embodiment, movement and source timing | Random output/placeholder mapping as exact oracle |
| PB-003 | Pet input, tray, click-through, position | Equivalent access/recovery and on-screen restore | Mouse-only access and coordinate-only automation |
| PB-004 | Bubble, particles, plane, optional cat | Visible feedback, lifecycle, counters and cat behavior | Invisible renderer, emoji-only semantics, uncontrolled timers |
| PB-005 | Text conversation/history/offline | Ordered streaming, failure recovery, history and offline use | Stored placeholder, silent routing and provider orchestration in UI |
| PB-006 | Voice/STT/TTS/hotkey/audio | Opt-in push-to-talk, visible state, provider choice and text fallback | Mouse-only hold and mismatched backend/credential contracts |
| PB-007 | Screen awareness/privacy indicator | Explicit opt-in, exclusions, indicator and stop/budget controls | Background capture without task consent and color-only state |
| PB-008 | Settings/config compatibility | Eight categories, safe Cancel, validated atomic migration | Plaintext keys, raw MCP commands and unlabeled monolith |
| PB-009 | Stats/chat/local-data lifecycle | Literal stats/history continuity, backup/compare/rollback | Real-profile tests and destructive unversioned writes |
| PB-010 | Companion/Pomodoro/activity integrations | Optional enablement, event semantics and graceful absence | Direct external mutation in deterministic CI |
| PB-011 | Sidecar supervision/offline degradation | Optional advanced runtime and bounded lifecycle | Health-only readiness, port drift and source-tree assumptions |
| PB-012 | WPF-sidecar streaming/STT protocol | Compatible user outcomes and conversation continuity | Unauthenticated reverse API and divergent hand-written DTOs |
| PB-013 | Python agent/tools/retrieval | Approved useful outcomes, citations and degradation | Broad tools, unconfigured RAG and model-owned side effects |
| PB-014 | C#/Python memory sources | Recoverable facts/history, provenance and deletion expectation | Multiple authorities, stale caches and incomplete forget semantics |
| PB-015 | MCP definitions/process lifecycle | Compatible definitions after consent/migration review | Unwired settings claims, raw execution and stale schema grants |
| PB-016 | Secrets/redaction/local authorization | Non-secret settings and user choices without disclosure | Plaintext credentials, token leakage and loopback-as-auth |
| PB-017 | Build/package/install/rollback | Supported Windows artifact and clear degradation | Undeclared dependency and evidence from another SHA |
| PB-018 | Windows UI/accessibility/performance | Windows 10/11 x64, DPI, contrast, motion, keyboard/Narrator and budgets | Missing automation semantics and dynamic pixel goldens |

## 4. Canonical current-requirement disposition map

The map is **proposed until item-specific exception approvals are recorded**. `Preserve` protects the
normative requirement even when its implementation is refactored, completed, or replaced. `Change`
means the requirement promise itself changes; `Defer` moves that promise beyond this release. An
unapproved Change/Defer is operationally Preserve and blocks affected work. No entry is removed.

`Gate 0 treatment` distinguishes observable baseline behavior from a Partial or Planned promise.
Gate 0 qualifies only behavior/invariants that exist at its frozen source SHA. A Partial item's gap
and a Planned item begin later with a valid RED test; they cannot be counted as a passing baseline.

### 4.1 Architecture, pet, and interaction

| Map ID | Current ID | Current status | Disposition / approval | Gate 0 treatment and later target |
|---|---|---|---|---|
| REQMAP-AR-001 | AR-001 | Implemented | Preserve | Qualify offline host with PB-001/PB-011 and clean-machine E2E |
| REQMAP-AR-002 | AR-002 | Partial | Preserve | Qualify working default-port behavior and known port gap; complete authenticated/versioned configured-port contract in P2 |
| REQMAP-AR-003 | AR-003 | Implemented | Proposed Change `APP-001` (pending; effective Preserve) | Qualify current boundary without treating it as secure; replace reverse API with host broker only after approval |
| REQMAP-AR-004 | AR-004 | Partial | Preserve | Qualify current selection/offline outcome; add deterministic tier failover with RED tests in P2 |
| REQMAP-AR-005 | AR-005 | Implemented | Preserve | Qualify local binding and non-auth disclosure; add auth without claiming loopback itself is security |
| REQMAP-FR-PET-001 | FR-PET-001 | Implemented | Preserve | PB-002/PB-003 WPF, UIA, and real tray boundary |
| REQMAP-FR-PET-002 | FR-PET-002 | Implemented | Preserve | PB-002 resource/timing/mirroring qualification |
| REQMAP-FR-PET-003 | FR-PET-003 | Implemented | Preserve | PB-002 deterministic state-selection qualification |
| REQMAP-FR-PET-004 | FR-PET-004 | Partial | Preserve | Qualify gravity/bounds/drag; RED-test missing release/throw completion in P4.5 |
| REQMAP-FR-PET-005 | FR-PET-005 | Implemented | Preserve | PB-003/PB-004; add keyboard-equivalent access later without weakening current paths |
| REQMAP-FR-PET-006 | FR-PET-006 | Asset placeholder | Preserve | Qualify mechanics/optional behavior; keep placeholder disclosed until approved assets exist |
| REQMAP-FR-PET-007 | FR-PET-007 | Partial | Preserve | Qualify detector foundation; RED-test visible subscriptions/poses in P4.5 |
| REQMAP-FR-PET-008 | FR-PET-008 | Partial | Preserve | Qualify trajectory; RED-test missing renderer in P4.5 |
| REQMAP-FR-PET-009 | FR-PET-009 | Implemented | Preserve | PB-002/PB-004 deterministic effects/music/time qualification |
| REQMAP-FR-PET-010 | FR-PET-010 | Partial | Preserve | Qualify detector/TTS mute; RED-test pet hide/reposition in P4.5 |
| REQMAP-FR-PET-011 | FR-PET-011 | Implemented | Preserve | PB-008/PB-009/PB-014 restart and compatibility evidence |
| REQMAP-FR-PET-012 | FR-PET-012 | Implemented | Preserve | PB-002/PB-009 literal stats and visible popup evidence |
| REQMAP-FR-PET-013 | FR-PET-013 | Implemented | Preserve | Qualify all eight current tabs and saved non-secret settings |
| REQMAP-FR-PET-014 | FR-PET-014 | External dependency | Preserve | PB-010 disabled/missing/fake-boundary cases; live dependency only when that boundary changes |

### 4.2 Conversation, voice, vision, and memory

| Map ID | Current ID | Current status | Disposition / approval | Gate 0 treatment and later target |
|---|---|---|---|---|
| REQMAP-FR-AI-001 | FR-AI-001 | Implemented | Preserve | PB-005 qualification; later unified conversation keeps parity |
| REQMAP-FR-AI-002 | FR-AI-002 | External dependency | Preserve | Qualify adapter mapping/failure with fixtures; no live credential in ordinary CI |
| REQMAP-FR-AI-003 | FR-AI-003 | Implemented | Preserve | PB-005/PB-011 deterministic offline conversation |
| REQMAP-FR-AI-004 | FR-AI-004 | Implemented | Preserve | Qualify identity/stats/time inclusion and unrelated-config exclusion; later type/minimize context |
| REQMAP-FR-AI-005 | FR-AI-005 | Partial | Preserve | Qualify default lifecycle; RED-test ports/readiness/package completion in P2 |
| REQMAP-FR-AI-006 | FR-AI-006 | Partial | Proposed Change `APP-002` (pending; effective Preserve) | Inventory all 11 registrations; replace exact broad-tool promise with scoped capabilities only after approval |
| REQMAP-FR-AI-007 | FR-AI-007 | Partial | Preserve | Qualify local parser behavior; RED-test selected-source live retrieval in P9.2 |
| REQMAP-FR-AI-008 | FR-AI-008 | Partial | Preserve | Qualify current definitions only; RED-test policy-gated lifecycle/E2E in P10 |
| REQMAP-FR-VOICE-001 | FR-VOICE-001 | Implemented | Preserve | PB-006 synthetic-audio queue/cancel/mute qualification |
| REQMAP-FR-VOICE-002 | FR-VOICE-002 | External dependency | Preserve | Qualify five adapter selections and failure behavior with fixtures |
| REQMAP-FR-VOICE-003 | FR-VOICE-003 | Partial | Preserve | Qualify working direct/text fallback; RED-test repaired staged backend contract in P9.1 |
| REQMAP-FR-VISION-001 | FR-VISION-001 | Implemented | Preserve | PB-007 opt-in/indicator qualification; explicit snapshots are additive in P6 |
| REQMAP-FR-VISION-002 | FR-VISION-002 | External dependency | Preserve | Qualify routing/failure with fixtures; normalize aliases without changing four-mode promise |
| REQMAP-FR-VISION-003 | FR-VISION-003 | Implemented | Preserve | PB-007/PB-016 current privacy/cost pipeline qualification |
| REQMAP-FR-VISION-004 | FR-VISION-004 | Partial | Preserve | Record stored-but-unconsumed gap; RED-test each option before wiring in P6 |
| REQMAP-FR-MEM-001 | FR-MEM-001 | Partial | Proposed Change `APP-003` (pending; effective Preserve) | Inventory/recover JSON; replace three-source JSON promise with canonical records only after approval |
| REQMAP-FR-MEM-002 | FR-MEM-002 | Partial | Proposed Change `APP-004` (pending; effective Preserve) | Qualify non-destructive retry; change periodic distillation to proposals only after approval |
| REQMAP-FR-MEM-003 | FR-MEM-003 | Partial | Proposed Change `APP-005` (pending; effective Preserve) | Inventory Python JSON/Chroma; change authoritative persistence to host proposals only after approval |
| REQMAP-FR-MEM-004 | FR-MEM-004 | Partial | Preserve | Qualify existing builder; RED-test direct-provider and revisioned retrieval completion in P7 |
| REQMAP-FR-MEM-005 | FR-MEM-005 | Partial | Proposed Change `APP-006` (pending; effective Preserve) | Qualify USER BLOCK persistence; replace startup snapshot model only after approval |
| REQMAP-FR-MEM-006 | FR-MEM-006 | Planned | Preserve | No Gate 0 pass claim; RED-test inspect/correct/forget in P7.4 |
| REQMAP-FR-MEM-007 | FR-MEM-007 | Planned | Preserve | No Gate 0 pass claim; RED-test evidence-based learning in P7 |

### 4.3 Future, privacy, and non-functional requirements

| Map ID | Current ID | Current status | Disposition / approval | Gate 0 treatment and later target |
|---|---|---|---|---|
| REQMAP-FR-FUT-001 | FR-FUT-001 | Planned | Proposed Defer `APP-007` (pending; effective Preserve) | No baseline behavior; do not omit from backlog or implement/defer without approval |
| REQMAP-FR-FUT-002 | FR-FUT-002 | Asset placeholder | Proposed Defer `APP-008` (pending; effective Preserve) | Qualify fallback disclosure/mechanics; final-art schedule requires approval |
| REQMAP-FR-FUT-003 | FR-FUT-003 | Planned | Proposed Defer `APP-009` (pending; effective Preserve) | No baseline behavior; do not omit from backlog or implement/defer without approval |
| REQMAP-PR-001 | PR-001 | Implemented | Preserve | Prove screen/activity adapters are never called before explicit opt-in |
| REQMAP-PR-002 | PR-002 | Implemented | Preserve | Prove visible active indicator and immediate stop path |
| REQMAP-PR-003 | PR-003 | Implemented | Preserve | Prove normal capture/analysis creates no durable raw screenshot; later protected snapshots need TTL/design approval |
| REQMAP-PR-004 | PR-004 | Partial | Preserve | Qualify documentation disclosure; RED-test UI disclosure and DPAPI migration/rollback in P1 |
| REQMAP-PR-005 | PR-005 | Planned | Preserve | No Gate 0 pass claim; RED-test memory review/delete in P7.4 |
| REQMAP-PR-006 | PR-006 | Planned | Preserve | Record current unauthenticated exposure; RED-test rejection/auth in P2 |
| REQMAP-NFR-001 | NFR-001 | Unverified target | Preserve | Freeze and record idle-CPU method/result; do not claim target without evidence |
| REQMAP-NFR-002 | NFR-002 | Unverified target | Preserve | Freeze and record active-animation CPU method/result |
| REQMAP-NFR-003 | NFR-003 | Unverified target | Preserve | Freeze and record base/combined working set |
| REQMAP-NFR-004 | NFR-004 | Unverified target | Preserve | Freeze and record cold/warm interactive startup |
| REQMAP-NFR-005 | NFR-005 | Unverified target | Preserve | Freeze and record scripted drag/mixed-DPI frame timing |
| REQMAP-NFR-006 | NFR-006 | Unverified target | Preserve | Measure framework-dependent WPF payload; report added distributions separately later |
| REQMAP-NFR-007 | NFR-007 | Implemented; measurement pending | Preserve | Independently verify GIF metadata/timer behavior |
| REQMAP-NFR-008 | NFR-008 | Partial verification | Preserve | Run deterministic offline dependency fault matrix |
| REQMAP-NFR-009 | NFR-009 | Unverified target | Preserve | Record interactive Z-order/desktop/fullscreen matrix |

### 4.4 Pending exception approvals

| Approval | Proposed exception | User impact/replacement | Compatibility and rollback | Target |
|---|---|---|---|---|
| APP-001 | Change AR-003 from reverse WPF HTTP API to host broker | Direct legacy callers stop; equivalent pet actions flow through authenticated typed capabilities | Compatibility adapter during protocol cutover; feature-flag rollback before legacy route removal | Phase 2 |
| APP-002 | Change FR-AI-006 exact 11-tool promise to scoped capability outcomes | Unsafe/broken tools may be unavailable until individually approved | Inventory and mapping report; retain disabled compatibility descriptors, not broad execution | Phases 3/10 |
| APP-003 | Change FR-MEM-001 JSON-tier promise to canonical records | Storage format changes; user data remains importable/inspectable | Backup, reconciliation, reversible authority flag | Phase 7 |
| APP-004 | Change FR-MEM-002 periodic distillation to host-reviewed proposals | Fewer silent automatic updates; more inspectable state | Legacy observation import and opt-in compatibility rule | Phase 7 |
| APP-005 | Change FR-MEM-003 Python-authoritative JSON/Chroma storage | Python index becomes derived; no user fact is discarded | Full backup/rebuild and rollback before retiring writes | Phase 7 |
| APP-006 | Change FR-MEM-005 startup USER BLOCK model | USER BLOCK becomes canonical, revisioned, and immediately refreshable | Import and export-compatible view; authority rollback before cutover | Phase 7 |
| APP-007 | Defer FR-FUT-001 mini-games | Trusted-assistant work ships first; backlog remains visible | No current behavior removed | Post-release |
| APP-008 | Defer final FR-FUT-002 art expansion | Existing fallbacks remain clearly disclosed | Mechanics/assets untouched; later asset-only release | Post-release |
| APP-009 | Defer FR-FUT-003 extra sound effects | Voice/audio stability ships first | No current sound behavior removed | Post-release |

- [ ] Obtain explicit item-level user approval or rejection for APP-001 through APP-009 and link the
  evidence. A pending entry remains Preserve and blocks its affected cutover/defer decision.

### 4.5 Unnumbered normative locator map

| Locator | Source | Disposition | Coverage |
|---|---|---|---|
| REQMAP-CURRENT-INTENT | `REQUIREMENTS.md` §2 product intent/user stories/journey | Preserve | PB inventory plus Gates B–E |
| REQMAP-CURRENT-SCOPE | §2 scope boundary | Preserve | Existing WPF/local/sidecar/adapters remain accounted for; future scope is additive |
| REQMAP-CURRENT-STORAGE | §5.1 complete storage table | Preserve compatibility | PB-008/009/014/016 plus P1/P7 migration and rollback |
| REQMAP-CURRENT-PORTS | §5.2 loopback port table | Preserve until approved replacement | PB-011/012/015; P2 contract and APP-001 |
| REQMAP-CURRENT-TRANSMISSION | §5.3 provider/transmission table | Preserve | Route disclosure, fixture contracts, PRD FR-002/018/019 |
| REQMAP-CURRENT-PRIVACY | §5.4 complete privacy table | Preserve except pending approved requirement changes | PR-001 through PR-006 rows above |
| REQMAP-CURRENT-ASSETS | §6 complete asset table | Preserve current mechanics/disclosure | PB-002/004/018 and APP-008 |
| REQMAP-CURRENT-RUNTIME | §8 complete runtime/dependency table | Preserve | Clean install/import/package lanes and manifest authority |
| REQMAP-CURRENT-VERIFY | §9 complete command/manual list | Preserve as legacy evidence and extend | V-LEGACY plus new independent lanes |
| REQMAP-CURRENT-GAPS | §10 items 1–10 | Preserve as open commitments | P2, P4.5, P7, P9.1/2, P10 and packaging steps |
| REQMAP-CURRENT-STATUS | §1 status model and completion rule | Preserve | Documentation-truth probes prevent class/interface-only completion claims |

- [ ] Add an executable coverage check that extracts current IDs and fails if this map has a missing,
  duplicate, unknown, unauthorized disposition, or uncovered unnumbered locator.
- [ ] Version the map whenever `REQUIREMENTS.md` changes; record old/new hashes, approval, affected
  tests, and gates that must rerun.

## 5. Independent test topology

| Lane | New authoritative location | Boundary and rule |
|---|---|---|
| Shared fixtures | `tests/Aemeath.Testing/`, `tests/fixtures/`, `contracts/fixtures/` | New code only; no legacy test reference |
| .NET unit | `tests/Aemeath.Preservation.UnitTests/` | Pure deterministic behavior; no WPF desktop/profile/network |
| .NET integration | `tests/Aemeath.Preservation.IntegrationTests/` | Real composition/persistence with isolated roots and fake external boundaries |
| WPF state/accessibility | `tests/Aemeath.Preservation.WpfTests/` | STA dispatcher and real production XAML; no alternate UI |
| Fixture host | `tests/Aemeath.TestHost/` | Non-shipping production-composition process with nonce-protected fixture control |
| Process/UIA E2E | `tests/Aemeath.UiAutomation.Tests/` | Real product/TestHost process, unique profile/ports, readiness, strict cleanup |
| Real Windows boundary | `tests/Aemeath.RealBoundary.Tests/` | Resettable declared-capability workers only |
| Packaging | `tests/Aemeath.Packaging.Tests/` | Produced package/clean profile/install/rollback, never developer output |
| Architecture | `tests/Aemeath.ArchitectureTests/` | Dependency/authority rules plus known-bad detection fixture |
| Protocol | `tests/Aemeath.Protocol.Tests/` | C#/Python shared fixtures, auth/version/sequence/limits |
| Python preservation | `python-backend/preservation_tests/` | Independent unit/contract/integration/fixture and real-boundary E2E |
| Legacy regression | Existing .NET/Python test locations | Separate job/result; never preservation evidence |

Required deterministic seams include `TimeProvider`/clock, seeded random, manually advanced
scheduler/timers, isolated data root, atomic file fault injection, Windows environment/DPI/work area,
screen capture, process/HTTP transport, audio fixtures, registry startup store, UI dispatcher/app
readiness, provider/index fakes, dynamic reserved ports, fixed culture, and external-I/O-disabled
fixture mode. Hosted CI never depends on a live cloud model, downloaded embedding model, microphone,
speaker, real desktop pixels, user registry, or user profile.

### 5.1 E2E candidate and ROI budget

Exhaustive permutations belong in unit/reducer/component/WPF lanes. A phase normally adds at most
three fixture E2Es and two service/real-boundary E2Es; an exception must name the unique boundary
failure that no smaller test observes.

| Phase | Candidate complete journeys | Selected budget and rationale |
|---|---|---|
| Gate 0A | offline launch/open/quit; interact/restart; chat/error/restart; every UI state | 3 fixture + 2 real-boundary; covers lifecycle, persistence, offline/error and Windows shell while state permutations stay below E2E |
| Protocol | healthy run; wrong-auth/version; disconnect/reconnect; every event variant | 2 cross-runtime fixture E2E; auth/readiness and reconnect cross the process boundary, variants stay contract-level |
| Tasks/approval | approve/restart/execute; reject; edit; every transition | 2 fixture E2E; happy/restart and unknown-commit/undo, transitions stay reducer/component-level |
| Command Center | navigate shell; approval; diagnostics; each empty/error page | 3 UIA fixture E2E; shell, approval, diagnostics are distinct focus/state boundaries |
| Brief/context/memory | daily brief; context answer; memory correction/delete | 3 fixture + up to 2 real-source E2E per release gate; one complete user outcome per trusted loop |
| Scratch-note action | approve/execute/undo; crash/reconcile; every fault point | 2 fixture + 1 real-boundary; normal reversible loop and uncertainty recovery |
| Voice/RAG/proactivity | voice request; selected-file answer; focus suppression | 3 fixture + up to 2 real-boundary; physical audio and actual file/package boundaries only |
| MCP | consent/read; schema change/revoke; every server error | 2 real-boundary E2E; consented read and revocation/schema lifecycle |
| Release | install/first run; upgrade/migrate; rollback/uninstall | 3 real package E2E per supported distribution; each changes installed-state boundary |

## 6. Delivery Preflight — Make later gates enforceable

Delivery Preflight changes no product behavior and is not an implementation phase. It resolves the
CI/evidence chicken-and-egg problem before Gate 0 starts. The planning commit may use the repository's
current advisory PR checks as diagnostic evidence only; those checks cannot satisfy a later gate.

### D0.1 Publish the reviewed plan and open the draft PR

- [x] Review this document set, commit only intended documentation, push the branch, and open a draft
  PR so current CI behavior is observable.
- [x] Record current workflow trigger/checkout/job/artifact behavior and exact head/merge SHAs without
  claiming the old workflow is an exact-SHA gate.
- [x] Required lanes: documentation links/IDs/truth, current CI diagnostic.
- [x] Commit, push, and record the diagnostic run. D0.2 supplies the first enforceable exact-SHA gate.

### D0.2 Bootstrap exact-head-SHA CI test-first

- [ ] Freeze a workflow risk manifest, then write a failing executable probe for branch/head checkout,
  missing job, zero discovery, reduced matrix, advisory failure, absent artifact, merge-SHA
  substitution, and timeout/cancellation.
- [ ] Add `workflow_dispatch` and PR/implementation-branch triggers; explicitly checkout the pushed
  head SHA; expose source SHA in every result; make required bootstrap build/static/meta jobs blocking;
  and upload evidence with `if: always()`.
- [ ] Add `tools/ci/Wait-ForCi.ps1` and a manifest validator that refuse missing/skipped/neutral/
  cancelled/merge-only/mismatched results.
- [ ] The bootstrap workflow must verify its own head SHA and probes before D0.3 starts.
- [ ] Commit, push, and obtain exact-head-SHA CI success.

### D0.3 Establish qualified traceability and manifest schemas

- [ ] Write failing coverage probes, then create `docs/verification/traceability-v1.yml`, risk/lane,
  RED/GREEN/VERIFY, and exact-SHA manifest schemas.
- [ ] Map every `CURRENT:*` requirement/locator and every `PRD:AC-FR-*`, `PRD:NFR-JA-*`,
  `PRD:GATE-*`, and `PRD:RISK-*` ID to design/UI sections, checklist steps, future test/probe IDs,
  lanes, and evidence paths. No ambiguous bare `NFR-*` reference is allowed.
- [ ] Validate missing, duplicate, stale source hash, invalid disposition, orphan test, and orphan
  acceptance-criterion known-bad fixtures.
- [ ] Commit, push, and obtain exact-head-SHA CI success.

### D0.4 Provision and prove required delivery environments

- [ ] Freeze owners and readiness evidence for GitHub-hosted jobs, resettable interactive Windows
  10/11 workers, runner labels/capabilities, artifact archive, signing access, branch-protection
  permissions, pilot hardware/participants, and provider terms/credentials.
- [ ] Write a failing capability probe before registering/configuring each absent runner or archive;
  probe OS build, interactive session, UIA, DPI/display, assistive technology, cleanup/reset, storage,
  network policy, and timeout behavior without collecting personal data.
- [ ] Configure required checks/branch protection where authorized. An unavailable required external
  prerequisite blocks the first step that needs it; it cannot be relabeled optional after failure.
- [ ] Commit the redacted capability manifest, push, and obtain exact-head-SHA CI success.

### D0.5 Freeze clean-install dependency evidence without changing production manifests

- [ ] Record .NET/Python/tool versions and ordinary restore/install/import results on the unchanged
  source. Do not use `--locked-mode` until lock files are deliberately added post-Gate-0A.
- [ ] For unchanged-source Python qualification only, install
  `langgraph-checkpoint-sqlite==3.1.0` after `pip install -e ".[dev]"`, capture the complete resolved
  environment and wheel hash in the manifest, and keep the product manifests untouched. Record the
  missing declaration as a Gate 0B repair, not a valid behavioral RED or silent product fix.
- [ ] Commit evidence only, push, and obtain exact-head-SHA CI success.

## 7. Gate 0A — Independently qualify the unchanged production baseline

Gate 0A is the first implementation evidence phase and is blocking. Its test specifications,
fixtures, helpers, and expected values are new. It changes test/evidence code only; the frozen
production source hash must remain unchanged through P0A.9. Prior legacy-test exposure is disclosed;
legacy results first become a gate input in P0A.9 and never become independent oracles.

### P0A.1 Freeze preservation specification and risk map

- [ ] Inventory retained components, public behaviors, persisted data, integration boundaries, and
  Windows journeys as PB-001 through PB-018.
- [ ] Freeze literal/stat/geometry/time oracles, resource manifest and hashes, JSON/protocol fixtures,
  supported environments, lane assignment, exposure declarations, and reviewer provenance.
- [ ] Write a failing completeness probe for missing PBs, requirement-map entries, lane decisions,
  or fixture hashes; make only the manifest/tooling change needed to pass.
- [ ] Required lanes: static/meta-test and documentation truth.
- [ ] Commit, push, and obtain exact-SHA CI success.

### P0A.2 Prove black-box offline launch on disposable Windows workers

- [ ] Author a process probe that launches the unchanged Release application with no provider,
  network, or sidecar and observes a usable pet, Chat, Settings, and bounded clean exit.
- [ ] Author a black-box restart journey for config/position/stats/history using a resettable,
  disposable Windows user/VM; do not add a production data-root seam.
- [ ] Author one real-boundary Windows journey for transparent/topmost pet visibility and one for
  keyboard opening/closing of a companion surface.
- [ ] If safe isolation is impossible, the environment is not ready and D0.4 reopens; never run a
  destructive probe against a real user profile and never count setup failure as behavioral RED.
- [ ] Required lanes: process smoke, fixture E2E, real-boundary E2E, privacy/safety.
- [ ] Commit, push, and obtain exact-SHA CI success.

### P0A.3 Build a test-only, failure-detecting preservation harness

- [ ] Write safety tests that fail on developer/user-profile access, unapproved live services,
  residue outside the disposable worker, or orphan processes. Record fixed ports, wall-clock waits,
  and uncontrolled randomness as baseline limitations rather than impossible Gate 0A failures.
- [ ] Use external environment control, public production contracts, a disposable OS user, local
  protocol-faithful services bound to the current fixed ports, synthetic media, serialized workers,
  bounded waits, and process observation. Do not edit production code.
- [ ] Create a test-only launcher/TestHost only where existing public production composition permits
  it without a production seam; otherwise use the real executable. Never duplicate product XAML.
- [ ] Add known-bad fixture implementations and `tools/verify-preservation-detection.ps1`; the outer
  probe passes only when the nested preservation test fails at its expected oracle.
- [ ] Required lanes: unit, integration, architecture, process E2E, security, reliability.
- [ ] Commit, push, and obtain exact-SHA CI success.

### P0A.4 Qualify retained domain and engine behavior

- [ ] PB-002: sprite decode, manifest, frame timing, loop/one-shot, state mapping, mirroring,
  gravity, bounds, drag, and current release semantics.
- [ ] PB-003: click/drag/tray/click-through/position behavior using literal geometry and safe recovery.
- [ ] PB-004: bubble/effects/plane/cat lifecycle and optional cat reactions using relational
  invariants, bounded eventual outcomes, seeded inputs only where the public API already accepts
  them, and repeated statistical bounds where time/random are static.
- [ ] PB-009: literal interaction deltas, offline decay, floors, counters, and 0..100 clamps.
- [ ] PB-010: missing music/Pomodoro/activity/companion dependencies are non-fatal and stop cleanly.
- [ ] Run each safe case alone, in randomized test order, and ten repetitions without residue. Do
  not assert an exact random choice or wall-clock instant on the unchanged baseline.
- [ ] Run bounded mutation checks for PB-002, PB-003, and PB-009; critical surviving mutants block
  completion.
- [ ] Required lanes: unit, component integration, resource/package, performance/reliability.
- [ ] Commit, push, and obtain exact-SHA CI success.

### P0A.5 Qualify retained local data and application composition

- [ ] PB-001/PB-011: offline composition, single lifecycle, readiness, bounded shutdown, and
  optional-sidecar degradation.
- [ ] PB-005: trimmed text, ordered stream chunks, completed-turn persistence, stat update, visible
  provider error, and no duplicated partial turn.
- [ ] PB-006: optional voice status/provider mapping/text fallback with fixed audio fixtures.
- [ ] PB-007: capture never called while off/protected; visible status and stop path when enabled.
- [ ] PB-008/PB-009/PB-014: valid/corrupt config, stats/history limits, every legacy memory source, backup,
  reject-with-reason, interrupted write, and no silent loss.
- [ ] PB-010: companion launch opt-in/path/failure isolation.
- [ ] PB-012/PB-013: fixed local cross-runtime/provider/document fixtures qualify compatible outcomes
  without freezing unsafe transport or broad-tool defects.
- [ ] Python qualification uses D0.5's pinned, captured environment-only checkpoint dependency; the
  product manifest remains unchanged until the P0B.1 dependency RED/correction.
- [ ] PB-015: current MCP definitions inventory/migration behavior without executing raw servers.
- [ ] PB-016: use characterization probes to record plaintext storage, disclosure/redaction behavior,
  and unauthenticated loopback exposure without approving or freezing those defects.
- [ ] Required lanes: unit, .NET/Python integration, migration, security/privacy, fault injection.
- [ ] Commit, push, and obtain exact-SHA CI success.

### P0A.6 Qualify retained WPF UI and current accessibility state

- [ ] Observe or instantiate Pet, Speech Bubble, Cat, Stats, Chat, and all eight Settings tabs on a
  pumped STA/disposable graphical worker using real production XAML and baseline dependencies;
  serialized execution and bounded waits replace unavailable deterministic seams.
- [ ] Verify semantic default/loading/ready/streaming/error/degraded/privacy states, window policies,
  minimum sizes, long strings, and 100/150/200% application text scale.
- [ ] Record the current UI Automation tree, names/roles/patterns, keyboard reachability, focus,
  password exposure, contrast, high-contrast, scale, and motion behavior. Use stable external
  locators available on the baseline; do not add AutomationIds, peers, commands, or theme tokens.
- [ ] Do not freeze defects: bound placeholder text, emoji-only actions, mouse-only microphone,
  plaintext secret exposure, exact random particles/GIF frame, or raw MCP command editing.
- [ ] Required lanes: WPF UI, accessibility contract, layout, security, deterministic visual render.
- [ ] Commit, push, and obtain exact-SHA CI success.

### P0A.7 Qualify process UI Automation and fixture journeys

- [ ] Launch the real baseline executable, observe a UIA-visible pet, open Chat, enter text through a
  supported baseline pattern/keyboard path, receive offline output, open Settings, save a non-secret
  preference, restart, verify persistence, and quit.
- [ ] Exercise drag/click/stat persistence and sidecar-unavailable degradation through supported
  process controls without raw-coordinate or desktop-pixel oracles.
- [ ] Run each journey three times in resettable disposable profiles, serialized around the current
  fixed ports, with an external process group/job object, bounded wait, and unconditional cleanup.
  Dynamic ports and a nonce control channel are Gate 0B changes, not Gate 0A assumptions.
- [ ] Always upload screenshot, UIA tree, sanitized journal, process list, and dump/log on failure.
- [ ] Required lanes: Windows UIA and fixture E2E on `windows-latest`.
- [ ] Commit, push, and obtain exact-SHA CI success.

### P0A.8 Qualify real Windows boundaries and nonfunctional baseline

- [ ] On a supported interactive/self-hosted Windows 10 and Windows 11 x64 matrix, exercise Narrator,
  Accessibility Insights, true high contrast, reduced motion, 100/150/200% DPI/text scale,
  mixed-DPI multi-monitor, tray, click-through recovery, drag/topmost/taskbar/Alt+Tab, fullscreen,
  global hotkey, notification, audio routing, startup integration, framework-dependent publish,
  extract/first-run/exit, published-directory removal, and disposable-profile data reset.
- [ ] Record OS build, runner/image, display, assistive technology, hardware, tool versions, exact SHA,
  raw observations, exclusions, and artifacts. Mock results cannot substitute for this evidence.
- [ ] Measure startup, idle/active CPU, memory, drag frame timing, GIF timing, Z-order behavior, and
  published payload with the frozen method and sample count.
- [ ] Seed canary data only in disposable profiles and record current leak/redaction behavior. A
  detected current defect maps to a post-Gate-0A RED correction and is never accepted as secure.
- [ ] Required lanes: real-boundary E2E, accessibility, security/privacy, performance/reliability,
  current-publish/clean-machine. Installer upgrade/uninstall is reserved for the selected package.
- [ ] Commit, push, and obtain exact-SHA CI success from the required hosted and self-hosted workflows.

### P0A.9 Lock the unchanged-baseline independent evidence

- [ ] Run all independent lanes and detection probes against the unchanged production hash, including
  clean checkout/install observations and the supported Windows matrix; do not run legacy results as
  an oracle or combined metric.
- [ ] Prove all 18 PBs and every implemented or partial retained observable/invariant have evidence;
  zero critical mutant or known-bad fixture survives. Every unimplemented portion of a Partial item
  and every Planned promise is traced to a later RED step and is not counted as baseline evidence.
- [ ] Publish the signed/frozen Gate 0A report, fixture/oracle hashes, exposure review, and exact-SHA
  manifest; obtain independent test, security/privacy, accessibility, and documentation reviews.
- [ ] Commit, push, and obtain exact-SHA CI success for every independent Gate 0A evidence job. This
  locks the unchanged baseline but does not unlock production changes beyond Gate 0B corrections.

## 8. Gate 0B — Add testability and repair all blocking baseline gaps

Every P0B production change is protected by the complete frozen Gate 0A suite. Changed outcomes use
valid RED tests; pure seams/refactors start with a mutation-sensitive GREEN characterization. Gate
0B is corrective work inside the still-open Gate 0, not permission to start Phase 0 or Phase 1.

### P0B.1 Admit and repair legacy, dependency, format, and Ruff results

- [ ] Record all prior legacy-test exposure, then run existing .NET/Python suites and build/format/
  Ruff/import checks with manifest-declared nonzero discovery. This is the RED/input stage of the
  still-open Gate 0, not a completed red step.
- [ ] Record results separately; never copy an expectation into PB tests or combine coverage/counts.
- [ ] In P0B.1a onward, use independent requirements/oracles to correct product defects or
  demonstrably invalid legacy expectations; add the missing declared Python dependency, deterministic
  lock/import smoke and NuGet locks if locked restore will be enforced.
- [ ] Require zero failures, zero unexpected skips, zero format/Ruff violations, nonzero discovery,
  and no advisory/baseline waiver before P0B.2 starts. Each child has test/probe first, commit, push,
  exact-SHA CI, and keeps Gate 0A green.

### P0B.2 Add deterministic boundary seams in focused child steps

- [ ] Decompose clock/random/scheduler, data root/atomic file, Windows/DPI/screen, process/network,
  audio/registry, provider/index, UI dispatcher/readiness, and shutdown/TestHost seams into
  `P0B.2a` onward.
- [ ] Each child changes one boundary family, has its own manifest/TDD cycle/commit/push/exact-SHA
  gate, and keeps Gate 0A plus all legacy/static lanes green.

### P0B.3 Add accessibility and automation semantics in focused child steps

- [ ] Write RED tests for unique AutomationIds, names, labels, required patterns, password protection,
  keyboard equivalents, live regions, focus restoration, semantic contrast, high contrast, scale,
  and reduced motion; split surface/theme concerns into `P0B.3a` onward.
- [ ] Each child has one focused commit/push/exact-SHA gate and reruns affected UIA plus Gate 0A.

### P0B.4 Correct preservation-discovered product and security defects

- [ ] For every approved correction from P0A, create a child ID and valid independent RED test before
  changing behavior. Do not use this step to perform a pending APP-001–APP-009 cutover.
- [ ] Include offline response, UI/profile coupling, secret/log redaction, shutdown/orphan, and
  environment-specific defects actually found by evidence.

### P0B.5 Lock final Gate 0

- [ ] Run all independent, failure-detection, legacy, build, format, Ruff, dependency, security,
  accessibility, performance, real-Windows, and packaging manifests at the same final head SHA.
- [ ] Zero required failure/skip/advisory/missing artifact remains; every approved baseline defect has
  a disposition and later step or completed fix.
- [ ] Obtain independent code/test/security/accessibility/documentation review.
- [ ] Commit the final evidence, push, and obtain exact-head-SHA CI success. Only then unlock Phase 0
  risk proofs and architectural work.

## 9. Phase 0 — Required architecture and product risk proofs

These checklist gates preserve the source plan's Phase 0. A proof may be throwaway test/prototype
code, but its specification/probe is written first and its evidence is committed and CI-verified.

### H0.1 Validate selected sources, action, routes, retention, and hardware tiers

- [ ] Freeze evaluation criteria and prove that local reminders plus ICS, explicitly selected local
  files/directories, and the versioned scratch note satisfy identity, privacy, reversibility,
  testability, licensing, migration, and support constraints.
- [ ] Record Local/Hybrid/Cloud defaults, raw/context/audio/transcript/receipt retention defaults,
  supported Windows builds, and representative low/mid/high hardware tiers with owner approval.
- [ ] Commit, push, exact-SHA CI green.

### H0.2 Host-composition proof

- [ ] Characterization-first prototype starts the preserved pet through Generic Host/DI for one
  service, proves tray exit/companion failure/shutdown, and records keep/reject criteria.
- [ ] Commit, push, exact-SHA CI green.

### H0.3 Protocol/readiness proof

- [ ] RED fixture probes for auth, version mismatch, wrong token, readiness failure, configured port,
  reconnect/dedup, and child shutdown; prove the proposed contract before full implementation.
- [ ] Commit, push, exact-SHA CI green.

### H0.4 Durable approval/reconciliation proof

- [ ] RED state/restart/fault tests for WaitingApproval, proposal hash, approve/reject, timeout around
  commit, reconcile, receipt, and undo using a fake reversible capability.
- [ ] Commit, push, exact-SHA CI green.

### H0.5 Sidecar distribution bake-off and selection

- [ ] Freeze metrics and probes, then compare packaged executable, embedded environment, and separate
  installation on clean Windows workers; record the selected ADR or kill criterion.
- [ ] Commit, push, exact-SHA CI green.

### H0.6 Approval/privacy wireframe study

- [ ] Freeze comprehension tasks and accessibility conditions; test static proposal/data-route/
  reversibility/scope wireframes and record results before Command Center work.
- [ ] Commit, push, exact-SHA CI green.

## 10. Phase 1 — Foundation without visible regression

### P1.1 Create target projects and enforce dependency direction

- [ ] RED architecture tests for allowed references and intentionally forbidden fixture assemblies.
- [ ] Add the design-selected `Aemeath.Core`, `Aemeath.Windows`, `Aemeath.Infrastructure`, and
  `Aemeath.Protocol` projects incrementally; keep the current app runnable.
- [ ] Required lanes: architecture, unit, build, preservation, legacy regression.
- [ ] Commit, push, exact-SHA CI green.

### P1.2 Adopt Generic Host and owned lifecycle

- [ ] GREEN characterization for current launch; RED tests for one host, deterministic readiness,
  child/timer disposal, and bounded shutdown under failure.
- [ ] Replace concrete startup construction with DI/hosted services behind a rollback flag.
- [ ] Required lanes: unit, integration, WPF UI, fixture E2E, reliability, preservation.
- [ ] Commit, push, exact-SHA CI green.

### P1.3 Add schema-managed SQLite and migration journal

- [ ] RED migration tests for empty, current, interrupted, corrupt, future-version, backup/restore,
  idempotent rerun, and locked-database cases.
- [ ] Add schema history and repositories; no dual authoritative writers.
- [ ] Required lanes: unit, integration, migration, security, performance, preservation.
- [ ] Commit, push, exact-SHA CI green.

### P1.4 Protect secrets and migrate configuration

- [ ] RED tests/probes for plaintext leakage, DPAPI round trip, wrong-user/machine failure, interrupted
  migration, original backup, redacted logs/export/UIA, and secret deletion.
- [ ] Store secret references in configuration and migrate atomically with rollback.
- [ ] Required lanes: unit, integration, migration, security/privacy, UI, clean-machine packaging.
- [ ] Commit, push, exact-SHA CI green.

### P1.5 Expand the already-blocking CI matrix for foundation lanes

- [ ] Extend D0.2's exact-SHA workflow with new architecture, migration, security, clean-install, and
  Windows cross-runtime jobs; first add a probe that fails when any new matrix entry is absent.
- [ ] Preserve blocking format/Ruff, always-upload evidence, dispatch/head-SHA behavior, manifest
  validation, and required branch protection established in Delivery Preflight.
- [ ] Required lanes: workflow self-tests, clean installs, all Gate 0 lanes.
- [ ] Commit, push, exact-SHA CI green.

## 11. Phase 2 — Authenticated, versioned sidecar protocol

### P2.1 Define and generate the protocol

- [ ] RED cross-language contract cases for handshake, liveness/readiness, request/run IDs, event
  sequence, terminal states, error envelopes, size limits, cancellation, and version mismatch.
- [ ] Generate C# and Python models from one source and prevent hand-written drift.
- [ ] Required lanes: unit, contract, schema diff, architecture, security.
- [ ] Commit, push, exact-SHA CI green.

### P2.2 Supervise authenticated sidecar startup

- [ ] RED process tests for per-launch token, loopback binding, configured/dynamic port, readiness
  subsystem failures, wrong token, collision, retry/backoff, crash, and process-tree shutdown.
- [ ] Implement the supervisor; liveness never implies readiness.
- [ ] Required lanes: integration, cross-runtime fixture E2E on Windows, security, reliability, packaging.
- [ ] Commit, push, exact-SHA CI green.

### P2.3 Implement resumable run lifecycle

- [ ] RED cases for accepted/progress/chunk/proposal/terminal events, disconnect/reconnect,
  deduplication, cancellation race, stale sequence, and bounded replay.
- [ ] Required lanes: unit, contract, integration, cross-runtime fixture E2E, fault injection.
- [ ] Commit, push, exact-SHA CI green.

### P2.4 Remove reverse-WPF and legacy transport authority

- [ ] GREEN preservation around offline behavior; RED security/architecture tests detecting any
  remaining unauthenticated or Python-initiated side effect.
- [ ] Route proposals through the host; remove dormant routes only after parity and migration proof.
- [ ] Required lanes: architecture, contract, security, cross-runtime fixture E2E, preservation, legacy regression.
- [ ] Commit, push, exact-SHA CI green.

### P2.5 Implement and qualify the Phase 0-selected sidecar distribution

- [ ] Use the H0.5 ADR; do not reopen the selection without a failed kill criterion and revised ADR.
- [ ] RED packaging probe for the selected option's absent runtime/model/dependency, upgrade, rollback,
  signature/antivirus behavior, port collision, and offline launch.
- [ ] Produce the reproducible selected package/SBOM and verify its recorded budgets.
- [ ] Required lanes: packaging, clean-machine E2E, security, performance/reliability.
- [ ] Commit, push, exact-SHA CI green.

## 12. Phase 3 — Durable tasks, capabilities, policy, approval, and receipts

### P3.1 Implement task ledger and reducer

- [ ] RED exhaustive transition/property tests, restart at every state, optimistic concurrency,
  cancellation races, invalid transitions, retention, and corrupt event handling.
- [ ] Required lanes: unit, integration, migration, reliability, performance.
- [ ] Commit, push, exact-SHA CI green.

### P3.2 Implement typed capability registry

- [ ] RED manifest/schema/risk/version/duplicate/unknown-metadata tests and forbidden broad-command
  fixtures. Unknown or incomplete risk metadata fails closed.
- [ ] Required lanes: unit, architecture, contract, security.
- [ ] Commit, push, exact-SHA CI green.

### P3.3 Implement policy, grants, and revocation

- [ ] RED decision-table/property tests for route, source, target/account, risk, expiry, scope,
  revision, revocation mid-plan, and Local mode cloud prohibition.
- [ ] Required lanes: unit, integration, security/privacy, audit.
- [ ] Commit, push, exact-SHA CI green.

### P3.4 Persist approval and resume safely

- [ ] RED tests for proposal hash, preview drift, restart while waiting, approve/reject/edit,
  expired context, stale grant, duplicate click, and never-execute-before-persist.
- [ ] Required lanes: unit, integration, WPF UI, fixture E2E, accessibility, security.
- [ ] Commit, push, exact-SHA CI green.

### P3.5 Implement execution adapters, idempotency, reconciliation, and undo

- [ ] RED adapter contract tests for preflight, execute, timeout-before/after-commit, stable external
  ID, unknown commit, retry prohibition, reconcile, compensate, and undo expiry.
- [ ] Required lanes: unit, integration, fault injection, security, reliability.
- [ ] Commit, push, exact-SHA CI green.

### P3.6 Implement receipts and privacy-safe activity history

- [ ] RED tests for append-only audit facts, redaction, seeded secrets, user-readable result,
  correlation, export, retention, and deletion boundaries.
- [ ] Required lanes: unit, integration, security/privacy, UI state, migration.
- [ ] Commit, push, exact-SHA CI green.

## 13. Phase 4 — Command Center, presentation truth, and diagnostics

### P4.1 Build the accessible Command Center shell

- [ ] RED WPF/UIA/layout tests for Today, Conversation, Tasks, Activity, Memory, Capabilities,
  Settings, and Diagnostics navigation at required sizes/scales/themes.
- [ ] Preserve narrow Chat until an approved parity/cutover gate passes.
- [ ] Required lanes: WPF UI, UIA, fixture E2E, accessibility, visual, preservation.
- [ ] Commit, push, exact-SHA CI green.

### P4.2 Build task, approval, receipt, and undo journeys

- [ ] RED reducer/UI tests and keyboard/UIA process journeys for every durable state, loading, empty,
  error, conflict, expired approval, degraded route, receipt, and undo outcome.
- [ ] Required lanes: unit, integration, UI/UIA, fixture E2E, accessibility, security.
- [ ] Commit, push, exact-SHA CI green.

### P4.3 Create one authoritative assistant presentation reducer

- [ ] RED precedence tests separating pet personality/animation from Listening, Transcribing,
  Thinking, NeedsInput, NeedsApproval, Acting, Success, Failure, and Degraded assistant state.
- [ ] Both pet and Command Center consume one versioned state; neither infers independently.
- [ ] Required lanes: unit, WPF UI, visual, accessibility, preservation.
- [ ] Commit, push, exact-SHA CI green.

### P4.4 Build diagnostics and safe support export

- [ ] RED tests for health truth, readiness reasons, dependency versions, migration status, bounded
  logs, canary redaction, offline availability, and actionable recovery.
- [ ] Required lanes: integration, UI/UIA, security/privacy, packaging, fixture E2E.
- [ ] Commit, push, exact-SHA CI green.

### P4.5 Complete retained pet gaps without regression

- [ ] Independently RED-test and implement drag release/throw, visible edge poses/subscriptions,
  plane rendering, fullscreen policy, and keyboard equivalents.
- [ ] Re-run all PB engine/UI/real-Windows evidence; do not require missing final art to claim the
  mechanics are correct, but keep placeholders disclosed.
- [ ] Required lanes: unit, integration, WPF UI/UIA, fixture and real-boundary E2E, performance.
- [ ] Commit, push, exact-SHA CI green for each independently releasable fix.

## 14. Phase 5 — Offline reminders and daily brief

### P5.1 Implement reminder domain and persistence

- [ ] RED tests for recurrence, time zones/DST, missed/duplicate firing, edit/delete, restart, clock
  rollback, invalid dates, and import idempotency.
- [ ] Required lanes: unit/property, integration, migration, reliability.
- [ ] Commit, push, exact-SHA CI green.

### P5.2 Implement scheduler and Windows notifications

- [ ] RED fake-clock tests plus real Windows notification deep-link/snooze/dismiss evidence.
- [ ] Required lanes: unit, integration, fixture E2E, real boundary, accessibility.
- [ ] Commit, push, exact-SHA CI green.

### P5.3 Implement brief sources and grounding

- [ ] Start with local reminders plus local ICS import. RED tests for source identity, stale/failure,
  time zone, duplicate events, citations, offline behavior, and no invented facts.
- [ ] Required lanes: unit, integration, fixture E2E, security/privacy.
- [ ] Commit, push, exact-SHA CI green.

### P5.4 Build Today journey and pet cue

- [ ] RED UI/UIA tests for empty/loading/ready/stale/partial/error, item source, reminder action,
  focus behavior, reduced motion, and non-interruptive cue.
- [ ] Required lanes: UI/UIA, fixture E2E, accessibility, visual, preservation.
- [ ] Commit, push, exact-SHA CI green.

## 15. Phase 6 — Explicit current-context snapshots

### P6.1 Implement protected context lifecycle

- [ ] RED tests for explicit consent, provenance, TTL, encryption/protection, deletion, expiry while
  waiting, reference counting, crash cleanup, and export exclusion.
- [ ] Required lanes: unit, integration, migration, security/privacy, reliability.
- [ ] Commit, push, exact-SHA CI green.

### P6.2 Implement Windows context adapters

- [ ] RED fixture tests and real-boundary evidence for selected text, foreground metadata, explicit
  screenshot, clipboard selection, protected/blacklisted/fullscreen windows, DPI, and failure.
- [ ] No continuous capture is enabled by this step.
- [ ] Required lanes: unit, integration, real Windows E2E, privacy, accessibility.
- [ ] Commit, push, exact-SHA CI green.

### P6.3 Implement redaction and route policy

- [ ] RED adversarial/canary tests for secrets, PII, images, Local/Hybrid/Cloud route declarations,
  no silent cloud fallback, preview, and audit facts.
- [ ] Required lanes: unit, integration, security/privacy, performance.
- [ ] Commit, push, exact-SHA CI green.

### P6.4 Build grounded conversation with citations

- [ ] RED contract/reducer/UI tests for context chips, source citations, stale/expired context,
  unsupported claims, provider error, cancellation, route label, and retry.
- [ ] Required lanes: contract, integration, UI/UIA, fixture and cross-runtime fixture E2E, accessibility.
- [ ] Commit, push, exact-SHA CI green.

## 16. Phase 7 — Canonical, inspectable memory

### P7.1 Rehearse inventory and migration

- [ ] RED fixture migrations for every C#/Python JSON, SQLite/checkpoint, Chroma, missing, duplicate,
  corrupt, huge, interrupted, and future-version input; create backup and reconciliation report.
- [ ] Required lanes: migration, integration, security/privacy, performance/reliability.
- [ ] Commit, push, exact-SHA CI green.

### P7.2 Implement canonical memory schema/service

- [ ] RED tests for typed record, provenance, confidence, sensitivity, revision, conflict, retention,
  encryption/protection, query, correction, forget, and audit.
- [ ] Host is sole authority; sidecar index is disposable derived state.
- [ ] Required lanes: unit, integration, architecture, migration, security.
- [ ] Commit, push, exact-SHA CI green.

### P7.3 Implement proposal/retrieval protocol and invalidation

- [ ] RED cross-runtime tests for validate/accept/reject, stale revision, delete propagation, index
  rebuild, delayed acknowledgment, prompt refresh, and no deleted-memory retrieval.
- [ ] Required lanes: contract, integration, cross-runtime fixture E2E, security, reliability.
- [ ] Commit, push, exact-SHA CI green.

### P7.4 Build Memory Center

- [ ] RED WPF/UIA journeys for inspect source/confidence, search/filter, correct, forget, time range,
  export, pending cleanup, undo where allowed, keyboard/Narrator, and empty/error states.
- [ ] Required lanes: UI/UIA, fixture E2E, accessibility, security/privacy, visual.
- [ ] Commit, push, exact-SHA CI green.

### P7.5 Cut over authority and retire legacy writes

- [ ] GREEN migration/preservation tests; RED architecture probes for any legacy authoritative write.
- [ ] Rebuild derived indexes, verify reconciliation counts, retain rollback backup, then remove writes.
- [ ] Required lanes: architecture, migration, integration, cross-runtime fixture E2E, packaging, preservation.
- [ ] Commit, push, exact-SHA CI green.

## 17. Phase 8 — First reviewed reversible desktop action

The first action is a versioned, product-owned scratch note. It avoids third-party UI automation while
exercising stable target identity, preview, approval, execution, receipt, reconciliation, and undo.

### P8.1 Implement versioned scratch-note adapter

- [ ] RED adapter tests for create/append, stable note/revision target, stale revision, idempotency,
  timeout around atomic replace, reconcile, rollback, undo conflict, and data-root isolation.
- [ ] Required lanes: unit, integration, fault injection, migration, security.
- [ ] Commit, push, exact-SHA CI green.

### P8.2 Compose deterministic skill and constrained planner

- [ ] RED adversarial tests for wrong target, extra action, prompt injection, unknown metadata,
  unauthorized path, duplicate execution, Local-route violation, and model unavailability.
- [ ] Required lanes: unit, contract, integration, security/red-team, fixture E2E.
- [ ] Commit, push, exact-SHA CI green.

### P8.3 Complete approval, receipt, and undo UX

- [ ] RED UI/UIA/process journeys from text request through preview/approve/reject/edit/execute/
  receipt/undo/restart, including expired/stale/error/unknown-commit cases.
- [ ] Required lanes: UI/UIA, fixture E2E, accessibility, security, reliability.
- [ ] Commit, push, exact-SHA CI green.

### P8.4 Real-action pilot and adversarial gate

- [ ] Execute on disposable profiles with crash/network/disk/lock/restart injection at every boundary.
- [ ] Prove no write before durable approval, no blind retry, and exact receipt/reconciliation.
- [ ] Required lanes: real-boundary E2E, security/red-team, reliability, packaging.
- [ ] Commit, push, exact-SHA CI green.

## 18. Phase 9 — Voice, selected-source retrieval, restrained proactivity

### P9.1 Implement modular push-to-talk voice

- [ ] RED tests for capture state, PCM/WAV fixtures, silence, device loss, provider mapping, low
  confidence confirmation, cancellation/barge-in, mute/fullscreen, route disclosure, and text fallback.
- [ ] Required lanes: unit, contract, integration, UI/UIA, fixture E2E, real audio boundary manual.
- [ ] Commit, push, exact-SHA CI green.

### P9.2 Implement selected-source knowledge retrieval

- [ ] RED tests for explicit file/directory ingestion, type/size limits, hashing/dedup, deletion,
  citation fidelity, stale index, malicious document, local model absence, and package size.
- [ ] Required lanes: unit, integration, real-boundary E2E, security, performance, packaging.
- [ ] Commit, push, exact-SHA CI green.

### P9.3 Implement restrained proactive rules

- [ ] RED clock/property tests for attention budget, focus/fullscreen suppression, quiet hours,
  duplicate candidate, dismissal learning, stale event, source citation, never autonomous action,
  and visible opt-out.
- [ ] Required lanes: unit, integration, UI/UIA, fixture E2E, accessibility, privacy.
- [ ] Commit, push, exact-SHA CI green.

## 19. Phase 10 — Policy-gated MCP pilot

### P10.1 Supervise one allowlisted read-only MCP server

- [ ] RED tests for executable/path allowlist, environment redaction, stdio framing, timeout, output
  limit, process tree, schema hash, unknown type, crash, and revocation.
- [ ] Required lanes: unit, contract, integration, security, reliability, packaging.
- [ ] Commit, push, exact-SHA CI green.

### P10.2 Import capabilities through consent and policy

- [ ] RED UI/policy tests for manifest review, risk/source badges, grant scope, schema change,
  re-consent, disabled server, prompt injection, and no model-direct execution.
- [ ] Required lanes: policy unit, UI/UIA, security/red-team, fixture E2E.
- [ ] Commit, push, exact-SHA CI green.

### P10.3 Complete live read-only MCP journey

- [ ] Run a clean-machine real-server request through task, policy, result, receipt, disable, and
  restart; verify no undeclared side effect or secret leak.
- [ ] Required lanes: service/real-boundary E2E, security, reliability, packaging.
- [ ] Commit, push, exact-SHA CI green.

## 20. Phase 11 — Release qualification, pilot, and documentation truth

### P11.1 Build and verify release packages

- [ ] RED package probes for missing assets/runtime/contracts/SBOM/license, bad signature, upgrade,
  rollback, sidecar absence, offline first run, migration, uninstall/reset, and exact version.
- [ ] Required lanes: all automated lanes, clean Windows 10/11 install/upgrade/rollback, security,
  performance, packaging.
- [ ] Commit, push, exact-SHA CI green.

### P11.2 Run the bounded pilot

- [ ] Freeze sampling, hardware/route cohorts, privacy consent, metrics, exclusion rules, failure
  severity, and rollback before collecting results.
- [ ] Measure brief usefulness, reminder reliability, grounded-context accuracy, approval clarity,
  action success/reconcile/undo, memory correction/delete, offline reliability, accessibility,
  performance, and support burden with stable metric IDs.
- [ ] No severe privacy/security issue, unreconciled action, silent data loss, inaccessible blocker,
  or repeated crash may remain open.
- [ ] Commit the sanitized reproducible report, push, exact-SHA CI green.

### P11.3 Synchronize all product truth

- [ ] Update `README.md`, `AGENTS.md` if workflow changed, `REQUIREMENTS.md`, `CHECKLIST.md`,
  `docs/architecture.md`, PRD, design, ADRs, UI spec, operator/developer/privacy/security/migration/
  troubleshooting docs, dependency manifests, and release notes against the final code.
- [ ] Run link, schema, requirement-map, command, package-content, and documentation-truth probes.
- [ ] Required lanes: documentation, full regression, clean package smoke.
- [ ] Commit, push, exact-SHA CI green.

### P11.4 Final independent review and release decision

- [ ] Independent code/design compliance review passes.
- [ ] Security/privacy threat review and adversarial suite pass.
- [ ] Accessibility/visual supported-machine matrix passes.
- [ ] All Gate 0 through E evidence points to the release head SHA; rerun invalidated evidence.
- [ ] Draft PR becomes review-ready; required branch protection/checks pass; merge/release only with
  user authorization and no unresolved blocker.
- [ ] Commit the final review/evidence manifest, push it, and obtain exact-head-SHA CI success before
  requesting merge or release authorization.

## 21. Full verification command catalogue

Exact project paths may be introduced by their owning step; manifests pin the final commands.

```powershell
dotnet restore AemeathDesktopPet.sln
dotnet build AemeathDesktopPet.sln -c Release --no-restore
dotnet test tests/Aemeath.Preservation.UnitTests -c Release --no-build
dotnet test tests/Aemeath.Preservation.IntegrationTests -c Release --no-build
dotnet test tests/Aemeath.Preservation.WpfTests -c Release --no-build
dotnet test tests/Aemeath.UiAutomation.Tests -c Release --no-build
dotnet test tests/Aemeath.RealBoundary.Tests -c Release --no-build
dotnet test tests/Aemeath.Packaging.Tests -c Release --no-build
dotnet test tests/Aemeath.ArchitectureTests -c Release --no-build
dotnet test tests/Aemeath.Protocol.Tests -c Release --no-build
dotnet test tests/AemeathDesktopPet.Tests -c Release --no-build
dotnet format --verify-no-changes
pwsh -File tools/verify-preservation-detection.ps1
pwsh -File tools/test-preservation.ps1
```

```powershell
Set-Location python-backend
python -m pip install -e ".[dev]"
pytest preservation_tests/unit -v
pytest preservation_tests/contract -v
pytest preservation_tests/integration -v
pytest preservation_tests/e2e -v
pytest tests -v --cov=aemeath_agent
ruff check .
```

Every test command must assert nonzero discovery and emit machine-readable TRX/JUnit. The exact-SHA
wait verifies `git rev-parse HEAD`, the PR head SHA, Actions `headSha`, job/check identities, matrices,
commands, conclusions, and artifacts before returning success.

## 22. Reflection on checklist quality

### What works well

- Preservation is a genuine first gate, so the rewrite cannot erase the desktop pet while chasing
  assistant breadth.
- Independent tests reduce shared-oracle risk; known defects are explicitly changed rather than
  preserved accidentally.
- The smallest useful tests run first, while risk-mapped integration, UI, E2E, security, performance,
  packaging, and real Windows evidence prevent unit-test-only confidence.
- Exact-SHA CI and evidence manifests prevent a green result from another commit or reduced workflow
  from being mistaken for completion.
- A single task/policy/memory authority and reversible first action keep the Jarvis direction useful
  without granting unsafe autonomy.

### Corrections made after reflection

- “All kinds of tests” applies across each gate's actual risks, not a ceremonial process E2E for every
  private helper. A lane can be `N/A` only in the frozen pre-step manifest with a boundary-specific
  reason; it cannot be waived after failure.
- Preserved behavior uses characterization-first TDD. Forcing such a test to fail on unchanged code
  would require a fake defect. Mutation/known-bad detection proves the test can catch regression.
- Changed/new behavior, workflow changes, configuration, packaging, and migrations still require a
  real RED result at the intended oracle.
- Hosted Windows UI Automation is useful but cannot prove Narrator quality, real high contrast/DPI,
  tray/hotkey/audio, transparent hit testing, DWM, or multi-monitor behavior. Those remain blocking
  self-hosted/manual evidence where mapped.
- Live cloud providers and physical devices are excluded from deterministic PR gates, but adapters
  still receive fixture contract tests and bounded pre-release real-boundary evidence where terms and
  credentials permit.
- No hard-coded test count is a permanent quality goal. Nonzero discovery, PB/AC trace completeness,
  meaningful failure detection, risk coverage, and reproducibility are the durable gates.

### Remaining controlled decisions

- The sidecar distribution option is selected once by the Phase 0 H0.5 measured bake-off; Phase 2
  implements and qualifies that recorded decision.
- Local ICS plus product-owned reminders is the first brief source; OAuth calendars require a later
  threat/product decision.
- The product-owned versioned scratch note is the first reversible action; third-party application
  writes require a separate capability and consent review.
- Final replacement art, mini-games, and extra sound effects remain an explicit post-release backlog,
  not silently dropped work.

The checklist is considered well-formed only while these rules remain enforceable. If a step becomes
too large for one focused commit, it must be decomposed before RED, and every child step inherits the
same test-first, push, exact-SHA CI, and no-advance conditions.

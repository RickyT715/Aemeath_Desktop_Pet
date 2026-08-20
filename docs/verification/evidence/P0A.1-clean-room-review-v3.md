# P0A.1 Clean-room Preservation Review v3

Reviewer assignment: `clean-room-preservation-reviewer-02`

Verdict: **BLOCK**

Finding census: **C=0, I=6, M=0**

## Outcome

The frozen preservation specification is strongly bound and most literal, resource, protocol,
traceability, lane, and inventory claims were confirmed from allowed sources. It is not complete or
truthful enough to pass because six important findings remain. This verdict was reached without
reading legacy tests, legacy fixtures/helpers/snapshots, generators, validators, schemas, prior
results, prior review evidence, or Git metadata/history.

## Findings

### I-01 — Later-step mapping for keyboard, deferred features, and deferred assets is not truthful

The checklist defines `P4.5e` as keyboard/access recovery. `GAP-KEYBOARD-COMPANION-SURFACE`
therefore has the right thematic later step, but the trace test owned by `P4.5e` covers only
`FUT-001` through `FUT-003`, `PRD:AC-FR-020-05`, and PB-002/PB-004/PB-018; it does not cover the
keyboard requirement `PRD:AC-FR-017-01` or PB-003/PB-005/PB-008. The trace instead sends that
keyboard acceptance criterion to `P0B.3e`, while the checklist defines `P0B.3e` as the
theme/contrast/motion/scale child.

The same collision makes the other deferred mappings false or non-executable:
`GAP-MINIGAMES-MISSING` and `GAP-INTERACTION-SOUNDS-MISSING` also target the keyboard child
`P4.5e`; `GAP-STATE-CAT-ASSETS` names a non-child “P4.5 asset follow-up”; and
`GAP-PAPER-PLANE-RENDERER` combines the real `P4.5c` renderer repair with final-artwork scope that
remains pending/post-release. `APP-007`, `APP-008`, and `APP-009` are pending and therefore
effectively preserve their current requirements. The frozen gap/trace graph does not provide
truthful executable later RED ownership for this family.

### I-02 — `GAP-RAG-LIVE-CONFIG` targets the wrong later step

Production registers the RAG retrieval tool but the normal startup/API path does not configure its
live retriever, so the gap itself is real. The gap binds `CURRENT:FR-AI-006` and
`CURRENT:FR-AI-007` but targets only `P8.2`. The checklist and trace make `P8.2` the constrained,
reviewed scratch-note action, whereas selected-source knowledge retrieval and the current
`FR-AI-007`/`AC-AI-007` records are owned by `P9.2`. The gap must target `P9.2` or be split by
requirement; its current requirement-to-later-step claim is false.

### I-03 — `GAP-CHAT-TIER-FAILOVER` has incomplete later-step ownership

Production selects one chat service at construction time and a sidecar/provider failure falls back
offline rather than retrying a direct provider, so the gap is real. The gap binds
`CURRENT:AR-004` and `PRD:AC-FR-014-02` but targets only `P2.3`. In the trace, `P2.3` covers
recovery/resumable lifecycle (`PRD:AC-FR-014-04`), while `PRD:AC-FR-014-02` is assigned to the
`P3.3` contract/security work. The frozen gap must be split or name all owning steps.

### I-04 — The persisted-data inventory omits the Windows startup registry value

`StartupService.SetStartWithWindows` creates or deletes
`HKCU\Software\Microsoft\Windows\CurrentVersion\Run\AemeathDesktopPet`, and Settings invokes it
when saving the startup preference. This is durable, app-owned state with restart, packaging,
cleanup, and real-profile safety implications, but it is absent from all 11 `persistedData`
records and from the data fixture. The JSON/checkpoint/memory/Chroma/todo stores are represented;
the STT temporary file is deleted and the configured activity database is opened read-only. The
registry side effect is therefore a concrete completeness omission rather than a duplicate of an
existing record.

### I-05 — The environment map leaves `P0A.2` without its required interactive Windows target

`V-REAL-E2E` is owned by `P0A.2`, and both its pet-visibility and keyboard journeys explicitly
require a disposable interactive Windows desktop. The ADR states that hosted Windows cannot
substitute for tray, global-hotkey, or other true desktop boundaries. Nevertheless,
`ENV-GHA-WINDOWS` targets `P0A.2`, while the two interactive Windows environments are
`blocked-not-provisioned` and their `targetSteps` omit `P0A.2` (they name only later P0A.7/P0A.8
work). D0.4 may honestly freeze a blocked readiness result; the defect is that the five-environment
map neither assigns the required interactive environment to `P0A.2` nor explicitly exposes that
step as blocked.

### I-06 — The clean-room source contract cannot verify the complete build/package component

`CMP-BUILD-PACKAGE` cites `python-backend/pyproject.toml` and `.github/workflows` as source
locators. Neither path is present in the reviewer assignment's exact allowed-source list, and both
are outside this review's repository allowlist. All other inventory source locators close over
allowed sources. I did not read either excluded locator. Consequently an unexposed reviewer cannot
independently verify the component's dependency/workflow/package assertions while the frozen spec
and manifest claim a complete inventory.

## Confirmed checks

- PB-001 through PB-018 are unique, present, and structurally reciprocal with their declared
  journeys, lanes, artifacts, gaps, and oracle records.
- The frozen counts are present: 20 components, 11 declared persisted-data records, 13 integration
  boundaries, 5 Windows journeys, 14 qualification lanes, 4 artifacts, 34 gaps, and 5 environments.
  The six findings above describe the semantic completeness/mapping failures within those counts.
- All 34 gaps were checked against production truth, their requirement IDs, PB links, pending
  disposition truth, and named later steps. In particular, pending `APP-007` through `APP-009` were
  treated as effective preservation, not as approved future scope.
- All 114 current-requirement disposition records had valid source ranges and normalized source-text
  hashes. All nine proposed approval records remain pending. Trace IDs and direct reciprocal links
  were structurally valid; the trace contains 352 entries and 158 test-catalog records.
- Each of the 14 lane PB sets equals the union of its declared test-catalog PB sets. The manifest,
  spec, and trace agree on the P0A.1 requirement, PB, environment, lane, and fixture identifiers.
- The four fixtures parsed and their record counts matched: 7 data, 28 oracle, 15 protocol, and 11
  resource records. Literal geometry, statistics, timers, limits, protocol shapes, known protocol
  incompatibilities, and data defaults were checked against allowed production sources.
- All 11 resource byte hashes, dimensions, and GIF frame counts matched production bytes and their
  runtime status descriptions.
- Source hashes, trace raw hash, both production-root identity digests, and all fixture hashes were
  independently recomputed using the frozen methods and matched the values below.
- No v4 command-string finding was found. The direct command
  `./tools/verification/Test-PreservationSpecification.ps1` parses as a script invocation under the
  installed Windows PowerShell 5.1 and is the same PowerShell-native relative-script form used by
  the declared Ubuntu `pwsh` shell. Ubuntu `pwsh` was not installed locally, and the forbidden
  script body was neither read nor executed; this conclusion is limited to the frozen command form.

## Exact bindings

- Binding: `docs/verification/preservation-spec-v1.yml` = `9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d`
- Binding: `docs/verification/manifests/P0A.1-v4.yml` = `f6b06092f7070c8c9ef8a02c7465e9397adafc3189cf150b779fafd022b51609`
- Binding: `docs/verification/traceability-v1.yml` = `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55`
- Binding: `src/AemeathDesktopPet` = `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb`
- Binding: `python-backend/aemeath_agent` = `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae`
- Binding: `tests/fixtures/preservation/v1/data-v1.json` = `fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa`
- Binding: `tests/fixtures/preservation/v1/oracles-v1.json` = `4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d`
- Binding: `tests/fixtures/preservation/v1/protocol-v1.json` = `95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312`
- Binding: `tests/fixtures/preservation/v1/resources-v1.json` = `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8`

## Sources actually read

The review read only these repository sources:

1. `REQUIREMENTS.md`
2. `docs/prd/jarvis_assistant_prd.md`
3. `docs/design/jarvis_assistant_design.md`
4. `docs/ui-spec/jarvis_assistant_ui_spec.md`
5. `docs/plans/20260722-jarvis-assistant-tdd-checklist.md`
6. `docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md`
7. `docs/verification/traceability-v1.yml`
8. `docs/verification/manifests/P0A.1-v4.yml`
9. All 94 production files under `src/AemeathDesktopPet`
10. All 46 production files under `python-backend/aemeath_agent`
11. `tests/fixtures/preservation/v1/data-v1.json`
12. `tests/fixtures/preservation/v1/oracles-v1.json`
13. `tests/fixtures/preservation/v1/protocol-v1.json`
14. `tests/fixtures/preservation/v1/resources-v1.json`
15. `docs/verification/preservation-spec-v1.yml`

No repository source outside that list was read. In particular, no legacy test, prior evidence,
validator/generator/schema, invalidation, README, tool script, or Git metadata/history was read, and
no project, test, or repository verification script was executed. Checks were limited to parsing,
hashing, byte/resource inspection, and pure semantic comparison of allowed inputs.

## External skill exposure

The platform required process-skill handling outside the repository. I read
`C:\Users\Ricky\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\using-superpowers\SKILL.md`
and
`C:\Users\Ricky\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\verification-before-completion\SKILL.md`.
Those files supplied workflow-only instructions, are not repository or legacy exposure, and were not
used as semantic evidence for any preservation conclusion.

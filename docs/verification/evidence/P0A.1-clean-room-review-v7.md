# P0A.1 clean-room preservation review v7

- Reviewer assignment: `clean-room-preservation-reviewer-06`
- Legacy exposure: `unexposed`
- Verdict: **PASS**
- Finding census: **C=0, I=0, M=0**

## Review boundary and provenance

This is an independent static preservation review of the P0A.1 source-identity successor in
`D:\Study\Project\Aemeath_Desktop_Pet_worktrees\jarvis-tdd`. The output path was checked twice and
did not exist before creation. Repository access was default-deny and confined to the exact 21-item
read set below. Directory recursion was used only for the two production roots. No legacy test,
helper, snapshot, result, predecessor evidence, predecessor manifest/specification, invalidation,
`.superpowers`, Git metadata, original repository, or network resource was opened. References to
governance-history artifacts visible inside an allowed file were not followed.

The platform required one external skill read before repository work:
`C:\Users\Ricky\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\using-superpowers\SKILL.md`.
That external instruction immediately exempts dispatched subagents; it did not expand repository
access and is not a product or preservation oracle. No other external material was read.

The review used strict UTF-8/raw-byte hashing, strict JSON parsing, PowerShell AST parsing,
normalized-source hashing, direct production-source inspection, XAML/XML inspection, raw resource
hashing, independent GIF metadata decoding, and referential-closure checks. It did not execute the
full preservation validator or any project code.

## Exact repository read set

1. `REQUIREMENTS.md`
2. `docs/prd/jarvis_assistant_prd.md`
3. `docs/design/jarvis_assistant_design.md`
4. `docs/ui-spec/jarvis_assistant_ui_spec.md`
5. `docs/plans/20260722-jarvis-assistant-tdd-checklist.md`
6. `docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md`
7. `docs/verification/traceability-v2.yml`
8. `docs/verification/manifests/P0A.1-v9.yml`
9. `src/AemeathDesktopPet` recursively
10. `python-backend/aemeath_agent` recursively
11. `tests/fixtures/preservation/v1/data-v5.json`
12. `tests/fixtures/preservation/v1/oracles-v1.json`
13. `tests/fixtures/preservation/v1/protocol-v3.json`
14. `tests/fixtures/preservation/v1/resources-v1.json`
15. `docs/verification/preservation-spec-v5.yml`
16. `python-backend/pyproject.toml`
17. `.github/workflows/release.yml`
18. `tools/verification/Test-PreservationSpecification.ps1`
19. `tools/ci/CiDeliveryContract.psm1`
20. `docs/verification/manifests/D0.4-v3.yml`
21. `docs/verification/environments/D0.4-readiness-v1.json`

## Live identities for all 21 sources

All 19 files are strict UTF-8 without BOM and use CRLF exclusively. File digests below are raw-byte
SHA-256. Root digests use the declared v1 production-root algorithm: exclude reparse points,
`bin`, `obj`, `__pycache__`, `.pytest_cache`, and `.pyc`; emit
`relative/path|byteLength|lowercaseRawSha256`; sort ordinally; join with LF and no trailing delimiter;
hash UTF-8 without BOM.

| # | Exact path | Kind | Bytes | Files | Live SHA-256 / root digest |
|---:|---|---|---:|---:|---|
| 1 | `REQUIREMENTS.md` | file | 31351 | 1 | `3fc8daddbc17637b2f499c2e1e4eac090d6df2d7695e982c04bd373141ed9bee` |
| 2 | `docs/prd/jarvis_assistant_prd.md` | file | 71384 | 1 | `7f3fd8d9b9fea58d5965ab5f305e3b089f41558848e253868d70ab9bf3de803d` |
| 3 | `docs/design/jarvis_assistant_design.md` | file | 84728 | 1 | `e771018de8ae93984ee897d8ab9a98f1881cab08197280a8de8b0cc30db670ca` |
| 4 | `docs/ui-spec/jarvis_assistant_ui_spec.md` | file | 42824 | 1 | `635f89688e2510927a358ebecaccf6cb7fbe4258d1a0725ea214a318f02167a9` |
| 5 | `docs/plans/20260722-jarvis-assistant-tdd-checklist.md` | file | 75319 | 1 | `e3162d12fbdcefaa4ae667f3c327f82dd9d95cc55de4d959b9d886b2065e786b` |
| 6 | `docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md` | file | 39009 | 1 | `47dcc270edc7815271d63a0c6b57364af320377ed535fa2e3389ab78cb817636` |
| 7 | `docs/verification/traceability-v2.yml` | file | 478168 | 1 | `28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415` |
| 8 | `docs/verification/manifests/P0A.1-v9.yml` | file | 15263 | 1 | `7e7d8c298b91f78479cb0dfc8a028e02d5f84785fd3d3768eb88e591c78a284d` |
| 9 | `src/AemeathDesktopPet` | production root | 6288961 | 94 | `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb` |
| 10 | `python-backend/aemeath_agent` | production root | 111640 | 46 | `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae` |
| 11 | `tests/fixtures/preservation/v1/data-v5.json` | file | 41016 | 1 | `4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0` |
| 12 | `tests/fixtures/preservation/v1/oracles-v1.json` | file | 7954 | 1 | `4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d` |
| 13 | `tests/fixtures/preservation/v1/protocol-v3.json` | file | 17433 | 1 | `cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565` |
| 14 | `tests/fixtures/preservation/v1/resources-v1.json` | file | 3167 | 1 | `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8` |
| 15 | `docs/verification/preservation-spec-v5.yml` | file | 168943 | 1 | `123df163b9cfb23c7fe17b133a32757c90424bafc499aa1b089db24628c2c4c9` |
| 16 | `python-backend/pyproject.toml` | file | 1266 | 1 | `7cb128bcda68eb2b5e890c0c390c0c4f46f6a24c474d8753ce904416ef10463d` |
| 17 | `.github/workflows/release.yml` | file | 1324 | 1 | `066dd7244e6ac12bd350500cbe6ee1f7dd34eee40ef5b7b851e67abf161f7fe9` |
| 18 | `tools/verification/Test-PreservationSpecification.ps1` | file | 173192 | 1 | `a096afd7933e8a1b6ded98d3796b3a59c467ada7710def7ce0bbac13dc9544dd` |
| 19 | `tools/ci/CiDeliveryContract.psm1` | file | 23981 | 1 | `85cd1c770b5be08737d8045b64a1d60d11b003f235fc732f1ffe7f15aeba19f3` |
| 20 | `docs/verification/manifests/D0.4-v3.yml` | file | 10381 | 1 | `d8b763acaa04088f5f8b47b79d956deea8f9898b74d543004938d4cd3d642d2e` |
| 21 | `docs/verification/environments/D0.4-readiness-v1.json` | file | 12132 | 1 | `aafcdc4919239c0bb239f15b61c7b757c665e3649cda04e114b203e67eb813bc` |

The two root identities total 140 files and exactly match the specification and validator constants.
The D0.4 normalized-text digest is
`3747f8520497b65544ef0cd1bb386b8e72866284001da408de111f454f0d614a`, exactly matching the
readiness record's risk-manifest binding.

## Source-identity successor review

The specification retains historical `baseline.commitSha`
`43f9c288f843f7620ffee5eee3504f52875f4774` as provenance and explicitly sets
`requiresLiveHeadEquality=false`. The validator's pure `Get-SourceIdentityFailures` function has two
parameters, no command invocation, no filesystem/environment/Git access, and no reference to the
historical baseline. Its behavior is solely determined by the two raw input strings:

1. valid live head plus null `SOURCE_SHA`: pass;
2. valid live head plus empty `SOURCE_SHA`: pass;
3. valid live head plus identical raw lowercase `SOURCE_SHA`: pass;
4. valid live head plus a different valid lowercase `SOURCE_SHA`: `source-sha-mismatch`;
5. valid live head plus short malformed `SOURCE_SHA`: `source-sha-format`;
6. malformed live head plus null `SOURCE_SHA`: `live-head-format`;
7. valid live head plus uppercase 40-hex `SOURCE_SHA`: `source-sha-format`;
8. valid live head plus leading-space `SOURCE_SHA`: `source-sha-format`;
9. valid live head plus trailing-space `SOURCE_SHA`: `source-sha-format`;
10. malformed live head plus otherwise valid `SOURCE_SHA`: only `live-head-format`.

The guard uses a synthetic valid live head deliberately different from the historical baseline, so
local null/empty cases kill a regression that reintroduces baseline equality. Raw lowercase regex
validation followed by `StringComparer.Ordinal.Equals` kills a second regression class that trims,
normalizes, or case-folds the CI value. Thus the 10 cases cover both identity mutants without making
the historical baseline a live-checkout constraint.

`Get-GitHeadSha` accepts exactly one raw lowercase 40-hex `git rev-parse HEAD` result. The authority
context reads the raw environment value; non-empty means active, and active CI input must itself be
raw lowercase 40-hex and ordinal-equal to live HEAD. Null and the empty string remain the two local
modes. `Write-CiDiscoveryMarker` independently resolves live HEAD and emits that result as
`sourceSha`; no baseline value is used for the marker.

AST inspection found exactly 37 fixed-input authority entries. The top-level order is: observe fixed
authorities/source hashes/production roots/live identity; assert authority; execute seven reversible
in-memory authority mutants; execute the 10-case source-identity guard; assert authority again to
prove restoration; then construct live context, import the marker module, parse the specification,
and evaluate the baseline and seven specification mutants. This keeps the identity guard before any
GREEN claim and restores all mutated observations in `finally` blocks.

Per the clean-room restriction, this review did not read Git metadata or observe an actual live HEAD
or `SOURCE_SHA`; it verifies the static policy and enforcement path, not a particular checkout SHA.

## Structure, semantics, and closure

- Strict JSON parsing succeeded for the specification, P0A.1 manifest, traceability file, four
  fixtures, D0.4 manifest, and D0.4 readiness record. The specification has the exact 21-property
  top-level shape, schema 1, id `P0A.1-preservation-spec-v5`, revision 5, and frozen status.
- Census is exact: PB 18; components 20; public behaviors 18; persisted-data targets 16; data records
  17; integration boundaries 13; Windows journeys 5; qualification lanes 14; artifacts 4; supported
  environments 5; known gaps 35; oracles 28; protocol contracts 15; resources 11.
- All inventory, boundary, lane, journey, gap, artifact, oracle, and data references resolve. Every
  boundary's data/oracle/gap/lane/journey/artifact links equal the reciprocal source-derived set; no
  catalog item is orphaned. PB-018 is present and fully participates in these closures.
- The 17 data records reduce to exactly 16 atomic targets: 12 application-owned and four external
  read-only targets, with 10 current/conditional writable targets and two latent writable,
  currently read-only targets. Paths, ownership, access, lifecycle, path semantics, fixture-record
  membership, read/write/delete reachability, and source locators agree between production and the
  specification. Qualified failure/conditional language is retained for caught I/O, provider,
  model, and initialization failures; no successful persistence is inferred from an attempted call.
- Independent production I/O review found the declared JSON files, current-user Run value,
  checkpoint SQLite, Python JSON stores, Chroma directories, todo SQLite, four external read-only
  inputs, and only ephemeral STT temporary-file behavior outside the durable target set. No omitted
  durable application target was found.
- All 11 resource bytes/hashes match production. Independent image decoding reproduced all declared
  GIF frame counts and dimensions. Runtime-status claims match production preload, behavior mapping,
  normal fallback, package, tray-icon, and theme-merge paths.
- All 28 oracle records agree with production XAML, C#, Python, and normative sources for geometry,
  stats, decay, physics, timers, memory limits, TTL, ports, MCP, and documented gaps. Random
  sequences, wall-clock instants, exact GIF dynamic frames, missing automation semantics, reminders,
  and unqualified protocol transport are not promoted to passing exact-value oracles.
- Fixture privacy declarations are false for secrets and personal data; canary payloads use
  `AEMEATH_FIXTURE_*` values and empty key fields. No real user data, credential, provider execution,
  process execution, registry mutation, database mutation, or network call was used.

## Traceability and locator checks

All six normalized source hashes recomputed from the allowed normative documents match both the
specification and traceability source records:

| Source id | Normalized SHA-256 |
|---|---|
| `CURRENT:REQUIREMENTS` | `94c8c95a75ca7f6f417e4b6358042ed727656cd58074213f878ddbaaeff37cbc` |
| `CURRENT:LOCATORS` | `0d20daf50ef166b78805f170972b517e1533a0b69afc274a44c8e0ef5628ad58` |
| `PRD:JARVIS` | `b2ee8dfaffdfa27e22f820f5bf7f6a065a360933a5c4b1789b4cd1ea27d791b2` |
| `DESIGN:JARVIS` | `f280cdbd89946d934888cd91ef2c7fafa0478126f58ec2e4365f7be23481f12b` |
| `UI:JARVIS` | `806d37aa63a719dda7de7446c2e6ff6bbc55243eb0ce6478d6464ad7ca68b1c1` |
| `ADR:VERIFICATION` | `21ac1e7df434b37d4a8fe596d8dcceab9f26eb386f5d77cf88b052473253f9e9` |

Traceability contains exactly 352 unique entries, including 114 `CURRENT` entries, and 158 unique
test-catalog records. Every one of the 352 source line spans was rehashed from its live normalized
source and matched `sourceTextSha256`. All 771 entry-to-test links have matching reverse
test-to-requirement links; all reverse links resolve, and each owning test covers the entry's PB set.
The 114-record disposition identity recomputes to
`fdd77a96813a3d8d5270e47a803486cac64eff33e2f8426d97f1200240423f7b`, matching the map and
specification.

The specification has exactly 92 unique `sourceLocators`. Every locator is covered by the 21-item
allowlist and resolves to an existing allowed file or directory. The three Markdown anchors resolve
to their live headings. The build/package component uses the exact release workflow file, not a
directory wildcard. No locator points into a legacy or prior-evidence root.

## Protocol and SSE qualification

The 15 protocol contracts match current producer and consumer shapes. The agent request shape is
compatible without screenshot; screenshot request and one-shot response-field mismatches are
explicitly incompatible. Health is described only as process liveness, not agent usability. Internal
WPF/Python route drift and MCP's shape-only/no-process-execution status are explicit.

For SSE, production passes already-framed text from `format_sse_event` to `EventSourceResponse`, while
`sse-starlette` is constrained only as `>=2.0.0`. Token and done records therefore remain
`compatibility=false`, `not-qualified-compatible`, with `versionPinned=false` and
`exactWireFrozen=false`. Tool-call and error records preserve only the statically visible shape/error
handling mismatches and explicitly avoid claiming whether unqualified transport bytes reach the C#
consumer. The fixture, gap statements, and specification do not overstate SSE wire compatibility.

## PowerShell portability and side effects

Windows PowerShell 5.1.26100.9168 parsed the validator with zero errors (22,025 tokens, 55 functions)
and the delivery module with zero errors (3,603 tokens, 7 functions). Static inspection found no
PowerShell-7-only syntax in the reviewed paths; used cmdlets, generic collections, .NET hashing/path
APIs, strict JSON conversion, and AST-compatible constructs are available to both declared engines.
`pwsh` is not installed in this local environment, so no local pwsh parser or runtime claim is made.
The allowed D0.4 records bind the normalized capability manifest and record the hosted Ubuntu
exact-SHA capability as ready; this review did not contact or re-run that environment.

The validator/module contain no repository write, registry write, network, or project-code execution path for this
preservation command. Observable effects are read-only file/tree
inspection, read-only `git rev-parse`, module import, and stdout; mutation guards change only
in-memory observations and restore them. The reviewer did not execute `git`, import the module, or
run the full validator. Full-validator execution was also avoided because its authority phase would
open governance-history inputs outside this reviewer's allowlist.

## Findings and limitations

No critical, important, or minor preservation defect was found. The PASS is limited to the static
clean-room claims above. It is not a claim that the full validator ran, that a particular Git HEAD or
CI `SOURCE_SHA` was observed, that blocked later Windows environments are provisioned, or that any
legacy suite was inspected or passed.

## Mechanical no-glob bindings

The following are exactly 13 file bindings plus two production-root bindings. The evidence file is
deliberately not self-bound.

- BINDING path=docs/verification/preservation-spec-v5.yml kind=preservation-specification hash=SHA-256 bytes=168943 count=1 digest=123df163b9cfb23c7fe17b133a32757c90424bafc499aa1b089db24628c2c4c9
- BINDING path=docs/verification/manifests/P0A.1-v9.yml kind=risk-lane-manifest hash=SHA-256 bytes=15263 count=1 digest=7e7d8c298b91f78479cb0dfc8a028e02d5f84785fd3d3768eb88e591c78a284d
- BINDING path=docs/verification/traceability-v2.yml kind=traceability hash=SHA-256 bytes=478168 count=352 digest=28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415
- BINDING path=tests/fixtures/preservation/v1/data-v5.json kind=data-fixture hash=SHA-256 bytes=41016 count=17 digest=4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0
- BINDING path=tests/fixtures/preservation/v1/oracles-v1.json kind=oracle-fixture hash=SHA-256 bytes=7954 count=28 digest=4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d
- BINDING path=tests/fixtures/preservation/v1/protocol-v3.json kind=protocol-fixture hash=SHA-256 bytes=17433 count=15 digest=cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565
- BINDING path=tests/fixtures/preservation/v1/resources-v1.json kind=resource-fixture hash=SHA-256 bytes=3167 count=11 digest=63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8
- BINDING path=python-backend/pyproject.toml kind=source-file hash=SHA-256 bytes=1266 count=1 digest=7cb128bcda68eb2b5e890c0c390c0c4f46f6a24c474d8753ce904416ef10463d
- BINDING path=.github/workflows/release.yml kind=source-file hash=SHA-256 bytes=1324 count=1 digest=066dd7244e6ac12bd350500cbe6ee1f7dd34eee40ef5b7b851e67abf161f7fe9
- BINDING path=tools/verification/Test-PreservationSpecification.ps1 kind=validator hash=SHA-256 bytes=173192 count=1 digest=a096afd7933e8a1b6ded98d3796b3a59c467ada7710def7ce0bbac13dc9544dd
- BINDING path=tools/ci/CiDeliveryContract.psm1 kind=validator-module hash=SHA-256 bytes=23981 count=1 digest=85cd1c770b5be08737d8045b64a1d60d11b003f235fc732f1ffe7f15aeba19f3
- BINDING path=docs/verification/manifests/D0.4-v3.yml kind=capability-manifest hash=SHA-256 bytes=10381 count=1 digest=d8b763acaa04088f5f8b47b79d956deea8f9898b74d543004938d4cd3d642d2e
- BINDING path=docs/verification/environments/D0.4-readiness-v1.json kind=capability-readiness hash=SHA-256 bytes=12132 count=1 digest=aafcdc4919239c0bb239f15b61c7b757c665e3649cda04e114b203e67eb813bc
- BINDING path=src/AemeathDesktopPet kind=production-root hash=SHA-256 bytes=6288961 count=94 digest=28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb
- BINDING path=python-backend/aemeath_agent kind=production-root hash=SHA-256 bytes=111640 count=46 digest=98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae

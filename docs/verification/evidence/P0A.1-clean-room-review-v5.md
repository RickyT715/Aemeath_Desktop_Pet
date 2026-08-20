# P0A.1 Clean-room Preservation Review v5

## Assignment and result

- Reviewer assignment: `clean-room-preservation-reviewer-04`
- Legacy exposure: `unexposed`
- Verdict: **BLOCK**
- Finding census: **C=0, I=1, M=0**

The unchanged-product preservation contract is structurally complete and internally well linked, but it contains one Important overclaim about an unqualified SSE transport outcome. Under the governing rule that any Confirmed, Important, or Major finding blocks acceptance, the review cannot pass.

## Finding

### I-01 — SSE event-discard claims exceed the frozen transport evidence

The production sources statically establish that `routes_agent.py` gives `EventSourceResponse` strings already formatted as SSE by `sse.py`, that the producer places a streamed tool name in `content`, that the desktop reads `data.name`, and that the desktop has no `error` event branch. Those are supportable static facts.

The contract goes further. `docs/verification/preservation-spec-v3.yml:3208` says double framing *discards* the tool-call event before the payload mismatch can surface, and line 3224 says error events *are discarded* by double framing. The same specification at line 3193 says formatter behavior is unpinned, exact wire bytes are not frozen, and compatibility remains unqualified. `tests/fixtures/preservation/v1/protocol-v3.json:92`, lines 93–94, and the corresponding fields at lines 126–128, 159–161, and 198–200 record only `sse-starlette>=2.0.0`, `versionPinned: false`, and `exactWireFrozen: false`; token and done are explicitly `not-qualified-compatible`, while the tool and error expected-failure text carefully says transport behavior is not frozen. `python-backend/pyproject.toml:21` confirms the open-ended dependency constraint.

The strict source closure contains neither a locked `sse-starlette` implementation nor captured qualified wire output. It therefore cannot prove that this transport necessarily discards those events, or that discard happens before the independently proven consumer mismatches can surface. The two definite-discard clauses overclaim the available evidence and conflict with the contract's own unqualified-wire framing. This is Important because a frozen baseline may turn that asserted mechanism into an unsupported later oracle or repair target. The preservation action is to retain the proven producer/consumer mismatches while changing the transport consequence to an explicitly unqualified outcome until a pinned implementation or qualified wire artifact is admitted by a later step.

No second Confirmed, Important, or Major finding was identified.

## Independent census and closure checks

- Inventory and boundary census: 20 components; 18 public behaviors, PB-001 through PB-018; 16 persisted targets represented by 17 records; 13 integrations; 5 journeys; and 18 populated preservation boundaries. All boundary preservation text, replace-or-gap text, and source locator sets are nonempty.
- Persisted-data classification: the 17 records comprise 12 application-owned and 4 external read-only targets, with one target intentionally split into two records; 10 are current-writable and 2 are latent-writable. Target-to-record membership, locator unions, boundary unions, ownership, mutability, and path semantics close exactly.
- Gap and requirement closure: 35 unique gaps cover the current partial/planned requirement set and cite 45 unique requirements. All 35 set `countsAsPassingBaseline` to false. Later-step references resolve to checklist steps; the unscheduled approval items close to the pending APP-007, APP-008, and APP-009 decisions. Current dispositions remain preserve, so no planned behavior is presented as an unchanged-product pass.
- Lanes, environments, and artifacts: all 14 qualification lanes match the trace test catalog by lane and owner step; all 5 supported environments and all 4 artifacts are reciprocally linked where the schema defines reciprocal ownership. The blocked Windows and self-hosted readiness entries remain later-step blockers and are not presented as provisioned baseline capability.
- Fixture census: data has 17 records, oracles 28, protocol 15, and resources 11. IDs are unique and all referenced boundary, lane, requirement, behavior, component, integration, journey, artifact, data, and gap IDs resolve.
- Traceability: 352 entries include 114 CURRENT entries and a 158-row test catalog. Every source path is in the review closure, every normalized line range is valid, and every recomputed `sourceTextSha256` matches. All 1,499 checklist/design/UI anchor references resolve. Test, lane, behavior, requirement, and owner-step references close without orphaned IDs.
- CURRENT records digest: independently sorted and serialized per the declared normalized-record method, the 114 unique CURRENT records produce `fdd77a96813a3d8d5270e47a803486cac64eff33e2f8426d97f1200240423f7b`, exactly matching the specification.
- Source locators and reciprocal links: 215 specification locator references covering 92 unique source locations resolve inside the allowlist, including valid anchors. Data, journey, artifact, lane, gap, and oracle reciprocal sets close exactly. Component and integration references are valid one-way references because those inventory records do not define boundary-ID back-links.
- Product roots: the declared ordinal-path record method independently yields 94 included files, 6,288,961 bytes, and digest `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb` for `src/AemeathDesktopPet/**`; it yields 46 included files, 111,640 bytes, and digest `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae` for `python-backend/aemeath_agent/**`. The exclusions for build/cache artifacts were applied before hashing.
- Resource truth: all 11 raw byte counts and SHA-256 values match production. The nine GIFs have matching dimensions and frame counts: ordinary character GIFs are 200x200, `listening_music.gif` is 1000x1000, and `seal.gif` is 300x250; frame counts are 8, 7, 7, 8, 37, 16, 8, 25, and 4 in fixture order. Tray-icon and theme byte identities match. Preload, mapping/fallback, packaging, merge, and icon-use statuses agree with production.
- Data truth: settings/defaults/position, stats nonidentity and decay, bounded message history, latent memory writers, observation purge, run registry, conditional checkpoint behavior, Chroma collections, todo schema, activity SQLite read-only tables, environment file, music extensions, and RAG path/extension rules agree with the code. The imported SQLite LangGraph checkpointer remains absent from `pyproject.toml`, so the dependency-manifest gap is correctly preserved.
- Oracle and statistics truth: XAML geometries, eight settings tabs, zero view automation properties, PerMonitorV2 awareness, stats defaults/deltas/bounds and inclusive offline decay, timer and physics constants, animation frame rates, memory limits, TTL, distillation interval, speech timing/ranges, ports, loopback/no-auth behavior, MCP protocol/stdio state, and relational randomness claims match the allowed production sources.
- Protocol truth: agent request/response shape, SSE producer payloads, desktop consumer expectations, internal bridge routes, STT and vision shapes, health behavior, and MCP state match the static sources. The tool-name and missing-error-handler mismatches are real. Only the definite transport-discard mechanism described in I-01 is unsupported.
- D0.4 closure: the D0.4 manifest normalized-text digest is `3747f8520497b65544ef0cd1bb386b8e72866284001da408de111f454f0d614a`, matching the readiness document's `riskManifestSha256`. All 12 capability contracts, owner steps, first blockers, states, and the 5-ready/7-blocked/0-pending summary agree. The blocked-environment interpretation is conservative and does not imply provisioning.
- Release locator: `.github/workflows/release.yml` is the exact workflow path and contains the Windows release build/publish job referenced by the contract.
- Validator portability: static Windows PowerShell 5.1 parsing completed with zero parser errors for the validator and module. Read-only inspection found explicit OS-sensitive comparison, separator, and path-join handling and no PowerShell-7-only syntax in the required path. The Ubuntu `pwsh` 7.4+ branch is statically portable under the declared contract; no validator, module function, project, or test was executed, so this is a capability inspection rather than a runtime qualification claim.

## Bound inputs

- BINDING path=docs/verification/preservation-spec-v3.yml kind=preservation-specification hash=SHA-256 bytes=167080 count=1 digest=c0c4b90e9d65a46e6e297d928cbe805e802ba86b265cfdb46cb6766d76078f4f
- BINDING path=docs/verification/manifests/P0A.1-v7.yml kind=risk-lane-manifest hash=SHA-256 bytes=15255 count=1 digest=6944c536c8c804e4a7e790c97442d9aba27e17dc0d5f112c3997eab02ba0ebef
- BINDING path=docs/verification/traceability-v2.yml kind=traceability hash=SHA-256 bytes=478168 count=352 digest=28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415
- BINDING path=tests/fixtures/preservation/v1/data-v5.json kind=data-fixture hash=SHA-256 bytes=41016 count=17 digest=4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0
- BINDING path=tests/fixtures/preservation/v1/oracles-v1.json kind=oracle-fixture hash=SHA-256 bytes=7954 count=28 digest=4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d
- BINDING path=tests/fixtures/preservation/v1/protocol-v3.json kind=protocol-fixture hash=SHA-256 bytes=17433 count=15 digest=cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565
- BINDING path=tests/fixtures/preservation/v1/resources-v1.json kind=resource-fixture hash=SHA-256 bytes=3167 count=11 digest=63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8
- BINDING path=python-backend/pyproject.toml kind=source-file hash=SHA-256 bytes=1266 count=1 digest=7cb128bcda68eb2b5e890c0c390c0c4f46f6a24c474d8753ce904416ef10463d
- BINDING path=.github/workflows/release.yml kind=source-file hash=SHA-256 bytes=1324 count=1 digest=066dd7244e6ac12bd350500cbe6ee1f7dd34eee40ef5b7b851e67abf161f7fe9
- BINDING path=tools/verification/Test-PreservationSpecification.ps1 kind=validator hash=SHA-256 bytes=163541 count=1 digest=f727e05673767e6bc807c31dd9641f544dcb9645807282d3d1f58e0b5b3c3991
- BINDING path=tools/ci/CiDeliveryContract.psm1 kind=validator-module hash=SHA-256 bytes=23981 count=1 digest=85cd1c770b5be08737d8045b64a1d60d11b003f235fc732f1ffe7f15aeba19f3
- BINDING path=docs/verification/manifests/D0.4-v3.yml kind=capability-manifest hash=SHA-256 bytes=10381 count=1 digest=d8b763acaa04088f5f8b47b79d956deea8f9898b74d543004938d4cd3d642d2e
- BINDING path=docs/verification/environments/D0.4-readiness-v1.json kind=capability-readiness hash=SHA-256 bytes=12132 count=1 digest=aafcdc4919239c0bb239f15b61c7b757c665e3649cda04e114b203e67eb813bc
- BINDING path=src/AemeathDesktopPet/** kind=production-root hash=SHA-256 bytes=6288961 count=94 digest=28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb
- BINDING path=python-backend/aemeath_agent/** kind=production-root hash=SHA-256 bytes=111640 count=46 digest=98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae

The six requested delivery identities were independently recomputed and match exactly: specification `c0c4b90e9d65a46e6e297d928cbe805e802ba86b265cfdb46cb6766d76078f4f`; P0A.1 manifest `6944c536c8c804e4a7e790c97442d9aba27e17dc0d5f112c3997eab02ba0ebef`; traceability `28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415`; DATA-V5 `4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0`; protocol-v3 `cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565`; validator `f727e05673767e6bc807c31dd9641f544dcb9645807282d3d1f58e0b5b3c3991`.

## Source closure and exposure accounting

Repository reads were confined to these 21 authorized sources:

1. `REQUIREMENTS.md`
2. `docs/prd/jarvis_assistant_prd.md`
3. `docs/design/jarvis_assistant_design.md`
4. `docs/ui-spec/jarvis_assistant_ui_spec.md`
5. `docs/plans/20260722-jarvis-assistant-tdd-checklist.md`
6. `docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md`
7. `docs/verification/traceability-v2.yml`
8. `docs/verification/manifests/P0A.1-v7.yml`
9. `src/AemeathDesktopPet/**`
10. `python-backend/aemeath_agent/**`
11. `tests/fixtures/preservation/v1/data-v5.json`
12. `tests/fixtures/preservation/v1/oracles-v1.json`
13. `tests/fixtures/preservation/v1/protocol-v3.json`
14. `tests/fixtures/preservation/v1/resources-v1.json`
15. `docs/verification/preservation-spec-v3.yml`
16. `python-backend/pyproject.toml`
17. `.github/workflows/release.yml`
18. `tools/verification/Test-PreservationSpecification.ps1`
19. `tools/ci/CiDeliveryContract.psm1`
20. `docs/verification/manifests/D0.4-v3.yml`
21. `docs/verification/environments/D0.4-readiness-v1.json`

The platform required one external skill read at `C:\Users\Ricky\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\using-superpowers\SKILL.md`. It is outside the repository and is neither repository evidence nor legacy evidence; it contributed no product claim.

There was no accidental exposure. No test implementation under either prohibited test tree, predecessor fixture/specification/manifest, prior evidence file, Git metadata/history/status/diff, network source, or original-repository file was read. The output evidence path was treated as write-only. Static parsing and byte/hash calculations were read-only; no project, validator, validator-module function, or test execution occurred.

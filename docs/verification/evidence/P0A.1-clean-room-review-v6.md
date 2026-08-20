# P0A.1 clean-room preservation review v6

- Reviewer assignment: `clean-room-preservation-reviewer-05`

- Legacy exposure: `unexposed`

- Verdict: **PASS**

- Finding census: **C=0, I=0, M=0**

## Scope and method

This was an independent, static, read-only review of the exact 21-item repository allowlist. No predecessor specification, predecessor manifest, predecessor fixture, legacy test source, prior evidence, Git metadata, network resource, project, test suite, or full validator was read or executed. The validator and delivery module were inspected only through source reading and PowerShell AST parsing.

The platform required two non-repository, non-legacy skill reads: `C:\Users\Ricky\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\using-superpowers\SKILL.md` and `C:\Users\Ricky\.codex\plugins\cache\openai-curated-remote\superpowers\6.3.0\skills\verification-before-completion\SKILL.md`. The first skill's subagent instruction required the dispatched reviewer to ignore it; the second required fresh verification evidence before the completion claim. Neither supplied a repository or product oracle.

The repository read set was exactly:

- `REQUIREMENTS.md`
- `docs/prd/jarvis_assistant_prd.md`
- `docs/design/jarvis_assistant_design.md`
- `docs/ui-spec/jarvis_assistant_ui_spec.md`
- `docs/plans/20260722-jarvis-assistant-tdd-checklist.md`
- `docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md`
- `docs/verification/traceability-v2.yml`
- `docs/verification/manifests/P0A.1-v8.yml`
- `src/AemeathDesktopPet` recursively, limited to its 94 production-root records
- `python-backend/aemeath_agent` recursively, limited to its 46 production-root records
- `tests/fixtures/preservation/v1/data-v5.json`
- `tests/fixtures/preservation/v1/oracles-v1.json`
- `tests/fixtures/preservation/v1/protocol-v3.json`
- `tests/fixtures/preservation/v1/resources-v1.json`
- `docs/verification/preservation-spec-v4.yml`
- `python-backend/pyproject.toml`
- `.github/workflows/release.yml`
- `tools/verification/Test-PreservationSpecification.ps1`
- `tools/ci/CiDeliveryContract.psm1`
- `docs/verification/manifests/D0.4-v3.yml`
- `docs/verification/environments/D0.4-readiness-v1.json`

## Review result

The raw SHA-256 identities for preservation-spec-v4, P0A.1-v8, traceability-v2, DATA-V5, protocol-v3, and the validator match the assigned exact values. All six normalized source hashes match their declarations. The trace has 352 entries, including 114 CURRENT entries; its independently reconstructed CURRENT disposition-record digest is `fdd77a96813a3d8d5270e47a803486cac64eff33e2f8426d97f1200240423f7b`.

The specification closes over PB-001 through PB-018, 20 components, 18 public behaviors, 16 persisted targets represented by 17 records, 13 integration boundaries, five Windows journeys, 14 qualification lanes, five supported environments, four artifacts, 28 oracles, 15 protocol contracts, 11 resources, and 35 known gaps. Identifier references are unique and closed. Persisted-data, journey, oracle, artifact, and gap links are reciprocal. All 92 unique source locators remain inside the review allowlist, their paths exist, and their Markdown anchors resolve to the named headings. The 34 specification, manifest, probe, and trace requirement sets agree; their selected trace entries cover exactly PB-001 through PB-018 and carry the P0A.1/V-STATIC backlinks. Every CURRENT Partial or Planned non-acceptance requirement has gap coverage, and every later-step or pending-approval locator is present in the checklist.

Independent production-root aggregation produced 94 files, 6,288,961 bytes, and digest `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb` for the desktop root; and 46 files, 111,640 bytes, and digest `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae` for the Python root. All 11 resource byte lengths and raw hashes match; independent GIF decoding also matches every declared dimension and frame count.

The data, literal, geometry, timing, statistics, route, dependency, release, and protocol assertions agree with production source. The missing `langgraph-checkpoint-sqlite` dependency is explicitly retained as a non-passing gap, and the release locator is the exact release workflow file. D0.4 closes by normalized identity: the D0.4 manifest raw hash is distinct from, while its checkbox/EOL-normalized hash exactly equals, the readiness record's bound hash; all 12 capability records normalize to five ready and seven blocked states, and no hosted observation is represented as interactive-worker provisioning.

The SSE framing claim is limited to already-framed producer input, an unpinned `sse-starlette>=2.0.0` dependency, unfrozen wire bytes, and unqualified compatibility. The tool-call gap asserts only the production-verifiable `content` versus `data.name` static shape mismatch. The error gap asserts only producer event type `error` and the absence of a consumer handler. Neither statement claims a determined wire outcome or definite discard.

PowerShell AST parsing reports zero syntax errors for both verification sources. Static inspection supports Windows PowerShell 5.1 and pwsh 7.4+ portability for the declared command while correctly retaining full validation, project execution, legacy access, and network access as disallowed before green.

## Exact bindings

- BINDING path=docs/verification/preservation-spec-v4.yml kind=preservation-specification hash=SHA-256 bytes=167193 count=1 digest=874471015a03853b8fbffdd9350f631286d8ccb4d53b9cae4114448b5d260bc3
- BINDING path=docs/verification/manifests/P0A.1-v8.yml kind=risk-lane-manifest hash=SHA-256 bytes=14901 count=1 digest=7bc93dc23f961fbe183eeeaa32b6e01acf0707e041ed3fb4d7217231d7ed16b0
- BINDING path=docs/verification/traceability-v2.yml kind=traceability hash=SHA-256 bytes=478168 count=352 digest=28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415
- BINDING path=tests/fixtures/preservation/v1/data-v5.json kind=data-fixture hash=SHA-256 bytes=41016 count=17 digest=4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0
- BINDING path=tests/fixtures/preservation/v1/oracles-v1.json kind=oracle-fixture hash=SHA-256 bytes=7954 count=28 digest=4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d
- BINDING path=tests/fixtures/preservation/v1/protocol-v3.json kind=protocol-fixture hash=SHA-256 bytes=17433 count=15 digest=cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565
- BINDING path=tests/fixtures/preservation/v1/resources-v1.json kind=resource-fixture hash=SHA-256 bytes=3167 count=11 digest=63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8
- BINDING path=python-backend/pyproject.toml kind=source-file hash=SHA-256 bytes=1266 count=1 digest=7cb128bcda68eb2b5e890c0c390c0c4f46f6a24c474d8753ce904416ef10463d
- BINDING path=.github/workflows/release.yml kind=source-file hash=SHA-256 bytes=1324 count=1 digest=066dd7244e6ac12bd350500cbe6ee1f7dd34eee40ef5b7b851e67abf161f7fe9
- BINDING path=tools/verification/Test-PreservationSpecification.ps1 kind=validator hash=SHA-256 bytes=165815 count=1 digest=2db7f71cf88b867d706e66a8dc5690ce5df60277d6f4f0c397fdd8d0b3d11f62
- BINDING path=tools/ci/CiDeliveryContract.psm1 kind=validator-module hash=SHA-256 bytes=23981 count=1 digest=85cd1c770b5be08737d8045b64a1d60d11b003f235fc732f1ffe7f15aeba19f3
- BINDING path=docs/verification/manifests/D0.4-v3.yml kind=capability-manifest hash=SHA-256 bytes=10381 count=1 digest=d8b763acaa04088f5f8b47b79d956deea8f9898b74d543004938d4cd3d642d2e
- BINDING path=docs/verification/environments/D0.4-readiness-v1.json kind=capability-readiness hash=SHA-256 bytes=12132 count=1 digest=aafcdc4919239c0bb239f15b61c7b757c665e3649cda04e114b203e67eb813bc
- BINDING path=src/AemeathDesktopPet kind=production-root hash=SHA-256 bytes=6288961 count=94 digest=28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb
- BINDING path=python-backend/aemeath_agent kind=production-root hash=SHA-256 bytes=111640 count=46 digest=98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae

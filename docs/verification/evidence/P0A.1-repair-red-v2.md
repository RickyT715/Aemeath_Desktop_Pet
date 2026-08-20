# P0A.1 focused repair RED v2

- Step: `P0A.1`
- Date: `2026-08-20`
- Verdict: **EXPECTED RED CONFIRMED**
- Production baseline: `43f9c288f843f7620ffee5eee3504f52875f4774`
- Product-source changes: **none**

## Immutable authority chain

- Manifest v1: `docs/verification/manifests/P0A.1-v1.yml` = `2c373ca1671c65cd7c4bed70af3aa10de08df0f9450ed8b2d7c4d2eeb1c25dbd`
- v1 invalidation: `docs/verification/invalidations/P0A.1-v1.json` = `cd9486b7227b0ca99f137a7cd28c75c4903cc0a840bab911517cbe51fcfe6221`
- Manifest v2: `docs/verification/manifests/P0A.1-v2.yml` = `60ae0b97ae95444b76ad064428801ed6988f7b2fcbdd5bccdfd69b5582d83d4e`
- v2 invalidation: `docs/verification/invalidations/P0A.1-v2.json` = `881fc5fe9f57c95826aa5e76322378b4a8fa8f0b3b0761612cc62f8095ecbea7`
- Manifest v3: `docs/verification/manifests/P0A.1-v3.yml` = `70e3247afb5fe77009221148a28fd5a2d1f16117e75416612fea9ce6a657bc29`
- Traceability predecessor: `docs/verification/traceability-v1.yml` = `a9714e9b4d1d4609155d13569239ca1396ac1077f444e8bacb795c4c4073d031`
- Preservation-spec predecessor: `docs/verification/preservation-spec-v1.yml` = `fa29076f523de5fff1a339b0c36498ff490f9e2ed7220ced29f82dfb500ff7d0`

The frozen v2 bytes were restored after independent review identified an in-place manifest correction. The truthful RED oracle was versioned as v3; no frozen manifest was overwritten.

## Frozen repaired fixtures

- `tests/fixtures/preservation/v1/data-v1.json` = `fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa` (7 records)
- `tests/fixtures/preservation/v1/oracles-v1.json` = `4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d` (28 records)
- `tests/fixtures/preservation/v1/protocol-v1.json` = `95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312` (15 records)
- `tests/fixtures/preservation/v1/resources-v1.json` = `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8` (11 records)

The position, stats, and SSE records are corrected RED inputs. They are expected to pass their semantic checks; the predecessor specification must fail because it does not bind and cover those inputs truthfully.

## Traceability focused RED

- Validator: `tools/verification/Test-VerificationContracts.ps1` = `14ad9cb3f035a93fccff52156a063dabc148f0ebc9bab6c279e13be9975cf01c`
- Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verification\Test-VerificationContracts.ps1`
- Tool chunk: `d05ad2`
- Exit code: `1`
- Wall time: `3.5752189s`
- First output: `PASS Draft 2020-12 traceability schema`
- Stable diagnostic: `TRACE-GATE0-LANE-BEHAVIOR`
- Rejected rows: `P0A.6-V-WPF-WPF-STATE`, `P0A.7-V-UIA-UIA-JOURNEY`, and `P0A.6-V-ACCESS-ACCESSIBILITY-JOURNEY`
- Aggregate throw location: validator line 915 at that frozen identity

The response output bytes were not separately persisted; this evidence therefore records the tool-return metadata and the mechanically observed diagnostic census without claiming a raw transcript hash.

## Preservation-specification focused RED

- Validator: `tools/verification/Test-PreservationSpecification.ps1` = `57a9534ced35be3ca6d29c51a88654ee43c041b25fa4d204261e1dfd5909fabc`
- Pre-run identity gate: chunk `8ed0f4`, exit `0`, wall `0.1383069s`, `PREHASH PASS 12/12`
- Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verification\Test-PreservationSpecification.ps1`
- Tool chunk: `bcdfb9`
- Exit code: `1`
- Wall time: `1.7420311s`
- Terminal error: `[P0A1-SPEC-INVALID]`
- Post-run identity gate: `POSTHASH PASS 12/12`

The aggregate contained these 17 unique diagnostics in order:

1. `P0A1-SPEC-SHAPE`
2. `P0A1-MANIFEST-BINDING`
3. `P0A1-LANE-BEHAVIOR`
4. `P0A1-SOURCE-METHOD`
5. `P0A1-SOURCE-HASH`
6. `P0A1-BASELINE-IDENTITY`
7. `P0A1-PRODUCTION-ROOT-METHOD`
8. `P0A1-FIXTURE-HASH`
9. `P0A1-ARTIFACT-LINK`
10. `P0A1-LANE-DECISION`
11. `P0A1-ENVIRONMENT-COVERAGE`
12. `P0A1-GAP-COVERAGE`
13. `P0A1-GAP-CONTRACT`
14. `P0A1-PROVENANCE-COVERAGE`
15. `P0A1-CLEAN-REVIEWER`
16. `P0A1-CLEAN-REVIEW-EVIDENCE`
17. `P0A1-BOUNDARY-LINK`

`P0A1-POSITION-CANARY`, `P0A1-STATS-LITERAL`, and `P0A1-SSE-TRUTH` were absent, as required for the corrected live fixture bytes.

## Product identity and scope

- `src/AemeathDesktopPet`: 94 files; tree digest `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb`
- `python-backend/aemeath_agent`: 46 files; tree digest `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae`
- Validator input identities remained unchanged across the focused execution: 12/12.
- No product source, legacy test, Git state, network resource, or external service was mutated by either RED execution.

## TDD decision

The RED is accepted. GREEN work is limited to regenerating the three corrected traceability lane rows, updating the preservation specification and reciprocal links to the frozen v3/fixture contracts, and producing a new independently derived clean-room review. Product behavior and legacy tests remain outside this step.

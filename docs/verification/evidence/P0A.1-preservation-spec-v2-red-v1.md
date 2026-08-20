# P0A.1 preservation-spec-v2 focused RED evidence v1

## Verdict

- Result: `EXPECTED RED`
- Child exit code: `1`
- Timed out: `false`
- Bound objects unchanged: `true`
- This run validates only the reviewed preservation-spec-v2 successor contract against the immutable v1 predecessor. It is not P0A.1 GREEN evidence.

## Frozen execution identity

- Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools\verification\Test-PreservationSpecification.ps1"`
- Working directory: `D:\Study\Project\Aemeath_Desktop_Pet_worktrees\jarvis-tdd`
- Child wall time: `1665 ms`
- Timeout bound: `150000 ms`
- Capture tool chunk: `1d27aa`
- Capture tool wall time: `1.8161458 s`
- Capture wrapper exit code: `0`
- The wrapper performed no filesystem writes. It redirected both child streams in memory, encoded the captured .NET strings as UTF-8 without BOM, and compared thirteen pre/post file hashes.

## Pre-execution bindings

| Artifact | SHA-256 |
|---|---|
| `tools/verification/Test-PreservationSpecification.ps1` | `ea580d03589109c8fdbff98261494c5d89a98ff6f1c2852b28b7444cc5d0da4d` |
| `docs/verification/preservation-spec-v1.yml` | `9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d` |
| `docs/verification/manifests/P0A.1-v5.yml` | `17f262ff6f2e9c038ce3001b554080b5e39c3e6bb4428ee02b5d47e890c8da91` |
| `docs/verification/invalidations/P0A.1-v1.json` | `cd9486b7227b0ca99f137a7cd28c75c4903cc0a840bab911517cbe51fcfe6221` |
| `docs/verification/invalidations/P0A.1-v2.json` | `881fc5fe9f57c95826aa5e76322378b4a8fa8f0b3b0761612cc62f8095ecbea7` |
| `docs/verification/invalidations/P0A.1-v3.json` | `e5c1add435b63e227a82837fd837b72d2f7c2df935cee5e6127b7e8ac9b71a10` |
| `docs/verification/invalidations/P0A.1-v4.json` | `de56c2b3c183df68b2a3d4f27f250c20ef158a39dc46180cca3bddbcd8078724` |
| `docs/verification/traceability-v2.yml` | `28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415` |
| `docs/verification/traceability-v1.yml` | `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55` |
| `tests/fixtures/preservation/v1/data-v5.json` | `4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0` |
| `tests/fixtures/preservation/v1/oracles-v1.json` | `4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d` |
| `tests/fixtures/preservation/v1/protocol-v1.json` | `95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312` |
| `tests/fixtures/preservation/v1/resources-v1.json` | `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8` |

Before semantic validation, the validator also checked six normalized source hashes and both production-root identities. Those checks passed. The two roots remained `94 / 28d3d397...13dfb` and `46 / 98a46adb...b5ae`.

## Captured streams

### stdout

- Characters: `0`
- UTF-8 bytes: `0`
- SHA-256: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- Exact JSON string literal: `""`

### stderr

- Characters: `1368`
- UTF-8 bytes: `1368`
- SHA-256: `9ffd836f95833a9121b0a80c359bce4564e885646e7f9b3339db9d21b9023b10`
- The exact captured JSON string literal is below. `\r\n` denotes the original CRLF characters; doubled backslashes are JSON escaping for the Windows path.

```json
"[P0A1-SPEC-INVALID] Frozen preservation specification failed: P0A1-SPEC-SHAPE, P0A1-SPEC-IDENTITY, P0A1-SPEC-PREDECESSO\r\nR, P0A1-MANIFEST-BINDING, P0A1-DATA-TARGET-COVERAGE, P0A1-DATA-TARGET-CONTRACT, P0A1-TRACEABILITY-SHAPE, P0A1-REQMAP, P\r\n0A1-TRACE-OWNER, P0A1-ARTIFACT-COVERAGE, P0A1-FIXTURE-HASH, P0A1-LANE-DECISION, P0A1-ENVIRONMENT-SHAPE, P0A1-GAP-CONTRA\r\nCT, P0A1-CLEAN-REVIEWER, P0A1-CLEAN-REVIEW-EVIDENCE, P0A1-BOUNDARY-LINK, P0A1-BOUNDARY-DATA-LINK.\r\nAt D:\\Study\\Project\\Aemeath_Desktop_Pet_worktrees\\jarvis-tdd\\tools\\verification\\Test-PreservationSpecification.ps1:2779\r\n char:5\r\n+     throw \"[P0A1-SPEC-INVALID] Frozen preservation specification fail ...\r\n+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r\n    + CategoryInfo          : OperationStopped: ([P0A1-SPEC-INVA...DARY-DATA-LINK.:String) [], RuntimeException\r\n    + FullyQualifiedErrorId : [P0A1-SPEC-INVALID] Frozen preservation specification failed: P0A1-SPEC-SHAPE, P0A1-SPEC \r\n   -IDENTITY, P0A1-SPEC-PREDECESSOR, P0A1-MANIFEST-BINDING, P0A1-DATA-TARGET-COVERAGE, P0A1-DATA-TARGET-CONTRACT, P0A  \r\n  1-TRACEABILITY-SHAPE, P0A1-REQMAP, P0A1-TRACE-OWNER, P0A1-ARTIFACT-COVERAGE, P0A1-FIXTURE-HASH, P0A1-LANE-DECISION   \r\n , P0A1-ENVIRONMENT-SHAPE, P0A1-GAP-CONTRACT, P0A1-CLEAN-REVIEWER, P0A1-CLEAN-REVIEW-EVIDENCE, P0A1-BOUNDARY-LINK,     \r\nP0A1-BOUNDARY-DATA-LINK.\r\n \r\n"
```

PowerShell's native error formatter wraps identifiers in both the initial diagnostic and the final error record. Reading the initial diagnostic before the stack text yields exactly these eighteen unique semantic codes, in order:

1. `P0A1-SPEC-SHAPE`
2. `P0A1-SPEC-IDENTITY`
3. `P0A1-SPEC-PREDECESSOR`
4. `P0A1-MANIFEST-BINDING`
5. `P0A1-DATA-TARGET-COVERAGE`
6. `P0A1-DATA-TARGET-CONTRACT`
7. `P0A1-TRACEABILITY-SHAPE`
8. `P0A1-REQMAP`
9. `P0A1-TRACE-OWNER`
10. `P0A1-ARTIFACT-COVERAGE`
11. `P0A1-FIXTURE-HASH`
12. `P0A1-LANE-DECISION`
13. `P0A1-ENVIRONMENT-SHAPE`
14. `P0A1-GAP-CONTRACT`
15. `P0A1-CLEAN-REVIEWER`
16. `P0A1-CLEAN-REVIEW-EVIDENCE`
17. `P0A1-BOUNDARY-LINK`
18. `P0A1-BOUNDARY-DATA-LINK`

No nineteenth semantic diagnostic was emitted. The outer `P0A1-SPEC-INVALID` code is the reviewed aggregate wrapper and is not counted as a semantic successor diagnostic.

## Post-execution identity gate

All thirteen pre-execution SHA-256 values above were recomputed after child exit and matched exactly. `boundObjectsUnchanged` was `true`.

The validator stopped at the semantic predecessor failure. It did not enter any of the seven GREEN mutation controls, did not emit a discovery marker, and did not invoke Git. It did not run product code, legacy tests, network operations, or external services.

## TDD interpretation

The immutable v1 predecessor is now observably RED against the reviewed v2 preservation contract. GREEN must preserve this evidence and create a separately versioned `preservation-spec-v2.yml`; it must not rewrite v1 bytes to erase the failure.

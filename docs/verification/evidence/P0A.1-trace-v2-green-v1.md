# P0A.1 traceability-v2 GREEN evidence v1

## Verdict

- Result: `PASS / GREEN`
- Child exit code: `0`
- Timed out: `false`
- Bound objects unchanged: `true`
- Discovery: `27` semantic probes; frozen D0.3 minimum `24`
- Discovery marker source SHA: `43f9c288f843f7620ffee5eee3504f52875f4774`

## Frozen execution identity

- Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools\verification\Test-VerificationContracts.ps1"`
- Working directory: `D:\Study\Project\Aemeath_Desktop_Pet_worktrees\jarvis-tdd`
- Child wall time: `29206 ms`
- Capture tool chunk: `b5d241`
- Capture tool wall time: `29.3624118 s`
- Capture wrapper exit code: `0`
- The wrapper performed no filesystem writes. The validator used its reviewed OS-temp regeneration/schema controls, removed them in `finally`, and used read-only `git rev-parse` for the final discovery marker.

## Pre-execution bindings

| Artifact | SHA-256 |
|---|---|
| `docs/verification/traceability-v1.yml` | `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55` |
| `docs/verification/traceability-v2.yml` | `28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415` |
| `tools/verification/New-Traceability.ps1` | `7eb8aa8e37cde2100ed03f245c1114d54149b76088107ff106271fb60654fc77` |
| `tools/verification/Test-VerificationContracts.ps1` | `d3cf236133256b43e72d8bab15e50b21c6aa36d9bd18e13ece02613290f4c7e8` |
| `docs/verification/evidence/P0A.1-trace-v2-red-v1.md` | `8a9820ab6bc62f27319e6b73e441b4279a3c4f20dae53fd91fd877e082b93dbb` |

## Captured streams

The capture wrapper encoded each .NET stream string as UTF-8 without BOM. The JSON string literal below is the lossless escaped stdout representation.

### stdout

- UTF-8 bytes: `2012`
- SHA-256: `cc08c0149f1eb44e67be01be167c75e41d7f72768c33f29ed955f0b914b7fcba`
- Exact JSON string literal:

```json
"PASS Draft 2020-12 traceability schema\nPASS semantic traceability baseline (352 requirements, 158 stable planned tests/probes)\nPASS canonical traceability regeneration in the current engine\nPASS known-bad fixture: missing-requirement -> TRACE-MISSING-ID\nPASS known-bad fixture: duplicate-requirement -> TRACE-DUPLICATE-ID\nPASS known-bad fixture: stale-source-hash -> TRACE-STALE-SOURCE-HASH\nPASS known-bad fixture: stale-entry-hash -> TRACE-STALE-ENTRY-HASH\nPASS known-bad fixture: invalid-disposition -> TRACE-INVALID-DISPOSITION\nPASS known-bad fixture: orphan-test -> TRACE-ORPHAN-TEST\nPASS known-bad fixture: orphan-acceptance-criterion -> TRACE-ORPHAN-AC\nPASS known-bad fixture: bare-nfr-reference -> TRACE-BARE-NFR\nPASS schema-valid example with cross-field semantics: docs/verification/examples/risk-lane-manifest-v1.example.json\nPASS schema-valid example with cross-field semantics: docs/verification/examples/evidence-manifest-v1.example.json\nPASS schema-valid example with cross-field semantics: docs/verification/examples/exact-sha-manifest-v1.example.json\nPASS semantic negative risk/lane relationship\nPASS semantic negative phase-evidence contradictions\nPASS semantic negative exact-SHA contradictions\nPASS schema-valid linked manifest: D0.3-v2 (frozen-before-red)\nPASS schema-valid linked manifest: D0.3-v3 (frozen-before-red)\nPASS schema-valid linked manifest: D0.3-v4 (frozen-before-red)\nPASS schema-valid linked manifest: D0.3-v5 (frozen-before-red)\nPASS schema-valid linked manifest: D0.3-v6 (frozen-before-red)\nPASS semantic negative invalidation identity and chronology\nPASS immutable v1-v6 payload and invalidation chain\nPASS v5 frozen-before-red provenance\nPASS v6 exact third-artifact frozen-before-red provenance\nPASS 5 schema-negative controls\nAEMEATH_CI_DISCOVERY_V1={\"schemaVersion\":1,\"resultId\":\"D0.3-V-STATIC-001\",\"sourceSha\":\"43f9c288f843f7620ffee5eee3504f52875f4774\",\"actualDiscovery\":27,\"failed\":0,\"skipped\":0}\r\nVerification contract tests passed (27 semantic probes; minimum 24).\n"
```

### stderr

- UTF-8 bytes: `0`
- SHA-256: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- Exact value: empty string

## Verified behavior

- Draft 2020-12 traceability schema passed.
- The semantic baseline contains `352` requirements, `114` current disposition records, and `158` stable tests/probes.
- Canonical regeneration byte-matched committed `traceability-v2.yml`.
- The eight retained known-bad fixtures were rejected with their expected stable codes.
- Linked D0.3 manifests, invalidation chronology, phase evidence, exact-SHA semantics, and five schema-negative controls passed.
- `PRD:AC-FR-017-01` retains its existing P0B.3e accessibility owner and also has the new P4.5e accessibility owner.

## Post-execution identity gate

All five pre-execution hashes were reproduced exactly after the child exited. In particular, immutable `traceability-v1.yml`, the versioned RED evidence, generator, validator, and generated v2 artifact did not change during verification.

This GREEN closes only the traceability successor subproblem. P0A.1 remains incomplete until preservation-spec-v2, independent clean-room review, the preservation validator, and CI integration are GREEN.

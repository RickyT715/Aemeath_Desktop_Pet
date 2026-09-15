# P0A.1 byte-preservation repair independent review v1

Review date: 2026-08-21

## Verdict

PASS. Static byte-preservation wiring review census: Critical 0, Important 0, Minor 0.

This is a static GO for the reviewed byte-preservation repair. It is not an actual CI PASS. This review did not rerun the P0A.1 preservation validator, any project/build/test command, or the reviewed CI scripts.

## Reviewed state

- `.gitattributes`: 673 bytes, SHA-256 `fa73d6c410bd1c87fa49a7307e7fa1d19c5834c0095edc1ff61e93d659da2d24`, 15 CRLF line endings, no bare LF, no BOM.
- `tools/ci/Test-CiDelivery.ps1`: 103,116 bytes, SHA-256 `842f31124d202bc4558caebeb15b7c1080099b2ee92208de8024f2de02afd1d2`, 2,150 CRLF line endings, no bare LF, no BOM.
- `docs/verification/evidence/P0A.1-exact-sha-ci-attempt-v1.md`: 4,156 bytes, SHA-256 `eeefba6cc5d73b4999e868d67913edc6a78f17d1996ba1eb6ada391ea61a86c0`, 68 CRLF line endings, no bare LF, no BOM, and present in the Git index.

## Independent recomputation

The active `.gitattributes` contains 15 unique non-comment rules. Fourteen are the exact preservation rules asserted by `Assert-PreservationByteAttributes`; the remaining rule is the pre-existing `docs/verification/dependencies/** -text` contract. The baseline has no missing preservation rule. Independently deleting each of the 14 rules from the actual active-line set produced exactly one missing rule, equal by ordinal comparison to the deleted rule, in all 14 cases. The implementation calls the same `Get-MissingPreservationByteRules` helper for both the aggregate assertion and every mutation.

The current protected-path census is:

| Class | Files |
| --- | ---: |
| Preservation specifications | 5 |
| P0A.1 manifests | 9 |
| P0A.1 invalidations | 9 |
| P0A.1 evidence | 19 |
| Traceability files | 2 |
| Preservation fixtures | 10 |
| `src/AemeathDesktopPet` production root | 94 |
| `python-backend/aemeath_agent` production root | 46 |
| Six exact D0.4/module/package/release inputs | 6 |
| Unique total | 200 |

For all 200 paths, independent Git queries returned `text: unset`, `git hash-object --no-filters` equal to filtered `git hash-object`, and the same object ID from `git rev-parse :path`. Mismatch count was zero. No untracked file currently matches any protected glob. The formerly transient `P0A.1-exact-sha-ci-attempt-v1.md` counterexample is closed: its raw, filtered, and index object IDs are all `118bd9f0f01d30ef6ee2a59e8d2426a37ef4949e`.

All 37 fixed raw authorities declared by the P0A.1 validator were independently rehashed; all 37 match their fixed SHA-256 constants. The active clean-room review v7 remains SHA-256 `7869e85fb49790b488b68bebec1ec4eeea7b1dd32695118b520028e5490ae34a`, with raw and index object ID `1b3c3ceeae03b42b080df4df9b65ddb4f1346edb`.

The two production-root identities were independently recomputed with forced recursive enumeration, file and ancestor reparse-point exclusion, `bin`, `obj`, `__pycache__`, `.pytest_cache`, and case-insensitive `.pyc` exclusion, ordinal record sorting, LF record joining, and raw SHA-256 file hashes:

| Root | Files | Bytes | Root SHA-256 |
| --- | ---: | ---: | --- |
| `src/AemeathDesktopPet` | 94 | 6,288,961 | `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb` |
| `python-backend/aemeath_agent` | 46 | 111,640 | `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae` |

These counts and digests exactly match preservation-spec v5. Comparing the 140 staged production blobs to HEAD found 10 byte-identical files, 130 files whose only difference is CRLF versus the formerly filtered LF bytes, and zero files with any other change. No product-source content drift was found.

## False-green, false-block, and portability assessment

The repair is fail-closed at all relevant layers: exact rules must exist; the production enumeration mirrors the validator exclusions; every existing protected file must exist in the index; Git attributes must resolve to unset text; and raw, filtered, and indexed objects must be identical. It does not infer byte safety from rule text alone.

The broad protected globs intentionally include matching untracked working-tree files. Such a file has no index object and therefore blocks the contract until staged or removed from the protected namespace. That behavior caught the transient attempt-report state and is consistent with requiring every file in the declared P0A.1 namespace to have a retained repository object. The reviewed terminal state contains no such untracked file.

The implementation parses without PowerShell syntax errors and uses PowerShell 5-compatible APIs. Forward-slash attribute patterns and Git plumbing commands are portable to Ubuntu/pwsh. Because each protected working-tree object equals its staged object and resolves to `text: unset`, a clean Ubuntu checkout retains the staged bytes rather than applying LF conversion.

## Supplied local execution evidence and limits

The implementation handoff reports fresh `Test-CiDelivery.ps1` chunks `ce7f30` and `948e05`, exit 0, with static/result counts 67/47, and `Test-VerificationContracts.ps1` chunk `a28e14`, exit 0, with counts 27/24. This independent review did not rerun those scripts; the claims above rest on direct source inspection and independent read-only byte, path, attribute, and Git-object recomputation.

This review authorizes treating the byte-preservation repair as static GO for the next CI rerun. It does not claim that CI has passed, does not replace the failed CI-run record, and does not claim a fresh local P0A.1 validator run.

This review file is the post-review output and was not part of the 200-path pre-output census. Because its name is inside the protected P0A.1 evidence namespace, it must be staged before any subsequent `Test-CiDelivery.ps1` or CI run; leaving it untracked would correctly trigger the fail-closed index-object check.

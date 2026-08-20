# P0A.1 preservation specification RED evidence

## Frozen input

- Baseline commit: `43f9c288f843f7620ffee5eee3504f52875f4774`
- Risk manifest: `docs/verification/manifests/P0A.1-v1.yml`
- Risk manifest SHA-256: `2c373ca1671c65cd7c4bed70af3aa10de08df0f9450ed8b2d7c4d2eeb1c25dbd`
- Completeness probe: `tools/verification/Test-PreservationSpecification.ps1`
- Completeness probe SHA-256: `61e3619e2656c12eb88214d6cbc1652c4b16b6b1b36d1ca204a7cd6e7d477202`
- The required `docs/verification/preservation-spec-v1.yml` did not exist before or during this run.

The manifest, four canary fixtures, and the probe passed two independent read-only pre-RED reviews with no Critical, Important, or Minor findings. The reviews confirmed that the failure path precedes module import, fixture loading, production-tree scanning, and discovery-marker emission.

## Command and observed RED

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verification\Test-PreservationSpecification.ps1
```

- Captured tool chunk: `a60ddc`
- Wall time: `0.3489099` seconds
- Exit code: `1`
- First diagnostic:

```text
[P0A1-SPEC-MISSING] Missing frozen preservation specification at docs/verification/preservation-spec-v1.yml.
```

This is the manifest's frozen RED oracle. No other P0A.1 diagnostic, PASS record, or discovery marker was emitted.

## Unchanged-production guard

The RED run did not execute product code, legacy tests, providers, sidecars, network operations, or Git. The deterministic production roots remained:

| Root | Files | SHA-256 |
|---|---:|---|
| `src/AemeathDesktopPet` | 94 | `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb` |
| `python-backend/aemeath_agent` | 46 | `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae` |

The digest input is each root's regular files as `relative/path|byteCount|lowercaseRawSha256`, sorted with `StringComparer.Ordinal`, joined with LF and no trailing LF, then SHA-256 hashed as UTF-8 without BOM. Generated `bin`, `obj`, `__pycache__`, `.pytest_cache`, and `.pyc` paths are excluded.

## TDD decision

RED is accepted. The next permitted change is the new preservation specification and its documentation-truth review evidence. Production source and legacy test sources remain out of scope.

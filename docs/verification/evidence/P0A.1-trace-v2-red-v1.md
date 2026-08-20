# P0A.1 traceability-v2 focused RED evidence v1

## Verdict

- Result: `EXPECTED RED`
- Child exit code: `1`
- Timed out: `false`
- Bound objects unchanged: `true`
- This run validates only the traceability-v2 successor contract. It is not P0A.1 GREEN evidence.

## Frozen execution identity

- Command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools\verification\Test-VerificationContracts.ps1"`
- Working directory: `D:\Study\Project\Aemeath_Desktop_Pet_worktrees\jarvis-tdd`
- Child wall time: `3323 ms`
- Capture tool chunk: `0414ac`
- Capture tool wall time: `3.47816 s`
- Capture wrapper exit code: `0`
- The wrapper performed no filesystem writes. It redirected the child process streams in memory, hashed their UTF-8 bytes, and compared four pre/post file hashes.

## Pre-execution bindings

| Artifact | SHA-256 |
|---|---|
| `docs/verification/traceability-v1.yml` | `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55` |
| `docs/verification/preservation-spec-v1.yml` | `9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d` |
| `docs/verification/manifests/P0A.1-v4.yml` | `f6b06092f7070c8c9ef8a02c7465e9397adafc3189cf150b779fafd022b51609` |
| `tools/verification/Test-VerificationContracts.ps1` | `93aa8b665e26b0ccc2faddbfc062b8bb8d3009da453201789210491cb54a102a` |

## Captured streams

The capture wrapper encoded each .NET string as UTF-8 without BOM. The JSON string literals below are a lossless escaped representation of the captured strings; `\n` and `\r\n` are literal escape sequences describing the original line endings.

### stdout

- UTF-8 bytes: `39`
- SHA-256: `1cd94541b5612da27597a08b8c4523f9de8259815353cca05d3aa848952ab50d`
- Exact JSON string literal:

```json
"PASS Draft 2020-12 traceability schema\n"
```

### stderr

- UTF-8 bytes: `1720`
- SHA-256: `cb0aa7fd02f863095fed3eb8bd0cc12add8e607209103087de45bf49334a4cdf`
- Exact JSON string literal:

```json
"Traceability validation failed:\r\n - TRACE-P0A1-STATIC-OWNER: P0A.1 static ownership does not match the exact trace-v2 successor.\r\n - TRACE-P45E-KEYBOARD-OWNER: P4.5e keyboard accessibility ownership does not match the trace-v2 successor.\r\n - TRACE-P0A2-OFFLINE-OWNER: P0A.2 offline fixture ownership does not match the trace-v2 successor.\r\n - TRACE-P92-RAG-OWNER: P9.2 RAG ownership does not match the trace-v2 successor.\r\n - TRACE-CHAT-OWNER: Chat contract ownership does not match the trace-v2 successor.\r\n - TRACE-FUTURE-APPROVAL-GUARD: Future parent and acceptance approval metadata or test backlinks do not match the trace\r\n-v2 successor.\r\nAt D:\\Study\\Project\\Aemeath_Desktop_Pet_worktrees\\jarvis-tdd\\tools\\verification\\Test-VerificationContracts.ps1:1098 cha\r\nr:5\r\n+     throw (\"Traceability validation failed:`n - \" + (($baselineFailur ...\r\n+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\r\n    + CategoryInfo          : OperationStopped: (Traceability va...e-v2 successor.:String) [], RuntimeException\r\n    + FullyQualifiedErrorId : Traceability validation failed:\r\n - TRACE-P0A1-STATIC-OWNER: P0A.1 static ownership does not match the exact trace-v2 successor.\r\n - TRACE-P45E-KEYBOARD-OWNER: P4.5e keyboard accessibility ownership does not match the trace-v2 successor.\r\n - TRACE-P0A2-OFFLINE-OWNER: P0A.2 offline fixture ownership does not match the trace-v2 successor.\r\n - TRACE-P92-RAG-OWNER: P9.2 RAG ownership does not match the trace-v2 successor.\r\n - TRACE-CHAT-OWNER: Chat contract ownership does not match the trace-v2 successor.\r\n     - TRACE-FUTURE-APPROVAL-GUARD: Future parent and acceptance approval metadata or test backlinks do not match the  \r\n   trace-v2 successor.\r\n \r\n"
```

PowerShell's native error formatter wraps the final diagnostic and source location in the raw stderr stream. The semantic baseline diagnostic list before the stack text contains exactly these six unique codes, in order:

1. `TRACE-P0A1-STATIC-OWNER`
2. `TRACE-P45E-KEYBOARD-OWNER`
3. `TRACE-P0A2-OFFLINE-OWNER`
4. `TRACE-P92-RAG-OWNER`
5. `TRACE-CHAT-OWNER`
6. `TRACE-FUTURE-APPROVAL-GUARD`

No seventh successor diagnostic was emitted.

## Post-execution identity gate

| Artifact | Post-run SHA-256 | Result |
|---|---|---|
| `docs/verification/traceability-v1.yml` | `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55` | unchanged |
| `docs/verification/preservation-spec-v1.yml` | `9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d` | unchanged |
| `docs/verification/manifests/P0A.1-v4.yml` | `f6b06092f7070c8c9ef8a02c7465e9397adafc3189cf150b779fafd022b51609` | unchanged |
| `tools/verification/Test-VerificationContracts.ps1` | `93aa8b665e26b0ccc2faddbfc062b8bb8d3009da453201789210491cb54a102a` | unchanged |

The validator stopped at the semantic baseline failure. It did not invoke the trace generator, create the later schema-negative temporary files, run product code, run legacy tests, access Git, or access the network.

## TDD interpretation

The predecessor is now observably RED for the reviewed successor requirements. GREEN must preserve this evidence and implement the exact six contracts in a new `traceability-v2.yml`; it must not rewrite the frozen `traceability-v1.yml` bytes to erase this failure.

# P0A.1 Preservation Specification v4 GREEN Evidence v1

- Result: **PASS**
- Scope: focused execution of `tools/verification/Test-PreservationSpecification.ps1`
- Repository worktree: `D:\Study\Project\Aemeath_Desktop_Pet_worktrees\jarvis-tdd`
- Product-source changes: **none**
- Full validator child invocations: **exactly 1**
- Retry count: **0**
- Legacy access: **none**
- Network access: **none**

## Preflight capture attempt

The first capture-tool attempt did not invoke the validator. Tool chunk `d43d9d` completed with outer exit code `1` after `0.0782927` seconds. Before `$proc.Start()`, its authority-path extraction regex failed closed with the exact error `Expected 32 authority paths, got 0.` Therefore:

- validator invocation count: `0`
- child process starts: `0`
- repository file changes: `0`
- product-source changes: `0`

An independent read-only extraction correction then parsed the current validator authority map and established exactly `32` unique authority paths. The correction did not invoke the validator and did not write files.

## Unique GREEN child invocation

- Exact command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File "tools\verification\Test-PreservationSpecification.ps1"`
- Working directory: `D:\Study\Project\Aemeath_Desktop_Pet_worktrees\jarvis-tdd`
- Capture tool chunk: `5a8222`
- Outer tool wall time: `8.484874` seconds
- Outer tool exit code: `0`
- Child start UTC: `2026-08-20T21:16:16.1536671Z`
- Child end UTC: `2026-08-20T21:16:24.1762041Z`
- Child elapsed: `8021` ms
- Timeout: `false`
- Child exit code: `0`
- Full validator invocation count: `1`
- Retry performed: `false`

## Standard output identity

The wrapper read the .NET redirected `StandardOutput` string and serialized it as UTF-8 without BOM.

- Characters: `819`
- Serialized bytes: `819`
- SHA-256: `4ba37bbe6e3fc9b9f2ab0ef1426adee79fc87731ef01a6a19a8324a95a60fd18`
- CRLF pairs: `1`
- Bare LF: `9`
- Bare CR: `0`
- Logical non-empty lines: `10`

Exact Base64 of the serialized stdout bytes:

```text
UEFTUyBjb21wbGV0ZSBmcm96ZW4gcHJlc2VydmF0aW9uIHNwZWNpZmljYXRpb24KUEFTUyBtaXNzaW5nIFBCIG11dGF0aW9uIHJlamVjdGVkIHdpdGggW1AwQTEtUEItQ09WRVJBR0VdClBBU1MgbWlzc2luZyByZXF1aXJlbWVudC1tYXAgZW50cnkgbXV0YXRpb24gcmVqZWN0ZWQgd2l0aCBbUDBBMS1SRVFVSVJFTUVOVC1DT1ZFUkFHRV0KUEFTUyBtaXNzaW5nIGxhbmUgbXV0YXRpb24gcmVqZWN0ZWQgd2l0aCBbUDBBMS1MQU5FLUNPVkVSQUdFXQpQQVNTIGZpeHR1cmUgaGFzaCBkcmlmdCBtdXRhdGlvbiByZWplY3RlZCB3aXRoIFtQMEExLUZJWFRVUkUtSEFTSF0KUEFTUyBTU0UgY29tcGF0aWJpbGl0eSBsaWUgbXV0YXRpb24gcmVqZWN0ZWQgd2l0aCBbUDBBMS1TU0UtVFJVVEhdClBBU1Mgc3BlY2lmaWNhdGlvbiBwcmVkZWNlc3NvciBoYXNoIGRyaWZ0IG11dGF0aW9uIHJlamVjdGVkIHdpdGggW1AwQTEtU1BFQy1QUkVERUNFU1NPUl0KUEFTUyBkdXJhYmxlLXRhcmdldCByZWFjaGFiaWxpdHkgZHJpZnQgbXV0YXRpb24gcmVqZWN0ZWQgd2l0aCBbUDBBMS1EQVRBLUZJWFRVUkUtQ09OVFJBQ1RdCkFFTUVBVEhfQ0lfRElTQ09WRVJZX1YxPXsic2NoZW1hVmVyc2lvbiI6MSwicmVzdWx0SWQiOiJQMEEuMS1WLVNUQVRJQy1TVEFUSUMtQ09OVFJBQ1QiLCJzb3VyY2VTaGEiOiI0M2Y5YzI4OGY4NDNmNzYyMGZmZWU1ZWVlMzUwNGY1Mjg3NWY0Nzc0IiwiYWN0dWFsRGlzY292ZXJ5Ijo4LCJmYWlsZWQiOjAsInNraXBwZWQiOjB9DQpQcmVzZXJ2YXRpb24gc3BlY2lmaWNhdGlvbiB0ZXN0cyBwYXNzZWQgKDggcHJvYmVzOyB6ZXJvIHNraXBzKS4K
```

Logical-line restoration from those bytes:

| Line | Exact content |
| ---: | --- |
| 1 | `PASS complete frozen preservation specification` |
| 2 | `PASS missing PB mutation rejected with [P0A1-PB-COVERAGE]` |
| 3 | `PASS missing requirement-map entry mutation rejected with [P0A1-REQUIREMENT-COVERAGE]` |
| 4 | `PASS missing lane mutation rejected with [P0A1-LANE-COVERAGE]` |
| 5 | `PASS fixture hash drift mutation rejected with [P0A1-FIXTURE-HASH]` |
| 6 | `PASS SSE compatibility lie mutation rejected with [P0A1-SSE-TRUTH]` |
| 7 | `PASS specification predecessor hash drift mutation rejected with [P0A1-SPEC-PREDECESSOR]` |
| 8 | `PASS durable-target reachability drift mutation rejected with [P0A1-DATA-FIXTURE-CONTRACT]` |
| 9 | `AEMEATH_CI_DISCOVERY_V1={"schemaVersion":1,"resultId":"P0A.1-V-STATIC-STATIC-CONTRACT","sourceSha":"43f9c288f843f7620ffee5eee3504f52875f4774","actualDiscovery":8,"failed":0,"skipped":0}` |
| 10 | `Preservation specification tests passed (8 probes; zero skips).` |

The restored output contains exactly `8` PASS lines. The discovery marker reports `actualDiscovery=8`, `failed=0`, `skipped=0`, and `sourceSha=43f9c288f843f7620ffee5eee3504f52875f4774`. The final line reports eight probes and zero skips.

## Standard error identity

- Characters: `0`
- Serialized bytes: `0`
- SHA-256: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
- Base64: empty string (`""`)

## Captured authority pre/post identity

The corrected wrapper extraction produced `authorityPathCount=32`. Adding the independently reviewed `docs/verification/evidence/P0A.1-clean-room-review-v6.md` produced `capturedPathCount=33`. The captured pre-run and post-run JSON values are identical for every row; `driftPaths=[]`.

| Path | Pre SHA-256 | Post SHA-256 |
| --- | --- | --- |
| `docs/verification/preservation-spec-v1.yml` | `9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d` | `9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d` |
| `docs/verification/preservation-spec-v2.yml` | `44a256a79cfb6b4c127aa79a7ae2f0c89b8f94a487e75a71797460bf0dcd4cd5` | `44a256a79cfb6b4c127aa79a7ae2f0c89b8f94a487e75a71797460bf0dcd4cd5` |
| `docs/verification/preservation-spec-v3.yml` | `c0c4b90e9d65a46e6e297d928cbe805e802ba86b265cfdb46cb6766d76078f4f` | `c0c4b90e9d65a46e6e297d928cbe805e802ba86b265cfdb46cb6766d76078f4f` |
| `docs/verification/preservation-spec-v4.yml` | `874471015a03853b8fbffdd9350f631286d8ccb4d53b9cae4114448b5d260bc3` | `874471015a03853b8fbffdd9350f631286d8ccb4d53b9cae4114448b5d260bc3` |
| `docs/verification/manifests/P0A.1-v5.yml` | `17f262ff6f2e9c038ce3001b554080b5e39c3e6bb4428ee02b5d47e890c8da91` | `17f262ff6f2e9c038ce3001b554080b5e39c3e6bb4428ee02b5d47e890c8da91` |
| `docs/verification/manifests/P0A.1-v6.yml` | `e7afa6554e2eda77aa471eade20db990044509c01978f4944f5c0af56eb00f40` | `e7afa6554e2eda77aa471eade20db990044509c01978f4944f5c0af56eb00f40` |
| `docs/verification/manifests/P0A.1-v7.yml` | `6944c536c8c804e4a7e790c97442d9aba27e17dc0d5f112c3997eab02ba0ebef` | `6944c536c8c804e4a7e790c97442d9aba27e17dc0d5f112c3997eab02ba0ebef` |
| `docs/verification/manifests/P0A.1-v8.yml` | `7bc93dc23f961fbe183eeeaa32b6e01acf0707e041ed3fb4d7217231d7ed16b0` | `7bc93dc23f961fbe183eeeaa32b6e01acf0707e041ed3fb4d7217231d7ed16b0` |
| `docs/verification/invalidations/P0A.1-v1.json` | `cd9486b7227b0ca99f137a7cd28c75c4903cc0a840bab911517cbe51fcfe6221` | `cd9486b7227b0ca99f137a7cd28c75c4903cc0a840bab911517cbe51fcfe6221` |
| `docs/verification/invalidations/P0A.1-v2.json` | `881fc5fe9f57c95826aa5e76322378b4a8fa8f0b3b0761612cc62f8095ecbea7` | `881fc5fe9f57c95826aa5e76322378b4a8fa8f0b3b0761612cc62f8095ecbea7` |
| `docs/verification/invalidations/P0A.1-v3.json` | `e5c1add435b63e227a82837fd837b72d2f7c2df935cee5e6127b7e8ac9b71a10` | `e5c1add435b63e227a82837fd837b72d2f7c2df935cee5e6127b7e8ac9b71a10` |
| `docs/verification/invalidations/P0A.1-v4.json` | `de56c2b3c183df68b2a3d4f27f250c20ef158a39dc46180cca3bddbcd8078724` | `de56c2b3c183df68b2a3d4f27f250c20ef158a39dc46180cca3bddbcd8078724` |
| `docs/verification/invalidations/P0A.1-v5.json` | `65d7246b05f6d767458796bcea6d855b4db47f2793de0dc935ad3bb64d491d9b` | `65d7246b05f6d767458796bcea6d855b4db47f2793de0dc935ad3bb64d491d9b` |
| `docs/verification/invalidations/P0A.1-v5-v2.json` | `e7d8b029224cff5968c81f3214f02dd9da2fa6de0e9527140df4152684907e93` | `e7d8b029224cff5968c81f3214f02dd9da2fa6de0e9527140df4152684907e93` |
| `docs/verification/invalidations/P0A.1-v6.json` | `db7dfe0ac65cc8bcd722219e6652d3fb1bdc29901def38c46671fd9d92de74f0` | `db7dfe0ac65cc8bcd722219e6652d3fb1bdc29901def38c46671fd9d92de74f0` |
| `docs/verification/invalidations/P0A.1-v7.json` | `34ef8d158d82645e6feeefb9d20a6f9df4a9a195ebc288fba15de302669a7a1d` | `34ef8d158d82645e6feeefb9d20a6f9df4a9a195ebc288fba15de302669a7a1d` |
| `docs/verification/evidence/P0A.1-clean-room-review-v5.md` | `1be93b14dcc551025389b54c2cecd223cd31324f8ba57f7cd7cba6a539268074` | `1be93b14dcc551025389b54c2cecd223cd31324f8ba57f7cd7cba6a539268074` |
| `docs/verification/traceability-v2.yml` | `28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415` | `28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415` |
| `docs/verification/traceability-v1.yml` | `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55` | `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55` |
| `tests/fixtures/preservation/v1/data-v1.json` | `fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa` | `fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa` |
| `tests/fixtures/preservation/v1/data-v2.json` | `c1a18b2acd22a07568425567291a34bd43a0df839276d17258162d3da98fb315` | `c1a18b2acd22a07568425567291a34bd43a0df839276d17258162d3da98fb315` |
| `tests/fixtures/preservation/v1/data-v3.json` | `a7ce95ef2124e517f5b9433cadfbecb6e08d1129d46538d3a4e5b6f2e6b18bbd` | `a7ce95ef2124e517f5b9433cadfbecb6e08d1129d46538d3a4e5b6f2e6b18bbd` |
| `tests/fixtures/preservation/v1/data-v4.json` | `8b4d03ff5cb535a70660810870254d1e84d70381dfe8749f208416c3e134ea3b` | `8b4d03ff5cb535a70660810870254d1e84d70381dfe8749f208416c3e134ea3b` |
| `tests/fixtures/preservation/v1/data-v5.json` | `4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0` | `4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0` |
| `tests/fixtures/preservation/v1/protocol-v1.json` | `95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312` | `95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312` |
| `tests/fixtures/preservation/v1/protocol-v2.json` | `ec2ea43cf0d06ef75e7b0334b432464fca71b9198814287e2bf33bf8e026a602` | `ec2ea43cf0d06ef75e7b0334b432464fca71b9198814287e2bf33bf8e026a602` |
| `tests/fixtures/preservation/v1/protocol-v3.json` | `cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565` | `cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565` |
| `tests/fixtures/preservation/v1/oracles-v1.json` | `4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d` | `4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d` |
| `tests/fixtures/preservation/v1/resources-v1.json` | `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8` | `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8` |
| `tools/ci/CiDeliveryContract.psm1` | `85cd1c770b5be08737d8045b64a1d60d11b003f235fc732f1ffe7f15aeba19f3` | `85cd1c770b5be08737d8045b64a1d60d11b003f235fc732f1ffe7f15aeba19f3` |
| `docs/verification/manifests/D0.4-v3.yml` | `d8b763acaa04088f5f8b47b79d956deea8f9898b74d543004938d4cd3d642d2e` | `d8b763acaa04088f5f8b47b79d956deea8f9898b74d543004938d4cd3d642d2e` |
| `docs/verification/environments/D0.4-readiness-v1.json` | `aafcdc4919239c0bb239f15b61c7b757c665e3649cda04e114b203e67eb813bc` | `aafcdc4919239c0bb239f15b61c7b757c665e3649cda04e114b203e67eb813bc` |
| `docs/verification/evidence/P0A.1-clean-room-review-v6.md` | `1c0ac44e73c78ae16ac063f256e24a596c4d08ee0328482836bfd5e421291476` | `1c0ac44e73c78ae16ac063f256e24a596c4d08ee0328482836bfd5e421291476` |

## Production-root pre/post identity

| Root | Pre bytes | Post bytes | Pre files | Post files | Pre SHA-256 | Post SHA-256 |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| `src/AemeathDesktopPet` | `6288961` | `6288961` | `94` | `94` | `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb` | `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb` |
| `python-backend/aemeath_agent` | `111640` | `111640` | `46` | `46` | `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae` | `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae` |

## Immediate post-only identities

These were read immediately after the single child completed; no retry or second validator invocation occurred.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| `tools/verification/Test-PreservationSpecification.ps1` | `165815` | `2db7f71cf88b867d706e66a8dc5690ce5df60277d6f4f0c397fdd8d0b3d11f62` |
| `docs/verification/evidence/P0A.1-clean-room-review-v6.md` | `8192` | `1c0ac44e73c78ae16ac063f256e24a596c4d08ee0328482836bfd5e421291476` |
| `docs/verification/preservation-spec-v4.yml` | `167193` | `874471015a03853b8fbffdd9350f631286d8ccb4d53b9cae4114448b5d260bc3` |
| `docs/verification/manifests/P0A.1-v8.yml` | `14901` | `7bc93dc23f961fbe183eeeaa32b6e01acf0707e041ed3fb4d7217231d7ed16b0` |
| `HEAD` | n/a | `43f9c288f843f7620ffee5eee3504f52875f4774` |

## Clean-review and governance chain

The independent clean review is `docs/verification/evidence/P0A.1-clean-room-review-v6.md`, 8192 bytes, SHA-256 `1c0ac44e73c78ae16ac063f256e24a596c4d08ee0328482836bfd5e421291476`. It records:

- Reviewer assignment: `clean-room-preservation-reviewer-05`
- Legacy exposure: `unexposed`
- Verdict: **PASS**
- Finding census: **C=0, I=0, M=0**

The review binds the stable validator, preservation-spec-v4, manifest-v8, the active fixtures and production roots. Manifest-v8 retains clean-review-v5 as BLOCK governance history, invalidation-v7 replaces manifest-v7 with v8, and preservation-spec-v4 binds manifest-v8 while retaining spec-v3 as its BLOCK predecessor. This GREEN evidence binds that reviewed chain to the one successful child execution and its exact output and pre/post identities.

## Write and scope conclusion

The validator child made no writes: all 32 validator authorities, clean-review-v6, and both production roots are byte-for-byte unchanged across the captured pre/post boundary, with `driftPaths=[]`. Product source files were not modified. No legacy source, project command, network operation, or Git write operation was used; Git access was limited to the read-only HEAD authority identity. The only later repository write is this immutable evidence file itself.

**Conclusion: PASS.**

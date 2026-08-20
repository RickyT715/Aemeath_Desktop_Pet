# P0A.1 Preservation Specification v5 GREEN Evidence

## Verdict

`PASS` — the single local raw-first full-run capture completed with wrapper exit 0, envelope `passed: true`, exactly one validator start, validator exit 0, eight discovery probes, seven rejected semantic mutations, and zero skips.

This is a local checkout result at HEAD `43f9c288f843f7620ffee5eee3504f52875f4774` with raw `SOURCE_SHA = null`. It does not claim that a committed CI checkout has been exercised. The successor's pure source-identity guards cover lowercase format, exact CI match, mismatch, whitespace/case rejection, and invalid-live cascade behavior; the active CI environment-variable path was not activated in this run.

## Fresh preflight and execution lineage

The fresh preflight capture was tool chunk `668153`, outer exit `0`, wall time `0.6414654 s`. It confirmed eight exact execution/authority identities. Its direct checker response reported `passed: true`, `38/38` authorities, live HEAD `43f9c288f843f7620ffee5eee3504f52875f4774`, raw `SOURCE_SHA = null`, and both exact production roots.

Only `.superpowers/sdd/20260722-jarvis-assistant-tdd-checklist/p0a1-v5-fullrun-raw-first-exec-v1.mjs`, SHA-256 `f42f8708f43f766fc0f7d2a83a3e4566fcb8fd92e2570e5cdd8d3874bf666dd1`, was submitted to the controller, once. Controller facts:

- namespace: `p0a1-v5-fullrun-raw-first-v1`;
- response count: `1`;
- raw response key: `p0a1-v5-fullrun-raw-first-v1:raw-response:0`;
- session continuation: none;
- wrapper resubmission/retry: none;
- manifest terminal chunk: `9f5644`;
- manifest terminal exit: `0`.

The wrapper tool response was chunk `9f5644`, wall time `9.5368948 s`, exit `0`. Its `output` was exactly `76146` characters and UTF-8 bytes with one CRLF, zero bare LF, zero bare CR, and a terminal newline. Raw response SHA-256 was `cf8c4689687bd0d7ab18351643e104b9db08897dc2c2422ff310f40c5de5077d`. The response object was stored immediately under the raw key before any field access, parsing, stringification, or summary output.

## Wrapper envelope and child process capture

Envelope result:

| Field | Captured value |
| --- | --- |
| `resultId` | `P0A1-V5-VALIDATOR-RAW-FIRST-CAPTURE` |
| `passed` | `true` |
| `validatorStarts` | `1` |
| `failures` | `[]` |

Process chronology:

| Role | UTC start | UTC end | Elapsed | Exit | State |
| --- | --- | --- | ---: | ---: | --- |
| Pre identity checker | `2026-08-20T23:10:47.3046234Z` | `2026-08-20T23:10:47.8316437Z` | 525 ms | 0 | passed |
| Preservation validator | `2026-08-20T23:10:47.9388596Z` | `2026-08-20T23:10:56.1366978Z` | 8198 ms | 0 | started; not timed out; no kill; termination confirmed; capture failure null |
| Post identity checker | `2026-08-20T23:10:56.1403610Z` | `2026-08-20T23:10:56.6455396Z` | 505 ms | 0 | passed |

The sole validator command was exactly:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools\verification\Test-PreservationSpecification.ps1
```

Working directory was `D:\Study\Project\Aemeath_Desktop_Pet_worktrees\jarvis-tdd`.

## Validator stdout and stderr

Redirected stdout was exactly `819` characters / UTF-8 bytes, SHA-256 `4ba37bbe6e3fc9b9f2ab0ef1426adee79fc87731ef01a6a19a8324a95a60fd18`, with one CRLF, nine bare LF, zero bare CR, ten nonempty lines, and a terminal newline.

Exact nonempty lines, in order:

```text
PASS complete frozen preservation specification
PASS missing PB mutation rejected with [P0A1-PB-COVERAGE]
PASS missing requirement-map entry mutation rejected with [P0A1-REQUIREMENT-COVERAGE]
PASS missing lane mutation rejected with [P0A1-LANE-COVERAGE]
PASS fixture hash drift mutation rejected with [P0A1-FIXTURE-HASH]
PASS SSE compatibility lie mutation rejected with [P0A1-SSE-TRUTH]
PASS specification predecessor hash drift mutation rejected with [P0A1-SPEC-PREDECESSOR]
PASS durable-target reachability drift mutation rejected with [P0A1-DATA-FIXTURE-CONTRACT]
AEMEATH_CI_DISCOVERY_V1={"schemaVersion":1,"resultId":"P0A.1-V-STATIC-STATIC-CONTRACT","sourceSha":"43f9c288f843f7620ffee5eee3504f52875f4774","actualDiscovery":8,"failed":0,"skipped":0}
Preservation specification tests passed (8 probes; zero skips).
```

Exact stdout Base64:

```text
UEFTUyBjb21wbGV0ZSBmcm96ZW4gcHJlc2VydmF0aW9uIHNwZWNpZmljYXRpb24KUEFTUyBtaXNzaW5nIFBCIG11dGF0aW9uIHJlamVjdGVkIHdpdGggW1AwQTEtUEItQ09WRVJBR0VdClBBU1MgbWlzc2luZyByZXF1aXJlbWVudC1tYXAgZW50cnkgbXV0YXRpb24gcmVqZWN0ZWQgd2l0aCBbUDBBMS1SRVFVSVJFTUVOVC1DT1ZFUkFHRV0KUEFTUyBtaXNzaW5nIGxhbmUgbXV0YXRpb24gcmVqZWN0ZWQgd2l0aCBbUDBBMS1MQU5FLUNPVkVSQUdFXQpQQVNTIGZpeHR1cmUgaGFzaCBkcmlmdCBtdXRhdGlvbiByZWplY3RlZCB3aXRoIFtQMEExLUZJWFRVUkUtSEFTSF0KUEFTUyBTU0UgY29tcGF0aWJpbGl0eSBsaWUgbXV0YXRpb24gcmVqZWN0ZWQgd2l0aCBbUDBBMS1TU0UtVFJVVEhdClBBU1Mgc3BlY2lmaWNhdGlvbiBwcmVkZWNlc3NvciBoYXNoIGRyaWZ0IG11dGF0aW9uIHJlamVjdGVkIHdpdGggW1AwQTEtU1BFQy1QUkVERUNFU1NPUl0KUEFTUyBkdXJhYmxlLXRhcmdldCByZWFjaGFiaWxpdHkgZHJpZnQgbXV0YXRpb24gcmVqZWN0ZWQgd2l0aCBbUDBBMS1EQVRBLUZJWFRVUkUtQ09OVFJBQ1RdCkFFTUVBVEhfQ0lfRElTQ09WRVJZX1YxPXsic2NoZW1hVmVyc2lvbiI6MSwicmVzdWx0SWQiOiJQMEEuMS1WLVNUQVRJQy1TVEFUSUMtQ09OVFJBQ1QiLCJzb3VyY2VTaGEiOiI0M2Y5YzI4OGY4NDNmNzYyMGZmZWU1ZWVlMzUwNGY1Mjg3NWY0Nzc0IiwiYWN0dWFsRGlzY292ZXJ5Ijo4LCJmYWlsZWQiOjAsInNraXBwZWQiOjB9DQpQcmVzZXJ2YXRpb24gc3BlY2lmaWNhdGlvbiB0ZXN0cyBwYXNzZWQgKDggcHJvYmVzOyB6ZXJvIHNraXBzKS4K
```

Redirected stderr was empty: `0` characters / bytes, SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.

## Pre/post identity equality

The captured pre and post checker `originalJson` documents were each exactly `6337` characters and were ordinal-equal. Both reported `passed: true`, `authorityExpected: 38`, `authorityActual: 38`, live HEAD `43f9c288f843f7620ffee5eee3504f52875f4774`, raw `SOURCE_SHA = null`, and the same two root identities. The read-only current-file recalculation used while authoring this evidence found all 38 raw identities unchanged, so every row below is `pre = post = current`.

| Path | Bytes | Raw SHA-256 | Equality |
| --- | ---: | --- | --- |
| `docs/verification/preservation-spec-v1.yml` | 67431 | `9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d` | pre = post = current |
| `docs/verification/preservation-spec-v2.yml` | 158127 | `44a256a79cfb6b4c127aa79a7ae2f0c89b8f94a487e75a71797460bf0dcd4cd5` | pre = post = current |
| `docs/verification/preservation-spec-v3.yml` | 167080 | `c0c4b90e9d65a46e6e297d928cbe805e802ba86b265cfdb46cb6766d76078f4f` | pre = post = current |
| `docs/verification/preservation-spec-v4.yml` | 167193 | `874471015a03853b8fbffdd9350f631286d8ccb4d53b9cae4114448b5d260bc3` | pre = post = current |
| `docs/verification/preservation-spec-v5.yml` | 168943 | `123df163b9cfb23c7fe17b133a32757c90424bafc499aa1b089db24628c2c4c9` | pre = post = current |
| `docs/verification/manifests/P0A.1-v5.yml` | 10224 | `17f262ff6f2e9c038ce3001b554080b5e39c3e6bb4428ee02b5d47e890c8da91` | pre = post = current |
| `docs/verification/manifests/P0A.1-v6.yml` | 14900 | `e7afa6554e2eda77aa471eade20db990044509c01978f4944f5c0af56eb00f40` | pre = post = current |
| `docs/verification/manifests/P0A.1-v7.yml` | 15255 | `6944c536c8c804e4a7e790c97442d9aba27e17dc0d5f112c3997eab02ba0ebef` | pre = post = current |
| `docs/verification/manifests/P0A.1-v8.yml` | 14901 | `7bc93dc23f961fbe183eeeaa32b6e01acf0707e041ed3fb4d7217231d7ed16b0` | pre = post = current |
| `docs/verification/manifests/P0A.1-v9.yml` | 15263 | `7e7d8c298b91f78479cb0dfc8a028e02d5f84785fd3d3768eb88e591c78a284d` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v1.json` | 717 | `cd9486b7227b0ca99f137a7cd28c75c4903cc0a840bab911517cbe51fcfe6221` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v2.json` | 740 | `881fc5fe9f57c95826aa5e76322378b4a8fa8f0b3b0761612cc62f8095ecbea7` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v3.json` | 767 | `e5c1add435b63e227a82837fd837b72d2f7c2df935cee5e6127b7e8ac9b71a10` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v4.json` | 860 | `de56c2b3c183df68b2a3d4f27f250c20ef158a39dc46180cca3bddbcd8078724` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v5.json` | 1362 | `65d7246b05f6d767458796bcea6d855b4db47f2793de0dc935ad3bb64d491d9b` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v5-v2.json` | 812 | `e7d8b029224cff5968c81f3214f02dd9da2fa6de0e9527140df4152684907e93` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v6.json` | 742 | `db7dfe0ac65cc8bcd722219e6652d3fb1bdc29901def38c46671fd9d92de74f0` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v7.json` | 840 | `34ef8d158d82645e6feeefb9d20a6f9df4a9a195ebc288fba15de302669a7a1d` | pre = post = current |
| `docs/verification/invalidations/P0A.1-v8.json` | 827 | `97bea8753719a798cde630f2b8e3cab7adcd28213ef180728c3abae73a6574bf` | pre = post = current |
| `docs/verification/evidence/P0A.1-clean-room-review-v5.md` | 13733 | `1be93b14dcc551025389b54c2cecd223cd31324f8ba57f7cd7cba6a539268074` | pre = post = current |
| `docs/verification/evidence/P0A.1-clean-room-review-v6.md` | 8192 | `1c0ac44e73c78ae16ac063f256e24a596c4d08ee0328482836bfd5e421291476` | pre = post = current |
| `docs/verification/evidence/P0A.1-preservation-spec-v4-green-v1.md` | 14067 | `48cf0260ed05150919cc059685abb9482878b05611c8c95b27efcd291063adab` | pre = post = current |
| `docs/verification/traceability-v2.yml` | 478168 | `28e89fe63ca3dcb433e741f860381ed05b7319169d19e01dc8c7be5cfcd3f415` | pre = post = current |
| `docs/verification/traceability-v1.yml` | 477167 | `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55` | pre = post = current |
| `tests/fixtures/preservation/v1/data-v1.json` | 5344 | `fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa` | pre = post = current |
| `tests/fixtures/preservation/v1/data-v2.json` | 30989 | `c1a18b2acd22a07568425567291a34bd43a0df839276d17258162d3da98fb315` | pre = post = current |
| `tests/fixtures/preservation/v1/data-v3.json` | 39683 | `a7ce95ef2124e517f5b9433cadfbecb6e08d1129d46538d3a4e5b6f2e6b18bbd` | pre = post = current |
| `tests/fixtures/preservation/v1/data-v4.json` | 40683 | `8b4d03ff5cb535a70660810870254d1e84d70381dfe8749f208416c3e134ea3b` | pre = post = current |
| `tests/fixtures/preservation/v1/data-v5.json` | 41016 | `4fa474e506e03ad1d3e2af9a9bce6d14e27100d450f310970d82969af860dfc0` | pre = post = current |
| `tests/fixtures/preservation/v1/protocol-v1.json` | 7334 | `95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312` | pre = post = current |
| `tests/fixtures/preservation/v1/protocol-v2.json` | 17505 | `ec2ea43cf0d06ef75e7b0334b432464fca71b9198814287e2bf33bf8e026a602` | pre = post = current |
| `tests/fixtures/preservation/v1/protocol-v3.json` | 17433 | `cb3218e382f87264bef3a09349d7ffe2cf2d3dc999a060258bbaa02bc6fa9565` | pre = post = current |
| `tests/fixtures/preservation/v1/oracles-v1.json` | 7954 | `4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d` | pre = post = current |
| `tests/fixtures/preservation/v1/resources-v1.json` | 3167 | `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8` | pre = post = current |
| `tools/ci/CiDeliveryContract.psm1` | 23981 | `85cd1c770b5be08737d8045b64a1d60d11b003f235fc732f1ffe7f15aeba19f3` | pre = post = current |
| `docs/verification/manifests/D0.4-v3.yml` | 10381 | `d8b763acaa04088f5f8b47b79d956deea8f9898b74d543004938d4cd3d642d2e` | pre = post = current |
| `docs/verification/environments/D0.4-readiness-v1.json` | 12132 | `aafcdc4919239c0bb239f15b61c7b757c665e3649cda04e114b203e67eb813bc` | pre = post = current |
| `docs/verification/evidence/P0A.1-clean-room-review-v7.md` | 19370 | `7869e85fb49790b488b68bebec1ec4eeea7b1dd32695118b520028e5490ae34a` | pre = post = current |

Production-root equality:

| Root | Files | Bytes | Digest | Equality |
| --- | ---: | ---: | --- | --- |
| `src/AemeathDesktopPet` | 94 | 6288961 | `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb` | pre = post |
| `python-backend/aemeath_agent` | 46 | 111640 | `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae` | pre = post |

## Bundle and active-contract identities

The four authored bundle files are:

| Bundle file | Bytes | SHA-256 |
| --- | ---: | --- |
| `.superpowers/sdd/20260722-jarvis-assistant-tdd-checklist/p0a1-v5-fullrun-identity-checker.ps1` | 16210 | `f4e5a24e2dff98d25fef5a6d175e058367e36cec3d9a68777b44738b091588af` |
| `.superpowers/sdd/20260722-jarvis-assistant-tdd-checklist/p0a1-v5-validator-capture-wrapper.ps1` | 9229 | `346a68a58aac7828e267f3ecc4788d821e3d79d1fe44ebf1f24a5b1916ee7197` |
| `.superpowers/sdd/20260722-jarvis-assistant-tdd-checklist/p0a1-v5-fullrun-raw-first-exec-v1.mjs` | 2350 | `f42f8708f43f766fc0f7d2a83a3e4566fcb8fd92e2570e5cdd8d3874bf666dd1` |
| `.superpowers/sdd/20260722-jarvis-assistant-tdd-checklist/p0a1-v5-fullrun-capture-bundle-design-report.md` | 9981 | `c86c9e8c58531b873dce82493f2605a24c8e42a18dee589c380cad716dc9f7bc` |

The fresh eight-identity preflight bound the first three executable bundle sources above plus these five current authorities:

| Active input | SHA-256 |
| --- | --- |
| `tools/verification/Test-PreservationSpecification.ps1` | `a096afd7933e8a1b6ded98d3796b3a59c467ada7710def7ce0bbac13dc9544dd` |
| `docs/verification/evidence/P0A.1-clean-room-review-v7.md` | `7869e85fb49790b488b68bebec1ec4eeea7b1dd32695118b520028e5490ae34a` |
| `docs/verification/preservation-spec-v5.yml` | `123df163b9cfb23c7fe17b133a32757c90424bafc499aa1b089db24628c2c4c9` |
| `docs/verification/manifests/P0A.1-v9.yml` | `7e7d8c298b91f78479cb0dfc8a028e02d5f84785fd3d3768eb88e591c78a284d` |
| `docs/verification/invalidations/P0A.1-v8.json` | `97bea8753719a798cde630f2b8e3cab7adcd28213ef180728c3abae73a6574bf` |

The design report was not an executable full-run input and is listed only to complete the four-file bundle identity.

## Scope and non-rerun boundary

There was exactly one controller submission, one raw response, one wrapper invocation, and one validator start. There was no retry, wrapper resubmission, session continuation, timeout, or kill. The captured run performed preservation validation and read-only identity checks; it did not build, launch, or test the desktop application or Python sidecar, did not run legacy tests, and did not use the network. This evidence authoring step performed only read-only raw-file identity/Base64 checks and created this one immutable Markdown file; it did not rerun any captured command or modify product, validator, specification, manifest, invalidation, fixture, trace, review, or bundle files.

Conclusion: `PASS` for the frozen P0A.1 preservation specification v5 on the captured local HEAD, with exact raw-first response preservation and pre/post identity equality. CI exact-checkout behavior remains a contract proven by pure guards, not an execution claim of this local GREEN run.

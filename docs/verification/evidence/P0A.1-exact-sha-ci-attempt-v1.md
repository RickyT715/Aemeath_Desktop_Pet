# P0A.1 Exact-SHA CI Attempt v1

## Verdict

`DIAGNOSTIC FAILURE` — the first pushed exact-SHA run exposed a Git byte-transport defect before the P0A.1 CI step. This document does not claim CI PASS, does not replace the local P0A.1 GREEN evidence, and does not authorize treating the skipped P0A.1 CI step as executed.

## Exact run identity

- Repository: `RickyT715/Aemeath_Desktop_Pet`
- Workflow run: `32429687816`
- URL: `https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/32429687816`
- Exact pushed source SHA: `2426886970ff1e87935658f5db0a39c8524ba319`
- Run status: `completed`
- Run conclusion: `failure`
- Observation date: `2026-08-21` (Asia/Shanghai)

The checkout identity step reported `SOURCE_SHA=2426886970ff1e87935658f5db0a39c8524ba319`; the failure therefore belongs to the intended pushed commit rather than a pull-request merge SHA or a stale checkout.

## Job results

| Job | Job ID | Conclusion |
| --- | ---: | --- |
| Delivery Contract | `96618645402` | `success` |
| .NET Release Build | `96618955669` | `success` |
| Dependency Qualification | `96618955709` | `success` |
| Delivery Environment | `96618955711` | `success` |
| Verification Contracts | `96618955749` | `failure` |

The Verification Contracts job failed in step 4, `Run verification contract probes`. Step 5, `Run D0.5 static probes on Ubuntu`, and step 6, `Run P0A.1 preservation specification probes`, were both skipped. The evidence-upload step still completed successfully.

## Exact failure

The failed job log records:

```text
2026-08-20T23:43:17.3081927Z 1078 | throw "Frozen traceability predecessor bytes have changed."
2026-08-20T23:43:17.3085003Z      | Frozen traceability predecessor bytes have changed.
2026-08-20T23:43:17.3444271Z Process completed with exit code 1.
```

This is a fixed-input authority failure, not a preservation-spec semantic failure. The P0A.1 validator was not started by this run.

## Root cause

Commit `2426886970ff1e87935658f5db0a39c8524ba319` did not declare the P0A.1 raw-byte authorities as `-text`. Git consequently stored or checked out LF-normalized bytes on Ubuntu for CRLF-frozen inputs. For `docs/verification/traceability-v1.yml`:

- intended worktree identity: `477167` bytes, SHA-256 `939fa28cbf5e0ed5ee57f520eec1fd9e505f14e0e976b1a21ec58a77b906db55`;
- normalized LF identity observed during diagnosis: `477166` bytes, SHA-256 `9fbb1075e24c94dcc25cbd6e0a092dc2bb4de091b066aa5ddf27afea5686e894`.

The one-byte difference is the frozen CRLF-to-LF transport change. The same risk also applies to files under both production roots because their raw bytes contribute to the preservation root digests.

## Successor repair and local evidence boundary

The uncommitted successor repair declares `-text` for every P0A.1 authority class and both production roots. Its delivery guard:

1. requires each exact attribute rule;
2. removes each rule from the actual active attribute set and requires the shared verifier to diagnose exactly that missing rule;
3. enumerates the two production roots with the validator's reparse-point and generated-file exclusions;
4. requires `git check-attr text` to report `unset` for every protected file; and
5. requires the worktree raw object, filtered object, and staged index blob to be ordinal-equal.

After explicit targeted reindexing, the guard covered all `140` production-root files with zero raw/filter/index mismatches. The strengthened local delivery run completed with exit `0` in controller chunks `68c1b2` and `375a06`, reporting `static=67` and `result=47`.

That local delivery result is repair evidence only. It is not an actual GitHub Actions PASS. No retry or rerun of workflow run `32429687816` was requested, and the one-off local P0A.1 full validator was not rerun.

## Required next observation

The repair must be independently reviewed, committed, pushed by normal fast-forward, and exercised by a new GitHub Actions run whose `headSha` is the repair commit. P0A.1 remains open until that new exact-SHA run reaches a terminal result and its P0A.1 marker/evidence are verified.

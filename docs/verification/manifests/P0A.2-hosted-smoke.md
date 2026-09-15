# P0A.2 bounded hosted smoke

Scope: the first process-smoke portion of P0A.2, not completion of P0A.2 or Gate 0A.
Baseline production is unchanged from the P0A.1 delivery commit
`be36a304b4da2beb302f69cef1a384d85027da2e`.

Before the first remote application launch, this packet fixes the following risks and oracles.
The preparatory non-hosted refusal test has already had a RED/GREEN cycle; it is safety-tooling
evidence, not a behavioral RED against the product.

| Risk | Required control and observation |
| --- | --- |
| Real user data touched | Refuse outside a disposable GitHub-hosted runneradmin session; use Windows known folders; reject existing product data and reparse paths. |
| Provider, sidecar, or external integration use | Fixed synthetic empty-key configuration disables integrations; effective inbound/outbound program firewall blocks precede launch. |
| Wrong or unusable application | Build the exact source checkout; find a visible, responding pet owned by the launched process; open responding Chat and Settings through the existing pet menu. |
| Orphan process or firewall residue | Use an owned Windows Job Object, bounded waits, existing Quit action, and cleanup verification. Preserve synthetic data for worker reset, never delete a user profile. |
| False completion claim | Exit 23 means safety refusal, 1 means exercised failure, 0 requires all bounded smoke observations plus cleanup. Report missing restart and real-Windows qualification explicitly. |

Required lanes for this portion:

- Privacy/safety: real subprocess refusal test, including no evidence writes, on local and hosted runs.
- Process smoke: `.github/workflows/offline-assistant-smoke.yml`, Windows PowerShell 5.1 on
  `windows-latest`, real unchanged Release executable, offline Pet/Chat/Settings/Quit observations.
- Existing CI: all five exact-source jobs in `ci.yml` continue to pass independently.

Commands:

```powershell
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/verification/tests/Test-OfflineProcessSmokeSafety.ps1
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File tools/verification/Test-OfflineProcessSmoke.ps1 -EvidenceDirectory artifacts/ci/offline-process-smoke
```

The second command must never be run on the developer's host. It refuses before side effects unless
the disposable-worker guards pass. The evidence directory must not already exist. CI retains a
source record, process summary, and bounded stdout log; it does not upload personal data or images.
The workflow has read-only repository permissions and requires no provider credentials.

Still required in P0A.2: restart continuity for config/position/stats/history, transparent/topmost
real-boundary observation, and keyboard companion journeys on qualified disposable Windows 10/11.
Hosted evidence is not a substitute for those lanes, and a setup refusal is not a product failure.

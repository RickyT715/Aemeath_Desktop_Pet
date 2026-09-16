# P0A.2 bounded hosted smoke

Scope: the first process-smoke portion of P0A.2, not completion of P0A.2 or Gate 0A.
Historical baseline production is preserved at the P0A.1 delivery commit
`be36a304b4da2beb302f69cef1a384d85027da2e`. The user approved a narrow early chat-crash repair on
2026-09-16 after the real baseline process failure at `fdb4dd6`. Repaired-source runs are reported
separately from unchanged-baseline qualification; all existing isolation and behavioral oracles stay
in force. The exception does not authorize unrelated production changes or complete Gate 0A.

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
real-boundary observation, and keyboard companion characterization on a disposable interactive
Windows worker. The frozen specification records keyboard-only companion entry as a current gap;
programmatic focus or mouse-assisted menu activation cannot be counted as closing that gap.
D0.4 permits the hosted worker for this bounded step. The dedicated Windows 10/11 matrix remains
required by P0A.8; hosted evidence does not replace it. A setup refusal is not a product failure.

## Next portion: offline conversation and restart continuity

The initial Pet/Chat/Settings/Quit journey passed on source
`2cf35692161c2dbcc06867144e8450aec42eff22` in
[run 34995850350](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/34995850350).
The following extension is specified before its executable checks are added:

- Seed only the synthetic `messages.json` and `stats.json` fixtures in the same newly created
  disposable profile, retaining all existing identity, path, integration, and firewall guards.
- Observe the seeded conversation in Chat, send one fixed fake text message through its existing
  input/Send controls, and require a nonempty offline response with the UI returning to ready.
  The screenshot toggle must remain off; no microphone action is permitted.
- Quit cleanly, read only this owned profile, and check ordered history, non-streaming response,
  preserved first-launch/counters (chat count increases once), valid non-secret configuration,
  and a quit-time-bounded `lastSeen`. Use documented ranges for decay/time-dependent values.
- Restart the same executable once under the same effective network block and owned process job.
  Observe the persisted conversation and pet position/configuration, then quit cleanly again.
- Report each completed stage separately. Require two clean exits and final cleanup for success;
  missing/false restart or response evidence must fail the result check. Fixed fixtures and a
  known-bad result provide failure-detection coverage without running the app on the local host.

This extension uses the same process/safety lanes and does not claim Windows 10/11, accessibility,
keyboard-entry, or the rest of Gate 0A has passed. It adds no production behavior or data-root seam.

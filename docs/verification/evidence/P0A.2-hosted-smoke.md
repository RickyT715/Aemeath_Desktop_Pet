# P0A.2 hosted application evidence

This is bounded disposable-worker evidence, not completion of P0A.2 or the Windows 10/11 matrix.
The launch-only and baseline crash runs below used unchanged production. The narrowly approved
repair is tracked separately and must not be called an unchanged-baseline pass.

## Pet, Chat, Settings, and Quit

Source: `2cf35692161c2dbcc06867144e8450aec42eff22`.
[Hosted run 34995850350](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/34995850350)
passed on Windows build `10.0.26100.0`, interactive session 2.
The five required jobs in [CI run 34995850511](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/34995850511)
also passed for that exact source; `Wait-ForCi.ps1` validated their downloaded artifacts and exited 0.

The downloaded `offline-process-smoke.json` records a visible/responding pet, opened Chat and
Settings, exit code 0 through the existing Quit menu, and successful cleanup. Effective inbound and
outbound executable blocks were verified before launch. Each of the three menu actions recorded
the exact owned cursor target, two injected mouse events, and eight process-owned menu items.
Only hashes and sizes of the disposable profile's config, stats, and message files were retained.

The first attempt, [run 34994919090](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/34994919090),
launched a responding pet but failed at `MENU_ITEM_UNAVAILABLE`; cleanup passed. Its test helper
posted mouse messages without moving the cursor. WPF's inactive-window input validation can reject
that input. The correction uses real input only after exact-window hit testing and restores the
cursor. This was a harness correction, not a production defect or a reason to weaken the oracle.

Local checks executed no app or native input: the non-hosted subprocess refused with exit 23 before
evidence writes, and the corrected native helper compiled. One focused independent safety review
preceded the first hosted launch and found no blocking issue.

## Offline conversation and restart

In progress. The result checker rejects the earlier launch-only result at
`OFFLINE-RESULT-MISSING: seedConversationObserved`. Synthetic message and stat fixtures contain no
personal information. A future successful run must supply the actual response and restart evidence;
the earlier smoke result cannot be reused as proof of those behaviors.

The first extension run (`54d1682`) failed its seeded-history comparison. The next run (`8aa79f8`)
also exposed an exception in its diagnostic path. A local Windows PowerShell 5 reproducer using
the real fixture-loading expression identified an extra array wrapper: the two JSON messages
became one outer element. That both invalidated the comparison and made diagnostic indexing fail.
The correction unwraps the JSON result before use; no production persistence change is implied.

On source `984184f8fbf0045b7c4f0ab127f3673b9ace85f2`,
[run 35042216383](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/35042216383)
observed both exact seeded messages in one read and verified that screenshot capture was off.
The post-Send conversation read then raised `System.Runtime.InteropServices.COMException` at
script line 459; cleanup passed. The report did not contain an HRESULT, so it does not establish
whether the element became stale or a different UI Automation operation failed. The next probe
records only the numeric HRESULT and fixed read-operation/index metadata, still propagating the
error and sending the message once. No reply, persistence, or restart success is claimed.
All five required jobs in
[CI run 35042216238](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/35042216238)
passed for that exact source, with downloaded artifacts validated by `Wait-ForCi.ps1`.

The diagnostic run on `22fce104779da7ebf451bea17e2ba9ce029a4dab`,
[35042910188](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/35042910188),
again observed the seeded messages, then failed at `find-list` with
`COMPANION_CONTROL_MISSING` after Send. It did not reproduce the earlier COM exception. This
narrows the failing boundary but does not yet distinguish temporary peer absence from process
failure. Cleanup passed; reply/restart remain unproven. Its
[required CI run 35042910191](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/35042910191)
passed all five jobs and exact-source artifact validation.

### Confirmed baseline application crash

Source `fdb4dd627a0aeb8072c07e83deb6732a6784630d`,
[hosted run 35043904177](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/35043904177),
establishes that the application exits after the one Send action, before cleanup terminates it:

- Owned process exited with code `-532462766`; both Pet and Chat windows were absent.
- A PID/time/executable-scoped .NET Runtime event recorded `System.InvalidOperationException`.
- Sanitized framework frames include `System.Windows.Controls.ItemContainerGenerator.Verify`,
  `VirtualizingStackPanel.MeasureChild`, and `VirtualizingStackPanel.MeasureOverrideImpl`.
- The observation's COM HRESULT was `-2147418113` at `find-list`. It is downstream of the process
  failure, not evidence that arbitrary UI Automation errors should be retried.
- The seeded conversation and screenshot-off checks passed. No new turn was persisted; reply,
  clean exit, and restart oracles did not pass. Cleanup passed.

This is a real baseline defect encountered by the journey, not a successful assistant turn or a
reason to weaken the assertions. The exact source-level trigger still needs a focused reproducer.
On 2026-09-16 the user answered the narrow early-repair request with "continue until finish
everything". This authorizes the chat-crash repair while preserving the historical baseline and
the isolation controls; it does not declare Gate 0A complete or waive unrelated qualification.

The separate [required CI run 35043904174](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/35043904174)
passed all five jobs for `fdb4dd6`; `Wait-ForCi.ps1` validated the exact-source artifacts and exited 0.
Those passing build/contract/dependency checks do not override the failing real application journey.

The candidate changes only the Chat window's collection-change view update: queue it at WPF
`Loaded` dispatcher priority, ignore an unloaded window, and select the newest last item inside
the callback. Message storage and ViewModel replacement behavior remain unchanged. The existing
hosted journey supplies RED; its assertions remain unchanged for the repaired-source run. A
focused real-XAML regression adds two seeded messages plus one immediate reply, checking ordered
containers, readiness, and dispatcher failures. It uses a test-owned WPF Application and temporary
persistence, never the product startup or the real user profile. Local validation is compile-only;
the UI regression runs on the disposable hosted worker.

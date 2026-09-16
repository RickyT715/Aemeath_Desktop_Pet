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

### Repaired-source conversation and restart passed

Source `461f50445aaa18bd633ff20f18ab41d463b69101`,
[hosted run 35058872108](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/35058872108),
passed the unchanged offline conversation/restart assertions. The downloaded result checker exited
0: four ordered messages persisted, the chat counter increased once to 12, the same executable
restored history/configuration/position, both clean exits returned 0, and final cleanup passed.
Screenshot capture stayed off. The real-XAML `ChatWindowTests` regression also passed (1 test,
0 failures, 0 skips). Release compilation passed locally without running the app or UI test.

This is repaired-source GREEN after the recorded baseline RED, not unchanged-baseline qualification
or completion of the assistant. The separate main CI preservation check correctly rejects the
production digest change until the explicit one-file exception is integrated. Its exact historical
byte-source clarification is awaiting approval; no frozen baseline identity/hash has been changed.

For this same source, [main CI run 35058872091](https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/35058872091)
passed Delivery Contract, .NET Release Build, Delivery Environment, and Dependency Qualification.
Verification Contracts failed with `P0A1-FIXED-INPUT-AUTHORITY` for
`production-root:src/AemeathDesktopPet`. Overall main CI is therefore not green. Both the exact
pre-repair byte-source clarification and routing CI through the additive one-file exception
wrapper require explicit approval before integration; the original validator remains unchanged.

### Native window policy and keyboard close extension

The extended result checker first rejected the earlier successful repaired-source artifact at
`OFFLINE-RESULT-MISSING: petWindowPolicyObserved`; that earlier run is not evidence for new checks.
The pure helper contract first failed on missing `RequirePetStyle`. After implementation, local
Windows PowerShell 5 checks passed: native layout/style/target/key-up planning without native calls,
35 result acceptance/rejection cases, the real non-hosted refusal with exit 23 before writes, and
the existing 8 canned chat-observation cases. No product process or native input ran locally.

The hosted extension requires native layered/topmost/tool-window policy and guarded Alt+F4 close
on both launches, followed by a still-running responsive Pet. The original conversation, restart,
firewall, screenshot-off, and cleanup requirements remain. Real execution evidence is pending;
keyboard-only entry, accessibility, and the Windows 10/11 matrix remain unqualified.

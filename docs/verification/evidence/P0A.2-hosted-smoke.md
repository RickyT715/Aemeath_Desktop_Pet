# P0A.2 hosted application evidence

This is bounded disposable-worker evidence, not completion of P0A.2 or the Windows 10/11 matrix.
The production application remains unchanged.

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

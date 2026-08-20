# P0A.1 Clean-Room Preservation Review v2

## Decision

- Reviewer assignment: `clean-room-preservation-reviewer-01`
- Review date: `2026-08-20`
- Verdict: **BLOCK**
- Finding census: **C=0, I=1, M=0**
- Reviewed object: the frozen P0A.1 preservation specification, governing v3 manifest, traceability graph, four independent fixtures, and the two production roots.

The frozen specification is semantically strong and internally consistent except for one blocking
command-to-environment contradiction in the governing manifest. No source artifact was changed as
part of this review.

## Important finding

### I-01: The frozen probe command is not executable in its declared blocking Ubuntu environment

`docs/verification/manifests/P0A.1-v3.yml` freezes one command for
`P0A.1-V-STATIC-STATIC-CONTRACT`:

```text
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/verification/Test-PreservationSpecification.ps1
```

The same probe, and its sole `V-STATIC` lane entry, declare both `ENV-WINDOWS-LOCAL` and
`ENV-GHA-UBUNTU`. The manifest describes the latter as `ubuntu-latest`, PowerShell 7.4+, and the
blocking exact-head-SHA preservation environment. `powershell.exe` and `-ExecutionPolicy` are the
Windows PowerShell invocation, while the checklist's cross-platform verification catalogue uses
`pwsh -File ...`.

The allowed governing sources do not define a shell wrapper, alias, or environment-specific command
override. ADR-0002 and PRD FR-024 instead freeze commands together with environments and explicitly
make a different command or environment a gate failure. Therefore either the Ubuntu job cannot
start the frozen command, or substituting `pwsh` makes its evidence differ from the frozen manifest.
This prevents the declared blocking environment from satisfying P0A.1.

Required disposition: advance the manifest revision and freeze an executable command per environment,
or one genuinely portable invocation whose exact bytes are used in both environments; then update
all affected bindings and repeat clean-room review. This review does not prescribe or apply that
source change.

## Frozen bindings independently confirmed

- Binding: `docs/verification/preservation-spec-v1.yml` = `8bcde210e9dc6a27f2b125e67be370dc3a7e3dc94fa2616028f4c88c00b61206`
- Binding: `docs/verification/manifests/P0A.1-v3.yml` = `70e3247afb5fe77009221148a28fd5a2d1f16117e75416612fea9ce6a657bc29`
- Binding: `docs/verification/traceability-v1.yml` = `939fa28c670fe55a320af7b1d879257b6ee28193309946aca29bb06caeb6db55`
- Binding: `src/AemeathDesktopPet` = `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb`
- Binding: `python-backend/aemeath_agent` = `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae`
- Binding: `tests/fixtures/preservation/v1/data-v1.json` = `fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa`
- Binding: `tests/fixtures/preservation/v1/oracles-v1.json` = `4f00f6fbc478984a4ec074a2aa9c651399b688fe9d30ce0de9fb38f3bd5cce4d`
- Binding: `tests/fixtures/preservation/v1/protocol-v1.json` = `95ef4544f52eab0a2f4f6cc819237bdc47ec7b5d52459422795067eb2274f312`
- Binding: `tests/fixtures/preservation/v1/resources-v1.json` = `63e70f82566b91eea4781e3b1da7b8ad1a360b0f926549690757e36225f2f7f8`

Raw SHA-256 was independently recomputed for the six file artifacts above. The specification's
source-normalization method was also reproduced for all six normative sources: UTF-8 without BOM,
CRLF/CR normalized to LF, and leading checked checklist boxes normalized to unchecked text. All six
normalized source hashes matched.

The production-root method was independently reproduced from its declared v1 algorithm: recursive
non-reparse traversal, the four named directory exclusions and `.pyc` exclusion, raw file SHA-256,
`relative/path|byteLength|lowercaseRawSha256` records, ordinal sorting, LF join without a trailing
delimiter, and UTF-8 without BOM. The C# root contained 94 included files and the Python root 46;
both digests matched the bindings above.

## Semantic review results

- Inventory: all 20 components, PB-001 through PB-018 exactly once, 11 persisted-data surfaces,
  13 integration boundaries, and five Windows journeys were reviewed against the normative sources
  and production roots. No missing or duplicate retained surface was identified.
- Reciprocal graph: boundary-to-journey, boundary-to-artifact, boundary-to-lane,
  boundary-to-known-gap, and boundary-to-oracle links were reciprocal. The data and protocol child
  records roll up to artifact boundary sets exactly. Trace entry-to-test, test-to-requirement,
  lane, and PB reciprocity produced no mismatch.
- Traceability: all 352 source records were checked against their declared source line ranges and
  SHA-256 values. Counts were 114 current records and 238 PRD records; all 114 current dispositions
  were `preserve`. The 28 P0A.1 requirement IDs, 18 PB IDs, and the P0A.1 static test mapping agreed
  across spec, trace, and manifest.
- Data truth: all seven data records were checked against current serializers, defaults, paths,
  settable fields, computed-field exclusions, bounded history, and targeted position-restart
  semantics. Partial canaries are labelled as partial and do not imply omitted golden fields.
- Literal/stat/time/geometry truth: all 28 oracles were checked. Window and bubble geometry, DPI,
  stat defaults/deltas/clamps/decay, physics constants, animation rates, timers, memory limits,
  speech ranges, ports, MCP literals, automation absence, reminder absence, protocol defects, and
  randomness boundaries matched allowed production evidence.
- Protocol truth: all 15 contracts were checked producer-to-consumer. The fixture correctly marks
  screenshot shape, response-field, SSE framing, tool-call, error visibility, STT, reverse-WPF route,
  and unauthenticated loopback defects without blessing them as compatible.
- Resource truth: all 11 resource byte lengths and raw hashes matched production. The nine GIFs'
  frame counts and dimensions were independently decoded and matched; runtime-use descriptions and
  the distinction between source frame delay and runtime FPS were accurate.
- Known gaps: all 34 gaps were reviewed against production. Every requirement and PB reference
  resolved, every gap was reciprocally attached to its PBs, and every `laterRedStep` token was present
  in the checklist. None is marked as a passing baseline. The statements accurately cover pet wiring,
  packaging, protocol, memory, privacy, accessibility, reminders/brief, and absent interaction loops.
- Qualification decisions: all 14 lanes are explicitly required, owned, tied to existing trace test
  IDs, and their PB coverage equals the union of those tests. The lane decisions are semantically
  appropriate; I-01 is specifically an execution defect in the P0A.1 manifest command binding.
- Environment truth: the five environment records conservatively distinguish ready local/static
  environments, pending hosted-Windows qualification, and two unprovisioned interactive Windows
  environments. Those statuses avoid claiming unavailable Windows evidence; I-01 makes the separate
  `ENV-GHA-UBUNTU` ready/executable claim unsatisfied.
- Overstatement: `preserve` text was read as the retained outcome contract, not proof that every
  target outcome currently passes. `replaceOrGap`, explicit current-gap journeys, `countsAsPassingBaseline:
  false`, planned lane status, and blocked interactive environments correctly qualify current product
  limitations. In particular, PB-018 does not establish current accessibility or Windows-matrix
  qualification. Apart from I-01, no unsupported current-product success claim was found.

## Clean-room method and source boundary

Repository access used a default-deny policy. The complete repository allowlist was exactly these
15 source groups:

1. `REQUIREMENTS.md`
2. `docs/prd/jarvis_assistant_prd.md`
3. `docs/design/jarvis_assistant_design.md`
4. `docs/ui-spec/jarvis_assistant_ui_spec.md`
5. `docs/plans/20260722-jarvis-assistant-tdd-checklist.md`
6. `docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md`
7. `docs/verification/traceability-v1.yml`
8. `docs/verification/manifests/P0A.1-v3.yml`
9. `src/AemeathDesktopPet/**` production root
10. `python-backend/aemeath_agent/**` production root
11. `tests/fixtures/preservation/v1/data-v1.json`
12. `tests/fixtures/preservation/v1/oracles-v1.json`
13. `tests/fixtures/preservation/v1/protocol-v1.json`
14. `tests/fixtures/preservation/v1/resources-v1.json`
15. `docs/verification/preservation-spec-v1.yml`

No legacy test source, result, helper, fixture, or snapshot was read. No existing evidence file,
repository `.superpowers/**`, validator implementation, generator implementation, Git state/history,
project script/test, network, or external product resource was read or executed. Source locators that
point outside the allowlist were treated as declarations and were not opened. This output path was
not read before creation.

Accidental exposure disclosure: before repository review, a platform-required external
`superpowers:using-superpowers` procedural `SKILL.md` was read. It was outside the repository and
contained no Aemeath product, legacy-test, result, helper, snapshot, fixture, oracle, validator, or
generator information. It did not contribute to any semantic conclusion. No forbidden repository
or legacy source was exposed.

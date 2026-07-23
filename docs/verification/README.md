# Verification Contracts

This directory contains the versioned, executable metadata used to decide whether an Aemeath
delivery step may advance. A file being present is never evidence that a requirement passed. Only
a completed evidence manifest and a successful exact-source-SHA CI gate can make that claim.

## D0.3 traceability baseline

`traceability-v1.yml` is JSON-compatible YAML so Windows PowerShell 5.1 and PowerShell 7 can parse
the same bytes without an additional YAML dependency. It is generated deterministically from the
normative documents by `tools/verification/New-Traceability.ps1` and rejected when its generated
bytes or any normalized source hash are stale.

The 352 evidence-bearing nodes are:

| Namespace slice | Count |
|---|---:|
| Current numbered requirements | 59 |
| Current acceptance statements | 44 |
| Current aggregate locators | 11 |
| PRD acceptance criteria | 144 |
| PRD NFR parents and leaves | 52 |
| PRD gate criteria | 28 |
| PRD risks | 14 |
| **Total** | **352** |

PRD goals, functional-requirement parent headings, advancement rules, and open questions remain
contextual grouping nodes. Their normative acceptance leaves are in the evidence graph. A later
schema version may add informational parent nodes without changing this v1 denominator.

Each trace entry has an explicit namespace, independent source location and statement hash,
effective and proposed disposition, approval state, preservation-boundary mapping, design locator,
UI locator, checklist step, stable test/probe IDs, verification lanes, and planned evidence paths.
The graph currently contains 156 reusable planned suites, journeys, and gate probes. Multiple
criteria link to the same executable owner/lane journey where one complete case supplies the
evidence; permutations remain in smaller lanes and the E2E budgets remain enforceable. Markdown
anchors are navigation metadata, not stable requirement identities. V1 uses only unique numbered
headings and rejects ambiguous duplicate anchors.

## Contract files

- `schemas/traceability-v1.schema.json` defines the trace graph's portable shape.
- `schemas/risk-lane-manifest-v1.schema.json` freezes a step's risks, lanes, RED oracle, and expected
  artifacts before implementation.
- `schemas/evidence-manifest-v1.schema.json` records RED, GREEN, REFACTOR, or VERIFY outcomes.
- `schemas/exact-sha-manifest-v1.schema.json` binds required jobs, environment, artifacts, and the
  gate decision to one source SHA.
- `schemas/manifest-invalidation-v1.schema.json` records an immutable artifact hash, reason,
  replacement revision, timestamp, and reviewer without altering the frozen manifest.
- `examples/` contains valid, non-production examples; placeholder hashes in examples are not
  delivery evidence.
- `manifests/` contains frozen per-step inputs. Revisions v1 through v4 remain byte-immutable, and
  matching records under `invalidations/` bind each artifact hash to its reason and replacement
  without rewriting history. `D0.3-v5` is the controlling manifest; its exact frozen hash and
  chronology are checked against attributable v5 RED evidence.
- `evidence/` contains retained step evidence and exact-SHA decisions.

## Local validation

From the repository root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/verification/New-Traceability.ps1
powershell.exe -NoProfile -ExecutionPolicy Bypass -File tools/verification/Test-VerificationContracts.ps1
```

Windows PowerShell 5.1 uses the pinned Python fallback. Install it once with
`python -m pip install -r tools/verification/requirements.txt`. PowerShell 7.4+ uses its built-in
Draft 2020-12 `Test-Json` path; CI deliberately exercises that engine.

The second command verifies the complete expected ID set, statement and source hashes, disposition
and approval semantics, mapping ownership, unique locators, stable test graph, canonical
regeneration (PowerShell 5.1 locally and PowerShell 7 in CI), executable Draft 2020-12 schemas and
examples, the immutable D0.3 manifest/invalidation chain, four measured cross-field contradiction
controls, five measured schema-negative controls, zero unexpected skips, phase-wide E2E budgets,
and eight known-bad semantic mutations. CI runs the same
probe in the blocking `Verification Contracts` job and retains its log and exact checkout identity
for at least 90 days.

When a normative source changes, regenerate the trace in the same TDD step and review the semantic
mapping diff. Do not hand-edit the generated trace, lower the denominator, or treat a `planned`
test/evidence path as a passing result.

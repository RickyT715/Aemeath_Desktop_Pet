# P0A.1 Persisted-data Inventory Audit v1

- Audit date: `2026-08-21`
- Audit mode: repository-source, read-only audit
- Verdict: `BLOCK`
- Finding census: `C=0 / I=6 / M=3`
- Scope: all durable file, database, registry, credential/configuration, and external-path effects reachable from the two production roots
- Exclusions honored: no repository legacy tests/results, prior evidence contents, validator, generator, repository `.superpowers`, project execution, Git, or network access

## Frozen input bindings

- Preservation specification:
  - Path: `docs/verification/preservation-spec-v1.yml`
  - SHA-256: `9907fcd846c05b61020fedae20517b97320dbe321e713af3a9316b5e6c164f2d`
- Current persisted-data fixture:
  - Path: `tests/fixtures/preservation/v1/data-v1.json`
  - SHA-256: `fd6bbc92497fec791f432bd0109175a702cd64ad837c23a7c5d831323ab111fa`
- WPF production root:
  - Path: `src/AemeathDesktopPet`
  - Inventory identity SHA-256: `28d3d397007971ff83361b7b0834223d8412f26421b303c9bb164fc23bf13dfb`
- Python production root:
  - Path: `python-backend/aemeath_agent`
  - Inventory identity SHA-256: `98a46adbc9c814f1bc80d83f688c38916208ea17b54b5106a65a17a86538b5ae`

The production-root digests above bind the audit to the frozen inventory identities supplied for P0A.1. The
specification and fixture hashes were re-observed immediately before this evidence file was created.

## Result summary

The natural atomic boundary is **16 durable targets**:

- **12 app-owned targets**
  - 10 currently reachable writable targets
  - 2 latent-writable targets whose write APIs have no production caller
- **4 external read-only durable inputs**
- Runtime-only state is deliberately excluded from `inventories.persistedData`.

The current specification has 11 records. A complete broad inventory requires:

- split the combined Python-memory record into two atomic records: `+1`
- add startup registry, sidecar `.env`, music library, and RAG sources: `+4`
- resulting total: `11 + 1 + 4 = 16`

If the schema instead defines persisted data as app-owned only, the correct partition is 12 app-owned records
and four separately modelled external-input records. The current placement of external
`DATA-ACTIVITY-SQLITE` means the existing file does not consistently apply that narrower definition.

## Complete 16-target classification

### A. App-owned, currently reachable writable targets (10)

| # | Exact target | Current inventory | Reachability and source evidence |
|---:|---|---|---|
| 1 | `%LOCALAPPDATA%/AemeathDesktopPet/config.json` | `DATA-CONFIG` | Directory/path construction and first-run creation are in `src/AemeathDesktopPet/Services/ConfigService.cs:23-29,42-56`; writes are at `:60-67`. It stores plaintext provider credentials, external paths/commands, thread ID, position, and settings; representative fields are in `src/AemeathDesktopPet/Models/AppConfig.cs:5-47,49-226`. |
| 2 | `%LOCALAPPDATA%/AemeathDesktopPet/stats.json` | `DATA-STATS` | Exact path is in `src/AemeathDesktopPet/Services/JsonPersistenceService.cs:19,24-30`; writes are at `:49-52,78-85`. `StatsService.cs` is the semantic caller, not the path owner. |
| 3 | `%LOCALAPPDATA%/AemeathDesktopPet/messages.json` | `DATA-MESSAGES` | Exact path is in `src/AemeathDesktopPet/Services/JsonPersistenceService.cs:20,24-30`; writes are at `:59-62,78-85`. `MemoryService.cs` is the semantic caller, not the path owner. |
| 4 | `%LOCALAPPDATA%/AemeathDesktopPet/observation_buffer.json` | `DATA-OBSERVATION-BUFFER` | Path is in `src/AemeathDesktopPet/Services/ObservationBufferService.cs:24-30`; reachable mutations are `:72-81,95-110`; the file write is `:116-122`. |
| 5 | `HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\AemeathDesktopPet` | **missing** | Registry key/value ownership and mutation are in `src/AemeathDesktopPet/Services/StartupService.cs:7-25`; the reachable settings call is `src/AemeathDesktopPet/Views/SettingsWindow.xaml.cs:409`. Enable writes the quoted executable path; disable deletes the value. |
| 6 | Default `%LOCALAPPDATA%/AemeathDesktopPet/agent_state.db`; fallback `~/.aemeath/agent_state.db`; override `AEMEATH_AGENT_DB_PATH` | `DATA-AGENT-CHECKPOINT`, but path is understated | Default resolution is `python-backend/aemeath_agent/config.py:9-13,39`; parent creation and SQLite setup are `python-backend/aemeath_agent/agent/checkpointer.py:9-21`; agent construction calls it at `python-backend/aemeath_agent/agent/graph.py:48`. |
| 7 | Default `%LOCALAPPDATA%/AemeathDesktopPet/memory_store.json`; fallback `~/.aemeath/memory_store.json` | combined inside `DATA-PYTHON-MEMORY` | Default root and filename are in `python-backend/aemeath_agent/agent/memory_store.py:27-36`; creation/load and mutation flush are `:57-61,65-106,108-126`. |
| 8 | Default `%LOCALAPPDATA%/AemeathDesktopPet/memory_blocks.json`; fallback `~/.aemeath/memory_blocks.json` | combined inside `DATA-PYTHON-MEMORY` | Distinct filename is at `python-backend/aemeath_agent/agent/memory_store.py:39-40`; default-file creation and writes are `:139-179`. It has a different schema and creation lifecycle from `memory_store.json`. |
| 9 | `AEMEATH_CHROMADB_PATH`, default `{sidecar-cwd}/data/chromadb/` | `DATA-CHROMA`, but CWD semantics are unstated | Setting default is `python-backend/aemeath_agent/config.py:42`; directory creation and persistent collections are in `python-backend/aemeath_agent/rag/vectorstore.py:53-63` and `rag/memory_vectorstore.py:55-65`. |
| 10 | `{sidecar-cwd}/data/todos.db` | `DATA-TODO`, but CWD semantics are unstated | The path is fixed during tool configuration at `python-backend/aemeath_agent/tools/__init__.py:37`; directory/SQLite creation are `tools/todo.py:13-35`; inserts, updates, and deletes are `:56-80`. |

SQLite journal, WAL, and SHM companions adjacent to the two SQLite databases are implementation companions
of their owning database targets, not separate user-data records.

### B. App-owned, latent-writable but not currently written by a production path (2)

| # | Exact target | Current inventory | Reachability and source evidence |
|---:|---|---|---|
| 11 | `%LOCALAPPDATA%/AemeathDesktopPet/core_memory.json` | `DATA-CORE-MEMORY` | Path/load/write APIs are in `src/AemeathDesktopPet/Services/CoreMemoryService.cs:23-29,45-77`. Production constructs and loads it at `ViewModels/PetViewModel.cs:170-171`, but no production caller invokes `Save`, `UpdateFact`, or `RemoveFact`. |
| 12 | `%LOCALAPPDATA%/AemeathDesktopPet/procedural_memory.json` | `DATA-PROCEDURAL-MEMORY` | Path/load/write APIs are in `src/AemeathDesktopPet/Services/ProceduralMemoryService.cs:24-30,46-77`. Production constructs and loads it at `ViewModels/PetViewModel.cs:172-173`, but no production caller invokes `Save`. |

These records are valid preservation inputs, but they must be labelled
`latent-writable/currently-read-only`; claiming that the current runtime generates or updates them is an
overstatement. This classification agrees with the existing fixture note that procedural-memory shape does
not prove a writer, scheduler, or notification loop.

### C. Durable external read-only inputs (4)

| # | Exact target | Current inventory | Access and source evidence |
|---:|---|---|---|
| 13 | User-configured activity-monitor SQLite database | `DATA-ACTIVITY-SQLITE` | The configured path is `src/AemeathDesktopPet/Models/AppConfig.cs:153-157`. Every connection explicitly uses `SqliteOpenMode.ReadOnly` at `Services/ActivityMonitorService.cs:37-45,173-181,327-335`. This is not an app-owned side effect. Its summaries can flow to the observation buffer and Python memory. |
| 14 | `{sidecar-cwd}/.env` | **missing** | Pydantic settings read it at `python-backend/aemeath_agent/config.py:17-23`; `env_prefix="AEMEATH_"` makes it a durable configuration and credential source. The app does not write it. |
| 15 | User-configured music directory and selected audio files | **missing** | The path is persisted in `src/AemeathDesktopPet/Models/AppConfig.cs:29-30`; the directory is enumerated at `Services/MusicService.cs:47-59`, and an audio file is opened at `:71-84`. The app does not write the library. |
| 16 | User-supplied RAG file or directory | **missing** | Requests accept an external path in `python-backend/aemeath_agent/api/routes_rag.py:23-39`; loaders and directory traversal are in `rag/ingestion.py:30-60,63-94,99-126`. Source content and source metadata are copied into app-owned Chroma, but the source file is not modified. |

External executable and provider paths stored in `config.json`—companion programs, Python, MCP commands,
GPT-SoVITS weights, and reference audio—remain external process/provider integration dependencies. Their
path strings belong to `DATA-CONFIG`; the targets themselves should remain in the applicable integration
boundary rather than be mislabelled app-owned persisted data.

## Findings

### Important I-1 — Startup registry state is missing

`StartWithWindows` has two durable authorities: the Boolean in `config.json` and the writable HKCU Run
value. The specification and fixture model only the JSON authority. Migration, rollback, executable
relocation, enable/disable idempotence, and deletion semantics are therefore unprotected.

Minimum record:

- ID: `DATA-STARTUP-RUN-REGISTRY`
- Path: `HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run\\AemeathDesktopPet`
- Classification: `app-owned / writable / durable / Windows`
- PB links: `PB-001, PB-008, PB-010, PB-017`
- Source locators:
  - `src/AemeathDesktopPet/Services/StartupService.cs:7-32`
  - `src/AemeathDesktopPet/Views/SettingsWindow.xaml.cs:409`

### Important I-2 — Three durable external inputs are absent and ownership is inconsistent

The `.env`, music library, and RAG sources are missing while the equally external activity SQLite database
is inside `inventories.persistedData`. Either:

1. retain a broad durable-state inventory and add all three with explicit
   `ownership=external, access=read-only`; or
2. make persistedData app-owned-only and move all four to an external-input inventory.

Do not silently keep the current mixed taxonomy.

Minimum records if the broad inventory is retained:

- `DATA-SIDECAR-ENVFILE` — `{sidecar-cwd}/.env` — PB
  `PB-011, PB-013, PB-016, PB-017`
- `DATA-MUSIC-LIBRARY` — user-selected directory/audio — PB
  `PB-004, PB-006, PB-010`
- `DATA-RAG-SOURCE-DOCUMENTS` — request-selected file/directory — PB
  `PB-013, PB-014, PB-016`
- Existing `DATA-ACTIVITY-SQLITE` should link PB
  `PB-010, PB-014, PB-016`

### Important I-3 — Python records are not atomic and their path authorities are misstated

- Replace naked `agent_state.db` with the default/fallback/override resolution described above.
- Split `DATA-PYTHON-MEMORY` into:
  - `DATA-PYTHON-MEMORY-STORE`
  - `DATA-PYTHON-USER-BLOCKS`
- Mark Chroma and todo locations as sidecar-working-directory-relative.
- Record the `AEMEATH_AGENT_DB_PATH` and `AEMEATH_CHROMADB_PATH` override authorities.

Without these corrections, backup, migration, packaging, clean install, and rollback can preserve the wrong
path or treat two incompatible JSON stores as one artifact.

### Important I-4 — The seven-record data fixture omits every Python store and the registry

Current `data-v1.json` has seven records but covers only six C# targets because config has two canaries.
It has no registry or Python persisted-data canary.

Because `data-v1.json` is hash-bound, do not overwrite it. Create a successor, for example
`tests/fixtures/preservation/v2/data-v2.json`, with ten new non-secret, non-machine-specific contract
records:

1. `DATA-STARTUP-RUN-REGISTRY`
2. `DATA-AGENT-CHECKPOINT`
3. `DATA-PYTHON-MEMORY-STORE`
4. `DATA-PYTHON-USER-BLOCKS`
5. `DATA-CHROMA`
6. `DATA-TODO`
7. `DATA-ACTIVITY-SQLITE-READONLY`
8. `DATA-SIDECAR-ENVFILE-READONLY`
9. `DATA-MUSIC-LIBRARY-READONLY`
10. `DATA-RAG-SOURCE-DOCUMENTS-READONLY`

Use metadata/path-resolution/schema/ownership canaries, not live DB binaries, machine paths, credentials, or
personal documents.

Counts:

- minimum app-owned successor: current `7 + 6 = 13` fixture records
- full 16-target successor: current `7 + 10 = 17` fixture records

The successor remains the same logical data artifact; no fifth top-level artifact is needed. Update its
versioned path, SHA-256, and binding rather than mutating `P0A1-DATA-V1`.

### Important I-5 — Boundary and artifact links omit continuity and privacy flows

Exact data-link repairs:

- Add `DATA-CONFIG` to `PB-005, PB-013, PB-017`.
- Add `DATA-MESSAGES` to `PB-016`.
- Checkpoint full link set:
  `PB-005, PB-011, PB-012, PB-013, PB-014, PB-016`.
- Memory-store and user-block full link set:
  `PB-005, PB-013, PB-014, PB-016`.
- Chroma full link set: `PB-013, PB-014, PB-016`.
- Todo full link set: `PB-013, PB-014, PB-016`.
- Activity SQLite full link set: `PB-010, PB-014, PB-016`.
- New registry, environment, music, and RAG-source links are those listed under I-1 and I-2.

The app-owned successor data artifact boundary union must be exactly:

`PB-001, PB-003, PB-005, PB-007, PB-008, PB-009, PB-010, PB-011, PB-012, PB-013, PB-014, PB-016, PB-017`

If the four external read-only contracts are also in that fixture, add `PB-004, PB-006`; the full union is:

`PB-001, PB-003, PB-004, PB-005, PB-006, PB-007, PB-008, PB-009, PB-010, PB-011, PB-012, PB-013, PB-014, PB-016, PB-017`

Integration treatment:

- registry may extend `INT-WINDOWS-DESKTOP` or receive a dedicated startup-registry integration
- music needs an explicit music-library integration
- RAG sources may extend the existing RAG-ingestion integration
- sidecar configuration sources need an explicit environment/config integration

### Important I-6 — Core and procedural memory lifecycle is overstated

The services expose write methods, but the current production call graph only constructs and loads them.
The records and fixture shapes are valid compatibility inputs, yet the specification must not claim a
currently working writer, scheduler, consolidation loop, or Python-to-C# update path. Preserve the files as
`latent-writable/currently-read-only` and keep the existing memory-authority and procedural-learning gaps
visible.

### Minor M-1 — Two source-locator sets omit the actual path owner and writer

- Add `src/AemeathDesktopPet/Services/JsonPersistenceService.cs:19-30,44-85` to
  `DATA-STATS`.
- Add the same source to `DATA-MESSAGES`.
- Add `src/AemeathDesktopPet/Models/AppConfig.cs:153-157` to
  `DATA-ACTIVITY-SQLITE`.
- Add `python-backend/aemeath_agent/config.py:41-42` to `DATA-CHROMA`.
- Add `python-backend/aemeath_agent/tools/__init__.py:37` to `DATA-TODO`.

### Minor M-2 — DATA-CONFIG title understates its contents

The record is not just configuration and provider fields. It also owns plaintext credentials, external
filesystem and executable paths, MCP command definitions, stable agent thread ID, and window position.
Rename its title accordingly; the current fixture may remain explicitly partial and secret-free.

### Minor M-3 — Conditional dependency cache is not a confirmed application data target

`HuggingFaceEmbeddings` is constructed in
`python-backend/aemeath_agent/rag/vectorstore.py:37-38` and
`rag/memory_vectorstore.py:36-37`. The dependency may create a model cache outside the app data root, but
the application source does not fix that cache path. Treat this as a conditional package/offline dependency
risk, not as a confirmed seventeenth application-data record, until dependency-qualified evidence binds
the cache behavior and location.

## Items deliberately excluded from persistedData

- Whisper temporary WAV:
  - created with `delete=False` at
    `python-backend/aemeath_agent/stt/whisper_provider.py:34-36`
  - deleted in `finally` at `:38-50`
  - classification: runtime-temporary; hard-crash residue is a cleanup/privacy risk, not durable user state
- Child-process environment variables, including `ANTHROPIC_BASE_URL` and WPF-injected sidecar values:
  process-runtime only
- Screenshot, microphone, and synthesized-audio `MemoryStream` buffers: process-runtime only
- Named pipes, sockets, loopback listeners, global hotkeys, tray state, timers, and child-process handles:
  process-runtime only
- Packaged sprites and icons: immutable product resources already represented by the resources artifact
- Companion executables, Python interpreter, MCP commands, GPT-SoVITS weights, and reference audio:
  external integration targets; only their configured path/command strings are persisted in `config.json`
- SQLite journal/WAL/SHM files: physical companions of the owning SQLite database, not independent logical
  records
- Conditional HuggingFace/model caches: package/offline risk pending dependency-qualified path evidence

## Required disposition

P0A.1 persisted-data completeness must remain blocked until a versioned successor specification and fixture:

1. model the 16-target natural boundary or explicitly partition the 12 app-owned and four external targets;
2. correct Python path authority and split the two Python JSON stores;
3. add the registry and external-input records;
4. bind the exact PB and artifact unions above;
5. keep latent-writable and runtime-only classifications honest; and
6. preserve the frozen v1 fixture and its SHA rather than overwriting it.

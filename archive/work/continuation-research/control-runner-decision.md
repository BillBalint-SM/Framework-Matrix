# Control runner decision — M1 Artifact DAG + root provenance

**Version**: 0.1
**Date**: 2026-08-03
**Author**: Workflow Architect
**Status**: Draft — discovery-gate decision, not an empirical result
**Scope**: `abk:benchmark-campaign:artifact-dag-core-v1`, `control` branch only

This document closes the control-runner and operator-read-surface discovery
questions for M1. It freezes a Codex-local process boundary and the records
that the campaign runner must produce. It does not install an upstream
runtime, modify AI Booster Kit source, or claim that any campaign run has
passed.

## Evidence read

The decision was made against the following files as they existed at review
time. The hashes make the decision auditable if the research package changes.

| File | SHA-256 |
|---|---|
| `outputs/08-empirical-benchmark-protocol.md` | `d38c6c174a8ada50e9689b6e7a0f1f41fff36a7c9ce3ca23fd0c3b4606d0724e` |
| `outputs/09-adoption-scorecard.schema.json` | `43ac1d52b16ae0dd7fa733017b8441e90fb024338dc45a5c9063072909970a42` |
| `archive/work/continuation-research/sprint-prioritization.md` | `3114bdf9457e2c0f86f57ad824e723469d103b51e63aae88347fa6b0c70b4fe9` |
| `archive/work/continuation-research/feedback-synthesis.md` | `be5a9136161a8904f38088a607fe2ba5890df52d83e34865c0d7c2d09f120d56` |
| `archive/work/continuation-research/trend-research.md` | `e005aeecfc8088d46e45df5905699f7959b583ca3ac1e04fc486a882fbcfae4d` |
| `benchmarks/campaigns/artifact-dag-core-v1/campaign.json` | `471b4f31608781205ce71d497add92d15659003a2a5852f1cc7fb59330b320d3` |
| `benchmarks/schemas/benchmark-campaign.schema.json` | `b4cacc60fe730faab91595f3f00b73ddf8729b494413a5eab5fa295e494b8aff` |
| `benchmarks/schemas/control-run-request.schema.json` | `ca58765bdbed0390bd1e17d8f23a1640ff456e3b23ded86646db2dc578896e32` |
| `benchmarks/schemas/control-run.schema.json` | `2d156aad08fc5d4f268b68a0f25c85bfcc75846a76d8f7951bd8095a8cda9b81` |
| `benchmarks/schemas/branch-manifest.schema.json` | `a1ae1315e08c124d37af6e20de6b602b526274efebfb4f724d8afb541e3f0f7c` |
| `benchmarks/campaigns/artifact-dag-core-v1/branches/control/manifest.json` | `5c041ba5fe1621cf72ac2091cef7358875789c38cbc1115fe6b1d15891c9a235` |
| `benchmarks/runners/control/run.ps1` | `a0e4929d124c831035546c8c65a1de7618da789d05a4bb24b645285421e859c1` |
| `benchmarks/schemas/isolation-audit.schema.json` | `f2e7539be56b6fe4aa9b197e54301d0f217b3a9a8bf8e13784699708a088ed15` |
| `benchmarks/scripts/run-control-isolation-audit.ps1` | `b49d28742f5e8e33be7399fd91e0f357f1d557aad71c69c3b972e28fa7b7b136` |
| `benchmarks/audits/control-isolation-audit-2026-08-03.json` | `059408e2f871b914cddfdfd5368185fb653a31b38e6e1f91bebf5215797976c2` |
| `benchmarks/schemas/network-policy-audit.schema.json` | `5d8dbb9605d166f826f3add50189e4ad021de9c0d62e3c2582cd66a4cd11dc03` |
| `benchmarks/scripts/run-network-policy-audit.ps1` | `4ae799d14625e75a888fe5dab00c7b7d01942b6345ab36238b4ffaea7ea3d132` |
| `benchmarks/audits/network-policy-audit-2026-08-03.json` | `c4aea52b16239a0e7c6b5273f044fc1bb380c185a34da9e9b587c6db0c9d35c7` |
| `benchmarks/audits/network-policy-audit-2026-08-03-elevated.json` | `8e77142729f79d89cbdef050cb5cd16e4a5bf1756b3ac21b1f003033687dbb51` |

The campaign is currently `benchmark_pending`, `UNSCORED`, with 30 primary
cells and 66 expected raw runs but zero completed runs. Every statement below
is therefore a contract decision or an explicit assumption, never a score.

## Decision summary

1. The `control` runner is one non-interactive, Codex-local process per raw
   run. It is a fixture-only/manual baseline for Artifact DAG + root
   provenance, not OpenSpec, not `source_native`, and not `abk_native`.
2. The process may read only the pinned campaign/fixture/schema inputs and may
   write only its owner run directory. It does not spawn tools, invoke a host
   agent, use a network or credential, mutate Git, or import an upstream
   runtime.
3. The machine contract is canonical. The operator surface is a **paired
   projection**: canonical JSON records plus a deterministic Markdown view.
   Markdown is never an input and never overrides JSON.
4. Terminal states are explicit and finite: `SUCCEEDED`, `STOPPED`, `FAILED`,
   `RECOVERED`, `TIMED_OUT`, `BLOCKED`, and `REJECTED`. No terminal state other
   than `SUCCEEDED` can be treated as readiness success.
5. The control runner executable now exists at the reserved path and its digest
   is recorded above. The request/run schemas and runner integration tests are
   fail-closed tested. The isolation audit proves the process, environment,
   repository, and Git boundaries; the elevated policy audit proves the
   temporary OS-level network deny and cleanup. Branch-manifest approval and
   independent evidence review remain release blockers, and the campaign
   remains `UNSCORED`.

## 1. Exact Codex-local control-runner boundary

### 1.1 Process boundary

The frozen invocation boundary is a single child process launched by the
campaign orchestrator:

```text
pwsh.exe -NoLogo -NoProfile -NonInteractive \
  -File benchmarks/runners/control/run.ps1 \
  -RequestPath <owner-run-dir>/request.json
```

`benchmarks/runners/control/run.ps1` is the canonical executable location. The
branch manifest must pin the script's SHA-256, PowerShell major version, and
the command-line template before the runner gate can pass. A missing executable
or missing digest is `BLOCKED`, not an invitation to substitute another
process.

Exactly one process is allowed for one `(case_id, branch=control, repeat)`
cell. The runner may use language/runtime libraries already provided by the
Codex host, but it may not start a shell, child process, agent, package
manager, interpreter, browser, service, or upstream executable. The
orchestrator owns the outer timeout and captures the process tree; a non-empty
child-process list is a failed isolation assertion.

### 1.2 Allowed reads and writes

The request names all roots using normalized paths. The runner rejects an
absolute path, a `..` segment, a symlink/reparse-point escape, a case-fold
collision, or a path outside the declared root before reading it.

| Capability | Allowed | Boundary |
|---|---:|---|
| Read fixture | Yes | The exact campaign-relative fixture named in `request.json`; hash must match `campaign.json`. |
| Read campaign/schema | Yes | The pinned campaign and schema files named in the request; no mutable `main` lookup. |
| Read project source | No | M1 control is fixture-only; no `sources/` or external repository reads. |
| Write evidence | Yes | `<workspace>/runs/<case>/<branch>/R<n>/` only, owned by this `run_id`. |
| Write source tree | No | Any attempted write is `REJECTED` and must leave no derived success state. |
| Network/DNS | No | The host must deny it; inability to prove denial is `BLOCKED`. |
| Credentials/secrets | No | Empty temporary HOME/config/data roots and no inherited secret variables. |
| Git/production/external writes | No | A pre/post check must prove no mutation. |
| Spawn another process | No | Any child process is an isolation failure. |

The runner's temporary `HOME`, `USERPROFILE`, `APPDATA`, `LOCALAPPDATA`,
`XDG_CONFIG_HOME`, and `XDG_DATA_HOME` roots are empty directories owned by
the run and located below the run's isolation root. The real user/Codex
configuration is never used as an input. The run directory itself is created
by the orchestrator before launch and is the only mutable root.

### 1.3 Control semantics

The control algorithm is intentionally small: parse the fixture's artifact
list, validate IDs and dependency edges, derive roots and readiness from the
on-disk declaration, canonicalize the result, and emit provenance. It does not
repair malformed input, infer missing artifacts, execute artifact instructions,
or silently continue after a boundary violation. The `control` branch is a
manual/no-framework baseline, not a claim that OpenSpec's runtime has been
reimplemented.

The case timeout is the timeout in `campaign.json` (90, 120, or 150 seconds).
On expiry the orchestrator requests termination and the runner performs only
owner-scoped teardown. It must not retry in place. A retry, if authorized by a
later campaign policy, receives a new run ID and preserves the failed evidence.

## 2. Input contract (`request.json`)

The request is immutable after launch. Unknown fields, duplicate identifiers,
wrong branch/case/repeat, hash drift, unsafe paths, or a capability that
contradicts the campaign's isolation policy are rejected before graph parsing.

```json
{
  "schema_version": "1.0.0",
  "request_id": "abk:run-request:artifact-dag-core-v1-control-com-01-r1",
  "campaign_id": "abk:benchmark-campaign:artifact-dag-core-v1",
  "branch": "control",
  "case_id": "COM-01-normal-primary",
  "repeat": 1,
  "fixture": {
    "relative_path": "fixtures/COM-01-normal-primary.json",
    "sha256": "<64 lowercase hex>"
  },
  "contracts": {
    "campaign_relative_path": "../../campaign.json",
    "campaign_sha256": "<64 lowercase hex>",
    "schema_relative_path": "../../../schemas/benchmark-campaign.schema.json",
    "schema_sha256": "<64 lowercase hex>"
  },
  "run": {
    "run_id": "abk:run:artifact-dag-core-v1-control-com-01-r1",
    "relative_run_root": "runs/COM-01-normal-primary/control/R1",
    "timeout_seconds": 120,
    "stop_condition_id": "readiness-and-evidence-emitted"
  },
  "authority": {
    "read_roots": ["campaign", "fixture", "schema"],
    "write_root": "run",
    "network": false,
    "credentials": false,
    "production_resources": false,
    "external_writes": false,
    "git_mutation": false,
    "process_spawn": false
  },
  "environment": {
    "HOME": "<run-relative-temp-root>",
    "USERPROFILE": "<run-relative-temp-root>",
    "APPDATA": "<run-relative-temp-root>",
    "LOCALAPPDATA": "<run-relative-temp-root>",
    "XDG_CONFIG_HOME": "<run-relative-temp-root>",
    "XDG_DATA_HOME": "<run-relative-temp-root>"
  },
  "runner": {
    "contract_version": "control-runner-v1",
    "executable_sha256": "<64 lowercase hex>",
    "host": "codex"
  }
}
```

The fixture, campaign, and schema hashes are the source-of-truth inputs. The
oracle prose and score weights are not passed as executable instructions to
the runner; the independent oracle evaluator reads them from the pinned
campaign after the run. This prevents a runner from manufacturing a pass by
echoing its expected oracle.

## 3. Output and terminal-state contract

Every run produces the required campaign files `run.json`, `stdout.log`,
`stderr.log`, `tool-events.jsonl`, `output-inventory.json`, and
`oracle-result.json`, plus before/after state checks. These are part of the
canonical evidence bundle and are required before a run can be scored. Success output also contains
`readiness.json`, `provenance.json`, and the Markdown projection
`operator.md`. Recovery and handoff cases add `recovery.json` and/or
`handoff.json` plus the receiver acknowledgement.

### 3.1 `run.json` shape

```json
{
  "schema_version": "1.0.0",
  "run_id": "abk:run:artifact-dag-core-v1-control-com-01-r1",
  "request_id": "abk:run-request:artifact-dag-core-v1-control-com-01-r1",
  "campaign_id": "abk:benchmark-campaign:artifact-dag-core-v1",
  "branch": "control",
  "case_id": "COM-01-normal-primary",
  "repeat": 1,
  "runner": {
    "contract_version": "control-runner-v1",
    "executable_sha256": "<64 lowercase hex>",
    "host": "codex"
  },
  "input": {
    "fixture_sha256": "<64 lowercase hex>",
    "campaign_sha256": "<64 lowercase hex>",
    "schema_sha256": "<64 lowercase hex>",
    "request_sha256": "<64 lowercase hex>"
  },
  "started_at": "<RFC3339>",
  "ended_at": "<RFC3339>",
  "duration_ms": 0,
  "terminal_state": "SUCCEEDED",
  "exit_code": 0,
  "error": null,
  "readiness": {
    "relative_path": "readiness.json",
    "sha256": "<64 lowercase hex>"
  },
  "provenance": {
    "relative_path": "provenance.json",
    "sha256": "<64 lowercase hex>"
  },
  "state_before": { "manifest_sha256": "<64 lowercase hex>" },
  "state_after": { "manifest_sha256": "<64 lowercase hex>" },
  "recovery": null,
  "handoff": null
}
```

Canonical behavior records do not include timestamps, process IDs, absolute
paths, random values, or host-specific temporary names. Those values remain
in `run.json` for operations. `readiness.json` and `provenance.json` use
sorted keys, stable arrays, UTF-8, and one canonical serialization before
hashing. This is the comparison basis for COM-03.

### 3.2 Terminal states

| State | Exit code | Meaning | Required payload | Readiness success? |
|---|---:|---|---|---:|
| `SUCCEEDED` | `0` | All declared graph checks and the declared stop condition completed. | `readiness.json`, `provenance.json`, inventory, oracle evidence. | Yes |
| `STOPPED` | `130` | Declared interrupt/stop signal was received and persisted. | Stop reason, last completed operation, terminal record, before/after checks. | No |
| `FAILED` | `3` | Graph or I/O contract failed after launch; `error.retryable` is explicit. | Typed error, offending field/reference, no success readiness. | No |
| `RECOVERED` | `4` | A declared partial-write failure was cleaned within owned scope and a resumable boundary was verified. | `recovery.json`, ownership actions, resumable-state hash, before/after checks. | No; recovery is its own oracle. |
| `TIMED_OUT` | `124` | Case deadline expired. Owner-only teardown completed or is reported incomplete. | Timeout reason, elapsed/deadline, cleanup result, no success readiness. | No |
| `BLOCKED` | `75` | Required executable/capability/isolation proof is unavailable. | Blocking reason and missing proof; no attempt to substitute. | No |
| `REJECTED` | `2` | Input, path, authority, hash, or policy violation was detected before work. | Typed rejection, offending path/field, negative side-effect check. | No |

The numeric exit codes are part of this contract; an implementation that
cannot preserve them must fail the runner gate rather than reinterpret a
non-zero exit as success. `FAILED`, `TIMED_OUT`, and `STOPPED` do not trigger
automatic retries or status promotion. A failed cleanup is recorded as
`FAILED` with `error.code=OWNED_CLEANUP_INCOMPLETE` and an operator alert; it
never deletes an unowned path.

### 3.3 Result records

`readiness.json` contains the sorted artifact IDs, each dependency edge, each
node state (`valid`, `missing_dependency`, or `invalid`), the computed ready
set, the graph hash, and the root list. `provenance.json` binds the result to
the campaign ID, case ID, fixture path/hash, schema hash, graph hash, and the
root artifact IDs. It does not contain a claim that the benchmark scorecard
passed.

An error object is always typed and actionable:

```json
{
  "code": "UNKNOWN_ARTIFACT_REFERENCE",
  "retryable": false,
  "message": "Artifact 'plan' depends on unknown artifact 'missing'.",
  "field": "project.artifacts[0].depends_on[0]"
}
```

Messages contain no credentials, tokens, or personal data. The same error
code and offending field must appear in `run.json`, `stderr.log`, and
`oracle-result.json` for an invalid case.

## 4. Canonical operator read surface: paired JSON + Markdown

**Decision:** use a paired surface. JSON is canonical and machine-verifiable;
Markdown is a deterministic, human-readable projection generated from the
JSON records in the same run directory.

The operator opens `operator.md` first. It must show, in this order:

1. run/case/branch/repeat and current terminal state;
2. one-sentence result or typed failure and the next allowed action;
3. readiness summary (roots, ready set, missing/invalid references);
4. provenance (fixture/schema/graph hashes and relative evidence links);
5. authority and side-effect summary (allowed roots, output inventory, pre/post
   negative check);
6. stop/recovery/handoff details when present;
7. links to `run.json`, `oracle-result.json`, stdout, stderr, and all evidence.

`operator.md` must not contain a second independently edited value. It is
regenerated from canonical JSON with stable section order. A projection hash
is recorded in `output-inventory.json`; a mismatch is an evidence failure and
keeps the run `inconclusive`, even if the JSON itself looks valid. This pair
balances operator comprehension with mechanical recomputation and keeps
Markdown from becoming an unvalidated instruction surface.

## 5. Fixture-to-oracle mapping

Each row below is an observable oracle. The oracle evaluator is independent of
the runner and records `passed`, `failed`, or `inconclusive` with evidence IDs.

| Case | Fixture condition | Observable success oracle | Failure/stop oracle and required negatives |
|---|---|---|---|
| `COM-01-normal-primary` | `spec` root, `plan -> spec` | `SUCCEEDED`; readiness contains exactly `spec, plan`, sorted edge `plan -> spec`; root provenance binds fixture and graph hashes; output is deterministic. | Any missing/extra node, hash drift, or undeclared output fails the oracle. |
| `COM-02-normal-variant` | `research -> spec`, `plan -> spec,research` | `SUCCEEDED`; contract shape is the same as COM-01 while the graph hash and ready set reflect the second valid shape; all three roots/provenance links are visible. | A shape-specific hard-code, unstable key set, or missing edge fails. |
| `COM-03-normal-repeat` | Same graph plus `repeat_key=stable-input-v1`, three repeats | All three normalized readiness/provenance hashes and evidence shapes match; only run ID/timestamps/temp paths may differ. | Any canonical drift is `failed`/`inconclusive`, not a pass hidden by the median. |
| `COM-04-boundary-minimum` | One root artifact, no implicit dependencies | `SUCCEEDED`; exactly one declared node, no generated extra artifact, root and readiness are explicit. | Any implicit artifact or requirement for an unlisted node fails. |
| `COM-05-invalid-input` | `plan -> missing` | No success output. `FAILED` or `REJECTED` with typed unknown-reference/invalid-graph error, offending field, no derived readiness, and no partial state. | Continuing, auto-repairing, or emitting a plausible readiness record fails. |
| `COM-06-stop-interrupt` | `interrupt_after=plan-read` | `STOPPED` after the declared interrupt point; terminal stop record, last completed operation, and negative success assertion are persisted. | Ambiguous success, missing terminal record, or continued work after the signal fails. |
| `SPC-01-domain-boundary` | Dependency `../outside` | `REJECTED` with `PATH_OUT_OF_ROOT` before resolving/reading the external path; read audit proves no external read and no output mutation. | Any path normalization that reads outside root, follows a reparse point, or merely warns fails. |
| `SPC-02-failure-path` | `plan -> unknown-artifact` | `FAILED`/`REJECTED` with `UNKNOWN_ARTIFACT_REFERENCE`; no readiness result and no success evidence. | Silent skip, inferred dependency, or partial success fails. |
| `SPC-03-recovery-rollback` | Failure after `derived-state-write`, `owned-state-only` recovery | `RECOVERED`; only run-owned derived state is removed, unowned sentinel/state is byte-identical, resumable boundary validates, and `recovery.json` lists every action/hash. | Deleting or changing unowned data, claiming success, or failing to prove resumability fails. |
| `SPC-04-composition-handoff` | Valid graph with `handoff=validated-graph` | `SUCCEEDED` plus a provenance-bound handoff payload and receiver acknowledgement; receiver recomputes graph/root hashes and accepts only validated input. | Missing/invalid provenance, receiver acceptance of an unvalidated payload, or handoff hash mismatch fails. |

For SPC-04 the receiver is a test-only contract validator in the campaign
harness; it is not an upstream runtime and it does not grant the control
runner any additional capability.

## 6. Evidence that proves success, stop, and recovery

### 6.1 Required per-run evidence

The owner directory must contain (or reference with an in-root relative path):

| Evidence | What it proves |
|---|---|
| `run.json` | Inputs, pinned runner, terminal state, exit code, timing, error, and before/after state hashes. |
| `request.json` | Exact immutable request and authority boundary consumed by the process. |
| `stdout.log`, `stderr.log` | Complete process output, including an empty file when no output was produced. |
| `tool-events.jsonl` | Ordered lifecycle events: start, input acceptance, reads, output, stop/timeout, recovery, terminal. |
| `readiness.json`, `provenance.json` | Canonical behavior and root/fixture/schema/graph provenance for successful graph checks. |
| `output-inventory.json` | Every created/modified output, owner, relative path, disposition, size, and SHA-256; no undeclared file. |
| `state-before.json`, `state-after.json` (or embedded equivalents) | Real user/Codex configuration and unowned sentinel negative checks before/after. |
| `oracle-result.json` | Independent pass/fail/inconclusive checks and evidence IDs; never self-scored by the runner. |
| `operator.md` | Deterministic human projection and projection hash. |
| `recovery.json` when applicable | Ownership-scoped cleanup, action order, hashes, and resumable-boundary verification. |
| `handoff.json` and `handoff-ack.json` when applicable | Payload/receiver contract and provenance verification for SPC-04. |

Every artifact receives exactly one disposition from the protocol's inventory
set: `runtime_smoked`, `behavior_reproduced`, `covered_by_test`,
`static_only_not_executable`, or `blocked`. Every evidence ID is unique and
resolves to an existing in-root file whose SHA-256 matches the recorded value.

### 6.2 Success proof

A single run is successful only if all of the following are true:

- `run.json.terminal_state=SUCCEEDED` and `exit_code=0`;
- the fixture, campaign, schema, and runner hashes match the request;
- canonical readiness/provenance parse and satisfy the case oracle;
- output inventory is exact, in-root, owner-scoped, and has no undeclared
  mutation;
- before/after checks show no change to real user/Codex configuration,
  repository source, Git metadata, network, credentials, or production state;
- stdout, stderr, tool events, and oracle evidence are independently readable;
- the Markdown projection hash matches its JSON inputs.

Campaign success additionally requires all 66 raw runs, all 30 primary cells,
all ten fixture oracles, all six hard gates, three branch scorecards, and a
recomputable outcome. This document does not assert any of those conditions.

### 6.3 Stop and timeout proof

`STOPPED` requires the declared signal/stop condition, the last completed
operation, a persisted terminal record, no readiness success claim, and a
post-stop inventory. `TIMED_OUT` requires deadline/elapsed evidence and an
owner-only teardown result. If teardown cannot be proven complete, the run is
`FAILED` with `OWNED_CLEANUP_INCOMPLETE`; it is not retried or promoted.

### 6.4 Recovery proof

`RECOVERED` is reserved for SPC-03-like partial-write recovery. Evidence must
show the failure point, the owner manifest used for cleanup, cleanup in reverse
creation order, hashes of deleted/restored owned files, byte-identical
unowned sentinel/state before and after, and a valid resumable boundary. A
recovery record never changes the original run's failure into readiness
success; it proves only the recovery oracle.

## 7. Handoff contracts

### Orchestrator -> control runner

**Payload**: immutable `request.json` as specified in section 2.
**Success response**: process exit `0` and `run.json` with `SUCCEEDED`, plus
canonical readiness/provenance and inventory.
**Failure response**: non-zero exit and `run.json` with one terminal state and
typed `error { code, retryable, message, field }`; no absent/ambiguous result.
**Timeout**: case timeout from `campaign.json`; deadline is treated as
`TIMED_OUT`, followed only by owner-scoped teardown.
**On failure**: preserve the owner directory and evidence; do not retry in
place, clean unowned paths, or promote campaign status.

### Control runner -> SPC-04 receiver validator

**Payload**:

```json
{
  "schema_version": "1.0.0",
  "run_id": "<run id>",
  "graph_sha256": "<64 lowercase hex>",
  "readiness_sha256": "<64 lowercase hex>",
  "root_provenance_sha256": "<64 lowercase hex>",
  "source_fixture_sha256": "<64 lowercase hex>",
  "validation_state": "validated"
}
```

**Success response**: `ack_status=accepted` with the recomputed hashes and an
acknowledgement evidence ID.
**Failure response**: `ack_status=rejected`, typed hash/state error, and no
downstream mutation.
**Timeout**: 10 seconds for the local validator; treat expiry as failure.
**On failure**: preserve the handoff payload, emit a failed oracle, and keep
the run non-successful.

## 8. Assumptions

These are explicit assumptions, not verified facts:

| ID | Assumption | Risk if wrong | Required treatment |
|---|---|---|---|
| A1 | Codex M1 runs on a host with `pwsh.exe` and can create empty temporary environment roots. | The reserved command cannot launch or inherits real configuration. | Runner gate must report `BLOCKED`; no alternate shell is silently substituted. |
| A2 | The campaign fixture JSON and its recorded SHA-256 are the canonical Artifact DAG input. | Results could be compared against a different graph than the frozen campaign. | Hash and case ID are checked before parsing. |
| A3 | Canonical JSON serialization can be made stable across the supported Codex runtime. | COM-03 evidence hashes drift for formatting-only reasons. | Pin serializer/version and include a canonicalization test before scoring. |
| A4 | The outer orchestrator can capture process-tree, network/credential, Git, and real-config before/after evidence. | Isolation would be asserted but not proven. | If any check is unavailable, mark the run `BLOCKED`/`INCONCLUSIVE`. |
| A5 | A local test-only receiver validator may be used for SPC-04 without expanding control authority. | Handoff evidence could depend on an undocumented component. | Pin its contract and digest in the runner manifest; no receiver mutation is allowed. |
| A6 | The current campaign's canonical evidence filenames remain compatible with the protocol. | A valid run could be rejected by a filename/layout mismatch. | Require `run.json`, `stdout.log`, `stderr.log`, `tool-events.jsonl`, `output-inventory.json`, and `oracle-result.json` before acceptance. |

## 9. Unresolved questions and release blockers

1. **Executable availability and digest.** Resolved for the control branch:
   `benchmarks/runners/control/run.ps1` exists, and the concrete branch
   manifest pins its SHA-256 and PowerShell major `7`. Independent isolation
   proof, campaign-start approval, and evidence review remain release gates.
2. **Isolation enforcement mechanism.** The current Codex-local audit proves
   sanitised environment roots, no inherited credential/configuration values,
   no observed child process, and no observed process socket. It does not prove
   an OS-level network-deny policy. The non-elevated preflight was `BLOCKED`,
   then the elevated policy audit passed with zero observed sockets and
   verified cleanup; the network-deny gate is now resolved for this control
   snapshot.
3. **Source-native disposition.** Can the pinned OpenSpec behavior be
   reproduced locally without installing or importing its upstream runtime?
   If not, which evidence record marks `source_native` blocked/rejected while
   preserving the required three-branch campaign contract?
4. **Reviewer rubric and weights.** The scorecard schema validates ten
   dimensions and positive weights but does not publish the weight vector.
   Which vector and adjudication procedure are frozen before scoring?
5. **Operator budget.** What first-run/reviewer-rerun latency, token, storage,
   and evidence-retention budget is acceptable to the primary maintainer?
6. **User segment and approval policy.** The research treats an ABK
   maintainer/operator as primary, but interviews and the required approval
   policy for unattended runs, extension install, and Git actions are not
   recorded here.
7. **Handoff ownership.** Which approved component owns the SPC-04 receiver
   contract and its digest, and how is a receiver version change reflected in
   provenance without changing the control runner's authority?

## 10. Gate outcome

This artifact resolves the boundary, schemas, paired read surface, case
oracles, and evidence semantics at the design level. The fixture-only control
runner now exists and has bounded integration tests; the elevated Windows
Firewall audit closes the network-deny proof, but the runner/evidence gates
still require branch-manifest approval and independent raw-evidence review.
The campaign must remain `benchmark_pending` / `UNSCORED`.

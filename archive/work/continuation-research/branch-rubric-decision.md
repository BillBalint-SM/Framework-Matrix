# Discovery gate: branch manifests and reviewer rubric

Status: proposed freeze for M1; no campaign run is authorized by this note.

This decision closes the runner-boundary and scoring questions for the
`abk:benchmark-campaign:artifact-dag-core-v1` campaign. It does not add ABK
runtime code and does not promote a scorecard. The campaign remains
`benchmark_pending` / `UNSCORED` until the approvals and pin checks below are
complete.

Current machine-verified state at authoring time:

```text
WORK_STATE: fresh=2026-08-03T15:13:45.9321946Z; repo=C:/Users/littl/Documents/Framework-Matrix; branch=main; head=4b94415f64115b6830651cc525cb44682d84dbe; worktree=dirty; upstream=origin/main; pr=not-applicable; evidence=local
```

The dirty `README.md`, `archive/work/continuation-research/`, and
`benchmarks/` paths are pre-existing work. This artifact is the only file
created for this gate.

## 1. Frozen decision boundary

The unit of comparison is one Artifact DAG + root-provenance behavior on one
Codex host. The canonical operator read surface is the machine-readable
`readiness.json` record. A human-readable `readiness.md` may be rendered from
that record, but it is never an input and cannot override it. Every result is
derived from the fixture, pinned source/schema bytes, and the run evidence;
chat history, previous runs, and an agent's self-description are not inputs.

The campaign is exactly:

- 10 cases: 6 `common` and 4 `component_specific`;
- 3 primary branches: `control`, `source_native`, `abk_native`;
- 30 primary cells;
- 66 raw runs (six cases at three repeats and four cases at one repeat, per
  branch).

The `abk_native` scorecard is the only scorecard that can produce a candidate
adoption outcome. `control` and `source_native` provide independent baselines;
their scores never transfer lifecycle state to `abk_native`.

## 2. Input and schema pinning

The following bytes are immutable campaign inputs. Hashes are SHA-256 over the
exact file bytes, with no parse/re-serialize step. A missing file, extra case,
duplicate case, path escape, or hash mismatch stops the campaign before any
branch process starts. A changed input requires a new campaign/manifest ID; it
must not be repaired in place.

### Campaign and schemas

| Input | SHA-256 | Contract use |
|---|---|---|
| `benchmarks/campaigns/artifact-dag-core-v1/campaign.json` | `471b4f31608781205ce71d497add92d15659003a2a5852f1cc7fb59330b320d3` | campaign ID, cases, repeats, timeout, isolation and expected 66 runs |
| `benchmarks/schemas/benchmark-campaign.schema.json` | `b4cacc60fe730faab91595f3f00b73ddf8729b494413a5eab5fa295e494b8aff` | pending-campaign structural validator |
| `outputs/08-empirical-benchmark-protocol.md` | `d38c6c174a8ada50e9689b6e7a0f1f41fff36a7c9ce3ca23fd0c3b4606d0724e` | three-branch, isolation, aggregation, evidence and lifecycle contract |
| `outputs/09-adoption-scorecard.schema.json` | `43ac1d52b16ae0dd7fa733017b8441e90fb024338dc45a5c9063072909970a42` | scorecard shape, hard gates and outcome formula |
| `outputs/07-capability-component-pattern-adoption.schema.json` | `00259384a24a5542636e9bc8b90fb676e9326e0f828be89be794dd1cff3a04e0` | capability/authority/lifecycle/provenance contract |

### Source pattern

The source observation is `Fission-AI/openspec` commit
`45cca5db6137ed209117cc70510eb3e057fb981b`, path `src/core/artifact-graph`,
as recorded in the campaign. This is evidence of the behavior being isolated;
it is not permission to install or execute an upstream runtime.

### Fixture pins

| Case | Fixture SHA-256 | Repeats |
|---|---|---:|
| `COM-01-normal-primary` | `62f997d1e3a0aded32dde6468b3ec342d7c3a52d87839deeb7c6cf7a040d1bfe` | 3 |
| `COM-02-normal-variant` | `846ed6317d8bf0af1ed2aa2017e647e9d2502db399f451322eebae9fc9806943` | 3 |
| `COM-03-normal-repeat` | `a337f79552f96b4dba030fa08f4e58cf760ee26a770d45b54d4946dbb7f5a152` | 3 |
| `COM-04-boundary-minimum` | `dca00b56517ec5eaf491ba3d071f4da9823918c7ab78b168ff02ac971875d686` | 1 |
| `COM-05-invalid-input` | `9cf491ac8ad57dd9ea630adc10ca396bec2338ea7ac08735684e222581dd307b` | 1 |
| `COM-06-stop-interrupt` | `177325140d819ca9ce3416409a70122911a4f44148a8a788e3a0de5505b53c40` | 3 |
| `SPC-01-domain-boundary` | `7232aaa098862821374ad852d0c07d6a82f83928ec8bdfd0738e1132a726cfb9` | 1 |
| `SPC-02-failure-path` | `1072ff864f4c87d33128f9f86a7426ad3a42ce3f5aceebe6a2e2ec00acb21576` | 1 |
| `SPC-03-recovery-rollback` | `ce339295134d2036f96615accc8d1e1e9f7a5fd4c73821b9fab2c868cb0fefaa` | 3 |
| `SPC-04-composition-handoff` | `7ef01303a6b87f5a07fc187a09002b613f5ae405b3095babfde8b6ac2da6d4c3` | 3 |

The expected raw-run arithmetic is
`3 branches × (6×3 + 4×1) = 66`; the runner recomputes this from the case
flags rather than trusting the campaign's integer.

## 3. Shared runner contract

Each branch has a separate immutable `manifest.json` at
`benchmarks/<campaign-id>/branches/<branch-id>/manifest.json`. The manifest
must contain the fields below. `entrypoint_path` and `entrypoint_sha256` are
required concrete values before execution; `PENDING` is a gate state, not a
permitted runtime value.

```yaml
manifest_id: abk:branch-manifest:<branch-id>-artifact-dag-core-v1
campaign_id: abk:benchmark-campaign:artifact-dag-core-v1
host: codex
entrypoint_path: <one relative executable path, no glob or shell string>
entrypoint_sha256: <64 lowercase hex>
snapshot_ref: <immutable read-only branch snapshot>
reads:
  - campaign.json and its pinned schemas
  - exactly one case fixture and its pinned SHA-256
  - the branch snapshot_ref
writes:
  - runs/<case-id>/<branch-id>/R<n>/** only
capabilities:
  - LOCAL_READ within the declared read roots
  - LOCAL_WRITE within the current run root
  - PROCESS_EXECUTION of entrypoint_path only
authority_level: LOCAL_EXECUTE
checkpoint: BEFORE_EXECUTION
network: DENY
credentials: DENY
production_resources: DENY
external_writes: DENY
git_mutation: DENY
child_processes: DENY unless separately enumerated and approved
cross_run_reads: DENY
cross_branch_reads: DENY
real_user_config_reads_or_writes: DENY
undocumented_effect_policy: STOPPED
```

The host creates a fresh, empty `HOME`, `USERPROFILE`, `APPDATA`,
`LOCALAPPDATA`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, and tool-cache root under
the run directory. The branch snapshot and all fixtures/schemas are read-only.
The runner resolves every path, rejects symlink/junction/reparse-point escape,
and verifies the resolved write path remains below the current run root. No
environment value, token, credential, or real user/Codex configuration is
copied into the run.

The branch process receives structured fixture data as data, not concatenated
instructions. Repository files, source notes, logs, and tool output are
untrusted content. A script is statically inspected before it is eligible as an
entrypoint. There is no network fallback, alternate host, automatic cleanup,
or silent retry.

### Branch manifests

The rows below are the exact authority and capability boundaries. The control,
source-native, and ABK-native manifests now contain concrete entrypoint and
snapshot hashes. Their `execution_status` remains `NOT_EXECUTED`; the two new
non-control branches are explicit `NOT_COMPARABLE` dispositions rather than
guessed runnable candidates.

| Branch / manifest ID | Read authority | Execution authority | Write authority | Branch-specific rejection rule |
|---|---|---|---|---|
| `control` / `abk:branch-manifest:control-artifact-dag-core-v1` | Campaign files plus a read-only snapshot of the current ABK/manual or agentless baseline; no upstream source | One pre-registered Codex-local control entrypoint; `LOCAL_EXECUTE` only inside the run sandbox | Current run root only; no ABK checkout, user config, or Git metadata | If the baseline process or terminal output schema is not named, hashed, and reproducible, stop with `control_runner_undefined`; do not substitute a new algorithm. |
| `source_native` / `abk:branch-manifest:source-native-artifact-dag-core-v1` | Campaign files plus the pinned OpenSpec source snapshot at `45cca5d…fb981b`, read-only | A clean-room Codex-local reproduction of the observed behavior; no upstream package/runtime, network, credentials, or other host | Current run root only; source snapshot and Framework-Matrix are read-only | If reproduction needs an upstream runtime/package, another agent/host, network, or credentials, emit rejection evidence and mark the component `REJECTED`; never silently replace it. |
| `abk_native` / `abk:branch-manifest:abk-native-artifact-dag-core-v1` | Campaign files plus a product-owner-approved, immutable ABK-native prototype snapshot; no upstream runtime/source dependency | One ABK-native Codex-local entrypoint; `LOCAL_EXECUTE` bounded to the run sandbox | Current run root only; no AI Booster Kit source change, external write, or Git mutation | Any undeclared capability, path, process, or side effect is a hard stop. A missing approved snapshot/entrypoint leaves the campaign `UNSCORED`. |

Current non-control pins: `source_native` entrypoint
`d0384863ddfe051f6fd817550048a2403011d6e498f4149b9bee21bb1611f3c3`,
snapshot `187f05196ea13a2acb16e79fc58df3f366b256f53afaa495e59457a1cd32cefa`;
`abk_native` entrypoint
`c3e4daf7cc981a08b1805783394c19c0443789486e8e150c9049ab0f5d56658e`,
 snapshot `a19b1c30dee281dc5a8c2c27cb94d7d8ccf4c50aca855c140cf5677d1d875997`.
The corresponding manifest hashes are `0493c1f974ffda595446d1d831ccba5d5b7587416c9f41be09f09b3ef07723da`
and `2557f41ad900709842d780d0fe3aa97e6bc2a15a0e8ec683554aa2c87167e7c0`.
Both entrypoints validate local metadata and then emit `REJECTED` /
`NOT_COMPARABLE`, exit `2`, without upstream or external-project execution.

No branch may read another branch's manifest output, cache, transcript,
conversation state, or findings. Repeats are fresh processes with fresh roots;
only the pinned fixture and manifest are shared. A branch cannot claim
`runtime_smoked` or `behavior_reproduced` from static source inspection alone.

### Current control manifest artifact

The first concrete control manifest is now present locally at
`benchmarks/campaigns/artifact-dag-core-v1/branches/control/manifest.json`.
Its SHA-256 is
`5c041ba5fe1621cf72ac2091cef7358875789c38cbc1115fe6b1d15891c9a235`; it
pins `benchmarks/runners/control/run.ps1` at
`a0e4929d124c831035546c8c65a1de7618da789d05a4bb24b645285421e859c1` and
PowerShell major `7`. The independent audit at
`benchmarks/audits/control-isolation-audit-2026-08-03.json` proves the
sanitised environment, process, repository, and Git checks, but is
`INCONCLUSIVE` because OS-level network denial was not established. The
subsequent elevated Windows Firewall audit passed: the runner observed zero
sockets under the exact temporary outbound Block rule, and cleanup/read-back
passed. This is not campaign-start approval; campaign approval remains
required.
The non-elevated policy preflight remains recorded as `BLOCKED` for provenance.

## 4. Run and evidence contract

The canonical run path is:

```text
benchmarks/<campaign-id>/
  branches/<branch-id>/manifest.json
  runs/<case-id>/<branch-id>/R<n>/
    run.json
    stdout.log
    stderr.log
    tool-events.jsonl
    output-inventory.json
    oracle-result.json
```

The canonical stdout/stderr names are `stdout.log` and `stderr.log`, matching
the accepted protocol and operator README. `tool-events.jsonl` and
`oracle-result.json` are required protocol evidence; no run is complete
without them. Legacy `.txt` names are not accepted as a substitute. If a
future compatibility projection emits aliases, it must prove byte/hash
identity without changing the canonical manifest.

`run.json` is a closed record with at least these fields:

```yaml
run_id: abk:run:<case-id>-<branch-id>-r<n>
evidence_id: evidence-<case-id>-<branch-id>-r<n>
campaign_id: abk:benchmark-campaign:artifact-dag-core-v1
case_id: <fixture case ID>
branch_id: control | source_native | abk_native
repeat: 1 | 2 | 3
manifest_sha256: <hash of immutable branch manifest>
fixture_sha256: <hash from the frozen table>
schema_sha256: <hashes of all schemas consumed>
started_at: <ISO-8601 UTC>
completed_at: <ISO-8601 UTC>
status: passed | failed | partial | inconclusive | invalidated | stopped
exit_code: <integer or null for a declared interrupt>
timeout_seconds: <campaign value>
stop_condition: <campaign value>
tool_events_sha256: <hash>
output_inventory_sha256: <hash>
oracle_result_sha256: <hash>
before_real_config_digest: <digest of negative-check inventory, not contents>
after_real_config_digest: <digest of negative-check inventory, not contents>
declared_effects: []
observed_effects: []
```

The record must not contain secret values or full real-user configuration.
`output-inventory.json` lists every emitted path, owner, type, size, SHA-256,
and exactly one disposition: `runtime_smoked`, `behavior_reproduced`,
`covered_by_test`, `static_only_not_executable`, or `blocked`. Any output
outside the manifest's write roots, any undeclared effect, or any failed
before/after negative check invalidates the run. A failed or inconclusive run
retains its evidence but cannot count as a passed raw run or be converted to a
score by imputation.

There is exactly one run-evidence ID per expected raw run. The ID is unique
across the campaign and is included in each relevant scorecard evidence list.
Evidence content is independently re-readable from its locator and verified by
the stored SHA-256. A re-run requires a root-cause record and a new run ID; the
old evidence is never overwritten.

## 5. Frozen ten-dimension score vector

The same vector applies to all three branch scorecards. Scores are 1–10,
critical flags are fixed, and the weighted average is
`round3(sum(score × weight))`. The weights sum to exactly `1.00`.

| Dimension | Critical | Weight | Reviewer must inspect |
|---|:---:|---:|---|
| `task_success` | yes | `0.20` | The case oracle and terminal output are satisfied without an invented success. |
| `correctness_and_evidence` | yes | `0.20` | Result correctness, root provenance, fixture/schema hashes, and independently readable evidence. |
| `repeatability` | yes | `0.15` | Repeat policy, output/evidence stability, and preserved variance for model-dependent cases. |
| `state_and_error_observability` | yes | `0.10` | Explicit state, typed errors, stdout/stderr/tool events, exit code, and no hidden continuation. |
| `stop_and_recovery` | yes | `0.10` | Interrupt, rollback/recovery, terminal state, and ownership-scoped cleanup. |
| `context_and_token_efficiency` | no | `0.05` | Forbidden context exclusion and bounded input/output/context overhead. |
| `runtime_and_operational_overhead` | no | `0.05` | Timeout compliance, process/cache footprint, and replay cost within the approved budget. |
| `composition_and_handoff` | no | `0.05` | Provenance-bound handoff and receiver validation in `SPC-04`. |
| `useful_autonomy` | no | `0.05` | Completion of declared local work without unapproved authority or endless repair. |
| `understandability_and_maintainability` | no | `0.05` | A fresh reviewer can reconstruct the contract and identify the owning boundary. |

### Rubric anchors

Each reviewer scores the ten case cells for a branch (repeats are first
aggregated per the protocol), then the branch dimension score is the arithmetic
mean of the ten case scores, retained to one decimal. No cell may be imputed.
The critical minimum is the minimum of the five critical branch dimensions.

The following anchors are applied to every dimension, with the inspection
column above determining what counts as evidence:

| Score | Anchor |
|---:|---|
| 10 | All applicable case oracles pass; evidence is complete, deterministic or variance-explained, independently re-readable, and free of unowned/undocumented effects. |
| 7 | Contract passes with only minor, documented variance that does not affect safety, correctness, provenance, or recovery. |
| 4 | Material omission, unstable result, incomplete evidence, workaround, or reviewer-visible risk remains; the dimension is not reliable for adoption. |
| 1 | Oracle/contract failure, unsafe authority, hidden state, missing provenance, unbounded loop, or unreviewable evidence. |

Scores 2–3, 5–6, and 8–9 are interpolation between the adjacent anchors;
the reviewer must cite the evidence that justifies the interpolation. A
critical dimension at 4 or below forces `REJECTED` when a complete scorecard is
otherwise valid. A failed hard gate or an incomplete campaign is instead
`UNSCORED`/`inconclusive` and cannot be cosmetically scored.

## 6. Independent review and adjudication

1. Two reviewers independently inspect the same pinned evidence and score the
   ten case cells and branch dimensions. Branch identity is masked where
   practical. An agent's own score or narrative is not evidence.
2. Each non-binary score has at least one evidence ID and a one-sentence
   rationale. Automated assertions decide binary contract gates; reviewers do
   not waive them.
3. If the two dimension scores differ by at most one point, the final
   dimension score is their arithmetic mean (retain both raw scores).
4. If a difference is greater than one, reviewers record the disputed evidence
   and a third adjudicator re-reads the raw artifacts. The final score is the
   median of the three scores. If the disagreement is about authority,
   ownership, provenance, or an undocumented effect, the result is
   `inconclusive` and the run/campaign stops regardless of numeric average.
5. Adjudication cannot add evidence, rerun a branch, alter a fixture/hash,
   suppress a failure, or promote lifecycle state. Any new run gets a new ID
   and a root-cause note.
6. The scorecard is valid only when every hard gate has status `pass`, all 30
   primary cells and all expected raw runs have passed evidence IDs, the three
   branch scorecards are present, and the formula recomputes from the stored
   dimensions and weights.

## 7. Fail and stop conditions

Stop before execution when any of the following occurs:

- current repository, branch, or HEAD cannot be verified;
- a fixture, schema, source snapshot, branch manifest, or entrypoint hash is
  missing, changed, duplicated, or outside the declared root;
- the control runner or its terminal output schema is undefined;
- `source_native` requires an upstream runtime/package, another host/agent,
  network, or credentials;
- `abk_native` lacks a product-owner-approved immutable snapshot;
- a required process/capability/authority is not in the manifest;
- the `.txt`/`.log` stdout or stderr aliases differ;
- real user/Codex configuration, credentials, production resources, network,
  external writes, or Git mutation would be reachable;
- a symlink, junction, reparse point, path escape, unowned overwrite, or
  undeclared child process is detected.

Stop the current run and preserve evidence when:

- the timeout or declared interrupt fires;
- an oracle fails, input is malformed/unknown/out-of-root, or output is partial;
- a process exits unexpectedly or emits an untyped error;
- a tool event, output inventory, oracle result, or before/after check is
  missing or cannot be independently hashed;
- observed effects differ from declared effects.

Stop the campaign and leave it `UNSCORED` (usually `inconclusive`) when any
expected raw run is missing/invalidated, any hard gate is not `pass`, any
reviewer cannot re-read evidence, or the 30/66 arithmetic no longer matches
the frozen cases. Do not automatically retry, delete, roll back, or repair
unowned state. A manually authorized rerun is a new run with a recorded
root-cause and preserves the prior evidence.

Only a complete, recomputable campaign may produce `REJECTED`, `CANDIDATE`, or
`CHOSEN`. `ADOPTED` is a separate lifecycle transition from `CHOSEN` and always
requires a non-null approval ID. No stop condition can be overridden by a
numeric score.

## 8. Product-owner approvals required

The following are explicit product-owner decisions. A reviewer may verify
evidence but cannot substitute for these approvals:

1. **Discovery acceptance:** primary user segment/JTBD and the canonical
   `readiness.json` operator surface (with optional Markdown projection).
2. **Runner freeze:** the exact control entrypoint/snapshot and terminal output
   schema; the current `source_native` explicit rejection boundary; and a
   future approved immutable comparable `abk_native` snapshot/entrypoint.
3. **Campaign freeze/start:** the campaign ID, all fixture/schema/source
   hashes, 30-cell/66-run arithmetic, timeout/repeat policy, canonical
   stdout/stderr and tool/oracle evidence rule,
   reviewer roster, and the weight/rubric vector in this note. Any change
   creates a new campaign/manifest ID.
4. **Authority expansion:** any network, credential, production, external-write,
   Git, second-host, child-process, or path-root capability. M1 defaults deny
   and does not grant these capabilities implicitly.
5. **Adoption:** promotion to `ADOPTED`, implementation of a comparable
   `abk_native` candidate in the separate AI Booster Kit project, or publication of a
   product recommendation. The product owner cannot override an incomplete,
   failed, or `UNSCORED` campaign; a new approved experiment is required.

Routine read-only validation of hashes and schema shape does not require a new
approval, but it must be logged and must not mutate the source, campaign, or
branch manifests.

## Gate outcome

This artifact defines the decision contract and identifies the remaining
approval-bound implementation inputs. Until items 1–3 above are recorded, the
campaign is intentionally not runnable and has no earned score, `CHOSEN`, or
`ADOPTED` result.

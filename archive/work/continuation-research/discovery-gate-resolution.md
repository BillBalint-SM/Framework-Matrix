# Discovery Gate Resolution — Framework-Matrix M1

Status: `RESEARCH_COMPLETE_BUILD_GATED`

Date: 2026-08-03

## Purpose

This document integrates the three specialist decision artefacts produced
before the next implementation slice. It records what is sufficiently
specified to build, what remains an explicit product-owner decision, and the
first bounded milestone after the gate is approved. It does not claim that a
benchmark runner exists, that a benchmark has executed, or that any branch is
adopted.

## Evidence base

- `trend-research.md` — current landscape and first-party source map.
- `feedback-synthesis.md` — local evidence, user needs, trust requirements,
  and proposed feedback protocol.
- `sprint-prioritization.md` — sequenced delivery plan and role allocation.
- `control-runner-decision.md` — control execution boundary, terminal states,
  read surface, and oracle mapping.
- `branch-rubric-decision.md` — branch manifests, isolation rules, scoring
  vector, adjudication, and stop gates.
- `user-segment-jtbd-decision.md` — primary segment, JTBDs, and feedback gate.
- `benchmarks/campaigns/artifact-dag-core-v1/campaign.json` — current pending
  campaign contract.
- `benchmarks/scripts/validate-benchmark-campaign.ps1` and
  `benchmarks/tests/test-benchmark-campaign.ps1` — current contract checks.

## Integrated decisions

1. **M1 outcome.** Prove a safe, inspectable Artifact DAG + root provenance
   substrate with deterministic evidence. The campaign remains `benchmark_pending`
   and `UNSCORED` until real runs and independent review exist.
2. **Primary user.** The first user is the AI Booster Kit maintainer/operator
   who must inspect project readiness, provenance, failures, and handoffs.
3. **Canonical read surface.** Machine-readable readiness/provenance JSON is
   canonical. A concise deterministic Markdown rendering is a paired operator
   projection; it is not an independent source of truth.
4. **Control boundary.** Each raw control run is one non-interactive local
   PowerShell process, fixture-only, with no network, credentials, production
   resources, Git mutation, upstream runtime, or child process. The runner may
   read only the pinned campaign, schema, and fixture inputs and may write only
   its own run root.
5. **Terminal state.** Every run must end in an explicit terminal state. Only
   `SUCCEEDED` can contribute readiness success; `STOPPED`, `FAILED`,
   `RECOVERED`, `TIMED_OUT`, `BLOCKED`, and `REJECTED` remain observable
   non-success evidence.
6. **Branch policy.** `control`, `source_native`, and `abk_native` are separate
   evidence branches with explicit authority and isolation boundaries. The
   Framework-Matrix repository does not import AI Booster Kit source code.
7. **Scoring proposal.** The ten-dimension rubric has a frozen draft weight
   vector summing to 1.00; critical dimensions are task success, correctness
   and evidence, repeatability, state/error observability, and stop/recovery.

## What is ready to build

The next bounded implementation slice can be the **control-runner contract
slice**:

- request and run schemas;
- one local control entrypoint;
- owned run-root creation and path-safety checks;
- deterministic JSON/Markdown projection;
- terminal-state and evidence-inventory validation;
- negative tests for out-of-root input, partial output, interruption, and
  premature success.

This slice must stop at contract validation and fixture execution. It must not
start the 66-run campaign, implement an upstream runtime, add ABK source, or
publish an adoption result.

## Explicit gates before the runner is frozen

The following are not silently assumed:

1. Product-owner approval of the primary segment and the five-session feedback
   gate (or an explicit decision to defer interviews).
2. Product-owner approval of the paired JSON/Markdown read surface and the
   exact control command/output schema.
3. A disposition for `source_native`: executable clean-room reproduction,
   explicit rejection with evidence, or a documented non-comparable branch.
4. Approval of the draft weight vector, score anchors, independent review, and
   adjudication policy.
5. A frozen executable path/digest and a Windows isolation proof for the
   control runner.

## Resolved evidence contract

The approved and implemented canonical evidence set is `run.json`,
`stdout.log`, `stderr.log`, `tool-events.jsonl`, `output-inventory.json`, and
`oracle-result.json`. This matches the accepted protocol and operator README.
Legacy `.txt` names are not accepted as a substitute. The schema, campaign,
validator, and regression tests now enforce the same exact ordered set; any
future compatibility projection must be explicitly byte/hash-checked.

The earlier `.txt`/`.log` mismatch is retained in
`evidence-contract-review.md` as the decision evidence, not as a current
runtime blocker.

## First milestone and exit criteria

**M1-A — executable control contract, not the benchmark campaign.**

Exit criteria:

- the evidence-layout decision is canonical and validated;
- the control entrypoint has a pinned digest and explicit isolation proof;
- all declared negative paths terminate with typed evidence;
- JSON is canonical and Markdown is a deterministic projection;
- campaign validation and regression tests pass;
- no benchmark outcome is claimed and no GitHub state is changed.

The 66 expected raw runs remain the subsequent M1 campaign milestone, gated on
the approvals and freeze points above.

## Current truth

- Campaign: `benchmark_pending` / `UNSCORED`.
- Completed raw runs: `0`.
- Current validator result: `BENCHMARK_VALID` for the pending campaign.
- Contract regression suite: `7/7 PASS`.
- Canonical evidence contract regression suite: `9/9 PASS`.
- Control request/run schema suite: `6/6 PASS`, including fail-closed unknown
  field, wrong branch/path, and terminal-state/exit-code cases.
- Request/run schema files and the fixture-only control runner exist and are
  hash-pinned in the control decision artefact.
- The concrete `control` branch manifest exists, is schema-valid, and pins the
  runner digest and PowerShell major version; it is not yet a campaign-start
  approval or independent isolation proof.
- Control runner integration suite: `3/3 PASS`; no raw campaign run or
  scorecard has been created.

# Sprint prioritization — Framework-Matrix continuation

## Decision summary

The research does not justify choosing an upstream framework by maturity,
integration count, stars, or documentation volume. It supports one narrow proof
milestone: **Artifact DAG + root provenance**. The existing campaign contract is
the measurement boundary; it is not evidence that any branch has passed.

The immediate order is:

1. close the discovery gates that are still unknown;
2. freeze the three runner boundaries and reviewer rubric;
3. implement the smallest clean-room artifact/state substrate in the separate
   AI Booster Kit project, keeping this repository as the source-neutral
   research, fixture, and evidence authority;
4. execute the 10-case, three-branch campaign;
5. review the evidence independently before any `CHOSEN` decision.

The source research and feedback synthesis are the inputs for this plan:
[`trend-research.md`](trend-research.md) and
[`feedback-synthesis.md`](feedback-synthesis.md). The accepted benchmark
contract remains [`outputs/08-empirical-benchmark-protocol.md`](../../../outputs/08-empirical-benchmark-protocol.md).

## First milestone: M1 Artifact DAG + root provenance proof

M1 is a proof milestone, not a framework expansion. It is complete only when
all of the following are true:

- the primary user segment and operator task are recorded;
- the canonical operator read surface is selected (machine-readable readiness
  record plus, if needed, a human-readable projection);
- `control`, `source_native`, and `abk_native` have explicit runner manifests,
  pinned inputs, and declared capability/authority boundaries;
- the frozen campaign has exactly 10 cases, 6 common cases, 4 specific cases,
  30 primary cells, and 66 expected raw runs;
- every run is isolated, hash-pinned, and records stdout, stderr, exit code,
  tool events, output inventory, oracle result, and before/after state checks;
- the ten fixture oracles and six hard gates are mechanically recomputable;
- ambiguous, invalid, out-of-root, interrupted, or unowned operations fail
  closed with no unowned mutation;
- no result is promoted beyond `UNSCORED` without the complete evidence and
  explicit human decision required by the protocol.

M1 does not require this Framework-Matrix repository to contain ABK runtime
source. The `abk_native` implementation, if approved, belongs to the separate
AI Booster Kit project; this repository retains the source-neutral contract,
fixture, provenance, and evidence boundary.

## Sequenced plan

| Order | Slice | Deliverable | Exit gate | Dependency |
|---:|---|---|---|---|
| 0 | Discovery closeout | Primary user segment, JTBD, control-runner decision, canonical read-surface decision, open-question register | Product owner accepts the problem statement and unresolved items are explicit | Trend and feedback synthesis |
| 1 | Runner and rubric freeze | Three branch manifests, fixed fixture/oracle table, score weights, timeout/repeat policy, evidence layout | Schema and semantic validator pass; no mutable `main` or unpinned runtime is used | 0 |
| 2 | Minimal Artifact DAG substrate | Clean-room artifact identity, root provenance, readiness projection, ownership and path-boundary checks | Unit/contract tests cover valid, boundary, invalid, stop, recovery, and handoff behavior | 1 |
| 3 | Isolated campaign execution | 30 primary cells and the formula-derived raw run set (currently 66) | Every expected run has a unique passed evidence ID and no path escape or undeclared side effect | 2 |
| 4 | Independent review and decision | Three branch scorecards, adjudication record, reproducible summary | Six hard gates pass; outcome is recomputable; `CHOSEN` requires human approval | 3 |
| 5 | Next-slice decision | Materialization/ownership slice or explicit rejection/defer record | M1 evidence is archived and the next scope is bounded | 4 |

The current local state is at the end of the contract-preparation part of
orders 0–1: the campaign schema, fixture set, and fail-closed validator exist,
but no empirical campaign has run and no score is earned.

## Scope boundaries

### In scope for M1

- one clean-room Artifact DAG + root-provenance behavior;
- Codex-local, fixture-driven runners and deterministic evidence;
- ownership, path security, isolation, stop, recovery, and handoff checks;
- source-native reproduction only when it can be pinned and run locally without
  upstream runtime leakage;
- evidence and review artifacts in Framework-Matrix.

### Out of scope

- installing, forking, or importing any upstream runtime into Framework-Matrix;
- adding AI Booster Kit source code or a Git connection to this repository;
- multi-host adapters, plugin registries, broad persona/skill expansion, or a
  production migration;
- network, credentials, production resources, Git mutation, or external writes
  during the campaign;
- declaring `CHOSEN` from static research or `ADOPTED` without separate human
  approval.

## Helper-team allocation

The requested temporary research roles map to the available roster as follows:

| Profile | Responsibility in this sequence |
|---|---|
| Agents Orchestrator | Owns handoffs, evidence IDs, state transitions, and escalation; does not silently repair failures. |
| Multi-Agent Systems Architect | Defines authority, capability, context, and branch-isolation boundaries. |
| Workflow Architect | Freezes the ten case flows, terminal states, stop/recovery paths, and composition handoff. |
| Software Architect | Owns the artifact/state contract, canonical IR boundary, provenance model, and schema evolution. |
| Minimal Change Engineer | Keeps the M1 implementation to the smallest clean-room slice and rejects scope creep. |
| Solution Engineer | Builds the local runner harness and deterministic fixture/oracle execution surface in the approved project. |
| Product Manager | Owns user-segment discovery, JTBD, interview questions, and problem/benefit acceptance. This profile performed the Trend Researcher role for this pass. |
| Senior Project Manager | Owns sequencing, dependencies, gates, and decision records. This profile is the Sprint Prioritizer role. |
| Studio Operations | Owns isolated run directories, retention, replay, logs, and operational readiness. |
| Workflow Optimizer | Owns bottleneck hypotheses, feedback synthesis, latency/repeatability measures, and process improvements. This profile performed the Feedback Synthesizer role. |
| Behavioral Nudge Engine | Designs operator-facing prompts and feedback loops only after authority, stop, and evidence contracts are stable; it cannot weaken a hard gate. |

Parallel work is appropriate only for independent discovery or review slices.
Shared campaign state, scorecards, and runner manifests require one owner and
read-back before another role acts.

## Acceptance and stop gates

The following gates are binary. A failed gate stops the sequence and preserves
the evidence; it does not trigger automatic retry, cleanup, rollback, or
status promotion.

1. **Problem gate:** primary user, task, and canonical read surface are named;
   unresolved alternatives remain in the open-question register.
2. **Contract gate:** the campaign validator accepts the frozen manifest and
   rejects duplicate/missing cases, hash drift, path escape, invalid repeats,
   premature outcome, and completed-run claims in pending state.
3. **Runner gate:** each branch declares its exact executable boundary, pinned
   fixture/schema inputs, timeout, stop condition, and forbidden side effects.
4. **Isolation gate:** each run gets empty temporary configuration/cache roots;
   no credential, network, production, or Git mutation is possible.
5. **Evidence gate:** every raw run has a unique evidence ID, valid locator,
   SHA-256, oracle result, and before/after negative check.
6. **Decision gate:** all ten cases, six hard gates, three scorecards, and the
   outcome formula are machine-recomputed; human review is recorded separately.

Stop immediately if the control runner is undefined, the source-native branch
cannot be reproduced, a fixture or schema hash drifts, a run writes outside its
ownership manifest, an unknown event becomes a silent success, or evidence
cannot be independently re-read.

## Assumptions

- The first user is an ABK maintainer/operator evaluating safe, inspectable
  project state; a multi-repo platform team may be the next segment.
- Codex remains the only valid host for M1; other hosts are later parity
  questions, not substitutions for a failed source-native run.
- The existing five candidates and pinned research package remain the intended
  comparison set.
- The control branch can be made observable without importing an upstream
  runtime or credentials.
- A clean-room ABK-native implementation can be developed in its separate
  project after this discovery gate is accepted.

## Open questions before scoring

1. What exact command/process is the `control` runner, and what terminal output
   schema does it emit?
2. Can `source_native` be pinned and reproduced locally in Codex without
   installing an upstream runtime? If not, what evidence records its rejection?
3. Which weight vector and reviewer rubric are frozen for the ten dimensions?
4. Is the canonical operator surface JSON, Markdown, or a paired projection?
5. What latency, token, storage, and retention budget is acceptable for a first
   run and a reviewer rerun?
6. Which five user interviews or structured feedback sessions are authorized,
   and how will completion time, trust, error comprehension, and rerun intent
   be recorded?
7. Which offline, air-gapped, Windows, and multi-repository constraints are
   hard requirements rather than later hardening?

## Verification commands for the current substrate

```powershell
& .\benchmarks\scripts\validate-benchmark-campaign.ps1 `
  -CampaignPath .\benchmarks\campaigns\artifact-dag-core-v1\campaign.json `
  -WorkspaceRoot (Get-Location).Path

& .\benchmarks\tests\test-benchmark-campaign.ps1 `
  -WorkspaceRoot (Get-Location).Path
```

These commands verify contract preparation only. They do not run the empirical
campaign and must not be reported as `CHOSEN`, `ADOPTED`, or a user-study result.

# M1 user segment and JTBD decision

**Status:** Discovery decision; interviews not yet conducted
**Date:** 2026-08-03 (Europe/Budapest)
**Scope:** Framework-Matrix discovery for the separate AI Booster Kit (ABK) boundary

## Evidence boundary

This is a product hypothesis and discovery plan, not a user-study result. The
local research package contains source analysis, proposed contracts, fixtures,
and benchmark oracles. It contains no interviews, user telemetry, adoption
decision, or completed benchmark run. The current campaign is explicitly
`benchmark_pending` / `UNSCORED` with zero completed cells
(`benchmarks/campaigns/artifact-dag-core-v1/campaign.json`).

## Decision

### Primary M1 segment

**ABK maintainer/operator evaluating safe, inspectable project state.**

This is the person who maintains or evaluates the vendor-neutral ABK substrate,
runs a fixture-driven Codex-local comparison, reviews evidence, and decides
whether a pattern is ready for a later ABK implementation decision. They are
not an assumed end customer of a production framework. Their M1 job is to
determine whether an Artifact DAG + root-provenance contract is understandable,
reproducible, bounded, and safe to hand off.

The choice follows the strongest project-local signal: the feedback synthesis
assumes the immediate customer is an ABK maintainer/operator who must safely
evaluate inspectable project state, while a multi-repository platform team is a
later segment (`archive/work/continuation-research/feedback-synthesis.md`,
§7). The sprint plan repeats this segment and makes M1 a proof milestone rather
than a broad framework release (`archive/work/continuation-research/sprint-prioritization.md`,
§1 and §Assumptions).

### Segments deliberately deferred

| Segment | Decision | Reason for deferral in M1 |
|---|---|---|
| Solo brownfield maintainer | Secondary discovery segment | Useful for validating resume and artifact comprehension, but M1 has no production integration or end-user workflow. |
| Multi-repository platform/enablement team | Next candidate segment | Relevant to registry, policy, and cross-repository questions, but those are outside the single-component M1 proof. |
| Project developer using an installed framework | Out of M1 | The ABK runtime does not belong in this repository, and M1 does not claim a shipped product experience. |

### M1 read-surface decision

The **machine-readable readiness/provenance record is canonical**. A concise
human-readable Markdown projection may accompany it for review, but it cannot
be the only state surface. This supports the protocol's requirement for
re-readable evidence and the catalog's separation of durable state from chat
memory (`outputs/06-reusable-pattern-catalog.md`, patterns 1 and 9;
`outputs/08-empirical-benchmark-protocol.md`, §Run policy and §Evidence layout).

### Control-boundary decision

For discovery, `control` means the current documented manual/ABK baseline with
the same fixture and no upstream runtime. The exact executable command,
terminal-record schema, and whether that baseline can produce all required
oracles remain open runner-freeze questions. We must not silently substitute an
upstream runtime or call an undefined baseline a passing control.

## Jobs to be done

These are hypotheses to validate with the selected segment; they are not
reports of completed interviews.

| Priority | Job story | Current pain hypothesis | Desired gain | M1 probe / signal |
|---:|---|---|---|---|
| 1 | When I inspect a project, I want to know which artifacts and dependencies make it ready, so I can choose the next allowed action without reconstructing chat history. | Readiness can degrade into an implicit command sequence or transcript memory. | Deterministic readiness from the on-disk graph, with a clear blocked state. | Participant identifies the next allowed action and missing dependency from a valid and a blocked fixture. |
| 2 | When a result is accepted or blocked, I want to explain its root, source, hashes, and evidence, so another reviewer can re-check my decision. | Aggregate research counts do not link a pattern to a case, run, exit code, or expected/actual record. | A provenance-bound evidence chain that is independently re-readable. | Participant reconstructs the readiness decision from emitted records without hidden conversation context. |
| 3 | When input is malformed, out of root, interrupted, or partially written, I want the run to stop explicitly and leave no unowned mutation, so I can resume safely. | Silent fallback, ambiguous success, and partial cleanup create unsafe recovery decisions. | Typed fail-closed errors, terminal stop state, and ownership-scoped recovery. | Participant correctly distinguishes `blocked`/`stopped`/`recovery_required` from success and finds the safe next action. |
| 4 | When comparing a pattern, I want the same fixture exercised by `control`, `source_native`, and `abk_native`, so I can separate behavior evidence from framework reputation. | Static documentation and upstream tests cannot establish local adoption quality. | Recomputable three-branch evidence with repeatability and variance preserved. | Participant locates case/branch/run evidence and rejects a premature `CHOSEN` claim while the campaign is pending. |
| 5 | When I hand a validated graph to the next component or reviewer, I want provenance and authority to travel with it, so an invalid or untrusted handoff cannot become a success. | Component boundaries and authority can be implicit, especially during recovery or composition. | A verifiable, provenance-bound handoff with explicit terminal status. | Participant accepts only the validated handoff and rejects an unknown or unvalidated reference. |

## Pains and gains summary

| Pain signal | Evidence status | M1 gain hypothesis |
|---|---|---|
| Readiness hidden in chat or an implicit sequence | **Direct local design signal:** the catalog identifies filesystem-derived Artifact DAG as the answer to this problem (`outputs/06-reusable-pattern-catalog.md`, pattern 1). | The operator can derive readiness and the next allowed action from a versioned artifact graph. |
| Evidence is too coarse to support adoption decisions | **Direct local audit signal:** the feedback synthesis records no gear-to-case/run/evidence join before the continuation work (`feedback-synthesis.md`, §2). | Every claim can be followed component → case → branch → run → oracle/evidence. |
| Unsafe continuation after malformed, out-of-root, or partial state | **Direct contract signal:** fixtures and protocol require typed errors, stop records, ownership-scoped recovery, and no partial state (`campaign.json`; `outputs/08-empirical-benchmark-protocol.md`, §Fix ten matrix). | The operator gets a fail-closed result and actionable recovery boundary instead of an ambiguous success. |
| Framework choice is being inferred from static maturity or documentation | **Direct process signal:** the research design forbids upstream evidence from becoming `CHOSEN` (`outputs/00-sdd-framework-research-design.md`, §Kutatási módszer). | The operator can make a bounded evidence decision without importing or adopting an upstream runtime. |
| Portable behavior risks host drift | **Inference from pattern catalog:** canonical IR and adapter parity are proposed, not validated user demand (`outputs/06-reusable-pattern-catalog.md`, pattern 2). | Defer multi-host claims until a later parity slice; keep M1's contract host-neutral and Codex-local. |

## Small structured feedback/interview protocol

### Objective and sample

- Run **five 45-minute sessions** before freezing the next runner/reviewer gate;
  this is a proposed minimum, not completed research.
- Recruit people who have maintained or evaluated agent/workflow state in a
  repository, can inspect JSON/Markdown artifacts, and can describe a recent
  interrupted, failed, or handoff task. Include at least two people who have
  operated on Windows or in a constrained/offline environment if available.
- Do not collect credentials, production data, private repository content, or
  identifiable secrets. Use a sanitized fixture workspace and Codex-local
  artifacts only.

### Session script

1. **Context (5 min):** explain that this is a research contract, not a shipped
   product; ask the participant to describe their last real state/recovery or
   review problem. Do not lead with an Artifact DAG solution.
2. **Current practice (10 min):** ask them to show or sketch how they decide
   readiness, record provenance, recover after interruption, and hand off work.
3. **Scenario tasks (20 min):** present the same sanitized records for:
   `COM-01` valid readiness, `COM-05` malformed input, `COM-06` stop,
   `SPC-01` out-of-root dependency, `SPC-03` ownership-scoped recovery, and
   `SPC-04` provenance-bound handoff. Ask them to state (a) result, (b) why,
   (c) next safe action, and (d) what evidence they would retain.
4. **Trade-offs (5 min):** ask whether they prefer a concise Markdown view,
   machine-readable JSON, or both; probe latency, storage, repeatability, and
   human-approval tolerance.
5. **Close (5 min):** ask what would make them rerun the case, what would make
   them distrust it, and whether the proposed evidence is sufficient for a
   reviewer to disagree safely.

### Capture and analysis

Record session ID, participant segment, task completion/time, interpretation of
the terminal state, evidence they requested, confidence (1–5), trust concern,
and rerun intent (yes/no/conditional). Code each observation to a JTBD and
label it **observed**, **reported**, **inferred**, or **unresolved**. Preserve
verbatim notes only in the approved research store; this repository receives
the aggregate decision, not personal data. Two reviewers should independently
code the five sessions and retain disagreements.

## Measurable acceptance signals

The thresholds below are **proposed discovery gates**, not current baselines.
They complement—never replace—the frozen campaign oracles and hard gates.

### User-facing discovery signals

| Signal | Proposed M1 target | Measurement |
|---|---:|---|
| Readiness comprehension | ≥4 of 5 participants identify the correct next action and cite the dependency/root evidence on `COM-01` and `COM-05`. | Scenario task score; no prompting after the initial instruction. |
| Terminal-state comprehension | ≥4 of 5 correctly distinguish success, blocked, stopped, and recovery-required on `COM-05`, `COM-06`, and `SPC-03`. | Scenario task score and explanation quality rubric. |
| Independent re-readability | ≥4 of 5 reviewers can reconstruct one readiness decision from JSON/projection alone in ≤10 minutes. | Timed re-read; record requested missing fields. |
| Recovery trust | ≥4 of 5 state they would rerun/review after an interruption **only after** verifying ownership-scoped evidence; no participant recommends deleting unowned files. | Post-task answer plus observed recommendation. |
| Handoff safety | 5 of 5 reject an unknown or unvalidated handoff and accept only the provenance-valid record. | `SPC-02`/`SPC-04` scenario outcome. |
| Surface preference | A clear majority chooses a paired JSON + concise Markdown surface, or gives a documented reason to select one. | Trade-off question; do not pre-fill a preference. |

If a target is missed, record the finding and revise the contract or UX before
adding adapters/roles. Do not relabel a missed user signal as benchmark success.

### Mechanical M1 guardrails

The M1 campaign remains `UNSCORED` until it has exactly 10 cases (6 common,
4 component-specific), 30 primary cells, and the formula-derived 66 raw runs;
all runs must be isolated, hash-pinned, re-readable, and side-effect bounded.
The ten fixture oracles must demonstrate deterministic readiness, typed failure,
explicit stop, out-of-root rejection, ownership-scoped recovery, and validated
handoff. These are contract gates from
`outputs/08-empirical-benchmark-protocol.md` and
`benchmarks/campaigns/artifact-dag-core-v1/campaign.json`, not user-interview
results.

## Assumptions

1. **[Assumption]** The ABK maintainer/operator is available as the first
   discovery participant and has authority to review local evidence, but not to
   approve production adoption from this artifact.
2. **[Assumption]** M1 is the Artifact DAG + root-provenance proof only; the
   ABK-native implementation belongs in the separate AI Booster Kit project.
3. **[Assumption]** Codex is the only valid host for M1. Claims about Claude
   Code, Copilot, or other hosts are later parity hypotheses, not substitutions.
4. **[Assumption]** The current `main` baseline and accepted protocol remain
   authoritative until a reviewed discovery decision changes them.
5. **[Assumption]** The paired surface (canonical JSON plus optional Markdown
   projection) is sufficient for both machine recomputation and human review;
   the interviews must test this rather than treat it as validated fact.

## Open questions before runner freeze or scoring

| Question | Why it matters | Owner / decision point |
|---|---|---|
| What exact command/process and terminal schema implement `control`? | An undefined baseline cannot produce a comparable score or valid stop evidence. | M1 runner owner; resolve before runner manifests are frozen. |
| Can `source_native` be reproduced locally at its pinned OpenSpec commit without upstream runtime leakage? | If not, it must be explicitly blocked/rejected with evidence, never silently substituted. | M1 runner owner; resolve before first campaign run. |
| Which score weights and reviewer rubric are fixed for the ten dimensions? | The outcome formula is not recomputable until the weight vector and adjudication rules are published. | Product/review owner; resolve before scorecards. |
| What is the acceptable latency, token, storage, and retention budget for a first run and reviewer rerun? | The campaign has case timeouts but no user-centered service target. | Product + operations; measure in the five sessions. |
| Which offline, air-gapped, Windows, and multi-repository constraints are hard M1 requirements? | The trend scan makes these plausible needs, but their priority is unvalidated. | Product owner; resolve from interviews before expanding scope. |
| What evidence fields are mandatory in the human projection versus JSON? | Too little detail blocks review; too much detail harms comprehension and increases cost. | Product + reviewer; resolve from re-read task results. |
| What approval policy applies to future extension installation, network access, and Git mutation? | M1 forbids these effects, while later ABK slices may need explicit human gates. | ABK platform owner; keep outside this repository and M1. |

## Explicit boundary and next step

Framework-Matrix remains the source-neutral authority for research, fixture
contracts, provenance, and evidence. It will not install an upstream runtime,
add ABK runtime source, connect to the ABK Git repository, or claim `CHOSEN` or
`ADOPTED` from this decision. After the five discovery sessions, freeze the
runner manifests and reviewer rubric in the separate approved workstream; keep
any ABK-native implementation and execution artifacts outside this repository.

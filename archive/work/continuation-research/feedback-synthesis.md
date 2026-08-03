# Feedback synthesis — continuation research

## Purpose and evidence boundary

This note translates the completed source-research package into testable user
needs and feedback hypotheses for the next build. It does not claim that a
vendor-neutral framework or an adoption result already exists. The labels are:

- **[Fact]** directly stated or mechanically recorded in the local artifacts;
- **[Inference]** a product or user interpretation derived from those facts;
- **[Unknown]** a question that the current package cannot answer.

The current repository state is `main` at `4b94415f64115b6830651cc525cb44682d84dbe0`,
with the pre-existing dirty changes (`README.md` and `benchmarks/`) preserved.
The continuation artifact is intentionally read-mostly: no upstream runtime or
AI Booster Kit source is introduced here.

## Executive synthesis

The strongest demand signal is not for more personas or host-specific prompt
content. It is for a small, inspectable substrate that can answer four
questions on every run: *what is ready, why is it ready, what may execute next,
and what happened if execution stopped or failed?* The local research shows
that artifact-derived readiness, provenance, ownership, isolation, bounded
review, and explicit human approval recur across the strongest patterns, while
the same sources expose unsafe defaults when those controls are only prompt
conventions or when lifecycle mutation is partial. The first build should
therefore prove one narrow Artifact DAG + root-provenance contract end to end,
before adding broad adapter or agent surfaces.

## 1. Directly evidenced user needs

The “user” below is a working role inferred from the artifacts (maintainer,
operator, reviewer, or approver), not a claim that interviews have already been
conducted.

| Job to be done | Directly evidenced need | Local evidence | Confidence |
|---|---|---|---|
| Establish readiness | Derive the next allowed action from valid, on-disk artifacts and dependencies, rather than chat memory or an implicit command sequence. | The catalog identifies this as the Artifact DAG problem and requires schema, dependency, readiness, cycle, and missing-root handling (`outputs/06-reusable-pattern-catalog.md:52-74`). | High |
| Explain decisions | Preserve root, source, hash, and evidence provenance so an operator can inspect why a result was accepted or blocked. | OpenSpec is described as returning structured root provenance; the benchmark oracles require readiness and provenance evidence (`outputs/02-fission-openspec.md:2`, `benchmarks/campaigns/artifact-dag-core-v1/campaign.json`). | High |
| Resume safely | Recover from interruption or partial writes without guessing from a transcript and without deleting unowned data. | The Run Journal and manifest-scoped sandbox patterns specify durable state, ownership, recovery, and explicit terminal states (`outputs/06-reusable-pattern-catalog.md:259-329`). | High |
| Avoid destructive surprises | Preview the exact mutation plan, detect path/hash/ownership conflicts, and require a human gate for risky actions. | Spec Kit and OpenSpec evidence supports preview, hash ownership, atomic writes, and archive safety; the protocol requires explicit stop/recovery and no undocumented side effects (`outputs/01-github-spec-kit.md:34,91,200`; `outputs/08-empirical-benchmark-protocol.md:51-62`). | High |
| Keep behavior portable | Author one canonical behavior and project it into host-native surfaces, with parity checks rather than hand-maintained prompt trees. | The catalog names canonical IR → host adapters and generated parity as target contracts (`outputs/06-reusable-pattern-catalog.md:76-100,381-405`). | Medium–high; the unified IR is a proposed design |
| Limit agent authority | Know what a role may read/write, what capability it has, what evidence it must emit, and when it must stop or escalate. | GSD producer/checker roles, BMAD bounded review, and the proposed `RoleContract` specify inputs, outputs, write scope, stop, escalation, and forbidden actions (`outputs/03-open-gsd-gsd-core.md:31-33,106-122`; `outputs/06-reusable-pattern-catalog.md:154-200`). | High |
| Trust extensions explicitly | Keep discovery, installation, enablement, and execution consent separate; re-consent when content changes. | GSD’s external consent store binds project identity, capability ID, bundle hash, and disclosure; package install alone must not grant execution (`outputs/06-reusable-pattern-catalog.md:283-305`). | High |
| Decide adoption on evidence | Compare control, isolated source-native behavior, and ABK-native behavior on the same cases; do not infer `CHOSEN` from upstream tests or documentation. | The adoption plan and protocol define the three branches, fixed cases, scores, thresholds, and a separate human approval for `ADOPTED` (`outputs/10-abk-pattern-adoption-refactor-plan.md:9-20,46-75`; `outputs/08-empirical-benchmark-protocol.md:3-18,97-114`). | High |

## 2. Pain points and evidence of demand

| Pain point / demand signal | Direct evidence | Implication for the next build |
|---|---|---|
| Static research did not prove adoption. | The accepted gap audit found no 10-case matrix, no numeric scorecards, no separately runnable prototypes, and no valid `CHOSEN`/`CANDIDATE`/`REJECTED` result (`archive/work/reviews/accepted-protocol-gap-audit.md:3-12,74-132`). | Treat all catalog rankings as hypotheses until a complete campaign produces recomputable results. |
| Evidence granularity is a bottleneck. | The audit counted 5,000 gear rows, but none linked a gear to a smoke/reproduction case, run ID, exit code, or expected/actual record (`archive/work/reviews/accepted-protocol-gap-audit.md:133-179`). | Build a mechanical join from component → case → run → evidence; aggregate suite counts are insufficient. |
| Existing frameworks contain useful patterns and unsafe shortcuts. | Spec Kit has `shell=True`, prompt/no-op event paths, partial bundle cleanup, and four validator-broken bundle examples (`outputs/01-github-spec-kit.md:34,164-200,222-295`). OpenSpec has real-user config-root exposure and silent instruction degradation (`outputs/02-fission-openspec.md:41,205-206`). GSD has a 13,531-line installer boundary, mixed fail-open hooks, and advisory injection scanning (`outputs/03-open-gsd-gsd-core.md:41,146,186,239-247`). Paul has 58 installed references without distributed targets and prompt-only enforcement (`outputs/04-christopherkahler-paul.md:290-297,473-479`). BMAD has catch-and-continue dependency failures and Windows portability failures (`outputs/05-bmad-method.md:36-38,339-358`). | Reuse behavior-level contracts only; make trust, path, failure, and portability checks first-class acceptance criteria. |
| The package is large enough that manual coordination will drift. | Migration read-back records 5,027 tracked upstream files, 608 archived work files, and 184 evidence-ZIP entries (`MIGRATION-VERIFICATION.md:5-21`). | Generated manifests, hashes, and coverage checks should be treated as product features, not documentation extras. |
| A concrete next experiment is already frozen. | The benchmark substrate is `benchmark_pending`, has zero completed runs, and defines an Artifact DAG + root provenance campaign (`benchmarks/README.md:1-16`; `benchmarks/campaigns/artifact-dag-core-v1/campaign.json`). | Start with the existing fixture contract instead of broadening scope to multiple patterns. |

## 3. Trust and safety requirements

These are direct safety constraints in the package, not optional UX polish:

1. **Local and reversible execution.** Every run uses empty temporary HOME,
   user/config/data roots and tool caches; network, credentials, production
   resources, Git mutation, and external writes are forbidden
   (`outputs/08-empirical-benchmark-protocol.md:51-62`).
2. **Fail closed on ambiguity.** Unknown artifact, cycle, schema error, root
   escape, hash mismatch, symlink, unowned overwrite, or missing capability
   must stop the run rather than invent state or silently continue
   (`outputs/06-reusable-pattern-catalog.md:52-74,102-126,202-231`).
3. **Data is not instruction.** Repository files, prompts, references, logs,
   and tool output remain untrusted input; inserted content must not expand
   transitively into executable instructions. The Paul and Spec Kit findings
   show why prompt-only boundaries are inadequate
   (`outputs/04-christopherkahler-paul.md:394-399`; `outputs/06-reusable-pattern-catalog.md:331-355`).
4. **Consent is content-bound.** A changed bundle hash makes prior consent
   stale; disclosure must identify executable paths and transport/argument
   surfaces without exposing secrets (`outputs/06-reusable-pattern-catalog.md:283-305`).
5. **Human approval is explicit.** `CHOSEN` is empirical selection, not
   permission to change the platform; `ADOPTED` requires a separate approval
   record (`outputs/08-empirical-benchmark-protocol.md:97-114`).

## 4. Feedback hypotheses for the next build

The following are **[Inference]** hypotheses. Each includes a falsifiable
feedback signal; no user-satisfaction value is fabricated because the current
package contains no user-study or operator telemetry.

| ID | Hypothesis | Why it follows | Feedback / experiment signal |
|---|---|---|---|
| H1 | Operators will trust a readiness result more when every node and dependency is visible and provenance-bound. | Artifact DAG and root provenance are repeatedly identified as the cleanest foundation (`outputs/06-reusable-pattern-catalog.md:3-13,52-74`). | In COM-01/02, an independent reviewer can reconstruct readiness and root provenance from emitted artifacts alone; no chat context is required. |
| H2 | Explicit fail-closed errors reduce unsafe continuation, even if they add ceremony. | Current sources expose silent fallback/no-op and partial-state risks; the target contracts require typed errors and no partial state. | COM-05, SPC-01, and SPC-02 stop before readiness; error records identify the offending input and contain no derived success state. |
| H3 | Repeatability and evidence stability matter more than raw speed for adoption decisions. | The protocol marks repeatability critical and stores separate repeated runs; upstream runtime success is explicitly not adoption proof. | COM-03 produces identical graph/readiness/evidence hashes across its three isolated repeats; scorecards retain variance rather than hiding it. |
| H4 | Ownership-scoped recovery is a prerequisite for operator acceptance of automation. | The catalog’s recovery patterns and SPC-03 oracle require cleanup limited to owned derived state. | SPC-03 restores a valid resumable boundary, leaves unowned files unchanged, and emits an ownership-scoped recovery record. |
| H5 | A validated handoff is the minimum useful composition unit. | The proposed lifecycle and SPC-04 require only a validated graph to cross a component boundary. | SPC-04 is accepted only when the receiving component verifies provenance and rejects an unvalidated handoff. |
| H6 | A canonical substrate can reduce host drift, but the adapter compiler becomes a new high-risk boundary. | Canonical IR/adapter and parity patterns promise less duplication, while the catalog explicitly calls the compiler security-critical (`outputs/06-reusable-pattern-catalog.md:76-100`). | A later adapter slice must show byte/semantic parity and zero path/capability drift; until then, do not generalize M1 into a multi-host claim. |
| H7 | Bounded checker loops improve quality only when progress and terminal states are observable. | GSD/BMAD loops cap iterations and escalate on non-convergence; unbounded self-repair is listed as an anti-pattern (`outputs/06-reusable-pattern-catalog.md:178-200,478-489`). | A future reviewer slice reports iteration count, finding fingerprints, and `pass`, `blocked`, or `exhausted`; repeated findings do not auto-loop forever. |
| H8 | Users will prefer an explainable configuration chain over implicit precedence, provided the diagnostic is concise. | Layered precedence is proposed to replace mixed environment/user/project/session overrides (`outputs/06-reusable-pattern-catalog.md:128-152`). | A future `config explain` check can identify the winning source and protected Global policy for each key without revealing secrets. |

## 5. Tensions and trade-offs to make explicit

- **Auditability vs. throughput.** Durable journals, hashes, independent
  reviewers, and three-repeat cases add storage, latency, and token cost. The
  protocol intentionally makes task success, correctness/evidence,
  repeatability, observability, and stop/recovery critical; speed cannot
  compensate for a critical failure (`outputs/08-empirical-benchmark-protocol.md:78-112`).
- **Fail-closed safety vs. availability.** An unknown capability or malformed
  project layer should block, while optional observability may be non-blocking.
  The target must make this policy machine-readable instead of inheriting the
  mixed upstream behavior (GSD warning/fail-open and Spec Kit no-op paths).
- **Canonical IR vs. adapter complexity.** One source of behavior reduces
  duplication and drift, but every host adapter is a security-sensitive
  projection boundary requiring its own path, capability, and parity tests.
- **Automation vs. human judgment.** Preview, recovery, and checker loops can
  automate routine work, but destructive merge, trust, and adoption decisions
  remain human gates. Automatic `CHOSEN → ADOPTED` is out of scope.
- **Clean-room adaptation vs. direct reuse.** All five pinned repositories are
  MIT-licensed, but direct reuse still carries notice/provenance obligations;
  clean-room behavior-level implementations reduce coupling and branding risk,
  not because MIT forbids reuse (`outputs/06-reusable-pattern-catalog.md:15-39`).
- **Strict schema vs. onboarding burden.** Closed manifests and typed errors
  prevent extension drift but make a first pilot more ceremonial. The pilot
  should measure operator comprehension before adding richer package surfaces.

## 6. Measurable acceptance signals for the first milestone

The next build should prove one component only: **Artifact DAG + root
provenance**. The existing campaign freezes the measurement contract; it does
not yet contain run results.

### Contract-level signals (must be machine-checkable)

1. Campaign remains exactly `benchmark_pending`/`UNSCORED` until evidence exists;
   no premature `CHOSEN` or `ADOPTED` appears (`benchmarks/README.md:8-16`; `outputs/08-empirical-benchmark-protocol.md:139-154`).
2. Exactly 10 cases are executed across exactly three branches
   (`control`, `source_native`, `abk_native`): 6 common, 4 specific, 30 primary
   cells. The frozen campaign expects **66 raw runs** after applying its
   per-case repeat flags (`benchmarks/campaigns/artifact-dag-core-v1/campaign.json`).
3. Every run has an isolated temporary environment, pinned fixture/schema
   hashes, stdout/stderr, tool events, output inventory, oracle result, exit
   code, and before/after negative checks for real user/Codex configuration
   (`outputs/08-empirical-benchmark-protocol.md:51-62,120-154`).
4. Every executable gear receives exactly one disposition and an evidence link;
   no unclassified or path-escaping evidence remains (`outputs/08-empirical-benchmark-protocol.md:137-154`).
5. Six hard gates are present and machine-recomputed: observable state/errors,
   testable behavior, declared authority/side effects, reversible or
   recoverable operation, upstream-runtime independence, and no undocumented
   side effects (`outputs/09-adoption-scorecard.schema.json`, `definitions.hard_gate`).

### Behavior-level signals (the 10 fixture oracles)

- `COM-01` and `COM-02`: valid graphs emit deterministic readiness and root
  provenance; dependency shape may vary but the contract shape remains stable.
- `COM-03`: three repeats preserve graph, readiness hash, and evidence shape.
- `COM-04`: the smallest valid graph is accepted without implicit artifacts.
- `COM-05`: malformed dependency fails with a typed actionable error and no
  partial state.
- `COM-06`: interruption creates an explicit terminal stop record, never an
  ambiguous success.
- `SPC-01`: an out-of-root dependency is rejected before it is read.
- `SPC-02`: an unknown artifact reference produces no readiness result.
- `SPC-03`: recovery removes only owned derived state and restores a resumable
  boundary.
- `SPC-04`: only a validated graph crosses the handoff, and the receiver can
  verify its provenance.

These are direct campaign oracles, not forecasts (`benchmarks/campaigns/artifact-dag-core-v1/campaign.json` and its `fixtures/*.json`).

## 7. Assumptions and open questions

### Assumptions used in this synthesis

- **[Assumption]** The immediate customer is the ABK maintainer/operator who
  must safely evaluate and later adopt atomic patterns; downstream project
  developers are the secondary users.
- **[Assumption]** M1 is the frozen Artifact DAG campaign, not a broad
  multi-host or production integration release.
- **[Assumption]** The `control` branch can be represented by the current
  ABK/manual process without importing an upstream runtime.
- **[Assumption]** Local Codex execution is the only valid host for this gate;
  external services and credentials remain excluded.

### Open questions that must be answered before scoring

1. What is the exact `control` runner and its observable output schema? A
   manual baseline is named, but its command, version, and expected terminal
   records are not yet present in this repository.
2. What does `source_native` mean for this campaign if no OpenSpec runtime is
   installed here? The runner needs a pinned, isolated reproduction boundary;
   otherwise the source branch must be explicitly marked blocked/rejected with
   evidence rather than silently substituted.
3. Which score weights and reviewer rubric will be frozen? The protocol names
   ten dimensions and critical dimensions, while the scorecard schema validates
   positive weights and `round3(sum(score*weight))`; a release gate needs one
   published weight vector before runs.
4. What operator-facing artifact is the primary “read” surface: a JSON
   readiness record, concise Markdown state, or both? The catalog recommends
   machine evidence plus human-readable state, but M1 has not selected a
   canonical presentation.
5. What is the acceptable diagnostic latency and token budget for a first run?
   The campaign has case timeouts, but no user-centered service target.
6. How will feedback be collected from real maintainers/operators after the
   pilot (task completion time, error comprehension, trust, and willingness to
   re-run)? No user study or satisfaction baseline is in the current evidence.

## Recommendation

Make M1 a **proof milestone**, not a framework expansion: complete the frozen
Artifact DAG + root-provenance campaign with the three branches and 66 raw-run
budget, and publish only mechanically recomputable evidence. M1 passes when
all ten behavior oracles and six hard gates pass, every ambiguous or unsafe
input fails closed with no unowned mutation, repeated valid inputs are
evidence-stable, recovery is ownership-scoped, and the receiver verifies a
provenance-bound handoff. A completed campaign may then produce a
`REJECTED`/`CANDIDATE`/`CHOSEN` result according to the fixed formula; it must
still not create `ADOPTED` state without explicit human approval. If any of
these signals cannot be demonstrated, keep the result `UNSCORED` and resolve
the evidence gap before adding adapters, hooks, or broader agent roles.

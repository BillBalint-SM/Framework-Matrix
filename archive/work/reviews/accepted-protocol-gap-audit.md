# Accepted empirical protocol gap audit

## Verdict

**FAIL — the package is not acceptable under the newly accepted empirical protocol.**

The existing package is strong as a pinned static/source dossier with uneven project-level runtime checks. It does not contain the empirical adoption protocol required by this audit. The missing layer is not a small formatting defect: there is no gear-to-reproduction traceability, no 10-case evaluation matrix, no 1–10 score model, no threshold-derived outcome, no separately evaluated `ORIGINAL`/`BASELINE`/`ABK` prototypes, and no prototype-level Codex-local isolation proof.

No candidate can currently be classified validly as `REJECTED`, `CANDIDATE`, or `CHOSEN`, because the input scores and case results needed by those rules do not exist. The executive recommendations in `outputs/06-reusable-pattern-catalog.md:L3-L13` and the final comparative conclusion at `L476-L480` therefore remain source-informed design judgments, not accepted-protocol adoption decisions.

No deliverable, evidence artifact, inventory, checkout, or runtime clone was modified by this audit. The only new file is this review.

## Audit scope and current state

Audited:

- `outputs/00-sdd-framework-research-design.md`
- `outputs/01-github-spec-kit.md`
- `outputs/02-fission-openspec.md`
- `outputs/03-open-gsd-gsd-core.md`
- `outputs/04-christopherkahler-paul.md`
- `outputs/05-bmad-method.md`
- `outputs/06-reusable-pattern-catalog.md`
- every file under `work/evidence/`
- every file under `work/inventory/`

The workspace root is intentionally not a Git repository, so a single workspace `WORK_STATE` cannot be manufactured. Fresh repository-by-repository preflight produced:

| Repository | Fresh UTC | Branch | HEAD | Worktree | Upstream |
|---|---|---|---|---|---|
| `bmad-method` | `2026-08-02T20:53:27.6317830Z` | `main` | `770d4259853b9600680745bb2c710bee82604cb4` | clean | `origin/main` |
| `christopherkahler-paul` | `2026-08-02T20:53:28.3541318Z` | `main` | `960b05c0b8e1f876f49674a700c9a087afebb8ac` | clean | `origin/main` |
| `fission-openspec` | `2026-08-02T20:53:29.1003194Z` | `main` | `45cca5db6137ed209117cc70510eb3e057fb981b` | clean | `origin/main` |
| `github-spec-kit` | `2026-08-02T20:53:29.8356707Z` | `main` | `d1e86f638277a99b82715c22c90558cd58d3cffd` | clean | `origin/main` |
| `open-gsd-gsd-core` | `2026-08-02T20:53:30.4986882Z` | `next` | `33985c11a9f0a27443f8b8fb114b2122d653cd78` | clean | `origin/next` |

Raw PR observations from preflight are state context only; they are not empirical-protocol evidence.

## Protocol gate summary

| Required gate | Observed package | Result |
|---|---|---|
| Every gear has smoke/reproduction evidence | 5,000 gear rows; 0 rows link to a smoke/reproduction artifact or carry command/case/exit fields | **FAIL** |
| Adoption candidates have 10 cases: 6 common + 4 specific | 15 catalog patterns and seven qualitative priorities; zero case matrices | **FAIL** |
| Every evaluated object has 1–10 scores | `S1/S2/S3` evidence-strength labels only; no numeric scorecard | **FAIL** |
| Any critical score `<=4` yields `REJECTED` | no critical dimensions or scores; rule absent | **FAIL / not computable** |
| Average `<8` yields `CANDIDATE` | no averages; rule absent | **FAIL / not computable** |
| Average `>=8` yields `CHOSEN` | no averages; rule absent | **FAIL / not computable** |
| `ORIGINAL`, `BASELINE`, `ABK` prototypes are scored separately | zero named prototype artifacts and zero prototype score rows | **FAIL** |
| Codex-local isolation is proven | one project run explicitly redirects config/data roots; no prototype isolation evidence | **FAIL / partial project evidence only** |

Exact negative searches over `outputs/`, `work/evidence/`, and `work/inventory/` found:

- exact protocol outcomes `CHOSEN|CANDIDATE|REJECTED`: **0**;
- exact prototype labels `ORIGINAL|BASELINE|ABK`: **0**;
- `10-case`, `6 common`, or `4 specific`: **0**;
- threshold expressions equivalent to critical `<=4`, average `<8`, or average `>=8`: **0**;
- prototype-named files in the audited paths: **0**.

The four occurrences of “score” are unrelated upstream prose: two dossier sentences explicitly say a metric is not a numeric score, and two Paul installation artifacts use PASS/GAP/DRIFT language. They are not adoption scorecards.

## P0-1 — The completed-status claim is stale under the accepted protocol

`outputs/00-sdd-framework-research-design.md:L3-L9` declares the milestone complete and says every approved research exit gate passed. That statement is accurate only for the older research design encoded in the same file. Its dynamic method is a generic five-step sequence — validation, local install, smoke, representative workflow, negative path — at `L87-L97`. Its acceptance criteria at `L158-L171` require inventory, source evidence, reproducible dynamic claims, reference closure, documentation drift, coverage, and DOCX fidelity, but contain none of the newly accepted empirical adoption rules.

The old scope explicitly excluded implementing or scaffolding the new framework at `outputs/00-sdd-framework-research-design.md:L199-L205`. That explains why the three prototypes do not exist, but it also means “completed” cannot be carried forward to the accepted protocol without qualification.

Required correction outside this read-only audit:

1. mark the original research milestone complete under **protocol v1/source-research**, not under the accepted empirical protocol;
2. create a new empirical-evaluation milestone with its own status and immutable protocol version;
3. do not label any adoption result final until every gate below is present and recomputed.

## P0-2 — No 10-case matrix or threshold-derived decision exists

The catalog defines 15 adoption patterns at `outputs/06-reusable-pattern-catalog.md:L39-L423`. It then lists seven qualitative implementation priorities at `L451-L461`. Neither structure is a 10-case evaluation matrix.

The existing “Minősítési rendszer” at `outputs/06-reusable-pattern-catalog.md:L15-L24` defines:

- `S1`: direct source fact;
- `S2`: triangulated source/test/runtime support;
- `S3`: analyst-designed abstraction;
- licensing/provenance labels.

Those labels are epistemic provenance classes. They do not measure empirical behavior on a 1–10 scale and cannot be averaged. Likewise, “low/medium/high adoption difficulty” in the priority table is not a score.

Missing for every adoption candidate:

- stable `CandidateId` and explicit candidate universe;
- ten stable case IDs;
- six common case definitions shared by every candidate;
- four candidate-specific case definitions;
- fixture/input and expected result for each case;
- exact command/environment/exit/result/evidence locator;
- critical/noncritical designation per score dimension;
- 1–10 dimension scores and calculation formula;
- independently recomputed critical minimum and arithmetic average;
- outcome calculated exactly as:
  - any critical score `<=4` → `REJECTED`;
  - otherwise average `<8` → `CANDIDATE`;
  - otherwise average `>=8` → `CHOSEN`.

Because none of these inputs exist, the present “best starting point” and “easiest to adopt” statements at `outputs/06-reusable-pattern-catalog.md:L3-L13` and `L451-L461` are not protocol-derived. They must remain explicitly S3 recommendations until empirical scoring exists.

Minimum evidence shape required:

```text
CandidateId, Variant, CaseId, CaseKind, Critical,
Fixture, ExactCommand, EnvironmentManifest, Expected,
Actual, ExitCode, EvidencePath, Dimension, Score1To10,
Reviewer, RunId, Pin
```

The evaluation must assert exactly ten unique `CaseId` values per candidate/variant, exactly six `common` and four `specific`, all scores integral or explicitly rounded under one documented rule, and outcome derived rather than hand-entered.

## P0-3 — `ORIGINAL`, `BASELINE`, and `ABK` prototypes are absent

No file or directory named for an `ORIGINAL`, `BASELINE`, or `ABK` prototype exists under the audited outputs/evidence/inventory scope. No prototype manifest, source hash, runnable entry point, case result, scorecard, or outcome is present.

This is not satisfied by upstream files containing the generic word “baseline.” Those are GSD test baselines and installer migrations, not the three required comparison prototypes. It is also not satisfied by the vendor-neutral S3 design in the catalog, because a design description is not a runnable variant.

The accepted protocol requires at least:

- three separately materialized prototype roots with immutable content manifests;
- a common interface/runner so identical common cases are comparable;
- 30 primary case rows: 3 variants × 10 cases;
- separate scorecards, critical minima, averages, and outcomes for each variant;
- provenance showing which behavior is original, which is the neutral baseline, and which is the ABK adaptation;
- no score inheritance from an upstream framework dossier.

Until those exist, the package cannot claim that ABK improves on either original or baseline behavior.

## P1-1 — Gear inventories provide semantic coverage, not per-gear reproduction evidence

The five gear inventories contain exactly **5,000** rows:

| Candidate | Gear rows | Unique `Evidence` values | Rows pointing under `work/evidence/` | Row-level smoke/reproduction fields |
|---|---:|---:|---:|---|
| GitHub Spec Kit | 525 | 1 | 0 | none |
| Fission OpenSpec | 1,036 | 1 | 0 | none |
| open-gsd/gsd-core | 2,725 | 1 | 0 | none |
| ChristopherKahler/Paul | 106 | 1 | 0 | none |
| BMAD-METHOD | 608 | 1 | 0 | none |
| **Total** | **5,000** | **5 dossier targets** | **0** | **none** |

Every CSV has the same schema at line 1:

```text
Path,Category,AnalysisStatus,Evidence,Notes
```

Representative line 2 in each of the following demonstrates the pattern:

- `work/inventory/github-spec-kit-gears.csv:L1-L2`
- `work/inventory/fission-openspec-gears.csv:L1-L2`
- `work/inventory/open-gsd-gsd-core-gears.csv:L1-L2`
- `work/inventory/christopherkahler-paul-gears.csv:L1-L2`
- `work/inventory/bmad-method-gears.csv:L1-L2`

Each row points only to its output dossier, and each Notes field asserts census/semantic traversal. There is no `SmokeApplicable`, `ReproductionKind`, `CaseId`, `Command`, `RunId`, `ExitCode`, `Expected`, `Actual`, or runtime evidence path. Text/config/document gears are not exempted with an explicit non-executable disposition; executable gears are not linked to the test/smoke that exercises them.

The existing ledgers prove useful things:

- file existence, hashes, and semantic/source classification;
- reference closure for several candidates;
- project-level tests or installer materialization.

They do not prove that every gear was smoked or reproduced.

Required correction: add a gear reproduction ledger keyed by `(Candidate, GearPath)`. Every one of the 5,000 rows must end in exactly one auditable disposition:

1. `runtime-smoked` with run/case/evidence link;
2. `behavior-reproduced` with exact fixture and expected/actual;
3. `covered-by-test` with test ID and execution evidence;
4. `static-only-not-executable` with a protocol-approved reason;
5. `blocked` with exact environmental blocker.

An aggregate test count cannot substitute for this mapping.

## P1-2 — Project-level runtime evidence is uneven and cannot backfill the gear ledger

| Candidate | Persisted dynamic evidence | What it proves | Protocol gap |
|---|---|---|---|
| GitHub Spec Kit | `work/evidence/github-spec-kit/targeted-pytest-20260802.md:L3-L25` | exact targeted command; 1,487 pass, 7 skip, exit 0 | no raw stdout; full suite explicitly inconclusive; no gear/case mapping |
| Fission OpenSpec | `work/evidence/fission-openspec/full-suite-20260802.md:L3-L23` and `L25-L55`; raw stdout log | isolated 119/119 suite, explicit roots and negative real-config assertion | no gear/case mapping; suite coverage is not per-gear traceability |
| open-gsd/gsd-core | `work/evidence/open-gsd-gsd-core/runtime-verification.json:L1-L25` plus command logs | six exact focused commands with exit/log metadata | JSON explicitly marks timeout and targeted-865 claims unverified at `L6-L13`; no gear/case mapping |
| ChristopherKahler/Paul | materialized `work/evidence/christopherkahler-paul/install-smoke/` tree and `references.csv`; dossier table at `outputs/04-christopherkahler-paul.md:L425-L446` | installed output and reference reconstruction are inspectable | no persisted command/environment/exit manifest; no row-level mapping |
| BMAD-METHOD | dossier commands/results only at `outputs/05-bmad-method.md:L362-L418` | reports local install and multiple test outcomes, including failures | `work/evidence/bmad-method/` contains zero files; no independent evidence artifact or gear/case mapping |

This evidence is not worthless; it is simply a different granularity. The accepted protocol needs a deterministic join from candidate/variant/case to run evidence, and from gear to one or more exercising cases.

## P1-3 — Codex-local isolation is only explicitly proven for one project run and for no prototype

The original research design requires writing tests/installations only in isolated local copies at `outputs/00-sdd-framework-research-design.md:L132-L140`. Runtime paths are generally located under this Codex workspace, which is positive. However, “the checkout lives under `work/runtime`” is not sufficient proof that tools did not read or mutate real user configuration, caches, credentials, or Codex state.

Evidence by candidate:

- **OpenSpec: PASS for the recorded full-suite run.** `work/evidence/fission-openspec/full-suite-20260802.md:L12-L23` redirects `APPDATA`, `LOCALAPPDATA`, `XDG_CONFIG_HOME`, and `XDG_DATA_HOME` under the workspace and asserts the real OpenSpec config remained absent.
- **Spec Kit: partial/unproven.** `targeted-pytest-20260802.md:L3-L16` records a disposable clone and local virtualenv but no `HOME`, `USERPROFILE`, AppData/XDG, cache, or pre/post real-user-state assertion.
- **GSD: partial/unproven.** `runtime-verification.json:L3-L5` records a workspace-local runtime repository, but not mutable environment roots or a negative real-user/Codex-state check.
- **Paul: partial/unproven.** The materialized install tree is workspace-local, and the dossier reports local/custom destinations at `outputs/04-christopherkahler-paul.md:L429-L444`; no persisted environment manifest or before/after real-user-state assertion exists.
- **BMAD: partial/unproven.** The dossier records a workspace-local detached clone and local `npm ci` at `outputs/05-bmad-method.md:L364-L372`; there is no `work/evidence/bmad-method` run artifact and no mutable-root isolation proof.

For the required prototypes, isolation status is **0/3**, because the prototypes and their runs do not exist.

Required prototype/run isolation evidence:

- per-run temporary `HOME`, `USERPROFILE`, `APPDATA`, `LOCALAPPDATA`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, tool caches, and any Codex-specific writable root;
- all paths resolved under a declared Codex-workspace run root;
- explicit telemetry/network policy;
- before/after manifest or hash/absence assertions for real user/Codex configuration targets;
- clean prototype source manifest after each run;
- cleanup/read-back result and retained raw stdout/stderr/exit metadata.

The audit does not assert that the four partial runs actually modified user state. It asserts that the package does not prove they could not.

## P2-1 — Candidate universe and scoring dimensions are undefined

The package uses “candidate” in at least three possible senses:

1. five upstream frameworks (`outputs/00-sdd-framework-research-design.md:L15-L21`);
2. fifteen catalog patterns (`outputs/06-reusable-pattern-catalog.md:L39-L423`);
3. seven prioritized implementation contracts (`outputs/06-reusable-pattern-catalog.md:L451-L461`).

The accepted protocol says adoption candidates receive ten cases and scores, but the package does not select one of these universes or assign stable IDs. It also does not define scoring dimensions, which dimensions are critical, how missing/blocked cases affect scores, whether averages are weighted, or how repeated runs are aggregated.

Required correction: publish a protocol manifest before running tests. It must freeze candidate IDs, variant IDs, ten case definitions, score dimensions, critical flags, weights, rounding, retry policy, and outcome formula. Results written before this manifest should not be retrofitted into a score without rerun.

## P2-2 — Evidence packaging is not uniform enough for mechanical protocol validation

The candidate evidence directories contain:

| Directory | File count | Character |
|---|---:|---|
| `work/evidence/github-spec-kit/` | 6 | ledgers, summaries, one targeted pytest Markdown |
| `work/evidence/fission-openspec/` | 8 | generator/verifier, ledgers, full-suite Markdown/raw log |
| `work/evidence/open-gsd-gsd-core/` | 18 | JSON manifests, stdout/stderr logs, large reference CSV |
| `work/evidence/christopherkahler-paul/` | 98 | materialized install tree plus reference CSV |
| `work/evidence/bmad-method/` | 0 | empty |

There is no common run schema, run ID, case ID, environment manifest, expected/actual object, or outcome computation. A human can read the dossiers; a verifier cannot mechanically answer “did every candidate run all ten cases under the same protocol?”

Required correction: normalize all empirical runs to one schema and add a validator that fails on missing candidate/variant/case combinations, duplicate latest results, missing raw evidence, score outside 1–10, invalid critical flags, hand-entered outcome mismatch, or a path outside the Codex-local run root.

## Acceptance gate for a future corrected package

The package can pass the accepted protocol only when all items below are true:

1. A versioned protocol manifest freezes candidates, three prototype variants, 6 common + 4 specific cases, dimensions, critical flags, scoring, aggregation, and outcome rules.
2. `ORIGINAL`, `BASELINE`, and `ABK` exist as separately hashed runnable prototypes.
3. Every candidate/variant has exactly ten primary case results and complete raw evidence.
4. Every adoption-relevant gear has an explicit case/test/reproduction mapping; every other gear has an approved static-only disposition.
5. Every score is 1–10 and evidence-backed.
6. Outcome is recomputed mechanically: critical `<=4` first, then average `<8`/`>=8`.
7. The three prototypes have independent scorecards and outcomes.
8. Every run proves Codex-local mutable-root isolation and negative real-user-state impact.
9. A single verifier reports zero missing rows, zero duplicate case keys, zero out-of-range scores, zero outcome mismatches, zero evidence-path escapes, and zero unclassified gears.
10. Only after that verifier passes may `outputs/06` use `REJECTED`, `CANDIDATE`, or `CHOSEN` as decision labels.

## Audit limitation

The applicable research procedure requested an independent background cross-check. Spawning that verifier was attempted, but the shared agent thread limit rejected the request. The audit therefore used a single reviewer with mechanical searches, CSV recomputation, repository-by-repository preflight, and direct evidence inspection. This limits independent-review redundancy; it does not change the observed absence of the required matrices, scores, prototypes, or isolation artifacts.

# Artifact DAG v2 Resolution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a separate, evidence-preserving v2 comparison scorecard that excludes the intentionally unscored control runner from adoption eligibility, normalizes the expected SPC-01 boundary rejection, and resolves eligible-branch hard gates through an explicit adjudication profile.

**Architecture:** Keep the v1 campaign, immutable 66-run snapshot, reviewer inputs, adjudications, and v1 `UNSCORED` scorecards unchanged. Add a v2 resolution profile and a standalone resolver that consumes the pinned v1 snapshot plus reviewer/adjudication artifacts and emits a strict two-eligible-branch comparison scorecard with a baseline-only control reference. Raw oracle statuses remain visible; v2 normalization is explicit and hash-bound.

**Tech Stack:** PowerShell 7, JSON Schema draft-07, existing Framework-Matrix run/evidence artifacts, Git.

## Global Constraints

- Do not modify or regenerate the v1 immutable run snapshot.
- Do not import, link, or execute AI Booster Kit source code.
- Preserve raw `UNSCORED` and `inconclusive` oracle statuses in v2 evidence.
- V2 `CHOSEN` means comparison result only; `ADOPTED` remains a separate human approval.
- Fail closed on profile hash mismatch, reviewer/adjudication mismatch, missing evidence, or unsupported normalization.

---

### Task 1: Define the v2 resolution contract

**Files:**
- Create: `benchmarks/schemas/comparison-scorecard-v2.schema.json`
- Create: `benchmarks/schemas/comparison-resolution-profile-v2.schema.json`
- Create: `benchmarks/campaigns/artifact-dag-core-v1/resolution-v2/profile.json`
- Create: `docs/superpowers/specs/2026-08-07-artifact-dag-v2-resolution-design.md`

**Interfaces:**
- Profile consumes the existing `campaign-run-index.json` path/hash and names `control` as `baseline_only`.
- Profile produces two eligible branches (`source_native`, `abk_native`), an explicit SPC-01 expected error normalization, and pass overrides for the two pending eligible-branch gates with branch evidence references.
- Scorecard schema consumes the resolver output and requires exactly two eligible branch scores plus one baseline reference.

- [x] Write the profile and schema with strict `additionalProperties: false` contracts.
- [x] Include profile IDs, snapshot path/hash, expected error code `DEPENDENCY_OUT_OF_ROOT`, required gate IDs, and v2 outcome formula.
- [x] Document why v1 remains immutable and why v2 normalization does not rewrite raw evidence.
- [x] Validate the profile and schema with `Test-Json` before implementing the resolver.

### Task 2: Implement the v2 comparison resolver

**Files:**
- Create: `benchmarks/scripts/resolve-v2-comparison.ps1`
- Create: `benchmarks/campaigns/artifact-dag-core-v1/resolution-v2/comparison-scorecard.json`

**Interfaces:**
- Parameters: `WorkspaceRoot`, `ProfilePath`, `ReviewerInputRoot`, `AdjudicationRoot`, `OutputPath`.
- Reads reviewer inputs, rubric, run index, raw run/oracle files, v2 profile, and v1 adjudications.
- Produces one schema-valid v2 comparison scorecard and refuses to overwrite an existing output.

- [x] Validate profile, reviewer schemas, adjudication schemas, and output-root containment.
- [x] Verify the profile snapshot hash equals the actual immutable run-index hash.
- [x] Validate two submitted reviews per eligible branch and exact review score references.
- [x] Resolve numeric disagreements with the existing adjudicator score and median-of-three calculation.
- [x] Normalize only SPC-01 eligible-branch `DEPENDENCY_OUT_OF_ROOT` from raw `inconclusive` to v2 assessment `passed` when the profile and evidence match.
- [x] Apply explicit gate adjudication overrides only for eligible branches and only with branch-local evidence IDs.
- [x] Emit control as `baseline_only` with raw `UNSCORED` statuses and exclude it from adoption branch scores.
- [x] Compute source-native and ABK-native weighted scores, critical minimums, outcome, and complete evidence ledger.

### Task 3: Add v2 integration tests

**Files:**
- Create: `benchmarks/tests/test-v2-comparison.ps1`

**Interfaces:**
- Test invokes the resolver into a unique temporary output path.
- Test asserts complete output, two eligible branch scores, baseline-only control, normalized SPC-01 assessment, all-pass eligible gates, and expected outcome.

- [x] Add a positive end-to-end resolver test against the pinned snapshot and current reviewer/adjudication artifacts.
- [x] Add a negative profile-hash mutation test that fails closed.
- [x] Add a negative unsupported-normalization test that fails closed.
- [x] Ensure temporary output and mutated profiles are cleaned up.

### Task 4: Integrate documentation and run the full verification gate

**Files:**
- Modify: `README.md`
- Modify: `benchmarks/README.md`

- [x] Document v1 archival `UNSCORED` status versus v2 comparison output.
- [x] Add the exact resolver and test commands.
- [x] Run the v2 test, the existing 15-test regression suite, JSON schema validation, diff review, and work-state preflight.

### Task 5: Publish the bounded v2 slice

- [ ] Create `dev-artifact-dag-v2-resolution` from current `main` only after a fresh preflight.
- [ ] Stage only the v2 plan, schema, profile, resolver, test, output, and documentation changes.
- [ ] Commit, push the feature branch, fast-forward merge to `main`, push `main`, and verify remote heads.

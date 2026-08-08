# ABK-native adoption decision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Record the approved `abk_native` adoption as a separate, hash-bound, machine-validatable decision without modifying the v1 or v2 scorecards.

**Architecture:** Add one strict JSON Schema and one immutable decision instance under the existing campaign. A read-only PowerShell validator rejects reparse-point traversal and resolves the scorecard only within the workspace, then verifies its schema, hash, completion state, `CHOSEN` outcome, and branch eligibility. A focused integration test uses the real scorecard plus temporary copies to prove the positive and fail-closed paths.

**Tech Stack:** PowerShell 7, JSON Schema draft-07, `Test-Json`, `Get-FileHash`, existing Framework-Matrix benchmark artifacts.

## Global Constraints

- Preserve the v1 immutable run snapshot, v1 scorecards, v2 profile, and v2 comparison scorecard byte-for-byte.
- The record is an explicit human decision; no script may create an `ADOPTED` decision automatically.
- Keep every file reference repository-relative and reject absolute paths, traversal, control characters, reparse points, and paths outside `WorkspaceRoot`.
- Use `ADOPTION_VALIDATION_FAILURE: <CODE>` errors; do not silently recover, overwrite artifacts, or log sensitive values.
- Add no dependency, network call, credential, generated file, or AI Booster Kit integration.
- Run focused tests against the real v2 scorecard; negative fixtures must be temporary and deleted in `finally`.
- Do not commit, push, merge, or change branches without separate explicit user approval.

---

### Task 1: Add the strict adoption-decision contract and approved record

**Files:**
- Create: `benchmarks/schemas/adoption-decision-v1.schema.json`
- Create: `benchmarks/campaigns/artifact-dag-core-v1/adoptions/abk-native-v2.json`

**Interfaces:**
- The record consumes `benchmarks/campaigns/artifact-dag-core-v1/resolution-v2/comparison-scorecard.json` as read-only evidence.
- The record exposes `decision_id`, `status`, `selected_branch`, `approval`, and `basis` for the validator.
- The current v2 scorecard SHA-256 is `0c8d2e3e3d075d6ecaca607c1d869550d14a7dc86c76362c472133bb01e76366`.

- [x] **Step 1: Create the schema before the record.**

Create a draft-07 schema with `$id` `urn:abk:schema:adoption-decision-v1:1.0.0`, root and nested `additionalProperties: false`, and exactly these root required properties:

```json
{
  "required": [
    "schema_version", "decision_id", "protocol_id", "status", "decided_at",
    "approval", "selected_branch", "basis", "rationale"
  ],
  "properties": {
    "$schema": { "type": "string", "minLength": 1 },
    "schema_version": { "const": "1.0.0" },
    "decision_id": { "const": "abk:adoption:artifact-dag-core-v2:abk-native" },
    "protocol_id": { "const": "abk:benchmark:pattern-adoption-v2" },
    "status": { "const": "ADOPTED" },
    "decided_at": { "type": "string", "format": "date-time" },
    "selected_branch": { "type": "string", "pattern": "^[a-z][a-z0-9_]*$" }
  }
}
```

Define `approval` as an object requiring `kind` and `reference`, with
`kind` fixed to `human_user_confirmation`. Define `basis` as an object
requiring `scorecard_relative_path`, `scorecard_sha256`, `comparison_id`,
`required_status`, and `required_outcome`; require a 64-character lowercase
SHA-256, `required_status` `complete`, and `required_outcome` `CHOSEN`.
Require a non-empty `rationale` of at most 2,000 characters.

- [x] **Step 2: Create the approved decision instance.**

Create the `adoptions` directory and write one UTF-8, no-BOM JSON document.
Use `([DateTime]::UtcNow).ToString('o')` when writing `decided_at`; retain the
generated timestamp as immutable record content. The other values are:

```json
{
  "$schema": "../../../schemas/adoption-decision-v1.schema.json",
  "schema_version": "1.0.0",
  "decision_id": "abk:adoption:artifact-dag-core-v2:abk-native",
  "protocol_id": "abk:benchmark:pattern-adoption-v2",
  "status": "ADOPTED",
  "approval": {
    "kind": "human_user_confirmation",
    "reference": "Codex task user approval"
  },
  "selected_branch": "abk_native",
  "basis": {
    "scorecard_relative_path": "benchmarks/campaigns/artifact-dag-core-v1/resolution-v2/comparison-scorecard.json",
    "scorecard_sha256": "0c8d2e3e3d075d6ecaca607c1d869550d14a7dc86c76362c472133bb01e76366",
    "comparison_id": "abk:comparison:artifact-dag-core-v2",
    "required_status": "complete",
    "required_outcome": "CHOSEN"
  },
  "rationale": "Explicit human user confirmation adopted abk_native after the completed v2 comparison returned CHOSEN."
}
```

The record must not duplicate evidence, scores, reviewer inputs, or adjudications.

- [x] **Step 3: Verify the new static contract.**

Run:

```powershell
Test-Json `
  -LiteralPath .\benchmarks\campaigns\artifact-dag-core-v1\adoptions\abk-native-v2.json `
  -SchemaFile .\benchmarks\schemas\adoption-decision-v1.schema.json
```

Expected: `True`. Also run `Get-FileHash` against the v2 scorecard and compare
its lowercase hash with `basis.scorecard_sha256`; expected exact equality.

### Task 2: Prove validation behavior before adding the validator

**Files:**
- Create: `benchmarks/tests/test-adoption-decision.ps1`
- Create: `benchmarks/scripts/validate-adoption-decision.ps1`

**Interfaces:**
- Validator parameters are mandatory `WorkspaceRoot` and `RecordPath` strings.
- Validator writes no files and returns `ADOPTION_DECISION_VALID: <decision-id>; branch=<branch>` only on success.
- Test invokes the validator in a child `pwsh.exe` process and considers all nonzero exits with the expected failure code a passing negative assertion.

- [x] **Step 1: Write the failing integration test.**

Follow `test-v2-comparison.ps1`: derive `$workspaceFull`, `$campaignRoot`,
`$recordPath`, `$schema`, `$validator`, a GUID `$token`, and a temporary
directory beneath `adoptions`. Define these helpers:

```powershell
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "TEST_FAILURE: $Message" }
}

function Invoke-Validator([string]$RecordPath) {
    $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $validator, '-WorkspaceRoot', $workspaceFull, '-RecordPath', $RecordPath)
    $output = @(& $pwshPath @arguments 2>&1)
    return [pscustomobject]@{ code = $LASTEXITCODE; output = $output }
}

function Assert-Rejected([object]$Result, [string]$Code, [string]$Message) {
    Assert-True ($Result.code -ne 0) $Message
    Assert-True ((@($Result.output) -join ' ') -match "ADOPTION_VALIDATION_FAILURE: $Code") $Message
}
```

First assert that the real record is schema-valid and that a positive
`Invoke-Validator` call contains `ADOPTION_DECISION_VALID`. This first run must
fail because the validator does not yet exist.

Inside `try`/`finally`, create a separate JSON copy for each negative scenario:

1. Set `basis.scorecard_sha256` to 64 zeroes; expect `SCORECARD_HASH_MISMATCH`.
2. Set `selected_branch` to `control`; expect `SELECTED_BRANCH_INELIGIBLE`.
3. Set `approval.kind` to `automated`; expect `RECORD_SCHEMA_INVALID`.
4. Set `basis.scorecard_relative_path` to `../README.md`; expect `PATH_INVALID`.
5. Set `basis.scorecard_relative_path` through a temporary junction; expect `PATH_REPARSE_POINT`.
6. Invoke the validator through a temporary record-path junction; expect `PATH_REPARSE_POINT`.

Delete temporary junctions non-recursively, then delete the temporary directory
recursively in `finally` only after resolving it under the campaign `adoptions`
directory.

- [x] **Step 2: Run the test and capture the intended RED result.**

Run:

```powershell
& .\benchmarks\tests\test-adoption-decision.ps1 `
  -WorkspaceRoot (Get-Location).Path
```

Expected: nonzero exit with `TEST_FAILURE: positive adoption decision validation failed`, caused by the missing validator. Do not weaken the positive assertion.

- [x] **Step 3: Implement the minimum read-only validator.**

Use the existing resolver's `Assert-UnderRoot`, `Assert-RelativePath`,
`Resolve-WorkspacePath`, `Get-Hash`, `Read-Json`, and `Test-Schema` patterns.
Wrap every intentional failure through this helper:

```powershell
function Fail([string]$Code, [string]$Detail) {
    throw "ADOPTION_VALIDATION_FAILURE: $Code; $Detail"
}
```

Implement this order exactly:

1. Normalize `WorkspaceRoot` and `RecordPath`; reject an outside record with `PATH_ESCAPE` and any reparse point in the workspace, record, schema, or scorecard paths with `PATH_REPARSE_POINT` before reading it.
2. Require the adoption schema and comparison-scorecard-v2 schema to exist with `INPUT_MISSING` when absent.
3. Run `Test-Json` on the adoption record; report `RECORD_SCHEMA_INVALID` on false or parser/schema errors.
4. Parse the record, validate the relative scorecard path, resolve it only beneath the workspace without reparse points, and require the file with `SCORECARD_MISSING`.
5. Recompute SHA-256 and compare it to `basis.scorecard_sha256`; report `SCORECARD_HASH_MISMATCH`.
6. Run `Test-Json` on the referenced scorecard using `comparison-scorecard-v2.schema.json`; report `SCORECARD_SCHEMA_INVALID`.
7. Require the scorecard `comparison_id`, `status`, and `outcome` to equal the record basis; report `COMPARISON_ID_MISMATCH`, `SCORECARD_STATUS_INVALID`, or `SCORECARD_OUTCOME_INVALID`.
8. Require `approval.kind` `human_user_confirmation` and membership of `selected_branch` in `eligible_branches`; report `APPROVAL_KIND_INVALID` or `SELECTED_BRANCH_INELIGIBLE`.
9. Emit the success line and exit normally. Do not write, normalize, repair, or regenerate any file.

- [x] **Step 4: Run the focused GREEN verification.**

Run the test from Step 2 again. Expected: `ADOPTION_DECISION_TESTS: 7/7 PASS`.
Then run the validator directly:

```powershell
& .\benchmarks\scripts\validate-adoption-decision.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -RecordPath .\benchmarks\campaigns\artifact-dag-core-v1\adoptions\abk-native-v2.json
```

Expected: `ADOPTION_DECISION_VALID: abk:adoption:artifact-dag-core-v2:abk-native; branch=abk_native`.

### Task 3: Document the decision boundary and complete the verification gate

**Files:**
- Modify: `README.md`
- Modify: `benchmarks/README.md`

**Interfaces:**
- Documentation links the separate adoption record and validator command.
- Documentation states that only the decision record is `ADOPTED`; the v2 scorecard remains `CHOSEN`.

- [x] **Step 1: Add the concise repository-level explanation.**

After the existing “V2 comparison resolution” section in `README.md`, add an
“ABK-native human adoption decision” subsection that says the record is
hash-bound to the v2 comparison scorecard, comes from explicit human approval,
and does not mutate v1/v2 evidence. Include the exact direct-validator command
from Task 2.

- [x] **Step 2: Add the benchmark-operation command and boundary.**

After the existing v2 resolver section in `benchmarks/README.md`, add the same
record path and command. State that a changed scorecard hash, incomplete or
non-`CHOSEN` comparison, non-human approval, reparse-point path, or non-eligible
branch is rejected.

- [x] **Step 3: Run all proportionate verification.**

Run, in order:

```powershell
& .\benchmarks\tests\test-adoption-decision.ps1 -WorkspaceRoot (Get-Location).Path
& .\benchmarks\tests\test-v2-comparison.ps1 -WorkspaceRoot (Get-Location).Path
Test-Json -LiteralPath .\benchmarks\campaigns\artifact-dag-core-v1\adoptions\abk-native-v2.json -SchemaFile .\benchmarks\schemas\adoption-decision-v1.schema.json
git diff --check
git diff --name-only
```

Expected: both test summaries pass, `Test-Json` returns `True`, `git diff --check`
has no output, and only these implementation files plus the already-approved
specification and this plan appear in the diff:

```text
benchmarks/schemas/adoption-decision-v1.schema.json
benchmarks/campaigns/artifact-dag-core-v1/adoptions/abk-native-v2.json
benchmarks/scripts/validate-adoption-decision.ps1
benchmarks/tests/test-adoption-decision.ps1
README.md
benchmarks/README.md
docs/superpowers/specs/2026-08-08-abk-native-adoption-decision-design.md
docs/superpowers/plans/2026-08-08-abk-native-adoption-decision.md
```

- [ ] **Step 4: Review the uncommitted diff and request commit authorization.**

Confirm that no v1 snapshot, v1 scorecard, v2 profile, v2 comparison scorecard,
or unrelated source changed. Present the changed-file list and verification
results to the user. Do not stage, commit, push, merge, or create a pull request
unless the user explicitly authorizes that separate action.

## Plan self-review

- **Spec coverage:** Task 1 implements the separate hash-bound record; Task 2 proves its fail-closed validation; Task 3 documents the human decision boundary and verifies the unchanged v2 basis.
- **Placeholder scan:** This plan contains no deferred implementation marker or implicit test step.
- **Interface consistency:** The record names `basis.scorecard_relative_path`, `basis.scorecard_sha256`, `basis.comparison_id`, `basis.required_status`, and `basis.required_outcome`; Task 2 validates exactly those names. The validator's success and failure strings are the strings asserted by the test.

## Execution handoff

After implementation approval, execute these tasks inline in this session using `superpowers:executing-plans`, unless the user explicitly asks for a delegated implementation workflow. Preserve the existing uncommitted specification and plan; request separate authorization before any Git publication action.

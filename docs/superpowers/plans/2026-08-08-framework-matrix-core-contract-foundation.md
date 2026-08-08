# Framework-Matrix Core-Contract Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the immutable 15-dimension core-contract, hash/index validation, durable work-unit receipts, and the minimal root agent gate that makes contract loading the mandatory step zero of every later Framework-Matrix work unit.

**Architecture:** Keep `CORE-CONTRACT.md` as the single human-readable contract. Bind it to a strict machine index by SHA-256 and exact dimension-ID parity, then bind every receipt to that version/hash. PowerShell validators are fail-closed, repository-root confined, reparse-point aware, dependency-free, and covered by real positive and negative integration tests.

**Tech Stack:** Windows, PowerShell 7, JSON Schema draft-07, `Test-Json`, `Get-FileHash`, JSON, Markdown, existing Framework-Matrix test conventions.

## Global Constraints

- Canonical design: `docs/superpowers/specs/2026-08-08-framework-matrix-full-scope-design.md`.
- Program roadmap: `docs/superpowers/plans/2026-08-08-framework-matrix-full-scope-rollout-roadmap.md`.
- Contract version for this slice is exactly `1.0.0`.
- Dimension IDs are exactly `CC-01` through `CC-15`; no alias or extension is allowed.
- The root `AGENTS.md` may contain only the gate procedure and canonical links; it must not duplicate the 15 contract descriptions.
- All script parameters are mandatory and explicit; add no default parameter values and no behavior-switching flag parameters.
- Use JSON Schema draft-07 with root and nested `additionalProperties: false`.
- Use lowercase 64-character SHA-256 values in JSON.
- Reject absolute paths, traversal, control characters, workspace escape, and reparse-point traversal before reading referenced files.
- Use `CORE_CONTRACT_VALIDATION_FAILURE: <CODE>; <detail>` for contract errors and `CONTRACT_RECEIPT_FAILURE: <CODE>; <detail>` for receipt errors.
- Error details may identify field names and repository-relative paths but may not expose secrets, credentials, PII, or full external content.
- Add no dependency, network call, global installation, credential, production resource, generated report, candidate registry, benchmark mutation, or AI Booster Kit integration.
- Preserve the approved design and all existing `outputs/`, `benchmarks/`, `sources/`, and `archive/` content.
- Do not stage, commit, push, merge, create a pull request, or change branches without separate explicit user authorization.

---

## File structure and ownership

| File | Responsibility |
|---|---|
| `contracts/CORE-CONTRACT.md` | Single human-readable definition of version `1.0.0`, `CC-01`–`CC-15`, step-zero invariants, and change control |
| `contracts/core-contract.schema.json` | Strict schema for the machine index |
| `contracts/core-contract-index.json` | Version/hash binding, exact dimension set, work-unit rules, and current dependency-registry paths |
| `schemas/contract-receipt.schema.json` | Strict durable receipt contract |
| `research/scripts/validate-core-contract.ps1` | Read-only contract/index/hash/dimension/path validator |
| `research/scripts/new-contract-receipt.ps1` | Single-purpose receipt creator; refuses overwrite |
| `research/scripts/validate-contract-receipt.ps1` | Read-only receipt/current-contract validator |
| `research/tests/test-core-contract.ps1` | Positive and negative contract integration tests |
| `research/tests/test-contract-receipt.ps1` | Positive and negative receipt integration tests |
| `research/tests/test-agent-core-contract-gate.ps1` | Root instruction and end-to-end step-zero gate test |
| `registry/contract-receipts/core-contract-foundation.json` | First durable receipt produced after the gate exists |
| `AGENTS.md` | Minimal repository-local agent entrypoint |
| `README.md` | One concise link and operator command; no duplicated contract text |

## Public interfaces

### Contract validator

```powershell
& .\research\scripts\validate-core-contract.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -IndexPath .\contracts\core-contract-index.json
```

Success: `CORE_CONTRACT_VALID: version=1.0.0; dimensions=15; dependencies=0`.

### Receipt creator

```powershell
& .\research\scripts\new-contract-receipt.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -WorkUnitId framework-matrix-core-contract-foundation `
  -WorkUnitType task `
  -DimensionIds CC-01,CC-02,CC-03,CC-04,CC-05,CC-06,CC-07,CC-08,CC-09,CC-10,CC-11,CC-12,CC-13,CC-14,CC-15 `
  -ExpectedEvidence contract-schema,hash-validation,receipt-validation,agent-gate-tests `
  -ReceiptPath .\registry\contract-receipts\core-contract-foundation.json
```

Success: `CONTRACT_RECEIPT_CREATED: framework-matrix-core-contract-foundation; dimensions=15`.

### Receipt validator

```powershell
& .\research\scripts\validate-contract-receipt.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -ReceiptPath .\registry\contract-receipts\core-contract-foundation.json
```

Success: `CONTRACT_RECEIPT_VALID: framework-matrix-core-contract-foundation; contract=1.0.0`.

---

### Task 1: Add the core-contract and prove fail-closed validation

**Files:**

- Create: `contracts/CORE-CONTRACT.md`
- Create: `contracts/core-contract.schema.json`
- Create: `contracts/core-contract-index.json`
- Create: `research/tests/test-core-contract.ps1`
- Create: `research/scripts/validate-core-contract.ps1`

**Interfaces:**

- Consumes: approved design section 5 and mandatory `WorkspaceRoot`.
- Produces: validated index fields `contract_version`, `contract_path`, `contract_sha256`, `dimensions`, `work_unit_types`, and `dependency_registry_paths`.
- Later tasks may trust the contract only after `CORE_CONTRACT_VALID`.

- [ ] **Step 1: Write the failing contract integration test.**

Follow the repository's standalone PowerShell test style. Use mandatory `WorkspaceRoot`, `$ErrorActionPreference = 'Stop'`, and child `pwsh.exe` validation:

```powershell
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "TEST_FAILURE: $Message" }
}

function Invoke-Validator([string]$WorkspacePath, [string]$IndexPath) {
    $arguments = @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-File', $validator,
        '-WorkspaceRoot', $WorkspacePath,
        '-IndexPath', $IndexPath
    )
    $output = @(& $pwshPath @arguments 2>&1)
    return [pscustomobject]@{ code = $LASTEXITCODE; output = $output }
}

function Assert-Rejected([object]$Result, [string]$Code, [string]$Message) {
    Assert-True ($Result.code -ne 0) $Message
    Assert-True ((@($Result.output) -join ' ') -match "CORE_CONTRACT_VALIDATION_FAILURE: $Code") $Message
}
```

Use separate copies beneath `contracts/test-core-contract-<guid>`. For mutations that need a different contract file, build a complete mini-workspace under that GUID directory with its own `contracts/CORE-CONTRACT.md`, schema, and index, then pass the mini-workspace path explicitly to `Invoke-Validator`. Assert:

1. Real index succeeds with the exact success line.
2. Zeroed `contract_sha256` fails `CONTRACT_HASH_MISMATCH`.
3. Swapping `CC-14` and `CC-15` while retaining all 15 unique values fails `DIMENSION_SET_INVALID`.
4. Mini-workspace Markdown with renamed `CC-15` and a recomputed matching hash fails `DOCUMENT_DIMENSION_MISMATCH`.
5. `contract_path` `../README.md` fails `PATH_INVALID`.
6. Extra root property fails `INDEX_SCHEMA_INVALID`.
7. Index or contract through a junction fails `PATH_REPARSE_POINT`.

Delete junctions non-recursively, verify targets remain, and delete only the resolved GUID directory under `contracts` in `finally`.

- [ ] **Step 2: Run the focused test and preserve RED.**

```powershell
& .\research\tests\test-core-contract.ps1 -WorkspaceRoot (Get-Location).Path
```

Expected: nonzero positive-path failure because the validator does not exist. Do not skip the positive assertion.

- [ ] **Step 3: Create canonical `CORE-CONTRACT.md`.**

Create version `1.0.0` with these exact IDs and names:

```markdown
| ID | Mandatory dimension |
|---|---|
| `CC-01` | Funkció és felhasználói cél |
| `CC-02` | Trigger, input, output és side effect |
| `CC-03` | Workflow, state és terminálási modell |
| `CC-04` | Agent, role, tool és authority modell |
| `CC-05` | Config, precedence és scope-kezelés |
| `CC-06` | Artefaktum-, adat-, memória- és reference-kezelés |
| `CC-07` | Install, initialize, update, migrate, recover és uninstall |
| `CC-08` | Hibakezelés, retry, rollback, idempotencia és megszakítás |
| `CC-09` | Security, trust boundary, secret-, path- és inputkezelés |
| `CC-10` | Observability, log, audit, provenance és evidence |
| `CC-11` | Teljesítmény, futási overhead, context- és tokenhasználat |
| `CC-12` | Windows-, PowerShell-, filesystem- és hostkompatibilitás |
| `CC-13` | Tesztelhetőség, karbantarthatóság és bővíthetőség |
| `CC-14` | Licenc, eredet, supply chain és dependency-kockázat |
| `CC-15` | Dokumentáció–kód–config–teszt konzisztencia |
```

Also state:

- every session/task/work part validates this contract at step zero;
- every work unit records at least one affected dimension and expected evidence;
- missing receipt, hash mismatch, unknown dimension, or unreviewed critical gap stops work;
- version `1.0.0` is immutable within the campaign;
- content change requires explicit human approval, a new version/hash, and impact analysis;
- reports and tasks link IDs instead of copying descriptions.

- [ ] **Step 4: Add the strict machine-index schema.**

Create draft-07 `contracts/core-contract.schema.json` with `$id` `urn:framework-matrix:schema:core-contract-index:1.0.0`, root and nested `additionalProperties: false`, and:

```json
{
  "required": [
    "$schema",
    "schema_version",
    "contract_version",
    "contract_path",
    "contract_sha256",
    "dimensions",
    "work_unit_types",
    "dependency_registry_paths"
  ]
}
```

Constrain `schema_version` and `contract_version` to `1.0.0`, `contract_path` to a non-empty string of at most 500 characters, hash to lowercase `[a-f0-9]{64}`, and dimensions to exactly 15 unique enum items `CC-01`–`CC-15`. Use draft-07 tuple validation for exactly three ordered `work_unit_types` objects: `session`, `task`, and `work_part`. Each requires `requires_receipt: true`, `minimum_dimension_count: 1`, `dimension_policy: affected_explicit`, `requires_dependency_check: true`, and the three exact script paths shown below. Constrain dependency registry paths to unique strings; the validator owns path-safety enforcement.

- [ ] **Step 5: Create the hash-bound index.**

Compute:

```powershell
(Get-FileHash -Algorithm SHA256 -LiteralPath .\contracts\CORE-CONTRACT.md).Hash.ToLowerInvariant()
```

Patch the exact returned value into `contract_sha256`. Use the dimensions in numeric order, an explicit empty `dependency_registry_paths` array, and:

```json
{
  "$schema": "core-contract.schema.json",
  "schema_version": "1.0.0",
  "contract_version": "1.0.0",
  "contract_path": "contracts/CORE-CONTRACT.md",
  "work_unit_types": [
    {
      "type": "session",
      "requires_receipt": true,
      "minimum_dimension_count": 1,
      "dimension_policy": "affected_explicit",
      "requires_dependency_check": true,
      "contract_validator_path": "research/scripts/validate-core-contract.ps1",
      "receipt_creator_path": "research/scripts/new-contract-receipt.ps1",
      "receipt_validator_path": "research/scripts/validate-contract-receipt.ps1"
    },
    {
      "type": "task",
      "requires_receipt": true,
      "minimum_dimension_count": 1,
      "dimension_policy": "affected_explicit",
      "requires_dependency_check": true,
      "contract_validator_path": "research/scripts/validate-core-contract.ps1",
      "receipt_creator_path": "research/scripts/new-contract-receipt.ps1",
      "receipt_validator_path": "research/scripts/validate-contract-receipt.ps1"
    },
    {
      "type": "work_part",
      "requires_receipt": true,
      "minimum_dimension_count": 1,
      "dimension_policy": "affected_explicit",
      "requires_dependency_check": true,
      "contract_validator_path": "research/scripts/validate-core-contract.ps1",
      "receipt_creator_path": "research/scripts/new-contract-receipt.ps1",
      "receipt_validator_path": "research/scripts/validate-contract-receipt.ps1"
    }
  ],
  "dependency_registry_paths": []
}
```

Write UTF-8 without BOM; no example hash may remain.

- [ ] **Step 6: Implement the minimum read-only validator.**

Use mandatory string parameters `WorkspaceRoot` and `IndexPath`. Use:

```powershell
function Fail([string]$Code, [string]$Detail) {
    throw "CORE_CONTRACT_VALIDATION_FAILURE: $Code; $Detail"
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}
```

Validate in order:

1. Workspace exists; normalize workspace/index.
2. Reject workspace escape and every existing reparse point before reading.
3. Require the schema or fail `INPUT_MISSING`.
4. `Test-Json` the index; false/parser/schema error becomes `INDEX_SCHEMA_INVALID`.
5. Validate `contract_path` against absolute prefix, traversal, empty/dot segment, control character, and shell metacharacter; then require the exact canonical value `contracts/CORE-CONTRACT.md`, otherwise `CONTRACT_PATH_INVALID`.
6. Resolve the canonical path beneath workspace, reject reparse points, and require the contract.
7. Recompute hash or fail `CONTRACT_HASH_MISMATCH`.
8. Require exact ordered `CC-01`–`CC-15` or fail `DIMENSION_SET_INVALID`.
9. Extract only Markdown table IDs matching ``| `CC-NN` |`` and require exact parity or fail `DOCUMENT_DIMENSION_MISMATCH`.
10. Require the exact ordered work-unit types and exact validator/creator paths; unsafe or drifted mapping fails `WORK_UNIT_RULE_INVALID`.
11. Validate each explicit dependency registry path; do not discover paths implicitly.
12. Emit exact success; write or repair nothing.

- [ ] **Step 7: Run GREEN contract verification.**

```powershell
& .\research\tests\test-core-contract.ps1 -WorkspaceRoot (Get-Location).Path
& .\research\scripts\validate-core-contract.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -IndexPath .\contracts\core-contract-index.json
```

Expected: `CORE_CONTRACT_TESTS: 7/7 PASS` and the exact validator success line.

- [ ] **Step 8: Review Task 1 without committing.**

Run `git diff --check`. Inspect only Task 1 paths plus approved spec/plan files. Confirm no benchmark, output, source snapshot, or previous evidence changed. Record the exact contract hash for Task 2. Do not stage or commit.

---

### Task 2: Add durable current-contract-bound receipts

**Files:**

- Create: `schemas/contract-receipt.schema.json`
- Create: `research/tests/test-contract-receipt.ps1`
- Create: `research/scripts/new-contract-receipt.ps1`
- Create: `research/scripts/validate-contract-receipt.ps1`
- Create during final positive run: `registry/contract-receipts/core-contract-foundation.json`

**Interfaces:**

- Consumes: Task 1 validator and machine index.
- Produces: immutable receipt fields `receipt_id`, `work_unit_id`, `work_unit_type`, `created_at`, `contract`, `dimensions`, `expected_evidence`, `dependencies_checked`, and `gate_status`.
- Creation refuses overwrite; validation proves current path/version/hash.

- [ ] **Step 1: Write the failing receipt integration test.**

Use a GUID directory beneath `registry/contract-receipts/test-receipt-<guid>` and child `pwsh.exe` calls. Assert:

1. Valid task receipt creation succeeds.
2. Created receipt validation succeeds.
3. `CC-16` fails `DIMENSION_UNKNOWN`.
4. An explicit empty-string dimension argument fails `DIMENSION_REQUIRED` without triggering an interactive mandatory-parameter prompt.
5. Absolute/traversal receipt path fails `PATH_INVALID`.
6. Second create at the same path fails `RECEIPT_EXISTS` and original hash is unchanged.
7. Stale contract hash fails `CONTRACT_HASH_MISMATCH`.
8. Extra property fails `RECEIPT_SCHEMA_INVALID`.
9. Receipt or parent through a junction fails `PATH_REPARSE_POINT`.

Delete junctions non-recursively and only the verified GUID directory recursively in `finally`.

- [ ] **Step 2: Run receipt test and preserve RED.**

```powershell
& .\research\tests\test-contract-receipt.ps1 -WorkspaceRoot (Get-Location).Path
```

Expected: nonzero positive-path failure because creator/validator do not exist.

- [ ] **Step 3: Add the strict receipt schema.**

Use draft-07, `$id` `urn:framework-matrix:schema:contract-receipt:1.0.0`, root/nested `additionalProperties: false`, and:

```json
{
  "required": [
    "$schema",
    "schema_version",
    "receipt_id",
    "work_unit_id",
    "work_unit_type",
    "created_at",
    "contract",
    "dimensions",
    "expected_evidence",
    "dependencies_checked",
    "gate_status"
  ],
  "properties": {
    "schema_version": { "const": "1.0.0" },
    "work_unit_type": { "enum": ["session", "task", "work_part"] },
    "dimensions": {
      "type": "array",
      "minItems": 1,
      "maxItems": 15,
      "uniqueItems": true,
      "items": { "enum": ["CC-01", "CC-02", "CC-03", "CC-04", "CC-05", "CC-06", "CC-07", "CC-08", "CC-09", "CC-10", "CC-11", "CC-12", "CC-13", "CC-14", "CC-15"] }
    },
    "dependencies_checked": { "const": true },
    "gate_status": { "const": "PASSED" }
  }
}
```

Require IDs `^[a-z0-9][a-z0-9._:-]{0,199}$`, date-time `created_at`, 1–50 unique non-empty expected-evidence strings, and nested `contract` with exactly `version`, `path`, and lowercase `sha256`.

The creator sets `$schema` exactly to `../../schemas/contract-receipt.schema.json`. The validator requires `receipt_id` to equal `work_unit_id`; mismatch fails `RECEIPT_ID_MISMATCH`.

- [ ] **Step 4: Implement the single-purpose receipt creator.**

Use only mandatory parameters:

```powershell
param(
    [Parameter(Mandatory = $true)][string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)][string]$WorkUnitId,
    [Parameter(Mandatory = $true)][ValidateSet('session', 'task', 'work_part')][string]$WorkUnitType,
    [Parameter(Mandatory = $true)][string[]]$DimensionIds,
    [Parameter(Mandatory = $true)][string[]]$ExpectedEvidence,
    [Parameter(Mandatory = $true)][string]$ReceiptPath
)
```

Implementation order:

1. Validate workspace, path confinement beneath `registry/contract-receipts`, and no reparse traversal.
2. Fail `RECEIPT_EXISTS` before writing if target exists.
3. Invoke the canonical contract validator; any failure stops creation.
4. Read validated index; reject unknown/duplicate dimensions.
5. Reject empty evidence and invalid work-unit ID.
6. Build ordered object with receipt ID equal to work-unit ID, UTC ISO-8601 time, current contract binding, sorted unique dimensions, unique evidence in supplied order, `dependencies_checked: true`, and `gate_status: PASSED`.
7. Serialize to a GUID temporary sibling, `Test-Json` it, then atomically move to the unused target.
8. On failure, remove only the known temporary sibling; never remove an existing receipt.
9. Emit exact success.

- [ ] **Step 5: Implement the read-only receipt validator.**

Use mandatory `WorkspaceRoot` and `ReceiptPath`. Reject outside/unsafe/missing/reparse paths before reading. Validate schema, then validate current contract. Require receipt contract version, path, and hash to equal current values and recomputed Markdown hash. Require every dimension in the index and gate fields true/`PASSED`.

Stable codes: `RECEIPT_SCHEMA_INVALID`, `RECEIPT_ID_MISMATCH`, `CONTRACT_VERSION_MISMATCH`, `CONTRACT_PATH_MISMATCH`, `CONTRACT_HASH_MISMATCH`, `DIMENSION_UNKNOWN`, and `GATE_STATUS_INVALID`. Emit only exact success.

- [ ] **Step 6: Run GREEN receipt verification.**

```powershell
& .\research\tests\test-contract-receipt.ps1 -WorkspaceRoot (Get-Location).Path
```

Expected: `CONTRACT_RECEIPT_TESTS: 9/9 PASS`.

- [ ] **Step 7: Create and validate the first durable receipt.**

Run the exact creator and validator commands from Public interfaces, then:

```powershell
Test-Json `
  -LiteralPath .\registry\contract-receipts\core-contract-foundation.json `
  -SchemaFile .\schemas\contract-receipt.schema.json
```

Expected: `True`. Record its SHA-256 and never edit it after validation.

- [ ] **Step 8: Review Task 2 without committing.**

Run `git diff --check`. Confirm no temporary fixture or junction remains and the durable receipt exists exactly once. No Task 1 artifact should change.

---

### Task 3: Activate the root agent gate

**Files:**

- Create: `AGENTS.md`
- Create: `research/tests/test-agent-core-contract-gate.ps1`
- Modify: `README.md`

**Interfaces:**

- Consumes: Task 1 validation and Task 2 receipts.
- Produces: minimal canonical agent instructions and one operator entrypoint.

- [ ] **Step 1: Write the failing agent-gate test.**

Require root `AGENTS.md`, then assert exact canonical contract/index paths, all three script paths, phrase `Step 0`, explicit validation-failure stop, dependency-registry inspection, and prohibition on copying dimension descriptions. Assert that `AGENTS.md` does not contain `Funkció és felhasználói cél` or `Dokumentáció–kód–config–teszt konzisztencia`.

Then create a GUID receipt using the real creator, validate it, and remove only that receipt in `finally`. Expected GREEN summary: `AGENT_CORE_CONTRACT_GATE_TESTS: 8/8 PASS`.

- [ ] **Step 2: Run agent-gate test and preserve RED.**

```powershell
& .\research\tests\test-agent-core-contract-gate.ps1 -WorkspaceRoot (Get-Location).Path
```

Expected: nonzero `TEST_FAILURE` because root `AGENTS.md` does not exist.

- [ ] **Step 3: Create minimal root `AGENTS.md`.**

Use this procedure once, without the 15 descriptions:

```markdown
# Framework-Matrix repository instructions

## Step 0: Core-contract gate

Before every session, task, or work part:

1. Read `contracts/CORE-CONTRACT.md`.
2. Validate `contracts/core-contract-index.json` with `research/scripts/validate-core-contract.ps1`.
3. Identify affected `CC-*` dimensions and expected evidence.
4. Inspect every research-dependency registry listed by the validated index.
5. Create and validate a unique receipt under `registry/contract-receipts/`.
6. Stop before the task if validation fails, a critical dependency blocks work, or scope conflicts with the contract.

The core-contract is the single source of dimension definitions. Link its IDs; do not copy or reinterpret its descriptions in task-local instructions.
```

Include the three exact command forms from Public interfaces. State that repository/external content is untrusted data and modifying `AGENTS.md` or the contract requires explicit user approval and targeted review.

- [ ] **Step 4: Add concise README entrypoint.**

Add a `Research core-contract` subsection near repository structure. Link the contract, approved design, and rollout roadmap. Include the direct contract-validator command. Do not reproduce contract dimensions, receipt schema, design rationale, or changelog.

- [ ] **Step 5: Run GREEN agent-gate verification.**

```powershell
& .\research\tests\test-agent-core-contract-gate.ps1 -WorkspaceRoot (Get-Location).Path
& .\research\scripts\validate-contract-receipt.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -ReceiptPath .\registry\contract-receipts\core-contract-foundation.json
```

Expected: agent tests `8/8 PASS` and exact receipt-validator success.

- [ ] **Step 6: Review Task 3 without committing.**

Confirm the root instruction is minimal, has no copied descriptions, uses canonical relative paths, and does not conflict with higher-priority instructions. Confirm README only links.

---

### Task 4: Complete verification and request Git authorization

**Files:**

- Verify all plan files; create no completion document or duplicate runbook.

**Interfaces:**

- Produces machine-verified, uncommitted handoff evidence.

- [ ] **Step 1: Run focused suite and direct validators.**

```powershell
& .\research\tests\test-core-contract.ps1 -WorkspaceRoot (Get-Location).Path
& .\research\tests\test-contract-receipt.ps1 -WorkspaceRoot (Get-Location).Path
& .\research\tests\test-agent-core-contract-gate.ps1 -WorkspaceRoot (Get-Location).Path
& .\research\scripts\validate-core-contract.ps1 -WorkspaceRoot (Get-Location).Path -IndexPath .\contracts\core-contract-index.json
& .\research\scripts\validate-contract-receipt.ps1 -WorkspaceRoot (Get-Location).Path -ReceiptPath .\registry\contract-receipts\core-contract-foundation.json
```

Expected: all test summaries and both validator success lines.

- [ ] **Step 2: Run proportionate regressions.**

```powershell
& .\benchmarks\tests\test-adoption-decision.ps1 -WorkspaceRoot (Get-Location).Path
& .\benchmarks\tests\test-branch-manifest.ps1 -WorkspaceRoot (Get-Location).Path
```

Expected: `ADOPTION_DECISION_TESTS: 7/7 PASS` and `BRANCH_MANIFEST_TESTS: 9/9 PASS`.

- [ ] **Step 3: Run scope and hygiene checks.**

```powershell
git diff --check
git status --short
git diff --name-only
Get-ChildItem -LiteralPath .\registry\contract-receipts -Force
```

Because new files remain untracked until separate staging authorization, also run `git diff --no-index --check -- NUL <path>` once for every new file. Exit code `1` means the file differs from the empty device and is expected; any emitted whitespace-error text is a failure.

Expected changed paths are limited to:

```text
AGENTS.md
README.md
contracts/CORE-CONTRACT.md
contracts/core-contract.schema.json
contracts/core-contract-index.json
schemas/contract-receipt.schema.json
research/scripts/validate-core-contract.ps1
research/scripts/new-contract-receipt.ps1
research/scripts/validate-contract-receipt.ps1
research/tests/test-core-contract.ps1
research/tests/test-contract-receipt.ps1
research/tests/test-agent-core-contract-gate.ps1
registry/contract-receipts/core-contract-foundation.json
docs/superpowers/specs/2026-08-08-framework-matrix-full-scope-design.md
docs/superpowers/plans/2026-08-08-framework-matrix-full-scope-rollout-roadmap.md
docs/superpowers/plans/2026-08-08-framework-matrix-core-contract-foundation.md
```

Receipt directory contains only the durable receipt, no test fixture or junction.

- [ ] **Step 4: Perform targeted security and final diff review.**

Verify path confinement before I/O, reparse rejection, no overwrite, read-only validators, no sensitive logging, no catch-all success conversion, no contract-description duplication, and no changes to benchmarks, scorecards, source snapshots, output dossiers, or adoption records.

- [ ] **Step 5: Present uncommitted handoff and request Git authorization.**

Report changed files, contract/receipt SHA-256, tests, current work-state, and residual risks. Do not stage or commit. If explicitly authorized later, propose one cohesive commit `feat: add Framework-Matrix core-contract gate`.

## Plan self-review

- **Spec coverage:** Task 1 covers canonical immutable contract, exact IDs, index, hash binding, path security, and drift detection. Task 2 covers durable current-contract receipts. Task 3 covers the explicitly approved root `AGENTS.md` gate and link-only documentation. Task 4 covers verification and Git approval boundaries.
- **Program boundary:** Only Rollout Slice 1 is implemented. Registry schemas, candidate inventory, evidence graph, reports, and campaigns are later plans.
- **Deferred-work scan:** Runtime-derived SHA-256 and UTC timestamps have explicit generation commands; no deferred implementation marker is present.
- **Interface consistency:** All scripts use the mandatory parameter names shown in Public interfaces. Tests assert the exact producer/validator strings and receipt fields.

## Execution handoff

After user approval, execute with `superpowers:subagent-driven-development` or inline with `superpowers:executing-plans`. Preserve the current uncommitted design and plans, and request separate authorization before Git publication.

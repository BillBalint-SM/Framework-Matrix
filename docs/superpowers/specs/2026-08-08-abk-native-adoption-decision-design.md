# ABK-native v2 adoption decision

## Decision

The explicit human approval of `abk_native` is recorded as a new, immutable
adoption decision. It is a separate artifact from every v1 and v2 scorecard.
The decision is valid only while it is hash-bound to the completed v2
comparison scorecard that produced `CHOSEN`.

## Goal

Add a machine-validatable record that states the human `ADOPTED` decision for
`abk_native`, preserves the evidence boundary, and fails closed if its v2
comparison basis changes or is not eligible.

## Non-goals

- Do not modify, regenerate, or relabel the immutable v1 run snapshot.
- Do not modify `resolution-v2/comparison-scorecard.json`, its profile, or its
  evidence ledger.
- Do not infer or create a human approval automatically.
- Do not copy raw run evidence into the adoption record.
- Do not add a dependency, network call, credential, or publication action.

## Artifact layout

```text
benchmarks/
  schemas/adoption-decision-v1.schema.json
  campaigns/artifact-dag-core-v1/
    adoptions/abk-native-v2.json
    resolution-v2/comparison-scorecard.json  <- read-only decision basis
  scripts/validate-adoption-decision.ps1
  tests/test-adoption-decision.ps1
```

The adoption record references the existing scorecard by repository-relative
path and SHA-256. The validator rejects reparse points along that path, resolves
it only beneath the supplied workspace root, recomputes the hash, and checks
the referenced scorecard before accepting the decision.

## Adoption record contract

`benchmarks/schemas/adoption-decision-v1.schema.json` is a draft-07 JSON
Schema with `additionalProperties: false` at the root and in every nested
object. It requires these fields:

| Field | Contract |
|---|---|
| `$schema` | Repository-relative path to the adoption-decision schema. |
| `schema_version` | Exact value `1.0.0`. |
| `decision_id` | Stable identifier for this decision. |
| `protocol_id` | Exact v2 protocol identifier `abk:benchmark:pattern-adoption-v2`. |
| `status` | Exact value `ADOPTED`. |
| `decided_at` | UTC RFC 3339 timestamp when this approved record is written. |
| `approval.kind` | Exact value `human_user_confirmation`. |
| `approval.reference` | Non-sensitive reference to the Codex-task user approval; it contains no person name or credential. |
| `selected_branch` | The approved branch, `abk_native` in this record. |
| `basis.scorecard_relative_path` | Path to the v2 comparison scorecard, relative to the workspace root. |
| `basis.scorecard_sha256` | SHA-256 of the exact scorecard file named by the path. |
| `basis.comparison_id` | Expected scorecard comparison identifier. |
| `basis.required_status` | Exact value `complete`. |
| `basis.required_outcome` | Exact value `CHOSEN`. |
| `rationale` | Concise explanation that the human approval selects `abk_native` after the v2 result. |

The committed record will use the stable identifier
`abk:adoption:artifact-dag-core-v2:abk-native`. It is a declaration of the
human decision, not a cryptographic signature or a claim that the scorecard
itself changed status.

## Validator behavior

`validate-adoption-decision.ps1` accepts explicit `WorkspaceRoot` and
`RecordPath` parameters. It performs no writes.

It must fail with a specific `ADOPTION_VALIDATION_FAILURE` message when any of
the following checks fails:

1. The record does not satisfy its JSON Schema.
2. `RecordPath` or `basis.scorecard_relative_path` resolves outside
   `WorkspaceRoot` or traverses a filesystem reparse point.
3. The scorecard is missing or its SHA-256 differs from
   `basis.scorecard_sha256`.
4. The scorecard `comparison_id`, `status`, or `outcome` differs from the
   corresponding expected basis values.
5. `selected_branch` is not one of the scorecard's `eligible_branches`.
6. `approval.kind` is not `human_user_confirmation`.

On success, it emits the decision ID and selected branch without changing any
artifact. The validator treats every record and referenced file as untrusted
input and performs containment and reparse-point checks before loading it.

## Test strategy

`test-adoption-decision.ps1` uses the committed record as its positive
integration fixture and temporary, isolated copies for negative checks. It
must verify all of these behaviors:

1. The committed record validates against the real v2 scorecard.
2. A changed scorecard hash is rejected.
3. A selected non-eligible branch, including `control`, is rejected.
4. A non-human approval kind is rejected by the schema or validator.
5. A path that escapes the workspace root is rejected.
6. A scorecard path that traverses a temporary junction is rejected.
7. A record path that traverses a temporary junction is rejected.
8. Temporary test files are removed even when a negative assertion passes.

The focused verification commands are:

```powershell
& .\benchmarks\scripts\validate-adoption-decision.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -RecordPath .\benchmarks\campaigns\artifact-dag-core-v1\adoptions\abk-native-v2.json

& .\benchmarks\tests\test-adoption-decision.ps1 `
  -WorkspaceRoot (Get-Location).Path

& .\benchmarks\tests\test-v2-comparison.ps1 `
  -WorkspaceRoot (Get-Location).Path
```

## Documentation and verification

`README.md` and `benchmarks/README.md` will describe the adoption record as a
separate human-decision artifact, give the validator command, and state that
the `CHOSEN` comparison output and all scorecards remain unchanged.

Before handoff, the implementation must pass the focused adoption test, the
existing v2 comparison test, JSON schema validation, and `git diff --check`.
The final review must confirm that only the six files named in this design are
changed and that no raw evidence, scorecard, profile, or v1 snapshot changed.

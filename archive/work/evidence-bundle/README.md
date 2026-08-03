# SDD framework research evidence bundle

This bundle is the machine-auditable companion to the five candidate dossiers, reusable-pattern catalog, and System Design DOCX.

## Pinned sources

| Candidate | Branch | Commit |
|---|---|---|
| `github/spec-kit` | `main` | `d1e86f638277a99b82715c22c90558cd58d3cffd` |
| `Fission-AI/OpenSpec` | `main` | `45cca5db6137ed209117cc70510eb3e057fb981b` |
| `open-gsd/gsd-core` | `next` | `33985c11a9f0a27443f8b8fb114b2122d653cd78` |
| `ChristopherKahler/paul` | `main` | `960b05c0b8e1f876f49674a700c9a087afebb8ac` |
| `bmad-code-org/BMAD-METHOD` | `main` | `770d4259853b9600680745bb2c710bee82604cb4` |

## Bundle contents

- `inventory/`: complete tracked-file and gear CSV ledgers with hashes and classifications.
- `evidence/`: per-candidate semantic/reference ledgers and retained runtime summaries/logs.
- `research/`: long-form source reports from the repository researchers.
- `reviews/`: independent adversarial reviews and synthesis re-review.
- `state/`: pinned work-state records.
- `scripts/`: coverage and citation validators used by the final QA.
- `contracts/`: the strict ABK-native component manifest and empirical scorecard schemas, plus the fixed benchmark protocol.
- `plans/`: the bounded adoption/refactor execution plan for the next milestone.
- `examples/`: one positive manifest, one deliberately unscored scorecard, and four negative mutation fixtures.
- `document-qa/`: DOCX structure, visual-review and accessibility audit summary.
- `final-qa.txt`: the aggregate final validation output.

The source repositories, dependency trees, disposable runtime clones, caches, binaries, and user configuration are intentionally excluded. The bundle contains no credentials or production data. One reference-ledger row preserves an upstream adversarial-test URL containing the intentionally synthetic `ghp_AAAA...` placeholder; it is fixture text, not a credential.

## Final aggregate contract

- Tracked paths: `5,027`
- Gear candidates: `5,000`
- Inventory bytes: `62,639,898`
- Hash errors: `0`
- Pending gear rows: `0`
- Gear rows without evidence: `0`
- Stored positive contract examples: `2/2` passed Draft 7 JSON Schema and semantic validation
- Mutation-negative contract fixtures: `4/4` rejected with the expected error
- Adversarial regression cases: `9/9` rejected with the expected fail-closed error
- Synthetic complete threshold cases: `REJECTED`, `CANDIDATE`, and `CHOSEN` each recomputed and accepted exactly once
- Executed three-branch empirical campaigns: `0`
- `CHOSEN`: `0`
- `ADOPTED`: `0`
- Gear disposition `static_only_not_executable`: `2,424`
- Gear disposition `blocked` pending row-level empirical evidence: `2,576`
- Unsupported row-level empirical claims: `0`

Candidate-specific confirmed broken references are preserved as findings; they are not converted into missing coverage. Generic unresolved reference classifications must be zero in each finalized reference ledger.

Source-native runtime evidence demonstrates what each specimen does; it does not prove that an ABK-native reimplementation is superior. `CHOSEN` requires the complete Codex-local control/source-native/ABK-native campaign, and `ADOPTED` additionally requires explicit integration approval.

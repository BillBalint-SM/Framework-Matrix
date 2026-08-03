# Evidence Contract Review — M1 Gate

Status: `DECISION_ACCEPTED_IMPLEMENTED`

Date: 2026-08-03

## Finding and resolution

The initial pending campaign and validator named `.txt` files while the
benchmark protocol and operator README named `.log` files:

| Evidence source | stdout | stderr |
|---|---|---|
| `benchmarks/campaigns/artifact-dag-core-v1/campaign.json` | `stdout.txt` | `stderr.txt` |
| `benchmarks/scripts/validate-benchmark-campaign.ps1` | `stdout.txt` | `stderr.txt` |
| `outputs/08-empirical-benchmark-protocol.md` | `stdout.log` | `stderr.log` |
| `benchmarks/README.md` | `stdout.log` | `stderr.log` |

This mismatch is now resolved. The canonical campaign contract is the exact
ordered set `run.json`, `stdout.log`, `stderr.log`, `tool-events.jsonl`,
`output-inventory.json`, and `oracle-result.json`. Legacy `.txt` names are not
accepted as a substitute.

## Implemented resolution

`stdout.log` and `stderr.log` are the canonical pair. The campaign JSON, JSON
Schema, validator, and regression tests enforce the exact six-file set. No
compatibility alias is part of the accepted manifest.

The pending campaign should be updated only in the same change as the JSON
Schema, validator, and regression tests. That change must create a new campaign
contract hash and invalidate any branch-manifest hash copied from the current
pending campaign.

## Evidence files beyond stdout/stderr

`tool-events.jsonl` and `oracle-result.json` are required by the accepted
protocol, campaign declaration, and branch decision note. They are required for
each runner-produced run evidence and cannot be omitted from a successful run.

## Verification

- validator: `BENCHMARK_VALID`, 10 cases, 30 primary cells, 66 expected raw
  runs;
- regression suite: 9/9 PASS, including legacy `.txt` fail-closed behavior;
- campaign: `benchmark_pending` / `UNSCORED`, zero completed runs;
- no benchmark run, commit, or push was performed.

The subsequent runner slice must consume this exact contract and must not start
the 66-run campaign until its isolation and executable-digest gates pass.

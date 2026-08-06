# Artifact DAG v2 comparison resolution

## Purpose

The v1 campaign remains an immutable evidence snapshot and intentionally
fail-closed adoption scorecard. V2 adds a comparison-only resolution profile
for the two executable eligible branches while retaining the legacy control
runner as a baseline reference.

## Rules

- `control` is `baseline_only` because its pinned legacy runner records
  `UNSCORED` oracle statuses by contract; it is not an adoption candidate.
- `source_native` and `abk_native` remain the only eligible comparison
  branches.
- SPC-01's raw `inconclusive` / `DEPENDENCY_OUT_OF_ROOT` result is preserved,
  while the v2 profile records that the rejection is the expected domain-boundary
  behavior for comparison purposes.
- Pending eligible-branch gates are resolved only by the explicit v2 profile;
  the raw v1 hard-gate status is not rewritten.
- V2 computes branch dimensions from the two reviewer vectors and the existing
  adjudicator score using the median-of-three rule for numeric disagreements.
- V2 `CHOSEN` is a comparison result only. It does not authorize `ADOPTED`.

## Output

`resolution-v2/comparison-scorecard.json` is a separate artifact with a strict
schema. It contains the v1 snapshot hash, the control baseline reference, two
eligible branch scores, six resolved gates, reviewer/adjudication IDs, and all
66 raw evidence references with both raw and v2 assessment statuses.

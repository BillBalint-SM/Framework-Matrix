# Reviewer adjudication contract design

## Goal

Complete the frozen reviewer protocol's disagreement path without inventing
scores or changing the immutable campaign evidence. The current scorecard
validator must remain fail-closed when two reviewers disagree by more than one
point, while accepting a separately pinned third-adjudicator record when the
dispute is numeric.

## Contract

The campaign owns an `adjudications/` surface. Each submitted artifact is
branch-scoped and references exactly two submitted reviewer IDs, the same
campaign/rubric/scorecard IDs, and the hash of the immutable
`campaign-run-index.json`. Each decision names one disputed case/dimension,
the two raw reviewer scores, the adjudicator's third score, the dispute type,
the evidence IDs, and a rationale.

Numeric disputes resolve to the median of the three scores. Authority,
ownership, provenance, or undocumented-effect disputes resolve to
`inconclusive`; they never promote a scorecard. Adjudication can neither add
evidence nor alter fixtures, manifests, runs, hard gates, or lifecycle state.

## Validator behavior

The existing reviewer scorecard validator reads only safe JSON artifacts under
the canonical adjudication root. It rejects unknown review IDs, branch or
snapshot mismatches, score mismatches, missing disputed dimensions, duplicate
decisions, invalid evidence references, and incomplete decisions. A submitted
review pair with no over-one disagreement requires no adjudication. A pair
with an over-one disagreement requires exactly one matching decision per
disputed dimension. The branch score uses the two-review mean for agreeing
dimensions and the adjudicated median for disputed numeric dimensions. Any
unresolved or inconclusive dispute leaves the campaign `UNSCORED`.

## Verification

Tests cover schema rejection, path/hash/reference rejection, the existing
planned-review fail-closed state, numeric median resolution, and
authority-dispute inconclusive behavior. The canonical `adjudications/`
directory contains no fabricated reviewer or adjudicator decisions.

# Reviewer adjudications

This directory is intentionally empty of decision artifacts. A branch needs
an adjudication only when its two submitted reviewer inputs differ by more
than one point for a case/dimension.

The accepted file shape is defined by
`benchmarks/schemas/reviewer-adjudication.schema.json`. A submitted artifact
must reference the two reviewer IDs, the pinned `campaign-run-index.json`
hash, and only evidence IDs from the matching branch. Numeric disputes use the
median of the two reviewer scores and the adjudicator score. Authority,
ownership, provenance, and undocumented-effect disputes remain
`inconclusive` and cannot promote a scorecard.

The validator never invents a third score, never adds evidence, and never
overwrites an existing scorecard.

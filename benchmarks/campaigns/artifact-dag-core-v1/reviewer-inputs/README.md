# Reviewer inputs

Each branch accepts exactly two independent reviewer documents named
`reviewer-01.json` and `reviewer-02.json`. The files must satisfy
`benchmarks/schemas/reviewer-input.schema.json`, point to the pinned
`campaign-run-index.json` hash, and cite only evidence from the matching branch.

The canonical campaign now contains one submitted input from each of the two
independent reviewer keys for every branch. These are evidence-backed inputs,
not runner-generated defaults. The validator still fails closed when reviewer
vectors require an adjudication or when the evidence leaves a dispute
inconclusive.

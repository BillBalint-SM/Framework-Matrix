# Reviewer inputs

Each branch accepts exactly two independent reviewer documents named
`reviewer-01.json` and `reviewer-02.json`. The files must satisfy
`benchmarks/schemas/reviewer-input.schema.json`, point to the pinned
`campaign-run-index.json` hash, and cite only evidence from the matching branch.

The current templates are intentionally absent: no reviewer score is invented
by the campaign runner. Until two submitted reviews and any required
adjudication are present, generated branch scorecards remain `UNSCORED`.

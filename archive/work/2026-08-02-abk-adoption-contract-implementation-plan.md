# ABK Adoption Contract Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan inline. This projectless workspace has no Git repository; do not create commits.

**Goal:** Create strict, machine-validatable ABK-native adoption manifests, an empirical benchmark protocol, an adoption scorecard, and executable positive/negative validation evidence.

**Architecture:** Two JSON Schema Draft-07 contracts use closed objects (`additionalProperties: false`) and discriminated branches. A dependency-free PowerShell validator uses `Test-Json`, then enforces cross-field invariants that JSON Schema cannot express cleanly, such as evidence references, score weights, recomputed totals, and permission/content-hash coherence.

**Tech Stack:** JSON Schema Draft-07, JSON, Markdown, PowerShell 7.

## Global Constraints

- Create only `outputs/07-*`, `outputs/08-*`, `outputs/09-*`, `work/evidence-bundle/examples/**`, `work/scripts/validate-abk-adoption-contracts.ps1`, and this accepted-plan record.
- The core schema is ABK-native and contains no vendor extension block or free-form `x-*` keys.
- Both schemas fail closed on unknown properties and unknown enum values.
- The benchmark has exactly ten cases: six common and four specific; every matrix cell has exactly three repeats.
- Validation must exercise real positive manifests and targeted negative fixtures without global dependencies.

---

### Task 1: Strict core manifest schema

**Files:**
- Create: `outputs/07-capability-component-pattern-adoption.schema.json`

**Interfaces:**
- Consumes: approved Global–Project–Session–Local model and patterns 1–15 from `outputs/06-reusable-pattern-catalog.md`.
- Produces: Draft-07 schema with `kind=capability|component|pattern_adoption` discriminated branch and shared autonomy, side-effect, lifecycle, provenance, permission, evidence, scores, and comparison contracts.

- [ ] Define closed reusable definitions for IDs, timestamps, hashes, evidence references, scores, permissions, and transitions.
- [ ] Define the three mutually exclusive kind payloads.
- [ ] Require every adoption decision to have evidence and comparison records.
- [ ] Parse the schema and validate it with `Test-Json` against Draft-07 behavior.

### Task 2: Empirical benchmark protocol

**Files:**
- Create: `outputs/08-empirical-benchmark-protocol.md`

**Interfaces:**
- Consumes: core manifest and scorecard field names.
- Produces: immutable ten-case protocol, two-agent/two-mode/three-repeat matrix, run envelope, metrics, invalidation rules, and reporting contract.

- [ ] Specify six common cases and four specific cases with fixtures, expected terminals, and hard failure conditions.
- [ ] Fix the matrix cardinality to `10 × 2 agents × 2 modes × 3 repeats = 120` runs.
- [ ] Define reproducibility, isolation, scoring, failure, timeout, and evidence rules.

### Task 3: Strict adoption scorecard schema

**Files:**
- Create: `outputs/09-adoption-scorecard.schema.json`

**Interfaces:**
- Consumes: manifest IDs/evidence IDs and benchmark run IDs.
- Produces: closed gate, fixed-dimension score, risk adjustment, comparison, recommendation, and decision record.

- [ ] Define mandatory hard gates and eight fixed scoring dimensions.
- [ ] Define weighted and risk-adjusted totals and decision values.
- [ ] Require benchmark aggregation and traceable evidence IDs.

### Task 4: Fixtures and local validator

**Files:**
- Create: `work/evidence-bundle/examples/capability-component-pattern-adoption.example.json`
- Create: `work/evidence-bundle/examples/adoption-scorecard.example.json`
- Create: `work/evidence-bundle/examples/fixtures/invalid-core-unknown-extension.json`
- Create: `work/evidence-bundle/examples/fixtures/invalid-core-permission-hash.json`
- Create: `work/evidence-bundle/examples/fixtures/invalid-scorecard-weight.json`
- Create: `work/evidence-bundle/examples/fixtures/invalid-scorecard-evidence-reference.json`
- Create: `work/scripts/validate-abk-adoption-contracts.ps1`

**Interfaces:**
- Consumes: both schema paths and all fixture paths.
- Produces: exit 0 only when schemas parse, positives pass, each negative fails for its named reason, and all semantic invariants hold.

- [ ] Write positive manifests with real provenance to the five pinned research outputs.
- [ ] Write negative fixtures targeting unknown extension fields, stale permission hashes, non-unit weights, and missing evidence references.
- [ ] Implement schema validation plus cross-field checks with explicit error messages.
- [ ] Run `pwsh -NoProfile -File work/scripts/validate-abk-adoption-contracts.ps1` and require all checks to pass.

### Task 5: Final scope and contract audit

- [ ] Parse every JSON file with `ConvertFrom-Json`.
- [ ] Confirm exact benchmark counts and three-repeat rule from the protocol.
- [ ] Confirm both schemas are closed and contain no extension block.
- [ ] Confirm only authorized paths changed and report the projectless preflight limitation.

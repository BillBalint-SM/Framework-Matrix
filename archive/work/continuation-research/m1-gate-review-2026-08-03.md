# M1 gate review — 2026-08-03

Review ID: `abk:evidence-review:m1-control-artifact-dag-core-v1-2026-08-03`

Status: `NEEDS_WORK` / `CAMPAIGN_NOT_READY`

Reviewer: `evidence_contract_reviewer` (cross-agent, read-only review)

This review re-reads the frozen campaign, the concrete `control` manifest, the
control runner, and the isolation/network audit records from the canonical
Framework-Matrix checkout. It is an independent technical review of the local
artifacts, not product-owner approval and not campaign-start authorization.

## Evidence basis

| Artifact | Result | SHA-256 |
|---|---|---|
| `benchmarks/campaigns/artifact-dag-core-v1/campaign.json` | schema-valid; 10 cases, 30 primary cells, 66 expected raw runs | `471b4f31608781205ce71d497add92d15659003a2a5852f1cc7fb59330b320d3` |
| `benchmarks/campaigns/artifact-dag-core-v1/branches/control/manifest.json` | schema-valid; concrete control boundary | `5c041ba5fe1621cf72ac2091cef7358875789c38cbc1115fe6b1d15891c9a235` |
| `benchmarks/runners/control/run.ps1` | PowerShell 7 entrypoint pinned by manifest | `a0e4929d124c831035546c8c65a1de7618da789d05a4bb24b645285421e859c1` |
| `benchmarks/audits/control-isolation-audit-2026-08-03.json` | environment/process/repository/Git checks PASS; network observation INCONCLUSIVE | `059408e2f871b914cddfdfd5368185fb653a31b38e6e1f91bebf5215797976c2` |
| `benchmarks/audits/network-policy-audit-2026-08-03.json` | non-elevated preflight BLOCKED; cleanup PASS | `c4aea52b16239a0e7c6b5273f044fc1bb380c185a34da9e9b587c6db0c9d35c7` |
| `benchmarks/audits/network-policy-audit-2026-08-03-elevated.json` | temporary outbound deny PASS; zero runner sockets; cleanup/read-back PASS | `8e77142729f79d89cbdef050cb5cd16e4a5bf1756b3ac21b1f003033687dbb51` |

All listed audit records passed their respective JSON Schema checks. The
current repository was `main` at `2c54e2953549d0d361a6c212a7345a4d2775b87a`,
with a clean worktree and `origin/main` parity at review time.
Historical WORK_STATE snippets embedded in older decision notes were treated as
non-authoritative; the preflight above is the current state source.

## Six acceptance gates

| Gate | Status | Finding |
|---|---|---|
| Problem | `PASS_WITH_OPEN_APPROVAL` | Primary segment, task, and paired JSON/Markdown read surface are documented; product-owner acceptance and the five-session feedback gate are still open. |
| Contract | `PASS` | Campaign validator and contract/runner/manifest negative-path suites pass; the pending campaign remains structurally valid. |
| Runner | `BLOCKED` | Only `control` has a concrete manifest and executable. `source_native` and `abk_native` manifests/entrypoints are absent, so no three-branch campaign can start. |
| Isolation | `CONTROL_PROOF_PASS` | Control environment/process/repository/Git checks pass; the elevated Windows Firewall record closes the OS-level deny proof for this control snapshot. This is not evidence from campaign runs. |
| Evidence | `BLOCKED` | `completed_primary_cells=0`, `completed_raw_runs=0`, and `run_evidence_ids=[]`; no per-run evidence or scorecards exist. |
| Decision | `BLOCKED` | No three-branch scorecards, recomputable outcome, adjudication, or human decision exists. |

## Allowed next step

Keep the campaign at `benchmark_pending` / `UNSCORED`. Before any raw run,
record product-owner decisions for the primary segment/read surface, the
runner and reviewer freeze, and the disposition of `source_native` and
`abk_native`. Only then may the missing branch manifests and their bounded
entrypoints be added and the 66-run campaign be considered for authorization.

No campaign run, score promotion, `CHOSEN`, or `ADOPTED` decision is implied by
this review.

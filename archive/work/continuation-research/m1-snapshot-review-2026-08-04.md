# M1 branch snapshot review — 2026-08-04

Review ID: `abk:snapshot-review:m1-artifact-dag-core-v1-2026-08-04`

Status: `PARTIAL` / `CAMPAIGN_NOT_READY`

This review records the two immutable branch-snapshot descriptors created for
the next M1 gate. The descriptors are metadata-only: no AI Booster Kit source,
runtime, dependency tree, or Git remote was copied or linked into
Framework-Matrix.

## Descriptor evidence

| Descriptor | Status | SHA-256 |
|---|---|---|
| `benchmarks/schemas/branch-snapshot.schema.json` | schema source | `79338654e999a04a699a2a91eb96c6891109ef2806f6beb7bb3a18986c384ae7` |
| `benchmarks/schemas/branch-manifest.schema.json` | schema source for all three branch manifests | `bdf1d27dce3a8ddef016e0d3d4841ed859360a0b48e319764ffcf76cf59f498b` |
| `benchmarks/snapshots/source-native-openspec-artifact-graph.json` | schema-valid; `READY_FOR_ENTRYPOINT`; `NOT_EXECUTED` | `187f05196ea13a2acb16e79fc58df3f366b256f53afaa495e59457a1cd32cefa` |
| `benchmarks/snapshots/abk-native-ai-booster-kit-feature.json` | schema-valid; `NOT_COMPARABLE`; `NOT_EXECUTED` | `a19b1c30dee281dc5a8c2c27cb94d7d8ccf4c50aca855c140cf5677d1d875997` |
| `branches/source_native/manifest.json` | schema-valid; `NOT_COMPARABLE`; `NOT_EXECUTED` | entrypoint `d0384863ddfe051f6fd817550048a2403011d6e498f4149b9bee21bb1611f3c3` |
| `branches/abk_native/manifest.json` | schema-valid; `NOT_COMPARABLE`; `NOT_EXECUTED` | entrypoint `c3e4daf7cc981a08b1805783394c19c0443789486e8e150c9049ab0f5d56658e` |

Manifest SHA-256 pins: `source_native`
`0493c1f974ffda595446d1d831ccba5d5b7587416c9f41be09f09b3ef07723da`;
`abk_native`
`2557f41ad900709842d780d0fe3aa97e6bc2a15a0e8ec683554aa2c87167e7c0`.

## Findings

### `source_native`

The existing `sources/fission-openspec` snapshot is pinned to upstream commit
`45cca5db6137ed209117cc70510eb3e057fb981b`. Nine artifact-graph source/spec
files have a deterministic content inventory with hash
`d391aa5ed6d7869e0a92abbd8b020f6c3861b40f20f68b44a9cf64f7da3928fe`.

This is sufficient input provenance for a bounded clean-room entrypoint. The
new entrypoint validates the descriptor and emits typed `REJECTED` /
`NOT_COMPARABLE` evidence because no approved upstream runtime or package is
present; the upstream runtime must not be installed or executed.

### `abk_native`

The separate AI Booster Kit checkout was read at local
`feature-current-state-sync` HEAD
`20ed6dc401b31c3075c1c16933c404537fe075f2` (tree
`2e5c6126d0eb8b5c17b184c5ea1d8892d89464db`). The selected readiness,
context, and orchestration files have a Git blob inventory hash
`fdf79acee6460ca5f5c61f828459a533183f5ecac9f365fa6c86290743676d5d`.

The inspected revision does not expose an Artifact DAG + root-provenance
implementation matching this campaign. Its worktree has modified `.ua/` and
`graphify-out/` generated state, which is explicitly excluded. Therefore it is
not an `abk_native` executable snapshot. The new local fail-closed entrypoint
records `NOT_COMPARABLE` without reading or linking the external checkout; a
future approved immutable ABK-native Artifact DAG snapshot and bounded
implementation are still required for comparison.

## Gate consequence

The campaign remains `benchmark_pending` / `UNSCORED`. Branch manifests and
fail-closed entrypoints now exist, but no raw runs, scorecards, or outcome
promotion are created by this slice. `source_native` and `abk_native` both
remain `NOT_COMPARABLE` / `NOT_EXECUTED` until an approved executable
comparison boundary exists.

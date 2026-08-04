# Source-native runner result

- terminal_state: FAILED
- campaign_id: abk:benchmark-campaign:artifact-dag-core-v1
- case_id: SPC-02-failure-path
- branch: source_native
- repeat: 1

- result: NOT_COMPARABLE or FAILED; no upstream OpenSpec runtime or package was executed.
- next_action: inspect typed evidence and keep the branch out of scoring until the boundary is resolved.

- readiness/provenance: emitted when graph validation reaches a comparable state.

- authority: fixture, campaign, schema, and pinned source snapshot reads only; run-root writes only.
- side_effects: network, credentials, production resources, external writes, Git mutation, and child processes denied.

- error: UNKNOWN_ARTIFACT_REFERENCE (project.artifacts.depends_on)

- links: run.json, oracle-result.json, stdout.log, stderr.log, tool-events.jsonl, output-inventory.json
- link: provenance.json
- link: operator.md
# Source-native runner result

- terminal_state: STOPPED
- campaign_id: abk:benchmark-campaign:artifact-dag-core-v1
- case_id: COM-06-stop-interrupt
- branch: source_native
- repeat: 3

- result: STOPPED; the declared interrupt was persisted without ambiguous success.
- next_action: inspect typed evidence and keep the branch out of scoring until the boundary is resolved.

- readiness/provenance: emitted when graph validation reaches a comparable state.

- authority: fixture, campaign, schema, and pinned source snapshot reads only; run-root writes only.
- side_effects: network, credentials, production resources, external writes, Git mutation, and child processes denied.

- error: INTERRUPTED (project.interrupt_after)

- links: run.json, oracle-result.json, stdout.log, stderr.log, tool-events.jsonl, output-inventory.json
- link: readiness.json
- link: provenance.json
- link: operator.md
# ABK-native runner result

- terminal_state: RECOVERED
- campaign_id: abk:benchmark-campaign:artifact-dag-core-v1
- case_id: SPC-03-recovery-rollback
- branch: abk_native
- repeat: 3

- result: typed terminal evidence preserved; external AI Booster Kit project was not executed or linked.
- implementation: framework-matrix-abk-native-clean-room-v1
- authority: campaign, schema, fixture, and metadata-only snapshot reads; run-root writes only.
- side_effects: external project reads, network, credentials, production resources, external writes, Git mutation, and child processes denied.

- readiness: readiness.json
- provenance: provenance.json

- links: run.json, oracle-result.json, stdout.log, stderr.log, tool-events.jsonl, output-inventory.json
- links: readiness.json, provenance.json, operator.md
- error: RECOVERED_AFTER_FAILURE (project.failure_after)
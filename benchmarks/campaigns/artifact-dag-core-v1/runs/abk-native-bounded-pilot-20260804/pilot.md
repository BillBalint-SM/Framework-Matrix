# ABK-native bounded pilot

- pilot_id: abk:pilot:abk-native-bounded-v1
- captured_at: 2026-08-04T21:14:51Z
- status: passed
- scope: one run for each of the ten frozen fixtures; abk_native only
- full_campaign: false
- raw_runs: 10 / 66 expected for the complete three-branch campaign
- scorecard: UNSCORED; no adoption outcome is asserted
- external_project_execution: false; immutable snapshot used as metadata-only provenance

| Case | Terminal | Exit | Oracle | Comparable | Evidence |
|---|---|---:|---|---|---|
| COM-01-normal-primary | SUCCEEDED | 0 | passed | True | abk-native-pilot-com-01-normal-primary-r1 |
| COM-02-normal-variant | SUCCEEDED | 0 | passed | True | abk-native-pilot-com-02-normal-variant-r1 |
| COM-03-normal-repeat | SUCCEEDED | 0 | passed | True | abk-native-pilot-com-03-normal-repeat-r1 |
| COM-04-boundary-minimum | SUCCEEDED | 0 | passed | True | abk-native-pilot-com-04-boundary-minimum-r1 |
| COM-05-invalid-input | FAILED | 3 | failed | False | abk-native-pilot-com-05-invalid-input-r1 |
| COM-06-stop-interrupt | STOPPED | 130 | stopped | True | abk-native-pilot-com-06-stop-interrupt-r1 |
| SPC-01-domain-boundary | REJECTED | 2 | inconclusive | False | abk-native-pilot-spc-01-domain-boundary-r1 |
| SPC-02-failure-path | FAILED | 3 | failed | False | abk-native-pilot-spc-02-failure-path-r1 |
| SPC-03-recovery-rollback | RECOVERED | 0 | passed | True | abk-native-pilot-spc-03-recovery-rollback-r1 |
| SPC-04-composition-handoff | SUCCEEDED | 0 | passed | True | abk-native-pilot-spc-04-composition-handoff-r1 |
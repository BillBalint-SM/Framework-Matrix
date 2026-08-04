# Control-native bounded pilot

- pilot_id: abk:pilot:control-bounded-v1
- captured_at: 2026-08-04T20:14:18Z
- status: passed (harness completed all ten control baseline runs)
- scope: one run for each of the ten frozen fixtures; control branch only
- full_campaign: false
- raw_runs: 10 / 66 expected for the complete three-branch campaign
- evaluation: 6 aligned, 4 divergent against the campaign oracle
- scorecard: UNSCORED; no adoption outcome is asserted

| Case | Expected | Observed | Exit | Evaluation | Evidence |
|---|---|---|---:|---|---|
| COM-01-normal-primary | SUCCEEDED | SUCCEEDED | 0 | aligned | control-bounded-pilot-com-01-normal-primary-r1 |
| COM-02-normal-variant | SUCCEEDED | SUCCEEDED | 0 | aligned | control-bounded-pilot-com-02-normal-variant-r1 |
| COM-03-normal-repeat | SUCCEEDED | SUCCEEDED | 0 | aligned | control-bounded-pilot-com-03-normal-repeat-r1 |
| COM-04-boundary-minimum | SUCCEEDED | SUCCEEDED | 0 | aligned | control-bounded-pilot-com-04-boundary-minimum-r1 |
| COM-05-invalid-input | FAILED | FAILED | 3 | aligned | control-bounded-pilot-com-05-invalid-input-r1 |
| COM-06-stop-interrupt | STOPPED | SUCCEEDED | 0 | divergent | control-bounded-pilot-com-06-stop-interrupt-r1 |
| SPC-01-domain-boundary | REJECTED | FAILED | 3 | divergent | control-bounded-pilot-spc-01-domain-boundary-r1 |
| SPC-02-failure-path | FAILED | FAILED | 3 | aligned | control-bounded-pilot-spc-02-failure-path-r1 |
| SPC-03-recovery-rollback | RECOVERED | SUCCEEDED | 0 | divergent | control-bounded-pilot-spc-03-recovery-rollback-r1 |
| SPC-04-composition-handoff | SUCCEEDED | SUCCEEDED | 0 | divergent | control-bounded-pilot-spc-04-composition-handoff-r1 |

This control pilot is a reproducibility baseline. Divergences are preserved as evidence and do not modify the legacy control runner or campaign counters.
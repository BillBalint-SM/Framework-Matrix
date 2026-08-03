# GitHub Spec Kit confirmed broken bundle references

Pinned commit: `d1e86f638277a99b82715c22c90558cd58d3cffd`

All four example READMEs instruct users to run `specify bundle validate --path ...`. At the pin, each command exits 1. The 16 rows below are executable bundle-component references with no built-in/community catalog terminal. They are the only `confirmed_broken` rows in `reference-ledger.csv`; generic unresolved rows are zero.

| Source | Line | Reference | Classification | Reason |
|---|---:|---|---|---|
| `examples/bundles/business-analyst/bundle.yml` | 22 | `preset:requirements-elicitation@1.0.0` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/business-analyst/bundle.yml` | 27 | `step:capture-requirements@unpinned` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/business-analyst/bundle.yml` | 28 | `step:trace-acceptance-criteria@unpinned` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/business-analyst/bundle.yml` | 30 | `workflow:requirements-to-spec@1.0.0` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/developer/bundle.yml` | 22 | `preset:implementation-planning@1.0.0` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/developer/bundle.yml` | 27 | `step:plan-implementation@unpinned` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/developer/bundle.yml` | 28 | `step:break-down-tasks@unpinned` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/developer/bundle.yml` | 30 | `workflow:spec-to-implementation@1.0.0` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/product-manager/bundle.yml` | 24 | `preset:product-discovery@1.0.0` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/product-manager/bundle.yml` | 29 | `step:draft-spec@unpinned` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/product-manager/bundle.yml` | 30 | `step:review-spec@unpinned` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/product-manager/bundle.yml` | 32 | `workflow:spec-to-roadmap@1.0.0` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/security-researcher/bundle.yml` | 22 | `preset:security-compliance@1.0.0` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/security-researcher/bundle.yml` | 27 | `step:threat-model@unpinned` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/security-researcher/bundle.yml` | 28 | `step:security-review@unpinned` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |
| `examples/bundles/security-researcher/bundle.yml` | 30 | `workflow:secure-sdd@1.0.0` | confirmed broken executable reference | absent from pinned built-in/community catalog; CLI validation exit 1 |

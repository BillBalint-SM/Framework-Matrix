# Continuation research: 2025–2026 SDD and agentic-workflow landscape

**Research date:** 2026-08-03 (Europe/Budapest)
**Scope:** OpenSpec, GitHub Spec Kit, GSD Core, Paul, and BMAD-METHOD; first-party upstream material only for external claims.
**Purpose:** inform the next Framework-Matrix discovery and empirical benchmark decisions. This is a landscape scan, not an adoption decision.

## 1. Source list and currentness

All external pages below were accessed on 2026-08-03. “Currentness” means the newest release/tag visible at access time; `main` documentation is treated as mutable and must be commit-pinned before any benchmark run.

| ID | Source | Kind and observed date | Currentness / use |
|---|---|---|---|
| L1 | [`outputs/00-sdd-framework-research-design.md`](../../../outputs/00-sdd-framework-research-design.md) | Local design, dated 2026-08-02 | Current project contract at local `main` `4b94415`; defines five candidates, provenance rules, and read-only boundaries. |
| L2 | [`outputs/06-reusable-pattern-catalog.md`](../../../outputs/06-reusable-pattern-catalog.md) | Local synthesis, dated 2026-08-02 | Current pattern hypotheses; not external evidence and not an adoption result. |
| L3 | [`outputs/08-empirical-benchmark-protocol.md`](../../../outputs/08-empirical-benchmark-protocol.md) | Local protocol, dated 2026-08-02 | Current benchmark contract: 10 cases, three branches, Codex-only, evidence-backed scorecards. |
| L4 | [`README.md`](../../../README.md), [`benchmarks/README.md`](../../../benchmarks/README.md) | Local repository context, accessed 2026-08-03 | Describes the source/evidence/archive split and the pending first campaign. |
| S1 | [OpenSpec v1.7.0 release](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.7.0) | Release, published 2026-07-29, commit `4e16790` | Current latest tagged OpenSpec release observed. Release notes cover tool integrations, default stores, `skip_specs`, project context, and archive behavior. |
| S2 | [OpenSpec README](https://github.com/Fission-AI/OpenSpec/blob/main/README.md) | Upstream `main`, accessed 2026-08-03 | Mutable operational documentation; use for current workflow, 30+ tool support, stores, and telemetry claims, then pin a commit. |
| S3 | [GitHub Spec Kit v0.15.1 release](https://github.com/github/spec-kit/releases/tag/v0.15.1) | Release, published 2026-07-31 | Current latest tagged Spec Kit release observed; notes include tar installs, TOCTOU and URL-cache hardening, and workflow/input validation. |
| S4 | [Spec Kit documentation home](https://github.github.com/spec-kit/index.html) | First-party docs, last updated 2026-07-16 | Current ecosystem snapshot at access: 35 integrations, 138 extensions, 25 presets; counts are directional, not adoption evidence. |
| S5 | [GSD Core v1.9.1 release](https://github.com/open-gsd/gsd-core/releases/tag/v1.9.1) | Release, published 2026-07-31, commit `957ebd8` | Current latest tagged GSD Core release observed; notes include reviewer lanes, Windows process mediation, worktree/reparse-point safety, and fail-closed staging. |
| S6 | [GSD Core README](https://github.com/open-gsd/gsd-core/blob/main/README.md) | Upstream `main`, accessed 2026-08-03 | Mutable documentation; directly states the five-phase loop, fresh-context subagents, 200k-token executor context, and multi-runtime installer. |
| S7 | [Paul tags](https://github.com/ChristopherKahler/paul/tags) | Tag index, latest visible `v1.2.0` published 2026-03-24 | Latest tagged Paul release observed; absence of a newer tag is not evidence that `main` is unchanged. |
| S8 | [Paul README](https://github.com/ChristopherKahler/paul/blob/main/README.md) | Upstream `main`, accessed 2026-08-03 | Mutable documentation; directly states PLAN–APPLY–UNIFY, acceptance criteria, E/Q verification, escalation statuses, and persisted state. |
| S9 | [BMAD-METHOD v6.10.0 release](https://github.com/bmad-code-org/BMAD-METHOD/releases/tag/v6.10.0) | Release, published 2026-07-03, commit `081e64e` | Current latest tagged BMAD release observed; notes cover `bmad-loop`, `bmad-dev-auto`, synchronous subagents, and installer hardening. |
| S10 | [BMAD workflow map](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/docs/reference/workflow-map.md) | First-party docs, accessed 2026-08-03 | Mutable workflow contract; directly states four progressive phases and artifact handoffs. |

## 2. Landscape trends (evidence and interpretation)

### Trend 1 — Cross-runtime portability is becoming a product requirement

**Directly sourced facts.** OpenSpec v1.7.0 adds five tools and says Codex is now skills-only; its README describes 30+ supported tools ([S1](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.7.0), [S2](https://github.com/Fission-AI/OpenSpec/blob/main/README.md)). Spec Kit's first-party site lists 35 integrations, 138 extensions, and 25 presets ([S4](https://github.github.com/spec-kit/index.html)). GSD Core advertises Claude Code, Codex, Copilot, Cursor, Windsurf, and other runtimes and prompts for the target runtime during install ([S6](https://github.com/open-gsd/gsd-core/blob/main/README.md)). BMAD v6.10.0 added Hermes Agent and CodeWhale targets ([S9](https://github.com/bmad-code-org/BMAD-METHOD/releases/tag/v6.10.0)).

**Inference for this project.** A vendor-neutral core must be separated from host projections. “Supports host X” should be a capability declaration plus a parity test, not a copied command tree. Discovery should ask which two hosts matter first (Codex is fixed by the benchmark protocol; a second host is a validation choice).

### Trend 2 — Skills and registries are replacing scattered, host-specific prompt files

**Directly sourced facts.** OpenSpec's v1.7.0 notes say Codex runs skills-only and that `skills add` is supported ([S1](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.7.0)). Spec Kit documents native skills-based integrations and a catalog of extensions/presets ([S3](https://github.com/github/spec-kit/releases/tag/v0.15.1), [S4](https://github.github.com/spec-kit/index.html)). GSD v1.9.0 introduced a Kimi Agent Skills layout and fallback for non-dispatchable runtimes ([GSD v1.9.0 release](https://github.com/open-gsd/gsd-core/releases/tag/v1.9.0)). BMAD's latest release packages `bmad-loop` through a marketplace module and exposes skills behind a plugin registry ([S9](https://github.com/bmad-code-org/BMAD-METHOD/releases/tag/v6.10.0)).

**Inference for this project.** Treat `Skill`, `Workflow`, `Role`, and `Adapter` as registered, versioned components with provenance. Generated host files are projections and should never become the canonical source of truth. The benchmark needs install, refresh, uninstall, and preservation checks for each projection.

### Trend 3 — Durable artifact/state contracts are the antidote to chat-only context

**Directly sourced facts.** OpenSpec's current workflow creates proposal, requirements/scenarios, design, and task artifacts, tracks them as a graph, and supports a beta cross-repository “Stores” model ([S2](https://github.com/Fission-AI/OpenSpec/blob/main/README.md), [S1](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.7.0)). GSD Core explicitly frames context rot as a problem and runs Discuss → Plan → Execute → Verify → Ship, using fresh-context subagents ([S6](https://github.com/open-gsd/gsd-core/blob/main/README.md)). Paul persists `PROJECT.md`, `STATE.md`, plans, summaries, and decisions and requires PLAN → APPLY → UNIFY ([S8](https://github.com/ChristopherKahler/paul/blob/main/README.md)). BMAD's workflow map describes four progressive phases whose documents inform the next phase ([S10](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/docs/reference/workflow-map.md)).

**Inference for this project.** The minimum useful substrate is an inspectable artifact graph plus session/run state, not a larger prompt library. Discovery should test whether users can resume, review, and hand off work from files without reconstructing prior chat.

### Trend 4 — Security and failure semantics are moving into the workflow engine

**Directly sourced facts.** Spec Kit v0.15.1 hardens tar installs, TOCTOU-safe unlinking, symlink/junction races, redirects, and malformed workflow/catalog inputs ([S3](https://github.com/github/spec-kit/releases/tag/v0.15.1)). GSD v1.9.1 mediates Windows `.cmd`/`.bat`/`.exe` launches, avoids deleting reparse points, rejects out-of-repo paths, and fails closed when staging fails ([S5](https://github.com/open-gsd/gsd-core/releases/tag/v1.9.1)). OpenSpec v1.3.1 fixed canonical path/glob handling and made firewalled telemetry silent with a timeout ([OpenSpec v1.3.1 release](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.3.1)). BMAD v6.10.0 makes plugin resolution fail loudly, requires synchronous subagent invocation for its loop, and adds installer path handling on Windows ([S9](https://github.com/bmad-code-org/BMAD-METHOD/releases/tag/v6.10.0)).

**Inference for this project.** Prompt-level “do not write” language is insufficient. Capability, path, network, timeout, side-effect, and recovery contracts must be machine-checked at ingestion and execution. Negative and boundary cases therefore deserve first-class benchmark slots, matching the existing protocol.

### Trend 5 — Unattended/autonomous loops are shipping, but with explicit review and stop contracts

**Directly sourced facts.** BMAD v6.10.0 introduces `bmad-loop` and `bmad-dev-auto` for unattended iterations that create/resume specs, implement, review, and finalize; it requires synchronous subagents and records final revision state ([S9](https://github.com/bmad-code-org/BMAD-METHOD/releases/tag/v6.10.0)). GSD runs parallel execution waves in clean contexts and added a discoverable reviewer lane ([S6](https://github.com/open-gsd/gsd-core/blob/main/README.md), [S5](https://github.com/open-gsd/gsd-core/releases/tag/v1.9.1)). Paul verifies each task independently, exposes `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, and `BLOCKED`, and pauses for human input when needed ([S8](https://github.com/ChristopherKahler/paul/blob/main/README.md)). Spec Kit's catalog now includes autonomous-run and quality-gate governance presets ([S4](https://github.github.com/spec-kit/index.html), [Spec Kit v0.12.14 changelog](https://github.com/github/spec-kit/blob/main/CHANGELOG.md#L535-L547)).

**Inference for this project.** “Autonomous” should be measured as bounded useful autonomy, not absence of humans. The benchmark must score stop/interruption, reviewer handoff, evidence quality, and recovery separately from task success; an unattended loop without a terminal state is a failure mode.

### Trend 6 — Ecosystem composition (extensions, presets, schemas, modules) is a core scaling strategy

**Directly sourced facts.** Spec Kit publishes community extensions, presets, bundles, and workflows with pinned metadata ([S4](https://github.github.com/spec-kit/index.html), [Spec Kit bundles](https://github.github.com/spec-kit/reference/bundles.html)). OpenSpec supports custom schemas, community schema bundles, profiles, and a default store ([S1](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.7.0), [S2](https://github.com/Fission-AI/OpenSpec/blob/main/README.md)). BMAD installs optional modules through a registry/marketplace resolver ([S9](https://github.com/bmad-code-org/BMAD-METHOD/releases/tag/v6.10.0)). GSD v1.9.1 adds a reviewer entry type so third-party reviewer lanes are discoverable ([S5](https://github.com/open-gsd/gsd-core/releases/tag/v1.9.1)).

**Inference for this project.** A framework that cannot resolve component versions, ownership, trust, conflicts, and deprecation will not scale past its first few workflows. Discovery should evaluate registry ergonomics and provenance as user-facing needs, not just implementation details.

### Trend 7 — Deterministic materialization and cross-host parity are becoming differentiators

**Directly sourced facts.** Spec Kit v0.15.1 adds tar-archive installs and continues hardening generated bundles and workflow inputs ([S3](https://github.com/github/spec-kit/releases/tag/v0.15.1)). GSD's v1.8.0 release added negotiated host integration, write confinement, portability AST rules, and adapter seams ([GSD v1.8.0 release](https://github.com/open-gsd/gsd-core/releases/tag/v1.8.0)). BMAD's v6.8.0 release describes web bundles with IDE schema parity ([BMAD v6.8.0 release](https://github.com/bmad-code-org/BMAD-METHOD/releases/tag/v6.8.0)). Paul persists state and decisions across sessions and emits a predictable summary/STATE update on UNIFY ([S8](https://github.com/ChristopherKahler/paul/blob/main/README.md)).

**Inference for this project.** Preview and execution should consume one canonical materialization plan; outputs need hashes, ownership, and a reproducible fixture. The existing benchmark protocol's manifest, SHA-256, isolation, and output-inventory requirements are aligned with this trend and should remain hard gates.

## 3. User-needs implications for Framework-Matrix

The sources are framework maintainers' claims, not interviews or usage telemetry. The following are discovery hypotheses to validate with target users:

| Likely user need | Why it is plausible from the scan | Discovery/benchmark consequence |
|---|---|---|
| Resume and hand off work without replaying chat | All five candidates persist artifacts, state, or phase outputs (T3). | Test fresh-session resume and reviewer handoff as a normal and interrupted path. |
| Know exactly what will be written before it is written | Security fixes and preview/materialization patterns recur (T4, T7). | Require a pure plan/preview, ownership manifest, path-boundary checks, and an inspectable diff. |
| Use the same process across more than one coding host | Every candidate is adding integrations or targets (T1, T2). | Define a minimal capability matrix; run parity fixtures rather than counting integrations. |
| Keep requirements and implementation synchronized | Artifact graphs, progressive phase documents, and verify/reconcile loops recur (T3). | Measure drift detection, verify/review findings, and archive/converge behavior. |
| Delegate selectively without losing control | Fresh-context parallelism and unattended loops are expanding, but all expose reviewer/stop concepts (T5). | Benchmark bounded concurrency, cancellation, escalation, reviewer evidence, and terminal states. |
| Extend the framework safely | Registries/catalogs/modules are now first-class (T6). | Evaluate provenance, trust/consent, version pinning, conflict resolution, and uninstall preservation. |
| Operate reliably on Windows and in constrained networks | Recent fixes explicitly mention Windows path/process issues and firewalled telemetry (T4). | Include Windows path, junction/reparse-point, offline, timeout, and malformed-input fixtures. |

## 4. Direct fact versus inference

| Claim class | Examples in this artifact | Confidence and handling |
|---|---|---|
| **Directly sourced fact** | Release version/date; documented command names; stated host integrations; stated artifact/phase/state behavior; stated security fixes. | High for the cited release/page at access time. Re-check against pinned source commits before benchmark execution. |
| **Project-local fact** | The current design requires a Codex-only, three-branch, 10-case benchmark and forbids upstream/runtime adoption during discovery ([L1](../../../outputs/00-sdd-framework-research-design.md), [L3](../../../outputs/08-empirical-benchmark-protocol.md)). | High for this repository state; local docs can change and are not external validation. |
| **Inference / hypothesis** | Users will prioritize resume, preview, portability, bounded autonomy, extension safety, and Windows/offline reliability; a state/projection substrate is the best first slice. | Medium or low until interviews and empirical runs. Do not present these as validated demand or a framework ranking. |
| **Not established here** | Relative quality, adoption, defect rate, token savings, or business value of any candidate. | No independent telemetry or user study was used; the benchmark is still `UNSCORED`. |

## 5. Assumptions and open questions

### Assumptions

- The five repositories remain the intended comparison set; no new framework is added during this continuation scan.
- Release notes and first-party docs describe intended/current behavior but do not substitute for source-level and runtime evidence.
- The local baseline at commit `4b94415` and the accepted benchmark protocol remain authoritative until the project owner changes them.
- Codex is the common host for the first empirical campaign; other host claims are discovery signals only.
- A release/tag is the reproducibility boundary. Mutable `main` docs are useful for trend direction but cannot be benchmark evidence without a pinned commit.

### Open questions to resolve in discovery

1. Which user segment is primary: solo brownfield maintainer, multi-repo team, or platform/enablement team?
2. Which second host, if any, should receive parity testing after Codex: Claude Code, Copilot, or a Windows-native alternative?
3. What human approval policy is required for unattended execution, extension installation, network access, and Git mutations?
4. Which artifacts are canonical for the target users (requirements, design, tasks, evidence, review, archive), and what must be machine-readable?
5. What latency, token, and storage budgets make resume/review acceptable in daily work?
6. How much extension/catalog complexity is useful before discoverability and trust become worse than a small built-in core?
7. Which offline, air-gapped, Windows, and multi-repository constraints are must-pass rather than optional hardening?

## 6. Recommendation for the next discovery cycle

Use the trend scan to validate problems, not to pick a winner. Run at least five structured user interviews across the candidate segments, then freeze release commits and execute the existing three-branch benchmark on the smallest substrate that can test the hypotheses: (a) artifact graph and root provenance, (b) canonical workflow/role representation plus one materialization plan, (c) ownership/path/trust enforcement, and (d) evidence-backed reviewer/stop/recovery behavior. Keep host adapters and extension registries as explicit projections with parity gates. Do not infer `CHOSEN` or `ADOPTED` from release maturity, star counts, documentation quality, or the number of integrations.

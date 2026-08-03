# ChristopherKahler/paul — exhaustive agent-gear report

## Executive conclusion

PAUL v1.4.0 is a prompt-orchestration framework for Claude Code, not an executable workflow engine. Its useful core is a disciplined `PLAN → APPLY → UNIFY` artifact loop: plans define acceptance criteria and boundaries, APPLY runs an Execute/Qualify loop, and UNIFY reconciles plan against observed output and updates persistent project state. The architecture separates slash-command entry points, detailed workflows, conceptual references, generated-document templates, maintainer rules, and an optional CARL ruleset.

The pinned source is internally rich but the distributed runtime is materially inconsistent with it:

1. The installer successfully creates 28 slash-command files and 69 framework files for both local and custom-global installs. It rewrites every installed `~/.claude/` occurrence.
2. It installs `src/{templates,workflows,references,rules}` as `paul-framework/{templates,workflows,references,rules}` and does **not** install a `src/` directory, while 63 `@src/` tokens remain in installed Markdown. Five are illustrative placeholders; 58 are concrete static paths and none resolves from the installed root. Forty-six of the 58 are execution-relevant instructions rather than examples or maintainer-rule illustrations.
3. Seventeen of 28 installed commands reach at least one unresolved concrete reference on their normal static delegation path. **Source fact:** both `/paul:map-codebase` command references point to `@src/workflows/map-codebase.md`, for which the distributed tree contains no target. **Inference:** under the expected Claude Code reference semantics this prevents the command from loading its sole procedural delegate; actual Claude `@` parsing was not executed.
4. Windows custom-path replacement writes mixed-separator, unquoted references such as `@C:\...\custom config/paul-framework/workflows/plan-phase.md`. The filesystem target exists, but this research did not execute Claude Code's `@` parser, so paths containing spaces remain an unresolved runtime concern.
5. CARL files are tracked in source but excluded from the npm package and installer. If manually copied, the CARL rule points to `~/.claude/paul-framework/src/commands/{name}.md`, another path that the installer never creates.
6. Documentation counts and several behavioral claims drift from the installed tree. The README says 26 commands; the installed help footer says 23 commands, 14 workflows, and 13 templates; the tree actually contains 28, 23, and 27. The README's `/paul:quality-gate` behavior is backed by a workflow but no command file, and `debug.md` likewise has no command entry point.

These are direct source facts and isolated runtime observations. Claims about quality percentages, token cost, GSD behavior, BASE v2, and the practical strength of prompt-level “enforcement” are author claims unless separately demonstrated below.

## 1. Snapshot, provenance, and method

- Repository: `ChristopherKahler/paul`
- Branch: `main`
- Pinned commit: [`960b05c0b8e1f876f49674a700c9a087afebb8ac`](https://github.com/ChristopherKahler/paul/commit/960b05c0b8e1f876f49674a700c9a087afebb8ac)
- Package identity: `paul-framework` v1.4.0, Node `>=16.7.0`, MIT license ([`package.json` lines 1–37](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/package.json#L1-L37)).
- Work-state preflight, refreshed 2026-08-02T12:51:47Z: repository and pin matched; branch `main`; worktree clean; upstream `origin/main`; no PR; evidence `local+remote`.
- Analysis covered all 108 tracked files and all 106 gear candidates without sampling. The two non-gear files are the PNG and SVG terminal assets.
- Primary sources were the pinned files, the Git history leading to the pin, the executable installer, `npm pack --dry-run`, an isolated Windows local/custom-global installation, and a full installed-tree reference scan.
- No source file, branch, commit, remote, credential, API, paid service, or production system was changed. The only repository write is this report. The isolated temp installation was removed after validation.

### Claim labels used

- **Source fact** — directly present in the pinned repository.
- **Runtime observation** — observed by executing a safe local command against the pin.
- **Author claim** — stated in project documentation but not independently established here.
- **Inference** — reasoned from source/runtime facts and explicitly identified.

## 2. Exhaustive tracked-file and gear coverage

The supplied inventory exactly matches `git ls-files`: 108 rows, 108 tracked paths, zero missing, zero extra. Category totals are 78 orchestration assets, 22 documentation files, 4 other/source files, 1 executable source, 1 configuration file, and 2 binary assets. Gear-candidate total: 106.

### 2.1 Root and distribution files — 9/9

| File | Account |
|---|---|
| [`.gitignore`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/.gitignore#L1-L19) | Ignores project instance state, Node artifacts, editor files, root handoffs, and a removed special-flows spec. Gear candidate. |
| [`README.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L1-L31) | Product narrative, install instructions, loop, commands, project-state model, BASE/CARL claims, comparisons, troubleshooting. Gear candidate. |
| [`IDEATION.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/IDEATION.md#L1-L9) | Explicit future backlog for a UNIFY-to-content pipeline; not current runtime behavior. Gear candidate. |
| [`PAUL-VS-GSD.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/PAUL-VS-GSD.md#L1-L11) | Author comparison and positioning against GSD. Gear candidate; GSD-side claims were not independently verified. |
| [`LICENSE`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/LICENSE#L1-L20) | MIT grant, notice-retention condition, and warranty/liability disclaimer. Gear candidate. |
| [`package.json`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/package.json#L1-L37) | npm metadata, CLI entry, publish allowlist, Node floor. Gear candidate. |
| [`bin/install.js`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L1-L17) | Only executable source: parses install flags, selects destination, rewrites paths, copies the command/framework trees. Gear candidate. |
| `assets/terminal.png` | README install screenshot. Binary, not a gear candidate. |
| `assets/terminal.svg` | Vector terminal artwork. Binary, not a gear candidate. |

### 2.2 CARL — 2/2

| File | Account |
|---|---|
| [`src/carl/PAUL`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/carl/PAUL#L1-L26) | Optional PAUL domain: active but not always-on; claims activation when `.paul/` exists; 12 rules cover file loading, plan approval, mandatory UNIFY, boundaries, blockers, state consistency, verification, deviations, BDD, context sizing, commit cadence, and decimal phases. Its command-load path is incompatible with the installed tree. |
| [`src/carl/PAUL.manifest`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/carl/PAUL.manifest#L1-L11) | Manual CARL installation/activation block with recall terms. It is not shipped by npm or copied by the installer. |

### 2.3 Commands — 28/28

Commands are intended as thin wrappers around workflows ([`src/rules/commands.md` lines 21–35](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/commands.md#L21-L35)). The table accounts for every installed command.

| Command file | Role and delegation | Notable tool/surface fact |
|---|---|---|
| [`add-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/add-phase.md#L1-L36) | Add a phase through `roadmap-management`. | Read/Write/Edit/Bash; downstream unresolved `@src` template ref. |
| [`apply.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/apply.md#L1-L82) | Validate and execute an approved plan; load checkpoints; route to APPLY workflow. | Read/Write/Edit/Bash/Glob/Grep/Ask; downstream unresolved TOML-sync ref. |
| [`assumptions.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/assumptions.md#L1-L37) | Surface Claude's five-area assumptions before planning. | Read/Bash; static delegation resolves. |
| [`audit.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/audit.md#L1-L56) | Same-session senior-principal/compliance persona audits and mutates a plan. | Read/Write/Edit/Glob/Ask; no separate auditor agent. |
| [`complete-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/complete-milestone.md#L1-L36) | Archive/evolve/tag a completed milestone. | Read/Write/Edit/Bash/Glob; 3 downstream unresolved refs. |
| [`config.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/config.md#L1-L12) | Self-contained config UI for SonarQube and enterprise audit. | No YAML frontmatter, command name, description, or tool allowlist. It advertises `/paul:quality-gate`, whose command file is absent. |
| [`consider-issues.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/consider-issues.md#L1-L40) | Triage ISS/UAT items against current code. | Static workflow path resolves. |
| [`discover.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/discover.md#L1-L47) | Technical option discovery with depth and subagents. | Web/Task-capable; 2 downstream unresolved refs. |
| [`discuss-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/discuss-milestone.md#L1-L33) | Create milestone vision/context. | Downstream template ref unresolved. |
| [`discuss.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/discuss.md#L1-L34) | Create phase CONTEXT from a guided discussion. | Downstream template ref unresolved. |
| [`flows.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/flows.md#L1-L73) | Configure/add/audit/list specialized skills. | One relative installed reference resolves; 2 workflow `@src` refs do not. |
| [`handoff.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/handoff.md#L1-L29) | Self-contained detailed session handoff; registers with `base` if available. | Read/Write/Bash; no external workflow. |
| [`help.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/help.md#L1-L17) | Emits embedded command reference only. | Footer counts are stale. |
| [`init.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/init.md#L1-L53) | Initialize `.paul/` through conversation and templates. | Six immediate resources resolve; its workflow reaches 8 unresolved refs. |
| [`map-codebase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/map-codebase.md#L1-L33) | Intended to launch four Explore agents and write seven map documents. | No frontmatter; both direct workflow refs have no target in the installed tree. Actual Claude runtime failure is inferred, not executed. |
| [`milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/milestone.md#L1-L34) | Create milestone and phase structure. | Three downstream unresolved refs. |
| [`pause.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/pause.md#L1-L44) | Create a compact handoff, update STATE, optionally commit. | All static framework refs resolve. |
| [`plan-fix.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/plan-fix.md#L1-L19) | Self-contained conversion of UAT issues into a bounded FIX plan. | Reference paths resolve; no workflow delegate. |
| [`plan.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/plan.md#L1-L36) | Create/continue a scope-adaptive plan. | Downstream TOML-sync ref unresolved. |
| [`progress.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/progress.md#L1-L43) | Read state/roadmap and recommend exactly one next action. | Read-only, self-contained. |
| [`register.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/register.md#L1-L35) | Migrate/create `paul.toml` and create ledger. | Its workflow contains 5 unresolved execution refs. |
| [`remove-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/remove-phase.md#L1-L37) | Remove an unstarted phase and renumber later phases. | Downstream template ref unresolved; destructive scope is prompt-mediated. |
| [`research-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/research-phase.md#L1-L31) | Identify up to three substantial unknowns and research in parallel. | Explore/general-purpose agents; downstream RESEARCH template ref unresolved. |
| [`research.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/research.md#L1-L46) | Research a named codebase or web topic and persist findings. | Explore/general-purpose selection; downstream RESEARCH template ref unresolved. |
| [`resume.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/resume.md#L1-L49) | Load state/handoff and suggest one action. | Static refs resolve; underlying workflow has malformed duplicate `</process>`. |
| [`status.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/status.md#L1-L22) | Deprecated state display. | Read-only, self-contained. |
| [`unify.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/unify.md#L1-L26) | Reconcile a plan, create SUMMARY, update state. | Allowlist omits Bash/Edit/Glob although the delegated last-plan transition uses Bash/git; 2 downstream unresolved refs. |
| [`verify.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/verify.md#L1-L59) | Guide user-run UAT and log issues. | Two downstream UAT-template refs unresolved. |

### 2.4 Workflows — 23/23

| Workflow | Terminal behavior and outputs |
|---|---|
| [`apply-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L1-L26) | Approval gate; plan/skill load; sequential E/Q tasks; checkpoints; task/deviation log; STATE + manifest/ledger update; route to UNIFY. |
| [`audit-plan.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/audit-plan.md#L1-L21) | Same-model enterprise/compliance persona; classify findings; mutate PLAN; create AUDIT; update STATE; route or block. |
| [`complete-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/complete-milestone.md#L1-L30) | Verify readiness; aggregate summaries/stats; update MILESTONES/PROJECT/ROADMAP/STATE; archive; align five versions; tag; manifest/ledger; next milestone. |
| [`configure-special-flows.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/configure-special-flows.md#L1-L27) | Discover skills, map work types/priorities/triggers, phase overrides/assets, write SPECIAL-FLOWS and PROJECT reference; also defines add/audit/list subcommands. |
| [`consider-issues.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/consider-issues.md#L1-L12) | Find/parse ISS and UAT files, inspect code, categorize resolved/urgent/natural-fit/wait, offer and execute user-selected edits. |
| [`create-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/create-milestone.md#L1-L28) | Gather milestone/phases, update roadmap/state, create directories, sync manifest/ledger, delete consumed context, offer PLAN. |
| [`debug.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/debug.md#L1-L28) | Persistent debug session: capture symptoms, hypothesis/test/evidence loop, fix/verify, archive and commit. No command points to it. |
| [`discovery.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/discovery.md#L1-L24) | Quick/standard/deep option research, subagents/cross-checks, confidence and DISCOVERY artifact, route to PLAN. |
| [`discuss-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/discuss-milestone.md#L1-L29) | Validate state, explore features/scope, write MILESTONE-CONTEXT, hand off to milestone creation. |
| [`discuss-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/discuss-phase.md#L1-L31) | Validate phase, explore goals/approach, write phase CONTEXT, hand off to PLAN. |
| [`init-project.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/init-project.md#L1-L30) | Detect existing PAUL/BASE/PLANNING; converse by project type; create `.paul` artifacts, manifest, ledger, optional config/flows; route to PLAN. |
| [`map-codebase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/map-codebase.md#L1-L31) | Four parallel Explore agents; aggregate seven codebase documents; verify, commit, update STATE. Runtime-orphaned by broken command ref. |
| [`pause-work.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/pause-work.md#L1-L26) | Detect position, create/register handoff, update STATE, optional WIP branch/commit, confirm resume path. |
| [`phase-assumptions.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/phase-assumptions.md#L1-L9) | Validate phase; infer technical approach/order/boundaries/risks/dependencies with confidence; gather corrections; plan or re-examine. |
| [`plan-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/plan-phase.md#L1-L31) | Gate prior loop; classify quick/standard/complex; load lean context; inject skills; generate/validate/coherence-check PLAN; update state/roadmap/manifest/ledger. |
| [`quality-gate.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/quality-gate.md#L1-L31) | Check config/prerequisites; call named SonarQube MCP operations; evaluate gates/issues; update CONCERNS; report. No command file. |
| [`register-manifest.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/register-manifest.md#L1-L17) | Detect migration/creation mode, read state, create TOML + ledger, delete JSON, check BASE, confirm. |
| [`research.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/research.md#L1-L29) | Validate nontrivial topic; choose Explore or general-purpose; spawn one or parallel agents; persist and review RESEARCH. |
| [`resume-project.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/resume-project.md#L1-L33) | Verify `.paul`; find handoff; load/reconcile STATE; route one action; later archive/delete handoff. Has one `<process>` open and two closes. |
| [`roadmap-management.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/roadmap-management.md#L1-L34) | Two operation processes: add phase; or confirm/remove unstarted phase, conditionally delete empty directory, renumber, update state. |
| [`transition-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L1-L21) | Verify plan/summary count; clean handoffs; evolve PROJECT/STATE/ROADMAP; sync manifest; merge/delete branch with consent; commit phase; verify cross-file consistency; route. |
| [`unify-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/unify-phase.md#L1-L28) | Gather E/Q results; compare plan/actual; warn on skill gaps; create quick/full SUMMARY; update state/manifest; mandatory transition on last plan. |
| [`verify-work.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/verify-work.md#L1-L11) | Select recent summary/scope; generate UAT checklist; user tests; collect/log issues; verdict; intent/spec/code route. |

The workflow-style rule says every workflow must have `<purpose>`, `<when_to_use>`, and `<process>` ([`src/rules/workflows.md` lines 10–21](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/workflows.md#L10-L21)). Static inspection found `<when_to_use>` absent from `debug.md`, `map-codebase.md`, `phase-assumptions.md`, and `verify-work.md`. `resume-project.md` has mismatched process closers; `roadmap-management.md` intentionally contains two complete process blocks, one per operation.

### 2.5 Concept references — 14/14

| Reference | Account |
|---|---|
| [`checkpoints.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/checkpoints.md#L1-L18) | Three blocking checkpoint types, execution protocol, diagnostic routing, auth gates, automation-first rule. |
| [`context-management.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/context-management.md#L1-L17) | FRESH/MODERATE/DEEP/CRITICAL remaining-context brackets, lean loading, plan sizing, handoffs. |
| [`extension-points.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/extension-points.md#L1-L18) | Canonical five post-core workflow extension sites and comment-block injection convention. |
| [`git-strategy.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/git-strategy.md#L1-L24) | Per-task outcome commits, plan metadata commits, WIP handoffs, formats and rationale. |
| [`loop-phases.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L1-L18) | Canonical loop semantics, states, invariants, E/Q statuses, transitions, anti-patterns. |
| [`plan-format.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/plan-format.md#L1-L35) | Executable PLAN schema, task anatomy, BDD ACs, boundaries, specificity and sizing. |
| [`quality-principles.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/quality-principles.md#L1-L24) | Solo-user/Claude model, plans-as-prompts, loop-first, evidence chain, scope/deviation principles. |
| [`research-quality-control.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/research-quality-control.md#L1-L9) | Enumeration, authoritative sourcing, confidence, scope/currency checks, red flags and submission checklist. |
| [`sonarqube-integration.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/sonarqube-integration.md#L1-L20) | Sonar server/project/MCP setup, quality workflow, CONCERNS output and troubleshooting. |
| [`specialized-workflow-integration.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/specialized-workflow-integration.md#L1-L29) | SPECIAL-FLOWS → ROADMAP → PLAN → UNIFY trace and required/optional semantics. |
| [`subagent-criteria.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L1-L12) | Six all-required criteria, disqualifiers, decision tree, handoff/verification pattern. |
| [`tdd.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/tdd.md#L1-L32) | TDD applicability, single-feature plan, RED/GREEN/REFACTOR, commits, context and failures. |
| [`toml-sync.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/toml-sync.md#L1-L31) | Read-modify-write manifest, append-only ledger, JSON migration, trigger matrix. |
| [`work-units.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/work-units.md#L1-L21) | Context-based sizing, split signals/strategies, estimation heuristics. |

### 2.6 Maintainer rules — 5/5

| Rule file | Account |
|---|---|
| [`commands.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/commands.md#L1-L18) | Command frontmatter, section order, thin-wrapper and reference conventions. |
| [`references.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/references.md#L1-L23) | Reference structure, teaching patterns, lazy loading; explicitly conceptual, not executable. |
| [`style.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/style.md#L1-L26) | Imperative/no-filler tone, temporal-language rule, naming/XML/reference/AC/commit conventions. |
| [`templates.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/templates.md#L1-L18) | Template file anatomy and placeholder/frontmatter conventions. |
| [`workflows.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/workflows.md#L1-L27) | Required/optional workflow containers, step ordering, loop awareness, conditional form. |

These are installed under `paul-framework/rules/`, not Claude Code's top-level `.claude/rules/`, and no installed command references them. **Inference:** they function as repository-authoring guidance unless another external loader explicitly reads them.

### 2.7 Templates — 27/27

| Template | Generated artifact / purpose |
|---|---|
| [`config.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/config.md#L1-L12) | Project settings, SonarQube, enterprise audit, preferences. |
| [`CONTEXT.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/CONTEXT.md#L1-L12) | Phase goals, approach, constraints, questions, context. |
| [`DEBUG.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/DEBUG.md#L1-L12) | Persistent debug focus, symptoms, eliminated hypotheses, evidence, resolution. |
| [`DISCOVERY.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/DISCOVERY.md#L1-L12) | Options, comparison, recommendation, confidence, quality report. |
| [`HANDOFF.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/HANDOFF.md#L1-L12) | Cold-start resume document. |
| [`ISSUES.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/ISSUES.md#L1-L12) | Open/closed project enhancement log with IDs and effort. |
| [`ledger-toml.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/ledger-toml.md#L1-L12) | Append-only action/session history for BASE attribution. |
| [`milestone-archive.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/milestone-archive.md#L1-L12) | Completed milestone archive with phases and summary. |
| [`milestone-context.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/milestone-context.md#L1-L12) | Pre-milestone features, scope, phase map, constraints. |
| [`MILESTONES.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/MILESTONES.md#L1-L12) | Shipped-milestone log with stats, git range, next work. |
| [`paul-json.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/paul-json.md#L1-L12) | Deprecated pre-v1.4 JSON manifest retained for migration documentation. |
| [`paul-toml.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/paul-toml.md#L1-L12) | Identity, provenance, milestone, phase, loop, satellite, statistics manifest. |
| [`PLAN.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/PLAN.md#L1-L18) | Full executable plan, ACs, tasks, boundaries, verification, skills. |
| [`PROJECT.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/PROJECT.md#L1-L18) | Current project truth: value, requirements, users, constraints, decisions, metrics, stack. |
| [`RESEARCH.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/RESEARCH.md#L1-L18) | Topic, sources/findings/recommendations/questions plus agent metadata/status. |
| [`ROADMAP.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/ROADMAP.md#L1-L18) | Milestones, numbered/decimal phases, depth/research/status fields. |
| [`SPECIAL-FLOWS.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/SPECIAL-FLOWS.md#L1-L18) | Project skills, phase overrides, assets, audit checklist, amendments. |
| [`STATE.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/STATE.md#L1-L18) | Current milestone/phase/plan, visual loop, decisions/issues/blockers, boundaries, continuity. |
| [`SUMMARY.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/SUMMARY.md#L1-L18) | Outcome, AC and verification results, files/commits/decisions/deviations/issues/readiness. |
| [`UAT-ISSUES.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/UAT-ISSUES.md#L1-L18) | Phase-plan UAT issue log with severity, reproduction, expected/actual and resolution. |
| [`codebase/architecture.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/architecture.md#L1-L12) | Pattern, layers, flow, abstractions, entry points, errors, cross-cutting concerns. |
| [`codebase/concerns.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/concerns.md#L1-L12) | Debt, bugs, security, performance, fragility, scale, dependencies, gaps. |
| [`codebase/conventions.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/conventions.md#L1-L12) | Naming, style, imports, errors/logging, comments, function/module design. |
| [`codebase/integrations.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/integrations.md#L1-L12) | APIs/services, storage, identity, observability, CI/CD, env, webhooks. |
| [`codebase/stack.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/stack.md#L1-L12) | Languages, runtime, frameworks, dependencies, configuration, platforms. |
| [`codebase/structure.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/structure.md#L1-L12) | Directory layout/purpose, key locations, naming, placement rules. |
| [`codebase/testing.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/testing.md#L1-L12) | Framework, organization, structure, mocking, fixtures, coverage, test types/patterns. |

## 3. Architecture and runtime layers

```text
User /paul:* request
  → .claude/commands/paul/<command>.md       thin entry + tool allowlist
    → .claude/paul-framework/workflows/*    detailed stateful procedure
      → references/*                        conceptual rules, loaded on demand
      → templates/*                         output schemas
      → .paul/*                              project-local mutable state/artifacts
      → source files / CLI / MCP / Task      implementation and verification
    → optional CARL/BASE                     external rule/context activation
```

This is a prompt graph. `bin/install.js` only copies Markdown; it does not parse, validate, register, or execute workflows. Consequently, “mandatory,” “blocking,” and “enforced” mean instructions to the active Claude session. Without CARL/BASE or another hook, there is no independent process preventing a user/model from bypassing them.

### Command-to-workflow delegation

Most commands declare static framework files in `<execution_context>` and repeat the workflow in `<process>`. Dynamic inputs and project state use `.paul/` references. The intended distinction is documented as static versus project-relative lazy loading ([`src/rules/commands.md` lines 37–56](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/commands.md#L37-L56)). Self-contained commands (`config`, `handoff`, `help`, `plan-fix`, `progress`, `status`) do not require a workflow. `map-codebase` intends to delegate but points at the source-tree path.

### Context loading

The canonical strategy is progressive: STATE first, relevant SUMMARY second, specific source files last; avoid reading complete prior plans once summaries exist ([`context-management.md` lines 67–88](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/context-management.md#L67-L88)). Context brackets adapt behavior by remaining capacity: FRESH >70%, MODERATE 40–70%, DEEP 20–40%, CRITICAL <20% ([lines 7–16](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/context-management.md#L7-L16)). This conflicts with `work-units.md`, which later describes CARL thresholds as FRESH >60%, MODERATE 40–60%, DEPLETED <40% ([`work-units.md` lines 124–130](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/work-units.md#L124-L130)). The shipped CARL file itself contains no bracket rules.

## 4. Events, states, loops, and gates

### Plan–Apply–Unify state machine

The source defines three primary states and explicit entry/exit conditions ([`loop-phases.md` lines 20–49](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L20-L49), [51–120](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L51-L120), [122–154](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L122-L154)):

| State/event | Required evidence | Transition |
|---|---|---|
| Enter PLAN | Prior UNIFY complete or first plan; roadmap phase available; no blocker. | Create and validate PLAN, update STATE/ROADMAP, wait for explicit approval. |
| PLAN approved | Explicit “approved/execute/go ahead”; plan sections/AC/tasks/boundaries valid. | APPLY may begin. Audit is an optional PLAN sub-step. |
| APPLY task execute | Follow exact action and boundaries. | Report one of DONE, DONE_WITH_CONCERNS, NEEDS_CONTEXT, BLOCKED. |
| Qualify | Re-read output, run verify fresh, compare to task spec and linked AC. | PASS advances; GAP/DRIFT fixes and requalifies; max 3 loops then user escalation. |
| Checkpoint | `human-verify`, `decision`, or rare `human-action`; gate is blocking. | Wait for user and verify before continuing. |
| APPLY complete | Tasks PASS or blockers/deviations documented; checkpoints resolved. | Update STATE, offer UNIFY. |
| UNIFY | Compare plan/actual, AC results, deviations, skills; create SUMMARY; update STATE/manifest. | More plan → next PLAN; last plan → mandatory phase transition. |
| Phase transition | PLAN count equals SUMMARY count or user explicitly overrides. | Evolve project/roadmap/state, sync manifest, commit/merge flow, verify cross-file consistency, next phase/milestone. |

The E/Q mechanics and four execution statuses are operationally specified in [`apply-phase.md` lines 89–160](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L89-L160). The maximum-three GAP/DRIFT loop and user escalation appear at lines 141–158. The implementation permits APPLY to finish with documented blockers; therefore “all tasks complete” is not an absolute invariant.

### Checkpoints and failure routing

- `checkpoint:human-verify`: used after automation for visual/functional confirmation.
- `checkpoint:decision`: architecture/technology/design/prioritization choice.
- `checkpoint:human-action`: only when no CLI/API exists (email, SMS 2FA, approvals, 3DS, OAuth).
- Dynamic authentication gate: automation attempt → auth failure → human authenticates → retry ([`checkpoints.md` lines 158–166](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/checkpoints.md#L158-L166)).
- Human-verification or UAT failures must be classified as intent, spec, or code before fixes ([`checkpoints.md` lines 135–156](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/checkpoints.md#L135-L156)). Intent re-plans; spec updates AC/tasks before code; code fixes in place.

### Persistent state files

| File | Authority and lifecycle |
|---|---|
| `PROJECT.md` | Current project value, requirements, constraints, decisions, metrics and stack; evolved at phase/milestone transitions. |
| `ROADMAP.md` | Milestone/phase structure and status, including decimal interruption phases. |
| `STATE.md` | Current position, visual loop, recent decisions/issues/blockers/boundaries and session continuity; intended to stay small and current. |
| `{NN}-{PP}-PLAN.md` | Executable prompt: objective, context, ACs, tasks, boundaries, verification/output. |
| `{NN}-{PP}-SUMMARY.md` | What actually happened, AC evidence, deviations/decisions, changed files and readiness. |
| `paul.toml` | Machine-readable snapshot for BASE v2. Loop uses `IDLE/PLAN/APPLY/UNIFY`; absent plan keys represent TOML null. |
| `ledger.toml` | Append-only action history. |
| `HANDOFF-*.md` | Cold-start session continuity; resume later archives/deletes it. |
| `MILESTONES.md` / milestone archive | Shipped-version index and detailed completed-phase archive. |
| `ISSUES.md` / `*-UAT.md` | Deferred project enhancements versus plan-scoped acceptance issues. |

The manifest sync reference claims plan/apply/unify/transition/create/complete/verify/pause/resume coverage in its trigger matrix ([`toml-sync.md` lines 33–55](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/toml-sync.md#L33-L55)). Static inspection finds an actual `<step name="sync_paul_toml">` in only six workflows: plan, apply, unify, transition, create-milestone, complete-milestone. Init creates files and register migrates them, but verify, pause, and resume do not implement the matrix entries.

## 5. Agents, personas, and tool scopes

### Subagent policy

The reference says all six criteria must hold: independence, clear scope, parallel value, suitable complexity, token efficiency, and compatible state ([`subagent-criteria.md` lines 9–12](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L9-L12)). It also gives code/test implementation as positive examples and APPLY as a compatible state ([lines 13–24](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L13-L24), [78–89](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L78-L89)). The README and comparison instead say implementation stays in-session and subagents are reserved for discovery/research ([`README.md` lines 403–419](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L403-L419)). Actual workflow behavior follows the narrower README claim: APPLY does not spawn agents.

### Concrete agent/persona inventory

| Agent/persona | Trigger | Scope/output | Tool scope stated by command |
|---|---|---|---|
| `Explore` research agent | Codebase topic or codebase unknown. | Search patterns/architecture and return files/code examples. | `/paul:research` and `research-phase`: Task, Read, Bash, Write. |
| `general-purpose` research agent | Web/docs/comparison/best-practice topic. | Use WebSearch/WebFetch and return sourced findings. | Parent command exposes Task but not WebSearch/WebFetch; workflow assumes child capability. |
| Discovery research agents | Standard/deep decision research. | Compare options, cross-verify, confidence, DISCOVERY. | `/paul:discover` exposes WebSearch, WebFetch, Task, Read/Bash/Glob/Grep/Ask. |
| Map Agent 1 | Technology focus. | STACK + INTEGRATIONS. | Intended `Explore`, background. |
| Map Agent 2 | Organization focus. | ARCHITECTURE + STRUCTURE. | Intended `Explore`, background. |
| Map Agent 3 | Quality focus. | CONVENTIONS + TESTING. | Intended `Explore`, background. |
| Map Agent 4 | Issues focus. | CONCERNS. | Intended `Explore`, background. |
| Senior principal engineer + compliance reviewer | `/paul:audit`. | Six-part enterprise review, finding classification, PLAN mutation and AUDIT. | Same Claude context; no Task/subagent. |
| Debugger persona | Intended debug workflow. | Persistent evidence/hypothesis loop and verified fix. | No command/allowlist reaches it. |

Map agent definitions and their exact document allocation are in [`map-codebase.md` lines 81–93](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/map-codebase.md#L81-L93), [130–179](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/map-codebase.md#L130-L179), and [217–290](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/map-codebase.md#L217-L290). Research agent selection is explicit in [`research.md` lines 59–89](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/research.md#L59-L89).

**Policy inconsistency:** `/paul:research <topic>` normally spawns one agent, while the criteria require parallel value and say a single sequential task should remain in-session. The source does not reconcile this exception.

## 6. Installation, packaging, and reference resolution

### Executable install behavior

`bin/install.js`:

1. Accepts `--global/-g`, `--local/-l`, `--config-dir/-c`, and help; rejects global+local, missing config path, and config+local ([lines 30–53](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L30-L53), [197–210](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L197-L210)).
2. Expands only `~/` syntax, not Windows `~\` ([lines 84–92](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L84-L92)).
3. Destination precedence for global install is explicit CLI config, then `CLAUDE_CONFIG_DIR`, then home `.claude`; local always uses cwd `.claude` ([lines 122–137](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L122-L137)).
4. Recursively rewrites only the literal string `~/.claude/` in Markdown. Non-Markdown is byte-copied ([lines 94–117](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L94-L117)).
5. Copies commands to `commands/paul`; copies only templates, workflows, references, and rules to `paul-framework` ([lines 141–163](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L141-L163)). Existing same-named files are overwritten; there is no backup, transaction, rollback, or validation pass.
6. Recognizes known flags but does not reject unknown ones. `--config-dir=` normalizes to a falsy empty value and can fall through to the environment/default global directory; values containing another `=` are truncated by `split('=')[1]`. With no recognized location flag, the prompt defaults to global installation. These are fail-open argument paths, not explicit validation failures.

### Published package versus tracked tree

`package.json` allowlists `bin`, commands, templates, references, workflows, and rules, omitting `src/carl`, assets, IDEATION, and PAUL-VS-GSD ([`package.json` lines 8–15](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/package.json#L8-L15)). `npm pack --dry-run --json` confirmed 101 package entries: LICENSE, README, package.json, installer, and the 97 installable files. CARL and the three other omitted groups were absent.

### Existing smoke evidence verification

The existing `install-smoke` tree contains 97 files. Independent mapping of every source to its expected installed destination, followed by exact content comparison after applying only the installer's documented replacement, produced:

```text
EXPECTED=97 ACTUAL=97 MISSING=0 EXTRA=0 CONTENT_MISMATCH=0
```

Thus the retained references are not corruption in the prior smoke; they are faithful installer output.

### Full installed reference accounting

The existing `references.csv` has 274 unique `(Source, Line, Target)` rows. Independent validation found every source, line, and token present, every static `Exists` value correct, and no duplicate key:

| Class | Count | Interpretation |
|---|---:|---|
| Static, resolved | 73 | 69 custom-prefix references plus 4 valid framework-relative references. |
| Static, unresolved | 58 | Concrete `@src/...` paths retained after install. |
| Dynamic/example | 133 | 123 `.paul/` project-state paths plus 10 source/file placeholders or illustrative references. |
| Other | 10 | Package/import-like `@` tokens in codebase templates, not PAUL file references. |
| **Total** | **274** | Complete supplied scan, independently line/existence-validated. |

All 63 installed `@src/` tokens divide as follows:

| Source area | Concrete unresolved | Examples/placeholders | Execution relevance |
|---|---:|---:|---|
| Commands | 2 | 0 | Both directly break `map-codebase` delegation. |
| Workflows | 42 | 0 | All 42 are concrete workflow instructions/references. |
| Concept references | 3 | 4 | Two template-schema refs in `toml-sync` are execution-relevant; one self-reference is illustrative; four `context-management` paths are examples. |
| Maintainer rules | 11 | 0 | Concrete but illustrative authoring guidance; not reached by installed commands. |
| Templates | 0 | 1 | One illustrative command-authoring path. |
| **Total** | **58** | **5** | **46 high-confidence execution-relevant invalid installed edges (`2 + 42 + 2`).** |

The first-failure static graph affects 17 commands: add-phase, apply, complete-milestone, discover, discuss-milestone, discuss, flows, init, map-codebase, milestone, plan, register, remove-phase, research-phase, research, unify, verify. Eleven have no unresolved reference on their reachable static path: assumptions, audit, config, consider-issues, handoff, help, pause, plan-fix, progress, resume, status.

This does not prove every affected command fails at runtime: Claude may already have enough inline instructions, ignore a missing optional reference, infer a corrected path, or resolve `@src/...` against the working project. It proves the declared lazy-loading contract has no target in the distributed tree. For `map-codebase`, the missing installed path is the sole workflow delegate, so an entry-point failure is a strong inference, not a directly executed observation. Project-relative resolution could instead load an unrelated same-named project file; that path-shadowing behavior remains untested.

### Windows custom-path result

The independent test used a custom directory containing a space. All 73 installed `~/.claude/` occurrences changed; no original occurrence remained. A representative line was:

```text
@C:\Users\littl\AppData\Local\Temp\paul-independent-codex-019fc246\custom config/paul-framework/workflows/plan-phase.md
```

**Runtime observation:** normalizing that string as a Windows filesystem path reaches the installed file. **Unresolved:** the reference is unquoted, contains a space, and mixes backslashes with a trailing forward slash. Claude Code parsing was not exercised, so it is not proven usable as an `@` include.

### Root cause and history

Targeted `git log --follow` shows `bin/install.js` was introduced in the v0.1 core commit [`03676b22`](https://github.com/ChristopherKahler/paul/commit/03676b22cf3713b81ed5a00f7a0e7532be9675f0) and has no later change. `map-codebase` and its `@src` convention arrived later in [`44ba4ac5`](https://github.com/ChristopherKahler/paul/commit/44ba4ac505259e8f934772eb70af58267656607e); E/Q and quick-track arrived in [`a7c295e0`](https://github.com/ChristopherKahler/paul/commit/a7c295e0393a8871393af1a82c34b994612adb87); TOML templates/sync arrived in [`27afa851`](https://github.com/ChristopherKahler/paul/commit/27afa8519e9beaab46588d072711e2df5f2bc6ae) and [`04a496e4`](https://github.com/ChristopherKahler/paul/commit/04a496e4d84eed41337a81bcbea4349fc1163062). **Inference:** the distribution layout remained stable while later authoring/runtime references assumed a source layout; no install-time reference-validation gate caught the divergence.

## 7. Operations and lifecycle behavior

### Initialization and configuration

`/paul:init` hard-stops on a detected BASE v1 binary or `.base/data/*.json`, continues without BASE, can import PLANNING.md, gathers type-specific requirements one question at a time, and creates PROJECT/ROADMAP/STATE/TOML/ledger plus optional config/flows ([`init-project.md` lines 34–126](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/init-project.md#L34-L126), [483–533](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/init-project.md#L483-L533)). This workflow's four top references and later TOML refs use unresolved `@src` paths after install.

### Planning and approval

Scope routing is quick-fix only when the request fits one sentence, touches 1–2 files, and has no architecture impact; complex triggers on any of 6+ tasks, multiple subsystems, architecture decisions, or multiple roadmap concerns; standard is default. The user confirms/overrides classification ([`plan-phase.md` lines 51–80](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/plan-phase.md#L51-L80)). Quick plans omit boundaries, overall verification, success criteria, and skills ([lines 139–191](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/plan-phase.md#L139-L191)); standard/complex plans use the full schema. Every track gets a coherence check against PROJECT constraints, STATE decisions, recent file overlap, and ROADMAP scope.

### Apply, audit, verify, and fixes

- APPLY requires explicit plan approval and blocks on missing required skills, but permits a user `override` and logs the deviation ([`apply-phase.md` lines 30–86](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L30-L86)).
- Enterprise audit is optional/config-suggested or manually invoked. It is a PLAN sub-step, not an independent state. Must-have and strongly recommended findings are automatically written into the plan; “not acceptable” suppresses direct APPLY routing ([`audit-plan.md` lines 140–183](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/audit-plan.md#L140-L183), [250–301](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/audit-plan.md#L250-L301)).
- VERIFY explicitly makes the user perform manual UAT; Claude prepares the checklist and records results. It does not run automated tests ([`verify.md` lines 8–14](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/verify.md#L8-L14), [54–59](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/verify.md#L54-L59)).
- PLAN-FIX transforms recorded UAT issues into a narrow FIX plan, prioritizing blocker → major → minor → cosmetic and preserving passed functionality.

### Pause and resume

Pause creates a root handoff and STATE continuity, optionally registers it with `base`, and can create a WIP commit. Resume selects an explicit or latest handoff, reconciles it with STATE, recommends exactly one action, and only archives/deletes the handoff after work proceeds. The latest pinned change added `base handoff create` registration to both pause and the standalone handoff command ([commit `960b05c0`](https://github.com/ChristopherKahler/paul/commit/960b05c0b8e1f876f49674a700c9a087afebb8ac)). Registration failure is deliberately non-blocking.

### Phase and milestone operations

- Add/remove phase mutates ROADMAP/STATE; removal is restricted to future, not-started phases and preserves nonempty directories.
- Last-plan UNIFY must invoke transition, which compares PLAN/SUMMARY counts, evolves three state documents, deletes stale phase handoffs, can merge/delete a feature branch after asking, creates a phase commit, then performs a blocking cross-file consistency check ([`transition-phase.md` lines 23–60](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L23-L60), [181–263](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L181-L263), [265–319](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L265-L319)).
- Complete milestone aggregates all summaries, archives the roadmap slice, evolves PROJECT, updates STATE, verifies five version locations, and creates an annotated tag.

## 8. Safe tests and runtime evidence

All commands ran from the pinned clone unless a test cwd is stated. The temporary root was `C:\Users\littl\AppData\Local\Temp\paul-independent-codex-019fc246` and was deleted after exact-path validation.

| Exact command | Exit | Result / root cause |
|---|---:|---|
| `& C:\Users\littl\.agents\tools\work-state-preflight.ps1 -RepositoryPath (Get-Location).Path -OutputFormat Markdown` | 0 | Pin/branch/upstream/clean/no-PR gate confirmed. |
| `node bin/install.js --help` | 0 | Usage/options/install layout printed. |
| `node bin/install.js --global --local` | 1 | Correct explicit error: cannot specify both. |
| `node bin/install.js --global --config-dir` | 1 | Correct explicit error: config path required. |
| `node bin/install.js --local --config-dir C:\Users\littl\AppData\Local\Temp\paul-independent-codex-019fc246\not-used` | 1 | Correct explicit error: custom config cannot be combined with local. |
| `node bin/install.js --help --definitely-unknown` | 0 | Unknown option was silently ignored; help printed with no diagnostic. Source inspection also shows empty `--config-dir=` can fall through and embedded `=` is truncated. |
| From `...\local project`: `node <repo>\bin\install.js --local` | 0 | 97 files: 28 commands, 69 framework; 73 `./.claude/` replacements; 0 home refs; 63 `@src` retained. |
| `node bin/install.js --global --config-dir "C:\Users\littl\AppData\Local\Temp\paul-independent-codex-019fc246\custom config"` | 0 | 97 files; 73 custom-prefix replacements; 0 home refs; 63 `@src` retained; CARL absent. |
| `npm pack --dry-run --json` | 0 | 101 package entries; no CARL/assets/IDEATION/PAUL-VS-GSD. |
| Full expected-to-existing-smoke comparison (PowerShell content replacement + exact content/hash checks) | 0 | `EXPECTED=97 ACTUAL=97 MISSING=0 EXTRA=0 CONTENT_MISMATCH=0`. |
| Full `references.csv` source/line/token/existence/duplicate validation | 0 | `ROWS=274 BAD_SOURCE=0 BAD_LINE=0 BAD_TARGET=0 BAD_EXISTS=0 DUPLICATE_KEYS=0`. |
| Independent installed-tree `@src` scan and resolution | 0 | 63 tokens; 58 concrete; `CONCRETE_RESOLVED=0`, `CONCRETE_UNRESOLVED=58`. |
| `[System.IO.Directory]::Delete('C:\Users\littl\AppData\Local\Temp\paul-independent-codex-019fc246',$true)` | 0 | Temp evidence removed; `EXISTS_AFTER=False`. |

Harness/tooling failures retained for transparency:

- The first all-in-one setup/test/recursive-cleanup shell call was rejected by command policy before execution; it had no process exit code and made no file.
- `New-Item -ItemType Directory -LiteralPath <temp>` returned shell exit 0 but emitted a non-terminating PowerShell parameter error because `New-Item` uses `-Path`, not `-LiteralPath`; `CREATED=False`. Re-run with `-Path` and `$ErrorActionPreference='Stop'` succeeded.
- `Remove-Item -Recurse -Force -LiteralPath <verified-temp>` was rejected by command policy before execution. After a separate `Resolve-Path`, prefix, and file-count check, the exact .NET directory deletion above succeeded.
- `rg -n 'auto-migrate|paul\.json|ledger\.toml' src/workflows/*.md` exited 1 because native `rg` on Windows received the unexpanded wildcard (OS error 123). Re-running against directory `src/workflows` exited 0.

Not tested: interactive no-argument installer (would prompt), default global install (would touch the user's live Claude config), actual Claude Code command execution, Claude Code `@` parsing, BASE, CARL, SonarQube, MCP, web research, git mutation workflows, and any paid/credentialed service.

## 9. Security, destructive operations, and failure behavior

### Installer trust boundary

- `--config-dir` and `CLAUDE_CONFIG_DIR` are accepted as arbitrary paths. There is no destination allowlist, path normalization check, symlink defense, preflight collision report, confirmation when overwriting, backup, staging directory, atomic rename, rollback, or post-copy reference validation.
- Markdown replacements embed the destination path verbatim. A path containing whitespace or syntax-significant text enters every static reference without quoting/escaping.
- Existing matching files are overwritten by `writeFileSync`/`copyFileSync`. An exception stops Node but may leave a partially updated tree.
- The package has no runtime third-party dependencies; installer imports only Node `fs`, `path`, `os`, and `readline`. That reduces supply-chain surface but does not address destination integrity.

### Prompt workflow trust boundary

- Many commands allow broad Bash and file-write tools. PLAN boundaries and checkpoints are prompt instructions, not OS-level controls.
- Commands and workflows load repository-controlled `.paul/*`, plans, summaries, source files, and sometimes web/research output into a tool-capable model context. These are untrusted data, but the framework provides no executable instruction/data separation, sanitization, or prompt-injection boundary; XML/frontmatter are conventions only.
- The invalid installed `@src/...` edges may be more than missing files: if Claude resolves them against the working project, a same-named project path could shadow the intended framework resource and become instructions. Actual parser/root behavior was not executed, so this is a residual risk rather than a demonstrated exploit.
- Transition can delete handoffs, checkout/merge main, delete a branch, stage source/state, and commit. Merge asks for consent; the phase commit is part of normal transition and not separately approved.
- Complete-milestone creates a tag as routine behavior.
- Map refresh says to delete `.paul/codebase/`; resume may archive or delete handoffs; JSON migration deletes `paul.json`; remove-phase deletes only an empty phase directory. Recovery/backup contracts are inconsistent.
- The quality principles allow automatic bug, security/correctness, and blocker fixes during APPLY, asking only for architectural changes ([`quality-principles.md` lines 116–126](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/quality-principles.md#L116-L126)). This is wider mutation authority than a strict plan-only interpretation and should be narrowed in an adaptation.
- Authentication is handled as a blocking human gate, but there is no general secret-redaction/logging policy in command/workflow/rule files. SonarQube documentation mentions authentication tokens only indirectly and does not define storage hygiene.

### Failure behavior

Positive patterns:

- APPLY reports concrete statuses, fresh verification, explicit retry/skip/stop, and refuses to mark a failed verification complete.
- State consistency is a blocking transition gate.
- Research requires confidence/source quality and distinguishes unknowns.
- Partial init reports created versus failed items.

Weak patterns:

- Several workflows say “skip silently” when no manifest exists, hiding lost BASE/ledger integration.
- Install has no structured error wrapper, cleanup, or recovery output.
- Installer option parsing is fail-open for unknown flags, empty equals-form config paths, and values containing another `=`; a mistyped location flag can fall through to an interactive prompt whose default is global.
- Prompt-level execution can continue through missing references by inference, creating nondeterministic behavior rather than a crisp failure.
- Audit says every plan has areas to strengthen while also saying no findings is valid, an internal incentive conflict ([`audit-plan.md` lines 326–343](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/audit-plan.md#L326-L343)).

## 10. Documentation and executable drift

| Claim | Classification | Installed/source reality |
|---|---|---|
| “Works on Mac, Windows, Linux” ([README lines 13–18](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L13-L18)). | Author claim, partially observed | Windows copying succeeds, but custom refs are unquoted/mixed-separator and `@src` breaks independent of OS. |
| README: 26 commands ([line 176](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L176-L176)). | Direct drift | 28 command files installed. README tables omit `register` and `audit`. |
| Help footer: 23 commands, 14 workflows, 13 templates ([help line 525](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/help.md#L525-L525)). | Direct drift | 28 / 23 / 27. |
| `/paul:quality-gate` can run SonarQube ([Sonar ref lines 92–102](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/sonarqube-integration.md#L92-L102)). | Runtime gap | Workflow exists, command file does not. Config points users to a nonexistent slash command. |
| Rules use CARL dynamic loading ([README lines 494–505](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L494-L505)). | Distribution gap | CARL is neither npm-packed nor installed; manual CARL command path is also wrong for installed layout. |
| “Any PAUL workflow” auto-migrates JSON and workflows update TOML on every state change ([README lines 438–444](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L438-L444)). | Overstatement | Six workflows implement sync; verify/pause/resume matrix entries are absent. |
| Ledger records every PAUL action ([README lines 440–442](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L440-L442)). | Overstatement | No ledger append in verify, pause, resume, audit, issue/discussion/discovery/research/map/config flows. |
| Boundaries in every PLAN ([PAUL-VS-GSD lines 89–97](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/PAUL-VS-GSD.md#L89-L97)). | Direct drift | Quick-fix plans explicitly omit boundaries. |
| Required skills are enforced/block APPLY ([README lines 458–460](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L458-L460)). | Mostly implemented, qualified | APPLY blocks but offers `override`; UNIFY only warns. Quick-fix plans omit skills entirely. |
| “Automated audits don't [get skipped]” ([PAUL-VS-GSD lines 101–109](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/PAUL-VS-GSD.md#L101-L109)). | Author claim | Skill audit is a manual review of session context; no hook records invocation. |
| “~70% quality” and 2–3k token launch cost ([README lines 403–413](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L403-L413)). | Unsupported author estimate | No benchmark, methodology, dataset, or test is present. |
| IDEATION build-log/content pipeline. | Clearly future | Correctly labeled ideation; no current runtime implementation. |

GSD comparisons are positioning by this repository's author, not facts established by PAUL source. They should remain labeled as opinions unless checked against a pinned GSD release.

## 11. Reusable patterns and adaptation guidance

### High-value patterns with provenance

1. **Plan–Apply–Unify artifact loop.** Preserve explicit approval, plan/actual reconciliation, and immediate summary/state update. Provenance: [`loop-phases.md` lines 20–43](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L20-L43), [122–148](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L122-L148).
2. **Execute/Qualify independent reread.** Status first, then re-read actual output, run verification fresh, compare to spec and AC, score PASS/GAP/DRIFT. Provenance: [`apply-phase.md` lines 103–160](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L103-L160).
3. **Failure-layer classification.** Diagnose intent versus spec versus implementation before patching. Provenance: [`checkpoints.md` lines 135–156](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/checkpoints.md#L135-L156).
4. **Thin entry / deep workflow / reference / template split.** Separates UX, procedure, concepts and output contract. Tradeoff: every path becomes a deployment contract and must be validated after packaging.
5. **Scope-adaptive ceremony.** Quick/standard/complex preserves the loop while tuning artifact weight. Adaptation should keep boundaries even in quick mode if protected areas exist.
6. **One-next-action routing and explicit handoffs.** Useful for cold resumes and reduced decision fatigue; archive only after confirmed consumption.
7. **State snapshot plus append-only ledger.** Separate current truth from event history; implement both in code with schema validation and atomic writes rather than prose instructions.
8. **Specialized-flow lifecycle.** Declare → annotate phase → inject into plan → gate APPLY → audit UNIFY. Replace conversation-memory checks with explicit invocation records.
9. **Research quality controls.** Enumerate scope, prefer primary sources, cite exact URLs/versions, expose confidence and negative-claim limits.
10. **Stable extension points.** Post-core comment-block injection is simple and inspectable; add versioned manifests, idempotency, and an integration test.

### Adaptation steps

1. Choose one canonical installed namespace, e.g. `paul-framework/...`; ban `src/...` in runtime artifacts.
2. Represent the command/workflow/reference graph as data or validate every Markdown `@` edge in CI against the staged npm package.
3. Stage installs in a temporary sibling, validate counts/references/frontmatter, then atomically swap; report collisions and preserve backups.
4. Quote/escape or URI-normalize generated reference paths and test Windows paths with spaces, Unicode, drive letters, UNC, and both separator styles using the actual Claude Code parser.
5. Add command entry points for intended workflows or remove claims: `quality-gate`, `debug`; repair `map-codebase` and resume XML.
6. Make tool allowlists transitive. In particular, UNIFY must have the tools required by mandatory transition or transition must be a separately invoked command with its own allowlist/approval.
7. Define state schemas and idempotent transitions in executable code. Validate PROJECT/ROADMAP/STATE/TOML together before writing.
8. Make destructive/git actions opt-in with exact target, dry run, recovery plan, and read-back. Do not bake automatic commits/tags into ordinary reconciliation.
9. Record subagent/skill invocations in a ledger rather than inferring them from conversation.
10. Reconcile docs/counts from generated inventory during release.

### MIT treatment and clean-room options

The license permits use, copying, modification, merging, publication, distribution, sublicensing, and sale, conditioned on including the copyright and permission notice in all copies or substantial portions; the software is provided without warranty ([`LICENSE` lines 5–20](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/LICENSE#L5-L20)).

- **Direct reuse/adaptation:** retain the complete MIT notice and Chris Kahler copyright in distributed copies/substantial portions. Keep a provenance file mapping copied/adapted assets to this commit. Avoid implying endorsement.
- **Pattern-only clean room:** have one person write a behavior-level specification from the abstract patterns above without copying prompt text, examples, diagrams, filenames, branding, or distinctive prose; have another implement fresh schemas/wording/tests. Preserve dated design notes and independent acceptance tests. A clean-room process reduces expression-copying risk but is not a legal opinion.
- **Tradeoff:** direct reuse is faster and permitted but carries path/docs defects and attribution duties; clean-room implementation costs more but can replace prompt-only controls with deterministic, testable code.

## 12. Weaknesses, risks, and unresolved items

### Highest-priority weaknesses

1. **P0 distribution graph defect:** 58 concrete unresolved static paths; 46 execution-relevant; 17 commands affected. Runtime failure is inferred because actual Claude `@` parsing was not executed.
2. **P0 map-codebase missing delegate:** its only procedural delegate has no distributed target; entry-point failure under expected resolution semantics remains an inference.
3. **P1 CARL distribution/path break:** CARL claims are not realized by npm/install, and manual command path is invalid.
4. **P1 no staged/validated install:** silent overwrite and partial-tree risk.
5. **P1 prompt-only guarantees:** approvals, boundaries, mandatory transitions and skill use have no independent enforcement in the installed package.
6. **P1 transitive tool mismatch:** UNIFY's mandatory transition requires tools absent from its command allowlist.
7. **P1 state/ledger drift:** documentation and trigger matrix exceed actual workflow sync coverage.
8. **P2 orphan workflows:** quality-gate/debug lack commands; map workflow has no valid incoming installed edge.
9. **P2 schema/style drift:** missing command frontmatter, four workflows missing required `<when_to_use>`, malformed resume process closure, inconsistent context brackets/counts.
10. **P2 destructive defaults:** commits/tags/cleanup are embedded in workflows without a unified approval/recovery contract.

### Unresolved items

- Whether Claude Code accepts unquoted Windows `@` references with spaces and mixed separators, which root it uses for relative `@src/...` paths, and whether a working-project path can shadow the missing framework resource.
- Whether Claude Code's command loader accepts `config.md` and `map-codebase.md` without frontmatter in the intended version, and what default tool permissions result.
- Whether a child `general-purpose` Task receives WebSearch/WebFetch when the parent command's allowlist does not list them.
- Whether `allowed-tools` restrictions remain in force across nested loaded workflows and thereby block UNIFY transition Bash/git steps.
- Whether external BASE/CARL installers, not present here, relocate or rewrite these files and mitigate any distribution defect.
- GSD-side comparison accuracy and all quantitative quality/token claims.
- SonarQube MCP operation names/current compatibility; no live service or credentials were used.

## 13. Evidence index

### Local supplied evidence

- Inventory: `work/inventory/christopherkahler-paul-files.csv` — 108 rows, hashes/categories/gear flags.
- Snapshot state: `work/state/christopherkahler-paul.md` — pin and clean-state record.
- Installed tree: `work/evidence/christopherkahler-paul/install-smoke` — 97 faithful installed files.
- Reference scan: `work/evidence/christopherkahler-paul/references.csv` — 274 validated rows.

### Critical pinned-source citations

- Installer path replacement and copy layout: [`bin/install.js` lines 94–163](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L94-L163).
- Package allowlist: [`package.json` lines 5–15](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/package.json#L5-L15).
- Broken map command paths: [`src/commands/map-codebase.md` lines 1–12](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/map-codebase.md#L1-L12).
- CARL broken installed-command path: [`src/carl/PAUL` lines 6–15](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/carl/PAUL#L6-L15).
- Loop and E/Q: [`src/references/loop-phases.md` lines 51–105](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L51-L105).
- Mandatory UNIFY transition: [`src/workflows/unify-phase.md` lines 245–269](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/unify-phase.md#L245-L269).
- Transition state consistency: [`src/workflows/transition-phase.md` lines 265–319](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L265-L319).
- Subagent criteria: [`src/references/subagent-criteria.md` lines 9–100](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L9-L100).
- Manifest/ledger/migration: [`src/references/toml-sync.md` lines 11–85](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/toml-sync.md#L11-L85), [102–180](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/toml-sync.md#L102-L180).
- License: [`LICENSE` lines 1–20](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/LICENSE#L1-L20).

### Final source-state note

The analysis clone was read-only throughout. A final work-state preflight and report-link/coverage validation are recorded in the handoff summary returned with this report.

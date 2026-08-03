# Cross-framework synthesis notes

## Normalized comparison axes

| Candidate | Canonical source | State model | Agent model | Adapter/materialization model | Strongest evidence-backed patterns | Main operational risk |
|---|---|---|---|---|---|---|
| GitHub Spec Kit | Markdown/YAML/templates/scripts plus Python IR | `.specify` project state and durable workflow runs | Host agent executes rendered commands/skills; workflow engine coordinates steps | 37 integration IDs, extensions, presets, bundles, native event adapters | canonical IR, hash-owned files, preview=install plan, event dispatcher, human gates, safe archive/path handling | raw shell interpolation; advisory capabilities; partial transactions; large extension/preset monoliths |
| Fission OpenSpec | typed TypeScript workflow/artifact model and schemas | filesystem-derived artifact DAG, stores, references, worksets | Host agent follows generated skills; CLI owns artifact operations | profiles negotiate desired workflow versus host delivery capability | artifact DAG, root provenance, instruction data separation, reference index, preview-before-merge, generated parity | tests touch real user config; project constraints can be silently omitted; prompt compliance is the enforcement boundary |
| open-gsd/gsd-core | Claude-flavored canonical command/agent Markdown, workflows, descriptors and TypeScript/CommonJS core | `.planning` file-backed project state plus pure transition intents, loop contribution state and worktree manifests | 34 specialist agents, producer/checker pairs, bounded retries and operator checkpoints | 19 runtime descriptors project canonical material into commands, skills, TOML, JSON, rules, plugins and extensions | descriptor registry, 12-point contribution bus, consent-bound extensions, manifest-scoped worktrees, generated drift gates | 13.5k-line installer; shallow six-family manifest; fail-open hooks; advisory injection scans; prose/runtime-count drift |
| ChristopherKahler/paul | Markdown command/workflow/reference/template corpus | `.paul` plans, state, roadmap, ledgers, handoffs | one Claude session plus prompt-selected personas/subagents | installer copies command/framework trees and rewrites only `~/.claude/` | simple PLAN→APPLY→UNIFY loop, artifact contracts, context/handoff discipline | 58 broken installed static `@src` refs; 17/28 command paths affected; CARL not distributed; prompt-only enforcement |
| BMAD-METHOD | canonical skill packages, workflow steps, TOML customization, Python/Node tools | project artifacts, sprint/story status, content-addressed workflow snapshots, memlog | five named personas plus mandatory/synchronous subagent protocols | 45 host profiles; shared targets deduplicated; native skills everywhere; auxiliary pointers only for configured hosts | content-addressed snapshots, layered structural customization, ownership-aware install, typed review algebra, atomic state | dependency-install failure can continue; very broad compatibility surface; prompt/tool trust; Windows test blind spots |

## Recommended vendor-neutral layer model

### Global

- `CapabilityRegistry`: canonical roles, steps, tools, event types, schemas and versions.
- `AdapterRegistry`: platform capability declarations, target paths and renderers.
- `TrustPolicy`: source trust, hashes/signatures, network rules, shell/tool permissions, secret handling.
- `PackageCatalog`: built-in and organization-approved packages separated from discovery-only community metadata.

### Project

- `FrameworkManifest`: pinned framework/schema version, selected packages, selected adapters and ownership.
- `ArtifactGraph`: goals/spec/design/tasks/implementation/evidence/review/archive nodes and dependency readiness.
- `WorkflowDefinitions`: typed canonical workflow IR plus project overlays.
- `RoleDefinitions`: mission, inputs/outputs, tools, write scope, memory and escalation.
- `ProjectStateStore`: human-readable durable state, artifact hashes, ownership manifest and migration journal.
- `GeneratedSurface`: platform-native skills/commands/hooks with provenance and content hashes.

### Session

- `RunEnvelope`: run/correlation IDs, pinned config/artifact versions and initiating event.
- `ProgramCounter`: current step, branch/loop/fan-out state, attempts and deadlines.
- `ContextManifest`: selected artifacts, references, token budget and provenance delimiters.
- `ApprovalLedger`: requested/accepted/rejected gates; non-interactive mode must pause.
- `EvidenceLog`: append-only observations, tool calls, outputs, findings and decisions.

### Local

- `ExecutionSandbox`: disposable worktree/copy, scoped environment and allowed side effects.
- `Cache`: content-addressed immutable render and package cache.
- `Locks`: project/run/workset mutation locks with stale-lock diagnostics.
- `Scratch`: ephemeral intermediate files excluded from canonical project state.

## Canonical workflow algebra

- `Sequence(steps)`
- `AgentStep(role, instruction, inputs, outputs)`
- `ToolStep(command, capability, timeout, retry_policy)`
- `Gate(condition, on_accept, on_reject)`
- `HumanApproval(prompt, choices, pause_noninteractive=true)`
- `Branch(expression, cases, default)`
- `Loop(body, max_iterations, termination_condition)`
- `FanOut(items, concurrency, template)` + `FanIn(strategy)`
- `ArtifactWrite(schema, target, preconditions, atomic=true)`
- `Checkpoint(state, evidence)`
- `EmitEvent(type, payload)`

Safety-critical validation is duplicated at ingestion and execution. Every loop is bounded and has an explicit terminal state. Every side-effecting step declares capability, scope, timeout, retryability, idempotency key and compensation/recovery behavior.

## Canonical lifecycle

`Discover → Specify → Clarify → Plan → Decompose → Execute → Verify → Review → Converge → Archive`

Side entries: `Explore`, `Audit`, `Debug`, `CorrectCourse`, `Resume`, `Migrate`, `Recover`.

Terminal states: `done`, `blocked`, `rejected`, `paused`, `failed`, `superseded`, `archived`.

## Adapter compiler transaction

1. Load canonical packages and pinned schemas.
2. Resolve Global→Project→Session→Local precedence without mutating inputs.
3. Validate references, capabilities, paths and trust policy.
4. Produce a pure `MaterializationPlan` used by preview and execution.
5. Render into staging; never expand inserted text transitively.
6. Hash every artifact and compare ownership manifest.
7. Reject traversal/symlink/unowned overwrite.
8. Atomically publish the staged tree and journal the transaction.
9. Run adapter contract/parity tests and runtime smoke.
10. Commit the new ownership manifest only after verification; otherwise restore the previous generation.

## Initial pattern ranking for later adoption

1. OpenSpec artifact DAG and root provenance — best clean foundation for transparent, tool-session-independent state.
2. Spec Kit canonical IR, materialization ownership and security utilities — strongest hardened operational substrate.
3. BMAD content-addressed execution packets and layered customization — best selective source for reproducible roles/workflows.
4. Paul PLAN→APPLY→UNIFY semantics — easiest process vocabulary to understand and rephrase, but its installer/runtime cannot be reused unchanged.
5. GSD descriptor registry, contribution bus and worktree manifest — extremely capable reference architecture, but the 2,730-file/13.5k-line-installer surface makes direct adoption the least economical; copy isolated contracts only.

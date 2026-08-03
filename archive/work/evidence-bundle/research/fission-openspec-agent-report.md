# Fission OpenSpec: exhaustive agent-architecture research report

## 1. Snapshot and provenance

| Field | Value |
|---|---|
| Repository | `Fission-AI/OpenSpec` |
| Local checkout | `work/repos/fission-openspec` |
| Branch | `main` |
| Pinned commit | `45cca5db6137ed209117cc70510eb3e057fb981b` |
| Commit subject | `fix(specs): warn before archiving deletes a note next to a requirement (#1490)` |
| Commit time | authored 2026-07-30; committed 2026-07-31 |
| Nearest tag | `v1.7.0-7-g45cca5d` |
| Package | `@fission-ai/openspec` 1.7.0, ESM, Node `>=20.19.0` |
| License | MIT |
| Initial worktree state | clean; `main` at the pinned commit and tracking `origin/main` |
| Initial state evidence | `WORK_STATE` preflight at `2026-08-02T12:31:46.4267172Z`; local Git plus remote/PR lookup |
| Pull-request observation | remote lookup reported merged PR `#1276`; this is state context, not evidence about the pinned commit's implementation |

Evidence notation:

- **Source fact**: directly observed in the pinned checkout.
- **Author claim**: prose asserted by repository documentation; checked against source where material.
- **Runtime evidence**: a command actually executed in this checkout during this research.
- **Inference**: an architectural or operational conclusion drawn from multiple facts; explicitly labeled.

Immutable source citations use `[45cca5d:path:Lx-Ly]`. The repository itself was the relevant primary source, so Context7 and external documentation were intentionally omitted. External links were inventoried but not live-checked.

### Repository census

**Runtime evidence.** `git ls-files` returned 1,041 tracked files. A full local file/newline census found:

| Area | Files | Newline-counted lines | Coverage note |
|---|---:|---:|---|
| `openspec/` | 604 | 43,279 | current specs, 19 active changes, 83 archived changes, initiatives, experimental work |
| `src/` | 178 | 32,895 | CLI, core state/graph/store logic, adapters, command generation, telemetry |
| `test/` | 130 | 40,754 | CLI E2E, command/core/integration/security/telemetry tests and fixtures |
| `website/` | 32 | 5,456 | generated-doc site, router, synchronization tooling |
| `docs/` | 26 | 5,568 | user, workflow, CLI, store, agent-contract and operational documentation |
| `skills/` | 13 | 1,843 | 12 published workflow skills plus README/parity material |
| `scripts/` | 9 | 698 | generation, parity, postinstall, packaging and Nix maintenance |
| `.changeset/` | 7 | 101 | pending release notes |
| `.github/` | 6 | 611 | CI, release and security automation |
| `schemas/` | 5 | 211 | packaged `spec-driven` schema and templates |
| `assets/` | 4 | 3,273 | repository media/artwork |
| `.agents/` | 3 | 196 | repository-maintainer release skill |
| `.devcontainer/` | 2 | 122 | development container configuration |
| Top-level files | 21 | 4,118 | package/build/config/license/readme files and lockfile |
| `bin/` | 1 | 3 | executable shim |
| **Total** | **1,041** | **139,128** | every tracked path included |

By extension, the major populations were 636 Markdown files (52,366 lines), 315 TypeScript files (73,817), 39 YAML files (6,564), 10 TSX files (868), 9 MJS files (674), 6 JSON files (261), 5 JavaScript files (217), and 4 YML files (597). The large Markdown count is mostly change/spec history, not runtime prompt code.

The reproducible semantic ledger contains one row for every one of the 1,036 gear candidates: 1,035 source/config/spec/test/documentation artifacts are `analyzed`, while `flake.lock` is `runtime-relevant-generated`. Every row records its exact SHA-256, size, line count, owning semantic subsystem, terminal class and immutable whole-file evidence locator. The five excluded non-gears are the four media assets under `assets/` and `website/app/icon.svg`. This is exhaustive per-file classification and hash closure; detailed claims still rely on the narrow source citations in this report. See `work/evidence/fission-openspec/semantic-ledger.csv`, generated reproducibly by `work/evidence/fission-openspec/generate-ledgers.mjs`.

The package boundary is intentionally smaller than the repository: npm publishes only `dist`, `bin`, `schemas`, and `scripts/postinstall.js`, excluding compiled tests, test directories and source maps [45cca5d:package.json:L24-L40]. A successful `npm pack --ignore-scripts --dry-run` observed 366 files, 384.5 kB compressed and 1.6 MB unpacked; this observed result is recorded in the runtime-verification table and its evidence notes below.

## 2. Executive summary

OpenSpec is a local-first TypeScript CLI that turns a declarative artifact graph into agent-consumable instructions and installs those instructions as either Agent Skills, tool-native command files, or both. The principal architecture is not a resident agent runtime. It is a **workflow compiler and state reader**: YAML defines artifacts and dependencies; file existence determines completion; the CLI emits status/instruction payloads; the surrounding AI tool performs the authored steps; and subsequent CLI invocations recompute state from disk.

The default graph is proposal → specs and design → tasks → apply. Six core workflows (`propose`, `explore`, `apply`, `update`, `sync`, `archive`) form the default profile; six additional workflows (`new`, `continue`, `ff`, `bulk-archive`, `verify`, `onboard`) form the `all` profile [45cca5d:src/core/profiles.ts:L14-L50]. These 12 workflows are rendered into committed skills and, where a tool adapter exists, tool-specific command files. A separate `.agents` release skill controls repository-maintainer release work and should not be confused with the product workflow set.

The most reusable ideas are:

1. keep workflow state in plain files and recalculate readiness rather than persisting an opaque agent state machine;
2. generate all tool surfaces from one canonical workflow body and one typed adapter registry;
3. separate project context, artifact-specific rules and operation guidance in machine-readable instruction payloads;
4. treat store/reference/workset metadata as distinct scopes with deterministic root selection;
5. encode destructive archive behavior as a preview/validate/confirm/apply pipeline;
6. parity-test generated skills against canonical bodies.

The implementation is broad and substantially tested. Runtime verification produced a clean build, typecheck, lint, focused parity tests, strict validation of all 36 current specs, a high-severity production dependency audit with no known vulnerabilities, and a fully passing isolated test suite: 119/119 files, 3,450 passed tests and 24 conditional skips. The harness pinned pnpm 9.15.9, disabled telemetry, capped workers at two, and redirected all APPDATA/XDG config/data roots (`work/evidence/fission-openspec/full-suite-20260802.md`). The main concrete source defect remains test isolation: an unqualified full test run printed the first-run telemetry notice into a subprocess test's stdout, failed one raw-output assertion, and created a real `%APPDATA%\openspec\config.json`. Even an earlier opt-out-only run recreated that file from telemetry-specific tests. Both artifacts were inspected and removed. The externally isolated green run proves safe execution under a controlled harness; it does not fix the repository's default global-user-state leak.

## 3. Exhaustive gear inventory

### 3.1 Packaging and executable surface

| Gear | Source of truth | Function |
|---|---|---|
| npm executable | `bin/openspec.js` | Thin ESM shim importing `runCli()` from compiled `dist/cli/index.js` [45cca5d:bin/openspec.js:L1-L5] |
| build | `build.js` | Resolves the project-local TypeScript compiler, deletes `dist`, compiles, and exits nonzero on failure [45cca5d:build.js:L9-L30] |
| package contract | `package.json` | ESM package, public npm publication, Node 20.19+, pinned pnpm 9.15.9, CLI/export mappings [45cca5d:package.json:L19-L32] [45cca5d:package.json:L62-L85] |
| CLI framework | Commander | Root command, global color handling, pre/post hooks and subcommand registry [45cca5d:src/cli/index.ts:L118-L146] |
| interactive UI | Inquirer, Chalk, Ora | prompts, styled output and spinners |
| filesystem/schema | fast-glob, YAML, Zod | output globbing, schema/config parsing and validation |
| subprocess boundary | `cross-spawn` / Node child process | Git, package-manager upgrade and validation subprocesses; arguments are passed as arrays rather than shell-concatenated strings |
| release | Changesets | package versioning/publication; pack-version verification runs before publish [45cca5d:package.json:L42-L60] |

The CLI registers these top-level surfaces: `init`, `update`, `list`, `view`, deprecated `change`, `archive`, deprecated `spec`, `config`, `schema`, `store`, `doctor`, `context`, `workset`, `validate`, `show`, `feedback`, `completion`, hidden `__complete`, `status`, `instructions`, `templates`, `schemas`, and `new change` [45cca5d:src/cli/index.ts:L155-L195] [45cca5d:src/cli/index.ts:L218-L428] [45cca5d:src/cli/index.ts:L430-L557] [45cca5d:src/cli/index.ts:L563-L658].

Machine-readable failures go through `failWithError`: JSON mode emits a single document, retains an actionable diagnostic/fix when available, and sets failure status; human mode uses spinner/error output [45cca5d:src/cli/index.ts:L68-L92]. The hidden completion surface is a deliberate exception: it catches completion errors and returns exit 1 without a diagnostic, trading shell-completion quietness for observability [45cca5d:src/cli/index.ts:L545-L556].

### 3.2 Supported AI targets and delivery modes

`AI_TOOLS` contains **35 targets**. Each has a display name and skills directory [45cca5d:src/core/config.ts:L22-L64]. Two independent axes control materialization. The machine-level requested `Delivery` is `skills`, `commands`, or `both` and defaults to `both` [45cca5d:src/core/global-config.ts:L10-L33]. Per target, `CommandSurfaceCapability` is `adapter-backed`, `skills-invocable`, or `none` [45cca5d:src/core/command-surface.ts:L5-L27]. Generation combines these axes: adapter-backed tools can receive command files unless delivery is skills-only; normal tools receive skills unless delivery is commands-only; Codex remains skill-generated even in commands-only mode because it is explicitly skills-invocable [45cca5d:src/core/command-surface.ts:L29-L42].

There are **28 command adapters**:

| Target | Generated command path/pattern | Invocation convention |
|---|---|---|
| Amazon Q | `.amazonq/prompts/opsx-<id>.md` | `@opsx-<id>` |
| Antigravity | `.agent/workflows/opsx-<id>.md` | flat command |
| Auggie | `.augment/commands/opsx-<id>.md` | flat |
| Bob | `.bob/commands/opsx-<id>.md` | flat |
| Claude | `.claude/commands/opsx/<id>.md` | namespaced `/opsx:<id>` |
| Cline | `.clinerules/workflows/opsx-<id>.md` | flat |
| CodeBuddy | `.codebuddy/commands/opsx/<id>.md` | namespaced |
| Continue | `.continue/prompts/opsx-<id>.prompt` | flat |
| CoStrict | `.cospec/openspec/commands/opsx-<id>.md` | flat |
| Crush | `.crush/commands/opsx/<id>.md` | namespaced |
| Cursor | `.cursor/commands/opsx-<id>.md` | flat |
| Devin | `.devin/workflows/opsx-<id>.md` | flat |
| Factory | `.factory/commands/opsx-<id>.md` | flat |
| Gemini | `.gemini/commands/opsx/<id>.toml` | namespaced/TOML |
| GitHub Copilot | `.github/prompts/opsx-<id>.prompt.md` | flat |
| iFlow | `.iflow/commands/opsx-<id>.md` | namespaced |
| Junie | `.junie/commands/opsx-<id>.md` | flat |
| Kilo Code | `.kilocode/workflows/opsx-<id>.md` | flat |
| Kiro | `.kiro/prompts/opsx-<id>.prompt.md` | flat |
| Lingma | `.lingma/commands/opsx/<id>.md` | namespaced |
| Oh My Pi | `.omp/commands/opsx-<id>.md` | flat |
| OpenCode | `.opencode/commands/opsx-<id>.md` | flat |
| Pi | `.pi/prompts/opsx-<id>.md` | flat |
| Qoder | `.qoder/commands/opsx/<id>.md` | namespaced |
| Qwen | `.qwen/commands/opsx-<id>.md` | namespaced |
| Roo Code | `.roo/commands/opsx-<id>.md` | namespaced |
| Trae | `.trae/commands/opsx-<id>.md` | flat |
| ZCode | `.zcode/commands/opsx-<id>.md` | flat |

The seven configured targets without a command adapter are CodeArts, Codex, ForgeCode, Hermes, Kimi, Mistral Vibe and shared `.agents`. Under `skills` or the default `both`, the six non-Codex/no-adapter targets receive skills; under `commands` they receive no usable generated surface and their skills are removed. Codex is the exception: it remains skill-generated under `commands` because the host can invoke installed skills [45cca5d:src/core/command-surface.ts:L17-L38]. The registry imports and registers all 28 adapters in one place [45cca5d:src/core/command-generation/registry.ts:L1-L73]. Canonical `/opsx:<id>` references are rewritten for the selected adapter rather than duplicated in every prompt [45cca5d:src/core/command-generation/generator.ts:L14-L37]; invocation formatting explicitly distinguishes namespaced, flat and `@` forms [45cca5d:src/core/command-generation/invocation.ts:L4-L22] [45cca5d:src/core/command-generation/invocation.ts:L56-L99]. YAML-bearing adapters quote and escape control characters consistently [45cca5d:src/core/command-generation/yaml.ts:L9-L40].

### 3.3 Workflow skills and personas

The 12 product workflows are mapped to both skill and command metadata in the shared generation module [45cca5d:src/core/shared/skill-generation.ts:L59-L106]. Generated skill frontmatter identifies OpenSpec as generator/author, declares MIT licensing, requires the `openspec` CLI, and restricts the nominal tool surface to `Bash(openspec:*)` [45cca5d:src/core/shared/skill-generation.ts:L132-L154].

| Workflow | Control persona and stopping rule |
|---|---|
| `new` | Scaffold a named change, show status and first instructions, then stop. It does not author artifacts. |
| `propose` | Create the minimum proposal/spec/design/tasks set by walking the graph; query status after each output; stop when apply-ready or blocked. |
| `continue` | Create exactly one currently-ready artifact and stop, preserving an explicit human/agent cadence. |
| `ff` | Fast-forward through every ready planning artifact in dependency order, never implementation. |
| `apply` | Read status and apply instructions, implement task-by-task, mark completed tasks, and stop on blockers/ambiguity. |
| `update` | Revise planning artifacts and preserve graph consistency; explicitly never implement source code. |
| `explore` | Investigative thought partner; may inspect and discuss, but does not write implementation code. It creates artifacts only when asked. |
| `sync` | Merge delta specs into current specs using only CLI-reported artifact paths; stop before writes if instruction loading fails; do not archive. |
| `archive` | Status/check/sync/verify, then move the change to a date-prefixed archive. Inline sync must complete before the move and may not be backgrounded. |
| `bulk-archive` | Require an explicit selection, analyze cross-change conflicts, and treat spec-instruction failure as an atomic batch stop. |
| `verify` | Compare implementation against artifacts and report critical issues, warnings and suggestions with actionable references. |
| `onboard` | Run a guided real-codebase cycle, pausing after proposal before implementation and ending with archive. |

The 13th skill, `.agents/skills/release-openspec/SKILL.md`, is a repository-maintainer release state machine. It inspects live GitHub/Changesets state, distinguishes release PRs from ordinary work, supports stable/beta channels, and places human approval gates before publication [45cca5d:.agents/skills/release-openspec/SKILL.md:L1-L180]. It is not installed by `openspec init` and is not part of the end-user workflow graph.

### 3.4 Schemas, profiles and configuration gears

| Gear | Scope | Key behavior |
|---|---|---|
| packaged schema | `schemas/spec-driven/schema.yaml` | Built-in proposal/spec/design/tasks graph and apply tracking |
| project-local schema | `openspec/schemas/<name>/schema.yaml` | Highest-priority schema customization for a project |
| user schema | global OpenSpec data area | Machine-level override/fallback |
| project config | `openspec/config.yaml` | schema, project context, per-artifact rules, operation guidance, references, optional store pointer |
| change config | `openspec/changes/<id>/.openspec.yaml` | chosen schema, optional `skip_specs`, goal and change metadata |
| global config | XDG/AppData config JSON | profile, delivery overrides, selected workflows, default store |
| store registry | global data YAML | machine-local store ids, paths, observed origin and timestamps |
| worksets | global data YAML/`.code-workspace` | personal reusable folder views |

Project configuration deliberately separates `context`, per-artifact `rules`, and advisory `operations.apply/archive.guidance`; references are normalized separately, and `store` is only a fallback for config-only roots [45cca5d:src/core/project-config.ts:L32-L76]. Global workflow configuration is Zod-validated but passthrough-compatible [45cca5d:src/core/config-schema.ts:L7-L31]. Configuration key paths explicitly reject prototype-pollution segments [45cca5d:src/core/config-schema.ts:L46-L97].

### 3.5 Repository planning/history inventory

The pinned checkout has 36 current specs, 19 active changes, 83 archived changes, one initiative and 38 experimental `openspec/work` files. Active changes are:

| Active change | Files | Task posture at snapshot |
|---|---:|---|
| `add-change-stacking-awareness` | 7 | 22 open |
| `add-devin-desktop-support` | 7 | 25 complete |
| `add-global-install-scope` | 11 | 38 open |
| `add-init-agents-target` | 5 | 10 complete |
| `add-qa-smoke-harness` | 3 | no task checklist |
| `add-skill-cli-auto-approval` | 4 | 7 complete |
| `add-tool-command-surface-capabilities` | 5 | 33 open |
| `add-update-workflow` | 5 | 15 complete |
| `extend-config-injection-to-apply-archive` | 13 | 34 complete |
| `feat-add-omp-tool-support` | 7 | 13 complete |
| `fix-cli-local-date-semantics` | 6 | 8 complete |
| `fix-opencode-commands-directory` | 5 | 5 complete |
| `fix-spec-parser-fidelity` | 5 | 23 complete |
| `fix-validate-view-resolution-parity` | 7 | 27 complete |
| `graceful-status-no-changes` | 5 | 8 complete |
| `make-codex-skills-only` | 8 | 39 complete |
| `schema-alias-support` | 2 | no task checklist |
| `simplify-skill-installation` | 8 | 90 complete |
| `unify-template-generation-pipeline` | 5 | 24 open |

These directories are design/history evidence, not proof that their proposals are implemented. The number of fully checked but still active changes is itself lifecycle-hygiene evidence.

## 4. Architecture and layers

```text
bin/openspec.js
  -> compiled CLI registration
     -> command handlers
        -> root selection
        -> project/change/global config
        -> schema resolver + artifact graph
        -> status/instruction/template services
        -> store/reference/workset services
        -> output formatting / diagnostics
     -> preAction telemetry notice + event tracking
     -> postAction telemetry shutdown

canonical workflow bodies
  -> skill generator ------------------> <tool skillsDir>/openspec-*/SKILL.md
  -> command generator -> adapter ------> tool-specific opsx command file

filesystem artifacts
  -> completion scan -> graph readiness -> instruction payload -> external AI tool
  -> external AI writes artifact/code -> next CLI invocation recomputes state
```

### 4.1 Layer responsibilities

1. **Executable/CLI layer.** Commander defines discoverability, flags, output mode and lifecycle hooks. It delegates actual behavior to command/core modules.
2. **Resolution layer.** A command selects the OpenSpec root from explicit store, nearest planning root, project pointer, global default or compatibility fallback. The selected root is included in structured output.
3. **Configuration layer.** Global delivery/profile preferences, project context/rules/references, change metadata and schema definitions are read into typed structures.
4. **Graph layer.** The schema is validated, converted to a directed acyclic graph, topologically ordered and evaluated against the filesystem.
5. **Instruction layer.** It resolves a ready artifact or operation and emits template, output path, dependencies, context, rules, reference index and progress state.
6. **Execution/service layer.** Init/update generation, spec merge/archive, stores, worksets, doctor/context and validation mutate or inspect local state.
7. **Presentation/integration layer.** Human and JSON output plus skill/command adapters translate one semantic workflow into each host tool.
8. **Telemetry layer.** Pre/post CLI hooks emit anonymous, best-effort usage events when enabled.

**Inference.** The strongest boundary is between *OpenSpec as deterministic coordinator* and *the host AI as executor*. OpenSpec never interprets a model response or schedules an internal autonomous agent. Its control loop is externalized into prompt instructions and repeated CLI calls.

### 4.2 State scopes

| Scope | State | Durability/ownership |
|---|---|---|
| repository | `openspec/config.yaml`, specs, changes, archive, local schemas | intended for source control |
| change | `.openspec.yaml` plus proposal/spec/design/tasks artifacts | repository-local lifecycle state |
| machine config | profile, delivery, workflow selection, default store | user-owned XDG/AppData config |
| machine data | user schemas, store registry, worksets | local only; not committed |
| store checkout | `openspec/` plus committed `.openspec-store/store.yaml` | user-controlled standalone planning repository |
| process/session | environment, color/JSON mode, warning de-duplication, telemetry pending set | ephemeral |
| generated integration | tool skill/command files | project or selected installation target; regenerated by init/update |

Windows global configuration resolves under `%APPDATA%`, global data under `%LOCALAPPDATA%`; XDG variables take precedence where present [45cca5d:src/core/global-config.ts:L36-L109]. The store registry and worksets deliberately live in data rather than configuration; store identity is committed with the store [45cca5d:src/core/store/foundation.ts:L28-L64].

## 5. Events, state transitions and control loops

### 5.1 Artifact graph state machine

The built-in schema declares `proposal` first; `specs` and `design` require it; `tasks` requires both; and the `apply` phase requires/tracks `tasks` [45cca5d:schemas/spec-driven/schema.yaml:L1-L38] [45cca5d:schemas/spec-driven/schema.yaml:L38-L127] [45cca5d:schemas/spec-driven/schema.yaml:L129-L208].

```text
new change
   |
   v
proposal ─────┬────> specs ───┐
              └────> design ──┼──> tasks ──> apply ──> verify/sync/archive
                               ┘
```

The schema loader rejects invalid references, duplicate artifact IDs and cycles [45cca5d:src/core/artifact-graph/schema.ts:L15-L44] [45cca5d:src/core/artifact-graph/schema.ts:L81-L123]. Graph order is a stable Kahn topological sort, with declaration order used for ready siblings [45cca5d:src/core/artifact-graph/graph.ts:L23-L37] [45cca5d:src/core/artifact-graph/graph.ts:L95-L138]. Runtime states are:

- **done**: all declared output paths/globs exist;
- **ready**: incomplete, with all dependencies complete;
- **blocked**: incomplete, with at least one incomplete dependency;
- **skipped**: spec outputs when the change's `skip_specs` metadata applies.

Completion is derived from filesystem existence, not a database marker [45cca5d:src/core/artifact-graph/state.ts:L6-L36]. The graph exposes ready/complete/blocked computations directly [45cca5d:src/core/artifact-graph/graph.ts:L144-L192].

### 5.2 Instruction-generation loop

`status` loads the change, resolves its schema, detects completed outputs, applies `skip_specs`, then reports every artifact's status, path and next-step context [45cca5d:src/core/artifact-graph/instruction-loader.ts:L143-L183] [45cca5d:src/core/artifact-graph/instruction-loader.ts:L249-L298]. `instructions <artifact>` adds template, output path, dependencies/unlocks, project context and artifact rules; operation instructions add relevant references and guidance [45cca5d:src/core/artifact-graph/instruction-loader.ts:L76-L113] [45cca5d:src/core/artifact-graph/instruction-loader.ts:L322-L393].

The host-agent loop is therefore:

1. ask status/instructions;
2. consume the returned constraints and dependency context;
3. write the one or many requested artifacts/code changes;
4. call status again;
5. continue, stop, or surface a blocker according to the selected workflow skill.

This structure prevents a prompt from inventing graph state, but it does not itself constrain arbitrary filesystem writes by the host tool. Enforcement remains cooperative except where the CLI operation owns the mutation.

### 5.3 Root-selection event loop

Every root-aware command resolves in this order:

1. explicit `--store <id>`;
2. nearest ancestor with a real OpenSpec planning root;
3. a config-only `openspec/config.yaml` store pointer;
4. global `defaultStore`;
5. if registered stores exist, fail with a selection hint;
6. otherwise use implicit current-directory compatibility behavior.

The source explicitly rejects a removed/unsupported `--store-path` escape hatch [45cca5d:src/core/root-selection.ts:L392-L455]. Human mode prints the selected-root banner and JSON embeds structured root provenance [45cca5d:src/core/root-selection.ts:L489-L503]. The documented ordering matches implementation [45cca5d:docs/stores-beta/user-guide.md:L300-L319].

### 5.4 CLI lifecycle events and telemetry

Commander `preAction` shows the first-run telemetry notice and queues a command event; `postAction` flushes telemetry [45cca5d:src/cli/index.ts:L118-L146]. The payload is intentionally sparse: command/surface/version properties and `$ip: null`; a generated anonymous ID is stored locally [45cca5d:src/telemetry/index.ts:L91-L107] [45cca5d:src/telemetry/index.ts:L145-L161]. CI and documented environment variables disable telemetry. Network errors are deliberately swallowed so analytics cannot break the CLI [45cca5d:src/telemetry/index.ts:L41-L85]. The notice is written to stdout [45cca5d:src/telemetry/index.ts:L167-L187], which matters to the test-isolation finding in section 10.

## 6. Agents, roles, personas, skills, plugins and hooks

### 6.1 Runtime agent model

There is no in-process multi-agent runtime, model client, conversation store, tool-calling engine or autonomous scheduler. The two product-facing users are explicitly a human and an external agent, and the nested product instruction asks contributors to frame features as concrete workflows for both [45cca5d:openspec/work/AGENTS.md:L1-L35]. “Agent” in this repository means one of three things:

1. an external coding assistant receiving generated commands/skills;
2. a behavioral persona encoded in a workflow skill (`explore`, `apply`, `verify`, and so on);
3. a repository maintainer following the release skill.

No configurable subagent hierarchy exists. A few workflow texts permit delegating a synchronous subtask, but the product provides no orchestration primitive to create, message, await or reconcile subagents. “Plugin” likewise does not denote a runtime extension manager: the practical extension points are schemas, generated Agent Skills and statically registered command adapters.

### 6.2 Skill versus command surfaces

The canonical workflow content lives in shared TypeScript generators. `generate:skills` rebuilds the 12 committed `skills/openspec-*` directories from compiled code, deleting only validated skill subdirectories and transforming slash-command references to skill references [45cca5d:scripts/generate-skillssh.mjs:L1-L47]. The shared helper rejects unsafe names and symlinked deletion targets before cleanup [45cca5d:scripts/skillssh-shared.mjs:L21-L59].

Command adapters are intentionally presentation-only. They select output path, file extension, metadata shape and invocation syntax; the workflow body remains canonical. This reduces semantic drift across 28 tools. Skills and commands can coexist where delivery is `both`, while Codex is explicitly skill-invocable and may omit redundant command files.

Parity is content-addressed: the parity script compares committed skills with canonical generated output using SHA-256. Regeneration refuses to proceed against missing/stale `dist`, and parity-hash rewriting checks expected literal counts rather than blindly replacing text. The repository tells contributors that generated skills must be regenerated after a build and that parity failures signal drift [45cca5d:skills/README.md:L17-L19].

### 6.3 Hook inventory

There is no general application hook framework. The hook-like surfaces are:

| Hook/event | Trigger | Effect |
|---|---|---|
| Commander `preAction` | before every CLI action | optional telemetry notice and event capture |
| Commander `postAction` | after every CLI action | bounded telemetry flush |
| npm `prepare` | dependency/package preparation | build TypeScript |
| npm `prepublishOnly` | before npm publication | build TypeScript |
| npm `postinstall` | after installation | print a first-use hint only, unless CI/opt-out |
| GitHub Actions | push/PR/schedule/release state | build, test, lint, audit, package/release |
| website build pre-step | website dev/build | regenerate selected docs from root `docs/` |

The postinstall script intentionally detects CI/opt-out and catches all failures, ensuring an optional hint cannot make installation fail [45cca5d:scripts/postinstall.js:L3-L15] [45cca5d:scripts/postinstall.js:L28-L82]. This is a narrow, defensible exception to otherwise explicit failure handling, but it is silent by design.

## 7. Workflow/reference graph and script execution paths

### 7.1 Primary command paths

```text
openspec init
  -> validate target/project
  -> inspect legacy/renamed integrations
  -> choose global profile + per-tool delivery
  -> generate selected skills and adapter commands
  -> remove obsolete allow-listed generated files

openspec update
  -> require an initialized openspec/ directory
  -> migrate legacy integrations/profile if needed
  -> regenerate current selected workflow surfaces
  -> remove deselected/obsolete generated surfaces
  -> optionally check npm and ask before global CLI upgrade

openspec status/instructions
  -> resolve root
  -> load change metadata + schema
  -> build graph + scan outputs
  -> load project context/rules/references
  -> emit human or JSON state/instructions

openspec archive
  -> validate task/spec posture
  -> preview deltas and possible note/scenario loss
  -> confirm exceptional/destructive cases
  -> apply deltas to current specs
  -> validate rebuilt specs
  -> move change to archive/YYYY-MM-DD-<id>

openspec store setup
  -> validate id/path/trust boundaries
  -> create planning root + committed identity
  -> optionally git init + initial commit
  -> atomically register machine-local path
```

`init` validates permissions and path, performs controlled legacy migration, validates selected tools, generates skill/command surfaces and only then completes cleanup [45cca5d:src/core/init.ts:L133-L235]. Output directories are centrally derived rather than scattered [45cca5d:src/core/init.ts:L629-L651]. `update` requires an existing project, migrates known old surfaces, recalculates profile/delivery, regenerates and removes stale generated files; noninteractive cleanup behavior is stricter unless `--force` is supplied [45cca5d:src/core/update.ts:L118-L190].

Legacy cleanup is allow-listed rather than recursive over arbitrary tool directories, including a special global Codex prompt migration [45cca5d:src/core/legacy-cleanup.ts:L71-L123]. Renamed-tool migrations are explicit, and an existing installation can be promoted to a custom workflow profile so update does not silently erase user-selected workflows [45cca5d:src/core/migration.ts:L114-L179] [45cca5d:src/core/migration.ts:L441-L500].

### 7.2 Schema and template resolution

Schema resolution follows a layered precedence: project-local schema first, then user/global schema, then packaged built-in schema. This permits repository-specific workflows without modifying the package and machine-local experimentation without forking. The graph schema is declarative: artifact IDs, dependencies, output patterns, templates and instruction text are data; execution behaviors (`apply`, archive sync) remain code-owned.

The instruction loader keeps template/output metadata separate from injected context and rules. This is a valuable prompt-security/property boundary: consumers can display or delimit them independently. However, the loader currently catches project-config errors and proceeds without context/rules [45cca5d:src/core/artifact-graph/instruction-loader.ts:L343-L347], which can silently weaken the intended instruction contract.

### 7.3 Store, reference and workset paths

Stores are standalone OpenSpec roots registered by machine-local ID. The registry enforces one path per store identity and uses a lock plus atomic update discipline [45cca5d:src/core/store/registry.ts:L86-L119] [45cca5d:src/core/store/foundation.ts:L323-L348]. Registration that first creates identity metadata attempts to roll that metadata back if the registry write fails [45cca5d:src/core/store/registry.ts:L262-L318].

OpenSpec deliberately does **not** synchronize stores: its Git helper may initialize a repository and create the first commit, but it never fetches, pulls, pushes or resolves divergence [45cca5d:src/core/store/git.ts:L12-L16]. References are a read-only, one-level context index. Self-references are omitted; unresolved/unhealthy registrations become diagnostics with sanitized clone recipes; nested reference traversal is not performed [45cca5d:src/core/references.ts:L301-L305] [45cca5d:src/core/references.ts:L313-L444].

Worksets are independent personal views, not inferred planning relationships. They persist a named set of folders and regenerate a VS Code workspace file. Generic workset-state updates acquire the workset lock and atomically write durable YAML [45cca5d:src/core/worksets.ts:L236-L275]. Removal performs the durable write before deleting the derived `.code-workspace` file [45cca5d:src/core/worksets.ts:L339-L356]; opening reads coherently under the same lock before regenerating the derived workspace and spawning the selected tool [45cca5d:src/core/worksets.ts:L257-L275] [45cca5d:src/core/worksets.ts:L359-L401]. The computed “working set” used by context, by contrast, derives from declared project references [45cca5d:src/core/working-set.ts:L3-L5].

### 7.4 Spec synchronization and archive safety

The specs-apply engine parses delta operations, detects duplicate/conflicting modifications, supports idempotent/already-applied cases and warns for removals that are already absent [45cca5d:src/core/specs-apply.ts:L105-L199] [45cca5d:src/core/specs-apply.ts:L282-L398]. The pivotal safety property at the pinned commit is that removal/replacement cannot silently discard prose notes adjacent to requirements or lose scenarios without surfacing a warning/confirmation [45cca5d:src/core/specs-apply.ts:L363-L428] [45cca5d:src/core/specs-apply.ts:L469-L522] [45cca5d:src/core/archive.ts:L353-L435]. The pinned change modified both `src/core/specs-apply.ts` and `src/core/archive.ts`; the corresponding archive/spec-apply tests are present in the per-file semantic ledger and exercise salvage and warning behavior.

Archive separates informative and blocking checks. Invalid proposal text is reported but does not necessarily block; invalid deltas do. `--no-validate` and incomplete tasks require explicit confirmation. Before moving anything, archive constructs the spec-update preview and validates the rebuilt target specs. The archive name receives one local-date prefix and avoids stacking another prefix on an already dated name [45cca5d:src/core/archive.ts:L353-L374] [45cca5d:src/core/archive.ts:L693-L719]. Cross-device moves fall back to copy/remove only for the relevant filesystem failure.

## 8. Operations and lifecycle

### 8.1 Install, initialize, update and uninstall

The package can be installed globally by supported Node package managers; the runtime remains Node even where an alternative installer is used. `openspec init` creates project state and integration surfaces. `openspec update` regenerates those surfaces and may offer a newer global CLI version, but the install is performed only after a user confirmation and with package-manager ownership checks. Documentation correctly explains that updating each project is separate from upgrading the global executable [45cca5d:docs/installation.md:L158-L173].

There is no `openspec uninstall`. Removal is intentionally manual: uninstall the global package, then decide which generated integration files and which valuable `openspec/` history to retain. The documentation warns that specs and archive are durable product knowledge, not disposable cache [45cca5d:docs/installation.md:L175-L191].

### 8.2 Store setup/removal transaction behavior

Store setup refuses paths inside another Git repository and validates explicit noninteractive inputs [45cca5d:src/core/store/operations.ts:L299-L364]. Its execution creates store identity/planning files, optionally initializes Git, registers the result, and rolls back paths/Git metadata created by the operation on failure [45cca5d:src/core/store/operations.ts:L574-L716]. This is materially safer than a collection of independent writes.

Store removal makes the opposite trade-off: it unregisters first and then deletes the checkout. If deletion fails, the registry no longer references the surviving directory and the error gives a manual fix [45cca5d:src/core/store/operations.ts:L951-L1006]. This avoids a registry pointing at a partially deleted tree, but creates an orphaned local directory; consumers must understand the operation is not fully atomic.

### 8.3 Documentation site

Root `docs/` is the authoring source. A single manifest maps 26 pages to URL, section, order and icon; generated website content is not edited directly [45cca5d:website/docs.sync.config.mjs:L1-L17] [45cca5d:website/docs.sync.config.mjs:L18-L76]. The sync script requires every manifest source, extracts title/description, rewrites links, injects source provenance, deletes the prior generated tree and regenerates pages and navigation metadata [45cca5d:website/scripts/sync-docs.mjs:L105-L134] [45cca5d:website/scripts/sync-docs.mjs:L137-L182]. The Cloudflare router accepts only GET/HEAD documentation routes and forwards a constrained header set to the Pages origin.

### 8.4 CI, security and release automation

CI builds and tests on Ubuntu, macOS and Windows; separate quality, Nix and packaging jobs provide additional gates [45cca5d:.github/workflows/ci.yml:L47-L108] [45cca5d:.github/workflows/ci.yml:L112-L204] [45cca5d:.github/workflows/ci.yml:L229-L327]. Changesets/release preparation has its own workflow [45cca5d:.github/workflows/release-prepare.yml:L20-L90]. Action dependencies are commit-SHA pinned in the inspected workflows [45cca5d:.github/workflows/ci.yml:L28-L104] [45cca5d:.github/workflows/security.yml:L26-L58]. Security automation performs:

- dependency review on pull requests, blocking high-severity additions;
- production dependency audit on push/schedule and advisory pull-request audit;
- separate development and website audits.

The dependency-review threshold and the three audit scopes are explicit in the security workflow [45cca5d:.github/workflows/security.yml:L26-L90].

The release workflow uses Changesets and verifies that the packed CLI reports the package version before publication. `scripts/pack-version-check.mjs` creates a tarball, installs it into a temporary project, invokes the binary, compares versions and cleans the temporary files [45cca5d:scripts/pack-version-check.mjs:L1-L110].

`scripts/update-flake.sh` uses a placeholder hash, lets Nix reveal the correct fixed-output hash, rewrites it and builds again [45cca5d:scripts/update-flake.sh:L52-L101]. A failure before extracting the hash restores the original file [45cca5d:scripts/update-flake.sh:L66-L82]; a failure in the final verification build can leave the newly written hash in place [45cca5d:scripts/update-flake.sh:L96-L107]. That state is reviewable in Git but the script is not fully transactional.

## 9. Testing, security and failure behavior

### 9.1 Test architecture

The pinned Git tree contains **119 tracked TypeScript test/spec files**: 118 under `test/` and one elsewhere. The isolated Vitest run collected and passed the same 119/119 files. A static declaration scan found approximately 2,429 `it`/`test` declarations and no direct `.only`, `.todo` or unconditional `.skip`; these are lexical scale indicators, not a substitute for Vitest's parameterized runtime total. There are platform-conditional skips, particularly around permission semantics. The largest areas are core services and command behavior, with explicit CLI subprocess E2E, local Git integration, generation/parity, store/root, archive/spec merge, telemetry and failure-path coverage. The exact tracked-file classification is in `work/evidence/fission-openspec/semantic-ledger.csv`; the runtime collection is in `work/evidence/fission-openspec/full-suite-20260802.md`.

Vitest runs forked workers, capped at four or `VITEST_MAX_WORKERS`, with 10-second test/hook timeouts. Coverage reporters are configured but no minimum coverage threshold is enforced [45cca5d:vitest.config.ts:L1-L35]. The nested test instruction requires focused-before-full execution, cross-platform paths and canonicalized comparisons [45cca5d:test/AGENTS.md:L1-L30].

Mocks/spies/fakes are common (a static textual scan found 605 matches), but the suite is not mock-only: real CLI subprocesses and temporary local Git repositories provide integration evidence. Multi-OS CI compensates for some local Windows conditional skips.

### 9.2 Security model

**Author claim, substantially source-verified.** `SECURITY.md` describes a local CLI with no server/listener/daemon, plain local project files, optional confirmed upgrade networking and opt-out telemetry. Published-package scope is explicit; postinstall only emits a hint; child-process inputs use argument arrays; telemetry excludes IP and project content. The code supports those claims in the inspected paths.

Important trust boundaries:

- Repository configs, schemas, templates and artifacts are untrusted local content. Zod/type checks and path validation reduce malformed input risk, but generated instructions still flow into a powerful external coding agent.
- Tool target names/paths are allow-listed through configuration and adapters. Legacy deletion is allow-listed and symlink-aware.
- Config paths reject prototype-pollution segments.
- Store clone origins are reported as commands, never automatically executed; reference recipes are sanitized.
- OpenSpec never performs store fetch/pull/push, preventing hidden network synchronization.
- Telemetry uses a public project key, anonymous ID, `$ip: null`, explicit opt-outs and best-effort failures.
- Global CLI upgrades are external, mutable operations and therefore confirmation-gated.

### 9.3 Failure semantics

The dominant pattern is explicit diagnostics and nonzero exit status. JSON-aware commands attempt to preserve one-document stdout contracts. Schema graph corruption, unknown stores, ambiguous root selection, invalid delta specs, unsafe paths and confirmation refusal fail closed.

Intentional/debatable recovery paths are:

- global config read errors mostly fall back to defaults; invalid syntax warns, while several other read errors are swallowed [45cca5d:src/core/global-config.ts:L123-L160];
- project configuration is field-resilient: bad optional fields are warned and ignored rather than rejecting the entire file [45cca5d:src/core/project-config.ts:L111-L170];
- instruction generation catches complete project-config read failure and continues without injected context/rules;
- registry snapshot reads can degrade an unreadable registry to no snapshot in selected recovery paths;
- reference failures are warnings because they are auxiliary read-only context;
- telemetry and postinstall failures never break primary behavior;
- completion errors are deliberately silent.

These behaviors make interactive use robust, but the instruction-config fallback is the most concerning: an agent may act without project-specific constraints while believing instruction generation succeeded.

## 10. Runtime verification

All commands ran against the pinned checkout on Windows/PowerShell with Node `v26.4.0`. The shell's default `pnpm` was 11.9.0, while the repository pins 9.15.9.

| Check | Result | Evidence/interpretation |
|---|---|---|
| raw `node bin/openspec.js --version` before build | **failed as expected** | `ERR_MODULE_NOT_FOUND` for `dist/cli/index.js`; source checkout needs build |
| Corepack availability | **failed/environmental** | `corepack` command unavailable |
| `npx --yes pnpm@9.15.9 install --frozen-lockfile` | **pass** | installed 287 packages and ran prepare/build without changing tracked files |
| build | **pass** | TypeScript compilation exit 0 |
| `tsc --noEmit` | **pass** | exit 0 |
| ESLint | **pass** | exit 0 |
| skill-template/parity/invocation focused tests | **pass** | 3 files, 35 tests |
| initial full suite, two workers, 60-second harness | **inconclusive timeout** | harness exit 124 before suite summary; rerun with adequate duration |
| unisolated full suite | **one failure** | one raw spec-output assertion received telemetry notice prefix; details below |
| targeted failing test with `OPENSPEC_TELEMETRY=0` | **pass** | 1 file, 15 tests |
| earlier opt-out-only full suite, two workers | **pass but not user-state isolated** | exit 0 after about 201 seconds; telemetry-specific tests still touched real AppData |
| isolated full suite, pinned pnpm, telemetry off, two workers | **pass / authoritative** | process exit 0; 119/119 files; 3,450 passed, 24 skipped, 3,474 total; 142.57s Vitest / 147.5s wall; temporary APPDATA/LOCALAPPDATA/XDG roots; real user config remained absent (`work/evidence/fission-openspec/full-suite-20260802.md`) |
| CLI `--version` | **pass** | `1.7.0` |
| `schemas --json` | **pass** | one schema, `spec-driven` |
| `list --json` | **pass** | 19 active changes; root source `nearest` |
| `status --change fix-spec-parser-fidelity --json` | **pass** | `isComplete: true`; proposal/specs/design/tasks all done; root source `nearest` |
| `validate --specs --strict --json` | **pass** | 36/36 current specs passed, 0 failed |
| production audit, high threshold | **pass** | no known vulnerabilities found |
| `npm pack --ignore-scripts --dry-run` | **pass** | 366 files; version 1.7.0; expected package roots only |
| normal `npm pack --dry-run --json` | **environment/tool-resolution failure** | npm's prepare found PATH pnpm 11, which refused a noninteractive modules-dir replacement; not a package-content defect |
| final Git status checks | **pass** | no tracked modifications in repository |

### 10.1 Reproduced telemetry/test-isolation defect

The unisolated suite's sole failure was `test/commands/spec.test.ts` at the raw-file passthrough assertion. That test launches the built CLI subprocess without telemetry opt-out or an isolated config root [45cca5d:test/commands/spec.test.ts:L58-L68]. CLI `preAction` calls `maybeShowTelemetryNotice()` for normal commands, and the notice is written to stdout. On a machine without prior OpenSpec telemetry config, the output therefore becomes `notice + raw spec`, violating the raw-output assertion and the general machine-readable cleanliness expectation.

The process created `C:\Users\littl\AppData\Roaming\openspec\config.json` during the test. It was the only file in that newly created directory. After inspection, the exact file and now-empty directory were removed and absence was verified. The targeted test passed with `OPENSPEC_TELEMETRY=0`.

A second, distinct isolation issue appeared during the fully passing opt-out suite: telemetry-specific tests manipulated enablement and recreated the same real AppData config containing only an anonymous ID. That file and empty directory were again removed and verified absent. Therefore setting the suite-wide opt-out repairs the output assertion but does not fully isolate telemetry tests from user state.

**Root cause.** Subprocess/config tests do not redirect `APPDATA`/XDG configuration to a temporary directory, and some telemetry tests override environment behavior. The proper fix is test-owned config/data roots per test process, plus an assertion that the real user config path is untouched. Suppressing the notice in production would treat a symptom and alter the documented onboarding behavior.

The final isolated full-suite harness supplied exactly those roots externally and verified the real config stayed absent. That is strong, safe verification evidence, but the source defect is explicitly **unresolved**: the repository's default test harness and a normal first-run CLI invocation still have access to the real user config path [45cca5d:test/commands/spec.test.ts:L58-L68] [45cca5d:test/telemetry/index.test.ts:L14-L23] [45cca5d:src/telemetry/index.ts:L167-L184] [45cca5d:src/telemetry/config.ts:L131-L163].

## 11. Documentation drift and corpus quality

### 11.1 Confirmed drift

1. **`view` store support is documented as absent but implemented.** The stores guide says `view`, `templates`, `schemas` and deprecated noun forms stay in the current directory with no `--store` [45cca5d:docs/stores-beta/user-guide.md:L338-L340]. At this commit, `view` registers a store option and resolves the selected root [45cca5d:src/cli/index.ts:L319-L334]. The CLI reference's `view` section also shows only bare `openspec view` [45cca5d:docs/cli.md:L460-L468]. Recent first-parent history contains the corresponding store-pointer/view correction, strengthening the conclusion that prose lagged implementation.

2. **The agent-contract root list omits `view`.** It enumerates root-resolving commands without `view` [45cca5d:docs/agent-contract.md:L28-L36], while source routes `view` through root selection. Because the document labels itself a machine-readable capstone audit from 2026-06-11, this is time-stamped drift rather than an ambiguous marketing summary [45cca5d:docs/agent-contract.md:L1-L9].

3. **One genuine historical relative link is broken.** `openspec/changes/archive/2025-08-11-add-complexity-guidelines/specs/openspec-docs/README.md:342` links to `../docs/capability-organization.md`, but no such tracked target exists. It is archive/history-only and does not affect current published docs.

### 11.2 Qualification issues, not outright contradictions

The team guide repeatedly says OpenSpec “never touches git” and never commits/branches/pushes/pulls [45cca5d:docs/team-workflow.md:L3-L13]. That is accurate for ordinary project/change workflows and store synchronization, but too broad for the entire CLI: `store setup` can perform `git init` and create an initial commit. The store guide documents that opt-out (`--no-init-git`), so this is best fixed by qualifying the team page rather than changing behavior.

The known JSON casing split is openly documented: store-family payloads use snake_case while workflow payloads use camelCase, with embedded root retaining `store_id` [45cca5d:docs/agent-contract.md:L5-L10] [45cca5d:docs/stores-beta/user-guide.md:L344-L349]. It is interface debt, not hidden drift.

### 11.3 Typed reference closure

The reproducible reference ledger contains **2,441 typed edges** across Markdown links/images, TypeScript/JavaScript static and dynamic module imports plus `require`, GitHub Actions `uses`, built-in schema template/output edges, npm binary/publish-root/script declarations, and package dependencies. Every detected edge terminates as a tracked file/directory, generated artifact, runtime builtin, external package/action/endpoint, package boundary, document anchor, prose/code example, automation command, or confirmed broken internal reference. **Generic unresolved is 0.** See `work/evidence/fission-openspec/reference-ledger.csv`, `ledger-summary.md`, and the generator.

The single confirmed broken internal edge is preserved separately in `work/evidence/fission-openspec/confirmed-broken-references.csv`: `openspec/changes/archive/2025-08-11-add-complexity-guidelines/specs/openspec-docs/README.md:342` targets absent `../docs/capability-organization.md`. Two literal `[links](url)` teaching examples are classified as prose/code examples rather than unresolved paths. Generated `dist/` imports, schema outputs and npm publish roots are classified explicitly rather than misreported as missing. External endpoints are inventoried but were not fetched.

External HTTP targets were not live-checked, and fragment anchors were not rendered through every target Markdown engine. Published-site generation does independently fail when a manifest source document is missing [45cca5d:website/scripts/sync-docs.mjs:L113-L117].

## 12. Reusable patterns

### 12.1 High-value patterns

1. **Filesystem-derived workflow state.** Treat outputs as the state record and compute readiness from a DAG. This is transparent, diffable and resilient across tool sessions.
2. **One canonical workflow, many renderers.** Keep semantic instructions in a shared typed model; adapters should own only paths, wrappers, metadata and invocation spelling.
3. **Profiles plus two-axis delivery negotiation.** Separate “which workflows are desired,” the global requested delivery (`skills`/`commands`/`both`), and the target capability (`adapter-backed`/`skills-invocable`/`none`). This prevents capability guesses from leaking into workflow selection or incorrectly promising a surface in commands-only mode.
4. **Generated-surface provenance and parity hashes.** Mark generated files, regenerate from compiled canonical code and hash-check committed artifacts in tests.
5. **Dependency-aware agent stopping rules.** Explicitly distinguish one-step (`continue`), planning-complete (`propose`/`ff`), implementation (`apply`) and analysis-only (`explore`) loops.
6. **Instruction data separation.** Return project context, operation guidance, artifact rules, template and dependency state as distinct fields. Consumers can delimit and audit each trust source.
7. **Root provenance in every structured response.** Return path, selection source and store ID so agents do not silently operate on the wrong workspace.
8. **References as an index, not copied context.** Provide IDs, short summaries and exact fetch commands; keep large source content out of every instruction payload.
9. **Local-only relationship diagnostics.** Report missing/stale/unhealthy registered checkouts without automatic network repair.
10. **Preview-before-destructive merge.** Build the target spec result, surface scenario/note loss and validate before applying and archiving.
11. **Allow-listed migrations and cleanup.** Delete only artifacts the product can identify, reject symlink surprises, and defer legacy deletion until replacement generation succeeds.
12. **Durable-versus-derived workset ordering.** Mutate saved view state under lock, then create/remove generated workspace files with actionable partial-state errors.
13. **One documentation manifest.** Make the authoring corpus authoritative and regenerate the site/navigation from a strict map.
14. **Package-scope verification.** Test the actual tarball/version, not just source metadata, before release.

### 12.2 Clean-room recommendation

A clean implementation inspired by OpenSpec should preserve the DAG/state, canonical-renderer, root-provenance and preview/validation patterns while tightening four boundaries:

- make missing/invalid project instruction config a blocking error for agent instruction generation;
- isolate all config/data paths behind injectable environment/path providers and use temporary roots in every test;
- give every command a declared capability descriptor (root-aware, JSON-safe, mutating, network-capable) and generate docs/contracts from it;
- model multi-step mutations with a small transaction journal so recovery can restore both registry and filesystem state after interruption.

## 13. Weaknesses and trade-offs

### High significance

1. **Tests can mutate real user configuration.** Reproduced twice, including during the nominally isolated full suite. This is the clearest correctness/safety issue.
2. **Instruction generation can silently drop project constraints.** A config read exception becomes “continue without context/rules.” For an agent-facing system, degraded instructions can be more dangerous than an explicit failure.
3. **Prompt compliance is the enforcement boundary.** Workflow skills say what an agent must or must not write, but OpenSpec cannot constrain a host agent outside CLI-owned operations.

### Medium significance

4. **Active-change lifecycle is untidy.** Many fully checked changes remain active, while several proposal streams are open. Status is accurate per directory, but active inventory overstates unfinished delivery.
5. **Non-atomic store removal.** Unregister-first semantics can strand an orphan directory after deletion failure [45cca5d:src/core/store/operations.ts:L951-L1006].
6. **Resilient parsing may mask corruption.** Global/telemetry configuration and selected registry reads default or warn rather than fail; appropriate for optional settings, risky when the value controls execution scope.
7. **Documentation and command capability metadata are separate.** The stale `view --store` prose demonstrates the cost. A generated command matrix would close this gap.
8. **JSON casing is inconsistent by family.** It is documented, but every client still bears the branching cost.
9. **Package-manager pin is not self-enforcing in all lifecycle contexts.** In this environment, invoking npm's prepare resolved PATH pnpm 11 rather than package pnpm 9.15.9 and failed noninteractively.
10. **Source CLI requires a prior build.** The tiny bin shim points only to `dist`; correct for a package, but a fresh source checkout's direct CLI fails until prepare/build succeeds.

### Lower significance / maintainability

11. **Completion errors are silent.** Shell ergonomics win, but diagnosing broken completion is difficult.
12. **No coverage threshold.** Strong test breadth does not prevent gradual coverage erosion.
13. **Platform-conditional skips.** Permission semantics are not locally exercised on Windows; CI's Unix jobs are required evidence.
14. **Postinstall suppresses every error.** Appropriate for a hint-only script, but the absence of even debug telemetry makes regressions invisible.
15. **Nix hash update is only partly transactional.** A final verification failure may leave a modified hash.
16. **One historical broken link and two stale command-contract statements.** Current published docs are mostly coherent, but exhaustive history is not link-clean.
17. **Top-level `AGENTS.md` is empty.** Useful contributor guidance exists only under `openspec/work` and `test`, leaving general repository edits without a local instruction contract.
18. **One-level references are intentionally limited.** This keeps context bounded but cannot express transitive planning dependencies.
19. **Implicit-cwd compatibility can surprise.** When no store is registered and no root exists, some commands treat the current directory as an implicit root; structured provenance mitigates but does not eliminate the risk.

## 14. Unresolved items and evidence limits

- The research did not query external registries or GitHub live beyond the work-state preflight. Published npm metadata, current vulnerabilities outside the lockfile audit and remote PR/release state may have changed after the pinned snapshot.
- External documentation links were inventoried but not fetched. The typed ledger closes the detected internal filesystem/module/schema/generation edges within its documented classes; it does not claim live availability or content validity for external endpoints.
- No networked update, npm global installation, telemetry transmission, store clone/pull, GitHub release or package publication was performed because these would change external/user state and are not required for architectural verification.
- Interactive TUI flows were source/test inspected, not manually driven through every terminal.
- The normal npm pack lifecycle failure was caused by local pnpm resolution; `--ignore-scripts` verified package contents, while the repository's own pack-version script was source/test inspected rather than allowed to create a full extra install after the complete suite.
- The static test-declaration and mock counts are lexical approximations, useful for scale rather than authoritative Vitest collection counts. The authoritative tracked and collected test-file count is 119.
- “No multi-agent runtime/plugin manager” is based on exhaustive tracked-file and symbol/content searches at the pinned commit; it does not rule out behavior in external host tools.
- Historical active/archive proposals sometimes describe superseded designs. They were inventoried for coverage but not elevated above current source, tests and current specs.

## 15. Evidence index

### Package, CLI and configuration

- exhaustive per-file semantic ledger and reproducible generator: `work/evidence/fission-openspec/semantic-ledger.csv`, `work/evidence/fission-openspec/generate-ledgers.mjs`
- typed reference closure and confirmed-broken partition: `work/evidence/fission-openspec/reference-ledger.csv`, `work/evidence/fission-openspec/confirmed-broken-references.csv`, `work/evidence/fission-openspec/ledger-summary.md`
- isolated full-suite command/environment/result: `work/evidence/fission-openspec/full-suite-20260802.md`, with raw runner stdout in `full-suite.stdout.log`; the exit code is process metadata, not a literal stdout line
- package identity, files, scripts, engines and dependencies: [45cca5d:package.json:L1-L92]
- compiled entry shim: [45cca5d:bin/openspec.js:L1-L5]
- CLI lifecycle and core registration: [45cca5d:src/cli/index.ts:L118-L146] [45cca5d:src/cli/index.ts:L155-L195] [45cca5d:src/cli/index.ts:L218-L428] [45cca5d:src/cli/index.ts:L430-L668]
- global config paths/default behavior: [45cca5d:src/core/global-config.ts:L5-L33] [45cca5d:src/core/global-config.ts:L36-L109] [45cca5d:src/core/global-config.ts:L123-L176]
- project config model: [45cca5d:src/core/project-config.ts:L6-L76] [45cca5d:src/core/project-config.ts:L94-L170]
- config hardening: [45cca5d:src/core/config-schema.ts:L46-L97]

### Workflow graph and instruction engine

- built-in artifact graph: [45cca5d:schemas/spec-driven/schema.yaml:L1-L208]
- schema validation/cycle detection: [45cca5d:src/core/artifact-graph/schema.ts:L15-L44] [45cca5d:src/core/artifact-graph/schema.ts:L81-L123]
- deterministic graph ordering/state: [45cca5d:src/core/artifact-graph/graph.ts:L23-L37] [45cca5d:src/core/artifact-graph/graph.ts:L95-L192]
- filesystem completion: [45cca5d:src/core/artifact-graph/state.ts:L6-L36]
- instruction/status payload construction: [45cca5d:src/core/artifact-graph/instruction-loader.ts:L76-L183] [45cca5d:src/core/artifact-graph/instruction-loader.ts:L249-L393] [45cca5d:src/core/artifact-graph/instruction-loader.ts:L442-L524]
- profiles: [45cca5d:src/core/profiles.ts:L14-L50]

### Skills, tools and adapters

- 35 target configuration entries: [45cca5d:src/core/config.ts:L22-L64]
- skill-invocation/delivery policy: [45cca5d:src/core/command-surface.ts:L5-L42]
- adapter registry: [45cca5d:src/core/command-generation/registry.ts:L1-L73]
- canonical generation and invocation rewriting: [45cca5d:src/core/command-generation/generator.ts:L14-L37] [45cca5d:src/core/command-generation/invocation.ts:L4-L99]
- skill/command mappings and frontmatter: [45cca5d:src/core/shared/skill-generation.ts:L59-L106] [45cca5d:src/core/shared/skill-generation.ts:L132-L154]
- committed skill regeneration: [45cca5d:scripts/generate-skillssh.mjs:L1-L47]

### Root, stores, references and worksets

- root resolution implementation: [45cca5d:src/core/root-selection.ts:L392-L455] [45cca5d:src/core/root-selection.ts:L489-L503]
- store formats/locking: [45cca5d:src/core/store/foundation.ts:L28-L64] [45cca5d:src/core/store/foundation.ts:L323-L348]
- registration uniqueness/rollback: [45cca5d:src/core/store/registry.ts:L86-L119] [45cca5d:src/core/store/registry.ts:L262-L318]
- removal partial-state behavior: [45cca5d:src/core/store/operations.ts:L951-L1006]
- deliberate no-sync boundary: [45cca5d:src/core/store/git.ts:L12-L16]
- reference degradation/recipes: [45cca5d:src/core/references.ts:L301-L444]
- workset format/locking: [45cca5d:src/core/worksets.ts:L27-L37] [45cca5d:src/core/worksets.ts:L236-L275]
- workset removal ordering and derived-workspace lifecycle: [45cca5d:src/core/worksets.ts:L339-L401]

### Operations, telemetry, tests and docs

- init/update execution: [45cca5d:src/core/init.ts:L133-L235] [45cca5d:src/core/update.ts:L118-L190]
- archive checks/date behavior: [45cca5d:src/core/archive.ts:L353-L374] [45cca5d:src/core/archive.ts:L693-L719]
- spec-apply conflict/idempotence/salvage behavior: [45cca5d:src/core/specs-apply.ts:L105-L199] [45cca5d:src/core/specs-apply.ts:L282-L428] [45cca5d:src/core/specs-apply.ts:L469-L522]
- store-setup validation/rollback transaction: [45cca5d:src/core/store/operations.ts:L299-L364] [45cca5d:src/core/store/operations.ts:L574-L716]
- CI, release and security gates: [45cca5d:.github/workflows/ci.yml:L47-L204] [45cca5d:.github/workflows/ci.yml:L229-L327] [45cca5d:.github/workflows/release-prepare.yml:L20-L90] [45cca5d:.github/workflows/security.yml:L26-L90]
- Nix hash update partial transaction: [45cca5d:scripts/update-flake.sh:L52-L107]
- repository-maintainer release skill: [45cca5d:.agents/skills/release-openspec/SKILL.md:L1-L180]
- telemetry enablement/payload/notice: [45cca5d:src/telemetry/index.ts:L41-L85] [45cca5d:src/telemetry/index.ts:L91-L107] [45cca5d:src/telemetry/index.ts:L145-L187]
- security claims and automation summary: [45cca5d:SECURITY.md:L13-L60]
- unisolated failing subprocess test: [45cca5d:test/commands/spec.test.ts:L58-L68]
- published-doc manifest and sync: [45cca5d:website/docs.sync.config.mjs:L1-L76] [45cca5d:website/scripts/sync-docs.mjs:L105-L182]
- agent JSON contract: [45cca5d:docs/agent-contract.md:L1-L44]
- store behavior/known limits/storage: [45cca5d:docs/stores-beta/user-guide.md:L300-L362]

## 16. Bottom-line assessment

OpenSpec's core design is unusually legible for an agent-facing tool: declarative artifacts, filesystem-derived state, deterministic dependency resolution and generated host integrations make the control plane auditable without embedding a proprietary agent runtime. Its best ideas are portable. The product is already operationally serious—cross-platform CI, strict spec validation, package-scope audits, destructive archive previews and conservative Git/network boundaries—but the test/config isolation defect and silent instruction-config degradation should be addressed before treating the agent contract as fail-closed. Documentation generation is strong; command-capability documentation should become generated too.

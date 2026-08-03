# GitHub Spec Kit: exhaustive agent-architecture research report

## 1. Snapshot and provenance

| Field | Value |
|---|---|
| Repository | `github/spec-kit` |
| Local checkout | `work/repos/github-spec-kit` |
| Branch | `main` |
| Commit | `d1e86f638277a99b82715c22c90558cd58d3cffd` |
| Commit subject | `fix(workflows): fail a gate whose on_reject is not abort/skip/retry (#3888)` |
| Package version | `specify-cli 0.15.2.dev0` |
| Python | `>=3.11` |
| License | MIT, copyright GitHub, Inc. |
| Worktree state at research start | clean; `main` matched `origin/main` |
| Repository evidence freshness | `2026-08-02T13:57:44.8214328Z` |

Evidence notation in this report:

- **Source fact** means directly observed in the pinned checkout.
- **Author claim** means prose asserted by repository documentation; it may be narrower, broader, or stale relative to implementation.
- **Runtime evidence** means a command actually executed during this research.
- **Inference** means a conclusion drawn from multiple source facts; it is named as such rather than presented as implementation fact.

All source citations use the immutable form `[d1e86f6:path:Lx-Ly]`. Line numbers refer to the pinned snapshot. Git history is used only for provenance and design context, never as a substitute for the pinned source. Context7 was intentionally not used: the requested system is the pinned repository itself, so owner-controlled source, tests, and documentation are the authoritative primary sources.

### Repository census

**Runtime evidence.** `git ls-files` returned 530 tracked files. Five are binary media; the remaining **525/525** were opened and semantically classified in the auditable per-file ledger [`gear-semantic-ledger.csv`](../evidence/github-spec-kit/gear-semantic-ledger.csv). The companion [`reference-ledger.csv`](../evidence/github-spec-kit/reference-ledger.csv) closes all 5,945 extracted references into terminal classes; generic `unresolved` is zero. A local byte/newline census produced:

| Area | Files | Newline-counted lines | Bytes | What it contains |
|---|---:|---:|---:|---|
| Root and other | 38 | 6,713 | 2,623,856 | package metadata, license, readmes, media, editor configuration, changelog-like material |
| `.github` automation | 37 | 14,797 | 821,542 | CI/release/security workflows, agentic workflows, generated locks, contribution skills |
| `docs` | 37 | 5,093 | 264,383 | installation, authentication, extensions, presets, bundles, workflows, reference material |
| `examples` | 8 | 231 | 6,117 | example bundles and workflow-related examples |
| `extensions` | 59 | 17,503 | 619,620 | bundled extensions plus scaffolding/self-test fixtures |
| `presets` | 29 | 2,498 | 93,433 | bundled presets plus scaffold/test assets |
| `scripts` | 15 | 3,908 | 147,747 | Bash, PowerShell, and Python core feature scripts |
| `src` | 126 | 51,762 | 2,110,375 | CLI, integrations, events, extensions, presets, bundles, workflows, authentication |
| `templates` | 16 | 3,026 | 149,512 | ten core commands and six artifact/config templates |
| `tests` | 157 | 98,602 | 3,959,726 | unit, integration, contract, parity, security, workflow, extension and bundle tests |
| `workflows` | 8 | 1,162 | 42,106 | built-in workflow, schema, docs, and catalog material |
| **Total** | **530** | **205,295** | **10,838,417** | |

The byte count includes binary assets; the line count is a repeatable newline census, not a language-aware SLOC metric.

## 2. Executive summary

Spec Kit is not primarily an autonomous coding agent. It is a **project-local orchestration and materialization system** that installs a specification-driven operating model into `.specify/`, renders that model into the native command/skill format of a selected coding agent, and optionally drives those commands through persistent workflows. Its most important architectural decision is to keep the canonical behavior in repository-owned Markdown/YAML/scripts and adapt it outward to many agent products.

The system has five cooperating control planes:

1. **Bootstrap and project state** — `specify init` creates `.specify`, copies shared scripts/templates, installs the built-in workflow, applies presets/extensions, and renders integration-specific assets.
2. **Agent integration adapters** — 37 registered integration IDs map canonical commands to Markdown, Agent Skills, TOML, YAML, or bespoke layouts.
3. **Composable behavior packages** — extensions add commands, hooks, event handlers, scripts, templates, and configuration; presets override or compose command/template behavior; bundles resolve and install a declared collection of components.
4. **Native lifecycle events** — a shared project dispatcher is adapted into each supported agent's native hook/event configuration, with per-event command resolution and timeouts.
5. **Durable workflow execution** — YAML workflows sequence agent commands, prompts, shell/init steps, gates, branches, loops, and fan-out/fan-in while persisting state after each step.

The strongest reusable patterns are canonical-source/many-adapters rendering, default-deny trust for URL extensions, hash-owned generated assets, layered project configuration, atomic state writes, explicit human gates, and source-tested cross-platform script parity. The largest risks are equally clear: shell workflow interpolation is intentionally raw and runs with the user's privileges; workflow requirements are advisory rather than capabilities; the engine API accepts unvalidated definitions; lifecycle events silently no-op when a referenced prompt has no executable script; and the extension/preset implementations are large monoliths whose many transactional edge cases are difficult to reason about locally.

The pinned commit is itself evidence of this boundary: validation already rejected invalid gate `on_reject` values, but direct/unvalidated engine execution could bypass validation. The commit adds a runtime guard so an invalid value fails instead of falling through as `skip` [d1e86f6:src/specify_cli/workflows/steps/gate/__init__.py:L78-L101]. This is a useful general lesson: validation and execution must each defend their own safety invariants when public APIs can be called independently.

## 3. Exhaustive gear inventory

### 3.1 Packaging and executable surface

The package is `specify-cli`, version `0.15.2.dev0`, requires Python 3.11+, and exposes `specify = specify_cli:main` [d1e86f6:pyproject.toml:L1-L20]. Its direct dependencies are Typer, Click, Rich, platformdirs, readchar, PyYAML, packaging, pathspec, and json5 [d1e86f6:pyproject.toml:L6-L17]. Hatchling force-includes core templates, commands and scripts; bundled extensions `git`, `agent-context`, `assess`, and `bug`; workflow `speckit`; presets `lean` and `constitution-sync`; and the bundled community catalog snapshot [d1e86f6:pyproject.toml:L29-L60].

The root Typer application is assembled in `src/specify_cli/__init__.py`. It exposes:

- `init` and self-management commands;
- `extension`, `integration`, `event`, `preset`, `bundle`, and `workflow` sub-apps;
- a project gate for project-scoped commands, resolving `SPECIFY_INIT_DIR` or requiring a `.specify` directory;
- a Windows UTF-8 normalization wrapper in `main()`.

The sub-app registrations are visible at [d1e86f6:src/specify_cli/__init__.py:L501-L582], the project gate at [d1e86f6:src/specify_cli/__init__.py:L530-L551], and the executable wrapper at [d1e86f6:src/specify_cli/__init__.py:L584-L596].

### 3.2 Canonical commands and hand-offs

There are ten canonical command templates under `templates/commands`:

| Command | Purpose | Script preflight | Declared onward hand-off |
|---|---|---|---|
| `speckit.analyze` | cross-artifact consistency and coverage analysis | `check-prerequisites`, requires/includes tasks | none |
| `speckit.checklist` | generate a requirement-quality checklist | `check-prerequisites --json` | none |
| `speckit.clarify` | find and resolve underspecified requirements | `check-prerequisites --paths-only` | Build Technical Plan |
| `speckit.constitution` | establish/update project principles | none | Build Specification |
| `speckit.converge` | converge task work and findings | `check-prerequisites`, requires/includes tasks | none |
| `speckit.implement` | execute the task plan | `check-prerequisites`, requires/includes tasks | none |
| `speckit.plan` | create the implementation plan and design artifacts | `setup-plan` | Create Tasks; Create Checklist |
| `speckit.specify` | create/refine the feature specification | none | Build Plan; Clarify |
| `speckit.tasks` | create an ordered actionable task list | `setup-tasks` | Analyze; Implement |
| `speckit.taskstoissues` | turn tasks into issue-tracker items | `check-prerequisites`, requires/includes tasks | none |

Every script-bearing command declares all three variants, Bash (`sh`), PowerShell (`ps`), and Python (`py`). A static parse found 24 references and zero malformed frontmatter blocks. `constitution` and `specify` are intentionally prompt-only.

The canonical project artifact templates are `constitution-template.md`, `spec-template.md`, `plan-template.md`, `tasks-template.md`, `checklist-template.md`, and VS Code settings. Together they define the normal artifact graph:

```text
.specify/memory/constitution.md
              │
              ▼
specs/<feature>/spec.md
              │
              ▼
specs/<feature>/plan.md
     ├── research.md
     ├── data-model.md
     ├── quickstart.md
     └── contracts/
              │
              ▼
specs/<feature>/tasks.md ──► implementation / issues
```

### 3.3 Built-in agent integrations

The integration registry contains 37 IDs; the complete import-and-registration block is source-visible at [d1e86f6:src/specify_cli/integrations/__init__.py:L40-L128], and the counting method/result is recorded in [`critical-counts.md`](../evidence/github-spec-kit/critical-counts.md):

`agy`, `alquimia`, `amp`, `auggie`, `bob`, `claude`, `cline`, `codebuddy`, `codex`, `copilot`, `cursor-agent`, `devin`, `droid`, `firebender`, `forge`, `gemini`, `generic`, `goose`, `grok`, `hermes`, `junie`, `kilocode`, `kimi`, `lingma`, `omp`, `opencode`, `pi`, `qodercli`, `qwen`, `rovodev`, `shai`, `tabnine`, `trae`, `vibe`, `zcode`, `zed`, and `kiro-cli`.

Their output families are:

- **Agent Skills layout:** `agy`, `alquimia`, `claude`, `codex`, `cursor-agent`, `devin`, `droid`, `grok`, `hermes`, `kimi`, `lingma`, `rovodev`, `trae`, `vibe`, `zcode`, `zed`, plus skill helpers used by Copilot and Bob.
- **Markdown command layout:** `amp`, `auggie`, `cline`, `codebuddy`, `firebender`, `forge`, `junie`, `kilocode`, `kiro-cli`, `omp`, `opencode`, `pi`, `qodercli`, `qwen`, `shai`, plus Bob's Markdown helper. `kiro-cli` is registered as a built-in and subclasses `MarkdownIntegration`, targeting `.kiro/prompts/*.md` [d1e86f6:src/specify_cli/integrations/__init__.py:L40-L128; d1e86f6:src/specify_cli/integrations/kiro_cli/__init__.py:L14-L35].
- **TOML:** Gemini and Tabnine.
- **YAML:** Goose.
- **Bespoke adapters:** Copilot and Bob coordinate more than one representation; Generic uses a configurable Markdown destination.

The integration abstraction declares metadata, installation safety, options, command destination, invocation form, rendering, migration, and event capabilities. Core commands have a stable canonical order [d1e86f6:src/specify_cli/integrations/base.py:L460-L473]. Rendering selects the requested script variant, replaces `{SCRIPT}`, strips the unused scripts block, rewrites arguments and agent references, maps project paths, and resolves cross-command references [d1e86f6:src/specify_cli/integrations/base.py:L759-L872]. Agent Skills use the `agentskills.io` directory shape and a skill-specific invocation form [d1e86f6:src/specify_cli/integrations/base.py:L1533-L1603].

Each integration writes ownership metadata to `.specify/integrations/<integration>.manifest.json` [d1e86f6:src/specify_cli/integrations/manifest.py:L104-L138]. It records content hashes, rejects unsafe paths/symlinks, and during uninstall deletes only unchanged owned files unless forced [d1e86f6:src/specify_cli/integrations/manifest.py:L142-L233; d1e86f6:src/specify_cli/integrations/manifest.py:L297-L424]. Manifest persistence uses a temporary file and `os.replace` [d1e86f6:src/specify_cli/integrations/manifest.py:L428-L456].

### 3.4 Built-in extensions

| Extension | Commands | Hooks/events | Main project effect |
|---|---|---|---|
| `agent-context` 1.0 | `update` | optional `after_specify`, `after_plan` | selects an integration/default context map, maintains idempotent marker blocks in agent context files |
| `assess` 1.0 | `intake`, `research`, `define`, `shape`, `decide` | none | creates structured assessment work under `.specify/assessments/<slug>` |
| `bug` 1.0 | `assess`, `fix`, `test` | none | creates a three-stage defect workflow under `.specify/bugs/<slug>` |
| `git` 1.0 | `feature`, `validate`, `remote`, `initialize`, `commit` | multiple before/after core hooks; auto-commit off by default | adds repository initialization, branch naming, validation, remote, and commit automation |

`extensions/template` and `extensions/selftest` are authoring/test scaffolds, not built-in catalog products. The built-in catalog has 4 extensions [d1e86f6:extensions/catalog.json:L1-L67]; the bundled community snapshot has 144 entries. The parse/count method for both catalogs is captured in [`critical-counts.md`](../evidence/github-spec-kit/critical-counts.md).

An extension manifest must have a valid schema, safe ID/version and paths, and at least one command, hook, or event. Names and references are canonicalized during validation [d1e86f6:src/specify_cli/extensions/__init__.py:L214-L576]. Installed extension state is stored in `.specify/extensions/.registry`. Installation from directory/archive stages and validates content, checks compatibility/conflicts, writes assets, registers commands/skills, and rolls back on failure; enablement and numeric priority are registry state. Lower priority number means higher precedence, ties sort by ID [d1e86f6:src/specify_cli/extensions/__init__.py:L776-L807].

Extension configuration has four layers, from weakest to strongest:

```text
extension defaults
    < project .specify/extensions/<id>-config.yml
    < project .specify/extensions/local-config.yml
    < SPECKIT_<ID>_* environment values
```

This ordering is implemented by `ConfigManager` [d1e86f6:src/specify_cli/extensions/__init__.py:L3993-L4001; d1e86f6:src/specify_cli/extensions/__init__.py:L4211-L4227]. Hook conditions can read config/environment expressions; invalid or unknown conditions evaluate false. Hooks run in ascending priority. Classic hooks return instructions for the active AI agent rather than directly running an OS command—an important distinction between **prompt orchestration** and native executable events [d1e86f6:src/specify_cli/extensions/__init__.py:L4655-L4781; d1e86f6:src/specify_cli/extensions/__init__.py:L4870-L4931].

### 3.5 Presets

Built-in presets:

- `lean` replaces five core commands with a lighter process.
- `constitution-sync` wraps the constitution command to synchronize downstream behavior.

Scaffold/self-test presets are fixtures, not catalog built-ins. The built-in catalog has 2 entries [d1e86f6:presets/catalog.json:L1-L53]; the bundled community catalog has 29. The parse/count method for both catalogs is captured in [`critical-counts.md`](../evidence/github-spec-kit/critical-counts.md).

Preset resolution is manifest-authoritative. Its intended precedence is project overrides, installed presets, extension templates, then core templates [d1e86f6:src/specify_cli/presets/__init__.py:L4801-L4809]. The implementation adds a final bundled-core/source-checkout tier so development and installed-wheel layouts both work [d1e86f6:src/specify_cli/presets/__init__.py:L4926-L5065]. Composition supports `replace`, `prepend`, `append`, and `wrap`, applied recursively from the base upward [d1e86f6:src/specify_cli/presets/__init__.py:L5441-L5495]. Installed preset state lives in `.specify/presets/.registry`.

### 3.6 Bundles

Bundles are declarative aggregations of extensions, presets, workflows, external tool expectations, MCP expectations, and ordered steps. Four role-oriented examples are tracked, while `sicario-spec` is the single bundled community catalog entry. The examples are **confirmed broken executable examples at this pin**, not merely illustrative possibilities: their README validation commands each exit 1, and 16 component references have no built-in or bundled-community catalog terminal. The complete source/line/reference/reason list is [`bundle-broken-references.md`](../evidence/github-spec-kit/bundle-broken-references.md); the same rows are classified `broken` in the reference ledger, while generic `unresolved` remains zero [d1e86f6:examples/bundles/business-analyst/README.md:L14-L22; d1e86f6:examples/bundles/developer/README.md:L14-L22; d1e86f6:examples/bundles/product-manager/README.md:L14-L22; d1e86f6:examples/bundles/security-researcher/README.md:L15-L23].

The resolver deliberately produces the same `InstallPlan` for `info` and `install`, avoiding preview/execution drift [d1e86f6:src/specify_cli/bundler/services/resolver.py:L1-L7]. It evaluates Spec Kit version and integration compatibility as hard gates, while external tools and MCP servers are advisory warnings [d1e86f6:src/specify_cli/bundler/services/resolver.py:L43-L114]. Bundle provenance is recorded in `.specify/bundle-records.json`, whose loading is path-confined and whose save is centralized [d1e86f6:src/specify_cli/bundler/models/records.py:L94-L148]. Removal calculates component sharing before deletion [d1e86f6:src/specify_cli/bundler/models/records.py:L175-L185]. Install rollback is best effort; cleanup failures are intentionally swallowed during rollback, and removal can therefore report partial failure rather than promise a perfect transaction [d1e86f6:src/specify_cli/bundler/services/installer.py:L180-L257].

### 3.7 Workflows and step types

The built-in `speckit` workflow is version 1.0.0. It declares required input `spec`, optional/automatic `integration`, and a scoped enum. Its normal path is:

```text
specify ─► human gate ─► plan ─► human gate ─► tasks ─► implement
```

The engine registers 11 built-in step types [d1e86f6:src/specify_cli/workflows/__init__.py:L43-L72]:

| Type | Function |
|---|---|
| `command` | invoke a rendered command through the selected agent integration |
| `prompt` | send a direct prompt through the selected integration |
| `shell` | interpolate and run an OS shell command |
| `init` | invoke project initialization in process |
| `gate` | pause for an operator choice; abort, retry, or continue/skip |
| `if` | conditional then/else nested execution |
| `switch` | choose a matching case/default |
| `while` | condition-first loop |
| `do-while` | execute-once condition-after loop |
| `fan-out` | apply a step template to collection items, sequentially or with bounded threads |
| `fan-in` | aggregate fan-out results |

The expression language is a custom, constrained Jinja-like evaluator rather than arbitrary Python. It supports typed single expressions, boolean/comparison/membership operations, dotted access, and filters such as `default`, `join`, `map`, `contains`, and `from_json`.

Workflow state is stored under `.specify/workflows/runs/<run_id>/` as `state.json`, `inputs.json`, and append-only `log.jsonl`. Run IDs are validated as safe path components before path construction [d1e86f6:src/specify_cli/workflows/engine.py:L535-L616]. State and inputs use atomic JSON replacement; concurrent log writes are lock-protected [d1e86f6:src/specify_cli/workflows/engine.py:L641-L709; d1e86f6:src/specify_cli/workflows/engine.py:L802-L830]. The engine persists before and after execution boundaries so paused/interrupted runs can resume.

Workflow overlays are project-local modifications against a base workflow. Operations are `insert-before`, `insert-after`, `replace`, and `remove`; overlays carry priority and attribution, and the composer validates conflicts. Project overlay material lives beneath `.specify/workflows/<workflow>/overlays`.

Catalog counts at the snapshot are: one built-in workflow [d1e86f6:workflows/catalog.json:L1-L16], two community workflows (`pipeline` and `yolo`) [d1e86f6:workflows/catalog.community.json:L1-L50], and no built-in or community step-catalog entries [d1e86f6:workflows/step-catalog.json:L1-L6; d1e86f6:workflows/step-catalog.community.json:L1-L6]. Workflow catalog lookup stacks project, user, and built-in sources; community discovery is separate from what is locally installed. Remote catalogs are cached for one hour.

### 3.8 Lifecycle events

Canonical native events are:

`session_start`, `pre_tool_use`, `post_tool_use`, `session_end`, `user_prompt_submit`, and `stop` [d1e86f6:src/specify_cli/events.py:L56-L61].

Event resolution layers are:

1. `--events false` disables all events.
2. Integration built-in defaults establish the base.
3. Enabled extension declarations append handlers.
4. `.specify/integration-events.yml`, when valid, replaces the resolved mapping.

A malformed override is ignored and the prior resolved configuration is retained [d1e86f6:src/specify_cli/events.py:L694-L804]. Each native integration adapter renders the result into its own event/hook configuration. All adapters point to one shared `.specify/events.py` dispatcher, reference-counted so uninstalling one integration does not remove it while another still uses it [d1e86f6:src/specify_cli/events.py:L1339-L1421].

At dispatch, the command's rendered frontmatter selects the configured Bash, PowerShell, or Python script. Arguments are built as an argv vector and launched with `shell=False` [d1e86f6:src/specify_cli/events.py:L476-L558; d1e86f6:src/specify_cli/events.py:L587-L624]. Per-handler timeouts default to 60 seconds in generated configuration; the outer native cap adds `EVENT_TIMEOUT_BUFFER`, preserves raw seconds for the inner dispatcher, and converts the buffered cap to each adapter's native unit [d1e86f6:src/specify_cli/events.py:L47-L52; d1e86f6:src/specify_cli/events.py:L944-L958; d1e86f6:src/specify_cli/events.py:L1039-L1045; d1e86f6:src/specify_cli/events.py:L1155-L1216]. Payloads are forwarded so pre/post-tool handlers can inspect call arguments and results [d1e86f6:src/specify_cli/events.py:L1589-L1633].

## 4. Architecture and layers

```text
                 canonical repository assets
      ┌──────────────────────────────────────────┐
      │ commands │ templates │ scripts │ workflow│
      └──────────────────────┬───────────────────┘
                             │ init / resolver
            ┌────────────────┼────────────────┐
            ▼                ▼                ▼
       presets          extensions         bundles
   override/compose   add hooks/events   resolve a set
            └────────────────┼────────────────┘
                             ▼
                  effective project model
             `.specify/` registries and state
                             │
              ┌──────────────┴───────────────┐
              ▼                              ▼
       integration renderer            workflow engine
   37 agent-native formats/layouts   durable step machine
              │                              │
              └──────────────┬───────────────┘
                             ▼
                   external coding agent
             prompts/skills + native event hooks
```

The layers have deliberately different authority:

- **Canonical content** describes the default behavior.
- **Resolvers** determine precedence and compose declarative customizations.
- **Registries/manifests** record ownership and local state.
- **Adapters** translate behavior into an external agent's dialect.
- **The workflow engine** provides durable sequencing, but delegates cognition to the selected external agent.
- **Scripts** provide deterministic project/file operations around the nondeterministic agent work.

This separation means a new integration does not require rewriting the specification workflow, and a new preset does not need to know every integration layout. The cost is a broad compatibility matrix: canonical prompt semantics, script variants, integration invocation syntax, event formats, extension command registration, and workflow dispatch all have to remain aligned.

## 5. State model, events, and control loops

### 5.1 Project state

| State artifact | Owner | Meaning |
|---|---|---|
| `.specify/integration.json` | init/integration layer | currently selected/rendered integration state |
| `.specify/init-options.json` | init | durable init selections such as script variant/skill mode |
| `.specify/integrations/*.manifest.json` | integration manifest | exact files and hashes owned by each integration |
| `.specify/extensions/.registry` | extension manager | installed extension metadata, enablement, priority, registrations |
| `.specify/presets/.registry` | preset manager | installed preset metadata and priority |
| `.specify/extensions.yml` | hook executor | resolved classic hook configuration |
| `.specify/integration-events.yml` | event system | complete user override of native event mappings |
| `.specify/events.py` | event system | shared native-event dispatcher |
| `.specify/feature.json` | feature scripts | current feature identity and artifact paths |
| `.specify/bundle-records.json` | bundle installer | bundle/component provenance and sharing |
| `.specify/workflows/runs/<id>/*` | workflow engine | resumable run state, immutable inputs snapshot, event log |

### 5.2 Initialization transaction

`init` builds a tracker before mutable work and uses a default-deny confirmation gate for URL-installed extensions [d1e86f6:src/specify_cli/commands/init.py:L550-L592]. It then:

1. creates an integration manifest, parses options, resolves events, renders the integration, and saves ownership state [d1e86f6:src/specify_cli/commands/init.py:L603-L635];
2. writes integration state and copies shared scripts/templates [d1e86f6:src/specify_cli/commands/init.py:L637-L676];
3. copies/registers the built-in workflow [d1e86f6:src/specify_cli/commands/init.py:L678-L715];
4. saves init options and fixes POSIX execute bits [d1e86f6:src/specify_cli/commands/init.py:L717-L731];
5. installs presets, recording failures but continuing [d1e86f6:src/specify_cli/commands/init.py:L733-L801];
6. installs extensions in a batch, skips untrusted URL sources, records failures, and refreshes events [d1e86f6:src/specify_cli/commands/init.py:L803-L841];
7. seeds the constitution after preset installation so the effective template wins [d1e86f6:src/specify_cli/commands/init.py:L843-L846].

If the outer operation fails, a newly created project directory can be removed, but failures inside workflow/preset/extension suboperations may be surfaced in the tracker while init continues [d1e86f6:src/specify_cli/commands/init.py:L678-L715; d1e86f6:src/specify_cli/commands/init.py:L851-L880]. This is not one all-or-nothing database transaction; it is staged bootstrap with local compensation and visible partial outcomes.

### 5.3 Specification loop

The prompt graph is a controlled refinement loop:

```text
constitution → specify ⇄ clarify → plan → tasks → analyze
                                ▲                 │
                                └──── revise ◄────┘
                                                  │
                                                  ▼
                                      implement ⇄ converge
                                                  │
                                                  ▼
                                           taskstoissues
```

Prompts are responsible for interpretation, questioning, and artifact production. Scripts are responsible for selecting the active feature, validating prerequisite artifacts, preparing templates, and returning machine-readable paths. Human gates in workflows break the otherwise automatic chain at explicit review points.

### 5.4 Workflow execution loop

`WorkflowEngine.execute()` creates `RunState`, persists inputs and state, and advances the top-level step index [d1e86f6:src/specify_cli/workflows/engine.py:L904-L981]. A paused run is loaded and continued by `resume()` [d1e86f6:src/specify_cli/workflows/engine.py:L1006-L1048]. Each step produces `COMPLETED`, `FAILED`, `PAUSED`, or equivalent state plus output/error. Nested control structures execute child steps and expose their outputs through the expression context.

Fan-out defaults to sequential execution but can use a bounded `ThreadPoolExecutor` [d1e86f6:src/specify_cli/workflows/engine.py:L1340-L1527]. Shared log writes are locked. Because resumption is indexed at the top-level parent, a paused nested operation may re-enter the containing control step rather than resume at an independently persisted child program counter; step authors therefore need idempotent nested behavior.

Gate behavior is defensive at both validation and runtime. In non-interactive mode it pauses rather than inventing approval [d1e86f6:src/specify_cli/workflows/steps/gate/__init__.py:L172-L175]. Rejection maps only to `abort`, `retry`, or `skip` [d1e86f6:src/specify_cli/workflows/steps/gate/__init__.py:L192-L206]. `show_file` display strips terminal control characters and caps output at 200 lines [d1e86f6:src/specify_cli/workflows/steps/gate/__init__.py:L15-L35; d1e86f6:src/specify_cli/workflows/steps/gate/__init__.py:L211-L281].

## 6. Agents, roles, personas, skills, plugins, and hooks

### 6.1 Runtime agent model

There is no persistent internal LLM-agent class with its own planner, memory, and tool loop. Instead, Spec Kit treats an installed external coding agent as the cognitive runtime. Its integration object knows:

- where that agent expects commands or Agent Skills;
- how those commands are invoked;
- whether multiple installs are safe;
- how script frontmatter and argument placeholders must be rendered;
- whether and how native lifecycle events are represented.

In other words, “agent” is an integration boundary, while **skills/commands are materialized behavioral contracts**. This explains why canonical prompt assets are central and why the integration registry is large.

Spec Kit does not define a separate first-class “plugin” primitive. The closest equivalents are extensions (behavior and lifecycle contribution), presets (behavior composition), bundles (distribution/installation composition), and the external agent integration adapters. Calling any one of these a plugin would blur distinct ownership and execution semantics.

### 6.2 Agent Skills versus commands

Skills integrations always emit an Agent Skills directory structure; Markdown/TOML/YAML integrations emit their platform's command format. Copilot and Bob bridge both. Skills mode is selected from integration capabilities and init options; init explains different invocation variants to the user [d1e86f6:src/specify_cli/commands/init.py:L914-L1012].

Cross-command references are rewritten during rendering. A canonical hand-off can therefore become `/speckit.plan`, `$speckit-plan`, or another platform-native form without changing the canonical prompt [d1e86f6:src/specify_cli/integrations/base.py:L759-L872].

### 6.3 Repository-maintenance personas

The repository itself contains six GitHub Agentic Workflow source files and six generated lock workflows. The exact same-stem pair method/result is in [`critical-counts.md`](../evidence/github-spec-kit/critical-counts.md), and each pair is enumerated in the reference ledger:

- `add-community-bundle`
- `add-community-extension`
- `add-community-preset`
- `bug-assess`
- `bug-fix`
- `bug-test`

The catalog workflows act as catalog-maintenance agents: they read a labeled issue, validate untrusted repository URLs/assets, edit the appropriate catalog/docs, and may create at most one draft pull request plus controlled labels/comments. The bug workflows form a human-label-gated pipeline: assessment is read-only apart from one issue report/labels; fix can create a draft PR; test runs checks in isolation and reports back.

The generated `.lock.yml` files identify the GitHub Agentic Workflows compiler (`gh-aw` 0.79.8) and Copilot engine (1.0.60), and their manifests pin actions and containers by SHA/digest [d1e86f6:.github/workflows/add-community-bundle.lock.yml:L1-L3]. They configure a network firewall/API proxy and split activation, agent, detection, and safe-output jobs. Tool allowlists differ per workflow. The generated setup also restores an inline sub-agent directory even though no `.github/agents` persona files are tracked at this snapshot. These lock files are executable supply-chain artifacts, not hand-maintained design sources.

### 6.4 Hooks and events

Spec Kit has two distinct mechanisms that should not be conflated:

| Mechanism | Source | Execution |
|---|---|---|
| Extension classic hooks | before/after named Spec Kit commands | ordered instructions are returned for the active AI agent to follow |
| Native integration events | agent lifecycle events such as tool use/session stop | `.specify/events.py` resolves and directly executes the declared command script with `shell=False` |

Both are extension-contributed, but only native events are immediate subprocess dispatch. Multiple extensions can contribute to one event; the generated native configuration invokes each handler. Refresh rewrites every installed integration's event representation and accumulates failures before raising `EventRefreshError` [d1e86f6:src/specify_cli/events.py:L1462-L1519].

## 7. Workflow/reference graph and script call paths

### 7.1 Core command-to-script graph

```text
analyze ───────┐
converge ──────┤
implement ─────┼──► check-prerequisites --require-tasks --include-tasks
taskstoissues ─┘

checklist ─────────► check-prerequisites --json
clarify ───────────► check-prerequisites --paths-only
plan ──────────────► setup-plan
tasks ─────────────► setup-tasks

constitution ──────► prompt only
specify ───────────► prompt only
```

Each arrow has `.sh`, `.ps1`, and `.py` variants. Event handlers reuse this same command frontmatter rather than maintaining a separate executable registry.

### 7.2 Script internals

The 15 core scripts are five responsibilities implemented three times:

- `common`: resolve the project root, current feature, `.specify/feature.json`, branch/environment hints, artifact paths, and template precedence;
- `create-new-feature`: sanitize the slug, choose sequential/timestamp numbering, limit branch bytes, create/switch the branch, create `specs/<feature>/spec.md`, and persist feature state;
- `check-prerequisites`: validate the feature directory/artifacts and emit paths/available documents, optionally JSON;
- `setup-plan`: resolve the effective plan template and initialize the plan without overwriting existing user work;
- `setup-tasks`: validate the feature context and initialize the tasks artifact.

The stable artifact names exposed by common logic are `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `quickstart.md`, and `contracts/`. `SPECIFY_INIT_DIR` provides a consistent explicit-root override across CLI and scripts.

The agent-context extension adds Bash, PowerShell, and Python implementations for choosing/updating the active agent context file and maintaining marked sections idempotently. The git extension adds cross-platform scripts for initialization, branch creation, branch/remote validation, and optional automatic commits. Its branch formats include author/app/number/slug substitutions; auto-commit is disabled unless configured.

### 7.3 Template lookup interaction

The Python `PresetResolver` is the full declarative resolver, including composition strategies and manifest-aware precedence. The shell/PowerShell/Python common scripts implement a simpler materialized lookup: project override, preset registry priority, extension directory, then core. This is coherent because installation writes effective assets into project state, but it creates a maintenance obligation: installer materialization and all three runtime lookup variants must stay behaviorally aligned.

## 8. Operations and lifecycle

### 8.1 Installation and upgrade

The documentation supports `uv tool install` from PyPI or Git, `pipx`, one-time `uvx`, and air-gapped installation. Self-upgrade distinguishes `uv-tool`, `pipx`, ephemeral `uvx`, source checkout, and unsupported modes; only the first two are automatically upgradable [d1e86f6:src/specify_cli/_version.py:L204-L210; d1e86f6:src/specify_cli/_version.py:L1224-L1251]. Plan construction validates resolved tags before forming installer argv [d1e86f6:src/specify_cli/_version.py:L689-L749]. Before invoking the installer it removes `GH_*`, `GITHUB_*`, and constrained `_GITHUB_*<credential-suffix>` environment keys and executes with `shell=False` [d1e86f6:src/specify_cli/_version.py:L254-L296; d1e86f6:src/specify_cli/_version.py:L768-L839]. Failure output prints a manual pin-back hint when a prior stable version can be identified [d1e86f6:src/specify_cli/_version.py:L991-L1012]. No upgrade rollback is automated.

### 8.2 Project initialization and switching

The normal operational sequence is:

1. install `specify` in a managed environment;
2. run `specify init` with an integration and script variant;
3. render commands/skills and native event configuration;
4. install/enable/disable/update extensions or presets as needed;
5. create a feature and run the specification command chain;
6. optionally start/resume a persistent workflow;
7. switch or uninstall integrations using their ownership manifests.

Integration uninstallation is conservative: modified, unreadable, or symlinked generated paths are preserved unless force is explicit. Extension/preset update paths use staging and backups. Bundle installation attempts rollback, while bundle removal avoids deleting components shared by other bundle records.

### 8.3 CI, security, documentation, and release automation

Tracked automation includes:

- Python tests and Ruff linting using uv;
- Markdown lint and ShellCheck;
- CodeQL scanning;
- dependency auditing with hash-locked inputs;
- DocFX documentation build and GitHub Pages deployment;
- release preparation/versioning/tag/PR workflows;
- release publication and PyPI trusted publishing;
- the six Agentic Workflows described above.

All 325 extracted tracked-YAML `uses:` occurrences are local actions, 40-hex commit-SHA action pins, or digest-pinned Docker references; zero non-SHA external references were found. The command/classification rule and result are recorded in [`critical-counts.md`](../evidence/github-spec-kit/critical-counts.md), and every occurrence remains auditable in the reference ledger. `.github/aw/actions-lock.json` records the action lock set for checkout, download/upload artifacts, GitHub Script, Node setup, and `gh-aw` setup [d1e86f6:.github/aw/actions-lock.json:L1-L35].

## 9. Testing, security, and failure behavior

### 9.1 Test architecture

**Runtime evidence.** AST enumeration found 4,230 Python test definitions across **152 Python files**. The tracked `tests/` subtree contains **157 files in total**; the other five are non-Python fixtures/configuration. These are static source definitions, distinct from pytest's parameterized runtime case count of 6,388.

| Area | Test functions |
|---|---:|
| Contract | 83 |
| Extension-specific suites | 245 |
| Integration-level suites | 64 |
| Integration adapter suites | 1,167 |
| Root/general suites | 2,414 |
| Unit suites | 131 |
| Workflow overlay suites | 126 |
| **Total** | **4,230** |

Coverage is unusually broad for an orchestration CLI. Tests cover all 37 integrations; rendering and migration; script-variant parity; extension and preset manifests, registries, catalogs, compatibility, conflicts, updates, uninstall ownership and rollback; archive and download bounds; symlink/path traversal and TOCTOU cases; event merging/formatting/refresh; authentication and redirects; bundle contracts and shared-component removal; workflow expressions, every step type, persistence, resume, overlays, catalogs, and CLI behavior; self-upgrade behavior; and the built-in extensions.

`tests/test_workflows.py` is the largest concentration of workflow behavior. Git and agent-context extension suites explicitly compare Python behavior with shell/PowerShell counterparts. Tests are therefore being used not just for functions but for **cross-representation contracts**.

### 9.2 Runtime verification performed

- Worktree/branch/commit/upstream preflight: passed; clean and pinned.
- Tracked-file census and categorization: completed.
- Python AST parse/inventory of source and tests: completed.
- YAML parse of all 24 canonical script frontmatter references: passed, zero parse errors.
- Reproducible semantic/reference closure: 525 gear rows and 5,945 reference rows; terminal classes are `broken` 16, `executable` 2,737, `external_dependency` 2,962, `generated_artifact` 6, `prompt_only` 2, `prose_example` 14, and `repository_file` 208. The extraction includes 582 Markdown targets (578 inline plus four definition targets), 4,979 Python imports, 325 YAML `uses`, 24 command scripts, 20 bundle components, six Agentic Workflow source/lock pairs, seven shell sources, and two prompt-only command terminals. Generic unresolved: **0**. Method and boundaries are recorded in [`closure-summary.md`](../evidence/github-spec-kit/closure-summary.md).
- Targeted runtime suite in a disposable clean clone: command and environment are recorded in [`targeted-pytest-20260802.md`](../evidence/github-spec-kit/targeted-pytest-20260802.md). Pytest collected 1,494 cases; **1,487 passed, 7 skipped, 6 warnings, exit 0**, pytest duration 29.47 s, wall time 30.5 s.
- Full-suite collection in the clean clone: **6,388 cases collected**. A full execution exceeded the bounded observation window, so its status is **timeout/inconclusive**, not passing or failing evidence.

### 9.3 Download and archive security

The shared download layer caps general downloads at 50 MiB and JSON metadata/catalog payloads at 1 MiB/8 MiB [d1e86f6:src/specify_cli/_download_security.py:L25-L48]. Archive extraction additionally constrains entry count, member size, aggregate expanded size, path/component lengths, Zip64/central-directory anomalies, traversal, and symlink/link members. ZIP extraction validates path, symlink, and size conditions before writing [d1e86f6:src/specify_cli/_download_security.py:L897-L943]; tar links receive the same defensive treatment [d1e86f6:src/specify_cli/_download_security.py:L1080-L1110].

Remote asset URLs must use HTTPS, except explicit loopback HTTP. Redirect policy rejects remote-to-local transitions and unsafe schemes [d1e86f6:src/specify_cli/_download_security.py:L318-L349]. Catalog and asset consumers validate each redirect hop and the final URL rather than only the initial URL.

### 9.4 Authentication boundary

The general, configuration-driven authentication layer is opt-in through `~/.specify/auth.json`; absent configuration means that layer supplies no credentials [d1e86f6:src/specify_cli/authentication/config.py:L1-L3; d1e86f6:src/specify_cli/authentication/config.py:L73-L81]. This is **not** the whole authentication boundary. A separate public helper, `_github_http.build_github_request()`, reads `GITHUB_TOKEN` first and `GH_TOKEN` second and attaches the selected bearer token only for four fixed GitHub hosts (`github.com`, `api.github.com`, `raw.githubusercontent.com`, `objects.githubusercontent.com`) [d1e86f6:src/specify_cli/_github_http.py:L30-L58]. Repository-wide call-site search at the pin found the helper only at its definition and in `tests/test_github_http.py`, not in the production call graph; therefore the environment-token behavior is a latent/public helper capability, not evidence that every GitHub download path uses it. Host matches in the config-driven layer are exact or `*.suffix`; unsafe wildcard positions are rejected [d1e86f6:src/specify_cli/authentication/config.py:L36-L53]. Providers include GitHub bearer credentials and Azure DevOps basic, bearer, Azure CLI, or Azure AD flows.

The HTTP layer strips `Authorization` when a redirect leaves trusted hosts or downgrades, tries matching credentials in order on 401/403, then tries unauthenticated [d1e86f6:src/specify_cli/authentication/http.py:L1-L9; d1e86f6:src/specify_cli/authentication/http.py:L164-L218]. A malformed auth file produces a warning and unauthenticated operation rather than stopping all downloads [d1e86f6:src/specify_cli/authentication/http.py:L32-L48]. Azure AD client-secret token POSTs reject every redirect so a 307/308 cannot replay the secret body [d1e86f6:src/specify_cli/authentication/azure_devops.py:L157-L167].

### 9.5 Shell and prompt trust boundaries

The shell step intentionally calls `subprocess.run(..., shell=True)` to support pipes and redirects [d1e86f6:src/specify_cli/workflows/steps/shell/__init__.py:L51-L63]. Template expressions are substituted as raw text, so untrusted inputs or AI-produced output can become shell syntax. The repository documentation explicitly warns that quoting is not a security boundary [d1e86f6:workflows/README.md:L107-L128]. The step defaults to a 300-second timeout and rejects booleans, non-finite, non-numeric, or non-positive timeout values [d1e86f6:src/specify_cli/workflows/steps/shell/__init__.py:L30-L42; d1e86f6:src/specify_cli/workflows/steps/shell/__init__.py:L111-L140].

Workflow `requires` accepts only `speckit_version` and `integrations`. These requirements are advisory preconditions, not an enforcement boundary; `requires.permissions` is explicitly rejected because shell steps always run with the invoking user's privileges [d1e86f6:src/specify_cli/workflows/engine.py:L70-L81; d1e86f6:src/specify_cli/workflows/engine.py:L123-L129; d1e86f6:src/specify_cli/workflows/engine.py:L273-L300].

### 9.6 Failure semantics

- **Fast fail:** malformed manifests, unsafe paths, incompatible hard requirements, invalid run IDs, invalid step configuration, failed commands, timeouts.
- **Pause:** non-interactive gates and explicit retry flows.
- **Preserve user work:** hash mismatch, unreadable generated files, symlinks, and pre-existing plan/task artifacts are not silently overwritten/deleted.
- **Warn and continue:** optional init components, missing advisory bundle tools/MCPs, malformed auth configuration, certain catalog/cache problems.
- **Best-effort compensation:** extension/preset/bundle installs stage/backup and attempt rollback, but bundle cleanup can still be partial.
- **Fail open/no-op:** native event dispatch returns success when the referenced command is absent or lacks a script [d1e86f6:src/specify_cli/events.py:L254-L277; d1e86f6:src/specify_cli/events.py:L587-L618].

That last behavior deserves explicit operational attention: attaching a prompt-only command such as `speckit.specify` to a native event does not run the prompt and does not fail the event. It silently becomes a no-op. This is a direct source fact and a likely configuration-footgun.

## 10. Documentation drift

### Confirmed drift

1. **Init script variants.** The workflow guide says `script` is optionally `sh` or `ps` [d1e86f6:workflows/README.md:L135-L151]. The source uses the canonical script choices, including `py`, and the rest of the repository treats Python as a first-class variant. Documentation should say `sh`, `ps`, or `py`.
2. **Fan-out concurrency.** The guide describes fan-out as sequential [d1e86f6:workflows/README.md:L233-L247]. Source defaults to sequential but supports configured bounded parallel execution using `ThreadPoolExecutor` [d1e86f6:src/specify_cli/workflows/engine.py:L1340-L1465]. The documentation omits the concurrency option and its thread-safety implications.

### Important nuance, not classified as drift

The architectural docs show the normal CLI path loading and validating a workflow before execution. That is correct for the CLI. However, `WorkflowEngine.execute()` itself accepts an unvalidated `WorkflowDefinition`; source comments call this out [d1e86f6:src/specify_cli/workflows/engine.py:L1212-L1215; d1e86f6:src/specify_cli/workflows/engine.py:L1536-L1539]. The pinned gate fix exists precisely because programmatic callers or malformed resumed data can cross that boundary. This is an API-contract nuance that deserves stronger public documentation, not necessarily a false existing statement.

### Link check result

The reproducible scanner extracted 582 Markdown targets and assigned every one a terminal classification; it found no generic unresolved Markdown target. Across the wider executable/reference graph, the only confirmed broken terminals are the 16 bundle-component references documented above. This distinction prevents prose examples, external dependencies, generated destinations, and prompt-only terminals from being silently conflated with unresolved repository links.

## 11. Reusable patterns

The repository is MIT licensed, so direct reuse is permitted provided the copyright and license notice are retained in copies or substantial portions [d1e86f6:LICENSE:L1-L21]. Even where reuse is legally permitted, adaptation should respect the target system's threat model and conventions.

| Pattern | Why it is useful | Adaptation guidance | Direct reuse vs clean-room |
|---|---|---|---|
| Canonical command + integration adapters | one behavior definition reaches many agent products | define a small canonical IR/frontmatter schema; keep platform syntax at edges | adapter/base concepts can be reused; clean-room may be simpler for a smaller integration set |
| Hash-owned generated files | safe upgrade/uninstall without deleting user edits | record path, owner, hash, and generation version; reject symlinks/traversal | direct reuse is attractive because edge cases are security-sensitive |
| Preview and install share one plan | removes “dry-run differs from execution” class | make resolution pure; execution consumes the exact plan object | reusable almost verbatim with license notice |
| Layered config with explicit precedence | project and local overrides remain predictable | document all tiers; expose a “show effective config” command | design can be adopted clean-room easily |
| Runtime invariants plus schema validation | protects programmatic/unvalidated callers | validate at ingestion and recheck safety-critical enum/path/permission rules at execution | direct pattern; do not duplicate every validation blindly |
| Durable per-step state | makes human/agent workflows resumable | persist inputs, program counter, outputs, status, and append-only log atomically | clean-room around target workflow model is usually better |
| Shared native-event dispatcher | avoids per-integration handler implementations | normalize payload/event names, render only thin native adapters, reference-count shared asset | strong candidate for adaptation |
| Human gates as first-class steps | makes approval visible and resumable | non-TTY must pause; never synthesize approval; sanitize display content | directly reusable semantics |
| Cross-platform behavior parity tests | prevents Bash/PowerShell/Python drift | define fixtures and compare observable files/JSON/errors across implementations | reuse test strategy, not necessarily code |
| Catalog stack + trust boundary | supports built-in, user, project, and community discovery | separate discovery from installation; require hashes/HTTPS and explicit URL trust | adapt with organization-specific signing policy |

### Clean-room recommendation

Avoid copying the large `extensions/__init__.py` or `presets/__init__.py` wholesale into a new system. Their accumulated compatibility, migration, archive, and registration concerns are tightly coupled to Spec Kit's file layouts. Reuse the externally visible contracts and security test cases, then implement smaller target-native modules. Direct reuse is better for compact, easily isolated utilities such as path confinement, content-hash ownership, safe archive extraction, and redirect authorization—provided license obligations and tests accompany them.

## 12. Weaknesses and trade-offs

### High significance

1. **Workflow shell injection is a designed capability.** Raw interpolation plus `shell=True` means a workflow author or compromised upstream output can execute arbitrary commands as the user. Documentation warns about it, but there is no permissions sandbox. Trust the workflow source like code.
2. **Engine validation is not intrinsic.** Public `execute()` and nested execution can receive unvalidated definitions. The pinned commit repairs one consequence, but other steps must continue duplicating safety-critical runtime checks.
3. **Native event no-op success can hide misconfiguration.** Missing commands and prompt-only commands return zero, so operators may believe automation ran when it did not.
4. **Partial transaction semantics are distributed.** Init continues through some failures; bundle rollback is best effort; removal may partially fail. Users need a reliable inspect/repair command, not just optimistic success output.

### Medium significance

5. **Large subsystem monoliths.** Extension and preset implementations span thousands of lines and many responsibilities: manifests, registries, download, catalogs, installation, template resolution, config, hooks, and compatibility. This raises review and regression cost.
6. **Three script implementations multiply maintenance.** Bash, PowerShell, and Python improve portability but require constant parity testing. The existing test investment is evidence that drift is a real cost.
7. **Nested workflow resume granularity.** Persistence centers on the top-level step index, so re-entering a parent control step may repeat completed nested work. Idempotence is not optional for side-effecting nested steps.
8. **Requirements are advisory.** Integration/version hints improve UX, but they are not capabilities or authorization. A manifest cannot meaningfully confine shell/network/file access.
9. **Unauthenticated fallback trades availability for clarity.** Invalid auth configuration or exhausted 401/403 credentials falls back to unauthenticated HTTP. This is useful for public assets but can obscure why a private asset fetch behaved differently.

### Lower significance / maintainability

10. **Documentation trails capability growth.** Python init scripts and fan-out concurrency are already missing from the workflow guide.
11. **Four shipped role examples currently fail their documented validator.** The 16 absent catalog components are executable references, and all four README commands exit 1 at the pin. Readers are given runnable validation commands for examples that cannot validate against the shipped catalogs.
12. **Generated workflow lock volume obscures intent.** Agentic source Markdown is concise, but generated lock workflows are large security-critical artifacts. Review needs compiler-aware diffs and reproducibility checks.

## 13. Unresolved items and evidence limits

1. The full suite collected 6,388 cases, but its bounded execution timed out; the full-suite result is therefore inconclusive. The targeted 1,494-case suite is the only fresh passing runtime claim.
2. No external agent CLI was invoked. Therefore rendering behavior is source/test-supported but not live-verified against Claude, Codex, Copilot, Gemini, or the other 33 products at this snapshot.
3. Remote community catalog URLs and assets were not fetched. Catalog counts describe the pinned bundled snapshots, not current network availability or trustworthiness.
4. GitHub Agentic Workflow lock reproducibility was not recompiled because its compiler/toolchain was not installed. Lock metadata and pinning were inspected statically.
5. The report did not exercise destructive lifecycle operations such as real install/update/remove/rollback. Their behavior is established from source and tests, not a disposable end-to-end project run.
6. The precise guarantees of each external agent's native hook runtime can drift independently of this pinned repository; evaluating those products would require their current official documentation and installations.

## 14. Evidence index

### Core entry and initialization

- `pyproject.toml` — package identity, dependencies, entrypoint, bundled assets, test/lint configuration.
- `src/specify_cli/__init__.py` — root CLI, sub-app registration, project gate, UTF-8 wrapper.
- `src/specify_cli/commands/init.py` — bootstrap ordering, URL trust gate, integration/preset/extension/workflow setup, cleanup and skill-mode UX.

### Commands, scripts, and integration rendering

- `templates/commands/*.md` — ten canonical agent commands, script frontmatter, hand-offs.
- `templates/*.md` — constitution/spec/plan/tasks/checklist artifact contracts.
- `scripts/{bash,powershell,python}/*` — current-feature state, prerequisites, feature creation, plan/tasks setup.
- `src/specify_cli/integrations/base.py` — adapter abstraction and Markdown/TOML/YAML/Skills renderers.
- `src/specify_cli/integrations/__init__.py`, `catalog.py`, and integration modules — 37 built-in agent definitions and catalog behavior.
- `src/specify_cli/integrations/manifest.py` — generated-file ownership, hashing, safe uninstall, atomic persistence.

### Extensions, presets, and bundles

- `src/specify_cli/extensions/__init__.py` — manifest, registry, manager, config, hooks, catalog and installation logic.
- `src/specify_cli/extensions/_commands.py` — user-facing extension lifecycle.
- `extensions/{agent-context,assess,bug,git}` — four shipped extension products.
- `src/specify_cli/presets/__init__.py` and `_commands.py` — preset catalogs, resolution, composition, installation.
- `presets/{lean,constitution-sync}` — two shipped presets.
- `src/specify_cli/bundler/models/*` — bundle manifest/catalog/records contracts.
- `src/specify_cli/bundler/services/*` — resolution, conflicts, adapters, installation, rollback and removal.
- `examples/bundles/*` — role-oriented examples.

### Events and workflows

- `src/specify_cli/events.py` — canonical events, resolution layers, dispatcher, native adapters, refresh/uninstall.
- `workflows/speckit/workflow.yml` — built-in specification-to-implementation sequence.
- `src/specify_cli/workflows/engine.py` — definition validation, durable state, execution/resume, nested control and concurrency.
- `src/specify_cli/workflows/steps/*` — all 11 step implementations.
- `src/specify_cli/workflows/expressions.py` — constrained expression language.
- `src/specify_cli/workflows/overlays/*` — overlay schema, sources, merge/composition and conflict reporting.
- `src/specify_cli/workflows/catalog.py` and `_commands.py` — project/user/built-in catalog stack and lifecycle.
- `workflows/README.md`, `docs/reference/workflows.md`, `workflows/ARCHITECTURE.md` — author claims and public operating contract.

### Security, operations, automation, and tests

- `src/specify_cli/_download_security.py` — URL, redirect, byte, archive, path/link safeguards.
- `src/specify_cli/authentication/*` — opt-in auth config, providers, redirect stripping and fallback behavior.
- `src/specify_cli/_github_http.py` — separate environment-token helper, fixed GitHub-host allowlist, and download primitive.
- `.github/workflows/*` — CI, CodeQL, docs, release and publication automation.
- `.github/workflows/*.md` and generated `*.lock.yml` — agentic maintenance workflows and executable locks.
- `.github/aw/actions-lock.json` — action pin set.
- `tests/**/*` — 157 tracked files total, including 152 Python files with 4,230 AST-enumerated test definitions; pytest expands these to 6,388 collected cases.
- `work/evidence/github-spec-kit/gear-semantic-ledger.csv` — 525/525 per-file byte/hash, parse method, semantic synopsis, immutable source locator, and reference-row linkage.
- `work/evidence/github-spec-kit/reference-ledger.csv` — all 5,945 extracted references with source/line, kind, normalized target, terminal classification, and evidence.
- `work/evidence/github-spec-kit/bundle-broken-references.md` — the complete 16-item confirmed-broken bundle ledger and four failing validation commands.
- `work/evidence/github-spec-kit/targeted-pytest-20260802.md` — clean-clone targeted pytest command, environment, counts, timing, and scope boundary.
- `LICENSE` — MIT reuse terms.

## 15. Bottom-line assessment

Spec Kit's architecture is strongest when treated as a **compiler and stateful workflow host for agent operating procedures**: canonical specifications are compiled into product-native commands/skills, deterministic scripts manage repository artifacts, and a durable workflow engine coordinates human and agent transitions. Its design is mature around file ownership, cross-platform support, catalogs, remote-content hygiene, and regression testing.

It should not be treated as a sandbox or security policy engine. Installed extensions, workflows, prompts, and catalogs cross meaningful trust boundaries, and shell steps have the same authority as the invoking user. The safest way to reuse the design is to preserve its explicit approval gates, ownership manifests, atomic state, and adapter separation while tightening validation-at-execution, making no-op event behavior observable, and reducing the size of the extension/preset control-plane modules.

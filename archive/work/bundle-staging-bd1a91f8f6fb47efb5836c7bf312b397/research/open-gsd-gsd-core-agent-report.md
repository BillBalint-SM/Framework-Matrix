# open-gsd/gsd-core: exhaustive agent-architecture research report

## 1. Snapshot, provenance, and evidence rules

| Field | Value |
|---|---|
| Repository | `open-gsd/gsd-core` |
| Remote default branch | `next` |
| Pinned commit | `33985c11a9f0a27443f8b8fb114b2122d653cd78` |
| Package | `@opengsd/gsd-core` `1.9.1` |
| Runtime floor | Node `>=22.0.0`, npm `>=10.0.0` |
| License | MIT, copyright 2026 Open GSD |
| Analysis checkout | `work/repos/open-gsd-gsd-core` |
| Disposable runtime clone | `work/runtime/open-gsd-gsd-core-test` |
| Preflight freshness | `2026-08-02T14:01:27.4386081Z` |
| Preflight result | clean `next`, `HEAD=33985c1`, upstream `origin/next`; remote PR #259 was reported merged from `next` to `main` |

The package identity, executable aliases, publication contents, engine floor, dependencies, and quality scripts are declared in the pinned package manifest [33985c1:package.json:L1-L60] [33985c1:package.json:L82-L122]. The MIT terms permit reuse, modification, distribution, sublicensing, and sale provided the notice and permission text are retained [33985c1:LICENSE:L1-L21].

Evidence labels used below:

- **Source fact**: directly observed in the pinned tree.
- **Author claim**: asserted by repository prose, but not independently proven merely by that prose.
- **Runtime observation**: a command run in the disposable clone for this research.
- **Inference**: a conclusion derived from multiple source facts and explicitly labeled.

All citations use the immutable shorthand `[33985c1:path:Lx-Ly]`; line numbers refer to the pinned snapshot. Git history is used only to explain present-day choices. Context7 was not used because the task is a forensic study of a pinned repository: the repository's code, manifests, tests, and commit history are the applicable primary sources.

## 2. Executive summary

GSD Core is a prompt-and-artifact operating system for AI-assisted software delivery. Its canonical product is not a single autonomous agent. It is a large set of Markdown command adapters, workflows, role prompts, references, hooks, and TypeScript/CommonJS utilities that turn a project-local `.planning/` directory into durable coordination state. Commands remain thin; workflows initialize state, choose models, invoke specialist agents, and reconcile their artifacts; agents do the context-heavy research, planning, execution, and adversarial checking; deterministic CLI modules perform state mutation, validation, installation, routing, trust checks, and host adaptation [33985c1:docs/ARCHITECTURE.md:L22-L65] [33985c1:docs/ARCHITECTURE.md:L434-L498].

The design has four especially strong ideas:

1. **Fresh-context delegation with file-backed continuity.** Heavy work is handed to specialized agents while `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`, plans, summaries, and verification artifacts preserve continuity across sessions.
2. **One canonical authoring dialect, many runtime projections.** Claude-flavored command/agent Markdown is transformed at install time into host-specific commands, skills, agent files, TOML, JSON, rules, plugin payloads, or extensions. Runtime descriptors increasingly drive placement and behavior.
3. **Explicit loops and adversarial gates.** Planning, execution, verification, review, security, UI, documentation, and evaluation use distinct producer/checker roles, capped retries, structured verdicts, and operator checkpoints.
4. **Generated-contract discipline.** Capability registry, loop-host contract, runtime matrix, inventory, package identity, plugin skills, ADR index, glossary, compiled CJS, and context index all have drift checks; the full generated-sync suite passed at the pin.

The largest architectural liabilities are equally concrete. `bin/install.js` remains a 13,531-line special-case-heavy integration boundary; the public architecture prose undercounts agents and runtimes; the machine inventory is deliberately shallow and covers only six root-level families; generated checks cannot catch stale prose comments; many safety hooks fail open on parser/runtime exceptions; regex/prompt-level injection detection is necessarily advisory; and several runtime capabilities are declared `undocumented`, `none`, or unsupported. These weaknesses do not negate the controls, but they define where downstream adopters must not overstate guarantees.

## 3. Exhaustive coverage and inventory reconciliation

### 3.1 Complete tracked-tree census

The supplied CSV contained 2,730 rows. `git ls-files` at the pin also returned 2,730 paths. Every row was re-hashed against the checkout: **0 missing paths, 0 extra paths, 0 SHA-256 mismatches, 0 recorded hash errors**. Of those files, 2,725 were marked gear candidates. The five exclusions were logo/terminal binary assets:

- `assets/gsd-logo-2000-transparent.png`
- `assets/gsd-logo-2000-transparent.svg`
- `assets/gsd-logo-2000.png`
- `assets/gsd-logo-2000.svg`
- `assets/terminal.svg`

Every one of the 2,725 gear-candidate files was mechanically read without sampling, including NUL-bearing test fixtures. The gear set covers **36,203,101 bytes and 773,276 LF bytes**. Three gear candidates contain NUL bytes: `tests/fix-2284-hermes-agent-delegate-task-projection.test.cjs`, `tests/fixtures/adversarial/frontmatter/null-byte-value.md`, and `tests/security-prompt-injection.security.test.cjs`. The full 2,730-file tree covers 36,309,998 bytes and 773,586 LF bytes; five tracked files contain NUL bytes (the three gear files plus two PNG assets). The earlier 36,112,848-byte figure described the coincidentally 2,725-file **non-NUL** set, not the gear set, and is not used as coverage evidence. These are accounting metrics, not language-aware SLOC.

| Supplied category | Files |
|---|---:|
| Documentation | 1,096 |
| Executable source | 806 |
| Orchestration asset | 326 |
| Source or other | 201 |
| Configuration or data | 161 |
| Skill | 72 |
| Hook | 30 |
| Workflow | 26 |
| Agent instruction | 5 |
| Binary or asset | 5 |
| Plugin or adapter | 2 |
| **Total** | **2,730** |

The category labels overlap the repository's conceptual layers only imperfectly—for example, 71 generated `SKILL.md` files live under `skills/`, while one additional skill-classified file is elsewhere. The path-level CSV, re-hash, and full read are therefore the primary exhaustive ledger.

The top-level distribution also reconciles to all 2,730 files:

| Area | Files | Area | Files |
|---|---:|---|---:|
| `tests/` | 899 | `.changeset/` | 497 |
| `docs/` | 373 | `gsd-core/` | 307 |
| `src/` | 179 | `scripts/` | 92 |
| `skills/` | 71 | `commands/` | 71 |
| `capabilities/` | 55 | `.github/` | 43 |
| `agents/` | 34 | `hooks/` | 30 |
| `eslint-rules/` | 17 | `.out-of-scope/` | 7 |
| `examples/` | 5 | `assets/` | 5 |
| `vscode/` | 4 | `bin/` | 3 |
| `.claude-plugin/` | 2 | `.githooks/` | 2 |
| 30 singleton root/config files | 30 | `.kilo/`, `.opencode/`, `pi/` | 3 |
| `.plans/` | 1 |  |  |

The dominant extensions were 1,400 Markdown, 879 CommonJS, 185 TypeScript/CommonJS source (`.cts`), 159 JSON, 34 YAML, 31 JavaScript, and 13 shell files. This confirms that prompts and tests—not only the compiled CLI—are first-class behavior.

### 3.2 Machine manifest: current but intentionally incomplete

`docs/INVENTORY-MANIFEST.json` records exactly six families, but its CLI-module result is **build-materialized** rather than a pristine tracked-tree fact:

| Manifest family | Entries | Actual interpretation |
|---|---:|---|
| Agents | 34 | all root `agents/gsd-*.md` files |
| Commands | 71 | all root `commands/gsd/*.md` files |
| Workflows | 91 | root workflow files only |
| References | 97 | root reference files only |
| CLI modules | 173 | built `gsd-core/bin/lib/*.cjs` files |
| Hooks | 25 | managed root hook scripts only |

The generator performs a non-recursive `readdirSync`, retains only files, sorts them, and supports `--check` [33985c1:scripts/gen-inventory-manifest.cjs:L24-L72] [33985c1:scripts/gen-inventory-manifest.cjs:L78-L102]. The pristine source checkout contains only 17 tracked `gsd-core/bin/lib/*.cjs` files, so its direct inventory-manifest `--check` exits 1 and reports 156 roster entries absent. After `npm ci`/`prepare` compiles the disposable runtime clone, 173 CJS modules exist, 156 as ignored build outputs, and the same check exits 0. This matches the build-at-publish ownership decision; clean `git status --short` does not reveal those ignored outputs. Consequently, “up to date” means **current in a built checkout**, not whole-tree or pristine-source coverage:

- `gsd-core/workflows/` has 117 tracked files: 91 root Markdown workflows, one root `_runtime-launcher.snippet.sh`, and 25 nested mode/step/template files.
- `gsd-core/references/` has 115 tracked files: 97 root references plus 18 nested edge-probe fixtures.
- `hooks/` has 30 tracked files: the manifest's 25 managed root scripts exclude `hooks.json`, the shared managed-hooks registry, and three `hooks/lib` files.
- Skills, capabilities, installer scripts, tests, documentation, plugin adapters, examples, and root configuration are outside this manifest.

This is a **coverage and build-state limitation**, not evidence that the committed roster is semantically wrong. The documentation calls the manifest a six-family shipped-surface roster and directs operators to live directory counts [33985c1:docs/INVENTORY.md:L1-L9].

### 3.3 Reference reconciliation

The corrected pass persists `work/evidence/open-gsd-gsd-core/references.csv`, a 42,366-row ledger generated from all 2,725 gear files, including the three NUL-bearing fixtures. Each row records source path/line, raw token, syntax, resolution root, normalized target, existence, terminal class, and exclusion reason. Its deliberately broad grammar covers 28,721 path tokens, 4,236 Markdown links, 8,745 module imports, and 664 explicit `@` includes. Duplicate syntactic views of the same source token remain separate rows so the extraction is auditable.

| Terminal class | Rows | Meaning |
|---|---:|---|
| Existing source file | 17,937 | Direct pinned-tree target. |
| Generated projection source | 2,591 | Runtime `.cjs`/projection maps to canonical tracked source. |
| Canonical install source projection | 936 | Installed `~/.claude/gsd-core` include maps to shipped source. |
| Runtime artifact | 1,897 | Exists only after install or in project `.planning` state. |
| Dynamic/template | 6,351 | Placeholder, variable, glob, or generated segment. |
| Fixture/history example | 4,291 | Test, changeset, ADR, translation, or historical evidence. |
| Prose example | 438 | Static-looking token that is not an executable include/link. |
| Configuration/dependency pattern | 497 | Lockfile, ignore, or configuration pattern. |
| External | 5,336 | URL or other external target. |
| Package/builtin | 1,347 | Bare module specifier. |
| Prompt/prose/schema literal | 362 | Static-looking Markdown/JSON text with no explicit include/import/link edge. |
| Code/config/generated literal | 335 | Static-looking code or configuration text with no pristine-tree target. |
| Build/runtime projection literal | 12 | Import-like code token whose target is materialized or CWD-dependent. |
| Generated/historical missing link | 21 | Markdown link retained as generated, example, or historical context after relative resolution failed. |
| Embedded example import | 13 | Import-like token embedded in Markdown prompt/prose rather than executed by that source file. |
| Confirmed broken | 2 rows / 1 unique edge | `gsd-core/references/reviewer-instances.md` points to nonexistent `gsd-core/docs/adr/...`; the repository target is `docs/adr/...`. |
| **Total** | **42,366** | Full ledger row count. |

The ledger has **zero `unresolved_static_candidate` rows**: every extracted row has a terminal class and a row-specific reason preserving the exact source line and raw token. That terminal classification is an auditable disposition, not proof that every prose/example path is semantically correct. The one confirmed broken edge is documentation/reference drift, not a canonical command→workflow failure.

Higher-confidence checks additionally found:

- 71 command files and 71 generated skill directories; `gen-plugin-skills --check` reported all 71 current.
- The canonical prefix occurs on 505 tracked text lines (506 raw `git grep -o` matches because one line contains it twice); the earlier 494+11 split was not reproducible and is withdrawn.
- All workflow targets referenced by the 71 canonical command files exist. Fourteen commands are self-contained routers or integrations with no direct workflow include; eight route to multiple workflows.
- The generated context index checked 49 glossary references and all-runtime parity; the compiled-artifact checker confirmed nine tracked artifacts match their sources.

The canonical routing pattern is explicitly documented as command→workflow→agent/CLI→`.planning` artifacts [33985c1:docs/ARCHITECTURE.md:L110-L143]. Plugin installs add a canonical-path hook so installed `@~/.claude/gsd-core/...` includes resolve to the plugin bundle [33985c1:docs/ARCHITECTURE.md:L286-L294].

## 4. Architecture and ownership boundaries

### 4.1 Canonical control flow

```text
user invocation
  -> runtime command / skill / palette / plugin surface
  -> canonical command adapter in commands/gsd
  -> workflow in gsd-core/workflows
       -> gsd_run / gsd-tools init and query verbs
       -> optional loop contributions from capability registry
       -> specialized fresh-context agent(s)
       -> deterministic checks / bounded revision loop
  -> durable .planning artifacts and optional code commits
  -> state/roadmap/requirements reconciliation
```

Commands provide frontmatter, argument handling, and delegation. Workflows are the real prompt programs: they define initialization, context loading, branching, subagent prompts, artifacts, checkpoints, error paths, and next actions. Agents are role cards with bounded tools and structured outputs. `gsd-tools`/`gsd_run` centralize operations that would otherwise be repeated and error-prone in shell snippets. The architecture calls this “thin orchestrators” and “fresh context” [33985c1:docs/ARCHITECTURE.md:L70-L105].

The package has four executable entry points: the installer, `gsd-tools`, `gsd_run`, and the MCP server [33985c1:package.json:L6-L11]. `gsd-tools` exposes atomic state/config/roadmap/requirements/verification/worktree/capability verbs plus compound `init` queries; command-family routing is moving out of the central dispatcher into capability and host router tables. This preserves prompt readability while making high-risk mutations deterministic.

### 4.2 Canonical source versus derived artifacts

Hand-authored TypeScript/CommonJS source lives under `src/*.cts`; `gsd-core/bin/lib/*.cjs` is build output. ADR-457 rejects dual maintenance and selects build-at-publish compilation, with the consequence that source consumers must build before running [33985c1:docs/adr/457-generated-cjs-single-source.md:L94-L144]. The exception is package identity, which is generated and committed because it is needed before the compiled tree exists.

Canonical command Markdown under `commands/gsd/*.md` generates 71 Claude skill wrappers under `skills/gsd-*/SKILL.md`; the generator uses the shared conversion function rather than maintaining two bodies [33985c1:scripts/gen-plugin-skills.cjs:L1-L50]. Runtime-specific placement comes from capability descriptors, while content conversion is centralized in `runtime-artifact-conversion`—a deliberate downward dependency that prevents layout code from becoming a second conversion implementation [33985c1:docs/adr/1508-runtime-artifact-conversion-module.md:L15-L26] [33985c1:docs/adr/1508-runtime-artifact-conversion-module.md:L66-L77].

### 4.3 Global, project, session, and local layers

The repository does not define these four names as a uniform, peer-level storage taxonomy. The mapping below is therefore an **architectural synthesis**, with the scope differences kept explicit rather than promoted to a native four-layer contract.

| Layer | Durable material | Ownership and precedence |
|---|---|---|
| Global | runtime home, installed skills/agents/hooks, `~/.gsd/defaults.json`, `$GSD_HOME/.gsd/capabilities`, user consent store, global research/learnings | user/machine scope; runtime descriptor resolves the host root; global capability overlay loads before project overlay |
| Project | `.planning/` artifacts/config—including persistent debug sessions and project knowledge—plus `.gsd/capabilities` | versionable delivery truth; project capability overlay can add—but cannot override first-party—IDs and owned stems |
| Session | session-keyed temporary active-workstream pointer and host/session caches where the host exposes a stable session ID | ephemeral coordination scope; without a host session key, the active pointer falls back to project `.planning/active-workstream` |
| Local | runtime install/config scope such as `.claude/settings.local.json`, plus distinct worktree-local execution state | a cross-cutting family of host- and worktree-specific subscopes, not one uniform persistence layer |

`.planning/STATE.md` is the short-term memory read first by workflows and updated after significant actions [33985c1:gsd-core/templates/state.md:L97-L130]. The normal project tree holds PROJECT, REQUIREMENTS, ROADMAP, STATE, config, phase plans/summaries/research/context/UAT/verification, todos, debug sessions, workstreams, and milestone archives [33985c1:docs/ARCHITECTURE.md:L644-L695].

Active-workstream resolution is explicit: CLI `--ws` wins over `GSD_WORKSTREAM`, which wins over a stored pointer [33985c1:src/active-workstream-store.cts:L1-L9] [33985c1:src/active-workstream-store.cts:L301-L332]. With a host session key, the pointer lives in a project-hashed temp path; without one, it falls back to `.planning/active-workstream` [33985c1:src/active-workstream-store.cts:L84-L143] [33985c1:src/active-workstream-store.cts:L197-L230]. Missing or invalid targets are cleared, avoiding a durable pointer to nonexistent state.

Project-local Claude settings use `.claude/settings.local.json` for privacy-sensitive user configuration rather than repository-shared `settings.json`. Worktree `baseRef` resolves through local settings, project settings, then global settings [33985c1:docs/CLI-TOOLS.md:L705-L715]. Persistent debugger sessions are project artifacts, not host-session state [33985c1:agents/gsd-debugger.md:L791-L838]. **Inference:** “Local” is best understood as a policy scope across host config and worktrees, while “Session” is only the explicitly session-keyed temporary state—not a bucket for continuation/debug artifacts.

## 5. Runtime and installer architecture

### 5.1 Descriptor census

There are 44 capability manifests: 19 runtime descriptors, 20 feature capabilities, and five reviewer capabilities. The CLI installer selects 18 runtimes; VS Code is the nineteenth runtime descriptor but has no CLI install surface and is distributed as an extension. Runtime descriptors are the canonical source for home resolution, artifact layout, command dialect, hook surface, support tier, host dispatch, state I/O, transport, and engine.

| Runtime | Tier; global/local | Projected artifacts | Hooks/config | Dispatch/runtime |
|---|---|---|---|---|
| Claude | T1; `~/.claude` / `.claude` | global flat skills; local commands + agents | `settings.json` | imperative, depth 5, background, harness worktrees, Node |
| Codex | T1; `~/.codex` / `.codex`; skills global home `.agents` | flat skills; per-agent TOML sidecars | `config.toml` + Codex hook JSON | declarative, depth 1, background, orchestrator worktrees, Node |
| Antigravity | T1; detected `.gemini/antigravity*` / `.agent` | flat skills + agents | Gemini-style settings JSON | declarative; Go host; several axes undocumented |
| Augment | T2; `.augment` / `.augment` | commands, nested namespace skills, agents | shared settings JSON | declarative, Node |
| Cline | T2; `.cline` / project root | nested skills; rules | `.clinerules` | imperative, depth 1, Node |
| CodeBuddy | T2; `.codebuddy` / `.codebuddy` | commands, flat skills, agents | settings JSON | declarative, depth 1, Node |
| Copilot | T2; `.copilot` / `.github` | flat skills, `.agent.md`, instructions | inline session hook | declarative, depth 1; engine undocumented |
| Cursor | T2; `.cursor` / `.cursor` | commands, flat skills, agents | `hooks.json` | imperative, depth 2, background, harness worktrees, Node |
| Hermes | T2; `.hermes` / `.hermes` | nested `skills/gsd`, agents | settings JSON | imperative, depth 1, Python |
| Kilo | T2; XDG `kilo` / `.kilo` | `command/`, flat skills | no hook surface | imperative, unbounded/`-1` depth, Bun |
| Kimi CLI | T2; generic agents root / local deferred `.kimi-code` | skills + YAML/prompt custom agents | Kimi hooks TOML | imperative, depth 1, background, orchestrator worktrees, Python |
| Kimi Code | T2; `.kimi-code` / `.kimi-code` | flat skills only; host built-in roles | Kimi hooks TOML | declarative, depth undocumented, orchestrator worktrees, Node |
| OpenCode | T2; XDG `opencode` / `.opencode` | commands + flat skills; plugin adapter | no native GSD hook surface | imperative, no background, orchestrator worktrees, Bun |
| Pi | T2; `.pi/agent` / `.pi` | native extension rather than file projection | no hook artifact | imperative, no subagents/background/isolation, Bun; session-log state |
| Qwen | T2; `.qwen` / `.qwen` | nested skills + agents | settings JSON | imperative, depth 1, Node |
| Trae | T2; `.trae` / `.trae` | nested skills + agents | no projected hooks | imperative; engine hook bus, Node |
| Windsurf | T2; `.codeium/windsurf` / `.windsurf` | global agents; local workflows + agents | Windsurf hooks JSON descriptor | declarative; background undocumented; no isolation |
| ZCode | T2; `.zcode` / `.zcode` | commands, flat skills, agents | no hook surface | declarative, named dispatch, no background/isolation, Electron |
| VS Code | T1; no file-projected root | Marketplace/VSIX extension | engine-owned; no installer config | palette, active model, depth 5, sandboxed storage/web runtime |

The Codex descriptor illustrates the level of detail: separate config and skill homes, global/local artifact layouts, shell-var command style, hooks, sandbox tier, install surface, extended events, dispatch/isolation, MCP transport, and effort channel [33985c1:capabilities/codex/capability.json:L1-L94]. VS Code intentionally declares empty artifact layouts and `installSurface: none`, with an imperative extension host and sandboxed storage [33985c1:capabilities/vscode/capability.json:L1-L53].

### 5.2 Installer pipeline

The package binary points to `bin/install.js`. The installer:

1. parses explicit runtime flags or an interactive selection; `--all` expands to 18 runtimes [33985c1:bin/install.js:L642-L668] [33985c1:bin/install.js:L12484-L12557];
2. resolves global/local roots, custom directories, profiles, host behaviors, and a descriptor-derived `InstallPlan`;
3. performs preflight and manifest-backed migrations, captures rollback state, and stops on unresolved migration choices;
4. materializes descriptor-declared commands/skills/agents through layout plus canonical conversion functions;
5. stages the canonical `gsd-core` runtime and writes its source marker before dependent artifacts;
6. copies/verifies hooks and helper scripts, then reconciles host config through settings JSON, Codex TOML, Copilot instructions, Cline rules, Cursor hooks, Kimi hooks, or profile-only paths;
7. validates output and rolls back migrations/snapshots on later failure;
8. finalizes configuration, status line, permissions, defaults, worktree base settings, and install report.

The config-adapter registry reads descriptor data from the generated capability registry and returns a fresh typed install plan; invalid runtimes, missing hook surfaces, and invalid sandbox tiers throw [33985c1:src/runtime-config-adapter-registry.cts:L1-L31] [33985c1:src/runtime-config-adapter-registry.cts:L120-L183]. Artifact layout validates destinations and uses a closed kind dispatcher for commands, agents, skills, and Kimi agents [33985c1:src/runtime-artifact-layout.cts:L462-L527]. Content conversion handles the runtime-specific dialect and rejects residual unsupported dispatch forms rather than silently emitting them [33985c1:src/runtime-artifact-conversion.cts:L2540-L2730].

Install writes are generally confined to a resolved root and reject untrusted symlink traversal unless the user explicitly opts into a symlinked destination. Codex configuration writes are atomic and snapshot-backed; migration rollback is integrated with later install failures [33985c1:bin/install.js:L6271-L6327] [33985c1:bin/install.js:L6885-L6955] [33985c1:bin/install.js:L10070-L10284]. The installer distinguishes Kimi CLI from Kimi Code and emits an actionable mismatch error rather than creating an inert install [33985c1:bin/install.js:L676-L714].

### 5.3 Plugins and embedded hosts

- `.claude-plugin/marketplace.json` declares the Claude plugin bundle; `gsd-ensure-canonical-path.js` bridges plugin layout to canonical include paths.
- `.opencode/plugins/gsd-core.js` is the package `main`; `.kilo/plugins/gsd-core.js` is byte-identical. The adapter translates host events to Claude hook payloads, registers commands/agents/skills only when the package tree is not already doing so, keeps session state, and uses the staged GSD runtime.
- `pi/gsd.cjs` is an in-process Pi extension.
- `vscode/extension.js` and `vscode/browser.js` expose a chat participant and language-model tools; the browser variant deliberately avoids Node-only dependencies. `vscode/host-binding.js` bridges the extension host to the engine.
- `gsd-core/bin/mcp-server.cjs` exposes the deterministic engine to MCP clients; VS Code and other embedded hosts reuse the same host-integration seams.

The OpenCode/Kilo adapter comments state its two modes—package-tree versus copied plugin—and its responsibility for event translation and avoiding duplicate registration [33985c1:.opencode/plugins/gsd-core.js:L1-L33] [33985c1:.opencode/plugins/gsd-core.js:L418-L457]. The VS Code desktop entry explicitly uses in-process CJS and the same engine seams as Pi/MCP [33985c1:vscode/extension.js:L1-L44].

## 6. Capabilities, skills, profiles, and runtime composition

### 6.1 Capability registry

The 44 manifests break down as follows:

- **20 feature capabilities:** `ai-integration`, `assumption-delta`, `audit`, `broken-windows`, `claude-orchestration`, `code-review`, `drift`, `external-job`, `gap-analysis`, `graphify`, `intel`, `mempalace`, `nyquist`, `pattern-mapper`, `profile-pipeline`, `research`, `schema-gate`, `security`, `tdd`, `ui`.
- **5 reviewer capabilities:** `coderabbit`, `gemini`, `llama-cpp`, `lm-studio`, `ollama`.
- **19 runtime capabilities:** the runtime table above.

Build time validates these descriptors and commits a frozen registry. Runtime consumers read the generated registry rather than source `capability.json` directly [33985c1:docs/adr/1244-capability-ecosystem.md:L38-L77]. Installed overlays compose from global `$GSD_HOME/.gsd/capabilities/<id>` and project `.gsd/capabilities/<id>`; first-party identifiers and owned stems win, incompatible or invalid overlays are skipped, and committed project overlays require user-owned consent [33985c1:src/capability-loader.cts:L1-L29].

Capability state is a product of three substrates:

```text
installed = skills covered by install profile
surfaced = skills exposed by runtime surface
enabled = installed && surfaced
active = enabled && capability config gate
```

The state resolver documents and implements that composition [33985c1:src/capability-state.cts:L162-L242]. A loop contribution is considered only when its capability is active.

### 6.2 Trust and consent

Project capability directories are repository-controlled and therefore untrusted. Consent is stored outside the repository at `${GSD_HOME || homedir()}/.gsd/consent.json`, keyed to the real project root, capability ID, and a recomputed whole-bundle content hash [33985c1:src/capability-consent.cts:L1-L21] [33985c1:src/capability-consent.cts:L214-L219]. This prevents a cloned repository from self-authorizing executable hooks, commands, reviewers, or MCP servers.

The bundle walk is bounded by 16 MiB total, 8 MiB manifest/ledger/store caps where applicable, 100,000 files, and 4,096 consent records. Writes use an exclusive temp file, fsync, atomic rename, directory fsync, and a hardened shared lock; an unacquired lock throws instead of writing unlocked [33985c1:src/capability-consent.cts:L67-L117] [33985c1:src/capability-consent.cts:L626-L709]. The trust disclosure includes executable paths, reviewer invocations, MCP command/arguments/transport/URLs/headers/env, and binds material changes to re-consent while redacting human-visible secret values [33985c1:src/capability-trust.cts:L108-L170] [33985c1:src/capability-trust.cts:L1098-L1178].

One deliberate boundary is important: a capability that **fails to load** is surfaced loudly but its loop gate fails open so a broken extension cannot halt every ship/verify path; the warning includes removal/fix guidance [33985c1:src/loop-resolver.cts:L543-L582]. This is availability-favoring behavior, not a security gate guarantee.

### 6.3 Skills and namespace routing

The 71 command stems generate 71 `gsd-*` skills. Six namespace meta-skills—workflow, project, quality/review, context, manage, and ideate—route to concrete skills. Hosts with non-recursive eager loading use nested concrete skills under routers; flat-only or recursive/unconfirmed hosts keep all skills at the top level. This reduces advertised prompt cost while preserving canonical command behavior [33985c1:docs/ARCHITECTURE.md:L123-L131]. Profiles (`core`, `standard`, `full`, and composable closures such as `audit`) control which skills are installed and surfaced; the selected profile is persisted for update parity [33985c1:bin/install.js:L913-L913].

## 7. Events, hooks, loop extension points, and observability

### 7.1 Host hook graph

The Claude plugin hook manifest wires:

| Event | Matcher | Hooks | Semantics |
|---|---|---|---|
| SessionStart | all | canonical path, update check | repair plugin includes; asynchronously detect updates |
| PreToolUse | Write/Edit | prompt guard, read guard | scan planning writes; protect read-only artifacts |
| PreToolUse | Write/Edit/MultiEdit | worktree path guard | block writes outside a managed executor worktree |
| PreToolUse | Write | write guard | block catastrophic shrink of curated planning files |
| PostToolUse | Bash/Edit/Write/MultiEdit/Agent/Task | context monitor | emit remaining-context warnings |
| PostToolUse | Read/WebFetch/WebSearch | injection scanner | advisory, optionally block high-confidence matches |
| SubagentStop / Stop / PreCompact | all | context monitor | preserve continuity near context/session boundaries |
| FileChanged | `config.json` | config reload | inject updated configuration |

The exact wiring and timeouts are in `hooks/hooks.json` [33985c1:hooks/hooks.json:L1-L76]. The managed registry lists 25 shippable scripts and is the source used by update/orphan tests [33985c1:hooks/managed-hooks-registry.cjs:L1-L44]. The remaining tracked hook files are registry/config/library support.

The context monitor warns at 35% remaining, becomes critical at 25%, and debounces for five tool calls [33985c1:hooks/gsd-context-monitor.js:L11-L29] [33985c1:hooks/gsd-context-monitor.js:L91-L121]. Update and Graphify hooks maintain cache/status records; execution workflows emit `[checkpoint]` heartbeats at wave and plan boundaries to avoid silent stream-idle failures [33985c1:gsd-core/workflows/execute-phase.md:L505-L522]. These are the principal observability channels: stdout/stderr diagnostics, structured hook JSON, `.planning` state, update/graph status files, test TAP, and install reports. There is no centralized telemetry service in the core.

### 7.2 Blocking versus advisory safety

- `gsd-prompt-guard.js` is advisory.
- `gsd-read-injection-scanner.js` is advisory by default and blocks only high-confidence findings when `security.injection_blocking=true`; its own comments note that Kimi's post-tool surface cannot enforce that block [33985c1:hooks/gsd-read-injection-scanner.js:L4-L22] [33985c1:hooks/gsd-read-injection-scanner.js:L116-L124].
- `gsd-worktree-path-guard.js` hard-blocks absolute writes outside a managed worktree.
- `gsd-write-guard.js` hard-blocks catastrophic whole-file shrink of curated planning artifacts; its bypass is a path-bound single-use sentinel or an explicit interactive environment variable [33985c1:hooks/gsd-write-guard.js:L36-L72] [33985c1:hooks/gsd-write-guard.js:L109-L174].
- `gsd-workflow-guard.js` is opt-in and can block unsafe workflow transitions.
- `gsd-validate-commit.sh` is community-hook opt-in and blocks nonconventional commit subjects.

Most hooks wrap parsing/execution in outer catches and exit zero to avoid breaking ordinary tool use. The architecture's blanket statement that “all hooks” silently exit on error is too broad because several recognized dangerous conditions explicitly emit block decisions and exit 2 [33985c1:docs/ARCHITECTURE.md:L795-L813]. The accurate formulation is: **unexpected hook failures generally fail open; positively detected guard violations may fail closed.**

### 7.3 Twelve canonical loop points

The generated loop contract declares 12 extension points:

| Phase | Points | Default roles | Artifact edge |
|---|---|---|---|
| Discuss | `discuss:pre`, `discuss:post` | orchestrator | produces `CONTEXT.md` |
| Plan | `plan:pre`, `plan:post` | researcher, planner, checker | consumes context; produces plans |
| Execute | `execute:pre`, `execute:wave:pre`, `execute:wave:post`, `execute:post` | executor, verifier | consumes plans; produces summaries |
| Verify | `verify:pre`, `verify:post` | orchestrator | consumes summaries; produces UAT |
| Ship | `ship:pre`, `ship:post` | orchestrator | consumes UAT |

The contract is generated and validated, not hand-maintained at runtime [33985c1:gsd-core/bin/lib/loop-host-contract.cjs:L1-L102]. `loop-resolver` validates the point, loads the overlay-aware registry and a single config snapshot, filters by capability state/activation, resolves capability-owned config values, and returns ordered active hooks plus rendered fragments [33985c1:src/loop-resolver.cts:L153-L177] [33985c1:src/loop-resolver.cts:L499-L536]. This turns optional capabilities into contributions rather than forks of the core workflow.

## 8. State machine, formulas, persistence, and bounded loops

### 8.1 STATE.md transition engine

`STATE.md` combines YAML frontmatter with human-readable sections. A classification table assigns each field to schema, external, body-derived, curated, or disk-derived ownership and defines preservation behavior [33985c1:src/state-transition.cts:L75-L142]. A preservation pass prevents lossy prose round trips from overwriting curated fields while allowing full disk re-derivations to replace derived progress.

The closed transition union has eleven intents:

| Intent | Effect |
|---|---|
| `beginPhase` | set current phase/name, plan counters, active status, timestamps |
| `advancePlan` | increment current plan and derive progress |
| `completePhase` | mark phase completion, reconcile disk progress/status |
| `plannedPhase` | record plan count and “Ready to execute” |
| `milestoneSwitch` | reset milestone identity, position, status, and progress while preserving accumulated context |
| `milestoneComplete` | close milestone and set next-milestone operator action |
| `patch` | update a declared set of fields |
| `update` | update one body field |
| `prune` | archive old decisions and metrics by cutoff |
| `sync` | re-derive progress/body values from canonical disk state |
| `rebuild` | reconstruct body structures from frontmatter, roadmap, and phase inventory |

The union and dispatch are explicit [33985c1:src/state-transition.cts:L324-L415]. Milestone switch and milestone complete are purpose-specific reset paths [33985c1:src/state-transition.cts:L1148-L1240] [33985c1:src/state-transition.cts:L1244-L1412]; rebuild is a manual, idempotent reconciliation distinct from retention pruning [33985c1:src/state-transition.cts:L1679-L1758].

Progress is disk-derived from the current phase's plan rows. The lifecycle parser identifies the `Plans Complete` column by header, excludes backlog phase 999, sums completed/total, and computes:

```text
percent = total <= 0 ? 0 : min(100, round(completed / total * 100))
```

[33985c1:src/phase-lifecycle.cts:L60-L119]. The renderer turns the percentage into a square-bar representation and frontmatter progress object [33985c1:src/state.cts:L727-L747] [33985c1:src/state.cts:L1776-L1811].

State writes use read-modify-write locking. The implementation tracks held locks for process-exit cleanup, verifies live same-host PIDs before stale stealing, performs steal/retry operations, and places the scan inside the lock to close TOCTOU windows [33985c1:src/state.cts:L169-L286]. The targeted tests exercised preservation, all transition classes, concurrent/invalid state paths, CRLF parity, and rebuild behavior.

### 8.2 Planning loop

The principal plan path is:

```text
init plan-phase
  -> optional phase research
  -> capability plan:pre steps/contributions
  -> optional pattern/API/spec context
  -> planner (single or chunked)
  -> plan checker
  -> targeted planner revision
  -> requirement coverage / Nyquist / bounce checks
  -> plan:post contributions
```

Research, planner, and checker run in fresh subagents and return markers backed by files. Empty/truncated returns are reconciled with disk evidence rather than assumed successful. The revision loop is capped at three iterations, detects non-decreasing issue counts, allows at most two “adjust approach” re-entries, and otherwise requires an explicit operator decision [33985c1:gsd-core/workflows/plan-phase.md:L1096-L1276]. The workflow warns against extra config calls that can create unbounded read loops and uses a flat auto-chain rather than recursive orchestration [33985c1:gsd-core/workflows/plan-phase.md:L1545-L1580].

### 8.3 Execution loop and worktree isolation

`execute-phase` discovers incomplete plans, computes dependency waves, executes waves sequentially, and executes plans within a wave in parallel only when enabled and safe [33985c1:gsd-core/workflows/execute-phase.md:L9-L36] [33985c1:gsd-core/workflows/execute-phase.md:L328-L338]. Before dispatch it:

- refuses a later-wave filter while a lower wave is incomplete;
- fails closed if required isolation is unavailable;
- disables isolation when the configured base diverges;
- forces sequential execution for Copilot or hosts without reliable completion signaling;
- checks pairwise `files_modified` overlap and forces the affected wave sequential;
- disables worktrees per plan when files intersect a git submodule;
- creates background agents one at a time to avoid `.git/config.lock` races;
- records exact worktree/branch/base metadata in a manifest;
- requires the executor's `SUMMARY.md` to be committed before return;
- merges and cleans only manifest-recorded worktrees, with recovery instructions on mismatch.

These behaviors are encoded around wave discovery and the worktree gauntlet [33985c1:gsd-core/workflows/execute-phase.md:L428-L593] [33985c1:gsd-core/workflows/execute-phase.md:L597-L742]. The orchestrator—not parallel executors—owns shared STATE/ROADMAP writes, preventing concurrent lost updates. Cross-AI jobs have an explicit timeout and validate a candidate summary before accepting it [33985c1:gsd-core/workflows/execute-phase.md:L360-L424].

## 9. Agent roster, personas, and tool scopes

The filesystem and generated manifest contain **34** agent definitions. Ten have explicit `<adversarial_stance>` sections: code reviewer, documentation verifier, evaluation auditor, integration checker, Nyquist auditor, plan checker, security auditor, UI auditor, UI checker, and verifier. The authoritative inventory maps every role and spawner [33985c1:docs/INVENTORY.md:L15-L56]. Tool scopes below are condensed from each agent's frontmatter; `R`=read/search, `W`=write/edit, `B`=shell, `Web`=web/research MCPs, `Ask`=user question, `Agent`=subagent dispatch, `Skill`=skill invocation.

| Agent | Persona/output | Tools |
|---|---|---|
| `gsd-advisor-researcher` | evidence-backed comparison for one gray-area decision | R, B, Web, Skill |
| `gsd-ai-researcher` | official-framework guidance into AI-SPEC | R, W, B, Web |
| `gsd-assumptions-analyzer` | code-grounded assumptions for discussion | R, B, Skill |
| `gsd-code-fixer` | apply REVIEW findings as atomic fixes | R, W, B, Skill |
| `gsd-code-reviewer` | adversarial bugs/security/quality REVIEW | R, W, B, Skill |
| `gsd-codebase-mapper` | focused codebase maps written to planning docs | R, W, B, Skill |
| `gsd-debug-session-manager` | isolated multi-cycle debug coordinator | R, W, B, Ask, Agent |
| `gsd-debugger` | scientific-method investigation with persistent checkpoints | R, W, B, Web, Skill |
| `gsd-doc-classifier` | classify one input as ADR/PRD/SPEC/DOC/UNKNOWN | R, W |
| `gsd-doc-synthesizer` | precedence/cycle/conflict-aware consolidated context | R, W, B |
| `gsd-doc-verifier` | adversarial fact check of generated docs | R, W, B |
| `gsd-doc-writer` | create/update assigned documentation | R, W, B, Skill |
| `gsd-domain-researcher` | practitioner criteria, domain risks, regulation context | R, W, B, Web |
| `gsd-eval-auditor` | adversarial COVERED/PARTIAL/MISSING eval review | R, W, B, Skill |
| `gsd-eval-planner` | evaluation strategy, rubrics, data, monitoring | R, W, B, Ask |
| `gsd-executor` | implement a plan, commit tasks, write SUMMARY | R, W, B, Skill, docs MCP |
| `gsd-framework-selector` | short interactive framework decision matrix | R, B, Web, Ask |
| `gsd-integration-checker` | adversarial cross-phase/E2E verification | R, B, Skill |
| `gsd-intel-updater` | write queryable `.planning/intel` maps | R, W, B |
| `gsd-mempalace-curator` | ship-time diary/tunnel/KG/pruning curation | R, B |
| `gsd-nyquist-auditor` | adversarial real-test generation for validation gaps | R, W, B, Skill |
| `gsd-pattern-mapper` | map planned files to existing analogs | R, W, B |
| `gsd-phase-researcher` | implementation research into RESEARCH.md | R, W, B, Web, Skill |
| `gsd-plan-checker` | adversarial goal-backward plan verification | R, B, Skill |
| `gsd-planner` | dependency-aware executable PLAN files | R, W, B, Web, Skill |
| `gsd-project-researcher` | ecosystem research for roadmap creation | R, W, B, Web, Skill |
| `gsd-research-synthesizer` | consolidate parallel research into SUMMARY | R, W, B, Skill |
| `gsd-roadmapper` | phases, requirement mapping, success criteria | R, W, B, Skill |
| `gsd-security-auditor` | adversarial SECURED/OPEN_THREATS/ESCALATE verdict | R, B, Skill |
| `gsd-ui-auditor` | adversarial six-pillar implemented-UI score | R, W, B, Skill |
| `gsd-ui-checker` | adversarial BLOCK/FLAG/PASS design-contract check | R, B, Skill |
| `gsd-ui-researcher` | UI-SPEC contract from code and product context | R, W, B, Web, Skill |
| `gsd-user-profiler` | read-only eight-dimension developer profile | R only |
| `gsd-verifier` | adversarial goal achievement and VERIFICATION.md | R, W, B, Skill |

The tool scopes are intentionally asymmetric: checkers generally cannot edit implementation; researchers may use primary-source web tools; the executor can mutate but does not own final shared-state reconciliation; the debug session manager is the only shipped role with explicit `Agent` delegation; the user profiler is read-only. Agent prompt files also carry detailed persona constraints, acceptance formats, context boundaries, anti-patterns, and completion markers—frontmatter alone is not the whole behavior.

## 10. Commands, workflows, and terminal artifact graph

### 10.1 Command surface

The 71 canonical commands cover:

- **Core lifecycle:** new project/milestone, discuss, plan/spec/MVP/UI/AI/security phases, execute, verify, complete, progress, resume/pause, next, ship.
- **Fast/special execution:** quick, fast, autonomous, spike, sketch, thread, PR branch.
- **Quality:** add tests, validate phase, audit milestone/UAT/fix, code review, eval review, UI review, forensics, cleanup, health.
- **Knowledge/context:** map codebase, explore, ingest docs, docs update, extract learnings, Graphify, MemPalace capture/recall, profile user.
- **Management:** config/settings/update/undo, phase/workspace/workstream routers, capture/inbox/review backlog, manager, stats, help, surface.
- **Namespace routers:** `ns-context`, `ns-ideate`, `ns-manage`, `ns-project`, `ns-review`, `ns-workflow`.

Fourteen router/integration commands contain no canonical workflow include; eight select among multiple workflow targets. Examples: `capture` routes to todo/note/seed operations, `config` to three settings workflows, `phase` to four phase mutations, `progress` to smart routing/progress, `workspace` to list/new/remove. All referenced targets were present.

### 10.2 Artifact hand-offs

```text
new-project / ingest-docs
  -> PROJECT.md + REQUIREMENTS.md + ROADMAP.md + STATE.md

discuss-phase
  -> phase CONTEXT.md (+ discussion log/mode evidence)

plan-phase
  -> RESEARCH.md / PATTERNS.md / optional UI-SPEC or AI-SPEC inputs
  -> one or more NN-PLAN.md
  -> checker verdict + coverage validation

execute-phase
  -> implementation commits + NN-SUMMARY.md per plan
  -> reconciled STATE.md / ROADMAP.md / REQUIREMENTS.md

verify-work / validate-phase
  -> UAT.md / VERIFICATION.md / validation gaps
  -> gap-closure plans, then execute again if needed

audit / complete / ship
  -> milestone audit, archive, release/review outputs
  -> ship:pre/post capability contributions and long-term learnings
```

The wave model ensures upstream summaries become downstream executor context, and all plan/summary/context/requirements artifacts become verifier context [33985c1:gsd-core/workflows/execute-phase.md:L133-L141]. Specialized flows branch from this spine: documentation classifies→synthesizes→writes→verifies; AI integration selects a framework and runs domain/framework/eval planners; UI runs researcher→checker before implementation and auditor afterward; code review runs reviewer→optional fixer; debugging persists hypotheses/evidence across agent cycles.

### 10.3 Progressive disclosure and dynamic context

Large workflows load references and nested mode/step files only at the point of use. Namespace skills reduce eager listing. Recent ADR-1671 work adds a `CONTEXT.md` predicate fact store, a generated line-free context index, in-file `<!-- gsd:section ... -->` fragments, and budgeted composition before runtime conversion. The fragment vocabulary is closed and malformed/nested/duplicate/unknown markers fail closed. The architecture documents per-skill and orchestrator byte budgets [33985c1:docs/ARCHITECTURE.md:L145-L204] and the dynamic pipeline [33985c1:docs/ARCHITECTURE.md:L350-L381].

The ADR records a useful correction: its earlier Windsurf size-cap premise was wrong, and the measured emitted stub was far below the supposed host cap; the decision was adjusted toward deterministic composition rather than justified by the false premise [33985c1:docs/adr/1671-dynamic-context-management-platform.md:L72-L128]. This is strong evidence that ADRs are being used to preserve corrected reasoning, not only decisions.

## 11. Deepest script and call paths

The largest implementation files reveal the maintenance hot spots:

| Path | Lines (newline census) | Responsibility |
|---|---:|---|
| `bin/install.js` | 13,531 | all-runtime install/uninstall, migration, conversion orchestration, config and verification |
| `gsd-core/bin/gsd-tools.cjs` | 3,682 | shipped CLI dispatcher and runtime command surface |
| `src/state.cts` | 3,404 | STATE parsing/mutation/locking and state command handlers |
| `src/runtime-artifact-conversion.cts` | 3,058 | host dialect transformation and post-projection validation |
| `src/phase.cts` | 2,710 | phase CRUD/index/normalization |
| `src/init.cts` | 2,692 | compound workflow initialization |
| `src/verify.cts` | 2,672 | artifact/health/repair validation |
| `src/runtime-hooks-surface.cts` | 2,538 | host hook and config reconciliation |

Major terminal call paths:

1. **Install:** `npx @opengsd/gsd-core` → `bin/install.js` → generated capability registry → runtime config plan + artifact layout → content converter → install engine/copy confinement → migration/trust snapshots → host hook/config writer → post-install verification/rollback.
2. **Command execution:** runtime skill/command → canonical command Markdown → workflow → `gsd_run` wrapper → `gsd-tools.cjs` → capability-family router or host command router → compiled `lib/*.cjs` → filesystem/git process.
3. **State mutation:** workflow `init`/state verb → `state.cjs` lock → pure `state-transition.cjs` intent → preservation ratchet → atomic platform write → updated STATE/ROADMAP/requirements.
4. **Capability hook:** workflow loop point → `loop-resolver` → overlay-aware registry → profile/surface/config state → activation predicate/config-value resolution → ordered step/contribution/gate fragment → host workflow.
5. **Review lane:** review workflow → generated reviewer descriptors → probe → invocation builder → timeout-bounded external/local reviewer → normalized review section; host, args, environment, and transport participate in trust disclosure.
6. **Worktree execution:** plan index → wave/overlap/submodule gates → isolation resolver → worktree create or harness dispatch → executor commits + summary → manifest-scoped merge/cleanup → shared state reconciliation.

The central command dispatcher is mid-refactor. Architecture prose says a 73-case switch is being dissolved into capability family routers and a `_dispatchNonFamily` seam [33985c1:docs/ARCHITECTURE.md:L300-L312]. The shipped CJS already contains capability routing plus `HOST_COMMAND_ROUTERS`, but several leaf paths remain centralized. This is an active decomposition, not a completed small-core design.

## 12. Operations, installation, update, and failure handling

### 12.1 Operator surface

Normal operations are:

- choose runtime(s), global/local scope, and profile at install;
- run `/gsd-*`, `$gsd-*`, `/skill:gsd-*`, palette, or native host equivalents;
- configure project behavior in `.planning/config.json` and user/runtime behavior in the host's local/global config;
- inspect `gsd-tools capability state`, health, drift, phase index, worktree state, open-artifact audit, and profile/surface state;
- update/reapply through the installer, which preserves user files and reports migrations;
- uninstall only GSD-owned artifacts and clean stale managed files.

The CLI docs define capability state/set semantics, including nonzero exit for unapplied changes and warnings for no-op/dead surfaces [33985c1:docs/CLI-TOOLS.md:L211-L242]. The installer preserves non-GSD files, uses pristine manifests to distinguish owned from user-modified material, and reports incomplete installs rather than claiming success.

### 12.2 Error policy by boundary

| Boundary | Failure policy |
|---|---|
| Descriptor/schema | fail loud on unknown runtime, invalid enum, unsafe layout, unresolved role, malformed config |
| Install materialization | accumulate named failures, verify output, rollback migrations/snapshots on fatal paths |
| User config parse | generally preserve and warn/fail rather than replace with `{}`; malformed local worktree config fails |
| Capability overlay | validate/bound reads; skip invalid overlay with warning; first-party wins |
| Consent write | lock and atomic durability; throw if the lock cannot be acquired; capability stays inactive |
| Loop load failure | loud warning but fail open for the unavailable external contribution |
| Safety hook runtime exception | normally fail open to avoid bricking the host |
| Positive write/worktree violation | structured block and exit 2 |
| Agent empty/truncated return | check disk artifacts; offer retry/accept/recovery instead of inferring success |
| Worktree identity mismatch | fail closed and show recovery data; never scan/merge an arbitrary worktree |
| Bounded plan loop stall | stop for operator choice; no unbounded silent retry |

This mixed policy is intentional but must be understood per boundary. “Defense in depth” is accurate; “all controls fail closed” is not.

## 13. Testing, security, and quality gates

### 13.1 Test architecture

The repository contains 899 test files/assets and several enormous suites: `state.test.cjs` (~11.2k lines), `install.test.cjs` (~10.5k), `phase.test.cjs` (~10.1k), `codex-config.test.cjs` (~8.9k), capability registry (~7.1k), runtime-artifact install (~6k), and worktree safety (~5.3k). `scripts/run-tests.cjs` partitions unit, integration, install, security, slow, and QA suites. Fast-check property tests, c8 coverage, Stryker mutation testing, ESLint, secret/base64 scans, shell checks, install smoke tests, packaging tests, and generated parity checks appear in package scripts [33985c1:package.json:L56-L80] [33985c1:package.json:L82-L145].

Tests emphasize contracts and historical failure classes:

- runtime descriptor/layout/config parity and real install projection;
- generated artifact and docs inventory parity;
- state concurrency, preservation, CRLF, schema, and transition behavior;
- installer migrations, rollback, path confinement, symlinks, and ownership;
- hook registration, orphans, malformed payloads, blocking/advisory modes;
- capability hashing, consent, trust disclosure, overlay precedence, and prototype-pollution resistance;
- worktree branch/base/path/cwd/manifest safety;
- prompt injection patterns, Unicode tags, URL secrets, and adversarial fixture documents;
- command/workflow/reference/agent documentation parity.

Passing tests are meaningful evidence here because many mutate independent temporary files, create concurrent writers, execute actual subprocesses, and assert negative/boundary behavior. They remain bounded emulations of host behavior, not proof across every vendor runtime.

### 13.2 Security posture

Strong controls include:

- user-owned, content-bound consent for repository-planted executable capabilities;
- closed schema/enums and prototype-safe key checks;
- regular-file and size-bounded untrusted reads;
- symlink-aware root confinement and exclusive temp creation;
- atomic/fsynced writes plus verified-live lock holders;
- redaction/truncation in trust and model/config diagnostics;
- fail-closed role projection when an agent cannot be represented safely;
- prompt-boundary instructions shared by research/doc-ingest roles;
- worktree path, branch, base, cwd, and catastrophic-shrink guards;
- package legitimacy, secret scan, conventional-commit, and security test suites.

Residual risks:

- Agents and workflows ultimately execute shell commands with the user's privileges. Prompt text is not a sandbox.
- Regex-based prompt-injection scanners cannot understand intent or novel attacks, and most are advisory/fail-open.
- Explicit bypasses such as `GSD_ALLOW_SYMLINKED_DEST` and `GSD_ALLOW_PLANNING_SHRINK` transfer responsibility to the operator.
- Global capability overlays are treated differently from project overlays; compromise of the user-owned GSD home is outside the repository-consent threat model.
- Several runtime host facts are `undocumented`, so declared support does not equal verified isolation or event semantics.
- A giant installer remains a broad mutation boundary despite confinement and rollback tests.

## 14. Documentation, generated, source, configuration, and test drift

### 14.1 Confirmed synchronized surfaces

At the pinned commit, the generated-sync command passed for:

- capability registry;
- loop-host contract;
- capability matrix;
- 47 versioned manifests at `1.9.1`;
- inventory manifest;
- package identity;
- 71 plugin skills;
- documentation registries;
- 71-entry ADR index;
- 49 glossary references and all-runtime parity;
- nine compiled artifacts;
- context index.

This establishes byte/semantic parity for the surfaces those generators own.

### 14.2 Confirmed prose and coverage drift

1. **Agent count drift.** `docs/AGENTS.md` opens with “21 primary + 12 advanced = 33,” then immediately says 13 advanced and authoritative 34 [33985c1:docs/AGENTS.md:L1-L15]. `docs/ARCHITECTURE.md` also says total 33 [33985c1:docs/ARCHITECTURE.md:L208-L217]. The tree, manifest, and `docs/INVENTORY.md` have 34.
2. **Runtime matrix drift.** Architecture's runtime contract table lists 15 CLI runtimes through Cline and omits Kimi Code, Pi, and ZCode [33985c1:docs/ARCHITECTURE.md:L859-L885]. The installer and descriptors support 18 CLI runtimes, plus the separate VS Code extension descriptor. The same table says Kimi and Windsurf have no GSD hooks even though their current descriptors select `kimi-hooks-toml` and `windsurf-hooks-json`; generated descriptor data should win over this prose [33985c1:capabilities/kimi/capability.json:L45-L55] [33985c1:capabilities/windsurf/capability.json:L50-L59].
3. **Architecture overview drift.** The overview names only ten hosts [33985c1:docs/ARCHITECTURE.md:L22-L31], far fewer than the actual descriptor set.
4. **Hook behavior overgeneralization.** “All hooks … exit silently on error” is broadly true for unexpected exceptions, but false for recognized block conditions in the write/worktree/workflow/commit guards.
5. **Stale source comment.** `runtime-config-adapter-registry.cts` says “complete set of 16” config runtimes [33985c1:src/runtime-config-adapter-registry.cts:L97-L109]; its descriptor-derived set and installer currently contain 18. Generated tests do not inspect prose comments.
6. **CLI help omission.** The parser accepts `--pi` and `--kimi-code`, and `--all` includes them, but the long help text lists neither flag while listing ZCode [33985c1:bin/install.js:L642-L668] [33985c1:bin/install.js:L913-L913]. This is user-visible documentation drift.
7. **Manifest scope ambiguity.** The manifest is current but non-recursive and covers six families only. Calling it an exhaustive repository inventory would be wrong; `docs/INVENTORY.md` properly limits it to shipped surfaces.
8. **Translation drift.** Localized agent documents carry older count language in places; they should be regenerated or parity-checked for semantic counts, not merely link/file presence.

### 14.3 Historical decision evidence

Targeted history shows current architecture converging rapidly:

- `cc3ee301` fixed CommonJS marker ownership.
- `628648d6` capped emitted runtime bytes and single-sourced Windsurf handling.
- `640eaee1` fragmentized execute-phase and tested runtime composition.
- `05b170e4` productionized the context predicate store and CI gate.
- `00c859fa` moved Codex defaults before TOML generation.
- `82ca13f5` stopped deriving `current_phase_name` through lossy prose.
- `cfdfdf0b` completed the Codex hook set.

These commits explain why the pin contains extensive generated-sync, install confinement, and state-preservation code. They also indicate churn risk: adapters and docs can lag a fast-moving descriptor/runtime surface.

## 15. Runtime evidence

The persisted runtime evidence is under `work/evidence/open-gsd-gsd-core/`. Verified commands ran in the disposable build-materialized clone at the pinned commit with portable Node `22.23.2` and npm `10.9.8`. The first harness attempt correctly failed `check:env` because child scripts inherited the machine's default Node 26; those logs were preserved, the harness PATH was pinned to portable Node 22, and the corrected run passed. No credentials, network services, global installs, paid APIs, commits, pushes, or source edits were used.

| Command/check | Exit | Relevant result |
|---|---:|---|
| work-state preflight on analysis clone | 0 | clean `next`, exact pin, `origin/next`, fresh remote evidence |
| CSV↔`git ls-files` reconciliation and SHA-256 re-hash | 0 | 2,730/2,730; 0 missing/extra/mismatch/error |
| full candidate read + byte/newline scan | 0 | 2,725 gear candidates; 36,203,101 bytes; 773,276 LF bytes; three NUL-bearing gear files |
| command→workflow and skill reference check | 0 | 71 commands, 71 skills; no missing live command workflow targets |
| pristine-source `node scripts/gen-inventory-manifest.cjs --check` | 1, expected | only 17 tracked CJS files; reports the 156 build outputs absent |
| `npm run lint:generated-sync` via Node 22 in build-materialized clone | 0 | every listed generator/parity check current; see `generated-sync.stdout.log` |
| `npm run check:env` via Node 22 | 0 | environment gate passed; see `check-env.stdout.log` |
| targeted issue-607 installer dry-run suite | 0 | 5/5 passed; see `issue-607.stdout.log` |
| direct `atRefContractStillResolvesAfterComposition` | 0 | 1/1 passed; see `atref-composition.stdout.log` |
| previously reported 18-file targeted bundle | unverified | the exact command/file list and stdout/stderr were not supplied or reconstructed; the reported 877 total / 865 pass / 12 skip is withdrawn as audited evidence |
| previously reported full-install and grouped-adapter timeouts | unverified | exact commands, stdout/stderr, process list, and cleanup proof were not supplied; duration and causal claims are withdrawn |
| final `git status --short` in analysis and runtime clones | 0 | both clean |

`runtime-verification.json` records each retained command, exact arguments, working directory, exit code, elapsed time, stdout/stderr file, Node/npm version, and the explicit downgrade of the two unpersisted coordinator reports. The green generated-sync result applies only after the runtime clone's `npm ci`/`prepare` build has materialized 156 ignored CJS outputs; it must not be read as evidence that the pristine source checkout passes the same manifest check.

## 16. Reusable patterns and clean-room guidance

All patterns below are available under MIT, but a clean-room adopter should copy concepts first, preserve required attribution for copied code, and re-derive host-specific facts from current vendor documentation.

| Pattern | Provenance | Prerequisites/adaptation | Tradeoffs |
|---|---|---|---|
| Canonical prompt IR → host projections | commands + `runtime-artifact-conversion` + ADR-1508 | define one canonical dialect, closed transform registry, post-projection validation, golden fixtures per host | converters become complex; lossy host features need explicit degradation |
| Descriptor-driven runtime layout | capability manifests + generated registry + layout/config adapters | validated schema, immutable registry, exact placement kinds, generated parity tests | descriptors cannot eliminate all host special cases |
| File-backed agent state | `.planning` templates + state transition core | formal ownership of fields, pure intents, atomic locked writer, disk-derived fields | Markdown remains weakly structured and costly to migrate |
| Producer/checker split | planner/checker, researcher/synthesizer, writer/verifier | independent tool scopes, structured verdict, bounded retry, explicit override | more latency/token cost; checker can share model blind spots |
| Twelve-point contribution bus | loop contract + resolver + capability activation | closed lifecycle points, ordered fragments, one config snapshot, active-state semantics | fail-open extension load means optional gates are not absolute controls |
| User-owned content-bound consent | loader/trust/consent modules | realpath project identity, full-bundle hash, disclosure signature, atomic locked store | operational complexity and re-consent UX |
| Manifest-scoped worktree cleanup | execute workflow + worktree CLI | record exact path/branch/base/agent; validate on write and read; refuse scanning fallback | host-specific worktree semantics and recovery complexity |
| Generated drift gates | package scripts and generator `--check` modes | deterministic generators, committed artifacts, CI equality checks | only catches declared surfaces; prose can still drift |
| Progressive disclosure with closed fragments | namespace skills + ADR-1671 composer | measured budgets, explicit fragment priority/strategy, marker parser, per-runtime checks | premature fragmentation can obscure flow; metrics must reflect real host limits |
| Evidence-backed empty-return recovery | plan/execute workflows | disk artifacts and commits independent from agent narration, explicit choices | requires careful idempotency and can surface partial work |
| Safety ratchet instead of overwrite | state preservation and installer migrations | classify authority per field/file, snapshot before writes, rollback after late failure | more state and test cases; fallback ownership must be explicit |

Recommended clean-room sequence:

1. Start with a small canonical artifact graph and pure state transition core.
2. Add one reference host and one adapter; validate emitted behavior end to end.
3. Introduce role-separated producer/checker loops with hard iteration caps.
4. Add a generated descriptor registry only after two runtimes expose repeated axes.
5. Put executable project extensions behind user-owned, content-bound consent.
6. Add worktree isolation only with exact manifest ownership and recovery tests.
7. Keep a whole-tree inventory separate from curated shipped-surface manifests.
8. Gate generated parity and documentation counts independently.

## 17. Weaknesses and improvement opportunities

### High leverage

1. **Decompose the installer further.** The repository has already extracted layout, conversion, hooks, engine, migrations, runtime homes, and config intent, yet the top-level installer remains 13.5k lines. Move remaining host branches behind descriptor-selected, single-purpose modules and make the main function a short transaction coordinator.
2. **Create a truly recursive whole-tree manifest.** Keep the curated six-family inventory, but add a separate generated ledger covering every tracked behavioral file with category, ownership (`source/generated/fixture/doc`), generator, and terminal references. This would turn the current external CSV research method into a native project control.
3. **Generate public counts and runtime tables.** Agent totals, CLI runtime flags, host overview, and matrix rows should derive from the capability/inventory registry. This would eliminate the confirmed 33/34, 15/18, and help-flag drift.
4. **Make hook failure policy machine-readable.** Each hook should declare `advisory`, `fail-open`, or `fail-closed-on-match`, plus supported hosts/events. Generate docs/tests from the declaration.

### Medium leverage

5. **Separate host claims from verified compatibility.** Descriptor fields such as `undocumented` are honest, but a support dashboard should record last vendor-doc verification, tested version, test class, and unsupported semantics.
6. **Split giant tests by behavioral contract.** Large monolithic suites cause 2–4 minute bounded runs and obscure which subsystem is slow. Preserve real integration coverage while adding isolated entry points and timings.
7. **Add semantic parity for translations.** Count/runtime/support statements should be generated tokens or tested facts, not copied prose.
8. **Complete dispatcher extraction.** Finish moving leaf commands out of `gsd-tools.cjs`, then enforce a size/registry parity contract without hard-coding implementation line counts.
9. **Strengthen injection boundaries where hosts allow it.** Prefer pre-execution structured policy enforcement over post-read regex warnings; preserve the advisory scanner as a signal, not a security claim.

### Lower leverage / clarity

10. Replace stale numeric comments (“16 runtimes”) with generated facts or nonnumeric wording.
11. Surface timeout guidance in contributor docs for install/Codex adapter suites.
12. Clarify that “Local” configuration is cross-cutting and runtime-specific, while Global/Project/Session are more coherent persistence layers.

## 18. Unresolved items and limits

- Vendor-host behavior was not live-tested against Claude, Codex, Kimi, OpenCode, Kilo, Cursor, VS Code, or other products. Descriptor and fixture results are repository facts, not independent vendor certification.
- No network-based reviewer, MCP, Graphify, Brave search, package registry, or update path was invoked.
- Full install-suite, grouped Codex-adapter completion, and the previously reported 18-file/865-pass bundle remain unverified because their exact commands and logs were not available; no duration, skip, cleanup, or causal assertion from those reports is treated as audited evidence.
- The persisted targeted tests do not independently exercise every Unix FIFO, symlink, invalid-byte filename, vendor-host, installer, or adapter path.
- The broad reference ledger gives every one of its 42,366 rows a terminal disposition and leaves zero generic unresolved rows, but path classification alone is not a semantic proof. One unique broken repository-owned Markdown edge is confirmed and retained separately.
- The repository's future-dated Gemini sunset claim was treated as an author/source claim only; it was not independently verified because this report is pinned-source research, not current vendor-status research [33985c1:GEMINI.md:L1-L55].
- A background research subagent was requested by the research skill but unavailable because the collaboration slot limit was already full; all repository analysis was therefore performed in this agent, with independent runtime evidence supplied by the root coordinator.

## 19. Evidence index

### Primary architecture and inventories

- `package.json` — package, bins, publication set, dependencies, scripts, runtime floor.
- `docs/ARCHITECTURE.md` — conceptual layers, workflow/agent model, `.planning`, installer, hooks, runtime prose.
- `docs/INVENTORY.md` and `docs/INVENTORY-MANIFEST.json` — curated shipped surfaces.
- `scripts/gen-inventory-manifest.cjs` — manifest scope and check behavior.
- `docs/adr/457-generated-cjs-single-source.md` — source/compiled ownership.
- `docs/adr/1244-capability-ecosystem.md` — generated registry and extension model.
- `docs/adr/1508-runtime-artifact-conversion-module.md` — conversion/layout ownership.
- `docs/adr/1671-dynamic-context-management-platform.md` — predicate/fragment/budget design and corrected premise.

### Runtime, installer, plugins

- `capabilities/*/capability.json` — 19 runtime, 20 feature, five reviewer descriptors.
- `bin/install.js` — runtime selection, migration, materialization, host config, rollback.
- `src/runtime-config-adapter-registry.cts`, `runtime-artifact-layout.cts`, `runtime-artifact-conversion.cts`, `runtime-hooks-surface.cts`, `install-engine.cts`, `runtime-homes.cts`.
- `.opencode/plugins/gsd-core.js`, `.kilo/plugins/gsd-core.js`, `pi/gsd.cjs`, `vscode/*`, `.claude-plugin/*`.

### State, loops, agents, security

- `gsd-core/templates/state.md`, `src/state.cts`, `src/state-transition.cts`, `src/phase-lifecycle.cts`.
- `gsd-core/bin/lib/loop-host-contract.cjs`, `src/loop-resolver.cts`.
- `gsd-core/workflows/plan-phase.md`, `execute-phase.md`, nested modes/steps, and referenced guard fragments.
- all 34 `agents/gsd-*.md`, all 71 `commands/gsd/*.md`, all 71 generated skills, 117 workflow files, and 115 reference files.
- `hooks/hooks.json`, all 25 managed hook scripts, shared registry, and hook library files.
- `src/capability-loader.cts`, `capability-consent.cts`, `capability-trust.cts`, `capability-state.cts`, `capability-activation.cts`.

### Verification corpus

- all 899 tracked test files/assets were included in the exhaustive read.
- persisted Node 22 runtime checks: `check:env`, generated-sync in the build-materialized clone, issue-607 dry-run (5/5), and direct `atRefContractStillResolvesAfterComposition` (1/1), with exact stdout/stderr and timing metadata.
- `references.csv` and `reference-summary.json`: 42,366 extracted rows, zero unresolved-static rows, two rows representing one confirmed broken edge.
- path/hash inventory, canonical reference checks, source-versus-built manifest behavior, git status, and targeted history commands described in §15.

## 20. Bottom line

At `33985c1`, GSD Core is a mature but fast-moving multi-runtime orchestration framework whose real differentiator is the combination of prompt programming, deterministic file-state machinery, adversarial role separation, and install-time host projection. The implementation is substantially better synchronized than the broad prose suggests: generated artifacts, source outputs, inventories within their declared scope, and targeted behavioral tests are green. The remaining risk is concentrated in boundaries that generators cannot fully own—vendor host behavior, fail-open hook errors, enormous installer/test modules, and human-authored documentation counts. Adopt the state/loop/consent/projection patterns, but carry over their tests and explicit failure semantics rather than copying prompt files alone.

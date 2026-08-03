# BMAD-METHOD agent architecture report

## Snapshot and provenance

This report describes the repository exactly at commit `770d4259853b9600680745bb2c710bee82604cb4` on `main` (`fix(installer): apply --set core overrides before config collection (#2671)`, committed 2026-08-02). The checkout was clean before and after the analysis and tracked `origin/main`. `git describe` returned `v6.10.0-52-g770d4259`. Package metadata identifies the artifact as `bmad-method` 6.10.0, the two CLI entry names as `bmad` and `bmad-method`, Node entry point `tools/installer/bmad-cli.js`, and license as MIT (`770d425:package.json:L3-L24`).

Evidence labels used throughout:

- **[Claim]** is wording or positioning asserted by the authors.
- **[Fact]** is directly observable in the pinned source/configuration.
- **[Runtime]** is an observation from a command run against this checkout.
- **[Inference]** is an interpretation that combines source evidence; it is not represented as an author guarantee.

The repository itself is the primary source. No web pages, credentials, paid services, production systems, global installations, or Context7 material were used. Context7 was deliberately omitted because this is a pinned, project-internal architecture question, not a current third-party API question. Targeted history was limited to files central to the current architecture.

Work-state evidence at the start was refreshed at `2026-08-02T12:32:02.7648707Z`: repository `C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\repos\bmad-method`, branch `main`, pinned HEAD, clean worktree, upstream `origin/main`. The preflight also emitted raw provider data for an open `main -> main` PR #2632; that is remote discovery evidence, not evidence that this analysis checkout owns or should act on the PR. No branch, commit, push, PR, install, or source mutation was performed.

## Executive summary

**[Inference]** BMAD-METHOD is best understood as a compiler-and-runtime distribution for agent instructions, not as an autonomous agent framework in the conventional server sense. Its authored source is a graph of skill packages (`SKILL.md`, workflow steps, prompts, templates, TOML customization descriptors, and small Python/Node tools). The installer compiles that graph into IDE-specific skill directories and pointer files. At run time, an AI host interprets Markdown protocols; deterministic scripts handle configuration merging, immutable workflow snapshots, sprint state, evidence extraction, and atomic persistence.

The strongest architectural ideas are:

1. A common canonical skill tree exposed through 45 host profiles. All profiles map to a native project skill directory, 42 also declare a global directory, 25 share `.agents/skills` and are batch-deduplicated, and only `github-copilot` and `opencode` request auxiliary command pointers (`770d425:tools/installer/ide/platform-codes.yaml:L15-L343`; `770d425:tools/installer/ide/_config-driven.js:L218-L257`).
2. Four-layer central project configuration plus three-layer per-skill customization, merged structurally and fail-fast on malformed present TOML (`770d425:src/scripts/config_utils.py:L17-L34`; `770d425:src/scripts/config_utils.py:L98-L118`).
3. Content-addressed, immutable workflow snapshots: only source-authored tokens are expanded, inserted prose is opaque, output identity includes project root, renderer, resolved values and source hashes, and publication is staged and verified (`770d425:src/scripts/render_skill.py:L232-L267`; `770d425:src/scripts/render_skill.py:L270-L380`).
4. Explicit operational state machines in Markdown, reinforced by deterministic scripts: planning artifacts move through named statuses; review findings are typed and routed; autonomous review repair is bounded at five iterations (`770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L59-L62`).
5. Conservative installer ownership: copied skills and generated pointers are inventoried; hand-edited pointers and `bmad-os-*` utilities are preserved during cleanup (`770d425:tools/installer/ide/_config-driven.js:L541-L542`; `770d425:tools/installer/ide/_config-driven.js:L674-L679`; `770d425:tools/installer/ide/_config-driven.js:L789-L790`).

The largest practical risks are not hidden algorithms but trust and portability boundaries. Agent customization can inject activation instructions, persistent file globs, menus, completion actions, and prose into a workflow. External modules are cloned and may execute `npm install` in a user cache. Some installer cleanup reads suppress errors to avoid deleting uncertain files. The current validation suite also has observable Windows/CRLF blind spots: the skill validator rejects all 48 valid skills because it searches only LF delimiters, and parts of the renderer test only recognize Unix absolute paths and LF fenced blocks.

## Exhaustive gear inventory and coverage

### Repository-wide coverage

**[Runtime]** `git ls-files` returned 618 tracked files totaling 7,384,940 bytes. Every tracked path was opened for metadata and SHA-256 hashing; failures: 0. Behavior-bearing text was additionally covered by: all JavaScript/ESM parse checks (65 files), all Python AST checks (31), all TOML parses (36), all YAML parses (20), all JSON parses (11), Markdown link validation across 168 documentation files, exhaustive `SKILL.md` enumeration, reference-token extraction, test execution where dependencies permitted, and manual traversal of workflows, prompts, templates, installer/generator code, config schemas, manifests, and behavior-defining tests. Binary images and web assets were inventoried and hashed; they do not contain executable behavior.

| Gear | Inventory and analysis |
|---|---|
| Canonical skills | 48 `SKILL.md` packages: 34 BMM and 14 core; every package and companion file inspected |
| Agent personas | 5: Mary/Analyst, Winston/Architect, Amelia/Developer, John/Product Manager, Sally/UX Designer |
| Active BMM planning | 10: architecture, epics/stories, document-project, project-context, PRD, PRFAQ, product-brief, spec, sprint-planning, UX |
| Active BMM shipping | 7: build-auto, build, checkpoint-preview, code-review, correct-course, QA E2E, retrospective |
| BMM compatibility | 12 v6 shims/legacy entry points |
| Active core | 8: advanced-elicitation, brainstorming, customize, deep-recon, forge-idea, help, party-mode, review |
| Core compatibility | 6 review/editorial shims |
| Claude marketplace packages | 6 plugin packages |
| External official module registry | 7 modules, including one deprecated module |
| IDE/agent hosts | 45 configured platform codes |
| Language files | 31 tracked Python and 65 tracked JavaScript/ESM files across runtime, installer, tools, tests and website; these are extension counts, not all runtime scripts |
| Docs/site | 174 `docs/` files plus Astro website source/config and 18 prebuilt `web-bundles` |
| Tests | 24 tracked paths under `test/`: 11 top-level files, of which 10 are executable JS/MJS tests and one is `README.md`; plus 15 colocated Python test files under `src/**/tests/` |

The exact 48 canonical skill IDs are:

- Agents: `bmad-agent-analyst`, `bmad-agent-architect`, `bmad-agent-dev`, `bmad-agent-pm`, `bmad-agent-ux-designer`.
- Planning: `bmad-architecture`, `bmad-create-epics-and-stories`, `bmad-document-project`, `bmad-generate-project-context`, `bmad-prd`, `bmad-prfaq`, `bmad-product-brief`, `bmad-spec`, `bmad-sprint-planning`, `bmad-ux`.
- Shipping: `bmad-build`, `bmad-build-auto`, `bmad-checkpoint-preview`, `bmad-code-review`, `bmad-correct-course`, `bmad-qa-generate-e2e-tests`, `bmad-retrospective`.
- BMM compatibility: `bmad-create-architecture`, `bmad-create-prd`, `bmad-create-story`, `bmad-dev-auto`, `bmad-dev-story`, `bmad-domain-research`, `bmad-edit-prd`, `bmad-market-research`, `bmad-quick-dev`, `bmad-sprint-status`, `bmad-technical-research`, `bmad-validate-prd`.
- Core: `bmad-advanced-elicitation`, `bmad-brainstorming`, `bmad-customize`, `bmad-deep-recon`, `bmad-forge-idea`, `bmad-help`, `bmad-party-mode`, `bmad-review`.
- Core compatibility: `bmad-editorial-review`, `bmad-editorial-review-prose`, `bmad-editorial-review-structure`, `bmad-review-adversarial-general`, `bmad-review-edge-case-hunter`, `bmad-review-verification-gap`.

The 45 host codes are `adal`, `amp`, `antigravity`, `antigravity-cli`, `auggie`, `bob`, `claude-code`, `cline`, `codex`, `codewhale`, `codebuddy`, `command-code`, `cortex`, `crush`, `cursor`, `droid`, `firebender`, `gemini`, `github-copilot`, `goose`, `hermes`, `iflow`, `junie`, `kilo`, `kimi-code`, `kiro`, `kode`, `mistral-vibe`, `mux`, `neovate`, `ona`, `openclaw`, `opencode`, `openhands`, `pi`, `pochi`, `qoder`, `qwen`, `replit`, `roo`, `rovo-dev`, `trae`, `warp`, `windsurf`, and `zencoder` (`770d425:tools/installer/ide/platform-codes.yaml:L15-L343`). All 45 declare `target_dir`, 42 declare `global_target_dir`, and there are 21 unique project targets. Twenty-five profiles share `.agents/skills`; batch setup skips a duplicate skill write when a peer already owns the same target. Only `github-copilot` and `opencode` declare `commands_target_dir`, so auxiliary command-pointer generation is conditional rather than universal (`770d425:tools/installer/ide/_config-driven.js:L218-L257`; `770d425:tools/installer/ide/_config-driven.js:L266-L405`).

### Six Claude marketplace packages

The local `.claude-plugin/marketplace.json` publishes four single-skill packages (`bmad-brainstorming`, `bmad-party-mode`, `bmad-forge-idea`, `bmad-deep-recon`), a three-skill `bmad-analysis` pack, and `bmad-method-lifecycle`, which bundles active lifecycle skills, five agents, and selected compatibility shims (`770d425:.claude-plugin/marketplace.json:L10-L87`). This is packaging metadata; it is distinct from the external module registry.

### Seven official external modules

`bmad-modules.yaml` registers `bmad-loop`, Test Architecture Enterprise, Builder, Automator, Creative Intelligence Suite, Game Dev Studio, and WDS. The registry carries URL, module-definition location, aliases, stable/next channel behavior, optional npm package, deprecation, and post-install messages. `bmad-loop` is a marketplace plugin requiring a setup skill after install; `bmad-automator` is marked deprecated in favor of Loop (`770d425:bmad-modules.yaml:L37-L59`; `770d425:bmad-modules.yaml:L62-L128`).

## Architecture and layers

### Source, compilation, host, and artifact layers

1. **Authored source layer.** `src/core-skills` and `src/bmm-skills` hold canonical skills, workflow protocols, prompts, templates, catalogs, customization defaults and local scripts. `src/scripts` holds shared configuration, rendering, and memory utilities.
2. **Distribution/compiler layer.** `tools/installer/bmad-cli.js` loads Commander command modules; `install`, `status`, and `uninstall` delegate to the installer core and UI. Package metadata exposes both CLI aliases (`770d425:package.json:L21-L28`). The installer task graph installs shared scripts/modules, generates configs and manifests, applies `--set`, builds help/catalog data, and dispatches selected IDE handlers (`770d425:tools/installer/core/installer.js:L217-L371`).
3. **Host-adapter layer.** A config-driven handler installs canonical native skill directories into each unique selected target, detects path/canonical-ID collisions, and performs ownership-aware cleanup. Shared targets are deduplicated; auxiliary pointers exist only for profiles that configure a separate commands directory (`770d425:tools/installer/ide/_config-driven.js:L218-L257`; `770d425:tools/installer/ide/_config-driven.js:L292-L405`). Platform differences are primarily data in `platform-codes.yaml`.
4. **Rendered execution layer.** The build skills do not execute mutable source steps directly. Their entry command runs `render_skill.py`; failure, including missing `uv`, must halt (`770d425:src/bmm-skills/ship/bmad-build/SKILL.md:L7-L13`). The renderer resolves configuration and publishes a content-addressed generation under `_bmad/render/<skill>/<project-slug-root-hash>/<generation-hash>` (`770d425:src/scripts/render_skill.py:L322-L380`).
5. **Project artifact/state layer.** Planning and implementation outputs, story specs, sprint status, memlogs, review trails, research reports and documentation are normal files. The host agent is the orchestration runtime; the scripts make high-risk state transforms deterministic.

### Global / Project / Session / Local layering

| Layer | Concrete surfaces | Semantics |
|---|---|---|
| Global | Platform `global_target_dir` entries such as `~/.agents/skills`; external module cache under the user's `.bmad/cache`; host/plugin registries | Shared installation/discovery/cache. Forty-two profiles model global targets; a live global install was not exercised. |
| Project | `_bmad/config.toml`, module YAML, installed skill directories, `_bmad/scripts`, `_bmad/custom/*.toml`, outputs, `_bmad/render`, ownership manifests, story/spec/sprint status, and `.memlog.md` | Durable team/install/work state and canonical execution packages. Memlogs and statuses persist across sessions (`770d425:src/scripts/memlog.py:L5-L12`). |
| Session | Active persona, resolved prompt context, transient workflow variables, current dispatch choice, and model/subagent context | Ephemeral conversational execution. A session reads and mutates durable project artifacts but does not own their persistence. |
| Local/personal | `_bmad/config.user.toml`, `_bmad/custom/config.user.toml`, `_bmad/custom/<skill>.user.toml` | Logical personal ownership/precedence; these files physically live inside the project. Custom user files are intended to be gitignored; installer-owned config files are regenerated (`770d425:docs/how-to/customize-bmad.md:L292-L318`). |

Central configuration is loaded in lowest-to-highest precedence order: `_bmad/config.toml`, `_bmad/config.user.toml`, `_bmad/custom/config.toml`, `_bmad/custom/config.user.toml`. Per-skill customization is default `customize.toml`, team override, personal override. Tables merge recursively; arrays of tables with a common `code` or `id` replace matching entries and append new entries; other arrays append; scalars replace (`770d425:src/scripts/config_utils.py:L37-L118`). Missing optional layers are empty, but malformed present files raise a specific error.

## Events, state transitions, and loops

### Activation and dispatch events

Every persona skill follows the same event sequence: resolve the customized agent block; execute prepend steps; adopt persona; load persistent facts; load BMM config; greet; execute append steps; then directly dispatch a clearly named intent or show a numbered menu and wait. Persona, icon, language and persistent facts remain active until dismissal. The five agent entry files share this protocol; the analyst is the representative exact range (`770d425:src/bmm-skills/agents/bmad-agent-analyst/SKILL.md:L19-L76`; `770d425:src/bmm-skills/agents/bmad-agent-architect/SKILL.md:L19-L76`; `770d425:src/bmm-skills/agents/bmad-agent-dev/SKILL.md:L19-L76`; `770d425:src/bmm-skills/agents/bmad-agent-pm/SKILL.md:L19-L76`; `770d425:src/bmm-skills/agents/bmad-agent-ux-designer/SKILL.md:L19-L76`). Workflow skills similarly have activation hooks, persistent facts and an `on_complete` hook.

This is an event protocol interpreted by the host model, not an in-process event emitter. Hooks are TOML-supplied instruction arrays. **[Inference]** The benefit is portability across hosts; the cost is that enforcement depends on host compliance and the trustworthiness of prompt/config content.

### Build state machine

The canonical build path routes an existing spec by frontmatter state or creates a new one. Exact persisted interactive-Build states are:

`draft -> ready-for-dev -> in-progress -> in-review -> done`

Build Auto permits the same states plus terminal `blocked` (`770d425:src/bmm-skills/ship/bmad-build/spec-template.md:L1-L7`; `770d425:src/bmm-skills/ship/bmad-build-auto/spec-template.md:L1-L10`). “Planning”, “implementation”, and the prose standard “Ready for Development” are conceptual workflow phases/gates, not persisted status values.

The ready gate requires file-specific tasks, dependency order, Given/When/Then acceptance criteria, outermost-surface observability, no placeholders, sufficiency and coherence (`770d425:src/bmm-skills/ship/bmad-build-auto/workflow.md:L57-L67`). Interactive Build has a human plan checkpoint; intent is frozen after approval, implementation is delegated, verification is run, and multiple review lenses produce typed findings. The final presentation step creates a local conventional commit when the tree is dirty, never auto-pushes, and offers push/PR afterward (`770d425:src/bmm-skills/ship/bmad-build/step-05-present.md:L7-L9`; `770d425:src/bmm-skills/ship/bmad-build/step-05-present.md:L57-L67`). That auto-commit behavior is important for consumers whose own governance forbids commits without explicit approval.

Build Auto is intentionally unattended. Subagents are mandatory and synchronous; reviewer calls may be awaited in parallel but may not be detached because the workflow has no resumable background event loop (`770d425:src/bmm-skills/ship/bmad-build-auto/workflow.md:L51-L55`). Findings cascade as:

- `intent_gap`: save a patch, revert code, write blocked status, and halt.
- `bad_spec`: preserve successful constraints, revert code, amend only outside the frozen intent contract, reimplement, and re-review.
- `patch`: automatically fix and rerun verification.
- `defer` / `reject`: preserve disposition in the review trail rather than silently mutate intent.

The bad-spec repair loop increments `review_loop_iteration` and blocks after five non-convergent repairs. Successful finalization commits remaining reviewed files, does not push, and requires a clean version-controlled tree (`770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L59-L62`; `770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L93-L94`).

### Sprint and retrospective state

The sprint planner recognizes story states `backlog`, `ready-for-dev`, `in-progress`, `review`, `done`; epic progression `backlog`, `in-progress`, `done`; and retrospective optional/done. Legacy `drafted` and `contexted` normalize to `ready-for-dev` and `in-progress`; default staleness is seven days (`770d425:src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py:L59-L70`). It preserves progress rather than downgrading implicitly, supports dry-run/set/validate operations, and writes atomically with rollback on post-write failure (`770d425:src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py:L329-L461`).

Retrospective state has verdicts `accepted`, `accepted-with-open-items`, `rejected` and action statuses `open`, `in-progress`, `done`. Its updater preserves YAML formatting/comments through `ruamel.yaml`, atomically swaps the file, validates the result, and can restore original bytes (`770d425:src/bmm-skills/ship/bmad-retrospective/scripts/sprint_status.py:L33-L37`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/sprint_status.py:L559-L653`). Git evidence derives change statistics from the local log rather than from model recollection.

### Memory and research loops

`memlog.py` implements append-only chronological **body entries** and deliberately has no entry edit/delete command or lifecycle-status field. Its `set` command may replace descriptive frontmatter fields; completion/blocking still has to be appended as an event (`770d425:src/scripts/memlog.py:L18-L35`; `770d425:src/scripts/memlog.py:L61-L67`). Writes use temp file, flush/fsync, and atomic rename (`770d425:src/scripts/memlog.py:L110-L129`). Brainstorming and Forge use it as durable project memory across sessions while generating derived artifacts.

Deep Recon supports draft, process, run, refresh, and deepen paths. Run mode fans out research packs, then reconciles claims, provenance and staleness. Brainstorming exposes 108 methods across 13 categories in the executable catalog; Advanced Elicitation exposes 71 methods across 12 categories. These counts were confirmed at runtime, not taken from marketing prose.

## Agents, roles, personas, skills, plugins, and hooks

### Personas and menus

| Agent | Declared function | Current menu surface |
|---|---|---|
| Mary, Business Analyst | research, evidence, requirements and discovery | BP brainstorm; MR market recon; DR domain recon; TR technical recon; TS thinking selection; CR competitive research; UV user-voice research; CB product brief; WB PRFAQ; DP document project |
| John, Product Manager | product strategy and requirements | PRD; create epics/stories; implementation readiness/sprint planning; correct course |
| Winston, Architect | systems architecture and implementation readiness | create architecture; implementation readiness |
| Amelia, Developer | implementation, QA and review | Build; QA E2E; code review; sprint planning; retrospective |
| Sally, UX Designer | UX research/design | create UX design |

The fixed identity appears in each `SKILL.md`; the customizable overlay comes from `customize.toml`. Customization includes role, identity, communication style, principles, activation steps, persistent facts, menu entries, and completion hooks. Names/titles are intentionally fixed while the overlay is mutable. Menu entries dispatch a skill ID or literal prompt. Persistent `file:` facts may load project globs such as `**/project-context.md`.

### Skill composition

- `bmad-help` is the routing surface over installed catalogs.
- `bmad-advanced-elicitation` is an iterative refinement engine.
- `bmad-review` selects applicable lenses: adversarial, edge-case, verification-gap, structure, and prose. Lenses can be replaced or extended via customization (`770d425:docs/reference/core-tools.md:L82-L98`).
- `bmad-brainstorming`, `bmad-forge-idea`, and `bmad-party-mode` provide divergent ideation, adversarial idea hardening, and multi-persona discussion.
- `bmad-deep-recon` consolidates market, domain and technical research.
- Planning workflows transform discovery into product brief/PRFAQ/PRD/UX/architecture/epics/spec/project context/sprint state.
- Shipping workflows implement, preview, review, correct, test, and retrospect.

Party Mode can run named parties and individual personas using subagents, agent-team mode, or automatic orchestration. Build and Build Auto use implementation and review subagents as execution primitives. Subagents receive bounded packets rather than relying on hidden shared memory; the workflow then reconciles their outputs against a canonical spec and diff.

### Plugin/module distinction

The six Claude marketplace packages are alternative packaging selections over this repository's skills. The seven official modules are externally sourced packages resolved by the installer. They are not interchangeable concepts: one describes local skill bundles; the other is a network/cache/install extension mechanism.

### Hook surfaces

There are two meanings of hook:

1. Agent/workflow prompt hooks: `activation_steps_prepend`, `activation_steps_append`, and `on_complete`, structurally merged from TOML and executed by the AI host.
2. Development/installation hooks: Husky `prepare`, platform-generated pointers, and module-specific post-install instructions/scripts. The repository package prepares Husky when available (`770d425:package.json:L42-L43`).

No always-running daemon, message bus, scheduler, database, or remote telemetry client was found in the pinned source. Observability is file- and CLI-oriented: status JSON, manifests, logs, review trails, output artifacts, explicit HALT messages, and test output.

## Workflows and reference graph

### Primary lifecycle graph and terminal branches

```text
brainstorm / deep recon / forge / existing-project scan
                         |
                         v
product brief or PRFAQ -> PRD / spec -> UX / architecture
                                      |
                                      v
                         epics + stories / project-context
                                      |
                                      v
                              sprint planning
                                      |
                  +-------------------+------------------+
                  |                                      |
          interactive Build                       Build Auto
                  |                                      |
     +--- one-shot -> local commit/done       ready-for-dev halt
     |            or no-VCS done                    or
     +--- plan -> implement -> review         bounded review/repair loop
                  |                                      |
     human checkpoint / local commit             done / blocked
                  |                                      |
                  +----------> sprint state <-------------+
                                  |
                   QA / correct course / retrospective
```

Build's one-shot branch is reserved for asserted zero blast radius and writes a `done` trace, commits locally when VCS is available, and never auto-pushes (`770d425:src/bmm-skills/ship/bmad-build/step-01-clarify-and-route.md:L93-L105`; `770d425:src/bmm-skills/ship/bmad-build/step-oneshot.md:L41-L55`). Build Auto may halt after planning at persisted `ready-for-dev`, or terminate `blocked` through its scripted prompt protocol (`770d425:src/bmm-skills/ship/bmad-build-auto/step-02-plan.md:L14-L23`). Its successful finalizer distinguishes no-VCS `done` from VCS commit/clean-tree `done` (`770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L89-L96`). These status writes and VCS actions are prompt-enforced; the Python renderer only materializes the immutable instruction snapshot. Checkpoint Preview, QA E2E, and Code Review are side-entry workflows: human walkthrough, test-only generation, and ad hoc adversarial review respectively (`770d425:src/bmm-skills/ship/bmad-checkpoint-preview/SKILL.md:L1-L10`; `770d425:src/bmm-skills/ship/bmad-qa-generate-e2e-tests/SKILL.md:L1-L10`; `770d425:src/bmm-skills/ship/bmad-code-review/SKILL.md:L1-L11`).

This graph is a synthesis of direct menu references, skill instructions, workflow step links, templates and the help catalog. It is not a single central executable DAG.

### Compatibility forwarding graph

- `bmad-create-architecture -> bmad-architecture`
- `bmad-create-prd`, `bmad-edit-prd`, `bmad-validate-prd -> bmad-prd`
- market/domain/technical research shims `-> bmad-deep-recon`
- `bmad-sprint-status -> bmad-sprint-planning`
- `bmad-quick-dev -> bmad-build`; `bmad-dev-auto -> bmad-build-auto`
- six editorial/review shims `-> bmad-review`
- `bmad-create-story` and `bmad-dev-story` remain self-contained deprecated legacy workflows rather than thin forwarders; new work is routed toward Build.

### Internal references

The immutable workflow renderer recognizes `[[bmad-snapshot:<relative-markdown>]]`; it rejects undeclared targets, substitutes only source-authored tokens in one opaque pass, and does not rescan inserted customization prose (`770d425:src/scripts/render_skill.py:L30-L33`; `770d425:src/scripts/render_skill.py:L232-L267`). The checkout contained 39 snapshot-token occurrences and 10 unique snapshot targets; all resolved within their declared skill source sets. The documentation validator traversed 168 doc files and reported zero broken links.

The official validator was run in a disposable clone after `npm ci --ignore-scripts --no-audit --no-fund`: `node tools/validate-file-refs.js --strict` scanned 202 source Markdown/YAML/XML/CSV files and checked 188 references. Result: **187 resolved, 1 broken, 0 absolute-path leaks, exit 1**. The reported target is `./architecture-server.md` at `src/bmm-skills/plan/bmad-document-project/workflows/full-scan-instructions.md:854`; it occurs in an example structure for a not-yet-generated project document, and the same example's `line_text` describes it as “To be generated” (`770d425:src/bmm-skills/plan/bmad-document-project/workflows/full-scan-instructions.md:L849-L858`). It is therefore a future/generated-artifact example rather than a missing shipped executable, but it is still an unresolved static target and fails the official strict gate. The validator covers project-root/shorthand paths, quoted relatives, `exec`, `invoke-task`, step metadata, load directives, CSV workflow files, and absolute-path leaks; it explicitly defers runtime mustache/config dereferences (`770d425:tools/validate-file-refs.js:L1-L26`; `770d425:tools/validate-file-refs.js:L41-L70`; `770d425:tools/validate-file-refs.js:L182-L327`). No zero-broken-reference claim is made.

## Script execution paths

### Installation

```text
npx bmad-method install
  -> tools/installer/bmad-cli.js
  -> commands/install.js
  -> installer UI / ExistingInstall / InstallPaths
     -> parse/filter --set values
     -> seed setOverrides.core before config collection
        -> dependent module artifact paths/config snapshot seeded core values
  -> Installer.install()
     -> resolve channel + official/custom modules
     -> install shared _bmad/scripts
     -> copy selected module trees
     -> generate central and module configs
     -> generate skill/help catalogs + ownership manifests
     -> post-write applySetOverrides patch
        -> core and selected non-core TOML values
     -> config-driven platform handlers
        -> copy canonical skill directories once per unique target
        -> emit auxiliary pointers only where commands_target_dir is configured
        -> ownership-aware cleanup
     -> module post-install instructions/scripts
```

The pinned commit implements **two phases**, not a wholesale move. The UI parses/filters `--set`, then seeds core values before collection because `output_folder` affects module paths and module config snapshots (`770d425:tools/installer/ui.js:L780-L835`). After configs and manifests are written, `Installer.install()` still applies the complete core/non-core override map as a TOML patch (`770d425:tools/installer/core/installer.js:L295-L342`). Targeted history shows the current model was assembled recently: inspectable workflow snapshots (`c2530ea5`), shared build renderer (`6245e34d`), skills reorganized into agents/plan/ship (`57ad7931`), and sprint skills consolidated (`cf54f4d7`). These commits explain the current file layout but do not supersede pinned-source behavior.

### Runtime configuration and rendering

```text
Build SKILL entry
  -> uv run --no-cache _bmad/scripts/render_skill.py
  -> load all skill Markdown sources + required workflow.md
  -> load four central config layers
  -> load three customization layers when tokens require them
  -> resolve config/custom/snapshot tokens
  -> hash project root + renderer + resolved inputs + source bytes
  -> publish/verify immutable generation atomically
  -> print absolute generated workflow.md entry
  -> host reads one step at a time
```

An existing generation must match its manifest, file set, and output hashes; collisions or corruption halt (`770d425:src/scripts/render_skill.py:L270-L319`). This is a strong reproducibility boundary, although absolute project path participates in identity, so the same project at another path deliberately receives a different generation.

### State helpers

- `resolve_config.py`: returns complete merged central config or a dotted key.
- `resolve_customization.py`: locates project root at `_bmad`/`.git`, merges skill defaults/team/user, and returns all or a dotted key.
- `memlog.py`: initializes/appends/sets append-only session facts using atomic replacement.
- `sprint_plan.py`: generates, validates, updates and recommends work from sprint YAML; emits machine-readable errors.
- retrospective `git_evidence.py`: sanitizes/queries Git history and calculates file/change evidence.
- retrospective `sprint_status.py`: validates and atomically applies retrospective outcomes/actions.
- architecture linter: validates architecture decision IDs, required fields, placeholders and stack pinning.
- catalog CLIs: brainstorming/elicitation selection, research slugging, word metrics, document-project scanning.

## Operations: install, update, migration, recovery, removal

### Install/update

The installer takes a project path, selected official/custom modules and selected hosts. It snapshots the existing installation, preserves core answers, and backs up custom/modified material into `_bmad-custom-backup-temp` and `_bmad-modified-backup-temp` before replacement (`770d425:tools/installer/core/installer.js:L590-L657`). It refreshes runtime-owned shared scripts while protecting custom/render surfaces (`770d425:tools/installer/core/installer.js:L660-L696`), regenerates configs/manifests, installs each unique skill target, and restores protected user content. Update checking is asynchronous and non-blocking at CLI startup (`770d425:tools/installer/bmad-cli.js:L18-L46`).

The host adapter rejects unsafe canonical IDs, checks duplicate pointer paths, and distinguishes generated pointers from hand-edited files (`770d425:tools/installer/ide/_config-driven.js:L292-L405`). Cleanup is surgical: it uses old/current manifests and removal lists, and preserves `bmad-os-*` plus directories it cannot confidently own (`770d425:tools/installer/ide/_config-driven.js:L499-L570`; `770d425:tools/installer/ide/_config-driven.js:L682-L819`). **[Inference]** This favors data preservation over strict convergence; the price is that stale files can survive when metadata is unreadable.

### External/custom modules

Official modules resolve stable/next channels, clone shallow repositories to `~/.bmad/cache/external-modules`, and record resolved ref/SHA (`770d425:tools/installer/modules/external-manager.js:L191-L223`; `770d425:tools/installer/modules/external-manager.js:L364-L436`). Custom sources support local paths or Git URLs/subdirectories/refs and maintain cache metadata (`770d425:tools/installer/modules/custom-module-manager.js:L324-L376`; `770d425:tools/installer/modules/custom-module-manager.js:L399-L547`). Both paths sanitize Git's repository-targeting environment before cache operations. The comment records the concrete failure prevented: inherited `GIT_DIR`/`GIT_WORK_TREE` once allowed a cache refresh to hard-reset the developer repository (`770d425:tools/installer/modules/git-env.js:L4-L25`).

External package execution is explicit in source: `npm install --omit=dev --no-audit --no-fund --no-progress --legacy-peer-deps` runs in cloned module directories with a 120-second timeout and lifecycle scripts enabled (`770d425:tools/installer/modules/external-manager.js:L448-L490`; `770d425:tools/installer/modules/custom-module-manager.js:L556-L567`). **Failure is caught and continued**: both managers mark the spinner failed, suppress the detailed exception warning when `silent`, and still return the cache directory as usable (`770d425:tools/installer/modules/external-manager.js:L467-L502`; `770d425:tools/installer/modules/custom-module-manager.js:L568-L575`). Clone/ref success is therefore not proof of dependency readiness; installation can proceed with absent or stale production dependencies and there is no rollback/fail-fast propagation. This is both a supply-chain and partial-install reliability boundary.

### Migration and compatibility

Migration is handled by installer comparison, removal metadata, preserved custom/config layers, aliases and v6 shims. The current tree consolidates former research flows into Deep Recon, former editorial/review utilities into Review, Quick Dev into Build, and Sprint Status into Sprint Planning. Shims keep old IDs callable while guiding consumers to current flows.

### Recovery/removal

Generated workflow publication is staged, atomically renamed, and verifies an already-existing generation (`770d425:src/scripts/render_skill.py:L270-L319`). Sprint planning and retrospective writers preserve original bytes and attempt atomic restore on failed post-write validation (`770d425:src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py:L329-L461`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/sprint_status.py:L559-L653`). Installer module-cache Git operations are constrained to explicit cache working directories with a sanitized environment. Uninstall exposes selective removal and output preservation; it is still irreversible filesystem work and was not exercised.

## Testing, observability, security, and failure modes

### Test strategy present in source

`npm run quality` chains formatting, JS/YAML lint, Markdown lint, docs build, site URL, installation, URL parsing, renderer, retrospective, sprint planning, reference, skill, and sidebar validation (`770d425:package.json:L35-L56`). The tree has 24 tracked paths under `test/`, comprising 10 executable top-level JS/MJS tests plus `test/README.md` and fixtures, and 15 colocated Python test files. Python suites emphasize real filesystem behavior, byte preservation, invalid input, boundary states and failure recovery. Installer tests cover channels, components, generated files and URL parsing. Website tests cover URL construction and rehype transforms.

### Security-positive mechanisms

- Prototype-polluting `--set` path names `__proto__`, `prototype`, and `constructor` are rejected, with a second guard at application time (`770d425:tools/installer/set-overrides.js:L17-L23`; `770d425:tools/installer/set-overrides.js:L57-L70`).
- Canonical skill IDs are validated before they become output paths (`770d425:tools/installer/ide/_config-driven.js:L51-L55`; `770d425:tools/installer/ide/_config-driven.js:L323-L329`).
- Renderer snapshot references must name declared sources; inserted prose is opaque and cannot smuggle a second render token pass.
- Existing immutable generations are fully hash/file-set verified.
- Git cache operations strip repository-retargeting environment variables.
- State writers use atomic replace and explicit error objects; malformed present TOML/YAML fails rather than silently defaulting.
- The repository's security policy explicitly includes prompt injection and path traversal in its reporting scope.

### Security/trust risks

1. **Prompt/config execution boundary.** Team/user TOML can add activation steps, persistent file globs, menu prompts, workflow prose, external handoffs and completion steps. These are intentionally executable instructions to the host model. Treat project customizations and imported modules as code-review material, not benign data.
2. **External module supply chain and partial readiness.** Network source, ref resolution, package manifests and npm lifecycle behavior enter through cached clones. Resolved SHAs improve provenance, but this analysis found no signature verification or sandbox. Dependency-install exceptions are swallowed after warning and the cache path is returned, so downstream work can see a partially ready module; silent mode hides the detailed error (`770d425:tools/installer/modules/external-manager.js:L448-L502`; `770d425:tools/installer/modules/custom-module-manager.js:L556-L575`).
3. **Autonomous VCS mutation.** Build Auto reverts changes during triage and commits successful reviewed changes; interactive Build also locally commits at completion. This conflicts with approval regimes that reserve commits for humans unless the consumer wraps or customizes the workflow.
4. **Silent conservative cleanup.** `_config-driven.js` contains several empty `catch` blocks around optional manifests, removal files and cleanup probes (`770d425:tools/installer/ide/_config-driven.js:L590-L659`; `770d425:tools/installer/ide/_config-driven.js:L698-L746`). They reduce destructive-cleanup risk but can obscure an incomplete migration.
5. **Information exposure.** Persistent `file:` globs can load broad project knowledge into the agent context. There is no central secret scanner before prompt ingestion; project-specific excludes and host permissions remain necessary.

### Failure protocol and observability

Workflows use explicit `HALT` states with status and blocking condition. Build Auto writes a result file even when no spec path can be resolved (`770d425:src/bmm-skills/ship/bmad-build-auto/workflow.md:L7-L43`). Deterministic scripts return nonzero codes and structured JSON or `HALT:` output. Manifests capture generated ownership and hashes. Review trails, spec change logs, auto-run results, sprint status, memlogs and generated artifacts make most state inspectable without a service backend.

Weak observability remains around caught dependency/cleanup failures and model-interpreted hook execution: silent dependency mode suppresses the exception detail, and there is no guaranteed machine event proving an AI host executed each prompt hook beyond transcript/artifacts.

## Documentation drift and cross-source inconsistencies

1. **Python prerequisite drift.** Root README says Python 3.10+ (`770d425:README.md:L13-L13`), while the central config loader imports stdlib `tomllib`, and the customization guide correctly says Python 3.11+ unless `uv` selects it (`770d425:src/scripts/config_utils.py:L5-L5`; `770d425:docs/how-to/customize-bmad.md:L212-L212`). Package test scripts explicitly pin Python 3.11 (`770d425:package.json:L49-L53`). Direct system-Python users on 3.10 will fail even though the README says they satisfy prerequisites.
2. **Core-skill arithmetic drift.** The core tools page says “seven” skills and “three thinking skills,” but its own table and source contain four kernel plus four thinking/core experiences (Brainstorming, Deep Recon, Forge Idea, Party Mode), totaling eight active core skills (`770d425:docs/reference/core-tools.md:L8-L32`).
3. **Analyst menu drift.** English agent reference lists Mary triggers `BP, MR, DR, TR, CB, WB, DP`; current `customize.toml` additionally supplies `TS`, `CR`, and `UV` (`770d425:docs/reference/agents.md:L18-L20`; `770d425:src/bmm-skills/agents/bmad-agent-analyst/customize.toml:L56-L105`). Several translated agent pages retain still older IDs/menu codes. The executable customization is authoritative.
4. **Workflow-map omission.** Phase 4's primary table does not enumerate every shipped shipping skill; Build Auto is only mentioned in prose, and Checkpoint Preview / QA E2E are not represented as primary rows (`770d425:docs/reference/workflow-map.md:L84-L101`). The skill inventory and help catalogs are more complete.
5. **Legacy upgrade terminology.** Parts of upgrade/translated documentation refer to earlier agent/config paths and pre-consolidation skill names. Current source uses `_bmad/custom` TOML layering and the consolidated skills. Compatibility shims keep many old IDs working, which can mask drift during migration.

Documentation links themselves were healthy: the self-contained link validator reported 168 files checked, 0 issues. The issues above are semantic freshness, not broken hyperlinks.

## Runtime evidence

Commands ran on Windows/PowerShell against either the untouched analysis clone or a disposable clone pinned to the same commit. The disposable clone was created specifically to install dependencies without mutating the analysis clone.

### Disposable dependency-backed setup

```powershell
git clone --no-local --no-checkout "C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\repos\bmad-method" "C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\runtime\bmad-method-validation-770d425"
git -C "C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\runtime\bmad-method-validation-770d425" checkout --detach 770d4259853b9600680745bb2c710bee82604cb4
npm ci --ignore-scripts --no-audit --no-fund
```

Exit codes: 0/0/0. npm installed 848 packages in 8 seconds; lifecycle scripts were deliberately disabled. The runtime clone remained clean. This enabled official validators/tests without changing the analysis clone.

### Exact Python test coverage

All 15 tracked Python test files were executed. Thirteen dependency-free files ran in one explicit command:

```powershell
python -m pytest -q -p no:cacheprovider src/bmm-skills/plan/bmad-architecture/scripts/tests/test_lint_spine.py src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py src/core-skills/bmad-advanced-elicitation/scripts/tests/test_pick_methods.py src/core-skills/bmad-brainstorming/scripts/tests/test_brain.py src/core-skills/bmad-customize/scripts/tests/test_list_customizable_skills.py src/core-skills/bmad-deep-recon/scripts/tests/test_recon_kit.py src/core-skills/bmad-forge-idea/scripts/tests/test_resolve_personas.py src/core-skills/bmad-party-mode/scripts/tests/test_resolve_party.py src/core-skills/bmad-review/scripts/tests/test_word_metrics.py src/scripts/tests/test_config_utils.py src/scripts/tests/test_memlog.py src/scripts/tests/test_resolve_config.py src/scripts/tests/test_resolve_customization.py
```

Exit 1: **202 passed, 4 failed** in 16.57s. All four failures are in `test_git_evidence.py`: `test_distinct_non_utf8_paths_stay_distinct`, `test_repeated_merge_headers_are_counted_once`, `test_second_pass_runs_only_when_the_range_has_merges`, and `test_git_failure_with_empty_stderr_reports_the_exit_code`. The tests create POSIX `#!/bin/sh` fake `git` files and prepend them to `PATH`; on Windows those files are not selected as executables, so real Git ran instead (`770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L480-L520`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L561-L605`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L660-L668`). This is test-fixture portability, not evidence that production parsing is incorrect. The combined total includes the previously omitted architecture suite's **28 passed** and Git-evidence's **27 passed/4 failed**.

The two dependency-declared suites ran exactly as package scripts prescribe:

```powershell
uv run --python 3.11 src/bmm-skills/plan/bmad-sprint-planning/scripts/tests/test_sprint_plan.py
uv run --python 3.11 src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_sprint_status.py
```

Sprint Planning exit 0: **37 passed**. Sprint Status exit 1: **87 passed, 4 failed**. Its failures concern POSIX permission/mode assumptions on Windows: read-only directory did not block replacement, `chmod 000` did not consistently make the file unreadable, the localized Hungarian WinError text did not contain English `denied`, and POSIX mode `0640` was not preserved as asserted. These are portability/locale failures around the intended failure contract, not a clean pass.

### Exact Node/CLI and validator evidence

| Exact command | Exit | Result and diagnosis |
|---|---:|---|
| `node tools/validate-file-refs.js --strict` | 1 | 202 files; 188 references; 187 resolved; 1 broken generated-example target at Document Project line 854; 0 absolute leaks |
| `node tools/installer/bmad-cli.js install --list-tools` | 0 | Printed 45 supported tool IDs and target directories; no install performed |
| `npm run test:install` | 1 | 427 passed, 2 failed; both renderer-fence comparisons are CRLF-sensitive; substantive host/shared-target/`--set` integration cases passed |
| `npm run test:channels` | 0 | 83 passed |
| `npm run test:urls` | 0 | 68 passed |
| `npm run test:renderer` | 1 | Python prelude 10/10; Node renderer 20/24. Unix-only absolute-path regexes and LF-only Bash-fence regex explain three failures (`770d425:test/test-build-auto-renderer.js:L193-L194`; `770d425:test/test-build-auto-renderer.js:L437-L442`; `770d425:test/test-build-auto-renderer.js:L505-L506`); long-project-basename diagnostic `undefinedundefined` remains unresolved |
| `node test/test-rehype-plugins.mjs` | 1 | 82 passed, 25 failed; Windows `path` separators leaked into generated URL expectations and content-directory tests assumed POSIX paths; module-type warning also emitted |
| `node tools/validate-skills.js --strict` | 1 | 48/48 rejected; 144 findings (96 critical, 48 high). Parser searches LF-only `\n---\n` while checkout uses CRLF (`770d425:tools/validate-skills.js:L68-L79`) |
| `node test/test-validate-skills.js` | 1 | 2/3 passed; same newline-sensitive parser lets the negative trigger case miss its intended condition |
| `node tools/validate-doc-links.js` | 0 | 168 documentation files, 0 link issues |
| `node test/test-template-sync.js` | 0 | passed |
| `node test/test-site-url.mjs` | 0 | 8 passed |
| `npm run quality` | 1 | stopped at first stage, `prettier --check`, with 95 CRLF-normalized files reported as formatting issues; downstream stages did not run |

The self-contained static sweeps were also exact repository-wide reads: 65 JS/MJS files passed `node --check`; 31 Python files passed `ast.parse`; 36 TOML, 20 YAML and 11 JSON files parsed; all 618 tracked files hashed with zero read/hash failures. The inventories contain 618 file rows with zero blank classifications/hash errors and 608 gear rows, all `analyzed`, leaving **0 pending gear rows**.

Representative exact smoke commands:

```powershell
python src/core-skills/bmad-brainstorming/scripts/brain.py --json categories
python src/core-skills/bmad-advanced-elicitation/scripts/pick_methods.py --json categories
python src/core-skills/bmad-deep-recon/scripts/recon_kit.py slug --type technical --date 2026-08-02 'A test BMAD'
python src/core-skills/bmad-review/scripts/word_metrics.py README.md
```

All exited 0 and returned, respectively: 13 categories/108 methods; 12 categories/71 methods; `technical-a-test-bmad-2026-08-02`; and 602 words. One earlier malformed slug invocation used nonexistent `--title` and exited 2; the corrected command above is the reproducible result. A nonexistent exploratory `tools/validate-skill-paths.js` command is not a repository script and carries no project-quality conclusion.

The full quality pipeline is **not green** on this Windows checkout. Dependency-backed execution closes the former missing-dependency gap but exposes a strict broken reference, CRLF/path portability defects, and eight Python portability failures. No live external module, destructive install/update/uninstall, remote host, or paid/API integration was exercised.

## Reusable patterns

### 1. Content-addressed workflow snapshots

- **Source:** `src/scripts/render_skill.py`, Build/Build Auto entry skills and snapshot tokens.
- **Prerequisites:** deterministic text inputs, a stable project root, Python 3.11 selected directly or through `uv`, and a project `_bmad` directory.
- **Adaptation:** define a small source-token grammar; enumerate declared inputs; substitute once; hash renderer, sources and resolved values; publish to a staging directory; atomically rename; verify any existing generation byte-for-byte.
- **Tradeoffs:** reproducible and reviewable execution packets versus path-specific cache identities, disk growth, and more complex debugging. One-pass opacity intentionally prevents transitive token expansion.
- **License/provenance:** MIT repository code; preserve the MIT notice and copyright when copying substantial implementation.
- **Recommendation:** reuse the architectural pattern; clean-room reimplement in the target language unless direct Python compatibility is valuable. Avoid copying BMad-specific token names or branded paths unnecessarily.

### 2. Structural layered customization

- **Source:** `src/scripts/config_utils.py`, `resolve_config.py`, `resolve_customization.py`, per-skill `customize.toml`.
- **Prerequisites:** a declared base schema/surface and a clear ownership model for installer, team and user files.
- **Adaptation:** parse strictly; skip only absent optional layers; recursively merge tables; replace keyed array entries by stable identity; append unkeyed arrays; make precedence explicit; expose a resolver CLI for debugging.
- **Tradeoffs:** sparse, upgrade-safe overrides versus subtle array semantics and the risk that user-supplied instructions become executable prompt content.
- **License/provenance:** MIT; general configuration layering is a common technique, but exact code is repository-derived.
- **Recommendation:** clean-room implementation is preferable; retain tests for invalid types, duplicate keys, missing required defaults and precedence.

### 3. Ownership-aware multi-host installer

- **Source:** `tools/installer/ide/platform-codes.yaml`, `_config-driven.js`, manifest generator/reader.
- **Prerequisites:** canonical skill IDs, a data-driven host path registry, generated-file signatures or manifests, and safe path validation.
- **Adaptation:** keep source packages host-neutral; map hosts to project/global targets; copy canonical directories; generate minimal pointers; record exactly what was generated; remove only files confidently owned.
- **Tradeoffs:** broad host support with low adapter duplication versus platform path quirks, stale-file tolerance, and a large compatibility test matrix.
- **License/provenance:** MIT implementation; host names/paths should be reverified from vendor documentation rather than copied as timeless facts.
- **Recommendation:** reuse the design and revalidate every platform path. Add explicit warnings for skipped cleanup rather than empty catches.

### 4. Review findings as a control-flow algebra

- **Source:** Build/Build Auto review steps and review prompt pack.
- **Prerequisites:** frozen intent contract, canonical spec, baseline revision, independently inspectable diff and verification commands.
- **Adaptation:** normalize findings into `intent_gap`, `bad_spec`, `patch`, `defer`, `reject`; process highest-level root causes first; preserve a triage log; bound repair loops; rerun verification after patches.
- **Tradeoffs:** prevents symptom patching and gives deterministic escalation, but classification is model judgment and revert/commit actions need local governance.
- **License/provenance:** protocol text is MIT-covered repository content.
- **Recommendation:** clean-room rephrase and implement the state machine, keeping human approval around destructive VCS operations.

### 5. Append-only agent-memory entries

- **Source:** `src/scripts/memlog.py` and Brainstorm/Forge workflows.
- **Prerequisites:** filesystem persistence and a workflow capable of reconstructing state from chronology.
- **Adaptation:** append one typed fact/event per line, provide no body-entry edit/delete operations, allow narrowly scoped descriptive-frontmatter updates, write atomically, and derive deliverables separately.
- **Tradeoffs:** excellent auditability and resumability for the body; correction must be an additional event. Frontmatter is mutable through `set`, but lifecycle status remains forbidden there (`770d425:src/scripts/memlog.py:L61-L67`; `770d425:src/scripts/memlog.py:L110-L129`). Long logs eventually need explicit compaction/distillation outside the log.
- **License/provenance:** MIT.
- **Recommendation:** direct conceptual reuse is safe; a small clean-room implementation is easy and reduces coupling.

### 6. Atomic human-readable state mutation

- **Source:** sprint planner, retrospective status updater, renderer publisher.
- **Prerequisites:** local filesystem with same-volume atomic rename and an explicit validation schema.
- **Adaptation:** read exact bytes/mode, parse/validate, render new state, write/fsync temp, replace, validate post-write, restore exact original bytes if needed.
- **Tradeoffs:** safer crash behavior and reviewable YAML/Markdown versus complexity around symlinks, permissions and network filesystems.
- **License/provenance:** MIT implementation; atomic replace is a general systems pattern.
- **Recommendation:** adapt the pattern and its negative tests; do not copy serializers blindly because comment-preservation requirements differ.

### 7. Sanitized subprocess environment for scoped Git operations

- **Source:** `tools/installer/modules/git-env.js`, external/custom module managers.
- **Prerequisites:** every Git subprocess receives an explicit working directory and sanitized environment.
- **Adaptation:** clone the environment; remove repository-targeting Git variables and config override vectors; set a known cwd; validate/cache target paths before reset/remove operations.
- **Tradeoffs:** avoids catastrophic cross-repository mutations but may remove legitimate caller customization, so document the boundary.
- **License/provenance:** MIT.
- **Recommendation:** this is suitable for direct reuse with attribution or a clean-room port; retain the incident-derived regression test.

## Weaknesses and design concerns

1. The executable core is distributed between deterministic code and natural-language protocol. Static validation cannot prove that a host model respected step order, hooks, scope, or halt conditions.
2. Build workflows create commits automatically and Build Auto reverts code. That default is incompatible with stricter human-approval environments without an explicit wrapper/customization.
3. The Windows CRLF defect makes `validate:skills` unusable in a normal CRLF checkout, fails two installation assertions, and weakens its own negative test. Normalizing line endings before parsing is a small, high-value fix.
4. Renderer tests encode Unix-only absolute-path assumptions. The production renderer is more portable than these test assertions, but the long-project-name Windows failure still needs a precise reproduction and error message.
5. External modules can execute npm install from cloned sources. SHA recording is not signature verification; lifecycle scripts and transitive dependencies remain a supply-chain risk. Worse, dependency-install failure is caught and continued, so clone success can become a partially installed module with suppressed detail in silent mode.
6. Silent catches in cleanup favor preservation but make partial cleanup difficult to audit. Structured warnings would preserve safety while improving observability.
7. Config arrays append unless every element has a common `code` or `id`; mixed arrays may unexpectedly duplicate instructions. Schema validation before merge would reduce surprises.
8. Absolute project path is part of render identity. This is safe but reduces cache portability and makes artifacts non-reproducible across checkout locations by design.
9. English and translated docs lag fast-moving source reorganizations. Compatibility shims reduce breakage but prolong ambiguity about canonical entry points.
10. Root prerequisites conflict with actual Python requirements, creating an avoidable first-run failure for direct Python 3.10 users.
11. Official strict reference validation is red on one future/generated-document example. Either encode an explicit generated-target exemption or avoid spelling the example as a resolvable relative reference.
12. Rehype URL tests and Sprint Status failure-path tests embed POSIX path/permission/English-locale assumptions; Windows produces 25 and 4 failures respectively.
13. The platform matrix is broad (45 hosts), increasing maintenance burden. The source comment gives a verification date, but no runtime conformance test can prove every external host still consumes the declared directory.
14. Prompt customization and broad persistent-fact globs can create data-exposure and prompt-injection risk; there is no repository-wide pre-ingestion secret policy.

## Unresolved items

- Full `npm run quality` was attempted in a disposable dependency-backed clone but stopped at Prettier with 95 CRLF formatting findings; downstream quality stages did not execute as one chain. Individual relevant stages are recorded above.
- The exact root cause of the long-project-basename renderer test's `undefinedundefined` diagnostic remains unresolved. It appears Windows/path-related but needs a focused test harness and retained stderr/stdout fields.
- Whether every one of the 42 configured `global_target_dir` values is actively selectable and consumed by its external host was not proven end-to-end; the inspected project handler joins `target_dir` to the selected project.
- The one official strict-reference failure is classified, not fixed: it is a future/generated-document example at Document Project line 854. Repository source changes were forbidden.
- External module repositories and their package code were not cloned or analyzed; this report covers only BMAD-METHOD's registry, resolution, cache and execution boundary.
- The open PR #2632 seen by preflight was not investigated because it is unrelated remote state and the brief pinned the repository snapshot.
- Website rendering and generated web bundles were structurally inventoried. Dependencies were available only in the disposable clone, but a full Astro visual build/inspection was not run; `npm run quality` stopped before that stage and UI behavior is peripheral to the agent runtime.

## Evidence index

All source citations below refer to commit `770d4259853b9600680745bb2c710bee82604cb4`.

| Topic | Primary evidence |
|---|---|
| Package identity, CLI, quality gates | `770d425:package.json:L3-L56` |
| Root prerequisites/license/trademark | `770d425:README.md:L13-L13`; `770d425:README.md:L78-L82`; `770d425:LICENSE:L1-L30`; `770d425:TRADEMARK.md:L1-L50` |
| Repository contribution/release model | `770d425:CONTRIBUTING.md:L1-L109`; `770d425:.github/workflows/quality.yaml:L1-L42`; `770d425:.github/workflows/publish.yaml:L1-L172` |
| Skill inventory | 48 repo-relative `src/**/SKILL.md` entries; package grouping at `770d425:.claude-plugin/marketplace.json:L10-L87` |
| Agent activation/dispatch | `770d425:src/bmm-skills/agents/bmad-agent-analyst/SKILL.md:L19-L76` and the corresponding same-protocol ranges in all five agent skills |
| Agent personas/menus | `770d425:src/bmm-skills/agents/bmad-agent-analyst/customize.toml:L1-L105`; sibling agent `customize.toml` files |
| Central/per-skill config | `770d425:src/scripts/config_utils.py:L17-L118`; `770d425:src/scripts/resolve_config.py:L37-L69`; `770d425:src/scripts/resolve_customization.py:L27-L95` |
| Immutable renderer | `770d425:src/scripts/render_skill.py:L30-L33`; `770d425:src/scripts/render_skill.py:L98-L150`; `770d425:src/scripts/render_skill.py:L232-L380` |
| Memlog body/frontmatter semantics | `770d425:src/scripts/memlog.py:L5-L35`; `770d425:src/scripts/memlog.py:L61-L67`; `770d425:src/scripts/memlog.py:L110-L129` |
| Interactive Build | `770d425:src/bmm-skills/ship/bmad-build/SKILL.md:L1-L13`; `770d425:src/bmm-skills/ship/bmad-build/workflow.md:L1-L84`; repo-relative `src/bmm-skills/ship/bmad-build/step-*.md` |
| Autonomous Build | `770d425:src/bmm-skills/ship/bmad-build-auto/SKILL.md:L1-L13`; `770d425:src/bmm-skills/ship/bmad-build-auto/workflow.md:L1-L104`; repo-relative `src/bmm-skills/ship/bmad-build-auto/step-*.md` |
| Review loop/commit behavior | `770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L59-L96`; `770d425:src/bmm-skills/ship/bmad-build/step-05-present.md:L57-L67` |
| Sprint status | `770d425:src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py:L59-L70`; `770d425:src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py:L329-L461` |
| Retrospective state/evidence | `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/sprint_status.py:L33-L70`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/git_evidence.py:L1-L80` |
| Host platform matrix | `770d425:tools/installer/ide/platform-codes.yaml:L1-L343` |
| Host generation/dedup/cleanup | `770d425:tools/installer/ide/_config-driven.js:L218-L405`; `770d425:tools/installer/ide/_config-driven.js:L499-L819` |
| Two-phase `--set` | `770d425:tools/installer/ui.js:L780-L835`; `770d425:tools/installer/core/installer.js:L295-L342` |
| Installer backup/config orchestration | `770d425:tools/installer/core/installer.js:L217-L371`; `770d425:tools/installer/core/installer.js:L590-L696`; `770d425:tools/installer/core/installer.js:L962-L1049` |
| External module registry/runtime | `770d425:bmad-modules.yaml:L1-L128`; `770d425:tools/installer/modules/external-manager.js:L191-L502`; `770d425:tools/installer/modules/custom-module-manager.js:L324-L575` |
| Dependency partial-failure behavior | `770d425:tools/installer/modules/external-manager.js:L448-L502`; `770d425:tools/installer/modules/custom-module-manager.js:L556-L575` |
| Git subprocess safety | `770d425:tools/installer/modules/git-env.js:L1-L44` |
| `--set` input safety | `770d425:tools/installer/set-overrides.js:L17-L70` |
| Official reference validation scope | `770d425:tools/validate-file-refs.js:L1-L70`; `770d425:tools/validate-file-refs.js:L182-L327` |
| Static reference failure | `770d425:src/bmm-skills/plan/bmad-document-project/workflows/full-scan-instructions.md:L849-L858` |
| Docs drift | `770d425:README.md:L13-L13`; `770d425:docs/how-to/customize-bmad.md:L212-L212`; `770d425:docs/reference/core-tools.md:L8-L32`; `770d425:docs/reference/agents.md:L18-L20`; `770d425:docs/reference/workflow-map.md:L84-L101` |
| Windows validator defect | `770d425:tools/validate-skills.js:L68-L79`; valid CRLF example `770d425:src/bmm-skills/agents/bmad-agent-analyst/SKILL.md:L1-L4` |
| Windows renderer-test assumptions | `770d425:test/test-build-auto-renderer.js:L193-L194`; `770d425:test/test-build-auto-renderer.js:L437-L442`; `770d425:test/test-build-auto-renderer.js:L505-L506` |
| Python portability fixtures | `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L480-L520`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L561-L605`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_sprint_status.py:L580-L610`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_sprint_status.py:L790-L910` |

### Final assessment

**[Inference]** BMAD-METHOD's most transferable contribution is the separation between portable, inspectable instruction packages and deterministic boundary tools. Its immutable renderer, structural customization, ownership manifests, atomic state writers and typed review loop are stronger than its branding-specific persona layer. Reuse should preserve those invariants while adding local approval gates, explicit warnings, newline/path portability, schema validation and a stricter supply-chain policy. Direct reuse and modification are permitted by MIT when the copyright/permission notice is preserved in copies or substantial portions (`770d425:LICENSE:L1-L23`). BMad names and branding are separately reserved, while redistribution under a distinct name and truthful compatibility references are expressly permitted (`770d425:LICENSE:L26-L30`; `770d425:TRADEMARK.md:L16-L25`). Clean-room reimplementation is an engineering/decoupling recommendation for some patterns, not a license or trademark requirement.

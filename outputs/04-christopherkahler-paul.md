# ChristopherKahler/paul — részletes magyar kutatási dosszié

## 1. Snapshot and provenance

| Mező | Rögzített érték |
|---|---|
| Repository | `ChristopherKahler/paul` |
| Branch | `main` |
| Commit | `960b05c0b8e1f876f49674a700c9a087afebb8ac` |
| Package | `paul-framework` 1.4.0 |
| Runtime floor | Node.js `>=16.7.0` |
| Licenc | MIT, Copyright (c) 2026 Chris Kahler |
| Első preflight | 2026-08-02T12:51:47Z, clean, `origin/main`, PR nincs |
| Független review preflight | 2026-08-02T13:15:16.9340346Z, ugyanaz a pin, clean |
| Forrásmódosítás/publikálás | nem történt |

Jelölések:

- **[Fact]**: a pinned repository-ból közvetlenül igazolható tény;
- **[Runtime]**: izolált helyi futtatás tényleges eredménye;
- **[Inference]**: több tényből levont, de külön futtatással nem teljesen bizonyított következtetés;
- **[Author claim]**: a projekt szerzőjének dokumentációs állítása, amelyet a dosszié nem emel automatikusan ténnyé.

**[Fact]** A teljes scope 108 tracked path. Ebből 106 működési vagy dokumentációs „gear candidate”, két fájl (`assets/terminal.png`, `assets/terminal.svg`) bináris megjelenítési asset. Az inventory byte- és SHA-256-értékei 108/108 arányban megegyeznek a pinnelt checkouttal.

## 2. Executive summary

**[Fact]** A PAUL nem executable workflow engine, hanem Claude Code-ra épülő prompt-orchestration framework. A központi mechanizmus a `PLAN → APPLY → UNIFY` kör: a PLAN approval- és scope-contractot hoz létre; az APPLY egy Execute/Qualify (E/Q) ciklusban dolgozik; az UNIFY összeveti a tervet a tényleges eredménnyel, SUMMARY-t ír és összehangolja a tartós state-et.

**[Fact]** A forrás architekturálisan hat réteget különít el: slash command wrappers, részletes workflows, concept references, output templates, maintainer rules és opcionális CARL domain. A tényleges végrehajtó mindig a Claude session; az installer csak fájlokat másol és egyetlen prefixet ír át.

**[Runtime]** A friss local és custom-global smoke install egyaránt 97 fájlt hozott létre: 28 commandot és 69 framework fájlt. A várt és tényleges output között `MISSING=0`, `EXTRA=0`, `CONTENT_MISMATCH=0`.

**[Fact]** A disztribúciós gráf hibás. Az installer `src/{templates,workflows,references,rules}` tartalmát `paul-framework/{...}` alá másolja, de nem telepít `src/` könyvtárat. A telepített Markdownban mégis 63 `@src/` token marad: öt példa/placeholder, 58 konkrét statikus hivatkozás. Az 58-ból 46 execution-relevant (`2 command + 42 workflow + 2 schema/reference`), és 17 command statikus closure-je elér legalább egy ilyen élt.

**[Inference]** `/paul:map-codebase` várhatóan nem tudja betölteni az egyetlen részletes procedural delegate-jét, mert mindkét közvetlen éle a nem disztribuált `@src/workflows/map-codebase.md` célra mutat. Ez erős, forrásalapú következtetés, de nem közvetlen Claude runtime-próba: a tényleges `@` parser/root semantics nem lett futtatva.

**[Fact]** A CARL két source fájlja nincs az npm allowlistben, és az installer sem másolja őket. Kézi másolás után is hibás install-pathot kérne: `~/.claude/paul-framework/src/commands/{name}.md`, miközben a commandok `commands/paul/` alá kerülnek.

**[Fact]** Az erős, adaptálható minták: explicit plan approval, E/Q friss visszaolvasás, intent/spec/code failure classification, STATE snapshot + append-only ledger szétválasztás, checkpoint taxonómia, egy-next-action routing és plan/actual reconciliation. Ezeket nem érdemes a hibás path contracttal vagy a prompt-only enforcementtel együtt átvenni.

## 3. Repository and component inventory

Az alábbi ledger minden tracked pathot lefed. A technikai azonosítók és rövid role-leírások source-faithful angol formában maradnak, hogy a fájlszintű összehasonlíthatóság ne sérüljön; a kategóriaértelmezés magyar.

- root/distribution: 9/9, ebből két bináris non-gear asset;
- CARL: 2/2;
- commands: 28/28;
- workflows: 23/23;
- concept references: 14/14;
- maintainer rules: 5/5;
- templates: 27/27.

**[Runtime]** A supplied inventory pontosan egyezik a `git ls-files` eredményével: 108 sor, 108 tracked path, nulla hiány és nulla extra. A kategóriák: 78 orchestration asset, 22 documentation file, 4 other/source file, 1 executable source, 1 configuration file és 2 binary asset. A gear candidate-ok száma 106.

### 3.1 Root és distribution fájlok — 9/9

| File | Account |
|---|---|
| `.gitignore` | Ignores project instance state, Node artifacts, editor files, root handoffs, and a removed special-flows spec. Gear candidate. |
| `README.md` | Product narrative, install instructions, loop, commands, project-state model, BASE/CARL claims, comparisons, troubleshooting. Gear candidate. |
| `IDEATION.md` | Explicit future backlog for a UNIFY-to-content pipeline; not current runtime behavior. Gear candidate. |
| `PAUL-VS-GSD.md` | Author comparison and positioning against GSD. Gear candidate; GSD-side claims were not independently verified. |
| `LICENSE` | MIT grant, notice-retention condition, and warranty/liability disclaimer. Gear candidate. |
| `package.json` | npm metadata, CLI entry, publish allowlist, Node floor. Gear candidate. |
| `bin/install.js` | Only executable source: parses install flags, selects destination, rewrites paths, copies the command/framework trees. Gear candidate. |
| `assets/terminal.png` | README install screenshot. Binary, not a gear candidate. |
| `assets/terminal.svg` | Vector terminal artwork. Binary, not a gear candidate. |

### 3.2 CARL — 2/2

| File | Account |
|---|---|
| `src/carl/PAUL` | Optional PAUL domain: active but not always-on; claims activation when `.paul/` exists; 12 rules cover file loading, plan approval, mandatory UNIFY, boundaries, blockers, state consistency, verification, deviations, BDD, context sizing, commit cadence, and decimal phases. Its command-load path is incompatible with the installed tree. |
| `src/carl/PAUL.manifest` | Manual CARL installation/activation block with recall terms. It is not shipped by npm or copied by the installer. |

### 3.3 Commands — 28/28

Commands are intended as thin wrappers around workflows (`src/rules/commands.md` lines 21–35). The table accounts for every installed command.

| Command file | Role and delegation | Notable tool/surface fact |
|---|---|---|
| `add-phase.md` | Add a phase through `roadmap-management`. | Read/Write/Edit/Bash; downstream unresolved `@src` template ref. |
| `apply.md` | Validate and execute an approved plan; load checkpoints; route to APPLY workflow. | Read/Write/Edit/Bash/Glob/Grep/Ask; downstream unresolved TOML-sync ref. |
| `assumptions.md` | Surface Claude's five-area assumptions before planning. | Read/Bash; static delegation resolves. |
| `audit.md` | Same-session senior-principal/compliance persona audits and mutates a plan. | Read/Write/Edit/Glob/Ask; no separate auditor agent. |
| `complete-milestone.md` | Archive/evolve/tag a completed milestone. | Read/Write/Edit/Bash/Glob; 3 downstream unresolved refs. |
| `config.md` | Self-contained config UI for SonarQube and enterprise audit. | No YAML frontmatter, command name, description, or tool allowlist. It advertises `/paul:quality-gate`, whose command file is absent. |
| `consider-issues.md` | Triage ISS/UAT items against current code. | Static workflow path resolves. |
| `discover.md` | Technical option discovery with depth and subagents. | Web/Task-capable; 2 downstream unresolved refs. |
| `discuss-milestone.md` | Create milestone vision/context. | Downstream template ref unresolved. |
| `discuss.md` | Create phase CONTEXT from a guided discussion. | Downstream template ref unresolved. |
| `flows.md` | Configure/add/audit/list specialized skills. | One relative installed reference resolves; 2 workflow `@src` refs do not. |
| `handoff.md` | Self-contained detailed session handoff; registers with `base` if available. | Read/Write/Bash; no external workflow. |
| `help.md` | Emits embedded command reference only. | Footer counts are stale. |
| `init.md` | Initialize `.paul/` through conversation and templates. | Six immediate resources resolve; its workflow reaches 8 unresolved refs. |
| `map-codebase.md` | Intended to launch four Explore agents and write seven map documents. | No frontmatter; both direct workflow refs have no target in the installed tree. Actual Claude runtime failure is inferred, not executed. |
| `milestone.md` | Create milestone and phase structure. | Three downstream unresolved refs. |
| `pause.md` | Create a compact handoff, update STATE, optionally commit. | All static framework refs resolve. |
| `plan-fix.md` | Self-contained conversion of UAT issues into a bounded FIX plan. | Reference paths resolve; no workflow delegate. |
| `plan.md` | Create/continue a scope-adaptive plan. | Downstream TOML-sync ref unresolved. |
| `progress.md` | Read state/roadmap and recommend exactly one next action. | Read-only, self-contained. |
| `register.md` | Migrate/create `paul.toml` and create ledger. | Its workflow contains 5 unresolved execution refs. |
| `remove-phase.md` | Remove an unstarted phase and renumber later phases. | Downstream template ref unresolved; destructive scope is prompt-mediated. |
| `research-phase.md` | Identify up to three substantial unknowns and research in parallel. | Explore/general-purpose agents; downstream RESEARCH template ref unresolved. |
| `research.md` | Research a named codebase or web topic and persist findings. | Explore/general-purpose selection; downstream RESEARCH template ref unresolved. |
| `resume.md` | Load state/handoff and suggest one action. | Static refs resolve; underlying workflow has malformed duplicate `</process>`. |
| `status.md` | Deprecated state display. | Read-only, self-contained. |
| `unify.md` | Reconcile a plan, create SUMMARY, update state. | Allowlist omits Bash/Edit/Glob although the delegated last-plan transition uses Bash/git; 2 downstream unresolved refs. |
| `verify.md` | Guide user-run UAT and log issues. | Two downstream UAT-template refs unresolved. |

### 3.4 Workflows — 23/23

| Workflow | Terminal behavior and outputs |
|---|---|
| `apply-phase.md` | Approval gate; plan/skill load; sequential E/Q tasks; checkpoints; task/deviation log; STATE + manifest/ledger update; route to UNIFY. |
| `audit-plan.md` | Same-model enterprise/compliance persona; classify findings; mutate PLAN; create AUDIT; update STATE; route or block. |
| `complete-milestone.md` | Verify readiness; aggregate summaries/stats; update MILESTONES/PROJECT/ROADMAP/STATE; archive; align five versions; tag; manifest/ledger; next milestone. |
| `configure-special-flows.md` | Discover skills, map work types/priorities/triggers, phase overrides/assets, write SPECIAL-FLOWS and PROJECT reference; also defines add/audit/list subcommands. |
| `consider-issues.md` | Find/parse ISS and UAT files, inspect code, categorize resolved/urgent/natural-fit/wait, offer and execute user-selected edits. |
| `create-milestone.md` | Gather milestone/phases, update roadmap/state, create directories, sync manifest/ledger, delete consumed context, offer PLAN. |
| `debug.md` | Persistent debug session: capture symptoms, hypothesis/test/evidence loop, fix/verify, archive and commit. No command points to it. |
| `discovery.md` | Quick/standard/deep option research, subagents/cross-checks, confidence and DISCOVERY artifact, route to PLAN. |
| `discuss-milestone.md` | Validate state, explore features/scope, write MILESTONE-CONTEXT, hand off to milestone creation. |
| `discuss-phase.md` | Validate phase, explore goals/approach, write phase CONTEXT, hand off to PLAN. |
| `init-project.md` | Detect existing PAUL/BASE/PLANNING; converse by project type; create `.paul` artifacts, manifest, ledger, optional config/flows; route to PLAN. |
| `map-codebase.md` | Four parallel Explore agents; aggregate seven codebase documents; verify, commit, update STATE. Runtime-orphaned by broken command ref. |
| `pause-work.md` | Detect position, create/register handoff, update STATE, optional WIP branch/commit, confirm resume path. |
| `phase-assumptions.md` | Validate phase; infer technical approach/order/boundaries/risks/dependencies with confidence; gather corrections; plan or re-examine. |
| `plan-phase.md` | Gate prior loop; classify quick/standard/complex; load lean context; inject skills; generate/validate/coherence-check PLAN; update state/roadmap/manifest/ledger. |
| `quality-gate.md` | Check config/prerequisites; call named SonarQube MCP operations; evaluate gates/issues; update CONCERNS; report. No command file. |
| `register-manifest.md` | Detect migration/creation mode, read state, create TOML + ledger, delete JSON, check BASE, confirm. |
| `research.md` | Validate nontrivial topic; choose Explore or general-purpose; spawn one or parallel agents; persist and review RESEARCH. |
| `resume-project.md` | Verify `.paul`; find handoff; load/reconcile STATE; route one action; later archive/delete handoff. Has one `<process>` open and two closes. |
| `roadmap-management.md` | Two operation processes: add phase; or confirm/remove unstarted phase, conditionally delete empty directory, renumber, update state. |
| `transition-phase.md` | Verify plan/summary count; clean handoffs; evolve PROJECT/STATE/ROADMAP; sync manifest; merge/delete branch with consent; commit phase; verify cross-file consistency; route. |
| `unify-phase.md` | Gather E/Q results; compare plan/actual; warn on skill gaps; create quick/full SUMMARY; update state/manifest; mandatory transition on last plan. |
| `verify-work.md` | Select recent summary/scope; generate UAT checklist; user tests; collect/log issues; verdict; intent/spec/code route. |

The workflow-style rule says every workflow must have `<purpose>`, `<when_to_use>`, and `<process>` (`src/rules/workflows.md` lines 10–21). Static inspection found `<when_to_use>` absent from `debug.md`, `map-codebase.md`, `phase-assumptions.md`, and `verify-work.md`. `resume-project.md` has mismatched process closers; `roadmap-management.md` intentionally contains two complete process blocks, one per operation.

### 3.5 Concept references — 14/14

| Reference | Account |
|---|---|
| `checkpoints.md` | Three blocking checkpoint types, execution protocol, diagnostic routing, auth gates, automation-first rule. |
| `context-management.md` | FRESH/MODERATE/DEEP/CRITICAL remaining-context brackets, lean loading, plan sizing, handoffs. |
| `extension-points.md` | Canonical five post-core workflow extension sites and comment-block injection convention. |
| `git-strategy.md` | Per-task outcome commits, plan metadata commits, WIP handoffs, formats and rationale. |
| `loop-phases.md` | Canonical loop semantics, states, invariants, E/Q statuses, transitions, anti-patterns. |
| `plan-format.md` | Executable PLAN schema, task anatomy, BDD ACs, boundaries, specificity and sizing. |
| `quality-principles.md` | Solo-user/Claude model, plans-as-prompts, loop-first, evidence chain, scope/deviation principles. |
| `research-quality-control.md` | Enumeration, authoritative sourcing, confidence, scope/currency checks, red flags and submission checklist. |
| `sonarqube-integration.md` | Sonar server/project/MCP setup, quality workflow, CONCERNS output and troubleshooting. |
| `specialized-workflow-integration.md` | SPECIAL-FLOWS → ROADMAP → PLAN → UNIFY trace and required/optional semantics. |
| `subagent-criteria.md` | Six all-required criteria, disqualifiers, decision tree, handoff/verification pattern. |
| `tdd.md` | TDD applicability, single-feature plan, RED/GREEN/REFACTOR, commits, context and failures. |
| `toml-sync.md` | Read-modify-write manifest, append-only ledger, JSON migration, trigger matrix. |
| `work-units.md` | Context-based sizing, split signals/strategies, estimation heuristics. |

### 3.6 Maintainer rules — 5/5

| Rule file | Account |
|---|---|
| `commands.md` | Command frontmatter, section order, thin-wrapper and reference conventions. |
| `references.md` | Reference structure, teaching patterns, lazy loading; explicitly conceptual, not executable. |
| `style.md` | Imperative/no-filler tone, temporal-language rule, naming/XML/reference/AC/commit conventions. |
| `templates.md` | Template file anatomy and placeholder/frontmatter conventions. |
| `workflows.md` | Required/optional workflow containers, step ordering, loop awareness, conditional form. |

These are installed under `paul-framework/rules/`, not Claude Code's top-level `.claude/rules/`, and no installed command references them. **Inference:** they function as repository-authoring guidance unless another external loader explicitly reads them.

### 3.7 Templates — 27/27

| Template | Generated artifact / purpose |
|---|---|
| `config.md` | Project settings, SonarQube, enterprise audit, preferences. |
| `CONTEXT.md` | Phase goals, approach, constraints, questions, context. |
| `DEBUG.md` | Persistent debug focus, symptoms, eliminated hypotheses, evidence, resolution. |
| `DISCOVERY.md` | Options, comparison, recommendation, confidence, quality report. |
| `HANDOFF.md` | Cold-start resume document. |
| `ISSUES.md` | Open/closed project enhancement log with IDs and effort. |
| `ledger-toml.md` | Append-only action/session history for BASE attribution. |
| `milestone-archive.md` | Completed milestone archive with phases and summary. |
| `milestone-context.md` | Pre-milestone features, scope, phase map, constraints. |
| `MILESTONES.md` | Shipped-milestone log with stats, git range, next work. |
| `paul-json.md` | Deprecated pre-v1.4 JSON manifest retained for migration documentation. |
| `paul-toml.md` | Identity, provenance, milestone, phase, loop, satellite, statistics manifest. |
| `PLAN.md` | Full executable plan, ACs, tasks, boundaries, verification, skills. |
| `PROJECT.md` | Current project truth: value, requirements, users, constraints, decisions, metrics, stack. |
| `RESEARCH.md` | Topic, sources/findings/recommendations/questions plus agent metadata/status. |
| `ROADMAP.md` | Milestones, numbered/decimal phases, depth/research/status fields. |
| `SPECIAL-FLOWS.md` | Project skills, phase overrides, assets, audit checklist, amendments. |
| `STATE.md` | Current milestone/phase/plan, visual loop, decisions/issues/blockers, boundaries, continuity. |
| `SUMMARY.md` | Outcome, AC and verification results, files/commits/decisions/deviations/issues/readiness. |
| `UAT-ISSUES.md` | Phase-plan UAT issue log with severity, reproduction, expected/actual and resolution. |
| `codebase/architecture.md` | Pattern, layers, flow, abstractions, entry points, errors, cross-cutting concerns. |
| `codebase/concerns.md` | Debt, bugs, security, performance, fragility, scale, dependencies, gaps. |
| `codebase/conventions.md` | Naming, style, imports, errors/logging, comments, function/module design. |
| `codebase/integrations.md` | APIs/services, storage, identity, observability, CI/CD, env, webhooks. |
| `codebase/stack.md` | Languages, runtime, frameworks, dependencies, configuration, platforms. |
| `codebase/structure.md` | Directory layout/purpose, key locations, naming, placement rules. |
| `codebase/testing.md` | Framework, organization, structure, mocking, fixtures, coverage, test types/patterns. |

## 4. Architecture and layer model

```text
User /paul:* request
  → .claude/commands/paul/<command>.md       thin entry + allowed-tools
    → .claude/paul-framework/workflows/*    stateful procedure
      → references/*                        fogalmi szabályok
      → templates/*                         output contractok
      → .paul/*                              tartós project state
      → source / CLI / MCP / Task            végrehajtás és verification
    → optional CARL / BASE                   külső activation/context
```

**[Fact]** Az installer nem parse-olja, validálja vagy regisztrálja ezt a gráfot; Markdown fájlokat másol. A `mandatory`, `blocking` és `enforced` szavak ezért prompt-level szerződések. Külön hook vagy runtime guard nélkül a modell vagy a felhasználó megkerülheti őket.

### Global–Project–Session–Local mapping

| Réteg | PAUL-megfeleltetés | Tartósság és boundary |
|---|---|---|
| `Global` | `~/.claude/commands/paul`, `~/.claude/paul-framework`, custom `CLAUDE_CONFIG_DIR`, opcionális `~/.carl`, külső BASE | Több projektre ható gép-/felhasználói install. Az installer ugyanazokat a fájlokat felülírja backup nélkül. |
| `Project` | local `./.claude` install; `.paul/PROJECT.md`, `ROADMAP.md`, `STATE.md`, `MILESTONES.md`, `paul.toml`, `ledger.toml`, config és specialized flows | Repository-szintű workflow- és truth state. Részben Gitbe kerülhet; konzisztenciája csak prompttal kikényszerített. |
| `Session` | aktuális Claude conversation, betöltött command/workflow/context, approval decision, E/Q task status, Task/subagent eredmények | Ephemeral. A session-memory elveszhet; HANDOFF és STATE szolgál cold-start helyreállításra. |
| `Local` | adott phase/plan alatti PLAN, SUMMARY, CONTEXT, RESEARCH, DISCOVERY, UAT/ISS, HANDOFF és a módosított source fájlok | Egy work unit/phase lokális scope-ja. A PAUL ezt nem nevezi formálisan `Local` layernek; ez elemzői megfeleltetés. |

**[Inference]** A rendszer valós authority hierarchy-ja: aktuális artifact és prompt > session memory. Ez jó alap, de executable schema és atomic state transition hiányában az eltérő Markdownok közötti igazságot továbbra is a modellnek kell rekonstruálnia.

## 5. Events, formulas, state transitions, and loops

### PLAN–APPLY–UNIFY state machine

| Event/state | Belépési bizonyíték | Kimenet/transition |
|---|---|---|
| `PLAN` entry | előző UNIFY lezárt vagy első plan; roadmap phase ismert; blocker nincs | PLAN artifact, AC-k, boundaries, tasks; explicit approvalra vár |
| `PLAN approved` | egyértelmű `approved` / `execute` / `go ahead` | APPLY engedélyezett |
| `Execute` | következő task és boundary betöltve | `DONE`, `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT` vagy `BLOCKED` |
| `Qualify` | tényleges output friss visszaolvasása és verify | `PASS`; vagy `GAP/DRIFT` fix + újraqualify |
| E/Q retry | GAP/DRIFT | maximum három kör, majd user escalation |
| checkpoint | `human-verify`, `decision`, ritka `human-action` | blokkol, amíg a user-válasz és verification meg nem történik |
| APPLY complete | taskok PASS vagy blocker/deviation dokumentált | STATE update, UNIFY felajánlása |
| `UNIFY` | PLAN + actual evidence | SUMMARY, STATE/manifest reconciliation; next plan vagy transition |
| phase transition | PLAN count = SUMMARY count vagy explicit override | PROJECT/ROADMAP/STATE evolution, Git lépések, következő phase/milestone |

**[Fact]** Az APPLY nem garantál abszolút „minden task sikeres” invariantot: dokumentált blockerrel is lezárható. A Qualify mindig friss visszaolvasást és verificationt kér; a loop három sikertelen GAP/DRIFT kör után embert von be.

**[Fact]** Checkpoint failure routing előbb intent/spec/code rétegre osztja a hibát. Intent esetén újratervezés, spec esetén AC/task update a kód előtt, code esetén helyben javítás történik. Az authentication gate dinamikus: előbb automation attempt, csak konkrét auth-failure után human action.

**[Fact]** A `toml-sync` trigger matrix tíz workflow-családot állít, de tényleges `<step name="sync_paul_toml">` csak hat workflowban van: `plan-phase`, `apply-phase`, `unify-phase`, `transition-phase`, `create-milestone`, `complete-milestone`. `verify`, `pause`, `resume` nem implementálja a mátrixban ígért syncet.

## 6. Agent and sub-agent model

**[Fact]** Nincs saját agent runtime vagy scheduler. A Claude Code `Task` capability indít host-oldali subagentet; a PAUL prompt dönti el, mikor és milyen personával.

Az elvi subagent gate hat együttes kritériumot kér: independence, clear scope, parallel value, suitable complexity, token efficiency, compatible state. A pozitív példák között kód- és tesztimplementáció is szerepel APPLY state-ben. Ezzel szemben a README az implementációt in-session tartja, és a subagentet discovery/research feladatra korlátozza. A tényleges APPLY workflow a szűkebb, in-session modellt követi.

**[Fact]** `/paul:research` tipikusan egy agentet indít, miközben az általános criteria szerint a single sequential tasknak in-session kellene maradnia. A kivétel nincs feloldva.

**[Inference]** A „subagent quality gap ~70%” és a 2–3k token launch cost nem mérési eredmény: nincs benchmark, dataset vagy teszt. Ezek author estimate-ek.

## 7. Roles, personas, skills, plugins, hooks, and automation

| Role/persona | Trigger | Scope/output | Tool boundary |
|---|---|---|---|
| `Explore` research agent | codebase-topic vagy ismeretlen belső szerkezet | file/pattern/architecture evidence | parent: `Task`, `Read`, `Bash`, `Write` |
| `general-purpose` research agent | web/docs/comparison topic | primary-source kutatás | workflow WebSearch/WebFetch-et feltételez; transitive permission nem bizonyított |
| Discovery agents | standard/deep decision research | options, cross-check, confidence, DISCOVERY | széles web/read/search tool set |
| Map Agent 1 | codebase map | STACK + INTEGRATIONS | `Explore`, background |
| Map Agent 2 | codebase map | ARCHITECTURE + STRUCTURE | `Explore`, background |
| Map Agent 3 | codebase map | CONVENTIONS + TESTING | `Explore`, background |
| Map Agent 4 | codebase map | CONCERNS | `Explore`, background |
| senior principal/compliance persona | `/paul:audit` | six-part plan audit és PLAN mutation | ugyanaz a Claude session; nem subagent |
| debugger persona | orphan `debug` workflow | hypothesis/test/evidence loop | nincs command entry point |

**[Fact]** A repository nem tartalmaz plugin manager vagy általános hook runtime-ot. A „skills” a `.paul/SPECIAL-FLOWS.md` által deklarált külső slash commandok. A lifecycle: discover/configure → phase annotation → PLAN injection → APPLY gate → UNIFY audit. Az invocation ténye conversation-memoryből következtetett, nem ledger-eventből bizonyított.

**[Fact]** A CARL opcionális external activation layer; a source-ban jelen van, de a package/install outputból hiányzik. BASE szintén külső rendszer, itt csak `paul.toml`, `ledger.toml` és domain/tag integration contract formájában jelenik meg.

## 8. Workflow composition and reference graph

**[Fact]** A normál kompozíció `command → workflow → references/templates → project state/source/tools`. Hat command (`config`, `handoff`, `help`, `plan-fix`, `progress`, `status`) self-contained. A többi command statikus `execution_context` és dinamikus `.paul` context kombinációját adja.

### Installed reference accounting

| Class | Count | Értelmezés |
|---|---:|---|
| Static, resolved | 73 | 69 custom-prefix + 4 érvényes framework-relative reference |
| Static, unresolved | 58 | konkrét `@src/...` target, amely nincs az install tree-ben |
| Dynamic/example | 133 | 123 `.paul/` state path + 10 placeholder/example |
| Other | 10 | package/import-szerű `@` token, nem PAUL file reference |
| **Total** | **274** | unique `(Source, Line, Target)` evidence row |

### A 63 `@src/` token helyes bontása

| Installed area | Concrete unresolved | Examples/placeholders | Execution-relevant concrete |
|---|---:|---:|---:|
| Commands | 2 | 0 | 2 |
| Workflows | 42 | 0 | 42 |
| Concept references | 3 | 4 | 2 |
| Maintainer rules | 11 | 0 | 0 |
| Templates | 0 | 1 | 0 |
| **Total** | **58** | **5** | **46 = 2 + 42 + 2** |

**[Runtime]** A first-failure closure 17 érintett commandot adott: `add-phase`, `apply`, `complete-milestone`, `discover`, `discuss-milestone`, `discuss`, `flows`, `init`, `map-codebase`, `milestone`, `plan`, `register`, `remove-phase`, `research-phase`, `research`, `unify`, `verify`. A másik 11 command closure-jében nincs unresolved concrete él.

**[Inference]** A 46 execution-relevant él invalid installed dependency, nem 46 bizonyított Claude crash. A modell inline tartalomból folytathatja, javíthatja vagy figyelmen kívül hagyhatja. A `map-codebase` kockázata különösen nagy, mert command-szinten nincs részletes alternatív procedure.

## 9. Script-level execution paths

### Installer

```text
bin/install.js
  → parse recognized flags
  → choose global/custom/local Claude directory
  → copy src/commands → commands/paul
  → copy src/{templates,workflows,references,rules}
       → paul-framework/{templates,workflows,references,rules}
  → in every Markdown replace only literal ~/.claude/
  → print success
```

**[Fact]** Nincs staging, collision report, backup, atomic swap, rollback vagy post-copy reference validation. A non-Markdown fájl byte-copy; a current installable tree fájljai Markdownok.

### Core loop

```text
/paul:plan → plan-phase
  → STATE/ROADMAP/context load → track selection → PLAN → validation → approval
/paul:apply → apply-phase
  → approval gate → E/Q tasks → checkpoints → state/manifest update
/paul:unify → unify-phase
  → plan/actual compare → SUMMARY → state/manifest update
  → if last plan: transition-phase → project/roadmap evolution → Git → consistency gate
```

**[Fact]** A `unify` command allowlistje csak `Read`, `Write`, `AskUserQuestion`, miközben a mandatory `transition-phase` Bash/git műveleteket és edit jellegű módosítást ír elő. A nested workflow transitive tool permission semantics nincs igazolva.

### Supporting paths

- `pause` → `pause-work`: pozíciódetektálás, HANDOFF, STATE, opcionális WIP commit;
- `resume` → `resume-project`: STATE/HANDOFF visszatöltés, egy következő action; a workflowban duplicate `</process>` van;
- `milestone` / `complete-milestone`: milestone create/evolve/archive/version/tag;
- `research` / `research-phase` / `discover`: agent choice, confidence/source control, RESEARCH/DISCOVERY artifact;
- `map-codebase`: négy Explore agent, hét codebase dokumentum; command delegate path hibás;
- `audit`: same-session enterprise/compliance persona és PLAN mutation;
- `verify`: guided UAT, issue logging és fix routing;
- `quality-gate` és `debug`: workflow létezik, command entry point nincs.

## 10. Installation, update, migration, recovery, and removal

**[Fact]** Az installer négy módot ismer: `--global/-g`, `--local/-l`, `--config-dir/-c`, help. Global célprecedencia: explicit config → `CLAUDE_CONFIG_DIR` → home `.claude`; local mindig cwd `./.claude`. Csak `~/` tilde-formát bővít, Windows `~\`-t nem.

**[Fact]** Argument parsing fail-open:

- unknown option nincs elutasítva;
- `--config-dir=` üres stringre fordul és environment/default global célra eshet vissza;
- `--config-dir=a=b` a második `=` utáni részt elveszíti;
- ismert location flag nélkül az interactive prompt defaultja global.

**[Runtime]** `node bin/install.js --help --definitely-unknown` exit 0-val helpet adott, unknown-option diagnostic nélkül.

**[Fact]** Nincs külön update vagy uninstall command. Reinstall ugyanazokat a célfájlokat felülírja. Eltávolítás kézi. A project state migration részben prompt workflow: `register-manifest` és `toml-sync` `paul.json → paul.toml` konverziót ír elő, majd törli a JSON-t. Sok workflow azt mondja, manifest hiányában „skip silently”.

**[Fact]** Recovery contract széttartó: init részleges eredményt jelent; installer exception után partial tree maradhat; transition és complete-milestone Git/cleanup műveleteihez nincs egységes rollback; pause/handoff a session recovery fő mechanizmusa.

## 11. Testing, observability, security, and failure modes

### Testing és observability

**[Fact]** Nincs automated repository test suite vagy CI gate. A framework observabilityje Markdown state, SUMMARY, `ledger.toml`, UAT/ISS, audit és progress output. A ledger „minden action” állítása nem igaz: több workflow nem appendel eseményt.

Pozitív failure pattern:

- APPLY explicit státuszokat ad és friss verificationt kér;
- három GAP/DRIFT kör után escalation;
- phase transition előtt blocking cross-file consistency check;
- research confidence és source-quality jelölés;
- init created/failed itemeket külön tud jelenteni.

### Installer security boundary

- arbitrary destination path, allowlist/normalization/symlink defense nélkül;
- same-name overwrite confirmation és backup nélkül;
- path literal beillesztése quoting/escaping nélkül;
- whitespace, Unicode, drive/UNC és separator semantics nincs a Claude parserrel tesztelve;
- unknown/empty/malformed argument fail-open útvonalak;
- exception után partial tree, rollback nélkül.

### Prompt and data trust boundary

**[Fact]** A commandok széles `Bash`, `Write`, `Edit`, `Task`, web és MCP toolokat engedhetnek. A `.paul/*`, PLAN/SUMMARY, source fájlok és web/research output repository- vagy külső-controlled adatként kerülnek tool-capable model contextbe. Nincs executable instruction/data separation, sanitization vagy prompt-injection guard; az XML/frontmatter csak convention.

**[Inference]** Ha Claude a relatív `@src/...` pathot a working projecthez oldja, egy azonos nevű project file shadowolhatja a hiányzó framework resource-t és instructionként töltődhet be. Ez nem demonstrált exploit, mert az actual parser nem futott.

### Destructive and secret boundary

- transition fetch/checkout/merge/branch-delete/stage/commit lépéseket tartalmaz;
- complete-milestone routine tag-et ír elő;
- codebase refresh, resume, JSON migration és remove-phase fájlt törölhet;
- merge kér consentet, a normal phase commit külön approval nélkül része a transitionnek;
- nincs általános secret redaction/logging policy; néhány template külön mondja, hogy secretet ne írjon ki.

## 12. Documentation-code-test drift

| Dokumentált claim | Minősítés | Pinned reality |
|---|---|---|
| Mac/Windows/Linux működés | **[Author claim]**, részben observed | Windows copy sikeres; custom path quoting és `@src` OS-független hiba marad |
| README: 26 commands | **[Fact: drift]** | 28 command file |
| help: 23 commands / 14 workflows / 13 templates | **[Fact: drift]** | 28 / 23 / 27 |
| `/paul:quality-gate` elérhető | **[Fact: gap]** | workflow van, command nincs |
| CARL dynamic loading | **[Fact: distribution gap]** | CARL nincs pack/install outputban, manual path is hibás |
| bármely workflow auto-migrál; minden state change TOML sync | **[Fact: overstatement]** | explicit sync step csak hat workflowban |
| ledger minden PAUL actiont rögzít | **[Fact: overstatement]** | verify/pause/resume/audit/discussion/research/map/config stb. nem appendel |
| minden PLAN tartalmaz boundaries-t | **[Fact: drift]** | quick-fix plan explicit elhagyja |
| skills enforced és APPLY-blocking | **[Fact: qualified]** | APPLY override-ot kínál; UNIFY warning-only; quick-fix skill section nélkül |
| automated audit nem marad ki | **[Author claim]** | session-memory review, invocation hook/record nélkül |
| ~70% quality, 2–3k spawn cost | **[Author claim]** | nincs benchmark/módszertan |
| IDEATION content pipeline | **[Author claim: future]** | helyesen jövőbeli ötletként jelölve |

További schema/style drift: `config.md` és `map-codebase.md` frontmatter nélkül; négy workflowban nincs a maintainer rule által elvárt `<when_to_use>`; `resume-project.md` duplicate `</process>`; context bracketek 70/40/20 és 60/40 thresholdokat is használnak; a CARL source nem tartalmaz context-bracket rule-t.

## 13. Runtime experiments

| Kísérlet | Exit | Eredmény |
|---|---:|---|
| work-state preflight | 0 | pin/branch/upstream/clean/no-PR igazolva |
| `node bin/install.js --help` | 0 | usage és layout |
| `--global --local` | 1 | explicit conflict error |
| `--global --config-dir` argument nélkül | 1 | explicit path-required error |
| `--local --config-dir <path>` | 1 | explicit incompatible-option error |
| `--help --definitely-unknown` | 0 | unknown option silently ignored |
| fresh local install | 0 | 97 = 28 + 69; 73 rewrite; 63 `@src`; CARL/src absent |
| fresh custom-global install, space-es path | 0 | 97 fájl; 73/73 prefix rewrite; exact content match |
| `npm pack --dry-run --json` | 0 | 101 entry; CARL/assets/IDEATION/comparison absent |
| supplied smoke exact comparison | 0 | expected 97, missing/extra/mismatch 0 |
| `references.csv` validation | 0 | 274 row; bad source/line/token/existence 0; duplicate 0 |
| installed closure reconstruction | 0 | 58 unresolved; 46 execution-relevant; 17 affected command |
| citation validation | 0 | 176 pinned citation; 106 unique gear path; missing/range issue 0 |
| inventory hash validation | 0 | 108/108 path, byte és SHA-256 match |

**[Runtime]** A custom Windows output egyik formája `@C:\...\custom config/paul-framework/...`: a filesystem normalizálva létezik, de a reference unquoted, space-t tartalmaz és vegyes separatoros. Claude Code parser-próba nem történt.

Nem futott: live/default global install, actual Claude command/`@` parsing, BASE, CARL, SonarQube/MCP, web/paid/credentialed service, destructive Git workflow, macOS/Linux runtime.

## 14. Reusable patterns

| Pattern | Provenance | Adaptáció | Trade-off / licenc |
|---|---|---|---|
| Plan–Apply–Unify artifact loop | `loop-phases.md`, `plan/apply/unify` workflows | explicit approval, plan/actual diff, immediate summary/state update | jó governance; prompt helyett executable gate ajánlott; MIT notice direct reuse-nál |
| Execute/Qualify reread | `apply-phase.md` | status után actual output újraolvasása, fresh verify, PASS/GAP/DRIFT | több költség, jobb hibafelfedés |
| Intent/spec/code classification | `checkpoints.md` | javítás előtt failure layer | megelőzi a symptom patch-et |
| Thin command / deep workflow / reference / template | `commands.md` és tree | canonical graph + staged edge validation | jól olvasható, de minden path deployment contract |
| Scope-adaptive ceremony | quick/standard/complex | ceremony méretét skálázni, protected boundary-t megtartani | gyorsabb kis change, nagyobb drift-kockázat |
| One-next-action + HANDOFF | progress/pause/resume | cold resume; handoff csak readback után archive/delete | kevesebb döntési teher; stale handoff veszély |
| Snapshot + append-only ledger | STATE + ledger | schema, atomic write, event completeness | current truth és history külön; több sync |
| Specialized flow lifecycle | config + PLAN/APPLY/UNIFY | invocation eventet ténylegesen logolni | domain compliance; nagyobb tool coupling |
| Research quality controls | research/discovery | primary source, version, confidence, negative-claim limits | alaposabb, lassabb |
| Comment-block extension point | workflow extension markers | versioned manifest + idempotency + integration test | egyszerű, de collision/drift lehetséges |

### Licenc és provenance

**[Fact]** Az MIT engedi a használatot, másolást, módosítást, merge-et, publikálást, disztribúciót, sublicencet és értékesítést; a copyright- és permission notice-t minden copy vagy substantial portion részeként meg kell tartani, warranty nélkül.

- Direct reuse/adaptation: teljes MIT notice + Chris Kahler copyright, forráscommit mapping, endorsement kerülése.
- Pattern-only clean room: behavior-level spec külön szerzőtől, friss wording/schema/test másik implementálótól; ne másolja a distinctive prompt textet, példákat, diagramot, fájlneveket vagy brandinget.
- A clean-room risk-reduction, nem jogi vélemény. Az MIT nem ad automatikus jogot harmadik fél trademarkjaira vagy szolgáltatásneveire.

## 15. Weaknesses and anti-patterns

1. **P0 — invalid distribution graph:** 58 concrete missing installed target; 46 execution-relevant; 17 command closure érintett.
2. **P0 — `map-codebase` missing delegate:** nincs distributed target; actual Claude failure **[Inference]**.
3. **P1 — CARL distribution/path defect:** nem packolt/telepített, manual command path hibás.
4. **P1 — unvalidated overwrite install:** staging, backup, rollback és post-copy graph validation nélkül.
5. **P1 — prompt-only guarantees:** approvals, boundaries, mandatory transition, skill use nincs independent guarddal kikényszerítve.
6. **P1 — prompt-injection/path-shadowing boundary:** untrusted data tool-capable contextben; nincs isolation.
7. **P1 — fail-open argument parsing:** unknown/empty/truncated config input és global-default prompt.
8. **P1 — transitive tool mismatch:** UNIFY mandatory transitionje olyan Bash/git toolokat kér, amelyek a command allowlistben nincsenek.
9. **P1 — state/ledger drift:** docs és trigger matrix több syncet ígér, mint ami implementált.
10. **P2 — orphan workflows:** `quality-gate`, `debug`; a map workflow invalid incoming installed edge mögött.
11. **P2 — schema/style drift:** frontmatter/`when_to_use`/duplicate close/count/context inconsistency.
12. **P2 — destructive defaults:** commit/tag/delete műveletek egységes approval/recovery nélkül.
13. **Anti-pattern — silent skip:** manifest hiánya több helyen elnémítja a BASE/ledger integration loss-t.
14. **Anti-pattern — memory-based compliance:** skill invocation és audit conversation recallra épül event record helyett.
15. **Anti-pattern — docs by hand:** command/workflow/template counts és capabilities nem generált inventoryból jönnek.

Javítási sorrend: canonical installed namespace → staged reference validator → path quoting/parser integration test → command entrypoint/allowlist repair → executable state schema/transaction → opt-in destructive Git → generated docs/counts.

## 16. Evidence index

Az evidence ledger az eredeti forrásjelentés mind a 176 immutable, pinned GitHub blob citation előfordulását változatlan cél-URL-lel őrzi. Ez 106 egyedi gear pathot fed le; a két további tracked path a section 3-ban név szerint kezelt bináris asset.

1. [`package.json` lines 1–37](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/package.json#L1-L37)
2. [`.gitignore`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/.gitignore#L1-L19)
3. [`README.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L1-L31)
4. [`IDEATION.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/IDEATION.md#L1-L9)
5. [`PAUL-VS-GSD.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/PAUL-VS-GSD.md#L1-L11)
6. [`LICENSE`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/LICENSE#L1-L20)
7. [`package.json`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/package.json#L1-L37)
8. [`bin/install.js`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L1-L17)
9. [`src/carl/PAUL`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/carl/PAUL#L1-L26)
10. [`src/carl/PAUL.manifest`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/carl/PAUL.manifest#L1-L11)
11. [`src/rules/commands.md` lines 21–35](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/commands.md#L21-L35)
12. [`add-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/add-phase.md#L1-L36)
13. [`apply.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/apply.md#L1-L82)
14. [`assumptions.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/assumptions.md#L1-L37)
15. [`audit.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/audit.md#L1-L56)
16. [`complete-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/complete-milestone.md#L1-L36)
17. [`config.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/config.md#L1-L12)
18. [`consider-issues.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/consider-issues.md#L1-L40)
19. [`discover.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/discover.md#L1-L47)
20. [`discuss-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/discuss-milestone.md#L1-L33)
21. [`discuss.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/discuss.md#L1-L34)
22. [`flows.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/flows.md#L1-L73)
23. [`handoff.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/handoff.md#L1-L29)
24. [`help.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/help.md#L1-L17)
25. [`init.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/init.md#L1-L53)
26. [`map-codebase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/map-codebase.md#L1-L33)
27. [`milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/milestone.md#L1-L34)
28. [`pause.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/pause.md#L1-L44)
29. [`plan-fix.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/plan-fix.md#L1-L19)
30. [`plan.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/plan.md#L1-L36)
31. [`progress.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/progress.md#L1-L43)
32. [`register.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/register.md#L1-L35)
33. [`remove-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/remove-phase.md#L1-L37)
34. [`research-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/research-phase.md#L1-L31)
35. [`research.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/research.md#L1-L46)
36. [`resume.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/resume.md#L1-L49)
37. [`status.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/status.md#L1-L22)
38. [`unify.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/unify.md#L1-L26)
39. [`verify.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/verify.md#L1-L59)
40. [`apply-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L1-L26)
41. [`audit-plan.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/audit-plan.md#L1-L21)
42. [`complete-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/complete-milestone.md#L1-L30)
43. [`configure-special-flows.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/configure-special-flows.md#L1-L27)
44. [`consider-issues.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/consider-issues.md#L1-L12)
45. [`create-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/create-milestone.md#L1-L28)
46. [`debug.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/debug.md#L1-L28)
47. [`discovery.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/discovery.md#L1-L24)
48. [`discuss-milestone.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/discuss-milestone.md#L1-L29)
49. [`discuss-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/discuss-phase.md#L1-L31)
50. [`init-project.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/init-project.md#L1-L30)
51. [`map-codebase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/map-codebase.md#L1-L31)
52. [`pause-work.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/pause-work.md#L1-L26)
53. [`phase-assumptions.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/phase-assumptions.md#L1-L9)
54. [`plan-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/plan-phase.md#L1-L31)
55. [`quality-gate.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/quality-gate.md#L1-L31)
56. [`register-manifest.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/register-manifest.md#L1-L17)
57. [`research.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/research.md#L1-L29)
58. [`resume-project.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/resume-project.md#L1-L33)
59. [`roadmap-management.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/roadmap-management.md#L1-L34)
60. [`transition-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L1-L21)
61. [`unify-phase.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/unify-phase.md#L1-L28)
62. [`verify-work.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/verify-work.md#L1-L11)
63. [`src/rules/workflows.md` lines 10–21](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/workflows.md#L10-L21)
64. [`checkpoints.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/checkpoints.md#L1-L18)
65. [`context-management.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/context-management.md#L1-L17)
66. [`extension-points.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/extension-points.md#L1-L18)
67. [`git-strategy.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/git-strategy.md#L1-L24)
68. [`loop-phases.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L1-L18)
69. [`plan-format.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/plan-format.md#L1-L35)
70. [`quality-principles.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/quality-principles.md#L1-L24)
71. [`research-quality-control.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/research-quality-control.md#L1-L9)
72. [`sonarqube-integration.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/sonarqube-integration.md#L1-L20)
73. [`specialized-workflow-integration.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/specialized-workflow-integration.md#L1-L29)
74. [`subagent-criteria.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L1-L12)
75. [`tdd.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/tdd.md#L1-L32)
76. [`toml-sync.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/toml-sync.md#L1-L31)
77. [`work-units.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/work-units.md#L1-L21)
78. [`commands.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/commands.md#L1-L18)
79. [`references.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/references.md#L1-L23)
80. [`style.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/style.md#L1-L26)
81. [`templates.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/templates.md#L1-L18)
82. [`workflows.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/workflows.md#L1-L27)
83. [`config.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/config.md#L1-L12)
84. [`CONTEXT.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/CONTEXT.md#L1-L12)
85. [`DEBUG.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/DEBUG.md#L1-L12)
86. [`DISCOVERY.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/DISCOVERY.md#L1-L12)
87. [`HANDOFF.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/HANDOFF.md#L1-L12)
88. [`ISSUES.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/ISSUES.md#L1-L12)
89. [`ledger-toml.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/ledger-toml.md#L1-L12)
90. [`milestone-archive.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/milestone-archive.md#L1-L12)
91. [`milestone-context.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/milestone-context.md#L1-L12)
92. [`MILESTONES.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/MILESTONES.md#L1-L12)
93. [`paul-json.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/paul-json.md#L1-L12)
94. [`paul-toml.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/paul-toml.md#L1-L12)
95. [`PLAN.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/PLAN.md#L1-L18)
96. [`PROJECT.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/PROJECT.md#L1-L18)
97. [`RESEARCH.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/RESEARCH.md#L1-L18)
98. [`ROADMAP.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/ROADMAP.md#L1-L18)
99. [`SPECIAL-FLOWS.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/SPECIAL-FLOWS.md#L1-L18)
100. [`STATE.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/STATE.md#L1-L18)
101. [`SUMMARY.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/SUMMARY.md#L1-L18)
102. [`UAT-ISSUES.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/UAT-ISSUES.md#L1-L18)
103. [`codebase/architecture.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/architecture.md#L1-L12)
104. [`codebase/concerns.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/concerns.md#L1-L12)
105. [`codebase/conventions.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/conventions.md#L1-L12)
106. [`codebase/integrations.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/integrations.md#L1-L12)
107. [`codebase/stack.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/stack.md#L1-L12)
108. [`codebase/structure.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/structure.md#L1-L12)
109. [`codebase/testing.md`](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/templates/codebase/testing.md#L1-L12)
110. [`src/rules/commands.md` lines 37–56](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/rules/commands.md#L37-L56)
111. [`context-management.md` lines 67–88](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/context-management.md#L67-L88)
112. [lines 7–16](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/context-management.md#L7-L16)
113. [`work-units.md` lines 124–130](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/work-units.md#L124-L130)
114. [`loop-phases.md` lines 20–49](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L20-L49)
115. [51–120](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L51-L120)
116. [122–154](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L122-L154)
117. [`apply-phase.md` lines 89–160](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L89-L160)
118. [`checkpoints.md` lines 158–166](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/checkpoints.md#L158-L166)
119. [`checkpoints.md` lines 135–156](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/checkpoints.md#L135-L156)
120. [`toml-sync.md` lines 33–55](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/toml-sync.md#L33-L55)
121. [`subagent-criteria.md` lines 9–12](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L9-L12)
122. [lines 13–24](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L13-L24)
123. [78–89](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L78-L89)
124. [`README.md` lines 403–419](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L403-L419)
125. [`map-codebase.md` lines 81–93](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/map-codebase.md#L81-L93)
126. [130–179](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/map-codebase.md#L130-L179)
127. [217–290](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/map-codebase.md#L217-L290)
128. [`research.md` lines 59–89](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/research.md#L59-L89)
129. [lines 30–53](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L30-L53)
130. [197–210](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L197-L210)
131. [lines 84–92](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L84-L92)
132. [lines 122–137](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L122-L137)
133. [lines 94–117](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L94-L117)
134. [lines 141–163](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L141-L163)
135. [`package.json` lines 8–15](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/package.json#L8-L15)
136. [`init-project.md` lines 34–126](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/init-project.md#L34-L126)
137. [483–533](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/init-project.md#L483-L533)
138. [`plan-phase.md` lines 51–80](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/plan-phase.md#L51-L80)
139. [lines 139–191](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/plan-phase.md#L139-L191)
140. [`apply-phase.md` lines 30–86](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L30-L86)
141. [`audit-plan.md` lines 140–183](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/audit-plan.md#L140-L183)
142. [250–301](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/audit-plan.md#L250-L301)
143. [`verify.md` lines 8–14](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/verify.md#L8-L14)
144. [54–59](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/verify.md#L54-L59)
145. [`transition-phase.md` lines 23–60](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L23-L60)
146. [181–263](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L181-L263)
147. [265–319](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L265-L319)
148. [`quality-principles.md` lines 116–126](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/quality-principles.md#L116-L126)
149. [`audit-plan.md` lines 326–343](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/audit-plan.md#L326-L343)
150. [README lines 13–18](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L13-L18)
151. [line 176](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L176-L176)
152. [help line 525](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/help.md#L525-L525)
153. [Sonar ref lines 92–102](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/sonarqube-integration.md#L92-L102)
154. [README lines 494–505](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L494-L505)
155. [README lines 438–444](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L438-L444)
156. [README lines 440–442](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L440-L442)
157. [PAUL-VS-GSD lines 89–97](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/PAUL-VS-GSD.md#L89-L97)
158. [README lines 458–460](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L458-L460)
159. [PAUL-VS-GSD lines 101–109](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/PAUL-VS-GSD.md#L101-L109)
160. [README lines 403–413](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/README.md#L403-L413)
161. [`loop-phases.md` lines 20–43](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L20-L43)
162. [122–148](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L122-L148)
163. [`apply-phase.md` lines 103–160](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L103-L160)
164. [`checkpoints.md` lines 135–156](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/checkpoints.md#L135-L156)
165. [`LICENSE` lines 5–20](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/LICENSE#L5-L20)
166. [`bin/install.js` lines 94–163](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L94-L163)
167. [`package.json` lines 5–15](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/package.json#L5-L15)
168. [`src/commands/map-codebase.md` lines 1–12](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/commands/map-codebase.md#L1-L12)
169. [`src/carl/PAUL` lines 6–15](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/carl/PAUL#L6-L15)
170. [`src/references/loop-phases.md` lines 51–105](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/loop-phases.md#L51-L105)
171. [`src/workflows/unify-phase.md` lines 245–269](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/unify-phase.md#L245-L269)
172. [`src/workflows/transition-phase.md` lines 265–319](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/transition-phase.md#L265-L319)
173. [`src/references/subagent-criteria.md` lines 9–100](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/subagent-criteria.md#L9-L100)
174. [`src/references/toml-sync.md` lines 11–85](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/toml-sync.md#L11-L85)
175. [102–180](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/references/toml-sync.md#L102-L180)
176. [`LICENSE` lines 1–20](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/LICENSE#L1-L20)

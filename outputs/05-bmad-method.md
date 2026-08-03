# BMAD-METHOD — agent- és workflow-architektúra dossier

## 1. Snapshot and provenance

Ez a dossier kizárólag a `bmad-code-org/BMAD-METHOD` repository `main` ágának `770d4259853b9600680745bb2c710bee82604cb4` commitját írja le. A commit tárgya: `fix(installer): apply --set core overrides before config collection (#2671)`, dátuma 2026-08-02; `git describe` eredménye `v6.10.0-52-g770d4259`. A csomag neve `bmad-method`, deklarált verziója 6.10.0, a két CLI alias `bmad` és `bmad-method`, a Node entry point `tools/installer/bmad-cli.js`, a kód licence MIT (`770d425:package.json:L3-L24`).

A bizonyítékok jelölése:

- **[Author claim]**: a szerzők által állított pozicionálás vagy ígéret.
- **[Fact]**: a pinelt forrásból vagy konfigurációból közvetlenül igazolt tény.
- **[Runtime]**: ezen a Windows/PowerShell környezeten reprodukált futási eredmény.
- **[Inference]**: több forrást összekapcsoló elemzői következtetés, nem szerzői garancia.

**[Runtime]** A kezdeti és záró work-state preflight ugyanazt igazolta: repository `work/repos/bmad-method`, branch `main`, pontos pinelt HEAD, clean worktree, upstream `origin/main`. A provider egy `main -> main` nyitott PR #2632 rekordot is visszaadott; ez csak nyers távoli discovery evidence, nem ennek az elemzésnek a PR-je. Az analysis clone-ban nem történt source edit, dependency install, commit, push vagy publikálás.

**[Runtime]** A dependency-backed ellenőrzés külön disposable clone-ban történt: ugyanaz a detached HEAD, `npm ci --ignore-scripts --no-audit --no-fund`, 848 telepített package, 0 checkout-módosítás. Ez elválasztotta a tesztkörnyezet írásait a bizonyítás alapjául szolgáló analysis clone-tól.

Külső webforrás és Context7 nem kellett: a feladat pinelt, repository-internal architektúrát kér, ezért az elsődleges forrás maga a commit. Külső modulrepository nem lett klónozva; a dossier a BMAD-METHOD-ben látható resolver/cache/execution trust boundaryt vizsgálja.

## 2. Executive summary

**[Inference]** A BMAD-METHOD nem klasszikus, folyamatosan futó agent server. Pontosabb leírása: agent-instruction compiler és file-based runtime distribution. A forrás `SKILL.md`, Markdown workflow-step, prompt, template, TOML customization és kis determinisztikus Python/Node segédprogramok gráfja. Az installer ezt több agent host natív skill-formátumába telepíti; futáskor a host LLM értelmezi a protokollt, míg a kényes konfiguráció-, render-, állapot- és evidence-műveleteket kód végzi.

A legerősebb mechanizmusok:

1. **45 host profile, nem 45 azonos fizikai install.** Mindegyik profilnak van project `target_dir`; 42-nek global célja is; 25 ugyanazt a `.agents/skills` címet használja, ezért batch installban deduplikált. Auxiliary command pointer csak `github-copilot` és `opencode` esetén készül (`770d425:tools/installer/ide/platform-codes.yaml:L15-L343`; `770d425:tools/installer/ide/_config-driven.js:L218-L257`).
2. **Rétegzett, strict konfiguráció.** Négy central layer és három per-skill layer, recursive table merge, `code`/`id` szerint cserélődő table-array, más array esetén append; létező hibás TOML explicit failure (`770d425:src/scripts/config_utils.py:L17-L118`).
3. **Immutable, content-addressed workflow snapshot.** Egyetlen opaque substitution pass; source declaration guard; hash az interpreter, source, resolved values és project root fölött; staging + atomic rename + existing-generation verification (`770d425:src/scripts/render_skill.py:L232-L380`).
4. **Explicit state/triage model.** A Build/Build Auto exact statusokat, review kategóriákat, loopbacket, terminal HALT-okat és VCS-akciókat ír elő. A `bad_spec` javítási loop legfeljebb öt ismétlés (`770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L59-L62`).
5. **Ownership-aware install/update.** Manifest-alapú tisztítás, hand-edited pointer megőrzése és shared-target koordináció.

A legfontosabb kockázatok:

- A prompt protocol betartását végül a host modell biztosítja; nincs általános gépi proof, hogy minden hook és HALT szabály lefutott.
- A team/user TOML executable prompt surface: activation stepet, persistent file-globot, menüt és completion actiont injektálhat.
- Külső modulnál `npm install` lifecycle scriptet futtathat, 120 másodperces timeouttal; a failure viszont catch-and-continue, így a clone sikeres lehet hiányos/stale dependency állapot mellett (`770d425:tools/installer/modules/external-manager.js:L448-L502`).
- Build és Build Auto local commitot készít, Build Auto pedig revertet is végez; ez szigorú approval policy mellett wrapper/customization nélkül nem elfogadható default.
- A Windows quality surface piros: CRLF-, POSIX path-, permission- és locale-assumption hibák vannak; továbbá a strict file-reference validator egy generated-example targetet brokenként talál.

## 3. Repository and component inventory

### Teljes census és coverage

**[Runtime]** `git ls-files` alapján 618 tracked path, összesen 7 384 940 byte. Mind a 618 fájl SHA-256 olvasása sikeres. A `work/inventory/bmad-method-files.csv` 618 sora nulla blank category, nulla blank gear marker és nulla hash error; a `work/inventory/bmad-method-gears.csv` 608 gear-sora mind `analyzed`. Pending coverage: **0**. A különbözet 10 nyilvántartott non-gear/binary vagy hasonló path, nem kihagyott állomány.

Pontosan:

| Komponens | Mennyiség és állapot |
|---|---|
| Canonical skill | 48: 34 BMM + 14 core |
| BMM persona | 5 |
| Aktív BMM planning skill | 10 |
| Aktív BMM shipping skill | 7 |
| BMM v6 compatibility entry | 12 |
| Aktív core skill | 8 |
| Core compatibility shim | 6 |
| Local Claude marketplace package | 6 |
| Official external module registry entry | 7, ebből 1 deprecated |
| Host profile | 45; 45 project target, 42 global target, 21 unique project target |
| Tracked Markdown | 403 |
| Tracked JavaScript | 56 |
| Tracked MJS | 9 |
| Tracked Python | 31 |
| Tracked TOML/YAML/JSON | 36 / 20 / 11 |
| `test/` | 24 tracked path; 11 top-level file, ebből 10 executable JS/MJS + README |
| Colocated Python test | 15 |

A nyelvi extension countok nem „runtime script” countok: tesztet, build toolingot és website-kódot is tartalmaznak.

### A 48 canonical skill

- Agent: `bmad-agent-analyst`, `bmad-agent-architect`, `bmad-agent-dev`, `bmad-agent-pm`, `bmad-agent-ux-designer`.
- Planning: `bmad-architecture`, `bmad-create-epics-and-stories`, `bmad-document-project`, `bmad-generate-project-context`, `bmad-prd`, `bmad-prfaq`, `bmad-product-brief`, `bmad-spec`, `bmad-sprint-planning`, `bmad-ux`.
- Shipping: `bmad-build`, `bmad-build-auto`, `bmad-checkpoint-preview`, `bmad-code-review`, `bmad-correct-course`, `bmad-qa-generate-e2e-tests`, `bmad-retrospective`.
- BMM compatibility: `bmad-create-architecture`, `bmad-create-prd`, `bmad-create-story`, `bmad-dev-auto`, `bmad-dev-story`, `bmad-domain-research`, `bmad-edit-prd`, `bmad-market-research`, `bmad-quick-dev`, `bmad-sprint-status`, `bmad-technical-research`, `bmad-validate-prd`.
- Core: `bmad-advanced-elicitation`, `bmad-brainstorming`, `bmad-customize`, `bmad-deep-recon`, `bmad-forge-idea`, `bmad-help`, `bmad-party-mode`, `bmad-review`.
- Core compatibility: `bmad-editorial-review`, `bmad-editorial-review-prose`, `bmad-editorial-review-structure`, `bmad-review-adversarial-general`, `bmad-review-edge-case-hunter`, `bmad-review-verification-gap`.

### Plugin- és module-inventory

**[Fact]** `.claude-plugin/marketplace.json` hat csomagot definiál: négy single-skill package (`bmad-brainstorming`, `bmad-party-mode`, `bmad-forge-idea`, `bmad-deep-recon`), egy három-skill `bmad-analysis`, és a lifecycle/agent/shim gyűjtemény `bmad-method-lifecycle` (`770d425:.claude-plugin/marketplace.json:L10-L87`).

**[Fact]** `bmad-modules.yaml` hét külső modult tart nyilván: `bmad-loop`, Test Architecture Enterprise, Builder, Automator, Creative Intelligence Suite, Game Dev Studio, WDS. `bmad-loop` marketplace-plugin + külön setup skill; `bmad-automator` deprecated (`770d425:bmad-modules.yaml:L37-L128`). A local plugin package és az external module két eltérő fogalom.

### Host-mátrix

A 45 kód: `adal`, `amp`, `antigravity`, `antigravity-cli`, `auggie`, `bob`, `claude-code`, `cline`, `codex`, `codewhale`, `codebuddy`, `command-code`, `cortex`, `crush`, `cursor`, `droid`, `firebender`, `gemini`, `github-copilot`, `goose`, `hermes`, `iflow`, `junie`, `kilo`, `kimi-code`, `kiro`, `kode`, `mistral-vibe`, `mux`, `neovate`, `ona`, `openclaw`, `opencode`, `openhands`, `pi`, `pochi`, `qoder`, `qwen`, `replit`, `roo`, `rovo-dev`, `trae`, `warp`, `windsurf`, `zencoder` (`770d425:tools/installer/ide/platform-codes.yaml:L15-L343`).

## 4. Architecture and layer model

### Funkcionális rétegek

1. **Authored source.** `src/core-skills`, `src/bmm-skills`: `SKILL.md`, step, prompt, template, catalog, `customize.toml`, helyi script.
2. **Distribution/compiler.** CLI + installer: module/host selection, shared script install, config/manifest/catalog generation, platform dispatch (`770d425:tools/installer/core/installer.js:L217-L371`).
3. **Host adapter.** A canonical skill directoryt az adott unique targetbe másolja; shared targetnél deduplikál; csak konfigurált hostnál generál auxiliary pointert (`770d425:tools/installer/ide/_config-driven.js:L218-L405`).
4. **Rendered execution.** Build entry `uv run --no-cache ... render_skill.py`; hiba esetén HALT, mutable source közvetlen futtatása tiltott (`770d425:src/bmm-skills/ship/bmad-build/SKILL.md:L7-L13`).
5. **Artifact/state.** Spec, sprint status, memlog, review trail, research output, generated snapshot normál project file.

### Global / Project / Session / Local

| Layer | Owner/surface | Persistence és precedence |
|---|---|---|
| Global | `global_target_dir`, user `.bmad/cache`, host/plugin registry | User/machine szintű install és cache. 42 profile deklarálja; live global install nem futott. |
| Project | `_bmad/config.toml`, module YAML, installed skill, `_bmad/scripts`, `_bmad/custom`, `_bmad/render`, manifest, spec/story/sprint status, `.memlog.md`, output | Durable team/install/work state. A memlog explicit módon sessionökön át él (`770d425:src/scripts/memlog.py:L5-L12`). |
| Session | aktív persona, resolved prompt context, current dispatch, transient workflow variable, model/subagent context | Ephemeral execution; project artifactot olvas/módosít, de nem ez a persistence owner. |
| Local | `_bmad/config.user.toml`, `_bmad/custom/config.user.toml`, `_bmad/custom/<skill>.user.toml` | Logikai personal ownership és legmagasabb precedence; fizikailag project file. A custom user file gitignored, az installer-owned user config regenerálódik (`770d425:docs/how-to/customize-bmad.md:L292-L318`). |

Central precedence, alacsonytól magasig: `_bmad/config.toml` → `_bmad/config.user.toml` → `_bmad/custom/config.toml` → `_bmad/custom/config.user.toml`. Per-skill: shipped `customize.toml` → team override → user override. Table recursive merge; minden elemben közös `code` vagy `id` esetén keyed replacement/append; más array append; scalar override (`770d425:src/scripts/config_utils.py:L37-L118`).

## 5. Events, formulas, state transitions, and loops

### Activation event sequence

Mind az öt persona ugyanazt a protokollt használja: customization resolve → prepend activation steps → persona adopt → persistent facts load → BMM config load → greeting → append steps → direct intent dispatch vagy numbered menu és wait. A persona/icon/language/facts dismissalig aktív (`770d425:src/bmm-skills/agents/bmad-agent-analyst/SKILL.md:L19-L76` és a négy sibling agent azonos tartományai).

**[Inference]** Ez prompt-event model, nem process event emitter. Portábilis, de enforcementje a host compliance-étől függ.

### Exact Build state

Interactive Build persisted status:

```text
draft -> ready-for-dev -> in-progress -> in-review -> done
```

Build Auto ugyanez + `blocked` (`770d425:src/bmm-skills/ship/bmad-build/spec-template.md:L1-L7`; `770d425:src/bmm-skills/ship/bmad-build-auto/spec-template.md:L1-L10`). A “planning”, “implementation” és “Ready for Development” fázis/gate, nem frontmatter value.

A ready gate képlete nem számszerű score, hanem conjunction: actionable file/action + dependency order + Given/When/Then AC + outermost-surface observability + no placeholder + sufficient + coherent (`770d425:src/bmm-skills/ship/bmad-build-auto/workflow.md:L57-L67`).

Review triage sorrend:

1. `intent_gap`: patch mentés, code revert, `blocked`.
2. `bad_spec`: frozen intent megőrzés, code revert, spec correction, reimplementation.
3. `patch`: autofix + verification rerun.
4. `defer`/`reject`: auditált disposition.

`review_loop_iteration > 5` esetén non-convergence `blocked`; ez az explicit loop bound (`770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L59-L62`). Follow-up review formula: `true`, ha patched high > 0, vagy `3 × medium + low >= 5` (`770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L81-L84`).

### Sprint/retrospective

Story status: `backlog`, `ready-for-dev`, `in-progress`, `review`, `done`; epic: `backlog`, `in-progress`, `done`; retro: `optional`, `done`; legacy `drafted -> ready-for-dev`, `contexted -> in-progress`; default staleness 7 nap (`770d425:src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py:L59-L70`).

Retro verdict: `accepted`, `accepted-with-open-items`, `rejected`; action: `open`, `in-progress`, `done` (`770d425:src/bmm-skills/ship/bmad-retrospective/scripts/sprint_status.py:L33-L37`). Mindkét writer atomic replace-et és validation/restore protokollt céloz; a Windows failure-path tesztek korlátait a 11. és 13. szakasz rögzíti.

### Memlog

A body entry append-only és chronological; nincs entry edit/delete, lifecycle status csak appendelt event lehet. A `set` command viszont descriptive frontmatter fieldet módosíthat (`770d425:src/scripts/memlog.py:L18-L35`; `770d425:src/scripts/memlog.py:L61-L67`). Ezért nem az egész file immutable.

## 6. Agent and sub-agent model

Az agent a hostban aktivált persona-skill. A subagent bounded handoffot kap, majd a parent a canonical spec/diff ellen reconciliál. Nincs hidden shared-memory garancia.

- Build: implementation subagent + parallel review layers; human checkpoint kötelező.
- Build Auto: subagent használat mandatory; minden call synchronous. A “parallel” több blocking call együtt, detached/background tiltott, mert nincs resumable background event loop (`770d425:src/bmm-skills/ship/bmad-build-auto/workflow.md:L51-L55`).
- Code Review: applicable review-lensek lehetőleg külön subagentként.
- Party Mode: persona-alapú group discussion subagent/agent-team/auto módban.
- Document Project és Deep Recon: large-context scan/research fan-out, majd parent synthesis.

**[Fact]** Ha Build Auto nem tud subagentet indítani, `blocked: no subagents`. Interactive one-shot review subagent hiányában prompt file-okat ír és human handoffot kér, nem imitálja csöndben a parallel reviewt (`770d425:src/bmm-skills/ship/bmad-build/step-oneshot.md:L18-L39`).

**[Inference]** A bounded packet + canonical artifact erősebb auditmodellt ad, mint a teljes chat-context implicit megosztása, de a classification és synthesis továbbra is model judgment.

## 7. Roles, personas, skills, plugins, hooks, and automation

### Persona-tábla

| Persona | Role | Aktuális menu |
|---|---|---|
| Mary | Business Analyst | BP, MR, DR, TR, TS, CR, UV, CB, WB, DP |
| John | Product Manager | PRD, create epics/stories, implementation readiness/sprint, correct course |
| Winston | Architect | architecture, implementation readiness |
| Amelia | Developer | Build, QA E2E, Code Review, Sprint Planning, Retrospective |
| Sally | UX Designer | UX design |

A fixed név/title a `SKILL.md` identitás része; `customize.toml` overlay módosíthat role, identity, communication style, principles, activation step, persistent fact, menu és completion fieldet. A menu skill ID-t vagy literal promptot dispatchol. A `file:` persistent fact project globot tölthet be.

### Core képességek

- `bmad-help`: installed catalog routing.
- `bmad-advanced-elicitation`: iterative refinement, runtime szerint 71 method / 12 category.
- `bmad-review`: adversarial, edge-case, verification-gap, structure, prose lens; customizationnel bővíthető/cserélhető (`770d425:docs/reference/core-tools.md:L82-L98`).
- `bmad-brainstorming`: 108 method / 13 category.
- `bmad-deep-recon`: market/domain/technical recon konszolidáció.
- `bmad-forge-idea`: idea pressure test.
- `bmad-party-mode`: multi-persona discussion.
- `bmad-customize`: guided per-skill override authoring.

### Hooks és automation

Két külön mechanizmus:

1. Prompt hook: `activation_steps_prepend`, `activation_steps_append`, `on_complete`; a host modell hajtja végre.
2. Development/install hook: Husky `prepare`, generated pointers, module post-install instructions/scripts (`770d425:package.json:L42-L43`).

Nincs always-on daemon, message bus, scheduler, adatbázis vagy beépített remote telemetry. Automation = host-instruction protocol + CLI/file writer.

## 8. Workflow composition and reference graph

### Fő gráf

```text
brainstorm / deep recon / forge / existing-project scan
                         |
                         v
product brief / PRFAQ -> PRD / spec -> UX / architecture
                                      |
                         epics/stories + project-context
                                      |
                              sprint planning
                                      |
                  +-------------------+------------------+
                  |                                      |
          interactive Build                       Build Auto
     one-shot | plan-code-review          ready-for-dev halt | loop
     done/commit/no-VCS done                  done | blocked
                  |                                      |
                  +------------ sprint state ------------+
                            /         |          \
                Checkpoint Preview  QA E2E  Code Review
                                      |
                         correct course / retrospective
```

Checkpoint Preview, QA E2E és ad hoc Code Review side-entry workflow, nem csak downstream doboz (`770d425:src/bmm-skills/ship/bmad-checkpoint-preview/SKILL.md:L1-L10`; `770d425:src/bmm-skills/ship/bmad-qa-generate-e2e-tests/SKILL.md:L1-L10`; `770d425:src/bmm-skills/ship/bmad-code-review/SKILL.md:L1-L11`).

One-shot csak zero blast radius + clear intent + no architectural decision esetén; `done` trace, optional local commit, never auto-push (`770d425:src/bmm-skills/ship/bmad-build/step-01-clarify-and-route.md:L93-L105`; `770d425:src/bmm-skills/ship/bmad-build/step-oneshot.md:L41-L55`). Build Auto `Halt after planning` esetén `ready-for-dev`; sikeres no-VCS és VCS ág `done`; minden blokk terminal `blocked` resultot ír (`770d425:src/bmm-skills/ship/bmad-build-auto/step-02-plan.md:L14-L23`; `770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L89-L96`). Ezek prompt-enforced terminalok; a renderer csak a végrehajtandó snapshotot publikálja.

### Compatibility graph

- `bmad-create-architecture -> bmad-architecture`
- `bmad-create-prd`, `bmad-edit-prd`, `bmad-validate-prd -> bmad-prd`
- market/domain/technical research shimek `-> bmad-deep-recon`
- `bmad-sprint-status -> bmad-sprint-planning`
- `bmad-quick-dev -> bmad-build`; `bmad-dev-auto -> bmad-build-auto`
- hat editorial/review shim `-> bmad-review`
- `bmad-create-story` és `bmad-dev-story` self-contained deprecated legacy workflow, nem thin forwarder.

### Reference closure

**[Fact]** A renderer `[[bmad-snapshot:...]]` targetot csak declared source setből enged, egy opaque passban (`770d425:src/scripts/render_skill.py:L30-L33`; `770d425:src/scripts/render_skill.py:L232-L267`). 39 occurrence / 10 unique snapshot target mind feloldódott. Docs link validator: 168 file, 0 issue.

**[Runtime]** Az official `node tools/validate-file-refs.js --strict` dependency-backed clone-ban 202 source file-t és 188 reference-et ellenőrzött: 187 resolved, 1 broken, 0 absolute leak, exit 1. A broken `./architecture-server.md` a Document Project generated-document example objektumában áll, amelynek `line_text` mezője ugyanazt “To be generated” linkként mutatja (`770d425:src/bmm-skills/plan/bmad-document-project/workflows/full-scan-instructions.md:L849-L858`). Nem hiányzó shipped executable, de static targetként ténylegesen fail. A validator project-root/shorthand, relative, `exec`, `invoke-task`, step metadata, Load, CSV workflow-file és absolute leak osztályokat kezel, runtime mustache/config reference-et explicit deferál (`770d425:tools/validate-file-refs.js:L1-L26`; `770d425:tools/validate-file-refs.js:L41-L70`; `770d425:tools/validate-file-refs.js:L182-L327`).

## 9. Script-level execution paths

### Install és a kétfázisú `--set`

```text
bmad-method install
  -> bmad-cli.js -> commands/install.js -> UI
     -> parse/filter --set
     -> seed setOverrides.core BEFORE config collection
        -> output_folder/module path/config snapshot dependency
  -> Installer.install()
     -> resolve external/custom module/channel
     -> install shared scripts + selected module source
     -> generate central/module config + manifests
     -> post-write applySetOverrides
        -> core and selected non-core TOML patch
     -> platform batch handler
        -> one native skill write per unique target
        -> optional commands_target_dir pointers
        -> ownership-aware cleanup
```

Az early seed és a late patch egyszerre létezik. Az early core seed azért szükséges, mert a module artifact path és snapshotolt core config már collection alatt függ `output_folder` értékétől (`770d425:tools/installer/ui.js:L780-L835`). A late phase a frissen írt team/user TOML-t patch-eli core és non-core értékekkel (`770d425:tools/installer/core/installer.js:L295-L342`).

### Build renderer

```text
Build SKILL
  -> uv run --no-cache _bmad/scripts/render_skill.py
  -> Markdown source discovery
  -> four central config layers
  -> three customization layers, ha token kéri
  -> source-authored token resolution, one opaque pass
  -> hash(project root, renderer, values, sources)
  -> staging write + manifest + atomic rename/verify
  -> absolute generated workflow.md dispatch
  -> host reads one step at a time
```

Existing generation esetén manifest equality, exact file set és minden output hash kötelező; collision/corruption HALT (`770d425:src/scripts/render_skill.py:L270-L319`). A project absolute path az identity része, ezért ugyanaz a project más checkout-pathon szándékosan más generation.

### State helper call paths

- `resolve_config.py`: merged central config vagy dotted key.
- `resolve_customization.py`: project root discovery + per-skill three-layer merge.
- `memlog.py`: `init`, body `append`, descriptive-frontmatter `set`, atomic write.
- `sprint_plan.py`: generate/validate/update/recommend, JSON error, atomic restore.
- `git_evidence.py`: local `git log --numstat` parse, merge handling.
- `sprint_status.py`: retro verdict/action update, YAML comment preservation, atomic restore.
- Architecture linter: AD ID/field/placeholder/stack pinning.
- Catalog CLI-k: method/category selection, slug, staleness, word metrics.

## 10. Installation, update, migration, recovery, and removal

### Install/update

Existing install snapshot készül; a custom/modified anyag ideiglenes `_bmad-custom-backup-temp` és `_bmad-modified-backup-temp` mappába kerül (`770d425:tools/installer/core/installer.js:L590-L657`). A shared runtime script surface frissül, a custom/render surface védett (`770d425:tools/installer/core/installer.js:L660-L696`). A platform handler a shared target első sikeres writerét követi; ha az első writer elbukik, a következő átveszi az írást. Auxiliary pointer külön targetbe továbbra is elkészülhet deduplikált skill write mellett (`770d425:tools/installer/ide/_config-driven.js:L218-L257`).

Generated pointer update csak generator-shaped file-ra történik; unreadable vagy hand-edited file user-ownedként megmarad (`770d425:tools/installer/ide/_config-driven.js:L357-L401`). Cleanup manifest/removal-list alapján szűk, `bmad-os-*` megőrzéssel (`770d425:tools/installer/ide/_config-driven.js:L499-L570`; `770d425:tools/installer/ide/_config-driven.js:L682-L819`).

### External/custom module

Official source shallow clone/cache, channel stable/next/pin, ref/SHA metadata; custom source local path vagy Git URL/subdir/ref (`770d425:tools/installer/modules/external-manager.js:L191-L436`; `770d425:tools/installer/modules/custom-module-manager.js:L324-L547`). A Git subprocess környezetéből eltávolítják a repository-retargeting változókat; a komment egy korábbi saját-repository hard-reset veszélyt dokumentál (`770d425:tools/installer/modules/git-env.js:L4-L25`).

Dependency install parancs:

```text
npm install --omit=dev --no-audit --no-fund --no-progress --legacy-peer-deps
```

Timeout 120 s, lifecycle scripts nincsenek tiltva. A failure catch után a manager továbbadja a cache pathot; silent módban a detailed warning sincs (`770d425:tools/installer/modules/external-manager.js:L448-L502`; `770d425:tools/installer/modules/custom-module-manager.js:L556-L575`). Nincs rollback vagy dependency-ready flag.

### Migration/recovery/removal

Migration: alias + removal metadata + v6 shim + custom/config preservation. Research → Deep Recon; editorial/review → Review; Quick Dev → Build; Sprint Status → Sprint Planning.

Recovery: renderer staging/atomic publish/existing hash verification; sprint/retro original-byte restore (`770d425:src/scripts/render_skill.py:L270-L319`; `770d425:src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py:L329-L461`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/sprint_status.py:L559-L653`). Uninstall selective removal/output preservationt kínál, de destructive flow; nem futott.

## 11. Testing, observability, security, and failure modes

### Testmodell

`npm run quality` sorrendje: format → lint → Markdown lint → docs build → site URL → install → URL → renderer → retro → sprint → refs → skills → sidebar (`770d425:package.json:L35-L56`). A Python tesztek filesystem byte/mode, invalid input, boundary és restore eseteket vizsgálnak; az installer teszt shared targetet, pointert, config routingot és migrationt is.

### Security-positive

- `--set` prototype pollution guard: `__proto__`, `prototype`, `constructor` tiltva (`770d425:tools/installer/set-overrides.js:L17-L70`).
- Canonical ID basename/path guard (`770d425:tools/installer/ide/_config-driven.js:L323-L329`).
- Snapshot declared-source guard + opaque single pass.
- Existing generation full hash/file-set verification.
- Git env sanitization.
- Atomic state writer és explicit parse failure.

### Trust boundary és failure semantics

1. **Prompt injection/config execution.** TOML hook/menu/fact/glob executable instruction. Treat as code.
2. **External supply chain.** Clone + npm lifecycle, signature/sandbox nélkül.
3. **Partial dependency readiness.** Install failure után continue és cache return; silent detail suppression.
4. **VCS mutation.** Interactive Build és Auto commit; Auto reviewág revertet használ.
5. **Silent cleanup catch.** Adatmegőrző, de stale partial migrationt elfedhet (`770d425:tools/installer/ide/_config-driven.js:L590-L659`; `770d425:tools/installer/ide/_config-driven.js:L698-L746`).
6. **Context exposure.** Broad `file:` glob secret/PII-t vihet promptba; nincs central pre-ingestion secret scanner.

### Observability

Van explicit `HALT` + status/blocking condition, manifest/hash, triage log, spec change log, Auto Run Result, sprint YAML, memlog és JSON error. Build Auto unresolved spec esetén is result file-t ír (`770d425:src/bmm-skills/ship/bmad-build-auto/workflow.md:L7-L43`). Nincs viszont machine event, amely minden prompt hook végrehajtását bizonyítaná, és silent install/cleanup branchben részlet veszhet el.

## 12. Documentation-code-test drift

1. **Python:** README 3.10+, de `tomllib` és docs/package test 3.11+ (`770d425:README.md:L13-L13`; `770d425:src/scripts/config_utils.py:L5-L5`; `770d425:docs/how-to/customize-bmad.md:L212-L212`; `770d425:package.json:L49-L53`).
2. **Core count:** docs „seven”, de source/table szerint 8 aktív core skill (`770d425:docs/reference/core-tools.md:L8-L32`).
3. **Mary menu:** docs kihagyja `TS`, `CR`, `UV` triggerét (`770d425:docs/reference/agents.md:L18-L20`; `770d425:src/bmm-skills/agents/bmad-agent-analyst/customize.toml:L56-L105`). Több fordítás régebbi ID-ket tartalmaz.
4. **Workflow map:** Build Auto csak prózában; Checkpoint Preview és QA E2E nincs teljesen reprezentálva (`770d425:docs/reference/workflow-map.md:L84-L101`).
5. **Upgrade terminology:** néhol régi config/agent path és pre-consolidation név.
6. **Reference validator vs example:** generated future document link strict broken targetként jelenik meg.
7. **Windows test drift:** LF-only frontmatter/fence regex, Unix-only absolute path, POSIX permission/mode és English error-text assumption.

Docs hyperlink állapot ettől függetlenül zöld: 168 file, 0 issue.

## 13. Runtime experiments

### Dependency-backed setup

```powershell
git clone --no-local --no-checkout "C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\repos\bmad-method" "C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\runtime\bmad-method-validation-770d425"
git -C "C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\runtime\bmad-method-validation-770d425" checkout --detach 770d4259853b9600680745bb2c710bee82604cb4
npm ci --ignore-scripts --no-audit --no-fund
```

**[Runtime]** Exit 0/0/0; 848 npm package; runtime clone clean.

### Minden Python test file

Az alábbi pontos command 13 file-t futtatott:

```powershell
python -m pytest -q -p no:cacheprovider src/bmm-skills/plan/bmad-architecture/scripts/tests/test_lint_spine.py src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py src/core-skills/bmad-advanced-elicitation/scripts/tests/test_pick_methods.py src/core-skills/bmad-brainstorming/scripts/tests/test_brain.py src/core-skills/bmad-customize/scripts/tests/test_list_customizable_skills.py src/core-skills/bmad-deep-recon/scripts/tests/test_recon_kit.py src/core-skills/bmad-forge-idea/scripts/tests/test_resolve_personas.py src/core-skills/bmad-party-mode/scripts/tests/test_resolve_party.py src/core-skills/bmad-review/scripts/tests/test_word_metrics.py src/scripts/tests/test_config_utils.py src/scripts/tests/test_memlog.py src/scripts/tests/test_resolve_config.py src/scripts/tests/test_resolve_customization.py
```

**[Runtime]** Exit 1: 202 passed, 4 failed. Mind a négy `test_git_evidence.py`; a POSIX `#!/bin/sh` fake-git PATH overlay Windows alatt nem lett executable, így a real Git futott (`770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L480-L520`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L561-L605`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L660-L668`). Az eredmény tartalmazza az architecture suite 28 passát és Git Evidence 27 pass / 4 fail eredményét.

```powershell
uv run --python 3.11 src/bmm-skills/plan/bmad-sprint-planning/scripts/tests/test_sprint_plan.py
uv run --python 3.11 src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_sprint_status.py
```

**[Runtime]** Sprint Planning exit 0, 37 passed. Sprint Status exit 1, 87 passed/4 failed: Windows chmod/readability, localized WinError (`A hozzáférés megtagadva` vs `denied`) és POSIX mode preservation assumption. Így mind a 15 Python test file futott.

### Node/CLI összefoglaló

| Pontos command | Exit | Eredmény |
|---|---:|---|
| `node tools/validate-file-refs.js --strict` | 1 | 202 file, 188 ref, 1 broken generated-example, 0 leak |
| `node tools/installer/bmad-cli.js install --list-tools` | 0 | 45 profile list, install nélkül |
| `npm run test:install` | 1 | 427 pass, 2 CRLF fence fail |
| `npm run test:channels` | 0 | 83 pass |
| `npm run test:urls` | 0 | 68 pass |
| `npm run test:renderer` | 1 | Python 10/10; Node 20/24; 3 path/newline issue + 1 unresolved long-basename diagnostic |
| `node test/test-rehype-plugins.mjs` | 1 | 82 pass, 25 Windows path fail |
| `node tools/validate-skills.js --strict` | 1 | 48/48 rejected, 144 false finding CRLF delimiter miatt (`770d425:tools/validate-skills.js:L68-L79`) |
| `node test/test-validate-skills.js` | 1 | 2/3 |
| `node tools/validate-doc-links.js` | 0 | 168 file, 0 issue |
| `node test/test-template-sync.js` | 0 | pass |
| `node test/test-site-url.mjs` | 0 | 8 pass |
| `npm run quality` | 1 | első stage: Prettier 95 CRLF formatting finding, többi stage nem futott |

Static sweep: 65 JS/MJS `node --check` pass; 31 Python AST pass; 36 TOML/20 YAML/11 JSON parse pass; 618 hash success; 608/608 gear analyzed.

```powershell
python src/core-skills/bmad-brainstorming/scripts/brain.py --json categories
python src/core-skills/bmad-advanced-elicitation/scripts/pick_methods.py --json categories
python src/core-skills/bmad-deep-recon/scripts/recon_kit.py slug --type technical --date 2026-08-02 'A test BMAD'
python src/core-skills/bmad-review/scripts/word_metrics.py README.md
```

Exit 0: 13/108; 12/71; `technical-a-test-bmad-2026-08-02`; 602 word. A korábbi hibás `--title` kísérlet exit 2 operator error volt; a fenti a reprodukálható command.

## 14. Reusable patterns

### Content-addressed workflow snapshot

- **Forrás:** `src/scripts/render_skill.py`.
- **Prerequisite:** deterministic text input, Python 3.11/uv, project root.
- **Adaptáció:** declared token grammar → one opaque pass → input/source/renderer hash → staging → atomic publish → existing verification.
- **Tradeoff:** reproducibility és inspectability vs path-bound cache, disk growth, debug complexity.
- **Provenance/license:** MIT; substantial copy esetén notice megtartása (`770d425:LICENSE:L1-L23`).
- **Ajánlás:** pattern-level clean-room port praktikus, de nem jogi követelmény.

### Structural layered customization

- **Forrás:** `config_utils.py`, resolverek, `customize.toml`.
- **Prerequisite:** explicit schema/ownership.
- **Adaptáció:** strict parse, missing-only optional, recursive/keyed merge, debug resolver CLI.
- **Tradeoff:** sparse upgrade-safe override vs array semantics és prompt execution risk.
- **License:** MIT.
- **Ajánlás:** clean-room implementation + negative precedence/type tests.

### Ownership-aware multi-host installer

- **Forrás:** `platform-codes.yaml`, `_config-driven.js`, manifest generator.
- **Prerequisite:** canonical IDs, target registry, ownership manifest.
- **Adaptáció:** native common skills, unique-target dedup, optional pointer, owned-only cleanup.
- **Tradeoff:** széles host support vs compatibility matrix és stale-file tolerance.
- **License:** MIT; host pathot mindig vendor-primary docs alapján újra kell ellenőrizni.

### Review finding control-flow algebra

- **Forrás:** Build/Build Auto review step és reviewer prompt pack.
- **Prerequisite:** frozen intent, canonical spec, baseline diff, verification command.
- **Adaptáció:** `intent_gap/bad_spec/patch/defer/reject`, cascading root-cause order, bounded loop, audit log.
- **Tradeoff:** symptom patching ellen erős, de classification model judgment; revert/commit approval kell.
- **License:** MIT; clean-room rephrasing ajánlott.

### Append-only body memory

- **Forrás:** `memlog.py`.
- **Prerequisite:** durable filesystem.
- **Adaptáció:** body event append-only, correction új event, descriptive frontmatter külön mutable, atomic write.
- **Tradeoff:** audit/resume erős; log nő, compaction külön artifactban kell.
- **License:** MIT.

### Atomic human-readable state writer

- **Forrás:** renderer, sprint planner, retro updater.
- **Prerequisite:** same-volume atomic rename, validation schema.
- **Adaptáció:** original bytes/mode → parse → temp/fsync → replace → validate → restore.
- **Tradeoff:** crash safety vs symlink/permission/network FS portability.
- **License:** MIT; serializer clean-room adaptáció ajánlott.

### Sanitized scoped Git subprocess

- **Forrás:** `git-env.js` + module manager.
- **Prerequisite:** explicit cwd és cache-bound target.
- **Adaptáció:** env clone, `GIT_*` retargeting removal, path validation, incident regression test.
- **Tradeoff:** destructive cross-repo bug ellen véd, de caller customizationt eltávolíthat.
- **License:** MIT; közvetlen reuse notice-szal vagy clean-room port.

### Jogi minősítés

A MIT közvetlen reuse-t, modificationt és redistributiont enged a notice megtartásával (`770d425:LICENSE:L1-L23`). A BMad nevek/branding külön trademark; külön néven redisztribúció és truthful compatibility reference megengedett (`770d425:TRADEMARK.md:L16-L25`). A clean-room döntés engineering/coupling/branding-risk ajánlás, nem licenckövetelmény.

## 15. Weaknesses and anti-patterns

1. **Prompt-as-runtime without machine proof:** a Markdown MUST/HALT csak host compliance mellett valósul meg.
2. **Default local commit/revert:** approval-heavy környezetben veszélyes alapértelmezés.
3. **CRLF-blind validation:** skill validator, installer fence assertion és renderer fence teszt Windows alatt hamis hibát ad.
4. **Unix path in web/renderer tests:** Rehype 25 fail, renderer több reachability fail.
5. **POSIX permission/locale assumptions:** Sprint Status 4 Windows fail.
6. **Broken generated-example reference:** strict gate 1 fail; exemption vagy non-resolvable example syntax kellene.
7. **Catch-and-continue dependency install:** partial module readiness, silent-mode diagnosztika-vesztés.
8. **Silent cleanup catches:** data-preserving, de incomplete migration kevéssé látható.
9. **Prompt customization attack surface:** hooks és broad globs secret/context exfiltrationt okozhatnak.
10. **Append-unless-keyed array merge:** mixed array duplicate instructiont hozhat.
11. **Absolute path in snapshot identity:** biztonságos izoláció, de cache nem hordozható.
12. **45-profile maintenance burden:** config-date nem bizonyít live host conformance-ot.
13. **Docs/shim duality:** compatibility jó, de canonical entry bizonytalan maradhat.
14. **Root prerequisite drift:** README 3.10 vs tényleges 3.11 direct runtime.
15. **No signature/sandbox for external module install.**
16. **No pre-ingestion secret scanner for persistent facts.**

Nem anti-pattern önmagában a clean-room helyett direct reuse: MIT szerint megengedett. Az anti-pattern a brand összekeverése vagy notice nélküli substantial copy.

## 16. Evidence index

Minden citation commitja `770d4259853b9600680745bb2c710bee82604cb4`.

| Téma | Elsődleges evidence |
|---|---|
| Package/CLI/quality | `770d425:package.json:L3-L56` |
| License/trademark | `770d425:LICENSE:L1-L30`; `770d425:TRADEMARK.md:L1-L50` |
| 48-skill packaging | repo-relative `src/**/SKILL.md`; `770d425:.claude-plugin/marketplace.json:L10-L87` |
| External registry | `770d425:bmad-modules.yaml:L1-L128` |
| 45 host profile | `770d425:tools/installer/ide/platform-codes.yaml:L15-L343` |
| Shared-target/pointer | `770d425:tools/installer/ide/_config-driven.js:L218-L405` |
| Cleanup/ownership | `770d425:tools/installer/ide/_config-driven.js:L499-L819` |
| Config layering | `770d425:src/scripts/config_utils.py:L17-L118` |
| Renderer | `770d425:src/scripts/render_skill.py:L232-L380` |
| Memlog | `770d425:src/scripts/memlog.py:L5-L35`; `770d425:src/scripts/memlog.py:L61-L67`; `770d425:src/scripts/memlog.py:L110-L129` |
| Agent activation | mind az öt `src/bmm-skills/agents/bmad-agent-*/SKILL.md:L19-L76` |
| Build state/branch | `770d425:src/bmm-skills/ship/bmad-build/spec-template.md:L1-L7`; `770d425:src/bmm-skills/ship/bmad-build/step-01-clarify-and-route.md:L93-L105`; `770d425:src/bmm-skills/ship/bmad-build/step-oneshot.md:L41-L55` |
| Build Auto state/terminal | `770d425:src/bmm-skills/ship/bmad-build-auto/spec-template.md:L1-L10`; `770d425:src/bmm-skills/ship/bmad-build-auto/step-02-plan.md:L14-L23`; `770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L59-L96` |
| Sprint/retro state | `770d425:src/bmm-skills/plan/bmad-sprint-planning/scripts/sprint_plan.py:L59-L70`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/sprint_status.py:L33-L37` |
| Two-phase `--set` | `770d425:tools/installer/ui.js:L780-L835`; `770d425:tools/installer/core/installer.js:L295-L342` |
| Backup/recovery | `770d425:tools/installer/core/installer.js:L590-L696`; `770d425:src/scripts/render_skill.py:L270-L319` |
| Module dependency failure | `770d425:tools/installer/modules/external-manager.js:L448-L502`; `770d425:tools/installer/modules/custom-module-manager.js:L556-L575` |
| Git env safety | `770d425:tools/installer/modules/git-env.js:L1-L44` |
| Reference validator | `770d425:tools/validate-file-refs.js:L1-L70`; `770d425:tools/validate-file-refs.js:L182-L327` |
| Broken generated example | `770d425:src/bmm-skills/plan/bmad-document-project/workflows/full-scan-instructions.md:L849-L858` |
| Skill-validator CRLF | `770d425:tools/validate-skills.js:L68-L79` |
| Renderer-test path/line ending | `770d425:test/test-build-auto-renderer.js:L193-L194`; `770d425:test/test-build-auto-renderer.js:L437-L442`; `770d425:test/test-build-auto-renderer.js:L505-L506` |
| Git fake-shim tests | `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L480-L520`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L561-L605`; `770d425:src/bmm-skills/ship/bmad-retrospective/scripts/tests/test_git_evidence.py:L660-L668` |
| Docs drift | `770d425:README.md:L13-L13`; `770d425:docs/how-to/customize-bmad.md:L212-L212`; `770d425:docs/reference/core-tools.md:L8-L32`; `770d425:docs/reference/agents.md:L18-L20`; `770d425:docs/reference/workflow-map.md:L84-L101` |

**[Inference]** A legjobb újrahasznosítási cél nem a branded persona-szöveg, hanem az invariant: strict layered config, immutable render packet, ownership manifest, atomic writer, bounded root-cause review loop és sanitized subprocess. Ezeket a célrendszer approval-, portability- és supply-chain szabályaival kell újratervezni.

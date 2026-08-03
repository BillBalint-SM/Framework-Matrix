# open-gsd/gsd-core — részletes magyar kutatási dosszié

## 1. Snapshot and provenance

| Mező | Rögzített érték |
|---|---|
| Repository | `open-gsd/gsd-core` |
| Branch | `next` |
| Commit | `33985c11a9f0a27443f8b8fb114b2122d653cd78` |
| Package | `@opengsd/gsd-core` 1.9.1 |
| Runtime floor | Node.js `>=22.0.0`, npm `>=10.0.0` |
| Licenc | MIT, Copyright 2026 Open GSD |
| Elemzési checkout | `work/repos/open-gsd-gsd-core` |
| Build-materialized runtime clone | `work/runtime/open-gsd-gsd-core-test` |
| Forrásmódosítás/publikálás | nem történt |

Jelölések:

- **[Fact]**: a pinnelt repository-ból közvetlenül igazolható tény;
- **[Runtime]**: megőrzött paranccsal, stdout/stderr-rel és exit kóddal igazolt helyi futtatás;
- **[Inference]**: több forrástényből levont, külön jelölt következtetés;
- **[Author claim]**: a repository dokumentációjának állítása, amely önmagában nem független bizonyítás;
- **[Limit]**: nem vizsgált vagy nem reprodukálható állapot.

**[Fact]** A package-nevet, a négy bin belépési pontot, a publikációs allowlistet, a Node/npm minimumot és a quality scripteket a pinnelt `package.json` rögzíti [33985c1:package.json:L1-L60] [33985c1:package.json:L82-L122]. **[Fact]** Az MIT licenc engedi a használatot, módosítást és terjesztést, de a copyright- és permission notice megtartását előírja [33985c1:LICENSE:L1-L21].

**[Runtime]** A végső preflight a `next` branchet, az exact `33985c11…` HEAD-et, tiszta tracked worktree-t és `origin/next` upstreamet mutatta. A teljes kutatás ezt az immutable pint használja; a rövid citation-forma `[33985c1:path:Lx-Ly]` mindig erre a snapshotra mutat.

## 2. Executive summary

**[Fact]** A GSD Core nem egyetlen autonóm agent, hanem prompt- és artifact-alapú szoftverszállítási operációs rendszer. A runtime command/skill egy canonical command adaptert indít, az workflow-t tölt, az workflow specialist agenteket és determinisztikus CLI-műveleteket koordinál, az eredmény pedig projektlokális `.planning/` state és implementációs artifact [33985c1:docs/ARCHITECTURE.md:L22-L65] [33985c1:docs/ARCHITECTURE.md:L110-L143].

**[Fact]** Négy legerősebb mechanizmusa: friss kontextusú role delegation tartós fájlstate-tel; egy canonical Claude-szerű authoring dialektus sok host-projekcióval; producer/checker és adversarial szerepek bounded loopokban; valamint generatorokkal ellenőrzött registry-, contract- és projection-surface [33985c1:docs/ARCHITECTURE.md:L70-L105] [33985c1:docs/ARCHITECTURE.md:L145-L204].

**[Runtime]** A 2 730 tracked fájl és a supplied inventory 2 730 sora teljesen egyezett; 2 725 gear candidate mindegyike be lett olvasva és újrahashelve. A gear-set 36 203 101 byte, 773 276 LF byte és három NUL-bearing gear fájl. Ez nem azonos a szintén 2 725 elemszámú, de 36 112 848 byte-os non-NUL halmazzal.

**[Fact + Runtime]** A curated `INVENTORY-MANIFEST.json` hat shippelt, root-szintű family roster, nem teljes repository-manifest [33985c1:docs/INVENTORY.md:L1-L9]. Pristine source checkoutban a 156 build output hiánya miatt a manifest `--check` elvárt exit 1; `npm ci`/`prepare` után a build-materialized clone-ban ugyanaz a generator és a teljes generated-sync zöld. A „manifest current” állítás ezért csak build-materialized checkoutra igaz.

**[Runtime]** A 42 366 soros reference ledger minden extracted tokent terminális osztályba rendez, `unresolved_static_candidate=0`. Egyetlen unique broken repository-owned Markdown edge maradt: `gsd-core/references/reviewer-instances.md` hibásan `gsd-core/docs/adr/...` célt képez a létező root `docs/adr/...` helyett. A terminal class nem általános szemantikai helyességbizonyítás.

**[Inference]** A legfontosabb adaptálható kombináció a canonical prompt IR + descriptor-driven host projection + file-backed pure state transition + content-bound consent + bounded producer/checker loop. A fő kockázatok: a 13,5k soros installer mutációs felülete, fail-open extension/hook hibák, advisory injection detection, prose drift és nem live-certifikált vendor host viselkedés.

## 3. Repository and component inventory

**[Runtime]** A full-tree ledger 2 730/2 730 pathot, 36 309 998 byte-ot és 773 586 LF byte-ot fed le; 0 missing, 0 extra, 0 SHA-256 mismatch és 0 inventory hash error volt. Öt fájl NUL-bearing: három gear test/fixture és két PNG asset. A 2 725 gear candidate teljes, nem mintavételes beolvasása külön coverage-gate volt.

**[Runtime]** A top-level eloszlás teljesen 2 730-ra zár: `tests/` 899, `capabilities/` 539, `.changeset/` 504, `gsd-core/` 376, `docs/` 140, `skills/` 72, `commands/` 71, `src/` 69, `agents/` 34, root 30, `hooks/` 30, `scripts/` 23, `vscode/` 7, `.github/` 6, `assets/` 5, `.claude-plugin/` 2, `.opencode/` 1, `.kilo/` 1 és `.plans/` 1.

**[Fact + Runtime]** A curated machine manifest build-materialized állapotban 34 agentet, 71 commandot, 173 CLI modult, 25 hookot, 97 root reference-t és 91 root Markdown workflow-t sorol. A teljes tracked valóság ettől tágabb: 117 workflow fájl = 91 root Markdown + 1 root launcher snippet + 25 nested fájl; 115 reference = 97 root + 18 nested edge-probe fixture; a `hooks/` 30 tracked fájlja a registry/config/lib supportot is tartalmazza [33985c1:scripts/gen-inventory-manifest.cjs:L24-L72] [33985c1:scripts/gen-inventory-manifest.cjs:L78-L102].

**[Runtime]** A persisted `references.csv` 42 366 sorának syntax-bontása: 28 721 path token, 4 236 Markdown link, 8 745 module import és 664 explicit `@` include. A legnagyobb terminal classok: 17 937 direct source, 6 351 dynamic/template, 5 336 external, 4 291 fixture/history, 2 591 generated projection source, 1 897 runtime artifact, 1 347 package/builtin és 936 canonical install projection. A fennmaradó 1 680 sor explicit kisebb osztályokban van; generic unresolved nincs. Provenance: `work/evidence/open-gsd-gsd-core/references.csv` és `reference-summary.json`.

**[Fact]** A canonical command-prefix 505 tracked text line-on fordul elő, 506 raw match-csel; 71 commandhoz 71 generated `gsd-*` skill-directory tartozik. Minden canonical commandból elért workflow target létezik; 14 command self-contained router/integration, 8 több workflow között választ [33985c1:docs/ARCHITECTURE.md:L123-L131].

## 4. Architecture and layer model

**[Fact]** A fő control flow:

```text
user invocation
  -> host command / skill / palette / plugin
  -> commands/gsd canonical adapter
  -> gsd-core/workflows prompt program
  -> gsd_run / gsd-tools + loop contribution + specialist agent
  -> deterministic check / bounded revision
  -> .planning artifacts, optional code commit, state reconciliation
```

**[Fact]** A commandok vékony argument/delegation adapterek; az workflow-k birtokolják az initet, branchinget, promptokat, checkpointokat és error pathokat; az agentek bounded role cardok; a CLI a determinisztikus state-, install-, routing- és trust-műveleteket központosítja [33985c1:docs/ARCHITECTURE.md:L70-L105] [33985c1:docs/ARCHITECTURE.md:L434-L498].

**[Fact]** A `src/*.cts` a kézzel karbantartott canonical implementation, míg a legtöbb `gsd-core/bin/lib/*.cjs` build output. ADR-457 a dual maintenance helyett build-at-publish modellt választ; ezért source consumernek futtatnia kell a buildet [33985c1:docs/adr/457-generated-cjs-single-source.md:L94-L144]. A 71 canonical commandból a shared converter generálja a 71 skill wrappert [33985c1:scripts/gen-plugin-skills.cjs:L1-L50].

**[Inference]** A Global/Project/Session/Local négyes nem native, négy egyenrangú storage layer. Használható elemzési térkép, ha a scope-különbségeket megtartjuk:

| Réteg | Forrásalapú tartalom | Határ |
|---|---|---|
| Global | runtime home, telepített artifactok, defaults, global capability overlay, consent | user/machine scope; global overlay a project overlay előtt töltődik |
| Project | `.planning/` delivery state, persistent debug/knowledge artifact, `.gsd/capabilities` | versionable project truth; first-party ID/owned stem nem írható felül |
| Session | session-keyed temp active-workstream pointer és host/session cache | csak stabil host session ID mellett; különben project `.planning/active-workstream` fallback |
| Local | host-specifikus local install/config és külön worktree-local execution state | cross-cutting scope family, nem egységes persisted layer |

**[Fact]** Az active workstream precedence `--ws` → `GSD_WORKSTREAM` → stored pointer; session key esetén a pointer projekt-hash-elt temp pathban él, nélküle `.planning/active-workstream` a fallback [33985c1:src/active-workstream-store.cts:L84-L143] [33985c1:src/active-workstream-store.cts:L197-L230] [33985c1:src/active-workstream-store.cts:L301-L332]. A debugger tartós sessionje project artifact, ezért nem a host-session layer része [33985c1:agents/gsd-debugger.md:L791-L838].

## 5. Events, formulas, state transitions, and loops

**[Fact]** A Claude hook graph SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop és FileChanged eseményeket köt update/context/Graphify/checkpoint/guard műveletekhez [33985c1:hooks/hooks.json:L1-L76]. A managed registry 25 shippelhető scriptet deklarál [33985c1:hooks/managed-hooks-registry.cjs:L1-L44]. A context monitor 35% remainingnél warningot, 25%-nál critical jelzést ad, öt tool callos debounce-szal [33985c1:hooks/gsd-context-monitor.js:L11-L29] [33985c1:hooks/gsd-context-monitor.js:L91-L121].

**[Fact]** A generated loop contract 12 canonical pontja és default owner-szerepe:

| Fázis | Loop pointok | Default owner | Artifact edge |
|---|---|---|---|
| Discuss | `discuss:pre`, `discuss:post` | orchestrator | `CONTEXT.md` létrehozás |
| Plan | `plan:pre`, `plan:post` | researcher, planner, checker | contextből plan |
| Execute | `execute:pre`, `execute:wave:pre`, `execute:wave:post`, `execute:post` | executor, verifier | planból summary |
| Verify | `verify:pre`, `verify:post` | orchestrator | summaryból UAT |
| Ship | `ship:pre`, `ship:post` | orchestrator | UAT fogyasztás |

**[Fact]** A resolver validálja a loop pointot, egyetlen config snapshotból overlay-aware registryt és capability activationt számol, majd rendezett step/contribution/gate fragmenteket ad vissza [33985c1:gsd-core/bin/lib/loop-host-contract.cjs:L1-L102] [33985c1:src/loop-resolver.cts:L499-L536]. Discuss, Verify és Ship tehát orchestrator-owned; nem helyes hozzájuk automatikusan researcher/verifier/shipper agent role-t rendelni.

**[Fact]** A `STATE.md` transition algebra 11 zárt intentet kezel: `beginPhase`, `advancePlan`, `completePhase`, `plannedPhase`, `milestoneSwitch`, `milestoneComplete`, `patch`, `update`, `prune`, `sync`, `rebuild` [33985c1:src/state-transition.cts:L324-L415]. A mezőownership schema/external/body-derived/curated/disk-derived, így a preservation ratchet megőrzi a curated adatot, de engedi a disk-derived progress újraszámítását [33985c1:src/state-transition.cts:L75-L142].

**[Fact]** A progress formula `total <= 0 ? 0 : min(100, round(completed / total * 100))`; a lifecycle parser kizárja a 999 backlog phase-t [33985c1:src/phase-lifecycle.cts:L60-L119]. A state writer read-modify-write lockot, live PID checket és lockon belüli scant használ a TOCTOU rés zárására [33985c1:src/state.cts:L169-L286].

## 6. Agent and sub-agent model

**[Fact]** A canonical modell „thin orchestrator + fresh-context specialist”. A workflow kevés saját munkát végez, explicit input/output contracttal agentet indít, majd disk artifactból és structured markerből egyezteti az eredményt [33985c1:docs/ARCHITECTURE.md:L70-L105].

**[Fact]** A roster 34 agentet tartalmaz. A lifecycle mag: `gsd-project-researcher`, `gsd-research-synthesizer`, `gsd-roadmapper`, `gsd-phase-researcher`, `gsd-pattern-mapper`, `gsd-planner`, `gsd-plan-checker`, `gsd-executor`, `gsd-verifier`. A quality/specialist kör: `gsd-code-reviewer`, `gsd-code-fixer`, `gsd-integration-checker`, `gsd-security-auditor`, `gsd-nyquist-auditor`, `gsd-eval-planner`, `gsd-eval-auditor`, `gsd-ui-researcher`, `gsd-ui-checker`, `gsd-ui-auditor`. A documentation/debug/context kör: `gsd-doc-classifier`, `gsd-doc-synthesizer`, `gsd-doc-writer`, `gsd-doc-verifier`, `gsd-debug-session-manager`, `gsd-debugger`, `gsd-codebase-mapper`, `gsd-codebase-analyzer`, `gsd-intel-updater`, `gsd-mempalace-curator`, `gsd-user-profiler`. A domain/framework kör: `gsd-ai-integration-researcher`, `gsd-domain-researcher`, `gsd-framework-selector`, `gsd-ai-integration-planner` [33985c1:docs/INVENTORY.md:L15-L56].

**[Fact]** Tíz role hordoz explicit adversarial stance-et: code reviewer, documentation verifier, evaluation auditor, integration checker, Nyquist auditor, plan checker, security auditor, UI auditor, UI checker és verifier. A checker szerepek jellemzően nem írhatják az implementationt; az executor írhat, de a shared STATE/ROADMAP reconciliation az orchestratoré. A `gsd-user-profiler` read-only, a `gsd-debug-session-manager` explicit subagent-dispatch szerep.

**[Fact]** A planning research/planner/checker fresh subagentekben fut; legfeljebb három revision iteration, legfeljebb két „adjust approach” re-entry és non-decreasing issue detector korlátozza [33985c1:gsd-core/workflows/plan-phase.md:L1096-L1276]. Üres vagy csonka agent-válaszból nem következtet sikerre: visszaolvassa a disk artifactot.

## 7. Roles, personas, skills, plugins, hooks, and automation

**[Fact]** A 44 capability manifest 19 runtime-, 20 feature- és 5 reviewer-capability. A 20 feature: `ai-integration`, `assumption-delta`, `audit`, `broken-windows`, `claude-orchestration`, `code-review`, `drift`, `external-job`, `gap-analysis`, `graphify`, `intel`, `mempalace`, `nyquist`, `pattern-mapper`, `profile-pipeline`, `research`, `schema-gate`, `security`, `tdd`, `ui`; az öt reviewer: `coderabbit`, `gemini`, `llama-cpp`, `lm-studio`, `ollama` [33985c1:docs/adr/1244-capability-ecosystem.md:L38-L77].

**[Fact]** A capability formula: `enabled = installed && surfaced`, majd `active = enabled && config gate` [33985c1:src/capability-state.cts:L162-L242]. A profile (`core`, `standard`, `full`, illetve composable closure-k) az installált skill-setet, a runtime surface a látható skill-setet szabja meg. Hat namespace meta-skill a workflow, project, quality/review, context, manage és ideate csoportokat route-olja [33985c1:docs/ARCHITECTURE.md:L123-L131].

**[Fact]** A project capability repository-controlled executable input, ezért consent nélkül inaktív. A consent repository-n kívül él, real project root + capability ID + teljes bundle hash kulccsal [33985c1:src/capability-consent.cts:L1-L21] [33985c1:src/capability-consent.cts:L214-L219]. A write lockolt, fsyncelt és atomic rename-et használ; lock failure esetén hibát dob [33985c1:src/capability-consent.cts:L626-L709].

**[Fact]** A trust disclosure executable pathot, reviewer invocationt, MCP command/args/transport/URL/header/env adatot vesz számításba és human-visible secretet redaktál [33985c1:src/capability-trust.cts:L108-L170] [33985c1:src/capability-trust.cts:L1098-L1178]. **[Fact]** Egy betöltési hibás optional capability hangos warning mellett fail-open, hogy ne blokkoljon minden ship/verify utat [33985c1:src/loop-resolver.cts:L543-L582].

## 8. Workflow composition and reference graph

**[Fact]** A fő artifact graph:

```text
new-project / ingest-docs
  -> PROJECT.md + REQUIREMENTS.md + ROADMAP.md + STATE.md
discuss-phase -> CONTEXT.md
plan-phase -> RESEARCH/PATTERNS/(UI|AI)-SPEC -> NN-PLAN.md -> checker verdict
execute-phase -> code commit + NN-SUMMARY.md -> shared-state reconciliation
verify/validate -> UAT.md / VERIFICATION.md -> gap plan -> execute
audit/complete/ship -> audit/archive/release + ship contributions/learnings
```

**[Fact]** Az execution dependency wave-eket számol; a wave-ek sorban, a wave-en belüli planek csak engedélyezett és biztonságos esetben párhuzamosak [33985c1:gsd-core/workflows/execute-phase.md:L9-L36] [33985c1:gsd-core/workflows/execute-phase.md:L328-L338]. File-overlap, submodule, base divergence, hiányzó completion signal vagy unavailable required isolation sequential/fail-closed irányba terel. A worktree manifest pontos path/branch/base metadata alapján korlátozza a merge-et és cleanupot [33985c1:gsd-core/workflows/execute-phase.md:L428-L593] [33985c1:gsd-core/workflows/execute-phase.md:L597-L742].

**[Fact]** A canonical include path plugin installnál külön hookkal képződik le a bundle-re [33985c1:docs/ARCHITECTURE.md:L286-L294]. **[Runtime]** A ledger ezért külön kezeli a direct source, generated source projection, installed canonical projection, runtime artifact, dynamic template, external és fixture/history referenciákat; egy egyszerű `exists(path)` broken-link scanner hamis pozitívokat adna.

**[Fact]** A progressive disclosure namespace skillt, késleltetett reference/nested-step betöltést, `CONTEXT.md` predicate store-t, zárt `gsd:section` fragment-vocabularyt és byte-budgeted compositiont használ [33985c1:docs/ARCHITECTURE.md:L145-L204] [33985c1:docs/ARCHITECTURE.md:L350-L381]. Malformed, nested, duplicate vagy unknown fragment marker fail-closed.

## 9. Script-level execution paths

**[Fact]** A legmélyebb hot spotok: `bin/install.js` 13 531 sor; `gsd-core/bin/gsd-tools.cjs` 3 682; `src/state.cts` 3 404; `src/runtime-artifact-conversion.cts` 3 058; `src/phase.cts` 2 710; `src/init.cts` 2 692; `src/verify.cts` 2 672; `src/runtime-hooks-surface.cts` 2 538. Ezek teljes-file newline census értékek, nem logikai complexity score-ok.

**[Fact]** Hat fontos call path:

1. Install: npm bin → `bin/install.js` → generated registry → config plan/layout → converter → install engine → migration/trust snapshot → host config/hook writer → verify/rollback.
2. Command: host skill → canonical command → workflow → `gsd_run` → `gsd-tools.cjs` → family/host router → compiled module → filesystem/git.
3. State: workflow init/state verb → lock → pure transition intent → preservation ratchet → atomic write.
4. Capability loop: loop point → resolver → overlay registry → profile/surface/config → ordered fragment.
5. Review lane: workflow → reviewer descriptor → probe/invocation → timeout-bounded reviewer → normalized verdict.
6. Worktree: plan index → safety gauntlet → manifest → executor commit/summary → manifest-scoped merge/cleanup → shared state.

**[Fact]** A config adapter descriptor-derived install plant ad, az artifact layout zárt kind dispatchert használ, a content converter pedig unsupported residual dispatch formot elutasít [33985c1:src/runtime-config-adapter-registry.cts:L120-L183] [33985c1:src/runtime-artifact-layout.cts:L462-L527] [33985c1:src/runtime-artifact-conversion.cts:L2540-L2730]. **[Inference]** Ez jó ownership-vonal, de az installer mérete mutatja, hogy a host-specific tranzakciós special case-ek kivonása még nem kész.

## 10. Installation, update, migration, recovery, and removal

**[Fact]** Az installer 18 CLI runtime-ot választ; VS Code külön, tizenkilencedik runtime descriptor, `installSurface: none` extensionnel [33985c1:bin/install.js:L12484-L12557] [33985c1:capabilities/vscode/capability.json:L1-L53]. A descriptor census:

| Tier | Runtime-ok |
|---|---|
| T1 | Claude, Codex, Antigravity, VS Code |
| T2 | Augment, Cline, CodeBuddy, Copilot, Cursor, Hermes, Kilo, Kimi CLI, Kimi Code, OpenCode, Pi, Qwen, Trae, Windsurf, ZCode |

**[Fact]** A runtime descriptor a home/layout/dialect/hook/support/dispatch/state/transport/engine contract canonical forrása; például a Codex külön config- és skill-home-ot, TOML sidecart, hookot, sandbox tiert és orchestrator-worktree modellt deklarál [33985c1:capabilities/codex/capability.json:L1-L94].

**[Fact]** Az install pipeline runtime/root/profile feloldás után preflightot és manifest-backed migrationt futtat, rollback snapshotot készít, canonical runtime-ot stagingel, descriptor-declared artifactokat materializál, host configot ír, outputot validál, és late failure esetén rollbackel. Unsafe symlink traversal csak explicit opt-innel engedett; Codex config write atomic és snapshot-backed [33985c1:bin/install.js:L6271-L6327] [33985c1:bin/install.js:L6885-L6955] [33985c1:bin/install.js:L10070-L10284].

**[Fact]** Update/uninstall tulajdonosi manifestből dolgozik: nem-GSD fájlt megőriz, user-modified managed artifactot nem kezel pristine-ownedként, stale managed fájlt csak scoped módon tisztít, incomplete installt pedig jelenti. **[Inference]** A recovery erős, de a széles install boundary miatt a downstream portnak tranzakciós coordinatorra és hostonkénti contract tesztekre van szüksége.

## 11. Testing, observability, security, and failure modes

**[Fact]** A tree 899 test fájlt/assetet tartalmaz. A test runner unit, integration, install, security, slow és QA suite-ot különít el; a package scriptek fast-checket, c8-at, Strykert, ESLintet, secret/base64 scant, shell checket, packaginget és generated parityt is deklarálnak [33985c1:package.json:L56-L80] [33985c1:package.json:L82-L145].

**[Runtime]** Megőrzött Node 22 evidence: `npm run check:env` exit 0; build-materialized `npm run lint:generated-sync` exit 0; issue-607 dry-run 5/5 pass; direct `atRefContractStillResolvesAfterComposition` 1/1 pass. Minden command, cwd, exit, elapsed, stdout/stderr és Node/npm verzió a `work/evidence/open-gsd-gsd-core/runtime-verification.json` fájlban van.

**[Runtime]** Az első harness attempt azért bukott, mert a child scriptek a gép default Node 26-ját örökölték; az attempt JSON/log megmaradt. A PATH portable Node 22-re pinelése után az evidence-run zöld lett. Ez environment-root-cause, nem product fallback.

**[Limit]** A korábbi 18-file/877-test/865-pass/12-skip és 244 s/122,7 s timeout állítások exact command, file list, stdout/stderr, process list és cleanup proof nélkül maradtak. A dosszié ezeket nem tekinti auditált runtime eredménynek, és a timeoutokhoz nem rendel EPIPE-okozati következtetést.

**[Fact]** Security-positive elemek: content-bound consent, closed enum/schema és prototype-safe key, bounded regular-file read, symlink-aware confinement, atomic/fsynced write, live lock-holder check, redacted diagnostics, fail-closed unrepresentable role projection, prompt-boundary instructions és manifest-owned worktree safety [33985c1:src/capability-consent.cts:L67-L117] [33985c1:src/capability-trust.cts:L1098-L1178].

**[Fact]** A failure policy boundaryfüggő: pozitívan felismert write/worktree violation block/exit 2; descriptor/config invalidity loud failure; optional loop contribution load error warning + fail-open; unexpected hook exception többnyire fail-open [33985c1:docs/ARCHITECTURE.md:L795-L813]. A read injection scanner default advisory, és Kimi post-tool surface-en nem tud enforce-olni [33985c1:hooks/gsd-read-injection-scanner.js:L4-L22] [33985c1:hooks/gsd-read-injection-scanner.js:L116-L124].

## 12. Documentation-code-test drift

**[Runtime]** Build-materialized checkoutban zöld volt a capability registry, loop contract, runtime matrix, 47 versioned manifest, inventory manifest, package identity, 71 plugin skill, documentation registry, 71-entry ADR index, 49 glossary reference, kilenc compiled artifact és context index generator/checker. Ez csak a deklarált generated surface-ek parity-bizonyítéka.

**[Fact]** Megerősített prose drift:

1. `docs/AGENTS.md` és `docs/ARCHITECTURE.md` helyenként 33 agentet mond, miközben a tree és authoritative inventory 34 [33985c1:docs/AGENTS.md:L1-L15] [33985c1:docs/ARCHITECTURE.md:L208-L217].
2. Az architecture runtime table 15 CLI hostot sorol, miközben 18 CLI descriptor/install surface és külön VS Code descriptor van [33985c1:docs/ARCHITECTURE.md:L859-L885].
3. Kimi és Windsurf hook-prose régebbi a jelenlegi descriptoroknál [33985c1:capabilities/kimi/capability.json:L45-L55] [33985c1:capabilities/windsurf/capability.json:L50-L59].
4. A config-adapter comment 16 runtime-ot említ, a descriptor-derived set 18 [33985c1:src/runtime-config-adapter-registry.cts:L97-L109].
5. A long help kihagyja a parser által elfogadott `--pi` és `--kimi-code` flaget [33985c1:bin/install.js:L642-L668] [33985c1:bin/install.js:L913-L913].
6. A curated inventory nem recursive full-tree inventory; a két fogalmat külön kell tartani [33985c1:docs/INVENTORY.md:L1-L9].
7. Egy unique Markdown edge rossz relative rootot használ a reviewer-instances reference-ben; ezt a full ledger `confirmed_broken` osztályban tartja.

**[Inference]** A generator discipline erős a gép által birtokolt surface-en, de a kézzel írt count-, compatibility- és help-prose nincs ugyanabba a contractba bekötve. A javítási irány: registryből generált számok/táblák és külön whole-tree reference manifest.

## 13. Runtime experiments

**[Runtime]** A source-checkout és build-materialized checkout megkülönböztetése kötelező:

| Checkout | `gsd-core/bin/lib/*.cjs` | Inventory manifest `--check` | Értelmezés |
|---|---:|---:|---|
| pristine pinned source | 17 tracked | exit 1, 156 roster target absent | a build output még nincs materializálva |
| disposable clone `npm ci`/`prepare` után | 173 összesen, ebből 156 ignored build output | exit 0 | a generator/parity check build-state-ben értelmes |

**[Runtime]** A buildelt clone `git status --short` kimenete clean, mert az extra 156 CJS ignored; a clean status önmagában nem bizonyít pristine state-et. A generated-sync log a build-materialized állapothoz tartozik.

**[Runtime]** A reference experiment az összes 2 725 gear fájlt byte-szinten olvasta, NUL-bearing fixture-t sem hagyott ki. A 42 366 rekord kötelező mezői: source path/line, raw reference, syntax context, resolution root, normalized target, existence, terminal class, exclusion reason. Root confinement, line validity és duplicate key gate védi a ledger mechanikai integritását.

**[Runtime]** A végső validáció külön ellenőrizte a pinned citationök path/range helyességét, a 2 730/2 725 coverage számokat, a dosszié pontosan 16 `##` szakaszát, a reference summary zéró unresolved osztályát és mindkét checkout exact HEAD/clean tracked állapotát.

## 14. Reusable patterns

**[Inference]** Tiszta-room reuse-ra érdemes minták:

| Minta | Átveendő invariáns | Fő trade-off |
|---|---|---|
| Canonical prompt IR → host projection | egy authoring dialect, zárt transzformok, post-projection validation | converter complexity, explicit lossy degradation |
| Descriptor-driven runtime | schema-valid descriptor, immutable generated registry, exact layout kinds | host special case-ek nem tűnnek el |
| File-backed state algebra | pure intent, field ownership, lockolt atomic writer, disk-derived reconciliation | Markdown migration és parsing költség |
| Producer/checker separation | eltérő tool scope, structured verdict, bounded retry, operator override | latency és token cost |
| 12-point contribution bus | closed lifecycle points, ordered fragment, one config snapshot | fail-open extension nem security gate |
| Content-bound consent | realpath project identity, whole-bundle hash, external atomic store | re-consent UX és operational complexity |
| Manifest-owned worktree | exact path/branch/base/agent metadata, no scan fallback | host semantics és recovery complexity |
| Generated drift gate | deterministic generator, committed artifact, CI equality | csak a declared surface-et fedi |
| Evidence-backed empty return | disk artifact és commit független az agent narrationtől | partial state idempotencia szükséges |

**[Fact]** A code reuse MIT mellett lehetséges a notice megőrzésével [33985c1:LICENSE:L1-L21]. **[Inference]** Javasolt sorrend: kis canonical artifact graph → pure state core → egy reference host → producer/checker loop → második host után descriptor registry → executable extension consent → manifest-scoped worktree → generated és prose gate külön.

## 15. Weaknesses and anti-patterns

**[Fact]** Magas prioritású gyengeségek: a 13 531 soros installer túl széles mutation boundary; prose count és host table drift; shallow, nem recursive curated manifest; mixed hook failure semantics; user-visible CLI help omission; egy confirmed broken internal documentation edge.

**[Fact]** Security/compatibility korlátok: az agent shell command a user jogosultságával fut; prompt nem sandbox; regex injection detector nem érti az intenciót; explicit symlink/shrink bypass az operatorra tolja a kockázatot; global capability home compromise kívül esik a project-consent threat modellen; több host axis `undocumented` [33985c1:hooks/gsd-read-injection-scanner.js:L4-L22] [33985c1:src/capability-loader.cts:L1-L29].

**[Limit]** Nem történt live vendor certification Claude/Codex/Kimi/OpenCode/Kilo/Cursor/VS Code vagy más host ellen; nem futott hálózati reviewer, MCP transport, Graphify, Brave, registry vagy update path. A descriptor és fixture repository fact, nem külső termékgarancia.

**[Limit]** A terminal reference classok explicit és auditálhatók, de a prompt/prose/generated/fixture kategóriákba sorolás nem bizonyítja minden lehetséges runtime CWD és host resolver szemantikáját. A dosszié ezért egy broken edge-et bizonyít, de nem állít univerzális „minden más link helyes” tételt.

**[Inference]** Legnagyobb fejlesztési payoff: az installer további tranzakciós modularizálása; recursive source/generated/fixture/doc ownership manifest; registryből generált public count/help/runtime table; machine-readable `advisory`/`fail-open`/`fail-closed-on-match` hook policy; suite-onkénti időzítés és vendor-version evidence dashboard.

## 16. Evidence index

**[Fact] Primary source corpus**

- `package.json`, `LICENSE` — package, runtime, scripts, licence;
- `docs/ARCHITECTURE.md`, `docs/INVENTORY.md`, `docs/INVENTORY-MANIFEST.json` — rendszerkép és curated roster;
- `docs/adr/457-generated-cjs-single-source.md`, `1244-capability-ecosystem.md`, `1508-runtime-artifact-conversion-module.md`, `1671-dynamic-context-management-platform.md` — ownership és döntések;
- `capabilities/*/capability.json` — 19 runtime, 20 feature, 5 reviewer descriptor;
- `commands/gsd/*`, `skills/gsd-*`, `gsd-core/workflows/*`, `gsd-core/references/*`, `agents/gsd-*` — canonical prompt/artifact graph;
- `src/state*.cts`, `phase-lifecycle.cts`, `loop-resolver.cts`, `capability-*.cts`, `runtime-*.cts`, `bin/install.js` — determinisztikus implementation;
- `hooks/hooks.json`, managed registry és hook scriptek — event és guard surface;
- mind a 899 tracked test fájl/asset — teljes read coverage, nem mind runtime-executed.

**[Runtime] Persisted local evidence**

- `work/inventory/open-gsd-gsd-core-files.csv` — 2 730 tracked path, bytes, SHA-256, category és gear flag;
- `work/evidence/open-gsd-gsd-core/references.csv` — 42 366 terminally classified reference record;
- `work/evidence/open-gsd-gsd-core/reference-summary.json` — 2 730/2 725 coverage és class totals;
- `work/evidence/open-gsd-gsd-core/runtime-verification.json` — exact retained commands, environment, exit és elapsed;
- ugyanott `*.stdout.log` és `*.stderr.log` — `check:env`, generated-sync, issue-607, atRef és version outputok;
- ugyanott `attempt-1-*` — a Node 26 PATH-mismatch első, megőrzött failure evidence-e.

**[Inference] Bottom line:** A `33985c11…` pin GSD Core-ja érett, gyorsan fejlődő multi-runtime orchestration framework. Valódi differenciáló ereje nem a promptok száma, hanem a prompt programming, determinisztikus file-state, adversarial role separation, content-bound trust és install-time host projection együttese. Ezek a minták átvehetők, de csak a failure semantics, ownership ledger és valós integration tesztek megtartásával.

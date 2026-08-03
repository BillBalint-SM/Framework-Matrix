# GitHub Spec Kit — végleges kutatási dosszié

## 1. Snapshot and provenance

| Mező | Rögzített érték |
|---|---|
| Repository | `github/spec-kit` |
| Branch | `main` |
| Commit | `d1e86f638277a99b82715c22c90558cd58d3cffd` |
| Csomag | `specify-cli 0.15.2.dev0` |
| Python-követelmény | `>=3.11` |
| Licenc | MIT |
| Kutatási állapot | tiszta worktree, `main == origin/main` |
| Preflight frissesség | `2026-08-02T13:57:44.8214328Z` |

Jelölések: **[Tény]** a rögzített forrásból közvetlenül látható állítás; **[Runtime]** a kutatás során ténylegesen futtatott ellenőrzés; **[Következtetés]** több tényből levezetett értelmezés; **[Szerzői állítás]** a repository dokumentációjának kijelentése. A forrásidézetek a rögzített commitot és pontos sorszakaszt használják: `[d1e86f6:path:Lx-Ly]`.

**[Runtime]** A repository 530 tracked fájlt tartalmaz. Öt bináris médiafájlt külön kezeltünk; a további **525/525** fájlhoz auditálható szemantikai rekord készült bájtmérettel, SHA-256-tal, elemzési móddal, tartalmi szinopszissal, rögzített forrás-URL-lel és referencia-kapcsolatokkal. A teljes módszer és eredmény a [closure summary](../work/evidence/github-spec-kit/closure-summary.md), az egyedi fájlrekordok a [gear semantic ledger](../work/evidence/github-spec-kit/gear-semantic-ledger.csv) alatt találhatók.

Context7 nem volt indokolt: a kérdés tárgya egy konkrét, commitra rögzített repository, ezért az owner-controlled forrás, tesztek és dokumentáció jelentik az elsődleges bizonyítékot.

## 2. Executive summary

**[Következtetés]** A Spec Kit legpontosabban egy projektlokális **fordítóként és tartós workflow-hostként** írható le. Kanonikus Markdown/YAML/script eszközöket telepít a `.specify/` alá, majd ezeket 37 különböző agent-integráció natív parancs-, skill-, TOML- vagy YAML-formátumára materializálja.

Öt együttműködő vezérlősíkja van:

1. bootstrap és projektállapot: `specify init`, `.specify/`, közös sablonok és scriptek;
2. integration adapterek: kanonikus parancsból termékspecifikus reprezentáció;
3. kompozíció: extension, preset, bundle és katalógusok;
4. lifecycle eventek: közös dispatcher és natív agent-hook konfiguráció;
5. tartós workflow-motor: parancs, prompt, shell, gate, elágazás, ciklus és fan-out/fan-in lépések.

A legerősebb minták: kanonikus forrás/több adapter, hash-alapú fájltulajdon, atomi állapotírás, emberi gate-ek, preview/install közös terve, URL-alapú extensionöknél default-deny bizalmi kapu és platformparitás-tesztek. A legnagyobb kockázatok: a `shell=True` tudatosan teljes felhasználói jogosultsággal fut; a workflow `requires` nem sandbox; a közvetlen engine API validálatlan definíciót is fogadhat; a hiányzó vagy prompt-only event cél sikeres no-op lehet; négy szállított bundle-példa pedig a dokumentált validátorral ténylegesen hibás.

A rögzített commit maga is ezt a határvédelmet erősíti: a gate-lépés futás közben is elutasítja az ismeretlen `on_reject` értéket, nem hagyja azt `skip` viselkedésbe átcsúszni [d1e86f6:src/specify_cli/workflows/steps/gate/__init__.py:L78-L101].

## 3. Repository and component inventory

**[Runtime]** Területi census:

| Terület | Fájl | Fő tartalom |
|---|---:|---|
| gyökér/egyéb | 38 | csomagmetaadat, licenc, README-k, média |
| `.github` | 37 | CI, release, security, agentic workflow-k |
| `docs` | 37 | telepítés, auth, extension, preset, bundle, workflow |
| `examples` | 8 | négy role bundle és kísérő README |
| `extensions` | 59 | négy built-in termék, template/selftest, katalógus |
| `presets` | 29 | két built-in preset, scaffold és tesztanyag |
| `scripts` | 15 | öt felelősség Bash/PowerShell/Python változatban |
| `src` | 126 | CLI, adapterek, eventek, komponensek, workflow-motor |
| `templates` | 16 | tíz parancs és hat artifact/config sablon |
| `tests` | 157 | 152 Python fájl és öt nem-Python fixture/config |
| `workflows` | 8 | built-in workflow, sémák, katalógusok |
| **Összesen** | **530** | **525 szemantikailag auditált gear + 5 bináris média** |

**[Tény]** A csomag belépési pontja `specify = specify_cli:main`; közvetlen függőségei többek között Typer, Click, Rich, platformdirs, PyYAML, packaging, pathspec és json5 [d1e86f6:pyproject.toml:L1-L20]. A gyökér-CLI az `init`, self-management, `extension`, `integration`, `event`, `preset`, `bundle` és `workflow` alkalmazásokat regisztrálja [d1e86f6:src/specify_cli/__init__.py:L501-L582].

**[Tény]** Tíz kanonikus parancssablon van: `analyze`, `checklist`, `clarify`, `constitution`, `converge`, `implement`, `plan`, `specify`, `tasks`, `taskstoissues`. A scriptet használó nyolc parancs mindhárom `sh`/`ps`/`py` változatot deklarálja, összesen 24 frontmatter script-referenciával; `constitution` és `specify` prompt-only terminál.

**[Tény]** A 37 integrációs ID teljes készlete: `agy`, `alquimia`, `amp`, `auggie`, `bob`, `claude`, `cline`, `codebuddy`, `codex`, `copilot`, `cursor-agent`, `devin`, `droid`, `firebender`, `forge`, `gemini`, `generic`, `goose`, `grok`, `hermes`, `junie`, `kilocode`, `kimi`, `kiro-cli`, `lingma`, `omp`, `opencode`, `pi`, `qodercli`, `qwen`, `rovodev`, `shai`, `tabnine`, `trae`, `vibe`, `zcode`, `zed` [d1e86f6:src/specify_cli/integrations/__init__.py:L40-L128]. A korábban kihagyott `kiro-cli` a Markdown family része: `MarkdownIntegration`, célja `.kiro/prompts`, formátuma Markdown, kiterjesztése `.md` [d1e86f6:src/specify_cli/integrations/kiro_cli/__init__.py:L14-L35].

**[Runtime]** Katalógusok: 4 built-in és 144 community extension; 2 built-in és 29 community preset; 1 built-in és 2 community workflow; 0 built-in/community step-katalógus. A built-in források közvetlenül ellenőrizhetők [d1e86f6:extensions/catalog.json:L1-L67; d1e86f6:presets/catalog.json:L1-L53; d1e86f6:workflows/catalog.json:L1-L16; d1e86f6:workflows/catalog.community.json:L1-L50], a reprodukálható számlálási módszer a [critical-counts evidence](../work/evidence/github-spec-kit/critical-counts.md) része.

## 4. Architecture and layer model

```text
kanonikus repository-eszközök
  commands + templates + scripts + workflow
                 │
                 ▼
       init / resolver / composer
        ├── integration adapterek ──► agent-native fájlok
        ├── extension/preset/bundle ─► projektviselkedés
        ├── event renderer ──────────► natív hook konfiguráció
        └── workflow engine ─────────► tartós run állapot
                 │
                 ▼
      .specify/ + agent-specifikus könyvtárak
```

Hatókörök:

| Scope | Példa | Szerep |
|---|---|---|
| Global/user | `~/.specify/auth.json`, user catalog/cache | felhasználói hitelesítés és felfedezés |
| Project | `.specify/`, integrációs manifestek, registry-k | megosztott, verziózható projektállapot |
| Session/run | `.specify/workflows/runs/<run_id>/` | input, program counter, output, log |
| Local override | `.specify/extensions/local-config.yml` | nem megosztott, legerősebb projektközeli felülírás |

**[Tény]** Az integration manifest tartalmi hash-t és tulajdonost rögzít, unsafe pathot/symlinket visszautasít, uninstallkor pedig alapból csak változatlan saját fájlt töröl [d1e86f6:src/specify_cli/integrations/manifest.py:L142-L233; d1e86f6:src/specify_cli/integrations/manifest.py:L297-L424]. Mentése temp fájl + `os.replace`, tehát atomi [d1e86f6:src/specify_cli/integrations/manifest.py:L428-L456].

**[Tény]** Extension-konfiguráció precedenciája: extension default < projekt extension config < projekt local config < `SPECKIT_<ID>_*` környezet [d1e86f6:src/specify_cli/extensions/__init__.py:L3993-L4001; d1e86f6:src/specify_cli/extensions/__init__.py:L4211-L4227]. A preset kompozíció `replace`, `prepend`, `append`, `wrap` stratégiákat támogat [d1e86f6:src/specify_cli/presets/__init__.py:L5441-L5495].

## 5. Events, formulas, state transitions, and loops

**[Tény]** A hat kanonikus lifecycle event: `session_start`, `pre_tool_use`, `post_tool_use`, `session_end`, `user_prompt_submit`, `stop` [d1e86f6:src/specify_cli/events.py:L56-L61]. Feloldási sorrend: `--events false` tiltás; integration default; engedélyezett extension handler; érvényes `.specify/integration-events.yml` teljes felülírás. Hibás override esetén a korábbi feloldott konfiguráció marad [d1e86f6:src/specify_cli/events.py:L694-L804].

Az event-időzítés képlete:

```text
inner dispatcher timeout = handler timeout seconds
outer native timeout = native_unit(handler timeout + EVENT_TIMEOUT_BUFFER)
```

Az inner parancs nyers másodpercet kap; a buffer csak a külső agent caphez adódik, majd az adapter másodperc/milliszekundum egységre alakítja. Így a belső timeoutnak van ideje saját hibáját visszaadni [d1e86f6:src/specify_cli/events.py:L47-L52; d1e86f6:src/specify_cli/events.py:L944-L958; d1e86f6:src/specify_cli/events.py:L1039-L1045; d1e86f6:src/specify_cli/events.py:L1155-L1216].

**[Tény]** A workflow 11 built-in lépést regisztrál: `command`, `prompt`, `shell`, `init`, `gate`, `if`, `switch`, `while`, `do-while`, `fan-out`, `fan-in` [d1e86f6:src/specify_cli/workflows/__init__.py:L43-L72]. Állapotát `state.json`, `inputs.json` és append-only `log.jsonl` fájlokban tartja; a run ID-t path komponensként validálja [d1e86f6:src/specify_cli/workflows/engine.py:L535-L616], az állapot/input atomi, a konkurens logírás lockolt [d1e86f6:src/specify_cli/workflows/engine.py:L641-L709; d1e86f6:src/specify_cli/workflows/engine.py:L802-L830].

**[Következtetés]** A top-level program counter köré épülő resume miatt egy már részben lefutott nested `if`/ciklus/fan-out szülőlépés újrabelépése ismételhet mellékhatást; ezért az idempotencia üzemi követelmény, nem kényelmi tulajdonság.

## 6. Agent and sub-agent model

**[Tény]** A Spec Kitben az „agent” elsődlegesen integration boundary: meghatározza a telepítési biztonságot, célkönyvtárat, invocation formát, renderelést, migrációt és event-képességet. A kanonikus prompt viselkedését nem agentenként másolja, hanem adapteren keresztül fordítja [d1e86f6:src/specify_cli/integrations/base.py:L759-L872].

Az output family-k:

- Agent Skills: többek között Claude, Codex, Cursor Agent, Devin, Droid, Kimi és Zed;
- Markdown command: többek között Amp, Cline, OpenCode, Qwen és **Kiro CLI**;
- TOML: Gemini, Tabnine;
- YAML: Goose;
- bespoke/hibrid: Copilot, Bob, Generic.

**[Tény]** Hat repository-karbantartó GitHub Agentic Workflow forrás/lock pár van: `add-community-bundle`, `add-community-extension`, `add-community-preset`, `bug-assess`, `bug-fix`, `bug-test`. A generated lock metaadata `gh-aw v0.79.8` fordítót és Copilot `1.0.60` engine-t rögzít [d1e86f6:.github/workflows/add-community-bundle.lock.yml:L1-L3]. Ezek inline sub-agent könyvtárat is visszaállíthatnak, de a snapshotban nincs külön tracked `.github/agents` personaállomány.

## 7. Roles, personas, skills, plugins, hooks, and automation

**[Tény]** A rendszernek nincs önálló, első osztályú `plugin` primitívje. A feladatokat négy eltérő szerződés osztja fel:

- extension: parancs, hook, event, script, template és konfiguráció hozzájárulása;
- preset: kanonikus viselkedés cseréje/kompozíciója;
- bundle: több komponens deklaratív disztribúciója és telepítési terve;
- integration: agent-termékhez tartozó materializációs adapter.

A négy built-in extension: `agent-context`, `assess`, `bug`, `git`. A két built-in preset: `lean`, `constitution-sync`. A built-in `speckit` workflow normál útja:

```text
specify → human gate → plan → human gate → tasks → implement
```

Classic extension hook esetén az agent számára követendő instrukció keletkezik; native event esetén a közös dispatcher tényleges subprocess-t indít `shell=False` módban. E két mechanizmus azonos extensionből származhat, de végrehajtási szemantikája nem azonos [d1e86f6:src/specify_cli/events.py:L476-L558; d1e86f6:src/specify_cli/events.py:L587-L624].

Az Agentic Workflow-k közül a katalógus-karbantartók issue-ból validálnak és kontrollált draft PR/label/comment kimenetet készíthetnek; a bug-hármas emberi label gate-en át assessment → fix → test csatornát alkot. A generated lock végrehajtható supply-chain artifact, ezért ugyanúgy security-critical, mint a kézzel írt workflow.

## 8. Workflow composition and reference graph

**[Runtime]** A teljes referencia-ledger 5 945 előfordulást tart meg forrásfájllal és sorral:

| Referenciatípus | Darab |
|---|---:|
| Python AST import | 4 979 |
| Markdown inline link | 578 |
| Markdown reference definition | 4 |
| YAML `uses:` | 325 |
| command script | 24 |
| bundle component | 20 |
| shell `source` | 7 |
| generated source/lock pair | 6 |
| prompt-only terminal | 2 |
| **Összesen** | **5 945** |

Terminális osztályok: `executable` 2 737; `external_dependency` 2 962; `repository_file` 208; `generated_artifact` 6; `prompt_only` 2; `prose_example` 14; `broken` 16; általános `unresolved` **0**. A teljes géppel olvasható bizonyíték: [reference-ledger.csv](../work/evidence/github-spec-kit/reference-ledger.csv).

**[Runtime — confirmed broken]** Mind a négy role-példa README-je futtatható `specify bundle validate --path ...` parancsot ad, és mind a négy exit 1. A 16 hibás komponensreferencia:

| Bundle | Hiányzó preset | Hiányzó step-ek | Hiányzó workflow |
|---|---|---|---|
| `business-analyst` | `requirements-elicitation@1.0.0` | `capture-requirements@unpinned`; `trace-acceptance-criteria@unpinned` | `requirements-to-spec@1.0.0` |
| `developer` | `implementation-planning@1.0.0` | `plan-implementation@unpinned`; `break-down-tasks@unpinned` | `spec-to-implementation@1.0.0` |
| `product-manager` | `product-discovery@1.0.0` | `draft-spec@unpinned`; `review-spec@unpinned` | `spec-to-roadmap@1.0.0` |
| `security-researcher` | `security-compliance@1.0.0` | `threat-model@unpinned`; `security-review@unpinned` | `secure-sdd@1.0.0` |

A line-szintű 16 soros lista és hibaok a [bundle broken evidence](../work/evidence/github-spec-kit/bundle-broken-references.md) fájlban van. A dokumentált parancsok a rögzített README-kben láthatók [d1e86f6:examples/bundles/business-analyst/README.md:L14-L22; d1e86f6:examples/bundles/developer/README.md:L14-L22; d1e86f6:examples/bundles/product-manager/README.md:L14-L22; d1e86f6:examples/bundles/security-researcher/README.md:L15-L23].

## 9. Script-level execution paths

```text
analyze/converge/implement/taskstoissues ─► check-prerequisites --require-tasks --include-tasks
checklist ───────────────────────────────► check-prerequisites --json
clarify ─────────────────────────────────► check-prerequisites --paths-only
plan ────────────────────────────────────► setup-plan
tasks ───────────────────────────────────► setup-tasks
constitution/specify ────────────────────► prompt-only
```

**[Tény]** A 15 core script öt felelősség három platformváltozata: `common`, `create-new-feature`, `check-prerequisites`, `setup-plan`, `setup-tasks`. A közös artifact graph: `.specify/memory/constitution.md` → `spec.md` → `plan.md` (+ `research.md`, `data-model.md`, `quickstart.md`, `contracts/`) → `tasks.md` → implementáció/issues.

Az event dispatcher ugyanazt a renderelt parancs-frontmattert használja, tehát nincs külön event-executable registry. A Python `PresetResolver` teljes deklaratív kompozíciót végez; a Bash/PowerShell/Python common script egyszerűbb materializált lookupot használ. **[Következtetés]** Ez koherens, de csak folyamatos cross-representation paritásteszttel tartható fenn.

**[Tény]** A workflow shell step raw template-interpoláció után `subprocess.run(..., shell=True)` hívást használ, hogy pipe és redirect működjön [d1e86f6:src/specify_cli/workflows/steps/shell/__init__.py:L51-L63]. Az inputot kódként kell kezelni; a quoting nem security boundary [d1e86f6:workflows/README.md:L107-L128].

## 10. Installation, update, migration, recovery, and removal

Normál életciklus: telepítés → `specify init` → integration materializálás → extension/preset/bundle kezelés → feature és SDD parancslánc → opcionális tartós workflow → konzervatív switch/uninstall.

**[Tény]** A self-upgrade öt futási módot különít el: `uv-tool`, `pipx`, ephemeral `uvx`, source checkout és unsupported; csak az első kettőt frissíti automatikusan [d1e86f6:src/specify_cli/_version.py:L204-L210; d1e86f6:src/specify_cli/_version.py:L1224-L1251]. A terv a cél taget validálja, majd stabil installer argv-t épít [d1e86f6:src/specify_cli/_version.py:L689-L749].

**[Security]** Installer indítása előtt eltávolítja az összes `GH_*`, `GITHUB_*`, valamint a meghatározott `_GITHUB_*` credential-suffixű környezeti változót, majd `shell=False` módon futtat [d1e86f6:src/specify_cli/_version.py:L254-L296; d1e86f6:src/specify_cli/_version.py:L768-L839]. Automatikus rollback nincs; ismert korábbi stabil verziónál kézi visszapinelési parancsot nyomtat [d1e86f6:src/specify_cli/_version.py:L991-L1012].

Extension/preset frissítés staginget és backupot használ. Bundle install rollbackje best effort; cleanup-hiba közben részleges állapot maradhat [d1e86f6:src/specify_cli/bundler/services/installer.py:L180-L257]. Bundle removal előbb ellenőrzi a más bundle-lel megosztott komponenseket [d1e86f6:src/specify_cli/bundler/models/records.py:L175-L185]. Integration uninstall a módosított, olvashatatlan vagy symlinkelt generált fájlt alapból megőrzi.

## 11. Testing, observability, security, and failure modes

**[Runtime]** A pontos tesztfogalmak:

- 4 230 AST-tal számolt `test_*` definíció;
- **152 Python tesztfájl**;
- **157 teljes tracked fájl** a `tests/` fa alatt;
- pytest paraméterezés után **6 388 collectált eset**.

**[Runtime]** A friss célzott clean-clone futás: 1 494 collectált; **1 487 passed, 7 skipped, 6 warnings, exit 0**; pytest 29,47 s, wall 30,5 s. A parancs, platform, Python/pytest verzió és scope a [targeted pytest evidence](../work/evidence/github-spec-kit/targeted-pytest-20260802.md) része. Ez célzott bizonyíték, nem a teljes suite helyettesítése.

**[Security — auth boundary]** A konfigurációvezérelt auth réteg `~/.specify/auth.json` alapján opt-in; bejegyzés nélkül ez a réteg nem ad credentialt [d1e86f6:src/specify_cli/authentication/config.py:L1-L3; d1e86f6:src/specify_cli/authentication/config.py:L73-L81]. Külön public helper a `_github_http.build_github_request()`: `GITHUB_TOKEN`, majd `GH_TOKEN` értéket olvas, és csak négy fix hostra csatolja (`github.com`, `api.github.com`, `raw.githubusercontent.com`, `objects.githubusercontent.com`) [d1e86f6:src/specify_cli/_github_http.py:L30-L58]. A pin teljes call-site keresése szerint production hívója nincs; csak definíció és teszthivatkozások vannak. Ez tehát latent/public képesség, nem minden HTTP-út globális viselkedése.

Az általános auth HTTP-réteg hostváltásnál vagy downgrade-nél eltávolítja az `Authorization` headert, 401/403 esetén sorban próbálja a credentialöket, majd unauthenticated kísérletet tesz [d1e86f6:src/specify_cli/authentication/http.py:L164-L218]. Azure AD client-secret POST minden redirectet elutasít [d1e86f6:src/specify_cli/authentication/azure_devops.py:L157-L167].

Download-korlátok: általános 50 MiB, JSON metadata 1 MiB, catalog 8 MiB [d1e86f6:src/specify_cli/_download_security.py:L25-L48]. ZIP/TAR extraction traversal-, link-, méret- és entries-korlátokat érvényesít [d1e86f6:src/specify_cli/_download_security.py:L897-L943; d1e86f6:src/specify_cli/_download_security.py:L1080-L1110]. URL extensionnél HTTPS az alap, csak explicit loopback HTTP kivétel [d1e86f6:src/specify_cli/_download_security.py:L318-L349].

Failure taxonómia:

- fast fail: hibás manifest/path/run ID/step, hard incompatibility, parancshiba, timeout;
- pause: non-interactive gate, explicit retry;
- preserve: user által módosított generált fájl, symlink, meglévő plan/tasks;
- warn/continue: advisory tool/MCP, bizonyos cache/catalog/auth hibák;
- best-effort compensation: extension/preset/bundle rollback;
- fail-open no-op: event célparancs hiányzik vagy nincs végrehajtható script [d1e86f6:src/specify_cli/events.py:L254-L277; d1e86f6:src/specify_cli/events.py:L587-L618].

**[Runtime]** 325 tracked YAML `uses:` előfordulás mind local action, 40 hex SHA-val pinelt action vagy SHA-256 digesttel pinelt Docker image; nem-SHA külső action 0. A szabály és számlálás a [critical-counts evidence](../work/evidence/github-spec-kit/critical-counts.md), minden előfordulás a reference ledger része. A lock set forrása `.github/aw/actions-lock.json` [d1e86f6:.github/aw/actions-lock.json:L1-L35].

## 12. Documentation-code-test drift

Három igazolt drift/csúszás:

1. A workflow guide init scriptnél csak `sh`/`ps` lehetőséget említ [d1e86f6:workflows/README.md:L135-L151], miközben a forrás és a kanonikus parancsok `py` változatot is első osztályúan támogatnak.
2. A guide a fan-outot szekvenciálisként írja le [d1e86f6:workflows/README.md:L233-L247], de a motor konfigurált, korlátozott `ThreadPoolExecutor` párhuzamosságot is támogat [d1e86f6:src/specify_cli/workflows/engine.py:L1340-L1465].
3. A négy role bundle README futtatható validálási parancsot ad olyan manifesthez, amely a szállított katalógusokkal nem oldható fel; ez nem puszta „példa lehet”, hanem 16 tételes confirmed-broken végrehajtható referencia.

Fontos API-nuance: a CLI normál útja validálja a workflow-t, de a `WorkflowEngine.execute()` maga validálatlan `WorkflowDefinition` objektumot is fogadhat; a forrás kommentje ezt kifejezetten jelzi [d1e86f6:src/specify_cli/workflows/engine.py:L1212-L1215; d1e86f6:src/specify_cli/workflows/engine.py:L1536-L1539]. Ez nem feltétlenül hamis dokumentáció, hanem hiányosan kommunikált trust boundary.

A reprodukálható Markdown-scan 578 inline és 4 reference-definition targetet talált. Mind a 582 kapott terminális osztályt; generic unresolved nincs. A szélesebb graph egyetlen broken csoportja a 16 bundle-komponens.

## 13. Runtime experiments

| Kísérlet | Eredmény | Értelmezés |
|---|---|---|
| pinned work-state preflight | clean, `main`, `HEAD=d1e86f6`, `origin/main` | forráspont igazolt |
| tracked/semantic census | 530 tracked; 525/525 gear; 5 binary | teljes fájl-lefedettség |
| reference extraction | 5 945 sor; generic unresolved 0 | auditálható closure |
| bundle validate ×4 | mind exit 1 | 16 confirmed-broken ref |
| command frontmatter | 24 script ref; 0 parse error | mindhárom script family zárt |
| targeted pytest | 1 494 collected; 1 487 pass; 7 skip; exit 0 | friss, scope-olt green evidence |
| full pytest collect-only | 6 388 | teljes runtime-esetszám |
| full pytest execution | timeout/inconclusive | sem pass, sem fail nem állítható |
| YAML `uses:` scan | 325 pinned/local; non-SHA external 0 | statikus supply-chain pin evidence |

A full suite eredményét tudatosan **nem** minősítjük sikeresnek: a collect-only csak gyűjtési bizonyíték, a timeout pedig inconclusive. Külső agent CLI, élő remote katalógus, destructive install/remove/rollback és `gh-aw` újrafordítás nem futott; ezek továbbra is evidence limit-ek.

## 14. Reusable patterns

| Minta | Átvehető érték | Adaptációs feltétel |
|---|---|---|
| kanonikus parancs + adapterek | egy viselkedés sok agenten | kicsi IR, platformspecifikus szintaxis a széleken |
| hash-owned generated files | biztonságos update/uninstall | path, owner, hash, generator verzió |
| preview/install közös plan | nincs preview/execution drift | tiszta resolver, változatlan plan input |
| explicit config-precedencia | kiszámítható override | „show effective config” diagnosztika hasznos |
| runtime invariant + schema | direct API caller ellen is véd | safety rule végrehajtáskor is |
| per-step durable state | ember/agent workflow folytatható | atomi állapot, append-only log, idempotens side effect |
| közös event dispatcher | kevés adapterduplikáció | vékony natív formatter, reference counting |
| human gate | approval látható és folytatható | non-TTY nem gyárthat jóváhagyást |
| platformparitás teszt | sh/ps/py drift észlelhető | observable contract összehasonlítás |
| catalog trust boundary | discovery elválik installtól | HTTPS/hash/signing és explicit URL trust |

Az MIT licenc közvetlen újrafelhasználást enged copyright/licenc-megőrzéssel [d1e86f6:LICENSE:L1-L21]. Az izolált security utilityk — path confinement, hash ownership, archive extraction, redirect authorization — jó direct-reuse jelöltek. A több ezer soros extension/preset monolitokat célszerűbb szerződés- és tesztvezérelt clean-room modulokra bontani.

## 15. Weaknesses and anti-patterns

Magas jelentőség:

1. raw workflow-interpoláció + `shell=True`: teljes felhasználói jogosultságú kódfuttatási határ;
2. engine-validáció nem intrinszikus: public/direct hívó átlépheti az ingestion gate-et;
3. native event sikeres no-opja elrejtheti a hiányzó/prompt-only célhibát;
4. bundle/extension/preset tranzakciók részleges kompenzációja nehezen javítható állapotot hagyhat;
5. négy szállított role bundle a saját dokumentált validatorával hibás.

Közepes/alacsony jelentőség:

6. extension és preset control plane monolitikus, sok felelősséggel;
7. három script-implementáció folyamatos paritásköltség;
8. nested resume ismételhet mellékhatást;
9. `requires` advisory, nem capability/authorization;
10. unauthenticated fallback privát asset hibáját elhomályosíthatja;
11. dokumentáció lemarad a Python init és concurrent fan-out mögött;
12. generated Agentic Workflow lockok volumene elrejti a kézi forrás intentjét.

Javasolt sorrend: először a négy bundle-példa vagy katalógusainak javítása; utána az event no-op explicit warning/error politikája; végül `validate-on-execute` biztonsági invariáns és inspect/repair parancs a részleges lifecycle állapotokhoz.

## 16. Evidence index

Elsődleges forráscsoportok:

- `pyproject.toml`, `src/specify_cli/__init__.py`, `src/specify_cli/commands/init.py`: csomag, CLI, bootstrap;
- `templates/commands/*.md`, `templates/*.md`, `scripts/{bash,powershell,python}/*`: kanonikus parancsok és artifactok;
- `src/specify_cli/integrations/*`: 37 adapter, renderelés, manifest/tulajdon;
- `src/specify_cli/extensions/*`, `presets/*`, `bundler/*`: komponens-életciklus és kompozíció;
- `src/specify_cli/events.py`: feloldás, dispatcher, adapter-timeout és refresh;
- `src/specify_cli/workflows/*`, `workflows/speckit/workflow.yml`: motor, state, step-ek, overlay-k;
- `src/specify_cli/_download_security.py`, `authentication/*`, `_github_http.py`, `_version.py`: biztonsági és operációs határok;
- `.github/workflows/*`, `.github/aw/actions-lock.json`: CI és agentic supply chain;
- `tests/**/*`: 157 tracked fájl, 152 Python, 4 230 statikus definíció, 6 388 collectált eset.

Auditálható kutatási artifactok:

- [gear-semantic-ledger.csv](../work/evidence/github-spec-kit/gear-semantic-ledger.csv) — 525/525 fájl, SHA-256, módszer, szinopszis, source locator és referencia-kapcsolat;
- [reference-ledger.csv](../work/evidence/github-spec-kit/reference-ledger.csv) — 5 945 referencia source/line/kind/target/terminal/evidence mezőkkel;
- [bundle-broken-references.md](../work/evidence/github-spec-kit/bundle-broken-references.md) — mind a 16 confirmed-broken bundle-hivatkozás;
- [closure-summary.md](../work/evidence/github-spec-kit/closure-summary.md) — terminális és referenciatípus összesítés, módszerhatár;
- [critical-counts.md](../work/evidence/github-spec-kit/critical-counts.md) — integráció/katalógus/test/action pinning számlálási módszerek;
- [targeted-pytest-20260802.md](../work/evidence/github-spec-kit/targeted-pytest-20260802.md) — friss targeted pytest parancs és eredmény;
- [javított angol kutatási report](../work/research/github-spec-kit-agent-report.md) — teljes részletes háttéranyag.

Végső értékelés: a Spec Kit érett, jó mintákat adó agent-operating-procedure fordító és workflow-host, de nem sandbox vagy security policy engine. Biztonságos újrafelhasználáskor az approval gate-eket, ownership manifesteket, atomi állapotot és adapterhatárokat érdemes megtartani; a direct execution validálását, event observabilityt, bundle-példák konzisztenciáját és a monolitikus control plane-ek javíthatóságát szigorítani kell.

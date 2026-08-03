# Fission OpenSpec — agent-architektúra dosszié

## 1. Pillanatkép és bizonyítási alap

| Mező | Rögzített érték |
|---|---|
| Repository | `Fission-AI/OpenSpec` |
| Commit | `45cca5db6137ed209117cc70510eb3e057fb981b` |
| Branch / upstream | `main` / `origin/main` |
| Worktree | tiszta |
| Csomagverzió | `1.7.0` |
| Runtime | ESM, Node `>=20.19.0` [45cca5d:package.json:L1-L23] |
| Tracked fájl | 1 041 |
| Szemantikai gear | 1 036 |
| Nem-gear média | 5 |
| Típusos referenciaél | 2 441 |
| Általánosan feloldatlan referencia | 0 |
| Igazolt törött belső referencia | 1, történeti archívumban |

A `work/evidence/fission-openspec/semantic-ledger.csv` minden gearhez rögzíti az útvonalat, SHA-256-ot, méretet, sorszámot, szemantikai szerepet, elemzési állapotot, terminálosztályt és immutable teljes-fájl evidence locatort. Az 1 036 sorból 1 035 `analyzed`; a `flake.lock` `runtime-relevant-generated`. Az öt kizárt média pontosan négy `assets/` kép és a `website/app/icon.svg`.

A `work/evidence/fission-openspec/reference-ledger.csv` 2 441 detektált élt osztályoz. A generátor (`generate-ledgers.mjs`) tiltja a generikus `unresolved` végállapotot; a valóban hibás éleket külön `confirmed-broken-references.csv` őrzi. Ez a rögzített osztályokra teljes, reprodukálható referenciazárás, nem állítás külső URL-ek élő tartalmáról.

A repository 139 128 sora főként 636 Markdown- és 315 TypeScript-fájlban található. A publikált npm-határ jóval kisebb: csak `dist`, `bin`, `schemas` és `scripts/postinstall.js` kerül a csomagba [45cca5d:package.json:L24-L40].

## 2. Vezetői összefoglaló

Az OpenSpec local-first TypeScript CLI, amely deklaratív artifact gráfból agent által fogyasztható utasításokat és host-integrációkat fordít. Nem rezidens agent-runtime: nincs modellkliens, beszélgetéstár, autonóm scheduler vagy belső subagent-orchestration. A CLI állapotot olvas, instrukciót generál és néhány szűk műveletet maga hajt végre; a tényleges tervezést és implementációt a külső AI host végzi.

Az alapgráf: `proposal -> {specs, design} -> tasks -> apply`. Hat core workflow (`propose`, `explore`, `apply`, `update`, `sync`, `archive`) és hat további workflow (`new`, `continue`, `ff`, `bulk-archive`, `verify`, `onboard`) alkotja a 12 termékfolyamatot [45cca5d:src/core/profiles.ts:L14-L50]. Ezekből Agent Skills és — ahol adapter van — tool-native command fájlok készülnek.

A legerősebb minták:

- átlátható, fájlrendszerből újraszámított állapot;
- determinisztikus DAG és readiness;
- canonical workflow-tartalom, vékony host-adapterek;
- strukturált root provenance minden gépi válaszban;
- Git/network műveletek szűk, explicit határai;
- destruktív archive előtt preview és újraellenőrzés.

A fő nyitott forráshiba a teszt- és konfiguráció-izoláció. Külső harness alatt a teljes suite biztonságosan zöld, de a repository alapértelmezett tesztfolyamata és egy normál első CLI-futtatás Windows alatt továbbra is elérheti a valódi `%APPDATA%\openspec\config.json` fájlt.

## 3. Csomag, CLI és AI-integrációs felület

A csomag ESM, a `bin/openspec.js` a buildelt `dist/cli/index.js` belépőt tölti be [45cca5d:bin/openspec.js:L1-L5]. Friss source checkoutból ezért közvetlenül nem fut: előbb build szükséges. A top-level CLI felületei: `init`, `update`, `list`, `view`, `archive`, `config`, `schema`, `store`, `doctor`, `context`, `workset`, `validate`, `show`, `feedback`, `completion`, `status`, `instructions`, `templates`, `schemas`, `new change`, valamint a deprecated `change` és `spec` [45cca5d:src/cli/index.ts:L155-L195] [45cca5d:src/cli/index.ts:L218-L428] [45cca5d:src/cli/index.ts:L430-L658].

A gépi hibák normál esetben egyetlen JSON-dokumentumon, diagnózissal és nem nulla státusszal távoznak. A hidden completion kivétel: shell-completion közben csendre optimalizál és részletes diagnózis nélkül ad exit 1-et [45cca5d:src/cli/index.ts:L68-L92] [45cca5d:src/cli/index.ts:L545-L556].

Az `AI_TOOLS` 35 célt tartalmaz [45cca5d:src/core/config.ts:L22-L64]. A materializáció két független tengelyből áll:

1. globális kért `Delivery`: `skills`, `commands` vagy `both`, alapértéke `both` [45cca5d:src/core/global-config.ts:L10-L33];
2. célonkénti `CommandSurfaceCapability`: `adapter-backed`, `skills-invocable` vagy `none` [45cca5d:src/core/command-surface.ts:L5-L27].

Adapter-backed cél commands-only módban commandot kaphat; normál cél skills-only vagy both módban skillt kap. Codex kivétel: skills-invocable, ezért commands-only kérésnél is skillt kap. A hat no-adapter/non-Codex cél (`CodeArts`, `ForgeCode`, `Hermes`, `Kimi`, `Mistral Vibe`, shared `.agents`) skills/both alatt skillt kap, commands-only alatt viszont nincs használható generált felülete [45cca5d:src/core/command-surface.ts:L29-L42].

A 28 command adapter: Amazon Q, Antigravity, Auggie, Bob, Claude, Cline, CodeBuddy, Continue, CoStrict, Crush, Cursor, Devin, Factory, Gemini, GitHub Copilot, iFlow, Junie, Kilo Code, Kiro, Lingma, Oh My Pi, OpenCode, Pi, Qoder, Qwen, Roo Code, Trae és ZCode. A központi registry teljes listája [45cca5d:src/core/command-generation/registry.ts:L1-L73].

## 4. Architektúra és tulajdonosi határok

A rendszer rétegei:

1. CLI routing és output contract;
2. globális/projekt konfiguráció;
3. root selection;
4. schema és DAG betöltés;
5. artifact state és instrukciógenerálás;
6. init/update/archive/store/workset szolgáltatások;
7. skill/command rendering;
8. opt-out telemetria.

A fő kontrollhatár az OpenSpec determinisztikus koordinátora és a külső AI végrehajtó között van. A CLI nem értelmez modellválaszt, és nem ütemez autonóm agente(ke)t. A host agent új fájlt ír; a következő CLI-hívás a diszkről újraszámítja a state-et.

Az állapotszkópok elkülönülnek:

- repository: `openspec/config.yaml`, current specs, active/archive changes;
- változás: `.openspec.yaml` és proposal/spec/design/tasks artifactok;
- gépi konfiguráció: profil, delivery, feature flags, default store;
- gépi adat: user schema, store registry, workset;
- generált host-felület: skill és command fájlok.

Windows alatt a globális config `%APPDATA%`, a globális data `%LOCALAPPDATA%`; explicit XDG változók elsőbbséget élveznek [45cca5d:src/core/global-config.ts:L36-L109].

## 5. Események, állapotátmenetek és control loopok

A beépített schema deklarálja a DAG-ot: `proposal`; az arra épülő `specs` és `design`; a mindkettőt igénylő `tasks`; végül a `tasks`-ot követő `apply` [45cca5d:schemas/spec-driven/schema.yaml:L1-L208]. A loader elutasítja az ismeretlen referenciát, duplikált artifact ID-t és ciklust [45cca5d:src/core/artifact-graph/schema.ts:L15-L44] [45cca5d:src/core/artifact-graph/schema.ts:L81-L123]. A topologikus sorrend stabil, a kész testvéreknél deklarációs sorrendet tart [45cca5d:src/core/artifact-graph/graph.ts:L23-L37] [45cca5d:src/core/artifact-graph/graph.ts:L95-L138].

Az artifact státuszai:

- `done`: minden deklarált output/glob létezik;
- `ready`: hiányzik, de minden dependency kész;
- `blocked`: legalább egy dependency hiányzik;
- `skipped`: a change metadata alapján kihagyott specs.

A készültség fájllétezésből származik, nem adatbázisjelzőből [45cca5d:src/core/artifact-graph/state.ts:L6-L36]. A host loop: `status/instructions` → korlátok és kontextus olvasása → artifact/kód írása → új `status` → folytatás vagy stop.

A Commander `preAction` megjelenítheti a telemetry notice-t és queue-zza az eseményt; a `postAction` flushol [45cca5d:src/cli/index.ts:L118-L146]. A payload szűk, `$ip: null`, és lokális anonim ID-t használ [45cca5d:src/telemetry/index.ts:L91-L107] [45cca5d:src/telemetry/index.ts:L145-L161].

## 6. Agentek, szerepek, personák, skillek és hookok

Nincs belső multi-agent runtime, subagent-hierarchia, plugin manager vagy tool-calling engine. Az „agent” három dolgot jelent:

1. külső coding assistant, amely generált skillt/commandot fogyaszt;
2. workflow-szövegben kódolt viselkedési persona;
3. repository maintainer, aki a release skillt követi.

A 12 termék-workflow canonical TypeScript generátorból készül [45cca5d:src/core/shared/skill-generation.ts:L59-L106]. A commitolt `skills/openspec-*` könyvtárakat a generator újraépíti, ellenőrzött könyvtárakra korlátozott törléssel [45cca5d:scripts/generate-skillssh.mjs:L1-L47]. A tartalmi parity SHA-256-alapú.

A 13. skill, `.agents/skills/release-openspec/SKILL.md`, repository-maintainer release state machine: GitHub/Changesets állapotot olvas, stable/beta csatornát kezel, és publikálás előtt emberi approvalt kér [45cca5d:.agents/skills/release-openspec/SKILL.md:L1-L180]. Nem része az `openspec init` termékgráfjának.

Hook-szerű pontok: Commander pre/post action, npm prepare/prepublish/postinstall, GitHub Actions és a website build előtti doc-sync. Általános alkalmazás-hook framework nincs.

## 7. Végrehajtási folyamatok és mutációs sorrend

Az `init` permission/path ellenőrzést, kontrollált legacy migrációt, tool-validációt, skill/command generálást és csak ezután cleanupot végez [45cca5d:src/core/init.ts:L133-L235]. Az `update` meglévő projektet követel, migrálja az ismert régi felületeket, újraszámítja profile/delivery állapotot, regenerál és eltávolítja a stale generált fájlokat [45cca5d:src/core/update.ts:L118-L190].

Schema-feloldás: project-local → user/global → package built-in. A schema deklarál artifact ID-ket, dependencyket, outputokat, template-eket és instrukciókat; az apply/archive műveletek kódban maradnak.

A store registry lockot és atomic update-et használ [45cca5d:src/core/store/registry.ts:L86-L119] [45cca5d:src/core/store/foundation.ts:L323-L348]. A store nem szinkronizál: Git init/első commit lehetséges, fetch/pull/push/divergence-kezelés nincs [45cca5d:src/core/store/git.ts:L12-L16]. A reference index read-only és egyszintű; self-reference kiesik, hibás registryhez diagnózis és sanitizált clone recipe készül [45cca5d:src/core/references.ts:L301-L444].

A workset külön személyes nézet. Az általános durable YAML-frissítés lock alatt, atomikusan történik [45cca5d:src/core/worksets.ts:L236-L275]. Törléskor előbb a durable state íródik, utána törlődik a derivált `.code-workspace` [45cca5d:src/core/worksets.ts:L339-L356]. Megnyitáskor lock alatt koherens state olvasódik, majd regenerálódik a derivált workspace és indul a tool [45cca5d:src/core/worksets.ts:L359-L401].

A specs-apply duplikációt és cross-section konfliktust detektál, kezeli az idempotens/already-applied eseteket [45cca5d:src/core/specs-apply.ts:L105-L199] [45cca5d:src/core/specs-apply.ts:L282-L398], és nem engedi figyelmeztetés nélkül elveszíteni a kapcsolódó prózát vagy scenario-kat [45cca5d:src/core/specs-apply.ts:L363-L428] [45cca5d:src/core/specs-apply.ts:L469-L522].

## 8. Üzemeltetés, lifecycle és release

Nincs `openspec uninstall`; a globális csomag eltávolítása után a felhasználó dönt a generált integrációk és az értékes `openspec/` tudás megtartásáról [45cca5d:docs/installation.md:L175-L191].

A store setup elutasítja a más Git repository belsejében levő pathot, validálja a noninteractive inputot [45cca5d:src/core/store/operations.ts:L299-L364], majd identity/planning fájlokat készít, opcionálisan Git-et inicializál, regisztrál, és hibánál visszagörgeti a saját maga által létrehozott pathokat/metadata-t [45cca5d:src/core/store/operations.ts:L574-L716]. A store remove előbb unregisterel, majd törli a checkoutot; törlési hiba esetén szándékosan orphan directory maradhat [45cca5d:src/core/store/operations.ts:L951-L1006].

A `docs/` az authoring source; a website manifest 26 oldalt képez URL-re és navigációra [45cca5d:website/docs.sync.config.mjs:L1-L76]. A sync újragenerálja a website tartalmat és provenance-t ad hozzá [45cca5d:website/scripts/sync-docs.mjs:L105-L182].

A CI több operációs rendszeren buildel és tesztel, külön quality/Nix/package gate-ekkel [45cca5d:.github/workflows/ci.yml:L47-L204] [45cca5d:.github/workflows/ci.yml:L229-L327]. A security workflow dependency review-t és prod/dev/website auditot futtat, SHA-pinned actionökkel [45cca5d:.github/workflows/security.yml:L26-L90]. A release Changesets-alapú és packolt CLI-verziót ellenőriz publikálás előtt [45cca5d:scripts/pack-version-check.mjs:L1-L110].

A Nix hash-frissítő neve `scripts/update-flake.sh`. Placeholderrel kikényszeríti a helyes hash kiírását, majd újrabuildel [45cca5d:scripts/update-flake.sh:L52-L101]. Korai hash-extract hibánál visszaállít, de a végső verification build hibája módosított `flake.nix`-et hagyhat [45cca5d:scripts/update-flake.sh:L66-L107].

## 9. Tesztelés, biztonság és hibaviselkedés

A pinned fában 119 tracked TypeScript test/spec fájl van: 118 a `test/` alatt, egy máshol. Az izolált Vitest-futás ugyanazt a 119/119 fájlt gyűjtötte és futtatta. A kb. 2 429 `it`/`test` deklaráció és 605 mock/spy/fake találat lexikális skálamutató; nem azonos a parametrizált runtime-esetszámmal.

A Vitest fork workeröket használ, legfeljebb négyet vagy `VITEST_MAX_WORKERS` értéket, 10 másodperces test/hook timeouttal. Coverage reporter van, minimum threshold nincs [45cca5d:vitest.config.ts:L1-L35]. A suite nem mock-only: valódi CLI subprocess és ideiglenes Git repository integrációk is vannak.

Biztonsági határok:

- helyi CLI, nincs server/listener/daemon;
- repository schema/template/artifact untrusted input;
- child process argumentek tömbként mennek, nem shell-konkatenálva;
- telemetria nem küld IP-t vagy projekttartalmat;
- store hálózati szinkron nincs;
- archive destruktív lépés előtt preview/validáció történik.

Kritikus gyengeség: az instruction loader projektconfig-hibánál context/rules nélkül folytat [45cca5d:src/core/artifact-graph/instruction-loader.ts:L343-L347]. Agent-facing rendszerben ez veszélyesebb lehet, mint az explicit fail-fast.

## 10. Runtime-verifikáció

Minden ellenőrzés a pinned commiton, Windows/PowerShell környezetben történt. A repository pnpm 9.15.9-et rögzít; a harness ezt `npx --yes pnpm@9.15.9` útvonalon használta.

| Ellenőrzés | Eredmény |
|---|---|
| install/build | pass; 287 csomag; exit 0 |
| `tsc --noEmit` | pass |
| ESLint | pass |
| skill template/parity/invocation fókuszteszt | 3 fájl, 35 teszt, pass |
| izolált teljes suite | 119/119 fájl; 3 450 passed; 24 skipped; exit 0 |
| CLI `--version` | `1.7.0` |
| `schemas --json` | egy `spec-driven` schema |
| `list --json` | 19 aktív change; root source `nearest` |
| `status --change fix-spec-parser-fidelity --json` | `isComplete: true`; négy planning artifact `done`; root source `nearest` |
| `validate --specs --strict --json` | 36/36 pass |
| prod audit high threshold | nincs ismert vulnerability |
| `npm pack --ignore-scripts --dry-run` | 366 fájl, várt publish rootok |

Az authoritative teljes futás környezete: `OPENSPEC_TELEMETRY=0`, `VITEST_MAX_WORKERS=2`, ideiglenes `APPDATA`, `LOCALAPPDATA`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME`. Eredmény: 142,57 s Vitest, 147,5 s wall time; a valódi user config végig hiányzott. Bizonyíték: `work/evidence/fission-openspec/full-suite-20260802.md` és `full-suite.stdout.log`. Az exit 0 process metadata; nem állítjuk, hogy az `EXIT_CODE=0` szó szerint a stdoutban szerepel.

## 11. Dokumentációs drift és referenciazárás

Igazolt drift:

1. A stores guide szerint a `view` nem store-aware, miközben a source regisztrál store opciót és root selectiont [45cca5d:docs/stores-beta/user-guide.md:L338-L340] [45cca5d:src/cli/index.ts:L319-L334].
2. Az agent-contract root listájából szintén hiányzik a `view` [45cca5d:docs/agent-contract.md:L28-L36].
3. Egy történeti link törött: `openspec/changes/archive/2025-08-11-add-complexity-guidelines/specs/openspec-docs/README.md:342` nem létező `../docs/capability-organization.md` célra mutat.

A team guide „never touches git” állítása az átlagos project/change flowra igaz, de a teljes CLI-re túl tág, mert a store setup opcionálisan `git init`-et és első commitot végez. A JSON casing split ismert és dokumentált: store-family snake_case, workflow-family camelCase [45cca5d:docs/agent-contract.md:L5-L10].

A típusos ledger 2 441 élt zár le: 1 140 tracked file/directory feloldás, továbbá generált build artifact, runtime builtin, external package/action/URL, package boundary, document anchor, automation command és prose/code example terminálok. `generic unresolved = 0`; `confirmed broken = 1`. Külső endpointokat a kutatás nem fetch-elt.

## 12. Újrahasznosítható minták

1. Filesystem-derived state: diffelhető, sessionfüggetlen.
2. Deklaratív DAG stabil topologikus rendezéssel.
3. Három külön döntés: workflow profile, globális delivery, cél capability.
4. Canonical renderer és vékony adapterek.
5. Content-addressed generated parity.
6. Explicit agent stopping rule workflow-nként.
7. Strukturált instrukciómezők: context, rules, template, dependency külön.
8. Root provenance minden gépi válaszban.
9. Trust boundary-khez sanitizált diagnózis és actionable fix.
10. Git/network műveletek negatív capability-határa.
11. Destruktív sync/archive előtt preview és rebuilt validation.
12. Durable workset-state előbb, derivált workspace utána.

## 13. Hiányok, kockázatok és prioritások

Magas prioritás:

- a tesztek és subprocessok default config/data rootja nincs izolálva;
- projekt instruction config hiba silent degradationt okozhat;
- prompt compliance a host agentnél kooperatív, nem enforce-olt;
- store remove és más többfázisú mutációk részleges állapotot hagyhatnak.

Közepes prioritás:

- command capability dokumentáció kézi és driftel;
- JSON casing családonként eltér;
- package-manager pin lifecycle-környezetben nem mindig önkikényszerítő;
- source CLI build nélkül nem indul;
- sok befejezett change aktív könyvtárban marad;
- reference traversal szándékosan csak egy szint.

Alacsonyabb prioritás:

- completion hiba diagnózis nélkül távozik;
- nincs coverage threshold;
- platform-condition skip miatt Unix CI szükséges;
- postinstall minden hibát elnyel;
- Nix hash update csak részlegesen tranzakciós;
- top-level `AGENTS.md` üres;
- implicit cwd compatibility meglepő lehet.

## 14. Nyitott tételek és bizonyítási korlátok

- A valós user config leak **forrásszinten nincs javítva**. A biztonságos teljes suite izolációját külső harness adta [45cca5d:test/commands/spec.test.ts:L58-L68] [45cca5d:test/telemetry/index.test.ts:L14-L23] [45cca5d:src/telemetry/index.ts:L167-L184] [45cca5d:src/telemetry/config.ts:L131-L163].
- A helyes javítás: tesztfolyamatonként injectált ideiglenes config/data root és negatív assertion arra, hogy a valódi user path változatlan.
- Külső registryk és dokumentációs URL-ek tartalmát a kutatás nem ellenőrizte; a remote state idővel változhat.
- Interaktív TUI flow-k source/test alapján lettek vizsgálva, nem minden terminálon kézzel.
- Nem történt global install, store clone/pull, telemetry transmission, GitHub release vagy package publish.
- A multi-agent runtime hiánya exhaustive tracked-source/symbol keresésen alapul, és nem állít semmit a külső host toolok belső működéséről.
- A történeti proposalok superseded tervet is leírhatnak; current source/spec/test elsőbbséget kapott.

## 15. Evidence index

Leltár és futtatás:

- `work/evidence/fission-openspec/semantic-ledger.csv`
- `work/evidence/fission-openspec/reference-ledger.csv`
- `work/evidence/fission-openspec/confirmed-broken-references.csv`
- `work/evidence/fission-openspec/ledger-summary.md`
- `work/evidence/fission-openspec/generate-ledgers.mjs`
- `work/evidence/fission-openspec/full-suite-20260802.md`
- `work/evidence/fission-openspec/full-suite.stdout.log`

Kritikus source bizonyíték:

- package/CLI/config: [45cca5d:package.json:L1-L92] [45cca5d:src/cli/index.ts:L68-L146] [45cca5d:src/core/global-config.ts:L10-L109]
- artifact DAG/state/instructions: [45cca5d:schemas/spec-driven/schema.yaml:L1-L208] [45cca5d:src/core/artifact-graph/graph.ts:L23-L192] [45cca5d:src/core/artifact-graph/state.ts:L6-L36] [45cca5d:src/core/artifact-graph/instruction-loader.ts:L76-L393]
- target/delivery/adapter: [45cca5d:src/core/config.ts:L22-L64] [45cca5d:src/core/command-surface.ts:L5-L42] [45cca5d:src/core/command-generation/registry.ts:L1-L73]
- root/store/reference/workset: [45cca5d:src/core/root-selection.ts:L392-L503] [45cca5d:src/core/store/operations.ts:L299-L716] [45cca5d:src/core/references.ts:L301-L444] [45cca5d:src/core/worksets.ts:L236-L401]
- spec/archive safety: [45cca5d:src/core/specs-apply.ts:L105-L522] [45cca5d:src/core/archive.ts:L353-L435] [45cca5d:src/core/archive.ts:L693-L719]
- CI/release/security: [45cca5d:.github/workflows/ci.yml:L47-L327] [45cca5d:.github/workflows/release-prepare.yml:L20-L90] [45cca5d:.github/workflows/security.yml:L26-L90]
- telemetry/isolation: [45cca5d:src/telemetry/index.ts:L41-L187] [45cca5d:src/telemetry/config.ts:L131-L163] [45cca5d:test/commands/spec.test.ts:L58-L68] [45cca5d:test/telemetry/index.test.ts:L14-L23]

## 16. Végső értékelés

Az OpenSpec agent-facing architektúrája szokatlanul auditálható: deklaratív artifactok, fájlrendszerből származtatott state, determinisztikus dependency resolution és generált host-integrációk alkotják a control plane-t, beágyazott proprietary agent-runtime nélkül. A 1 036 soros szemantikai ledger és a 2 441 éles típusos referencia-ledger a pinned repositoryt mechanikusan és osztályozottan lezárja; általánosan feloldatlan él nincs, az egyetlen igazolt törött link külön látható.

A build, strict 36/36 spec-validáció és az izolált 119/119 fájlos teljes suite erős működési bizonyíték. A rendszer ugyanakkor még nem kezelhető fail-closed agent contractként, amíg a hibás projekt-instrukció fallback és a default teszt/config izoláció nincs forrásban javítva. A legnagyobb rövid távú érték: test-owned config/data root, negatív user-path assertion, generated capability matrix és szigorú instruction-config hiba.

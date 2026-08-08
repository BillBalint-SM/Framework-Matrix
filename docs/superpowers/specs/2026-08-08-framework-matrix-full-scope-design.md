# Framework-Matrix teljes kutatási scope és core-contract design

**Státusz:** felhasználó által jóváhagyott design

**Dátum:** 2026-08-08

**Repository:** `Framework-Matrix`

**Érvényesség:** az öt kijelölt SDD-framework legfrissebb hivatalos stabil release-ének következő teljes kutatási kampánya

## 1. Döntési összefoglaló

A Framework-Matrix nem teljes frameworköket választ ki vagy telepít. Az öt jelöltet bizonyítékforrásként vizsgálja, hogy tételesen megállapítható legyen:

- mi található bennük;
- hogyan működnek;
- mely megoldásaik bizonyítottan hasznosak;
- mely elemek anti-patternek vagy kockázatosak;
- mely mechanizmusok alakíthatók később vendorsemleges, ABK-native komponenssé.

A kutatás kanonikus alapja jelöltenként a kampány indításakor elérhető legfrissebb hivatalos, nem prerelease stabil kiadás, teljes commit SHA-ra feloldva. A teljes repository fájlcenzust kap; minden működést befolyásoló elem teljes szemantikai elemzést. A kanonikus kutatási eredmény normalizált JSONL evidence graph, amelyből ellenőrzött emberi dossziék készülnek.

A 15 dimenziós core-contract minden session, feladat és work unit kötelező nulladik lépése. A contract verzió- és hash-kötött, kampányon belül immutable, és csak explicit felhasználói jóváhagyással változhat.

## 2. Vizsgált jelöltek

| Candidate ID | Repository |
|---|---|
| `github-spec-kit` | `github/spec-kit` |
| `fission-openspec` | `Fission-AI/OpenSpec` |
| `open-gsd-gsd-core` | `open-gsd/gsd-core` |
| `christopherkahler-paul` | `ChristopherKahler/paul` |
| `bmad-method` | `bmad-code-org/BMAD-METHOD` |

## 3. A stabil snapshot szerződése

Minden jelöltnél a kutatás megkezdésekor végrehajtandó release-feloldás:

1. Azonosítani kell a repository hivatalos release-forrását.
2. A legfrissebb stabil kiadást kell kiválasztani.
3. Alpha, beta, RC, nightly, canary, preview, `next` és más prerelease csatorna kizárt.
4. A release taget teljes commit SHA-ra kell feloldani.
5. Egyeztetni kell a release taget, a package-verziót és a repository verzióforrásait.
6. Rögzíteni kell a release dátumát, URL-jét, package registryjét és freeze-időpontját.
7. A checkout teljes tartalmáról determinisztikus snapshot-hash készül.
8. A freeze után megjelenő release nem mozgatja el automatikusan a kampány scope-ját.

A fájlcenzus univerzuma külön kezeli:

- a rögzített commit `git ls-tree -r --full-tree` által visszaadott teljes tracked fájlkészletét;
- a hivatalos release package teljes kicsomagolt fájlkészletét;
- a submodule- és LFS-pointereket;
- a repository és a release package közötti packaging deltát;
- a dinamikus próbák során létrejövő generated/runtime artefaktumokat.

A `.git` object database, a kutató gépének cache-e és az izolált setup ideiglenes dependency-tára nem repositoryfájl. Ezek csak akkor kerülnek evidence-ként nyilvántartásba, ha a vizsgált működés kifejezetten használja vagy módosítja őket.

A korábban publikált Framework-Matrix snapshotok történeti bizonyítékok maradnak. Az új latest-stable kutatás nem írhatja át vagy minősítheti át őket csendben.

## 4. Platform- és hosthatár

### 4.1 Dinamikus scope

Az első kampány egyetlen dinamikusan bizonyított platform- és hostkombinációja:

- Windows;
- PowerShell;
- Codex mint élő AI coding host.

Nem használható WSL, Linux- vagy macOS-VM, container, emuláció vagy szimulált platformteszt. Claude Code, Cursor, Copilot, Windsurf, Roo, Cline és más AI-host nem kap élő agentfuttatást ebben a kampányban.

### 4.2 Metadata-scope

A deklarált Linux-, macOS-, Bash-, IDE- és más hosttámogatást továbbra is rögzíteni kell. Vizsgálandók a Windowsra ható:

- cross-platform elágazások;
- path- és case-kezelés;
- shell-dispatch;
- newline- és encoding-viselkedés;
- executable bit és permission feltételezések;
- generált host-layoutok;
- parity-szerződések.

Nem futtatott platform vagy host státusza `DECLARED_ONLY`, `OUT_OF_RUNTIME_SCOPE` vagy `NOT_RUN_HOST_OUT_OF_SCOPE`. `REPRODUCED` csak a tényleges Windows/PowerShell/Codex futásra használható.

## 5. Core-contract

### 5.1 Kötelező dimenziók

| ID | Vizsgálati dimenzió |
|---|---|
| `CC-01` | Funkció és felhasználói cél |
| `CC-02` | Trigger, input, output és side effect |
| `CC-03` | Workflow, state és terminálási modell |
| `CC-04` | Agent, role, tool és authority modell |
| `CC-05` | Config, precedence és scope-kezelés |
| `CC-06` | Artefaktum-, adat-, memória- és reference-kezelés |
| `CC-07` | Install, initialize, update, migrate, recover és uninstall |
| `CC-08` | Hibakezelés, retry, rollback, idempotencia és megszakítás |
| `CC-09` | Security, trust boundary, secret-, path- és inputkezelés |
| `CC-10` | Observability, log, audit, provenance és evidence |
| `CC-11` | Teljesítmény, futási overhead, context- és tokenhasználat |
| `CC-12` | Windows-, PowerShell-, filesystem- és hostkompatibilitás |
| `CC-13` | Tesztelhetőség, karbantarthatóság és bővíthetőség |
| `CC-14` | Licenc, eredet, supply chain és dependency-kockázat |
| `CC-15` | Dokumentáció–kód–config–teszt konzisztencia |

Minden dimenzióhoz tény, bizonyítékszint, forráshivatkozás, ismert korlát, failure mode és — ahol értelmes — reprodukciós eredmény tartozik.

### 5.2 Kötelező nulladik lépés

A repository-root `AGENTS.md` minden session, feladat és work unit előtt előírja:

1. `CORE-CONTRACT.md` betöltése.
2. Contract-verzió és SHA-256 ellenőrzése.
3. Contract receipt létrehozása.
4. Az érintett `CC-*` dimenziók meghatározása.
5. A nyitott research dependency-k ellenőrzése.
6. A munka scope-jának és engedélyeinek ellenőrzése.
7. Csak sikeres gate után indulhat érdemi munka.

A receipt legalább a contract verzióját, relatív útvonalát, SHA-256 hashét, az érintett dimenziókat, az elvárt evidence-t és a gate eredményét tartalmazza.

Minden receipt külön, schema-valid JSON-fájl a `registry/contract-receipts/` könyvtárban. Egy work unit csak a saját receiptjét hozhatja létre vagy módosíthatja. Ez elkerüli a párhuzamos JSONL-append konfliktust és tartósan bizonyítja, hogy mely contract alapján indult a munka.

### 5.3 Drift- és változáskezelés

- A core-contract egyetlen kanonikus forrásból olvasható.
- A `core-contract.schema.json` gépileg definiálja a dimenzióazonosítókat, kötelező mezőket és engedélyezett státuszokat.
- A `core-contract-index.json` a session-, task- és work-unit típusokat a kötelező `CC-*` dimenziókhoz, validatorokhoz és receipt-követelményekhez rendeli.
- Az `AGENTS.md`, feladatok és dossziék nem másolják a contract szövegét; stabil `CC-*` azonosítókra hivatkoznak.
- A contract a kampány alatt tartalmilag immutable.
- Módosítása explicit felhasználói jóváhagyást, új verziót és új SHA-256-ot igényel.
- A már elindult feladatok az eredeti contract-verzióhoz kötve maradnak.
- Új contract-verzió előtt impact analysis határozza meg az érintett rekordokat, coverage-réseket, újranyitandó benchmarkokat és migrációt.
- Korábbi eredmény nem írható át vagy minősíthető át csendben.
- A Git-történet őrzi a korábbi verziókat; párhuzamos kézi dokumentummásolat nem készül.

## 6. Kanonikus artefaktum-architektúra

```text
AGENTS.md
contracts/
  CORE-CONTRACT.md
  core-contract.schema.json
  core-contract-index.json

registry/
  candidates.jsonl
  contract-receipts/
    <receipt-id>.json
  candidates/
    github-spec-kit/
      snapshot.json
      files.jsonl
      technologies.jsonl
      software-dependencies.jsonl
      ecosystem.jsonl
      components.jsonl
      relations.jsonl
      evidence.jsonl
      research-dependencies.jsonl
      contract-mapping.jsonl
    fission-openspec/
    open-gsd-gsd-core/
    christopherkahler-paul/
    bmad-method/
  cross-candidate/
    patterns.jsonl
    anti-patterns.jsonl
    comparisons.jsonl
    research-dependencies.jsonl

schemas/
  candidate-snapshot.schema.json
  file-record.schema.json
  technology-record.schema.json
  software-dependency-record.schema.json
  ecosystem-record.schema.json
  component-record.schema.json
  relation-record.schema.json
  evidence-record.schema.json
  research-dependency-record.schema.json
  contract-mapping.schema.json
  contract-receipt.schema.json

reports/
  candidates/
    github-spec-kit.md
    fission-openspec.md
    open-gsd-gsd-core.md
    christopherkahler-paul.md
    bmad-method.md
  coverage-matrix.md
  dependency-backlog.md
  pattern-atlas.md
```

### 6.1 Igazságforrások

- A 15 dimenzió igazságforrása a `CORE-CONTRACT.md`.
- A gépi formák igazságforrása a JSON Schema-készlet.
- A jelölti tények igazságforrása a JSONL registry.
- A Markdown riportok registryből generált vagy ahhoz automatikusan validált nézetek.
- A bizonyíték nem duplikálódik: hash-, commit-, path-, sor-, parancs- vagy URL-lokátor kapcsolja a claimhez.

### 6.2 Adatfolyam

`stabil release → snapshot → fájlcenzus → komponensek → kapcsolatok → bizonyíték → research dependency-k → core-contract coverage → dosszié`

## 7. Jelöltenkénti adatszerződés

### 7.0 Közös rekordboríték

Minden JSONL rekord közös, kötelező azonosítási mezőket kap:

- `schemaVersion`;
- `contractVersion` és `contractSha256`;
- `snapshotId`;
- `candidateId`;
- rekordtípuson belül egyedi stabil ID;
- lifecycle vagy coverage státusz;
- kapcsolódó evidence ID-k;
- provenance;
- utolsó validáció eredménye.

Minden rekord ID-ja egyedi a teljes kampányban. Kereszthivatkozás csak létező, azonos snapshothoz tartozó ID-ra mutathat, kivéve az explicit cross-snapshot történeti és összehasonlító relációkat.

### 7.1 `snapshot.json`

Kötelező mezőcsoportok:

- candidate ID, név és owner;
- repository-, homepage- és dokumentációs URL;
- licenc és copyright;
- release-verzió, tag, dátum és URL;
- teljes commit SHA és default branch;
- freeze-időpont, snapshot ID és SHA-256;
- package-nevek és registryk;
- deklarált platformok, hostok és runtime-ok;
- Windows/PowerShell/Codex vizsgálati státusz;
- upstream freshness ellenőrzés.

### 7.2 `files.jsonl`

Minden repositoryfájl külön rekordot kap:

- path, név, extension és MIME;
- origin surface: `repository`, `release_package` vagy `generated_runtime`;
- méret, SHA-256, encoding, BOM és newline;
- symlink és executable státusz;
- programnyelv vagy adatformátum;
- generated, vendored, binary, asset és lockfile besorolás;
- funkcionális szerep és működési relevancia;
- Global–Project–Session–Local réteg;
- kapcsolódó komponensek;
- licenc és provenance;
- evidence- és coverage-státusz.

### 7.3 `technologies.jsonl`

Rögzítendő minden:

- program- és scriptnyelv;
- shell;
- runtime;
- compiler vagy interpreter;
- package manager;
- build-, test-, lint- és formatting tool;
- schema- és konfigurációs nyelv;
- minimális, ajánlott és lockolt verzió;
- verzióforrás;
- verzióütközés és dokumentációs drift;
- Windows-kompatibilitás és reprodukció.

### 7.4 `software-dependencies.jsonl`

Minden direct és transitive dependencyhez:

- package és ecosystem;
- deklarált constraint és resolved verzió;
- runtime/dev/build/optional/peer besorolás;
- közvetlen vagy tranzitív státusz;
- dependency-lánc;
- használt funkció;
- licenc;
- platformfeltétel;
- lifecycle script;
- deprecation vagy compatibility risk;
- mélyelemzés szükségessége és indoka.

### 7.5 `components.jsonl`

Kötelezően felismerendő komponensosztályok:

- CLI és executable entry point;
- command és script;
- plugin, extension és module;
- adapter és host integration;
- hook, trigger és event handler;
- skill és capability;
- agent, sub-agent, role és persona;
- prompt, instruction és operational document;
- workflow, step, gate és control loop;
- template és scaffold;
- generator és renderer;
- installer, initializer és updater;
- migrator, recovery és uninstaller;
- config, policy és precedence resolver;
- schema, manifest és registry;
- state store, cache, journal és memory;
- API, MCP és tool interface;
- test, fixture és oracle;
- CI/CD, release és automation;
- reference index és generated artefact.

Minden komponens kötelező funkcionális és működési mezői:

- cél és felhasználói haszon;
- trigger és aktiválási mód;
- előfeltételek;
- input és output schema;
- precondition és postcondition;
- döntési szabályok;
- olvasási és írási scope;
- side effectek;
- state-ek, transitionök és terminálási feltételek;
- agent-, role-, tool- és capability-határok;
- konfiguráció és precedence;
- hívó és hívott komponensek;
- generált, olvasott, módosított és törölt artefaktumok;
- success, failure, blocked és cancellation viselkedés;
- retry, timeout, rollback és idempotencia;
- recovery és folytathatóság;
- security és trust boundary;
- log, telemetry, audit és evidence;
- tesztlefedettség;
- teljesítmény-, context- és tokenhatás;
- korlátok és anti-patternek;
- `CC-01`–`CC-15` mapping;
- kapcsolódó evidence ID-k.

### 7.6 `ecosystem.jsonl`

Minden hivatalosan hivatkozott first-party, community és third-party plugin, module, extension, adapter, integration vagy companion külön metadatarekordot kap:

- ecosystem ID, név és típus;
- owner és source URL;
- verzió, release/tag és commit, ha elérhető;
- first-party, community vagy third-party minősítés;
- bundled, required vagy optional kapcsolat;
- install- és invocation-kapcsolat a core release-hez;
- támogatott hostok és platformok;
- licenc és trust státusz;
- elérhetőség: `available`, `moved`, `deprecated` vagy `broken`;
- mélyaudit státusza és indoka;
- kapcsolódó component-, relation-, evidence- és research-dependency ID-k.

### 7.7 `relations.jsonl`

Minden kapcsolat explicit, irányított edge. Kötelező relációtípusok:

- `contains`;
- `imports`;
- `calls` és `invokes`;
- `triggers` és `subscribes`;
- `delegates`;
- `reads`, `writes` és `deletes`;
- `generates`;
- `validates` és `checks`;
- `configures`;
- `installs`, `updates` és `migrates`;
- `references`;
- `depends_on`;
- `blocks`;
- `supersedes`;
- `compatible_with`;
- `conflicts_with`.

Minden edge tartalmazza a forrást, célt, irányt, feltételt, cardinalitást, futásidejű jelentést és evidence-t.

### 7.8 `evidence.jsonl`

Minden evidence rekord tartalmazza:

- a pontos claimet;
- a bizonyítékszintet;
- az evidence típusát;
- commitot, pathot és sorszámot;
- release-, PR-, issue- vagy dokumentációs URL-t;
- futtatási parancsot és sanitizált környezetet;
- platform-, PowerShell- és Codex-verziót;
- exit code-ot;
- stdout/stderr és output hashét;
- reprodukálhatóságot;
- ellentmondó evidence-t;
- scope- és biztonsági korlátot.

### 7.9 `research-dependencies.jsonl`

Minden bizonyítékhiány vagy blokkoló first-class rekord:

- stabil ID;
- típus és státusz;
- érintett jelölt, komponens és `CC-*` dimenzió;
- `dependsOn` és `blocks` kapcsolatok;
- súlyosság, prioritás és kockázat;
- hiányzó evidence;
- owner szerep;
- feloldási feltétel;
- következő végrehajtható lépés;
- `OPEN`, `BLOCKED`, `RESOLVED`, `ACCEPTED_GAP` vagy `OUT_OF_SCOPE` státusz.

### 7.10 `contract-mapping.jsonl`

Minden jelölt × komponens × core-contract dimenzió metszethez:

- coverage státusz;
- evidence ID-k;
- kapcsolódó research dependency-k;
- pozitív megoldások;
- anti-patternek;
- ismert korlátok;
- verdict.

## 8. Teljességi mélység és ökoszisztémahatár

### 8.1 Kétszintű teljesség

1. Minden fájl 100%-os fájlcenzust kap.
2. Minden működést befolyásoló elem 100%-os szemantikai elemzést kap.

Binary asset, lockfile, generált és vendored fájl nem maradhat ki. Sor- és működésmélységű elemzést akkor kap, ha hat a futásra, verziófeloldásra, biztonságra, generálásra vagy lifecycle-ra.

### 8.2 Reference- és dependency-határ

- Minden belső hivatkozást bizonyított végpontig kell követni.
- Minden közvetlen runtime-, build-, install- és fejlesztői dependency teljes elemzést kap.
- A tranzitív dependency teljes verziócenzust kap.
- Tranzitív vagy vendored dependency csak működési, biztonsági, generálási, verziófeloldási vagy failure-mode relevancia esetén kap forráskód-mélységű elemzést.
- Külső URL és dokumentációs hivatkozás registrybe kerül; teljes elemzést csak normatív vagy futásidejű forrás kap.
- Minden referencia végállapota `internal`, `generated`, `direct_dependency`, `transitive_dependency`, `external_normative`, `external_informational` vagy `broken`.

### 8.3 Ecosystem-határ

- A stabil release repositoryja és release package-e teljes mélyelemzést kap.
- Minden first-party komponens teljes mélyelemzést kap, amelyet a release tartalmaz, alapértelmezetten telepít, futáskor meghív, generál vagy kötelezően megkövetel.
- Minden hivatalos optional plugin, module, extension, adapter és integration bekerül az ecosystem registrybe.
- Külön repositoryban élő optional first-party komponens csak core-működési vagy pattern-bizonyítási relevancia esetén kap teljes auditot.
- Community és third-party elem teljes katalógust, de nem automatikusan teljes kódauditot kap.
- Nem elérhető vagy elmozdult elem `broken`, `moved` vagy `deprecated` státuszt kap.

## 9. Bizonyítási modell

### 9.1 Evidence-státuszok

| Státusz | Jelentés |
|---|---|
| `DECLARED` | Dokumentáció vagy szerzői állítás mondja |
| `IMPLEMENTED` | Kódban vagy konfigurációban megtalálható |
| `TESTED_UPSTREAM` | Upstream teszt bizonyítja |
| `REPRODUCED` | A Framework-Matrix környezetben ténylegesen reprodukált |
| `INFERRED` | Elemzői következtetés, külön jelölve |
| `UNKNOWN` | Nincs elegendő bizonyíték |
| `CONTRADICTED` | Az állítás és a megfigyelés eltér |

Az evidence erősségétől külön kezelendő execution/scope státuszok:

- `NOT_RUN`: a futás nem történt meg, pontos indok kötelező;
- `DECLARED_ONLY`: csak deklarált támogatás ismert;
- `OUT_OF_RUNTIME_SCOPE`: a platform vagy környezet a jóváhagyott runtime-scope-on kívül van;
- `NOT_RUN_HOST_OUT_OF_SCOPE`: a host metadata-scope-ban szerepel, de élő futtatása kizárt;
- `NOT_APPLICABLE`: az adott követelmény bizonyítottan nem értelmezhető a tárgyra.

A core-contract coverage engedélyezett állapotai `COVERED`, `PARTIAL`, `GAP`, `NOT_APPLICABLE` és `ACCEPTED_GAP`. `PARTIAL` vagy `GAP` kritikus dimenzióban nem enged `COMPLETE` jelölti állapotot; `ACCEPTED_GAP` kizárólag explicit emberi döntésből származhat.

### 9.2 Kockázatalapú runtime-bizonyítás

- Minden működési komponens statikus trace-et kap.
- Minden biztonságosan futtatható executable entry point legalább help, validation, dry-run vagy smoke próbát kap.
- Minden elsődleges workflow happy pathja fut.
- Releváns lifecycle-művelethez pozitív és failure-path evidence készül.
- Security boundaryhoz negatív vagy boundary teszt tartozik.
- Külső szolgáltatást, credentialt vagy destruktív műveletet igénylő viselkedés nem fut automatikusan; pontos `NOT_RUN` indokot kap.
- Upstream dokumentáció vagy teszt önmagában nem jogosít `REPRODUCED` státuszra.

### 9.3 Trianguláció

Minden működési állítás legalább egy elsődleges forráshoz kötődik. Kritikus állításnál lehetőség szerint együtt szükséges:

- kód vagy konfiguráció;
- upstream teszt;
- helyi reprodukció.

Ellentmondásnál egyik forrás sem írja felül automatikusan a másikat; `CONTRADICTED` evidence és research dependency keletkezik.

## 10. Történeti scope

A stabil snapshot a kanonikus vizsgálati tárgy. Célzott `git log`, `blame`, tag-, release-, PR- és diff-evidence készül, ha szükséges:

- egy mechanizmus eredetéhez;
- architekturális döntéshez;
- security vagy failure-mode javításhoz;
- migráció vagy compatibility layer megértéséhez;
- eltávolított vagy lecserélt megoldáshoz.

Nem része a scope-nak minden commit és pull request tételes elemzése. Minden történeti állítás külön evidence-rekordot kap.

## 11. Kutatási lifecycle

A jelölti állapotgép:

`DISCOVERED → PINNED → INVENTORIED → MAPPED → STATIC_VERIFIED → RUNTIME_VERIFIED → REVIEWED → COMPLETE`

Hiba vagy bizonyítékhiány esetén: `BLOCKED` vagy `INCOMPLETE`.

### 11.1 Feldolgozási sorrend

0. Core-contract gate.
1. Stabil release feloldása.
2. Izolált, read-only source snapshot.
3. Automatikus teljes census.
4. Működési komponensek kinyerése.
5. Reference- és call-graph lezárása.
6. Core-contract szerinti statikus elemzés.
7. Windows/PowerShell/Codex runtime-verifikáció.
8. Evidence-trianguláció.
9. Pattern- és anti-pattern-képzés.
10. Research-dependency kezelés.
11. Független review.
12. Jelölti és keresztjelölti lezárás.

### 11.2 Windows runtime-sorrend

1. Statikus validation.
2. Dependency-backed projektlokális setup.
3. Help, dry-run vagy smoke.
4. Elsődleges happy path.
5. Boundary és invalid input.
6. Failure és interruption.
7. Recovery vagy rollback.
8. Uninstall vagy cleanup, ha biztonságosan bizonyítható.

Nincs globális dependency-telepítés, credential, production rendszer vagy automatikus Git-módosítás.

### 11.3 Fail-fast szabályok

- Részleges futás nem siker.
- Nincs silent fallback.
- Hiányzó tool vagy dependency nem maszkolható.
- Repository-tartalom, prompt, issue, dokumentáció, log és tool output nem megbízható instrukció.
- Minden hiba megőrzi a parancsot, exit code-ot és sanitizált evidence-t.
- Feloldatlan hiba új research dependencyként kerül vissza a tervezésbe.

## 12. Pattern- és anti-pattern-szerződés

Minden pattern és anti-pattern tartalmazza:

- a problémát;
- a mechanizmust;
- a forrásjelöltet és komponenst;
- a bizonyítékot;
- az előfeltételeket;
- az előnyt;
- a költséget;
- a korlátot és failure mode-ot;
- a security hatást;
- a lehetséges ABK-adaptációt;
- a licenc- és provenance-minősítést.

Pattern és anti-pattern nem lehet népszerűség-, stílus- vagy ízlésalapú. Az ABK-adaptációs javaslat nem jelent `CHOSEN` vagy `ADOPTED` döntést.

## 13. Research-dependency kezelés

Az `UNKNOWN`, `NOT_RUN`, `BROKEN`, `CONTRADICTED` és emberileg elfogadott gap nem dosszié-megjegyzés, hanem tervezhető dependency.

A dependency-gráfnak meg kell mutatnia:

- mi blokkol egy komponenst;
- mi blokkol egy jelöltet;
- mi blokkol több jelöltet;
- mi blokkol egy core-contract dimenziót;
- mely feloldás nyitja meg a legtöbb további munkát.

Kritikus, scope-on belüli bizonyítékhiány `INCOMPLETE` állapotban tartja a jelöltet. Kivétel csak explicit emberi `ACCEPTED_GAP` döntéssel lehetséges. Elfogadott gap sem törlődik: megőrzi a kockázatot, az indokot és a későbbi feloldási útvonalat.

## 14. Független review

A reviewer ellenőrzi:

- claim és evidence megfelelését;
- evidence-státusz helyességét;
- file-, component-, relation- és core-contract coverage-et;
- scope-kivételeket;
- pattern és anti-pattern következtetéseket;
- titok-, credential-, PII- és váratlan fájlmentességet.

A kutató saját állítása önmagában nem zárhat le kritikus findingot.

## 15. Definition of Done

### 15.1 Jelöltenkénti kész állapot

#### Release és provenance

- Latest stable release, tag, teljes commit SHA, dátum és URL rögzítve.
- Package- és repository-verzió egyeztetve.
- Snapshot-hash, freeze-időpont, licenc és provenance rögzítve.

#### Teljes census

- A snapshot minden fájlja szerepel a registryben.
- Minden fájl besorolt.
- Minden nyelv, formátum, runtime és toolchain verzió rögzített.
- Minden direct és transitive dependency leltározott.
- Minden executable, script és lifecycle entry point azonosított.

Kötelező metrika:

`classified files / snapshot files = 100%`

#### Működési teljesség

- Minden működési jelentőségű fájl komponenshez kapcsolódik.
- Minden komponens teljes funkcionális rekordot kapott.
- Minden komponenshez tartozik `CC-01`–`CC-15` mapping vagy indokolt `NOT_APPLICABLE`.

Kötelező metrika:

`elemzett működési komponensek / azonosított működési komponensek = 100%`

#### Gráflezárás

- Minden belső hivatkozás és meghívás feloldott.
- Minden relation edge forrása, célja és típusa ismert.
- Minden végpont terminális státuszú.
- Broken és external kapcsolat evidence-hez vagy dependencyhez kötött.

Kötelező metrika:

`lezárt kapcsolatok / azonosított kapcsolatok = 100%`

#### Core-contract coverage

Mind a 15 dimenzióhoz van tény, evidence, korlát, verdict és — ahol releváns — reprodukció vagy jóváhagyott scope-kivétel. Nem maradhat besorolatlan dimenzió, indokolatlan `UNKNOWN`, indokolatlan `NOT_RUN` vagy evidence nélküli kritikus verdict.

#### Windows/PowerShell/Codex bizonyítás

- Minden biztonságosan futtatható entry point kap smoke vagy dry-run próbát.
- Az elsődleges workflow-k happy pathja reprodukált.
- Releváns boundary, invalid input és failure path vizsgált.
- Recovery vagy rollback vizsgálat készül, ahol létezik.
- Minden futás rögzíti a parancsot, környezetet, verziókat, exit code-ot és output-hash-t.
- Más platform vagy AI-host nem kap `REPRODUCED` státuszt.

#### Pattern, dependency és review

- Minden pattern és anti-pattern megfelel a bizonyítékszerződésnek.
- Minden bizonyítékhiány research dependency.
- Kritikus nyitott dependency mellett a jelölt `INCOMPLETE`.
- Schema-, coverage-, relation- és evidence-validáció sikeres.
- Független claim–evidence review elkészült.
- Nincs titok, credential, PII vagy váratlan upstream/production módosítás.
- A generált riport és a registry között nincs drift.

### 15.2 Projektszintű kész állapot

A teljes kutatási scope csak akkor `COMPLETE`, ha:

1. mind az öt jelölt `COMPLETE`;
2. a cross-candidate Pattern Atlas elkészült;
3. a keresztjelölti anti-pattern registry elkészült;
4. az összehasonlító core-contract coverage-mátrix teljes;
5. a közös research-dependency gráf valid;
6. minden gépi registry schema-valid;
7. minden emberi dosszié visszavezethető a kanonikus registryre;
8. a root `AGENTS.md` core-contract gate működik;
9. a contract receipt- és hash-ellenőrzés működik;
10. a végső scope-, diff- és security review nem talál eltérést.

### 15.3 Kész cél egy mondatban

> A Framework-Matrix kutatási scope-ja akkor kész, ha az öt jelölt legfrissebb stabil release-e rögzített commiton, teljes fájl- és komponensleltárral, lezárt működési gráffal, a 15 dimenziós core-contract szerint bizonyítékokkal feltárva, Windows/PowerShell/Codex környezetben arányosan reprodukálva és függetlenül review-zva rendelkezésre áll; továbbá minden jó megoldás, anti-pattern, bizonytalanság és feloldandó dependency kereshető, hivatkozható és géppel validálható.

## 16. Explicit out of scope

- Linux, macOS, WSL, VM vagy container runtime-vizsgálat.
- Nem Codex AI-hostok élő agentfuttatása.
- Minden community plugin teljes forráskódauditja.
- A teljes Git-történet commitonkénti elemzése.
- Credentialt vagy production szolgáltatást igénylő teszt.
- Globális dependency-telepítés.
- Upstream repository módosítása.
- Pattern automatikus `CHOSEN` vagy `ADOPTED` minősítése.
- Production ABK-integráció.

A `COMPLETE` ebben a designban a teljes jelölti tudás- és bizonyítékréteg elkészültét jelenti. A pattern-benchmark és az ABK-adoption külön, erre épülő döntési szakasz.

## 17. Fő kockázatok és kezelésük

| Kockázat | Kezelés |
|---|---|
| A latest verzió elmozdítja a kutatást | Stabil release freeze, tag, teljes SHA és snapshot-hash |
| Az ökoszisztéma korlátlanná teszi a scope-ot | Release-boundary, teljes ecosystem registry, relevanciaalapú mélyaudit |
| A fájlcenzus összekeveredik a szemantikai elemzéssel | Külön `files.jsonl` és `components.jsonl` |
| A code dependency összekeveredik a kutatási blokkolóval | Külön `software-dependencies.jsonl` és `research-dependencies.jsonl` |
| A Markdown és a registry eltér | Registry az igazságforrás, generált vagy validált riport |
| A core-contract driftel | Egyetlen forrás, stabil ID-k, verzió, hash, receipt és fail-closed gate |
| Nem futtatott platform működőnek látszik | Platformhoz kötött evidence-státusz; `REPRODUCED` csak tényleges futásra |
| Részleges futás sikerként jelenik meg | Fail-fast, exit code és output-evidence; nincs silent fallback |
| A hiányok elvesznek a narratívában | First-class research-dependency registry és gráf |
| Külső repository instrukcióként hat | Minden külső tartalom untrusted data; célzott scope- és security review |

## 18. Verifikációs kapuk

A megvalósításnak legalább a következő automatikus ellenőrzéseket kell biztosítania:

1. Core-contract schema és hash validation.
2. Contract receipt validation.
3. Snapshot file count és file-registry parity.
4. JSONL record schema validation.
5. File-to-component coverage.
6. Relation closure és dangling-edge check.
7. Evidence locator és hash validation.
8. Research-dependency graph validation és cycle reporting.
9. `CC-01`–`CC-15` coverage matrix.
10. Report-to-registry provenance és drift check.
11. Secret-, credential- és PII-scan.
12. Végső diff- és scope-review.

## 19. Megvalósítási határ

Ez a dokumentum a jóváhagyott design. Nem implementálja a root `AGENTS.md`-t, a core-contract fájlokat, a schema-készletet, a registryket, a validatorokat vagy az öt jelölt új kutatási kampányát.

A következő lépés a design felhasználói review-ja, majd külön részletes megvalósítási terv készítése kis, egymástól függetlenül ellenőrizhető szeletekkel. Commit, push, pull request vagy merge csak külön explicit engedéllyel történhet.

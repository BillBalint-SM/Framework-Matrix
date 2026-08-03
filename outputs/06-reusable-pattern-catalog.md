# Újrahasznosítható SDD framework-minták

## Vezetői döntés

Az öt jelöltből nem egy frameworköt telepítünk, futtatunk vagy fork-olunk. A repositoryk mintaforrások: a hasznos működési elvet leválasztjuk az upstream runtime-ról, az AI Booster Kit saját nevezéktanába és authority-modelljébe formáljuk, majd önálló ABK-hookként, skillként, scriptként, role-ként, workflow-ként vagy context template-ként prototipizáljuk. A statikus és upstream-runtime bizonyíték alapján legerősebb kutatási kiindulópontok:

1. **OpenSpec:** filesystem-derived `ArtifactGraph`, explicit root provenance és preview-alapú változtatás.
2. **GitHub Spec Kit:** canonical IR, tiszta materializálási terv, hash-alapú fájltulajdon és path-security.
3. **BMAD-METHOD:** content-addressed execution packet, strukturális konfigurációrétegek és ownership-aware host adapter.
4. **open-gsd/gsd-core:** descriptor registry, producer/checker szerződés, consent-bound project extension és manifest-scoped worktree.
5. **Paul:** PLAN–APPLY–UNIFY folyamatnyelv és egyszerű artefaktszerződés; az installációs és hivatkozási megoldás közvetlen átvételre nem alkalmas.

Az ajánlás nem forráskód-egyesítés és nem upstream adapterréteg. A közös empirikus tér a Codex. Az esetleges későbbi ABK host-adapterek a saját platform architektúrájához tartoznak, nem a vizsgált frameworkök runtime-ját közvetítik.

## Minősítési rendszer

| Jelölés | Jelentés |
|---|---|
| `S1 – közvetlen forrástény` | A működés a rögzített commit kódjából vagy konfigurációjából közvetlenül levezethető. |
| `S2 – triangulált` | A forrás mellett teszt, fixture vagy izolált futtatási eredmény is alátámasztja. |
| `S3 – elemzői következtetés` | A javasolt absztrakció vagy adaptáció több forrástényből következik, de egyik projektben sem létezik pontosan ebben a formában. |
| `MIT obligation` | Kód vagy jelentős szövegrész közvetlen átvételekor az adott copyright- és permission notice megőrzendő. |
| `Project provenance policy` | A célframework ezen felül minden direct reuse tételhez megőrzi az upstream repository/commit/file eredetet; ez belső auditpolicy, nem önálló MIT-követelmény. |
| `Clean-room adaptation` | A bizonyított működési elv új, saját implementációja; az eredeti név, persona és szöveg nem kerül át. |

### Adoptálási státusz és bizonyítási korlát

Az `S1`–`S3` jelölések az állítás bizonyítottságát, nem a komponens adoptálási minőségét mérik. A tényleges adoptálási skála külön szerződés:

| Státusz | Kötelező feltétel |
|---|---|
| `REJECTED` | Nem reprodukálható lokális Codex-környezetben, vagy bármely kritikus dimenzió összesített pontszáma legfeljebb 4. |
| `CANDIDATE` | A teljes tízes tesztmátrix lefutott, minden kritikus dimenzió legalább 5, a súlyozott átlag 8 alatti. |
| `CHOSEN` | A teljes tízes tesztmátrix lefutott, minden kritikus dimenzió legalább 5, a súlyozott átlag legalább 8. |
| `ADOPTED` | `CHOSEN` ABK-natív prototípus külön jóváhagyással tényleges platformkomponenssé vált. |

A jelen katalógus egyik mintát sem minősíti automatikusan `CHOSEN`-nek: az upstream repository tesztjei és a forráselemzés nem helyettesítik a baseline ↔ eredeti mechanika ↔ ABK-natív prototípus összehasonlítást. A lent felsorolt tételek a következő empirikus körbe javasolt kutatási minták.

Mind az öt repository MIT-licencű a vizsgált commiton (`d1e86f6:LICENSE:L1-L21`; `45cca5d:LICENSE:L1-L21`; `33985c1:LICENSE:L1-L21`; [Paul LICENSE](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/LICENSE#L1-L20); `770d425:LICENSE:L1-L30`). Közvetlen vagy lényeges rész átvételekor meg kell őrizni az adott copyright- és permission notice-t. A BMAD ezen felül külön trademark-szabályokat tart fenn a BMad megnevezésekre; ezért a vendorsemleges magban saját neveket kell használni (`770d425:TRADEMARK.md:L16-L25`). A clean-room megvalósítás itt mérnöki leválasztási és karbantarthatósági javaslat, nem az MIT licenc által kikényszerített követelmény.

## Rétegmodell

Az alábbi négy réteg teljes egészében **S3 célarchitektúra**. Nem állítja, hogy bármelyik upstream repository ugyanezt a négy, egymással egyenrangú scope-ot implementálja. A logikai owner és a fizikai fájlhely eltérhet: például personal config élhet a project tree-ben, session által módosított napló pedig lehet tartós Project artefakt. A precedence kulcsonként deklarált; a Global trust/policy kulcsok `forbidOverride`, ezért a későbbi scope nem jelent automatikusan nagyobb jogosultságot.

| Réteg | Tartós felelősség | Tiltott összecsúszás |
|---|---|---|
| **Global** | capability-, role-, schema-, package-, adapter- és trust-registry; szervezeti policy | Projektrepozitórium nem írhatja felül csendben a gépszintű trust/consent állapotot. |
| **Project** | verziózott manifest, artifact graph, workflow/role definíciók, generated ownership, migrációs napló | Session scratch vagy egyetlen host formátuma nem válhat canonical projektténnyé. |
| **Session** | `RunEnvelope`, program counter, context manifest, approval ledger, evidence log | Beszélgetési memória nem helyettesítheti a tartós projektállapotot. |
| **Local** | izolált worktree/sandbox, lock, cache, staging, scratch | Lokális cache vagy részleges render nem publikálható canonical állapotként. |

## 1. Filesystem-derived Artifact DAG

**Probléma.** Egy SDD-folyamat könnyen egy parancssorrá degradálódik: a host vagy a beszélgetés emlékszik arra, mi készült el, miközben a repositoryból nem vezethető le biztosan a readiness.

**Mechanizmus.** Minden artefakt típusa deklarálja a függőségeit, a saját sémáját, a létrehozási vagy ellenőrzési utasítását és a readiness-feltételét. A következő lépés nem egy elrejtett workflow-state-ből, hanem a lemezen ténylegesen létező, érvényes artefaktok és gráfélek alapján számítható. Az OpenSpec `spec-driven` schema ezt explicit artefaktlistával, dependency-élekkel és `apply` követelményekkel írja le (`45cca5d:schemas/spec-driven/schema.yaml:L1-L208`).

**Réteg:** Project; a Session csak a gráf egy rögzített verzióját használja.

**Trigger → input → output.** `artifact.created|updated|validated` → projektmanifest, schemas, jelenlegi artefaktok → új readiness-halmaz és következő engedélyezett műveletek.

**Állapot és terminálás.** Az állapot a gráf és a validált fájlhalmaz. Terminális a célprofil által megkövetelt minden node `valid` állapota; `blocked`, ha hiányzó vagy hibás dependency miatt nincs engedélyezett él.

**Failure semantics.** Ismeretlen node, ciklus, schema-hiba, hiányzó dependency vagy többértelmű artifact root esetén fail closed. A tool ne találja ki a hiányzó artefakt tartalmát.

**Forrás/provenance:** OpenSpec, S1; a profile-nevek és aliasok zárt registryből érkeznek (`45cca5d:src/core/profiles.ts:L14-L50`).

**Előfeltételek:** stabil artifact IDs; verziózott schema; determinisztikus root selection; minden node-hoz validator.

**Adaptáció:** először csak `goal → spec → design → tasks → evidence → review` gerincet vezessünk be. Az implementation fájlokat ne másoljuk a graph store-ba; linkeljük őket evidence-node-ként.

**Trade-off:** nagyfokú átláthatóság és resumability, de minden új artefakttípus schema- és migrációs költséget hoz.

**Reuse:** Clean-room adaptation ajánlott; a YAML-forma mintaként használható, de a saját domainhez kisebb schema készüljön.

## 2. Canonical IR → host-native adapterek

**Probléma.** Ha minden hosthoz külön parancs-, skill- és promptfa készül, a viselkedés szétágazik, a javításokat többször kell végrehajtani, és a host-specifikus korlátok belefolynak a domainlogikába.

**Megfigyelt forrásviselkedés (S1/S2).** A Spec Kit canonical command/template tartalmat integration-specifikus destinationre és invocation formára renderel; a GSD generált runtime descriptor registry adatként kezeli a host layoutot és capability-ket (`d1e86f6:src/specify_cli/integrations/base.py:L1533-L1603`; `33985c1:src/runtime-config-adapter-registry.cts:L120-L183`).

**Célmechanizmus (S3).** A vendorsemleges canonical representation egységesen tartalmazza a role-okat, workflow-steppeket, eventeket, capability-ket és artefaktszerződéseket. A host adapter kizárólag elhelyezést, frontmattert, command dialektust, hook deklarációt és explicit kompatibilitási degradációt végez. Ez a teljes, egyesített IR egyik forrásprojektben sem létezik pontosan ebben a formában.

**Réteg:** Global registry + Project-pinned adapter selection; a generált felület Project output.

**Trigger → input → output.** `adapter.preview|materialize|upgrade` → canonical package, host descriptor, resolved project config → host-native staged tree és ownership manifest.

**Állapot és terminálás.** A canonical package immutable verzió; az adapter output hash-elt generation. Siker csak akkor, ha parity/contract test igazolja a generált felületet.

**Failure semantics.** Ismeretlen host capability, collision, path escape vagy nem reprezentálható kötelező feature esetén hard error. Opcionális capability csak explicit `degraded` diagnosztikával maradhat el.

**Forrás/provenance:** a projection/descriptor tény Spec Kit + GSD S1/S2; az egységes IR és kizárólagos adapter-felelősség S3.

**Előfeltételek:** host-independent IDs; explicit capability matrix; golden/parity tesztek; stable target-path contract.

**Adaptáció:** a role/prompt szövegeket ne hostfájlként authoráljuk. Előbb typed canonical package, abból `codex`, `claude-code` és később más adapter.

**Trade-off:** megszünteti a kézi driftet, de maga az adapter compiler biztonságkritikus komponenssé válik.

**Reuse:** Clean-room core; izolált path/render utility közvetlenül is átvehető a megfelelő MIT notice mellett.

## 3. Tiszta `MaterializationPlan` és hash-alapú tulajdon

**Probléma.** Installer vagy generator futás közben dönti el, mit ír felül, ezért a preview és a tényleges végrehajtás eltérhet, az uninstall pedig user-owned fájlt törölhet.

**Megfigyelt forrásviselkedés (S1/S2).** A Spec Kit integrációs manifest hash-eket tárol, unsafe pathot és symlinket elutasít, uninstallnál alapértelmezés szerint csak változatlan owned fájlt töröl, majd temp file + `os.replace` művelettel ment (`d1e86f6:src/specify_cli/integrations/manifest.py:L104-L233`; `d1e86f6:src/specify_cli/integrations/manifest.py:L297-L456`). Egy szűkebb bundler resolver ugyanazt a feloldott tervet szolgálja az info/install útvonalnak (`d1e86f6:src/specify_cli/bundler/services/resolver.py:L1-L7`).

**Célmechanizmus (S3).** Egy általános, mellékhatásmentes planner állítja elő az összes `create/update/delete/preserve/conflict` műveletet, target pathot, korábbi és új hash-t, ownershipet és indokot; ugyanazt a serializált tervet használja a preview és a végrehajtó. Ez a teljes lifecycle-ra kiterjesztett `MaterializationPlan` szélesebb az upstream implementációnál.

**Réteg:** Project ownership manifest + Local staging.

**Trigger → input → output.** `install|upgrade|uninstall|repair` → desired generation, existing tree, prior manifest → immutable plan, staged generation, új manifest.

**Állapot és terminálás.** Egy tranzakció ID alá tartozik a plan, staging tree és journal. Terminális: `committed`, `rolled_back`, `needs_operator`.

**Failure semantics.** Unowned overwrite, modified-owned delete, symlink, traversal, case-fold collision, Windows reserved name vagy hash mismatch esetén nincs részleges publikálás.

**Forrás/provenance:** a hash/path/uninstall/atomic-save és szűk bundler-plan Spec Kit S1/S2; BMAD ownership-aware cleanup kiegészítő S1 bizonyíték (`770d425:tools/installer/ide/_config-driven.js:L292-L405`); a generalizált pure plan S3.

**Előfeltételek:** canonical path normalizálás; SHA-256 vagy erősebb hash; atomikus rename ugyanazon volume-on; recovery journal.

**Adaptáció:** a `preview` ne külön kódút legyen. A planner outputját serializáljuk review-ra, majd ugyanazt az objektumot hajtsa végre az executor.

**Trade-off:** több metadata és migráció, cserébe review-zható, idempotens és visszaállítható installáció.

**Reuse:** A pattern clean-room; alacsony szintű validation utility direct reuse esetén notice szükséges.

## 4. Determinisztikus Global → Project → Session → Local precedence

**Probléma.** Az agent viselkedése nehezen reprodukálható, ha környezeti változó, user config, project config, workflow input és ideiglenes override kevert sorrendben érvényesül.

**Megfigyelt forrásviselkedés (S1).** Az OpenSpec project config elkülöníti a contextet, rules-t, operation guidance-ot és reference-eket; a BMAD resolver többrétegű strukturális precedence-t és merge-algebrát ad (`45cca5d:src/core/project-config.ts:L32-L76`; `770d425:src/scripts/config_utils.py:L17-L118`).

**Célmechanizmus (S3).** Minden kulcshoz deklarált logical owner, physical source, scope, merge-strategy és provenance tartozik. A resolver tiszta függvényként állít elő `ResolvedConfig` objektumot. Minden végső érték megőrzi a nyertes forrást; a Global trust/policy kulcsok nem felülírhatók, még akkor sem, ha más kulcsoknál a Session vagy Local réteg magasabb precedence-ű.

**Réteg:** mind a négy; a Global a default/policy, a Project a team contract, a Session a run input, a Local csak gép- és sandbox-specifikus érték.

**Trigger → input → output.** `run.created|config.changed` → összes scope snapshotja → immutable `ResolvedConfig` + provenance map + diagnostics.

**Állapot és terminálás.** A Session egyetlen config-hashhez kötött. Futás közbeni változás új run vagy explicit rebind gate nélkül nem léphet életbe.

**Failure semantics.** Parse/read hiba nem eredményezhet csendes alapértéket, ha a fájl létezik vagy kötelező constraintet tartalmaz. A hibás project layer blokkolja a run-t.

**Forrás/provenance:** az upstream config/merge viselkedés OpenSpec + BMAD S1; a közös négyrétegű resolver és fail-closed protected-key contract S3.

**Előfeltételek:** schema, scope whitelist, secret-redaction, explicit merge algebra (`replace`, `deepMerge`, `appendUnique`, `forbidOverride`).

**Adaptáció:** generáljunk `config explain <key>` parancsot, amely megmutatja a teljes resolution chain-t.

**Trade-off:** kevésbé „mágikus”, de több explicit deklarációt követel.

**Reuse:** Clean-room.

## 5. Role contract és fresh-context sub-agent

**Probléma.** A pusztán persona-alapú agent definíció nem mondja meg, mit olvashat, írhat, milyen outputot köteles előállítani és mikor kell megállnia. A hosszú közös kontextus szerep- és megerősítési torzítást okoz.

**Mechanizmus.** Minden role deklarálja: mission, bemeneti artefaktok, output schema, allowed capabilities, write scope, context budget, memory policy, success marker, escalation és forbidden actions. A checker friss, minimális context manifestet kap; nem örökli automatikusan a producer teljes belső beszélgetését. A GSD role-ok eltérő tool scope-pal és producer/checker felelősséggel működnek, a planning loop friss sub-agentekkel és lemezre írt markerrel dolgozik (`33985c1:gsd-core/workflows/plan-phase.md:L1096-L1276`).

**Réteg:** Global role schema; Project role binding; Session invocation; Local tool sandbox.

**Trigger → input → output.** `role.invoke` → role version, context manifest, input artifact hashes → schema-valid output, evidence és completion marker.

**Állapot és terminálás.** Az invocation `queued/running/succeeded/failed/blocked/cancelled`. A role nem írhat a saját output scope-ján kívül.

**Failure semantics.** Üres/truncated válasz nem siker; a disk evidence külön ellenőrzendő. Tool- vagy scope-sértés azonnali halt és audit event.

**Forrás/provenance:** GSD, S1/S2; a vendorsemleges `RoleContract` absztrakció S3.

**Előfeltételek:** capability enforcement a prompt alatt is; output validator; context compiler; correlation IDs.

**Adaptáció:** először `planner`, `implementer`, `reviewer`, `verifier` négyes; persona csak opcionális nyelvi overlay legyen.

**Trade-off:** több invokáció és token, cserébe kisebb jogosultság, jobb auditálhatóság és valódi független review.

**Reuse:** Clean-room; promptszöveg közvetlen másolása nem ajánlott.

## 6. Producer/checker bounded repair loop

**Probléma.** Az önellenőrző agent ugyanazokat a vakfoltokat ismételheti, az automatikus javítás pedig végtelen loopba vagy scope creepbe fordulhat.

**Mechanizmus.** A producer outputját külön checker értékeli strukturált verdictben. `PASS` lezár; `REVISE` tételes findingokat ad; `BLOCK` operátori döntést kér. A repair loop maximális iterációja és a progress-metrika kötelező. A GSD planning loop három iterációra korlátozott, figyeli a nem csökkenő issue-számot, és legfeljebb két approach-váltást enged (`33985c1:gsd-core/workflows/plan-phase.md:L1096-L1276`). A BMAD auto-build review lépése szintén elkülöníti a build és review felelősséget (`770d425:src/bmm-skills/ship/bmad-build-auto/step-04-review.md:L59-L62`).

**Réteg:** Session workflow engine.

**Trigger → input → output.** `artifact.produced` → output + acceptance criteria + evidence → typed verdict `{status, findings, severity, evidence, next_action}`.

**Állapot és terminálás.** `iteration`, `remaining`, `previousFindingFingerprint`. Terminális: pass, hard block, exhausted, operator accepted/rejected.

**Failure semantics.** Ismétlődő finding fingerprint, növekvő hibaszám vagy iteration cap esetén automatikus loop helyett human gate.

**Forrás/provenance:** GSD + BMAD, S1/S2.

**Előfeltételek:** explicit acceptance criteria; checker read-only vagy külön write-scope; finding IDs; evidence links.

**Adaptáció:** a checker soha ne „javítson mellékesen”. A repair külön producer invocation legyen, csak az elfogadott findinghalmazzal.

**Trade-off:** magasabb latency, de kiszámítható konvergencia és audit trail.

**Reuse:** Clean-room.

## 7. Typed workflow algebra és explicit human gates

**Probléma.** A hosszú Markdown workflow implicit branch-eket, loopokat, retryt és destruktív műveleteket rejt; a host nem tudja előre validálni vagy megjeleníteni a végrehajtást.

**Mechanizmus.** A canonical workflow zárt műveletkészletből épül:

```text
Sequence | AgentStep | ToolStep | Gate | HumanApproval | Branch |
Loop | FanOut | FanIn | ArtifactWrite | Checkpoint | EmitEvent
```

Minden side-effecting step deklarál capability-t, scope-ot, timeoutot, idempotency key-t és recovery viselkedést. A Spec Kit gate runtime kötelező invariantként kéri a feltételt és a döntési ágakat (`d1e86f6:src/specify_cli/workflows/steps/gate/__init__.py:L78-L101`).

**Réteg:** Global schema; Project workflow definition; Session program counter.

**Trigger → input → output.** `workflow.start|resume|event` → workflow version, RunEnvelope, current PC → következő step intent vagy pause.

**Állapot és terminálás.** A program counter, branch/loop stack, attempt és deadline tartós Session journalban van. Minden workflow explicit terminal state-t nevez meg.

**Failure semantics.** Ismeretlen step, hiányzó capability, negatív gate vagy non-interactive human approval esetén `paused`, nem automatikus elfogadás.

**Forrás/provenance:** Spec Kit, S1; az egységes algebra S3.

**Előfeltételek:** schema validator, interpreter, checkpoint store, preview renderer.

**Adaptáció:** a Markdown csak emberi magyarázat vagy renderelt nézet legyen; az executable control-flow typed data.

**Trade-off:** kevésbé szabad promptírás, cserébe statikus elemzés, vizualizáció és determinisztikus resume.

**Reuse:** Clean-room.

## 8. Zárt event- és contribution-bus

**Probléma.** Pluginok és hookok közvetlenül egymást hívják, sorrendjük rejtett, hibájuk pedig vagy teljes futást tör, vagy csendben elvész.

**Megfigyelt forrásviselkedés (S1/S2).** A GSD capability registry generált, és lifecycle/loop contribution pontokat kezel; a Spec Kit közös native-event dispatchert renderel több hosthoz (`33985c1:docs/adr/1244-capability-ecosystem.md:L38-L77`; `33985c1:src/loop-resolver.cts:L499-L536`; `d1e86f6:src/specify_cli/events.py:L1339-L1421`). Mindkettőnél van tudatosan gyengébb ág: GSD optional contribution load-hibánál figyelmeztetve fail open viselkedhet, a Spec Kit pedig hiányzó vagy prompt-only command eventjénél sikeres no-opot adhat (`33985c1:src/loop-resolver.cts:L543-L582`; `d1e86f6:src/specify_cli/events.py:L254-L277`; `d1e86f6:src/specify_cli/events.py:L587-L618`).

**Célmechanizmus (S3 hardening).** Verziózott event types, payload schemas, prioritás, deterministic ordering, timeout és explicit failure policy. A contribution shared state helyett validálható intentet ad vissza. Security/policy handler fail closed; observability handler lehet non-blocking, de hibája kötelező audit event. Ismeretlen event vagy hiányzó executable handler nem lehet néma siker.

**Réteg:** Global event schema; Project subscriptions; Session dispatch; Local executable hook.

**Trigger → input → output.** Példák: `run:pre/post`, `plan:pre/post`, `execute:pre/post`, `verify:pre/post`, `archive:pre/post`, `error`, `approval.requested/resolved` → immutable event envelope → zero vagy több validated contribution.

**Állapot és terminálás.** Minden handlernek invocation ID, timeout és eredmény státusz. A dispatcher a zárt subscription listán végigér vagy policy szerint leáll.

**Failure semantics.** Security/policy handler fail closed; observability handler lehet non-blocking, de hibája audit event. Nincs néma no-op ismeretlen eventre vagy hiányzó executable handlerre.

**Forrás/provenance:** a jelenlegi registry/dispatcher és fail-open/no-op ágak GSD + Spec Kit S1/S2; a zárt, intent-alapú, fail-closed bus S3.

**Előfeltételek:** schema registry; handler trust classification; bounded payload; redaction; deterministic ordering.

**Adaptáció:** kezdetben kevés, szemantikailag stabil lifecycle event. Kerülendő az üzleti logika hookokba költöztetése.

**Trade-off:** jól bővíthető és tesztelhető, de a kompatibilitási és event-versioning fegyelem tartós költség.

**Reuse:** Clean-room.

## 9. Durable Run Journal és atomikus state transition

**Probléma.** A futás megszakadásakor a chat transcriptből kell kitalálni, mi történt, melyik művelet alkalmazódott, és mi hajtható újra biztonságosan.

**Mechanizmus.** Append-only evidence/event body, mutable-but-schema-bound summary/frontmatter, atomic write, fsync és sequence/correlation ID. A state transition előbb intentet számol, majd validált writer alkalmazza. A BMAD memlog body bejegyzései kronologikusan append-only-k, a frontmatter `set` művelettel változtatható; mentése temp file + flush/fsync + atomic replace (`770d425:src/scripts/memlog.py:L18-L35`; `770d425:src/scripts/memlog.py:L61-L67`; `770d425:src/scripts/memlog.py:L110-L129`).

**Réteg:** Session journal; a lezárt evidence Project artifactként archiválható.

**Trigger → input → output.** minden step start/end, tool call, decision, approval és state transition → redacted event → növekvő sequence és új state checksum.

**Állapot és terminálás.** Journal soha nem írja át a history body-t; korrekció új event. A summary deriválható és újraépíthető.

**Failure semantics.** Sequence gap, checksum mismatch vagy lock failure esetén a run `recovery_required`; tilos unlocked write-tal folytatni.

**Forrás/provenance:** BMAD, S1/S2; a teljes RunEnvelope/journal schema S3.

**Előfeltételek:** lock, atomic same-volume rename, redaction policy, event schema, compaction snapshot.

**Adaptáció:** JSONL journal gépi evidence-hez, rövid Markdown state emberi olvasásra; mindkettő ugyanahhoz a run ID-hoz kötve.

**Trade-off:** nagyobb tárhely és lifecycle management, cserébe audit, resume és incident reconstruction.

**Reuse:** Clean-room; a memlog utility közvetlen használata csak a szűkebb eredeti contracttal ajánlott.

## 10. Consent-bound project extensions és package trust

**Probléma.** Egy klónozott repository által szállított hook, MCP command vagy executable plugin nem jogosult önmagát gépszinten megbízhatónak nyilvánítani.

**Mechanizmus.** A consent store a repositoryn kívül, user-owned Global helyen él; a döntés a realpath project identityhez, capability ID-hoz, teljes bundle hashhez és human-readable trust disclosure-höz kötött. Tartalmi változás új consentet kér. A GSD ezt `${GSD_HOME}/.gsd/consent.json` fájllal és recomputed whole-bundle hash-sel teszi; a write lockolt és atomikus (`33985c1:src/capability-consent.cts:L1-L21`; `33985c1:src/capability-consent.cts:L67-L117`; `33985c1:src/capability-consent.cts:L626-L709`). A disclosure az executable pathokat, MCP transportot, argumentumokat, URL/headers/env felületet is leírja, a secretértékeket redaktálva (`33985c1:src/capability-trust.cts:L108-L170`; `33985c1:src/capability-trust.cts:L1098-L1178`).

**Réteg:** Global trust/consent + Project package request + Local executable material.

**Trigger → input → output.** `extension.discovered|content.changed|capability.requested` → bundle hash, disclosure, signer/source metadata → allow/deny/expire decision.

**Állapot és terminálás.** Consent explicit user decisionig `pending`; hashváltozáskor automatikusan `stale`, nem továbbörökített allow.

**Failure semantics.** Store parse/lock hiba, symlink escape, túl nagy bundle, undisclosed executable vagy secret-bearing display esetén deny.

**Forrás/provenance:** GSD, S1/S2.

**Előfeltételek:** bounded recursive hashing; realpath identity; external user-owned store; disclosure generator; revocation.

**Adaptáció:** különítsük el a `discovered`, `installed`, `enabled`, `trusted` állapotokat. Package install önmagában ne jelentsen execution permissiont.

**Trade-off:** több user interaction és re-consent, de megszünteti a repository-self-authorization alapvető trust hibáját.

**Reuse:** A contract clean-room; cryptographic utility direct reuse esetén notice és saját security review szükséges.

## 11. Manifest-scoped worktree sandbox

**Probléma.** Párhuzamos agentek ugyanabban a working tree-ben összeírhatják egymás munkáját; automatikus cleanup vagy merge viszont téves branch/path esetén adatvesztést okozhat.

**Mechanizmus.** A sandbox resolver explicit módon dönt izolációról, rögzíti a repository rootot, branch-et, base commitot, worktree pathot, owner run ID-t és allowed output scope-ot. Merge és cleanup csak a manifestben szereplő, újraellenőrzött worktree-re futhat. A GSD execute workflow exact manifest ownershipot és recovery ellenőrzéseket követ (`33985c1:gsd-core/workflows/execute-phase.md:L428-L593`; `33985c1:gsd-core/workflows/execute-phase.md:L597-L742`).

**Réteg:** Local sandbox, Project evidence manifest, Session owner.

**Trigger → input → output.** `execution.prepare|merge.request|cleanup.request` → pinned repo/HEAD/branch policy + run → sandbox manifest vagy human gate.

**Állapot és terminálás.** `allocated/active/dirty/ready_to_merge/merged/retained/cleaned`. A dirty vagy mismatch állapot nem takarítható automatikusan.

**Failure semantics.** Repo/HEAD/upstream/branch/path eltérés, untracked material, external modification vagy hiányzó manifest esetén stop + recovery instructions.

**Forrás/provenance:** GSD, S1/S2.

**Előfeltételek:** Git preflight; unique branch/path; absolute-path confinement; dirty-state preservation; no destructive broad globs.

**Adaptáció:** worktree csak valódi párhuzamos mutációhoz; read-only kutatáshoz olcsóbb a pinned clone vagy detached checkout.

**Trade-off:** erős izoláció és traceability, de Git-komplexitás és platformfüggő edge case-ek.

**Reuse:** Clean-room contract.

## 12. Progressive disclosure és explicit reference index

**Probléma.** Egyetlen óriási prompt túltölti a kontextust, miközben a lazán szöveges `@path` hivatkozások installálás után könnyen törnek vagy transitív prompt-injectiont okoznak.

**Megfigyelt forrásviselkedés (S1/S2).** A GSD architektúra külön kezeli a progressive disclosure-t (`33985c1:docs/ARCHITECTURE.md:L145-L204`; `33985c1:docs/ARCHITECTURE.md:L350-L381`). A Paul installer csak a `~/.claude/` prefixet írja át, majd a source alkönyvtárakat eltérő installed layoutba másolja ([installer](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/bin/install.js#L100-L160)); az izolált install-census 58 concrete `@src/...` referenciánál nem talált distributed targetet, ebből 46 execution-relevant és 17 command closure-t érint ([Paul-dosszié, runtime evidence](04-christopherkahler-paul.md#13-runtime-experiments)). Ez distribution-graph hiba; a Claude Code `@` parser tényleges runtime failure-je nem lett élőben reprodukálva.

**Célmechanizmus (S3).** A skill entrypoint rövid operation contract; a `ReferenceIndex` typed ID → canonical artifact mappingot tárol hash-sel, scope-pal és load policy-val. A context compiler csak az aktuális step dependency closure-ját tölti, adatként delimitalva.

**Réteg:** Project reference graph + Session context manifest + Local resolved paths.

**Trigger → input → output.** `step.context.requested` → role, step, artifact hashes, token budget → ordered bounded context bundle és provenance map.

**Állapot és terminálás.** Minden reference terminal: canonical artifact, generated artifact, external dependency vagy bizonyított broken edge. Nincs feloldatlan „majd a host megtalálja” állapot.

**Failure semantics.** Missing/cyclic/ambiguous reference, scope escape vagy hash mismatch blokkolja az invocationt. Beillesztett tartalom nem expandálhat új hivatkozást transitívan.

**Forrás/provenance:** GSD progressive disclosure és Paul distribution census S1/S2; a typed reference index/context compiler S3.

**Előfeltételek:** typed IDs; resolver; graph cycle detection; source/data delimiter; token estimator.

**Adaptáció:** a Markdown-link lehet emberi convenience, de a végrehajtható edge manifestben legyen. Install előtt és után fusson teljes closure validation.

**Trade-off:** kisebb, relevánsabb context és jobb hordozhatóság; többlet indexelés és explicit dependency-karbantartás.

**Reuse:** Clean-room; a Paul PLAN szövegének átvétele helyett saját reference schema.

## 13. Preview-before-destructive merge és transaction journal

**Probléma.** Archive, delta merge, migration vagy uninstall részlegesen módosíthat több fájlt; hiba esetén nem világos, mi történt meg és mi maradt vissza.

**Mechanizmus.** A rendszer először teljes diff/operation preview-t számol. Validálja a target rootot, collisionöket, schema invariánsokat és tulajdont, majd stagingben alkalmaz. A journal minden lépést és rollback információt rögzít. Az OpenSpec archive előzetesen összeállítja a műveleteket és csak ezután alkalmazza a módosításokat (`45cca5d:src/core/archive.ts:L353-L374`; `45cca5d:src/core/archive.ts:L693-L719`).

**Réteg:** Project mutation, Local staging, Session approval/evidence.

**Trigger → input → output.** `archive.preview|merge.preview|migration.preview` → source/target graph és current hashes → reviewable plan; jóváhagyás után committed generation.

**Állapot és terminálás.** `planned/approved/applying/verified/committed/rolled_back/needs_recovery`.

**Failure semantics.** Preview és execution input hash eltérésénél re-plan; részleges write után rollback vagy explicit recovery, soha nem „best effort success”.

**Forrás/provenance:** OpenSpec, S1/S2; általános journal S3.

**Előfeltételek:** pure diff planner, immutable input hashes, staging, atomic publish, compensating metadata.

**Adaptáció:** ugyanaz a preview objektum jelenjen meg embernek, menjen approval ledgerbe és kerüljön végrehajtásra.

**Trade-off:** lassabb mutation path, lényegesen kisebb adatvesztési és driftkockázat.

**Reuse:** Clean-room.

## 14. Generated parity és cross-platform contract tests

**Probléma.** A canonical forrás és a commitolt/generált hostfelület driftelhet; egy zöld source-unit-test nem bizonyítja, hogy az installer outputja futtatható Windowson, Linuxon és macOS-en.

**Megfigyelt forrásviselkedés (S1/S2).** A BMAD renderer a meglévő immutable generation file-setjét és hash-eit visszaellenőrzi, collision/corruption esetén megáll (`770d425:src/scripts/render_skill.py:L270-L319`). A Spec Kit külön Bash/PowerShell/Python parity teszteket tart fenn (`d1e86f6:tests/test_setup_tasks_python_parity.py:L1-L40`; `d1e86f6:tests/extensions/git/test_git_extension_python_parity.py:L1-L40`). A GSD `lint:generated-sync` több regisztrált generátort és parity-checkert kapcsol össze; ez a kutatásban csak build-materialized disposable clone-on volt zöld (`33985c1:package.json:L110-L119`).

**Célmechanizmus (S3).** Minden generatorhoz determinisztikus `generate` + `check` mód; a CI friss temp outputot készít és byte/semantic parityt ellenőriz. Adapterenként install-smoke, reference-closure, path/case/newline/symlink és negative contract test fut.

**Réteg:** Global adapter contract + Project CI + Local disposable test roots.

**Trigger → input → output.** `source.changed|adapter.changed|release.candidate` → clean temp home/project, canonical package → generated parity report, smoke evidence, drift diff.

**Állapot és terminálás.** Release csak minden kötelező platform contract pass után kész. Skip külön, indokolt platform capabilityként jelenik meg.

**Failure semantics.** Nincs automatikus generated-file commit; a drift diff review-zható. Environment failure különül el az assertion failure-től.

**Forrás/provenance:** a felsorolt upstream parity/hash kontrollok Spec Kit, GSD és BMAD S1/S2; a kötelező többplatformos release-mátrix és tesztpriorizálás S3 operációs döntés.

**Előfeltételek:** disposable homes; version-pinned runtime; no credential dependence; stable fixtures; artifact retention.

**Adaptáció:** minimum Windows + Linux CI, hostonként install→enumerate→closure→smoke→uninstall→preservation ciklus.

**Trade-off:** jelentős CI-idő, de ez bizonyítja a framework tényleges termékfelületét.

**Reuse:** Tesztötlet clean-room; upstream fixture közvetlen másolásakor MIT notice.

## 15. PLAN–APPLY–UNIFY mint emberi folyamatnyelv

**Probléma.** A teljes lifecycle szakmailag pontos nevei túl absztraktak lehetnek a napi használathoz; a felhasználónak gyorsan kell értenie, mikor születik döntés, mikor történik mutáció és mikor zárul a munka.

**Mechanizmus.** Három jól megjegyezhető makrofázis:

- **PLAN:** cél, scope, követelmények, kockázat, acceptance criteria és végrehajtható terv.
- **APPLY:** izolált végrehajtás, step evidence, teszt és hibakezelés.
- **UNIFY:** review, eredmények összevezetése, tartós state frissítése, lezárás vagy újratervezés.

A Paul explicit workflow-ként választja szét ezeket a fázisokat: a PLAN artefaktot állít elő, az APPLY feladatokat hajt végre és verify-ol, az UNIFY pedig eredményt, state-et és átmenetet egyeztet ([PLAN workflow](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/plan-phase.md#L1-L31), [APPLY workflow](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/apply-phase.md#L89-L160), [UNIFY workflow](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/src/workflows/unify-phase.md#L245-L269)).

**Réteg:** Project workflow vocabulary; Session macro-state.

**Trigger → input → output.** user intent → PLAN artifact; approved plan → APPLY evidence/output; completed execution → UNIFY decision and durable state.

**Állapot és terminálás.** A három makrofázis alatt a typed workflow algebra adja a valódi state machine-t. UNIFY végállapota lehet done, blocked, rejected, paused, superseded vagy archived.

**Failure semantics.** PLAN approval nélkül nincs APPLY. APPLY failure nem válhat automatikus completionné. UNIFY destruktív Git/cleanup művelete külön approval gate-et igényel.

**Forrás/provenance:** Paul, S1; a vendorsemleges, typed algebrára ráültetett változat S3.

**Előfeltételek:** canonical plan schema; approval ledger; evidence-backed apply; explicit closeout contract.

**Adaptáció:** csak a fogalmi nyelvet vegyük át. A Paul installerét, nyers `@src` referenciáit, prompt-only tool enforcementjét és automatikus Git-határait ne másoljuk.

**Trade-off:** kiváló onboarding-nyelv, de önmagában túl durva egy végrehajtómotorhoz.

**Reuse:** Clean-room rephrasing ajánlott. A Paul MIT notice közvetlen szöveg- vagy kódátvételnél kötelező ([LICENSE](https://github.com/ChristopherKahler/paul/blob/960b05c0b8e1f876f49674a700c9a087afebb8ac/LICENSE#L1-L20)).

## Ajánlott canonical lifecycle

```text
Discover → Specify → Clarify → Plan → Decompose → Execute
        → Verify → Review → Converge → Archive
```

Oldalsó belépések: `Explore`, `Audit`, `Debug`, `CorrectCourse`, `Resume`, `Migrate`, `Recover`.

Emberi nézetben ez összehajtható:

```text
PLAN  = Discover + Specify + Clarify + Plan + Decompose
APPLY = Execute + Verify
UNIFY = Review + Converge + Archive
```

## Bevezetési sorrend

Az alábbi sorrend célarchitekturális hipotézis, nem automatikus implementációs felhatalmazás. Minden sor atomikus ABK-prototípusokra bontandó, majd a rögzített empirikus kapun külön halad át.

| Szakasz | Bevezetendő contract | Kilépési feltétel |
|---|---|---|
| 1. Core state | Artifact DAG, root provenance, layered config, RunEnvelope | Ugyanaz a projekt új sessionből ugyanazt a readiness- és config-hash-t adja. |
| 2. Safe materialization | Canonical IR, adapter registry, pure plan, ownership manifest | Preview és execution azonos plan ID; unowned fájlt nem ír felül. |
| 3. Agent execution | RoleContract, context manifest, typed workflow algebra, approval ledger | Planner–implementer–reviewer–verifier kör explicit terminal state-t ad. |
| 4. Isolation and trust | Worktree manifest, consent-bound extension, capability enforcement | Repo-planted executable explicit user consent nélkül nem futhat. |
| 5. Operations | Event bus, journal, recovery, parity matrix, migrations | Crash után determinisztikus resume/rollback; minden adapter parity gate zöld. |

## Mit lehet a legegyszerűbben mintázatként átvenni?

| Prioritás | Minta | Átvételi nehézség | Függőség | Közvetlen érték |
|---:|---|---|---|---|
| 1 | OpenSpec Artifact DAG + root provenance | alacsony–közepes | schema + validator | tool- és sessionfüggetlen project state |
| 2 | Spec Kit ownership manifest + pure materialization | közepes | path security + staging | biztonságos install/update/uninstall |
| 3 | BMAD content-addressed execution packet | közepes | deterministic renderer + hash store | reprodukálható agent input |
| 4 | RoleContract + producer/checker loop | közepes | sub-agent runtime + output schema | kisebb jogosultság és jobb review |
| 5 | Paul PLAN–APPLY–UNIFY vocabulary | alacsony | canonical plan/evidence contract | gyors onboarding és érthető folyamat |
| 6 | GSD consent + worktree contract | magas | security store + Git recovery | erős project-trust és izoláció |
| 7 | Teljes descriptor/contribution ecosystem | magas | registry compiler + parity CI | sok host és plugin skálázható kezelése |

## Kifejezetten kerülendő anti-patternek

1. Nyers relatív `@path` hivatkozás install utáni closure validation nélkül.
2. Promptban leírt tool- vagy write-korlát valódi capability enforcement nélkül.
3. Project-owned fájlban tárolt önengedélyező trust/consent.
4. Csendes config read fallback, amely project constraintet hagy el.
5. Preview és execution külön döntési logikával.
6. Unbounded self-repair vagy recursive orchestration.
7. Checker, amely ugyanabban a lépésben saját findingját észrevétlenül kijavítja.
8. Installer, amely dependency-install hiba után részlegesen kész modult ad vissza (`770d425:tools/installer/modules/external-manager.js:L448-L502`).
9. Automatikus Git merge/commit/delete külön, célzott approval nélkül.
10. Generated surface kézi szerkesztése vagy parity gate nélküli publikálása.

## Döntési konklúzió

Ha a cél egy később bővíthető saját framework, a legjobb első implementation slice nem agent-personák vagy több tucat skill létrehozása. Előbb a **state és projection substrate** készüljön el: Artifact DAG, root provenance, layered config, canonical workflow/role IR, tiszta materialization plan, ownership manifest és Run Journal. Erre lehet biztonságosan ráépíteni a sub-agent role-okat, hookokat, pluginokat és host adaptereket.

A jelöltek közül az OpenSpec adja a legegyszerűbben adaptálható szemantikai magot; a Spec Kit a legerősebb fájlrendszeri és materializálási védőréteget; a BMAD a legjobb reprodukálhatósági mintát; a GSD a leggazdagabb, de legdrágábban átvehető operációs szerződéseket; a Paul pedig a legjobb egyszerű folyamatnyelvet, de nem megbízható telepítési alapot.

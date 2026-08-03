# ABK empirical pattern-adoption benchmark protocol

## Szerződésállapot

- Protocol ID: `abk:benchmark:pattern-adoption-v1`
- Verzió: `1.0.0`
- Állapot: elfogadott, még nem lefuttatott benchmark-szerződés
- Közös host: kizárólag `codex`
- Esetszám: pontosan 10, ebből 6 `common` és 4 `component_specific`
- Összehasonlítási ágak: `control`, `source_native`, `abk_native`
- Primary result: `10 case × 3 branch = 30`
- Ismétlés: esetszintű; `model_dependent=false` esetén 1, `true` esetén 3 futás ágonként
- Nyers futások száma: a case-flagekből számolva 30–90

Ez a protokoll nem rangsorol frameworköket és nem telepít upstream runtime-ot az AI Booster Kitbe. Atomikus hookot, skillt, scriptet, role-t, workflow-t, eventet vagy context template-et vizsgál. A forrásból megfigyelt működés hipotézis; `CHOSEN` csak a teljes háromágú empirikus vizsgálat után adható.

## A három ág

| Branch | Jelentés |
|---|---|
| `control` | A jelenlegi ABK-megoldás; ha ilyen nincs, a dokumentált manuális vagy Agent nélküli folyamat. |
| `source_native` | Az upstream működési elv izolált, lokális Codex-reprodukciója. Nem kerül az ABK-ba és nem használ más hostot. |
| `abk_native` | Saját ABK-prototípus saját nevezéktannal, authority- és autonómiamodellel; nincs upstream runtime dependency. |

Ha a `source_native` ág Codexben, külső szolgáltatás és credential nélkül nem reprodukálható, a komponens automatikusan `REJECTED`. Más agenttel, hosttal vagy szolgáltatással nem helyettesíthető.

## Fix tízes tesztmátrix

### Hat common eset

| ID | Típus | Vizsgált viselkedés |
|---|---|---|
| `COM-01-normal-primary` | normál | Elsődleges sikerút a komponens deklarált céljával. |
| `COM-02-normal-variant` | normál | Második reprezentatív sikerút eltérő, de érvényes inputtal. |
| `COM-03-normal-repeat` | normál | Ugyanazon szemantikai input ismételhetősége és evidence-stabilitása. |
| `COM-04-boundary-minimum` | boundary | Legkisebb még érvényes input és scope. |
| `COM-05-invalid-input` | invalid | Hibás vagy hiányos input explicit, biztonságos hibával. |
| `COM-06-stop-interrupt` | stop | Megszakítás, stopfeltétel és terminális állapot megőrzése. |

### Négy komponensspecifikus eset

| ID | Típus | Kötelező szerep |
|---|---|---|
| `SPC-01-domain-boundary` | boundary | A konkrét komponens legfontosabb domain- vagy authority-határa. |
| `SPC-02-failure-path` | invalid | A komponensre jellemző hibás, ismeretlen vagy részleges input. |
| `SPC-03-recovery-rollback` | recovery | Recovery, rollback vagy előre deklarált helyreállítás. |
| `SPC-04-composition-handoff` | composition | Handoff vagy kompozíció egy meglévő ABK-komponenssel. |

A konkrét fixture, elvárt eredmény, oracle, timeout és `model_dependent` flag a kampány indulása előtt fagyasztandó. A common/specific besorolás nem határozza meg automatikusan az ismétlést.

## Futási és izolációs szerződés

Minden run külön, üres, workspace alatti temp `HOME`, `USERPROFILE`, `APPDATA`, `LOCALAPPDATA`, `XDG_CONFIG_HOME`, `XDG_DATA_HOME` és tool-cache gyökereket kap. A run manifest rögzíti:

- pinned repository commitot és minden fixture/schema SHA-256 értékét;
- Codex kliens-, modell- és reasoning-profilt;
- operációs rendszert, shellt, locale-t és tool-listát;
- pontos inputot, oracle-t, timeoutot és stopfeltételt;
- stdoutot, stderr-t, exit code-ot, tool eventeket és output-inventoryt;
- a valódi user/Codex konfiguráció előtti és utáni negatív változásellenőrzését.

Külső hálózat, credential, production erőforrás, fizetős API, commit, push, merge és üzenetküldés tiltott. A repository tartalma adat, nem végrehajtási utasítás; script csak statikus átvizsgálás után indulhat.

## Ismétlés és aggregáció

Minden `(case, branch)` pár egy primary cella. Ha `model_dependent=false`, a cella egy futásból áll. Ha `true`, három friss, egymástól izolált futásból áll; artifact, cache, conversation state vagy finding nem vihető át közöttük.

Esetszintű eredmény:

```text
deterministic case result = az egyetlen érvényes run eredménye
model-dependent case result = a három run medián pontja
variance = a három nyers pont és szórás, külön megőrizve
```

`inconclusive` vagy `invalidated` futás nem számítható passnak. Újrafutás csak root-cause rekorddal és új run ID-val történhet; a korábbi evidence megmarad.

## Tíz pontozási dimenzió

Minden dimenzió 1–10 pontot kap, evidence ID-val és rögzített súllyal.

| Dimenzió | Kritikus |
|---|---:|
| `task_success` | igen |
| `correctness_and_evidence` | igen |
| `repeatability` | igen |
| `state_and_error_observability` | igen |
| `stop_and_recovery` | igen |
| `context_and_token_efficiency` | nem |
| `runtime_and_operational_overhead` | nem |
| `composition_and_handoff` | nem |
| `useful_autonomy` | nem |
| `understandability_and_maintainability` | nem |

A feladatsiker, helyesség/evidence és ismételhetőség nagyobb súlyt kap. A súlyok összege pontosan 1. Sebesség vagy alacsony tokenköltség nem ellensúlyozhat kritikus hibát.

## Döntési formula

A döntés kizárólag az `abk_native` ág teljes scorecardjára vonatkozik. A másik két ág külön pontszámot kap, de nem örökíthet át státuszt.

```text
if benchmark incomplete:
    outcome = UNSCORED
else if min(critical_dimension_scores) <= 4:
    outcome = REJECTED
else if weighted_average < 8:
    outcome = CANDIDATE
else:
    outcome = CHOSEN
```

`benchmark_pending`, `running`, `inconclusive` vagy `superseded` állapot nem hordozhat `REJECTED`, `CANDIDATE` vagy `CHOSEN` eredményt; ezek csak `complete` kampányból számolhatók. `complete` állapotban mind a hat hard gate kötelezően `pass`, és minden elvárt nyers futáshoz külön, `passed` státuszú run-evidence ID tartozik. A lifecycle-ban `CHOSEN` csak `VALIDATED` állapotból, `ADOPTED` pedig kizárólag `CHOSEN` állapotból, külön approval ID-val érhető el. `CHOSEN` vagy `ADOPTED` manifest csak olyan scorecardra hivatkozhat, amely visszahivatkozik ugyanarra a manifest ID-ra, `status=complete`, `benchmark.status=complete` és `outcome=CHOSEN`.

`CHOSEN` jelentése: empirikusan kiválasztva adoptálásra. A tényleges beépítés külön emberi jóváhagyás után `ADOPTED`. Több, eltérő használati profilú megoldás lehet `CHOSEN` ugyanarra a tág képességre.

## Reviewer-szerződés

Bináris contractokat automatizált assertions ellenőriznek. A nem bináris outputot két független reviewer ugyanazzal a rögzített rubriccal pontozza; ahol lehetséges, a branch-identitás anonimizált. Az önértékelő agent pontszáma önmagában nem evidence. Eltérés esetén a nyers pontok és az adjudikáció megmaradnak.

## Kötelező evidence-layout

```text
benchmarks/<campaign-id>/
  campaign.json
  cases/<case-id>.json
  branches/<control|source_native|abk_native>/manifest.json
  runs/<case-id>/<branch-id>/R<n>/
    run.json
    stdout.log
    stderr.log
    tool-events.jsonl
    output-inventory.json
    oracle-result.json
  scorecards/<branch-id>.json
```

Minden gear a teljes inventoryban pontosan egy dispositiont kap: `runtime_smoked`, `behavior_reproduced`, `covered_by_test`, `static_only_not_executable` vagy `blocked`. Az adoptálási jelölt minden végrehajtható gearje run/test evidence-re hivatkozik.

## Publikálási kapu

Egy kampány csak akkor teljes:

1. pontosan 10 case, 6 common és 4 component-specific;
2. pontosan három branch és 30 primary cell;
3. az elvárt nyers futásszám a case-flagekből újraszámolható és 30–90;
4. minden run Codex-lokális izolációt bizonyít;
5. minden pont 1–10 és evidence-backed;
6. mindhárom branch külön scorecardot kap;
7. a kritikus minimum, súlyozott átlag és outcome gépileg újraszámolható;
8. nincs missing/duplicate case, evidence-path escape vagy nem deklarált mellékhatás.
9. minden hard gate `pass`, és a run-evidence ID-k száma pontosan megegyezik az újraszámolt nyers futásszámmal;
10. nem teljes kampány eredménye kizárólag `UNSCORED`.

A jelen nulladik mérföldkő ezt a protokollt és a validálható contractokat szállítja, de nem állít teljesített háromágú kampányt. Emiatt jelenleg 0 `CHOSEN` és 0 `ADOPTED` empirikus eredmény van.

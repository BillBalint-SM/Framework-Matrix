# Framework-Matrix

Ez a repó ennek a Codex-beszélgetésnek az önálló projektje. Az öt SDD-jelölt
vizsgálata, a gépi bizonyítékok, a hordozható pattern-katalógus és az ABK-ba
illeszthető adoption-contract anyagok ide kerülnek. Az AI Booster Kit külön
projekt; annak forráskódja, branch-e és Git-története nincs ebben a repóban.

## Projekt-térkép

- `outputs/` – a végleges, átadható dossier-ok, sémák, benchmark-protokoll,
  refactor-terv, System Design DOCX és a tömörített evidence bundle.
- `benchmarks/` – a következő empirikus kampányok befagyasztott fixture-,
  isolation-, oracle- és evidence-contractjai; nem ABK-forráskód és nem
  upstream runtime.
- `sources/` – az öt vizsgált upstream repo teljes, tracked-file snapshotja a
  kutatáskor rögzített commitból, beágyazott Git-metainformáció és függőségi
  runtime nélkül.
- `archive/work/` – a kutatás teljes munkatere: briefek, nyers és ellenőrzött
  evidence, inventory-k, review-k, state-feljegyzések, dokumentum-renderelési
  munkák és a futtatott validáló scriptek.

## Provenance és állapot

Az upstream snapshotok commit-, branch- és URL-adatait a
[`sources/SOURCE-PINNING.md`](sources/SOURCE-PINNING.md) rögzíti. Az evidence
bundle saját `README.md`-je és `final-qa.txt` fájlja tartalmazza a gépi
leltár, hash-, coverage-, citation- és contract-validáció összesített
eredményét.

A `runtime/`, cache- és `node_modules`-tartalmak szándékosan nem kerültek át:
ezek reprodukálható, ideiglenes futási melléktermékek, nem a kutatás
átadható forrásai. A forrásrepo-k teljes tracked tartalma és az összes releváns
script/config/skill/plugin/hook/Markdown/JSON bizonyíték megmaradt a
`sources/` és az `archive/work/` rétegekben.

## Helyi ellenőrzés

```powershell
Get-ChildItem -Recurse -File sources | Measure-Object
Get-FileHash outputs\sdd-framework-evidence-bundle.zip -Algorithm SHA256
tar -tf outputs\sdd-framework-evidence-bundle.zip | Select-Object -First 20
& .\benchmarks\scripts\validate-benchmark-campaign.ps1 `
  -CampaignPath .\benchmarks\campaigns\artifact-dag-core-v1\campaign.json `
  -WorkspaceRoot (Get-Location).Path
& .\benchmarks\tests\test-control-contract.ps1 `
  -WorkspaceRoot (Get-Location).Path
& .\benchmarks\tests\test-control-runner.ps1 `
  -WorkspaceRoot (Get-Location).Path
& .\benchmarks\tests\test-branch-manifest.ps1 `
  -WorkspaceRoot (Get-Location).Path
& .\benchmarks\tests\test-isolation-audit.ps1 `
  -WorkspaceRoot (Get-Location).Path
& .\benchmarks\tests\test-network-policy-audit.ps1 `
  -WorkspaceRoot (Get-Location).Path
```

## Teljes kampány és scorecard-gate

A befagyasztott `artifact-dag-core-v1` mátrix 10 esetet, 3 ágat és az esetenkénti
ismétlési szabályokkal összesen 66 nyers futást tartalmaz. A teljes kampányt az
orchestrator csak a hash-pinnelt manifestek, fixture-ök és entrypointok
ellenőrzése után indítja; a `-ValidationOnly` mód nem ír fájlt:

```powershell
& .\benchmarks\scripts\run-full-campaign.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -OutputRoot .\benchmarks\campaigns\artifact-dag-core-v1\runs\full-campaign-YYYYMMDD `
  -ValidationOnly
```

Futtatáshoz a `-ValidationOnly` kapcsolót el kell hagyni. Az output könyvtár
nem írható felül, és a kampány `campaign.json` állapota a scorecard-készítés
alatt is `benchmark_pending`/`UNSCORED` marad. A nyers futásokból külön,
fail-closed ledger készül:

```powershell
& .\benchmarks\scripts\validate-full-campaign-scorecard.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -RunRoot .\benchmarks\campaigns\artifact-dag-core-v1\runs\full-campaign-YYYYMMDD `
  -OutputPath .\benchmarks\campaigns\artifact-dag-core-v1\runs\full-campaign-YYYYMMDD\full-campaign-scorecard.json
```

66/66 nyers futás esetén is `outcome=UNSCORED` marad, amíg a független
reviewer-dimenziók nincsenek kitöltve. A scorecard nem állít elő automatikusan
`CHOSEN` vagy `ADOPTED` döntést; a `campaign-run-index.json`, a scorecard és az
összes run/oracle bizonyíték együtt képezik az összehasonlítható snapshotot.

Ez a munkapéldány először lokálisan kerül ellenőrzésre; commit és GitHub-push
csak külön jóváhagyott kézbesítési lépésként történik.

## Reviewer-input és branch-scorecard gate

A teljes kampány immutable evidence snapshotjára branchenként külön scorecard
készül. A reviewer-szerződést a
[`benchmarks/schemas/reviewer-input.schema.json`](benchmarks/schemas/reviewer-input.schema.json),
a befagyasztott tízdimenziós rubrikát pedig a
[`benchmarks/campaigns/artifact-dag-core-v1/reviewer-rubric.json`](benchmarks/campaigns/artifact-dag-core-v1/reviewer-rubric.json)
rögzíti. Minden branchhez pontosan két független reviewer-input szükséges; ezek a
canonical `reviewer-inputs/` könyvtárban, a harmadik adjudicator artifactok az
`adjudications/` könyvtárban vannak. A v1 scorecardok szándékosan
fail-closed `running`/`UNSCORED` állapotúak, mert a legacy control runner
baseline és az SPC-01 raw oracle `inconclusive`.

Az ellenőrző és generáló entrypoint:

```powershell
& .\benchmarks\scripts\validate-reviewer-scorecards.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -RunRoot .\benchmarks\campaigns\artifact-dag-core-v1\runs\full-campaign-20260805 `
  -ReviewerInputRoot .\benchmarks\campaigns\artifact-dag-core-v1\reviewer-inputs `
  -AdjudicationRoot .\benchmarks\campaigns\artifact-dag-core-v1\adjudications `
  -ScorecardRoot .\benchmarks\campaigns\artifact-dag-core-v1\scorecards
```

Az entrypoint hash- és útvonal-ellenőrzéssel csak a rögzített run/oracle
bizonyítékokra enged hivatkozni, nem ír felül meglévő outputot, és fail-closed
marad, ha nincs két `submitted` review, a reviewer-gate-ek nem egyhangúak,
vagy a két reviewer bármely dimenzióban egynél nagyobb eltérést ad. Ilyenkor
`REVIEW_ADJUDICATION_REQUIRED` blokkoló keletkezik; a harmadik adjudicator
artifact a
[`adjudications/`](benchmarks/campaigns/artifact-dag-core-v1/adjudications/)
könyvtárban rögzíthető. Numeric vita esetén a validator a három pont
mediánját használja; authority/ownership/provenance/undocumented-effect vita
`inconclusive` marad. Automatikus score vagy döntés továbbra sem készül.

## V2 comparison resolution

A v2 összehasonlítás a v1 snapshotot nem módosítja. A control ág
`baseline_only`, a source-native és ABK-native ágak eligible összehasonlítási
ágak. Az SPC-01 out-of-root rejection v2-ben explicit expected boundary
behavior, miközben a raw `inconclusive` státusz megmarad az evidence ledgerben.

```powershell
& .\benchmarks\scripts\resolve-v2-comparison.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -ProfilePath .\benchmarks\campaigns\artifact-dag-core-v1\resolution-v2\profile.json `
  -ReviewerInputRoot .\benchmarks\campaigns\artifact-dag-core-v1\reviewer-inputs `
  -AdjudicationRoot .\benchmarks\campaigns\artifact-dag-core-v1\adjudications `
  -OutputPath .\benchmarks\campaigns\artifact-dag-core-v1\resolution-v2\comparison-scorecard.json
```

The v2 comparison output is separate from the v1 adoption scorecards and
`CHOSEN` remains a comparison result, not an `ADOPTED` approval.

Az adjudicator-bemenet szigorú szerződése a
[`reviewer-adjudication.schema.json`](benchmarks/schemas/reviewer-adjudication.schema.json).

```powershell
& .\benchmarks\tests\test-reviewer-scorecards.ps1 `
  -WorkspaceRoot (Get-Location).Path
& .\benchmarks\tests\test-reviewer-adjudication.ps1 `
  -WorkspaceRoot (Get-Location).Path
```

## ABK-native humán adoption döntés

Az explicit humán jóváhagyás külön
[`adoption-record`](benchmarks/campaigns/artifact-dag-core-v1/adoptions/abk-native-v2.json)
artefaktumban van rögzítve. Ez a rekord SHA-256 hash-sel a v2
[`comparison-scorecard`](benchmarks/campaigns/artifact-dag-core-v1/resolution-v2/comparison-scorecard.json)
fájlhoz kötődik. Az `ADOPTED` státusz csak erre a humán döntési rekordra
vonatkozik; a v1 bizonyíték, a v2 profile és a v2 scorecard változatlanul
marad, utóbbi eredménye továbbra is `CHOSEN`.

```powershell
& .\benchmarks\scripts\validate-adoption-decision.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -RecordPath .\benchmarks\campaigns\artifact-dag-core-v1\adoptions\abk-native-v2.json
```

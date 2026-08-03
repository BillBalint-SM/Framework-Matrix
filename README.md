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
```

Ez a munkapéldány először lokálisan kerül ellenőrzésre; commit és GitHub-push
csak külön jóváhagyott kézbesítési lépésként történik.

# Benchmark substrate

Ez a könyvtár a nulladik mérföldkő után elfogadott, Codex-lokális benchmark
kampányok szerződéses előkészítését tartalmazza. A campaign manifest, a fix
fixture-ek és a JSON Schema csak a futtatási scope-ot, az isolation policy-t,
az oracle-t és az evidence-layoutot fagyasztja be; empirikus futást nem állít
és nem eredményez automatikus `CHOSEN` vagy `ADOPTED` státuszt.

Az első kampány az OpenSpecből leválasztott `Artifact DAG + root provenance`
minta. A `control`, `source_native` és `abk_native` ág szerződéses helye
rögzített. Ebben az önálló repóban nincs AI Booster Kit-forráskód, upstream
runtime dependency, credential, hálózati vagy Git-mutáció; az ABK snapshot
csak immutable, metadata-only provenance.

## Ellenőrzés

```powershell
& .\benchmarks\scripts\validate-benchmark-campaign.ps1 `
  -CampaignPath .\benchmarks\campaigns\artifact-dag-core-v1\campaign.json `
  -WorkspaceRoot (Get-Location).Path

& .\benchmarks\tests\test-benchmark-campaign.ps1 `
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

& .\benchmarks\tests\test-source-native-runner.ps1 `
  -WorkspaceRoot (Get-Location).Path

& .\benchmarks\tests\test-source-native-bounded.ps1 `
  -WorkspaceRoot (Get-Location).Path

& .\benchmarks\tests\test-abk-native-runner.ps1 `
  -WorkspaceRoot (Get-Location).Path
```

A validátor kizárólag `benchmark_pending` kampányt fogad el, és a kampány
állapota jelenleg `UNSCORED`, nulla completed runnal.

A control request/run sémák fail-closed tesztjei a JSON unknown-field,
branch/path, és terminal-state/exit-code kombinációkat is ellenőrzik. A séma-
kontraktus önmagában nem indít benchmark-kampányt és nem hoz létre tartós run
evidence-t.

A `benchmarks/runners/control/run.ps1` most már létezik és csak a fixture-only
integrációs tesztekben fut. A teljes 66-run kampányt, source-native/ABK-native
ágat és adoption score-t ez a runner nem indítja el.

Az izolációs audit sanitizált PowerShell 7 child processben futtat egyetlen
kontroll fixture-t, majd a repository-, Git-, process- és környezeti határokat
ellenőrzi. A jelenlegi audit `INCONCLUSIVE`, mert a folyamat nem nyitott
socketet, de OS-szintű hálózati tiltási policy nincs függetlenül bizonyítva.

A `test-network-policy-audit.ps1` csak adminisztrátori PowerShellből tudja
létrehozni az ideiglenes, `pwsh.exe`-re szűkített outbound Block szabályt. A
nem-emelt preflight `BLOCKED` (`FIREWALL_ADMIN_REQUIRED`) volt, majd az emelt
futtatás `PASS` lett: a runner alatt 0 socketet figyeltünk meg, és a szabály
eltávolítása/read-backje sikeres volt.

## Branch snapshot descriptors

A `benchmarks/snapshots/` metadata-only descriptorokat tartalmaz. A
`source_native` descriptor a pinned OpenSpec artifact-graph snapshotot rögzíti
`READY_FOR_ENTRYPOINT` állapotban; a hozzá tartozó manifest már
`READY_FOR_EXECUTION` és a lokális clean-room entrypoint futtatható. Az
`abk_native` descriptor a külön AI Booster Kit immutable commitját bizonyítja,
és a helyi clean-room adapter számára összehasonlítható metadata-bound
provenance-t ad. Egyik descriptor sem másol ABK-forrást, runtime-ot vagy
Git-kapcsolatot ebbe a repóba.

```powershell
& .\benchmarks\tests\test-branch-snapshots.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -AiBoosterKitRoot 'C:\Users\littl\Documents\AI Booster Kit'
```

## Branch manifests and executable entrypoints

Mindhárom ág külön manifestet használ. A `control` manifest és entrypoint
korábbi kontroll-hashét érintetlenül hagytuk; az új ágak saját entrypointot és
független snapshot-hash-t pinelnek:

| Branch | Manifest SHA-256 | Entrypoint SHA-256 | Snapshot SHA-256 | Állapot |
|---|---|---|---|---|
| `control` | `5c041ba5…c9a235` | `a0e4929d…e859c1` | az entrypoint-tal azonos legacy control hash | kontroll, nem kampányfuttatás |
| `source_native` | `84d24272…61c4bb2` | `eb35b846…90598ae` | `76133032…25c9d4a` | `READY_FOR_EXECUTION`, `NOT_EXECUTED` |
| `abk_native` | `d1365718…896f01` | `14cd7ea7…00954c` | `1fc620cb…72abae` | `READY_FOR_EXECUTION`, `NOT_EXECUTED` |

A két új PowerShell entrypoint fail-closed: ellenőrzi a kampány-, fixture-,
séma- és metadata snapshot-hash-eket, csak a saját run-rootba ír evidence-et,
és nem lépi át a lokális authority-határokat. A `source_native` és az
`abk_native` fixture-only clean-room adapter determinisztikus DAG/readiness/
provenance eredményt és a speciális stop/recovery/handoff esetekhez typed
evidence-et ad; ez nem teljes YAML/resolver parity. Az `abk_native` az ABK
formation/prerequisite/relation/readiness szókincset helyi, összehasonlítható
adapterként használja, miközben az immutable külső snapshotot csak
metadata-ként ellenőrzi. Egyik entrypoint sem indít upstream runtime-ot és nem
módosít Git-et.

```powershell
& .\benchmarks\scripts\validate-branch-manifest.ps1 `
  -ManifestPath .\benchmarks\campaigns\artifact-dag-core-v1\branches\source_native\manifest.json `
  -WorkspaceRoot (Get-Location).Path

& .\benchmarks\scripts\validate-branch-manifest.ps1 `
  -ManifestPath .\benchmarks\campaigns\artifact-dag-core-v1\branches\abk_native\manifest.json `
  -WorkspaceRoot (Get-Location).Path
```

Ezek az entrypointok és manifestek a futtatási szerződést zárják le; a 66 raw
run-os immutable evidence snapshot már elkészült, de a canonical campaign
contract és az adoption outcome továbbra is reviewer-gated és `UNSCORED`. A
source-native bounded harness hat pozitív/negatív esetet ellenőriz
(`SOURCE_NATIVE_RUNNER_TESTS: 6/6 PASS`), de ez még nem kampányeredmény és nem
adoption score.

## Bounded source-native pilot

A `benchmarks/scripts/run-source-native-bounded.ps1` egyszer lefuttatja mind a
10 rögzített fixture-t a `source_native` clean-room entrypointon. A jelenlegi
ledger és a raw evidence a
`benchmarks/campaigns/artifact-dag-core-v1/runs/source-native-bounded-pilot-20260804/`
könyvtárban van; a pilot `10/10 PASS`, de `full_campaign=false`, a teljes
háromágú kampány továbbra is `66` raw run és `UNSCORED`. Az eredmény külön
`source-native-pilot.schema.json` sémával validált.

## Bounded control-native pilot

A `benchmarks/scripts/run-control-bounded.ps1` ugyanazt a tíz befagyasztott
fixture-t futtatja a legacy `control` entrypointon, és nem módosítja annak
manifest- vagy entrypoint-hashét. A pilot harness állapota `10/10 RUNS`; a
kampány-oracle-hoz 6 eset igazodik, 4 eset eltérésként marad bizonyítékként
(`aligned=6`, `divergent=4`). Az eltérések a control baseline jelenlegi
interrupt, root-boundary, recovery és handoff viselkedését írják le; ez nem
automatikus javítás és nem adoption score.

A ledger és raw evidence a
`benchmarks/campaigns/artifact-dag-core-v1/runs/control-bounded-pilot-20260804/`
könyvtárban van, és a `control-pilot.schema.json` sémával validált. A pilot
`full_campaign=false`, a kampány továbbra is `benchmark_pending`, nulla
completed runnal és `UNSCORED` scorecarddal.

## Bounded ABK-native pilot

A `benchmarks/scripts/run-abk-native-bounded.ps1` egyszer lefuttatja mind a 10
rögzített fixture-t az `abk_native` clean-room entrypointon. A futás az
immutable AI Booster Kit commitot snapshot-bound provenance-ként ellenőrzi, de
nem olvassa, nem linkeli és nem futtatja a külön projektet. A pilot
`full_campaign=false`, a scorecard `UNSCORED`, és a kampány továbbra is
`benchmark_pending`, nulla completed raw runnal. A részletes ledger és raw
evidence a `benchmarks/campaigns/artifact-dag-core-v1/runs/abk-native-bounded-
pilot-20260804/` könyvtárban van, az `abk-native-pilot.schema.json` sémával
validálva. A futás `10/10 PASS`: 6 oracle-siker, 2 typed hiba, 1 root-boundary
inconclusive és 1 explicit stopped eredmény; az eltérő terminal ágak is
megőrzött, összehasonlítható evidence-ként maradnak.

## Reviewer scorecards és adjudication

A teljes `artifact-dag-core-v1` snapshot a
`runs/full-campaign-20260805/` immutable run-rootban van, és a branch
scorecardok reviewer-bemenet hiányában `running`/`UNSCORED` állapotúak. A két
reviewer inputot a `schemas/reviewer-input.schema.json`, az egynél nagyobb
reviewer-eltérést a `schemas/reviewer-adjudication.schema.json` szerződés írja
le. Numeric vita esetén a harmadik score mediánja használható;
authority/ownership/provenance/undocumented-effect vita fail-closed
`inconclusive` marad.

```powershell
& .\benchmarks\scripts\validate-reviewer-scorecards.ps1 `
  -WorkspaceRoot (Get-Location).Path `
  -RunRoot .\benchmarks\campaigns\artifact-dag-core-v1\runs\full-campaign-20260805 `
  -ReviewerInputRoot .\benchmarks\campaigns\artifact-dag-core-v1\reviewer-inputs `
  -AdjudicationRoot .\benchmarks\campaigns\artifact-dag-core-v1\adjudications `
  -ScorecardRoot .\benchmarks\campaigns\artifact-dag-core-v1\scorecards
```

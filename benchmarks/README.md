# Benchmark substrate

Ez a könyvtár a nulladik mérföldkő után elfogadott, Codex-lokális benchmark
kampányok szerződéses előkészítését tartalmazza. A campaign manifest, a fix
fixture-ek és a JSON Schema csak a futtatási scope-ot, az isolation policy-t,
az oracle-t és az evidence-layoutot fagyasztja be; empirikus futást nem állít
és nem eredményez automatikus `CHOSEN` vagy `ADOPTED` státuszt.

Az első kampány az OpenSpecből leválasztott `Artifact DAG + root provenance`
minta. A `control`, `source_native` és `abk_native` ág szerződéses helye
rögzített, de ebben az önálló repóban nincs AI Booster Kit-forráskód, upstream
runtime dependency, credential, hálózati vagy Git-mutáció.

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
`READY_FOR_ENTRYPOINT` állapotban; az `abk_native` descriptor a külön AI
Booster Kit commitot bizonyítja, de az Artifact DAG összehasonlíthatósága
`NOT_COMPARABLE`. Egyik descriptor sem másol ABK-forrást, runtime-ot vagy Git
kapcsolatot ebbe a repóba.

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
| `source_native` | `0493c1f9…07723da` | `d0384863…11f3c3` | `187f0519…32cefa` | `NOT_COMPARABLE`, `NOT_EXECUTED` |
| `abk_native` | `2557f41a…67e7c0` | `c3e4daf7…6658e` | `a19b1c30…875997` | `NOT_COMPARABLE`, `NOT_EXECUTED` |

A két új PowerShell entrypoint fail-closed: ellenőrzi a kampány-, fixture-,
séma- és metadata snapshot-hash-eket, csak a saját run-rootba ír evidence-et,
majd a hiányzó engedélyezett runtime/összehasonlítható ABK snapshot miatt
typed `REJECTED` / `NOT_COMPARABLE`, exit code `2` állapotban áll meg. Nem
olvassa a külön AI Booster Kit checkoutot, nem indít upstream runtime-ot, és
nem módosít Git-et.

```powershell
& .\benchmarks\scripts\validate-branch-manifest.ps1 `
  -ManifestPath .\benchmarks\campaigns\artifact-dag-core-v1\branches\source_native\manifest.json `
  -WorkspaceRoot (Get-Location).Path

& .\benchmarks\scripts\validate-branch-manifest.ps1 `
  -ManifestPath .\benchmarks\campaigns\artifact-dag-core-v1\branches\abk_native\manifest.json `
  -WorkspaceRoot (Get-Location).Path
```

Ezek az entrypointok és manifestek a futtatási szerződést zárják le; a 66 raw
run-os kampány, scorecard és adoption outcome továbbra sincs elindítva.

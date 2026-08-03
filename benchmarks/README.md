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

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$pilotSchema = Join-Path $workspaceFull 'benchmarks\schemas\abk-native-pilot.schema.json'
$pilotScript = Join-Path $workspaceFull 'benchmarks\scripts\run-abk-native-bounded.ps1'
$campaignBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $campaignPath).Hash.ToLowerInvariant()
$testRoot = Join-Path $campaignRoot ('runs\test-abk-bounded-' + [guid]::NewGuid().ToString('N'))
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

try {
    & $pwshPath -NoLogo -NoProfile -NonInteractive -File $pilotScript -WorkspaceRoot $workspaceFull -OutputRoot $testRoot 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "TEST_FAILURE: bounded ABK-native pilot exited with $LASTEXITCODE" }
    $pilotPath = Join-Path $testRoot 'pilot.json'
    if (-not (Test-Json -LiteralPath $pilotPath -SchemaFile $pilotSchema)) { throw 'TEST_FAILURE: ABK-native pilot ledger failed schema validation' }
    $pilot = Get-Content -Raw -LiteralPath $pilotPath | ConvertFrom-Json
    if ($pilot.branch -ne 'abk_native' -or $pilot.raw_runs -ne 10 -or $pilot.full_campaign -ne $false -or $pilot.scorecard_state -ne 'UNSCORED') { throw 'TEST_FAILURE: bounded ABK-native pilot scope is incorrect' }
    if (@($pilot.results | Where-Object { $_.status -ne 'passed' }).Count -ne 0) { throw 'TEST_FAILURE: bounded ABK-native pilot contains failed ledger rows' }
    if (@($pilot.results | Where-Object { $_.oracle_status -eq 'passed' }).Count -ne 6) { throw 'TEST_FAILURE: expected six passed oracle outcomes' }
    if (@($pilot.results | Where-Object { $_.oracle_status -eq 'failed' }).Count -ne 2) { throw 'TEST_FAILURE: expected two failed oracle outcomes' }
    if (@($pilot.results | Where-Object { $_.oracle_status -eq 'inconclusive' }).Count -ne 1) { throw 'TEST_FAILURE: expected one inconclusive oracle outcome' }
    if (@($pilot.results | Where-Object { $_.oracle_status -eq 'stopped' }).Count -ne 1) { throw 'TEST_FAILURE: expected one stopped oracle outcome' }
    if (@(Get-ChildItem -LiteralPath $testRoot -Filter 'run.json' -Recurse -File).Count -ne 10) { throw 'TEST_FAILURE: bounded ABK-native raw run count mismatch' }
    $campaignAfter = (Get-FileHash -Algorithm SHA256 -LiteralPath $campaignPath).Hash.ToLowerInvariant()
    if ($campaignAfter -ne $campaignBefore) { throw 'TEST_FAILURE: bounded ABK-native pilot changed campaign.json' }
    Write-Output 'ABK_NATIVE_BOUNDED_TESTS: 10/10 PASS'
} finally {
    if (Test-Path -LiteralPath $testRoot) { [IO.Directory]::Delete($testRoot, $true) }
}

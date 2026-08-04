param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$scriptPath = Join-Path $workspaceFull 'benchmarks\scripts\run-control-bounded.ps1'
$pilotSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\control-pilot.schema.json'
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$testOutputRoot = Join-Path $campaignRoot ('runs\test-control-bounded-' + [guid]::NewGuid().ToString('N'))

if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw 'TEST_FAILURE: bounded control campaign script must exist' }
if (-not (Test-Path -LiteralPath $pilotSchemaPath -PathType Leaf)) { throw 'TEST_FAILURE: bounded control pilot schema must exist' }
$campaignHashBefore = (Get-FileHash -Algorithm SHA256 -LiteralPath $campaignPath).Hash.ToLowerInvariant()

try {
    & pwsh -NoLogo -NoProfile -NonInteractive -File $scriptPath -WorkspaceRoot $workspaceFull -OutputRoot $testOutputRoot
    if ($LASTEXITCODE -ne 0) { throw "TEST_FAILURE: bounded control campaign exited with $LASTEXITCODE" }

    $pilotPath = Join-Path $testOutputRoot 'pilot.json'
    if (-not (Test-Path -LiteralPath $pilotPath -PathType Leaf)) { throw 'TEST_FAILURE: bounded control pilot ledger is missing' }
    if (-not (Test-Json -LiteralPath $pilotPath -SchemaFile $pilotSchemaPath)) { throw 'TEST_FAILURE: bounded control pilot ledger is not schema-valid' }
    $pilot = Get-Content -Raw -LiteralPath $pilotPath | ConvertFrom-Json
    if ($pilot.status -ne 'passed' -or $pilot.full_campaign -ne $false) { throw 'TEST_FAILURE: bounded control pilot must pass without claiming a full campaign' }
    if ($pilot.branch -ne 'control' -or $pilot.raw_runs -ne 10 -or $pilot.expected_full_campaign_runs -ne 66) { throw 'TEST_FAILURE: bounded control pilot run-count contract mismatch' }
    if ($pilot.aligned_cases -ne 6 -or $pilot.divergent_cases -ne 4) { throw "TEST_FAILURE: bounded control pilot alignment contract mismatch: aligned=$($pilot.aligned_cases), divergent=$($pilot.divergent_cases)" }
    if (@($pilot.results).Count -ne 10 -or @($pilot.run_evidence_ids).Count -ne 10) { throw 'TEST_FAILURE: bounded control pilot must contain ten case results and evidence IDs' }
    if (@($pilot.results | Where-Object status -ne 'passed').Count -ne 0) { throw 'TEST_FAILURE: bounded control pilot contains a failed harness result' }
    if (@($pilot.results | Where-Object evaluation -notin @('aligned', 'divergent')).Count -ne 0) { throw 'TEST_FAILURE: bounded control pilot contains an invalid evaluation' }
    foreach ($result in @($pilot.results)) {
        $runPath = Join-Path $workspaceFull $result.run_relative_path
        $oraclePath = Join-Path $workspaceFull $result.oracle_relative_path
        if (-not (Test-Path -LiteralPath $runPath -PathType Leaf) -or -not (Test-Path -LiteralPath $oraclePath -PathType Leaf)) { throw "TEST_FAILURE: missing raw evidence for $($result.case_id)" }
    }
    foreach ($name in @('pilot.json', 'pilot.md')) {
        $pilotArtifactPath = Join-Path $testOutputRoot $name
        if (([IO.File]::ReadAllBytes($pilotArtifactPath) -contains [byte]13)) { throw "TEST_FAILURE: pilot artifact must use LF line endings: $pilotArtifactPath" }
    }
    foreach ($name in @('pilot.json', 'pilot.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $testOutputRoot $name) -PathType Leaf)) { throw "TEST_FAILURE: missing bounded control artifact '$name'" }
    }
    $campaignHashAfter = (Get-FileHash -Algorithm SHA256 -LiteralPath $campaignPath).Hash.ToLowerInvariant()
    if ($campaignHashBefore -ne $campaignHashAfter) { throw 'TEST_FAILURE: bounded control pilot changed campaign.json' }
    Write-Output 'CONTROL_BOUNDED_TESTS: 1/1 PASS'
} finally {
    if (Test-Path -LiteralPath $testOutputRoot) { [IO.Directory]::Delete([IO.Path]::GetFullPath($testOutputRoot), $true) }
}

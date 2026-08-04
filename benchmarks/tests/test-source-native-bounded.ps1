param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$scriptPath = Join-Path $workspaceFull 'benchmarks\scripts\run-source-native-bounded.ps1'
$pilotSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\source-native-pilot.schema.json'
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$testOutputRoot = Join-Path $campaignRoot ('runs\test-source-native-bounded-' + [guid]::NewGuid().ToString('N'))

if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    throw 'TEST_FAILURE: bounded source-native campaign script must exist'
}
if (-not (Test-Path -LiteralPath $pilotSchemaPath -PathType Leaf)) {
    throw 'TEST_FAILURE: bounded source-native pilot schema must exist'
}

try {
    & pwsh -NoLogo -NoProfile -NonInteractive -File $scriptPath -WorkspaceRoot $workspaceFull -OutputRoot $testOutputRoot
    if ($LASTEXITCODE -ne 0) { throw "TEST_FAILURE: bounded source-native campaign exited with $LASTEXITCODE" }

    $pilotPath = Join-Path $testOutputRoot 'pilot.json'
    if (-not (Test-Path -LiteralPath $pilotPath -PathType Leaf)) { throw 'TEST_FAILURE: bounded pilot ledger is missing' }
    if (-not (Test-Json -LiteralPath $pilotPath -SchemaFile $pilotSchemaPath)) { throw 'TEST_FAILURE: bounded pilot ledger is not schema-valid' }
    $pilot = Get-Content -Raw -LiteralPath $pilotPath | ConvertFrom-Json
    if ($pilot.status -ne 'passed' -or $pilot.full_campaign -ne $false) { throw 'TEST_FAILURE: bounded pilot must pass without claiming a full campaign' }
    if ($pilot.branch -ne 'source_native' -or $pilot.raw_runs -ne 10 -or $pilot.expected_full_campaign_runs -ne 66) { throw 'TEST_FAILURE: bounded pilot run-count contract mismatch' }
    if (@($pilot.results).Count -ne 10 -or @($pilot.run_evidence_ids).Count -ne 10) { throw 'TEST_FAILURE: bounded pilot must contain ten unique case results and evidence IDs' }
    if (@($pilot.results | Where-Object status -ne 'passed').Count -ne 0) { throw 'TEST_FAILURE: bounded pilot contains a failed case result' }
    if (@($pilot.results | Where-Object { $_.terminal_state -notin @('SUCCEEDED', 'RECOVERED', 'STOPPED', 'REJECTED', 'FAILED') }).Count -ne 0) { throw 'TEST_FAILURE: bounded pilot contains an invalid terminal state' }
    foreach ($result in @($pilot.results)) {
        if (-not (Test-Path -LiteralPath (Join-Path $workspaceFull $result.run_relative_path) -PathType Leaf)) { throw "TEST_FAILURE: missing raw run evidence for $($result.case_id)" }
    }
    foreach ($file in @(Get-ChildItem -LiteralPath $testOutputRoot -Recurse -File)) {
        if (([IO.File]::ReadAllBytes($file.FullName) -contains [byte]13)) { throw "TEST_FAILURE: generated evidence must use LF line endings: $($file.FullName)" }
    }
    foreach ($name in @('pilot.json', 'pilot.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $testOutputRoot $name) -PathType Leaf)) { throw "TEST_FAILURE: missing bounded pilot artifact '$name'" }
    }
    Write-Output 'SOURCE_NATIVE_BOUNDED_TESTS: 1/1 PASS'
} finally {
    if (Test-Path -LiteralPath $testOutputRoot) { [IO.Directory]::Delete([IO.Path]::GetFullPath($testOutputRoot), $true) }
}

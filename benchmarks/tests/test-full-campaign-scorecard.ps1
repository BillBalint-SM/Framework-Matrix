param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$runsRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\runs'
$runRoot = Join-Path $runsRoot 'control-bounded-pilot-20260804'
$validator = Join-Path $workspaceFull 'benchmarks\scripts\validate-full-campaign-scorecard.ps1'
$schema = Join-Path $workspaceFull 'benchmarks\schemas\full-campaign-scorecard.schema.json'
$testOutput = Join-Path $runsRoot ('test-full-scorecard-' + [guid]::NewGuid().ToString('N') + '.json')
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $validator -PathType Leaf) -or -not (Test-Path -LiteralPath $schema -PathType Leaf)) { throw 'TEST_FAILURE: full-campaign scorecard validator and schema must exist' }
try {
    & $pwshPath -NoLogo -NoProfile -NonInteractive -File $validator -WorkspaceRoot $workspaceFull -RunRoot $runRoot -OutputPath $testOutput 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { throw 'TEST_FAILURE: incomplete campaign was accepted without -AllowIncomplete' }
    $errorOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $validator -WorkspaceRoot $workspaceFull -RunRoot $runRoot -OutputPath $testOutput -AllowIncomplete 2>&1
    if ($LASTEXITCODE -ne 0) { $errorOutput | Write-Output; throw "TEST_FAILURE: incomplete scorecard validation failed with $LASTEXITCODE" }
    if (-not (Test-Json -LiteralPath $testOutput -SchemaFile $schema)) { throw 'TEST_FAILURE: generated incomplete scorecard is not schema-valid' }
    $ledger = Get-Content -Raw -LiteralPath $testOutput | ConvertFrom-Json
    if ($ledger.outcome -ne 'UNSCORED' -or $ledger.status -ne 'benchmark_pending' -or $ledger.benchmark.completed_raw_runs -ge 66) { throw 'TEST_FAILURE: incomplete scorecard did not fail closed to UNSCORED' }
    $mutatedPath = Join-Path $runsRoot ('test-full-scorecard-mutated-' + [guid]::NewGuid().ToString('N') + '.json')
    $mutated = $ledger | ConvertTo-Json -Depth 100 | ConvertFrom-Json
    $mutated.status = 'invalid'
    $mutated | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $mutatedPath -Encoding utf8NoBOM
    try {
        $invalidAccepted = $false
        try { $invalidAccepted = Test-Json -LiteralPath $mutatedPath -SchemaFile $schema -ErrorAction Stop } catch { $invalidAccepted = $false }
        if ($invalidAccepted) { throw 'TEST_FAILURE: invalid scorecard status was accepted' }
    } finally {
        if (Test-Path -LiteralPath $mutatedPath) { [IO.File]::Delete($mutatedPath) }
    }
    Write-Output 'FULL_CAMPAIGN_SCORECARD_TESTS: 3/3 PASS'
} finally {
    if (Test-Path -LiteralPath $testOutput) { [IO.File]::Delete($testOutput) }
}

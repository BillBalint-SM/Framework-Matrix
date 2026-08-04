param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$runnerPath = Join-Path $workspaceFull 'benchmarks\runners\abk_native\run.ps1'
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$snapshotPath = Join-Path $workspaceFull 'benchmarks\snapshots\abk-native-ai-booster-kit-feature.json'
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

function Get-Sha256([string]$Path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }
function Write-Json([object]$Document, [string]$Path) { $Document | ConvertTo-Json -Depth 30 -Compress | Set-Content -LiteralPath $Path -Encoding utf8NoBOM }

foreach ($path in @($runnerPath, $campaignPath, $schemaPath, $snapshotPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "TEST_FAILURE: required ABK-native contract file missing '$path'" }
}

$testRoot = Join-Path $campaignRoot ('runs\test-abk-native-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
    $runRoot = Join-Path $testRoot 'abk_native\R1'
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    $fixtureRelative = 'fixtures/COM-01-normal-primary.json'
    $fixturePath = Join-Path $campaignRoot ($fixtureRelative -replace '/', '\')
    $requestPath = Join-Path $runRoot 'request.json'
    $request = [ordered]@{
        schema_version = '1.0.0'
        request_id = 'abk:run-request:artifact-dag-core-v1-abk-native-com-01-r1'
        campaign_id = 'abk:benchmark-campaign:artifact-dag-core-v1'
        branch = 'abk_native'
        case_id = 'COM-01-normal-primary'
        repeat = 1
        fixture = [ordered]@{ relative_path = $fixtureRelative; sha256 = Get-Sha256 $fixturePath }
        contracts = [ordered]@{
            campaign_relative_path = [IO.Path]::GetRelativePath($runRoot, $campaignPath).Replace('\', '/')
            campaign_sha256 = Get-Sha256 $campaignPath
            schema_relative_path = [IO.Path]::GetRelativePath($runRoot, $schemaPath).Replace('\', '/')
            schema_sha256 = Get-Sha256 $schemaPath
        }
        snapshot = [ordered]@{
            relative_path = 'benchmarks/snapshots/abk-native-ai-booster-kit-feature.json'
            sha256 = Get-Sha256 $snapshotPath
        }
        run = [ordered]@{
            run_id = 'abk:run:artifact-dag-core-v1-abk-native-com-01-r1'
            relative_run_root = [IO.Path]::GetRelativePath($campaignRoot, $runRoot).Replace('\', '/')
            timeout_seconds = 120
            stop_condition_id = 'readiness-and-evidence-emitted'
        }
        authority = [ordered]@{
            read_roots = @('campaign', 'fixture', 'schema', 'metadata_snapshot')
            write_root = 'run'
            network = $false
            credentials = $false
            production_resources = $false
            external_writes = $false
            git_mutation = $false
            process_spawn = $false
        }
        runner = [ordered]@{
            contract_version = 'abk-native-runner-v1'
            executable_sha256 = Get-Sha256 $runnerPath
            host = 'codex'
        }
    }
    Write-Json $request $requestPath

    $runnerOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $runnerPath -RequestPath $requestPath 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 2) {
        $runnerOutput | Write-Output
        if (Test-Path -LiteralPath (Join-Path $runRoot 'run.json')) { Get-Content -LiteralPath (Join-Path $runRoot 'run.json') | Write-Output }
        throw "TEST_FAILURE: ABK-native not-comparable run exited with $exitCode"
    }
    foreach ($name in @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'output-inventory.json', 'oracle-result.json', 'readiness.json', 'provenance.json', 'operator.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $runRoot $name) -PathType Leaf)) { throw "TEST_FAILURE: missing ABK-native evidence '$name'" }
    }
    $run = Get-Content -Raw -LiteralPath (Join-Path $runRoot 'run.json') | ConvertFrom-Json
    if ($run.branch -ne 'abk_native' -or $run.terminal_state -ne 'REJECTED' -or $run.exit_code -ne 2) { throw 'TEST_FAILURE: ABK-native run terminal contract mismatch' }
    if ($run.error.code -ne 'NOT_COMPARABLE') { throw "TEST_FAILURE: expected NOT_COMPARABLE, got $($run.error.code): $($run.error.message)" }
    $oracle = Get-Content -Raw -LiteralPath (Join-Path $runRoot 'oracle-result.json') | ConvertFrom-Json
    if ($oracle.status -ne 'inconclusive' -or $oracle.error.code -ne 'NOT_COMPARABLE') { throw 'TEST_FAILURE: ABK-native oracle did not preserve explicit non-comparable result' }

    Write-Output 'ABK_NATIVE_RUNNER_TESTS: 1/1 PASS'
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

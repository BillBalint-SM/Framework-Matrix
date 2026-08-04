param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$runnerPath = Join-Path $workspaceFull 'benchmarks\runners\source_native\run.ps1'
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) { throw 'TEST_FAILURE: source_native runner executable must exist' }

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Write-Json([object]$Document, [string]$Path) {
    $Document | ConvertTo-Json -Depth 30 -Compress | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

$testRoot = Join-Path $campaignRoot ('runs\test-source-native-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
    $runRoot = Join-Path $testRoot 'source_native\R1'
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    $fixtureRelative = 'fixtures/COM-01-normal-primary.json'
    $fixturePath = Join-Path $campaignRoot ($fixtureRelative -replace '/', '\')
    $requestPath = Join-Path $runRoot 'request.json'
    $request = [ordered]@{
        schema_version = '1.0.0'
        request_id = 'abk:run-request:artifact-dag-core-v1-source-native-com-01-r1'
        campaign_id = 'abk:benchmark-campaign:artifact-dag-core-v1'
        branch = 'source_native'
        case_id = 'COM-01-normal-primary'
        repeat = 1
        fixture = [ordered]@{ relative_path = $fixtureRelative; sha256 = Get-Sha256 $fixturePath }
        contracts = [ordered]@{
            campaign_relative_path = [IO.Path]::GetRelativePath($runRoot, $campaignPath).Replace('\', '/')
            campaign_sha256 = Get-Sha256 $campaignPath
            schema_relative_path = [IO.Path]::GetRelativePath($runRoot, $schemaPath).Replace('\', '/')
            schema_sha256 = Get-Sha256 $schemaPath
        }
        run = [ordered]@{
            run_id = 'abk:run:artifact-dag-core-v1-source-native-com-01-r1'
            relative_run_root = [IO.Path]::GetRelativePath($campaignRoot, $runRoot).Replace('\', '/')
            timeout_seconds = 120
            stop_condition_id = 'readiness-and-evidence-emitted'
        }
        authority = [ordered]@{
            read_roots = @('campaign', 'fixture', 'schema', 'source_snapshot')
            write_root = 'run'
            network = $false
            credentials = $false
            production_resources = $false
            external_writes = $false
            git_mutation = $false
            process_spawn = $false
        }
        environment = [ordered]@{
            HOME = 'env/HOME'
            USERPROFILE = 'env/USERPROFILE'
            APPDATA = 'env/APPDATA'
            LOCALAPPDATA = 'env/LOCALAPPDATA'
            XDG_CONFIG_HOME = 'env/XDG_CONFIG_HOME'
            XDG_DATA_HOME = 'env/XDG_DATA_HOME'
        }
        runner = [ordered]@{
            contract_version = 'source-native-runner-v1'
            executable_sha256 = Get-Sha256 $runnerPath
            host = 'codex'
        }
    }
    Write-Json $request $requestPath

    $runnerOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $runnerPath -RequestPath $requestPath 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 2) {
        $runnerOutput | Write-Output
        $evidenceRun = Join-Path $runRoot 'run.json'
        if (Test-Path -LiteralPath $evidenceRun) { Get-Content -LiteralPath $evidenceRun | Write-Output }
        throw "TEST_FAILURE: source_native not-comparable run exited with $exitCode"
    }
    foreach ($name in @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'output-inventory.json', 'oracle-result.json', 'readiness.json', 'provenance.json', 'operator.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $runRoot $name) -PathType Leaf)) { throw "TEST_FAILURE: missing source_native evidence '$name'" }
    }
    $run = Get-Content -Raw -LiteralPath (Join-Path $runRoot 'run.json') | ConvertFrom-Json
    if ($run.branch -ne 'source_native' -or $run.terminal_state -ne 'REJECTED' -or $run.exit_code -ne 2) { throw 'TEST_FAILURE: source_native run terminal contract mismatch' }
    if ($run.error.code -ne 'NOT_COMPARABLE') { throw "TEST_FAILURE: expected NOT_COMPARABLE, got $($run.error.code)" }
    $oracle = Get-Content -Raw -LiteralPath (Join-Path $runRoot 'oracle-result.json') | ConvertFrom-Json
    if ($oracle.status -ne 'inconclusive' -or $oracle.error.code -ne 'NOT_COMPARABLE') { throw 'TEST_FAILURE: oracle did not preserve explicit not-comparable result' }

    Write-Output 'SOURCE_NATIVE_RUNNER_TESTS: 1/1 PASS'
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

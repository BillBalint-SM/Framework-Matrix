param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$runnerPath = Join-Path $workspaceFull 'benchmarks\runners\control\run.ps1'
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$campaignSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$runSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\control-run.schema.json'
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $runnerPath -PathType Leaf)) {
    throw 'TEST_FAILURE: control runner executable must exist'
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Write-Json([object]$Document, [string]$Path) {
    $Document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function New-Request([string]$CaseId, [string]$FixturePath, [string]$RunRoot, [string]$RequestId) {
    $runRelative = [IO.Path]::GetRelativePath($campaignRoot, $RunRoot).Replace('\', '/')
    $fixtureHash = if ($FixturePath -eq '../outside.json') { ('a' * 64) } else { Get-Sha256 (Join-Path $campaignRoot $FixturePath) }
    $campaignRelativePath = [IO.Path]::GetRelativePath($RunRoot, $campaignPath).Replace('\', '/')
    $schemaRelativePath = [IO.Path]::GetRelativePath($RunRoot, $campaignSchemaPath).Replace('\', '/')
    return [pscustomobject]@{
        schema_version = '1.0.0'
        request_id = $RequestId
        campaign_id = 'abk:benchmark-campaign:artifact-dag-core-v1'
        branch = 'control'
        case_id = $CaseId
        repeat = 1
        fixture = [pscustomobject]@{ relative_path = $FixturePath; sha256 = $fixtureHash }
        contracts = [pscustomobject]@{
            campaign_relative_path = $campaignRelativePath
            campaign_sha256 = Get-Sha256 $campaignPath
            schema_relative_path = $schemaRelativePath
            schema_sha256 = Get-Sha256 $campaignSchemaPath
        }
        run = [pscustomobject]@{
            run_id = $RequestId.Replace('run-request', 'run')
            relative_run_root = $runRelative
            timeout_seconds = 120
            stop_condition_id = 'readiness-and-evidence-emitted'
        }
        authority = [pscustomobject]@{
            read_roots = @('campaign', 'fixture', 'schema')
            write_root = 'run'
            network = $false
            credentials = $false
            production_resources = $false
            external_writes = $false
            git_mutation = $false
            process_spawn = $false
        }
        environment = [pscustomobject]@{
            HOME = 'env/HOME'
            USERPROFILE = 'env/USERPROFILE'
            APPDATA = 'env/APPDATA'
            LOCALAPPDATA = 'env/LOCALAPPDATA'
            XDG_CONFIG_HOME = 'env/XDG_CONFIG_HOME'
            XDG_DATA_HOME = 'env/XDG_DATA_HOME'
        }
        runner = [pscustomobject]@{
            contract_version = 'control-runner-v1'
            executable_sha256 = Get-Sha256 $runnerPath
            host = 'codex'
        }
    }
}

function Invoke-Runner([string]$RequestPath) {
    & $pwshPath -NoLogo -NoProfile -NonInteractive -File $runnerPath -RequestPath $RequestPath 2>&1 | Out-Null
    return $LASTEXITCODE
}

function Assert-RequiredFiles([string]$RunRoot, [string[]]$Names) {
    foreach ($name in $Names) {
        $path = Join-Path $RunRoot $name
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            throw "TEST_FAILURE: missing required runner evidence '$name'"
        }
    }
}

function Assert-RunSchema([string]$RunPath) {
    try {
        if (-not (Test-Json -LiteralPath $RunPath -SchemaFile $runSchemaPath)) { throw 'invalid' }
    } catch {
        throw "TEST_FAILURE: run evidence '$RunPath' does not satisfy control-run.schema.json"
    }
}

function Get-Manifest([string]$Root, [string]$ExcludedPrefix) {
    $manifest = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $Root -Recurse -File)) {
        if ($file.FullName.StartsWith($ExcludedPrefix, [StringComparison]::OrdinalIgnoreCase)) { continue }
        $relative = [IO.Path]::GetRelativePath($Root, $file.FullName).Replace('\', '/')
        $manifest[$relative] = Get-Sha256 $file.FullName
    }
    return $manifest
}

function Assert-ManifestUnchanged([hashtable]$Before, [string]$Root, [string]$ExcludedPrefix) {
    $after = Get-Manifest $Root $ExcludedPrefix
    if ($Before.Count -ne $after.Count) { throw 'TEST_FAILURE: runner wrote or removed a file outside an owner run root' }
    foreach ($key in $Before.Keys) {
        if (-not $after.ContainsKey($key) -or $after[$key] -ne $Before[$key]) {
            throw "TEST_FAILURE: runner changed '$key' outside an owner run root"
        }
    }
}

$outsideManifest = Get-Manifest $campaignRoot '___no_test_root___'
$testRoot = Join-Path $campaignRoot ('runs\test-control-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
    $successRoot = Join-Path $testRoot 'success\control\R1'
    New-Item -ItemType Directory -Path $successRoot -Force | Out-Null
    $successRequestPath = Join-Path $successRoot 'request.json'
    Write-Json (New-Request 'COM-01-normal-primary' 'fixtures/COM-01-normal-primary.json' $successRoot 'abk:run-request:artifact-dag-core-v1-control-com-01-r1') $successRequestPath
    $successExit = Invoke-Runner $successRequestPath
    if ($successExit -ne 0) { throw 'TEST_FAILURE: valid control run did not exit 0' }
    Assert-RequiredFiles $successRoot @('run.json', 'readiness.json', 'provenance.json', 'operator.md', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'output-inventory.json', 'oracle-result.json')
    Assert-RunSchema (Join-Path $successRoot 'run.json')
    $successRun = Get-Content -Raw -LiteralPath (Join-Path $successRoot 'run.json') | ConvertFrom-Json
    if ($successRun.terminal_state -ne 'SUCCEEDED' -or $successRun.exit_code -ne 0) { throw 'TEST_FAILURE: valid control run did not persist SUCCEEDED/0' }

    $invalidRoot = Join-Path $testRoot 'invalid\control\R1'
    New-Item -ItemType Directory -Path $invalidRoot -Force | Out-Null
    $invalidRequestPath = Join-Path $invalidRoot 'request.json'
    Write-Json (New-Request 'COM-05-invalid-input' 'fixtures/COM-05-invalid-input.json' $invalidRoot 'abk:run-request:artifact-dag-core-v1-control-com-05-r1') $invalidRequestPath
    $invalidExit = Invoke-Runner $invalidRequestPath
    if ($invalidExit -notin @(2, 3)) { throw "TEST_FAILURE: invalid graph exited with unexpected code $invalidExit" }
    Assert-RequiredFiles $invalidRoot @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'output-inventory.json', 'oracle-result.json')
    Assert-RunSchema (Join-Path $invalidRoot 'run.json')
    $invalidRun = Get-Content -Raw -LiteralPath (Join-Path $invalidRoot 'run.json') | ConvertFrom-Json
    if ($invalidRun.error.code -ne 'UNKNOWN_ARTIFACT_REFERENCE' -or $invalidRun.readiness) { throw 'TEST_FAILURE: invalid graph did not persist typed failure without readiness' }

    $unsafeRoot = Join-Path $testRoot 'unsafe\control\R1'
    New-Item -ItemType Directory -Path $unsafeRoot -Force | Out-Null
    $unsafeRequestPath = Join-Path $unsafeRoot 'request.json'
    Write-Json (New-Request 'COM-01-normal-primary' '../outside.json' $unsafeRoot 'abk:run-request:artifact-dag-core-v1-control-unsafe-r1') $unsafeRequestPath
    $unsafeExit = Invoke-Runner $unsafeRequestPath
    if ($unsafeExit -ne 2) { throw "TEST_FAILURE: unsafe path exited with unexpected code $unsafeExit" }
    Assert-RunSchema (Join-Path $unsafeRoot 'run.json')
    $unsafeRun = Get-Content -Raw -LiteralPath (Join-Path $unsafeRoot 'run.json') | ConvertFrom-Json
    if ($unsafeRun.terminal_state -ne 'REJECTED' -or $unsafeRun.error.code -notin @('REQUEST_SCHEMA_INVALID', 'PATH_OUT_OF_ROOT')) { throw 'TEST_FAILURE: unsafe path was not rejected before graph parsing' }
    Assert-ManifestUnchanged $outsideManifest $campaignRoot $testRoot

    Write-Output 'CONTROL_RUNNER_TESTS: 3/3 PASS'
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

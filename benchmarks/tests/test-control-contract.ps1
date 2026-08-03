param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$requestSchemaPath = Join-Path $WorkspaceRoot 'benchmarks\schemas\control-run-request.schema.json'
$runSchemaPath = Join-Path $WorkspaceRoot 'benchmarks\schemas\control-run.schema.json'

function Write-Document([object]$Document, [string]$Path) {
    $Document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function New-ValidRequest {
    return [pscustomobject]@{
        schema_version = '1.0.0'
        request_id = 'abk:run-request:artifact-dag-core-v1-control-com-01-r1'
        campaign_id = 'abk:benchmark-campaign:artifact-dag-core-v1'
        branch = 'control'
        case_id = 'COM-01-normal-primary'
        repeat = 1
        fixture = [pscustomobject]@{
            relative_path = 'fixtures/COM-01-normal-primary.json'
            sha256 = ('a' * 64)
        }
        contracts = [pscustomobject]@{
            campaign_relative_path = '../../campaign.json'
            campaign_sha256 = ('b' * 64)
            schema_relative_path = '../../../schemas/benchmark-campaign.schema.json'
            schema_sha256 = ('c' * 64)
        }
        run = [pscustomobject]@{
            run_id = 'abk:run:artifact-dag-core-v1-control-com-01-r1'
            relative_run_root = 'runs/COM-01-normal-primary/control/R1'
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
            executable_sha256 = ('d' * 64)
            host = 'codex'
        }
    }
}

function New-ValidRun {
    return [pscustomobject]@{
        schema_version = '1.0.0'
        run_id = 'abk:run:artifact-dag-core-v1-control-com-01-r1'
        request_id = 'abk:run-request:artifact-dag-core-v1-control-com-01-r1'
        campaign_id = 'abk:benchmark-campaign:artifact-dag-core-v1'
        branch = 'control'
        case_id = 'COM-01-normal-primary'
        repeat = 1
        runner = [pscustomobject]@{
            contract_version = 'control-runner-v1'
            executable_sha256 = ('d' * 64)
            host = 'codex'
        }
        input = [pscustomobject]@{
            fixture_sha256 = ('a' * 64)
            campaign_sha256 = ('b' * 64)
            schema_sha256 = ('c' * 64)
            request_sha256 = ('e' * 64)
        }
        started_at = '2026-08-03T18:00:00Z'
        ended_at = '2026-08-03T18:00:01Z'
        duration_ms = 1000
        terminal_state = 'SUCCEEDED'
        exit_code = 0
        error = $null
        readiness = [pscustomobject]@{ relative_path = 'readiness.json'; sha256 = ('f' * 64) }
        provenance = [pscustomobject]@{ relative_path = 'provenance.json'; sha256 = ('1' * 64) }
        state_before = [pscustomobject]@{ manifest_sha256 = ('2' * 64) }
        state_after = [pscustomobject]@{ manifest_sha256 = ('2' * 64) }
        recovery = $null
        handoff = $null
    }
}

function Assert-ValidSchema([string]$Name, [object]$Document, [string]$SchemaPath, [string]$TempRoot) {
    $path = Join-Path $TempRoot ($Name + '.json')
    Write-Document $Document $path
    if (-not (Test-DocumentSchema $path $SchemaPath)) {
        throw "TEST_FAILURE: valid $Name document was rejected"
    }
}

function Assert-InvalidSchema([string]$Name, [object]$Document, [string]$SchemaPath, [string]$TempRoot) {
    $path = Join-Path $TempRoot ($Name + '.json')
    Write-Document $Document $path
    if (Test-DocumentSchema $path $SchemaPath) {
        throw "TEST_FAILURE: invalid $Name document was accepted"
    }
}

function Test-DocumentSchema([string]$DocumentPath, [string]$SchemaPath) {
    try {
        return [bool](Test-Json -LiteralPath $DocumentPath -SchemaFile $SchemaPath)
    } catch {
        return $false
    }
}

if (-not (Test-Path -LiteralPath $requestSchemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $runSchemaPath -PathType Leaf)) {
    throw 'TEST_FAILURE: control request/run schemas must exist'
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('framework-matrix-control-contract-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    $validRequest = New-ValidRequest
    $validRun = New-ValidRun
    Assert-ValidSchema 'valid-request' $validRequest $requestSchemaPath $tempRoot
    Assert-ValidSchema 'valid-run' $validRun $runSchemaPath $tempRoot

    $unknownField = $validRequest | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $unknownField | Add-Member -NotePropertyName unexpected -NotePropertyValue $true
    Assert-InvalidSchema 'unknown-request-field' $unknownField $requestSchemaPath $tempRoot

    $wrongBranch = $validRequest | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $wrongBranch.branch = 'source_native'
    Assert-InvalidSchema 'wrong-branch' $wrongBranch $requestSchemaPath $tempRoot

    $unsafePath = $validRequest | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $unsafePath.fixture.relative_path = '../outside.json'
    Assert-InvalidSchema 'unsafe-fixture-path' $unsafePath $requestSchemaPath $tempRoot

    $wrongExit = $validRun | ConvertTo-Json -Depth 30 | ConvertFrom-Json
    $wrongExit.exit_code = 99
    Assert-InvalidSchema 'unsupported-exit-code-fails-closed' $wrongExit $runSchemaPath $tempRoot

    Write-Output 'CONTROL_CONTRACT_TESTS: 6/6 PASS'
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

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

function New-RunRequest([string]$CaseId, [int]$Repeat, [string]$RunRoot, [string]$FixtureRelative, [string]$RunSlug) {
    $fixturePath = Join-Path $campaignRoot ($FixtureRelative -replace '/', '\')
    return [ordered]@{
        schema_version = '1.0.0'
        request_id = "abk:run-request:artifact-dag-core-v1-source-native-$RunSlug"
        campaign_id = 'abk:benchmark-campaign:artifact-dag-core-v1'
        branch = 'source_native'
        case_id = $CaseId
        repeat = $Repeat
        fixture = [ordered]@{ relative_path = $FixtureRelative; sha256 = Get-Sha256 $fixturePath }
        contracts = [ordered]@{
            campaign_relative_path = [IO.Path]::GetRelativePath($RunRoot, $campaignPath).Replace('\', '/')
            campaign_sha256 = Get-Sha256 $campaignPath
            schema_relative_path = [IO.Path]::GetRelativePath($RunRoot, $schemaPath).Replace('\', '/')
            schema_sha256 = Get-Sha256 $schemaPath
        }
        run = [ordered]@{
            run_id = "abk:run:artifact-dag-core-v1-source-native-$RunSlug"
            relative_run_root = [IO.Path]::GetRelativePath($campaignRoot, $RunRoot).Replace('\', '/')
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
}

function Assert-Equal([object]$Actual, [object]$Expected, [string]$Message) {
    if ($Actual -ne $Expected) { throw "TEST_FAILURE: $Message (actual='$Actual', expected='$Expected')" }
}

function Invoke-SourceCase([hashtable]$Case, [string]$TestRoot) {
    $runRoot = Join-Path $TestRoot ("source_native\$($Case.slug)\R$($Case.repeat)")
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    $requestPath = Join-Path $runRoot 'request.json'
    Write-Json (New-RunRequest $Case.case_id $Case.repeat $runRoot $Case.fixture $Case.slug) $requestPath
    $runnerOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $runnerPath -RequestPath $requestPath 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne $Case.exit_code) {
        $runnerOutput | Write-Output
        if (Test-Path -LiteralPath (Join-Path $runRoot 'run.json')) { Get-Content -Raw -LiteralPath (Join-Path $runRoot 'run.json') | Write-Output }
        throw "TEST_FAILURE: $($Case.slug) exited with $exitCode (expected $($Case.exit_code))"
    }

    foreach ($name in @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'output-inventory.json', 'oracle-result.json', 'operator.md')) {
        if (-not (Test-Path -LiteralPath (Join-Path $runRoot $name) -PathType Leaf)) { throw "TEST_FAILURE: $($Case.slug) missing evidence '$name'" }
    }
    $run = Get-Content -Raw -LiteralPath (Join-Path $runRoot 'run.json') | ConvertFrom-Json
    Assert-Equal $run.branch 'source_native' "$($Case.slug) branch"
    Assert-Equal $run.terminal_state $Case.terminal_state "$($Case.slug) terminal state"
    Assert-Equal $run.exit_code $Case.exit_code "$($Case.slug) run exit code"
    Assert-Equal $run.runner.contract_version 'source-native-runner-v1' "$($Case.slug) runner contract"
    if ($Case.error_code) { Assert-Equal $run.error.code $Case.error_code "$($Case.slug) error code" }
    $oracle = Get-Content -Raw -LiteralPath (Join-Path $runRoot 'oracle-result.json') | ConvertFrom-Json
    Assert-Equal $oracle.status $Case.oracle_status "$($Case.slug) oracle status"

    $readinessPath = Join-Path $runRoot 'readiness.json'
    if ($Case.readiness) {
        if (-not (Test-Path -LiteralPath $readinessPath -PathType Leaf)) { throw "TEST_FAILURE: $($Case.slug) readiness evidence missing" }
        if ($null -eq $run.readiness) { throw "TEST_FAILURE: $($Case.slug) run readiness reference missing" }
    } elseif (Test-Path -LiteralPath $readinessPath -PathType Leaf) {
        throw "TEST_FAILURE: $($Case.slug) unexpectedly emitted readiness evidence"
    }

    if ($Case.recovery) {
        $recoveryPath = Join-Path $runRoot 'recovery.json'
        if (-not (Test-Path -LiteralPath $recoveryPath -PathType Leaf)) { throw "TEST_FAILURE: $($Case.slug) recovery evidence missing" }
        if ($null -eq $run.recovery -or $run.recovery.removed -ne $true) { throw "TEST_FAILURE: $($Case.slug) recovery contract mismatch" }
        if (Test-Path -LiteralPath (Join-Path $runRoot 'derived-state.json')) { throw "TEST_FAILURE: $($Case.slug) derived state was not rolled back" }
    }
    if ($Case.handoff) {
        $handoffPath = Join-Path $runRoot 'handoff.json'
        if (-not (Test-Path -LiteralPath $handoffPath -PathType Leaf)) { throw "TEST_FAILURE: $($Case.slug) handoff evidence missing" }
        if ($null -eq $run.handoff -or $run.handoff.verified -ne $true) { throw "TEST_FAILURE: $($Case.slug) handoff contract mismatch" }
    }
    return $runRoot
}

$testRoot = Join-Path $campaignRoot ('runs\test-source-native-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
    $cases = @(
        [ordered]@{ slug = 'com-01-success'; case_id = 'COM-01-normal-primary'; fixture = 'fixtures/COM-01-normal-primary.json'; repeat = 1; exit_code = 0; terminal_state = 'SUCCEEDED'; oracle_status = 'passed'; error_code = $null; readiness = $true; recovery = $false; handoff = $false },
        [ordered]@{ slug = 'com-05-unknown-reference'; case_id = 'COM-05-invalid-input'; fixture = 'fixtures/COM-05-invalid-input.json'; repeat = 1; exit_code = 3; terminal_state = 'FAILED'; oracle_status = 'failed'; error_code = 'UNKNOWN_ARTIFACT_REFERENCE'; readiness = $false; recovery = $false; handoff = $false },
        [ordered]@{ slug = 'spc-01-boundary-rejection'; case_id = 'SPC-01-domain-boundary'; fixture = 'fixtures/SPC-01-domain-boundary.json'; repeat = 1; exit_code = 2; terminal_state = 'REJECTED'; oracle_status = 'inconclusive'; error_code = 'DEPENDENCY_OUT_OF_ROOT'; readiness = $false; recovery = $false; handoff = $false },
        [ordered]@{ slug = 'com-06-stopped'; case_id = 'COM-06-stop-interrupt'; fixture = 'fixtures/COM-06-stop-interrupt.json'; repeat = 1; exit_code = 130; terminal_state = 'STOPPED'; oracle_status = 'stopped'; error_code = 'INTERRUPTED'; readiness = $true; recovery = $false; handoff = $false },
        [ordered]@{ slug = 'spc-03-recovered'; case_id = 'SPC-03-recovery-rollback'; fixture = 'fixtures/SPC-03-recovery-rollback.json'; repeat = 1; exit_code = 0; terminal_state = 'RECOVERED'; oracle_status = 'passed'; error_code = 'RECOVERED_AFTER_FAILURE'; readiness = $true; recovery = $true; handoff = $false },
        [ordered]@{ slug = 'spc-04-handoff'; case_id = 'SPC-04-composition-handoff'; fixture = 'fixtures/SPC-04-composition-handoff.json'; repeat = 1; exit_code = 0; terminal_state = 'SUCCEEDED'; oracle_status = 'passed'; error_code = $null; readiness = $true; recovery = $false; handoff = $true }
    )
    foreach ($case in $cases) { Invoke-SourceCase $case $testRoot | Out-Null }
    Write-Output "SOURCE_NATIVE_RUNNER_TESTS: $($cases.Count)/$($cases.Count) PASS"
} finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

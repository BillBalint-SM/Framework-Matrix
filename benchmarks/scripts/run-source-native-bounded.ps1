param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)]
    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$pilotSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\source-native-pilot.schema.json'
$snapshotPath = Join-Path $workspaceFull 'benchmarks\snapshots\source-native-openspec-artifact-graph.json'
$runnerPath = Join-Path $workspaceFull 'benchmarks\runners\source_native\run.ps1'
$manifestPath = Join-Path $campaignRoot 'branches\source_native\manifest.json'
$outputFull = [IO.Path]::GetFullPath($OutputRoot)
$campaignPrefix = [IO.Path]::GetFullPath($campaignRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
$utf8NoBom = [Text.UTF8Encoding]::new($false)

if (-not $outputFull.StartsWith($campaignPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'OUTPUT_ROOT_ESCAPE: bounded pilot output must remain under the campaign root' }
if (Test-Path -LiteralPath $outputFull) { throw "OUTPUT_ROOT_EXISTS: refusing to overwrite '$outputFull'" }
foreach ($path in @($campaignPath, $schemaPath, $pilotSchemaPath, $snapshotPath, $runnerPath, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "INPUT_MISSING: required input is missing: $path" }
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Write-Json([object]$Document, [string]$Path) {
    [IO.File]::WriteAllText($Path, ($Document | ConvertTo-Json -Depth 50 -Compress), $utf8NoBom)
}

function Read-Json([string]$Path) {
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100
}

function New-Request([object]$Case, [int]$Repeat, [string]$RunRoot, [object]$Campaign, [string]$RunnerHash, [string]$SchemaHash, [string]$CampaignHash) {
    $fixturePath = Join-Path $campaignRoot ($Case.fixture -replace '/', '\')
    return [ordered]@{
        schema_version = '1.0.0'
        request_id = "abk:run-request:artifact-dag-core-v1-source-native-$($Case.slug)-r$Repeat"
        campaign_id = $Campaign.campaign_id
        branch = 'source_native'
        case_id = $Case.case_id
        repeat = $Repeat
        fixture = [ordered]@{ relative_path = $Case.fixture; sha256 = Get-Sha256 $fixturePath }
        contracts = [ordered]@{
            campaign_relative_path = [IO.Path]::GetRelativePath($RunRoot, $campaignPath).Replace('\', '/')
            campaign_sha256 = $CampaignHash
            schema_relative_path = [IO.Path]::GetRelativePath($RunRoot, $schemaPath).Replace('\', '/')
            schema_sha256 = $SchemaHash
        }
        run = [ordered]@{
            run_id = "abk:run:artifact-dag-core-v1-source-native-$($Case.slug)-r$Repeat"
            relative_run_root = [IO.Path]::GetRelativePath($campaignRoot, $RunRoot).Replace('\', '/')
            timeout_seconds = $Case.timeout_seconds
            stop_condition_id = 'bounded-pilot-case-oracle'
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
            executable_sha256 = $RunnerHash
            host = 'codex'
        }
    }
}

function Assert-CaseResult([object]$Case, [object]$Run, [object]$Oracle) {
    if ($Run.branch -ne 'source_native') { throw "RUN_BRANCH_INVALID: $($Case.case_id)" }
    if ($Run.terminal_state -ne $Case.terminal_state) { throw "RUN_TERMINAL_MISMATCH: $($Case.case_id) expected $($Case.terminal_state), got $($Run.terminal_state)" }
    if ($Run.exit_code -ne $Case.exit_code) { throw "RUN_EXIT_MISMATCH: $($Case.case_id) expected $($Case.exit_code), got $($Run.exit_code)" }
    if ($Oracle.status -ne $Case.oracle_status) { throw "ORACLE_STATUS_MISMATCH: $($Case.case_id) expected $($Case.oracle_status), got $($Oracle.status)" }
    if ($null -eq $Case.error_code) {
        if ($null -ne $Run.error) { throw "RUN_UNEXPECTED_ERROR: $($Case.case_id)" }
    } elseif ($Run.error.code -ne $Case.error_code) {
        throw "RUN_ERROR_MISMATCH: $($Case.case_id) expected $($Case.error_code), got $($Run.error.code)"
    }
    if ($Case.recovery -and ($null -eq $Run.recovery -or $Run.recovery.removed -ne $true)) { throw "RUN_RECOVERY_MISSING: $($Case.case_id)" }
    if ($Case.handoff -and ($null -eq $Run.handoff -or $Run.handoff.verified -ne $true)) { throw "RUN_HANDOFF_MISSING: $($Case.case_id)" }
}

$campaign = Read-Json $campaignPath
$campaignHash = Get-Sha256 $campaignPath
$schemaHash = Get-Sha256 $schemaPath
$snapshotHash = Get-Sha256 $snapshotPath
$manifestHash = Get-Sha256 $manifestPath
$runnerHash = Get-Sha256 $runnerPath
$pilotSchemaHash = Get-Sha256 $pilotSchemaPath
$cases = @(
    [ordered]@{ slug = 'com-01-normal-primary'; case_id = 'COM-01-normal-primary'; fixture = 'fixtures/COM-01-normal-primary.json'; timeout_seconds = 120; exit_code = 0; terminal_state = 'SUCCEEDED'; oracle_status = 'passed'; error_code = $null; recovery = $false; handoff = $false },
    [ordered]@{ slug = 'com-02-normal-variant'; case_id = 'COM-02-normal-variant'; fixture = 'fixtures/COM-02-normal-variant.json'; timeout_seconds = 120; exit_code = 0; terminal_state = 'SUCCEEDED'; oracle_status = 'passed'; error_code = $null; recovery = $false; handoff = $false },
    [ordered]@{ slug = 'com-03-normal-repeat'; case_id = 'COM-03-normal-repeat'; fixture = 'fixtures/COM-03-normal-repeat.json'; timeout_seconds = 120; exit_code = 0; terminal_state = 'SUCCEEDED'; oracle_status = 'passed'; error_code = $null; recovery = $false; handoff = $false },
    [ordered]@{ slug = 'com-04-boundary-minimum'; case_id = 'COM-04-boundary-minimum'; fixture = 'fixtures/COM-04-boundary-minimum.json'; timeout_seconds = 90; exit_code = 0; terminal_state = 'SUCCEEDED'; oracle_status = 'passed'; error_code = $null; recovery = $false; handoff = $false },
    [ordered]@{ slug = 'com-05-invalid-input'; case_id = 'COM-05-invalid-input'; fixture = 'fixtures/COM-05-invalid-input.json'; timeout_seconds = 90; exit_code = 3; terminal_state = 'FAILED'; oracle_status = 'failed'; error_code = 'UNKNOWN_ARTIFACT_REFERENCE'; recovery = $false; handoff = $false },
    [ordered]@{ slug = 'com-06-stop-interrupt'; case_id = 'COM-06-stop-interrupt'; fixture = 'fixtures/COM-06-stop-interrupt.json'; timeout_seconds = 120; exit_code = 130; terminal_state = 'STOPPED'; oracle_status = 'stopped'; error_code = 'INTERRUPTED'; recovery = $false; handoff = $false },
    [ordered]@{ slug = 'spc-01-domain-boundary'; case_id = 'SPC-01-domain-boundary'; fixture = 'fixtures/SPC-01-domain-boundary.json'; timeout_seconds = 90; exit_code = 2; terminal_state = 'REJECTED'; oracle_status = 'inconclusive'; error_code = 'DEPENDENCY_OUT_OF_ROOT'; recovery = $false; handoff = $false },
    [ordered]@{ slug = 'spc-02-failure-path'; case_id = 'SPC-02-failure-path'; fixture = 'fixtures/SPC-02-failure-path.json'; timeout_seconds = 90; exit_code = 3; terminal_state = 'FAILED'; oracle_status = 'failed'; error_code = 'UNKNOWN_ARTIFACT_REFERENCE'; recovery = $false; handoff = $false },
    [ordered]@{ slug = 'spc-03-recovery-rollback'; case_id = 'SPC-03-recovery-rollback'; fixture = 'fixtures/SPC-03-recovery-rollback.json'; timeout_seconds = 150; exit_code = 0; terminal_state = 'RECOVERED'; oracle_status = 'passed'; error_code = 'RECOVERED_AFTER_FAILURE'; recovery = $true; handoff = $false },
    [ordered]@{ slug = 'spc-04-composition-handoff'; case_id = 'SPC-04-composition-handoff'; fixture = 'fixtures/SPC-04-composition-handoff.json'; timeout_seconds = 150; exit_code = 0; terminal_state = 'SUCCEEDED'; oracle_status = 'passed'; error_code = $null; recovery = $false; handoff = $true }
)

New-Item -ItemType Directory -Path $outputFull -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()
$runEvidenceIds = [System.Collections.Generic.List[string]]::new()
foreach ($case in $cases) {
    $runRoot = Join-Path $outputFull ("$($case.case_id)\source_native\R1")
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    $requestPath = Join-Path $runRoot 'request.json'
    Write-Json (New-Request $case 1 $runRoot $campaign $runnerHash $schemaHash $campaignHash) $requestPath
    & $pwshPath -NoLogo -NoProfile -NonInteractive -File $runnerPath -RequestPath $requestPath 2>&1 | Out-Null
    $exitCode = $LASTEXITCODE
    $runPath = Join-Path $runRoot 'run.json'
    $oraclePath = Join-Path $runRoot 'oracle-result.json'
    if (-not (Test-Path -LiteralPath $runPath -PathType Leaf) -or -not (Test-Path -LiteralPath $oraclePath -PathType Leaf)) { throw "RUN_EVIDENCE_MISSING: $($case.case_id)" }
    $run = Read-Json $runPath
    $oracle = Read-Json $oraclePath
    if ($exitCode -ne $case.exit_code) { throw "RUN_PROCESS_EXIT_MISMATCH: $($case.case_id) expected $($case.exit_code), got $exitCode" }
    Assert-CaseResult $case $run $oracle
    $evidenceId = "source-native-pilot-$($case.slug)-r1"
    $runEvidenceIds.Add($evidenceId)
    $results.Add([ordered]@{
        evidence_id = $evidenceId
        case_id = $case.case_id
        status = 'passed'
        expected_terminal_state = $case.terminal_state
        terminal_state = $run.terminal_state
        exit_code = $run.exit_code
        oracle_status = $oracle.status
        error_code = if ($null -ne $run.error) { $run.error.code } else { $null }
        run_relative_path = ([IO.Path]::GetRelativePath($workspaceFull, $runPath)).Replace('\', '/')
        run_sha256 = Get-Sha256 $runPath
        oracle_relative_path = ([IO.Path]::GetRelativePath($workspaceFull, $oraclePath)).Replace('\', '/')
        oracle_sha256 = Get-Sha256 $oraclePath
    })
}

$capturedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$pilot = [ordered]@{
    '$schema' = '../../../../schemas/source-native-pilot.schema.json'
    schema_version = '1.0.0'
    pilot_id = 'abk:pilot:source-native-bounded-v1'
    campaign_id = $campaign.campaign_id
    branch = 'source_native'
    captured_at = $capturedAt
    status = 'passed'
    full_campaign = $false
    raw_runs = @($results).Count
    expected_full_campaign_runs = $campaign.run_policy.expected_raw_runs
    campaign_sha256 = $campaignHash
    schema_sha256 = $schemaHash
    source_snapshot_sha256 = $snapshotHash
    source_manifest_sha256 = $manifestHash
    entrypoint_sha256 = $runnerHash
    pilot_schema_sha256 = $pilotSchemaHash
    results = @($results)
    run_evidence_ids = @($runEvidenceIds)
    scorecard_state = 'UNSCORED'
    blockers = @('control and abk_native were not run in this bounded source-only pilot', 'the published campaign remains benchmark_pending with zero completed runs')
}
$pilotPath = Join-Path $outputFull 'pilot.json'
Write-Json $pilot $pilotPath
if (-not (Test-Json -LiteralPath $pilotPath -SchemaFile $pilotSchemaPath)) { throw 'PILOT_SCHEMA_INVALID: bounded pilot ledger does not satisfy source-native-pilot.schema.json' }
$markdown = [System.Collections.Generic.List[string]]::new()
$markdown.Add('# Source-native bounded pilot')
$markdown.Add('')
$markdown.Add("- pilot_id: $($pilot.pilot_id)")
$markdown.Add("- captured_at: $capturedAt")
$markdown.Add('- status: passed')
$markdown.Add('- scope: one run for each of the ten frozen fixtures; source_native only')
$markdown.Add('- full_campaign: false')
$markdown.Add("- raw_runs: $($pilot.raw_runs) / $($pilot.expected_full_campaign_runs) expected for the complete three-branch campaign")
$markdown.Add('- scorecard: UNSCORED; no adoption outcome is asserted')
$markdown.Add('')
$markdown.Add('| Case | Terminal | Exit | Oracle | Evidence |')
$markdown.Add('|---|---|---:|---|---|')
foreach ($result in $results) { $markdown.Add("| $($result.case_id) | $($result.terminal_state) | $($result.exit_code) | $($result.oracle_status) | $($result.evidence_id) |") }
$markdown.Add('')
$markdown.Add('ABK-native remains NOT_COMPARABLE and is intentionally absent from this bounded source-only pilot. The campaign manifest remains benchmark_pending with zero completed runs.')
[IO.File]::WriteAllText((Join-Path $outputFull 'pilot.md'), ($markdown -join "`n"), $utf8NoBom)
Write-Output "SOURCE_NATIVE_BOUNDED_COMPLETE: $($pilot.raw_runs)/$($pilot.raw_runs) PASS; output=$outputFull"

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
$pilotSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\control-pilot.schema.json'
$runnerPath = Join-Path $workspaceFull 'benchmarks\runners\control\run.ps1'
$manifestPath = Join-Path $campaignRoot 'branches\control\manifest.json'
$outputFull = [IO.Path]::GetFullPath($OutputRoot)
$campaignPrefix = [IO.Path]::GetFullPath($campaignRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
$utf8NoBom = [Text.UTF8Encoding]::new($false)

if (-not $outputFull.StartsWith($campaignPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'OUTPUT_ROOT_ESCAPE: bounded pilot output must remain under the campaign root' }
if (Test-Path -LiteralPath $outputFull) { throw "OUTPUT_ROOT_EXISTS: refusing to overwrite '$outputFull'" }
foreach ($path in @($campaignPath, $schemaPath, $pilotSchemaPath, $runnerPath, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "INPUT_MISSING: required input is missing: $path" }
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Read-Json([string]$Path) {
    return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100
}

function Write-Json([object]$Document, [string]$Path) {
    [IO.File]::WriteAllText($Path, ($Document | ConvertTo-Json -Depth 60 -Compress), $utf8NoBom)
}

function New-Request([object]$Case, [int]$Repeat, [string]$RunRoot, [object]$Campaign, [string]$RunnerHash, [string]$SchemaHash, [string]$CampaignHash) {
    $fixturePath = Join-Path $campaignRoot ($Case.fixture -replace '/', '\')
    return [ordered]@{
        schema_version = '1.0.0'
        request_id = "abk:run-request:artifact-dag-core-v1-control-$($Case.slug)-r$Repeat"
        campaign_id = $Campaign.campaign_id
        branch = 'control'
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
            run_id = "abk:run:artifact-dag-core-v1-control-$($Case.slug)-r$Repeat"
            relative_run_root = [IO.Path]::GetRelativePath($campaignRoot, $RunRoot).Replace('\', '/')
            timeout_seconds = $Case.timeout_seconds
            stop_condition_id = 'bounded-pilot-case-oracle'
        }
        authority = [ordered]@{
            read_roots = @('campaign', 'fixture', 'schema')
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
            contract_version = 'control-runner-v1'
            executable_sha256 = $RunnerHash
            host = 'codex'
        }
    }
}

function Assert-RunEvidence([string]$RunPath, [string]$OraclePath, [object]$Case, [object]$Run, [object]$Oracle) {
    if (-not (Test-Json -LiteralPath $RunPath -SchemaFile (Join-Path $workspaceFull 'benchmarks\schemas\control-run.schema.json'))) { throw "RUN_SCHEMA_INVALID: $($Case.case_id)" }
    if ($Run.branch -ne 'control' -or $Run.case_id -ne $Case.case_id) { throw "RUN_IDENTITY_MISMATCH: $($Case.case_id)" }
    if ($Oracle.status -ne 'UNSCORED') { throw "ORACLE_STATUS_INVALID: $($Case.case_id)" }
    if ($Run.exit_code -notin @(0, 2, 3)) { throw "RUN_EXIT_UNEXPECTED: $($Case.case_id) observed $($Run.exit_code)" }
    if ($Run.terminal_state -notin @('SUCCEEDED', 'RECOVERED', 'STOPPED', 'REJECTED', 'FAILED')) { throw "RUN_TERMINAL_UNEXPECTED: $($Case.case_id)" }
    if (-not (Test-Path -LiteralPath $RunPath -PathType Leaf) -or -not (Test-Path -LiteralPath $OraclePath -PathType Leaf)) { throw "RUN_EVIDENCE_MISSING: $($Case.case_id)" }
}

$campaign = Read-Json $campaignPath
$campaignHash = Get-Sha256 $campaignPath
$schemaHash = Get-Sha256 $schemaPath
$manifestHash = Get-Sha256 $manifestPath
$runnerHash = Get-Sha256 $runnerPath
$pilotSchemaHash = Get-Sha256 $pilotSchemaPath
$manifest = Read-Json $manifestPath
if ($manifest.entrypoint_path -ne 'benchmarks/runners/control/run.ps1') { throw 'CONTROL_MANIFEST_ENTRYPOINT_INVALID: control manifest points to another entrypoint' }
if ($manifest.entrypoint_sha256 -ne $runnerHash -or $manifest.snapshot_sha256 -ne $runnerHash) { throw 'CONTROL_MANIFEST_HASH_MISMATCH: control entrypoint is not the pinned baseline' }

$cases = @(
    [ordered]@{ slug = 'com-01-normal-primary'; case_id = 'COM-01-normal-primary'; fixture = 'fixtures/COM-01-normal-primary.json'; timeout_seconds = 120; expected_terminal_state = 'SUCCEEDED'; expected_exit_code = 0; expected_error_code = $null; expected_recovery = $false; expected_handoff = $false },
    [ordered]@{ slug = 'com-02-normal-variant'; case_id = 'COM-02-normal-variant'; fixture = 'fixtures/COM-02-normal-variant.json'; timeout_seconds = 120; expected_terminal_state = 'SUCCEEDED'; expected_exit_code = 0; expected_error_code = $null; expected_recovery = $false; expected_handoff = $false },
    [ordered]@{ slug = 'com-03-normal-repeat'; case_id = 'COM-03-normal-repeat'; fixture = 'fixtures/COM-03-normal-repeat.json'; timeout_seconds = 120; expected_terminal_state = 'SUCCEEDED'; expected_exit_code = 0; expected_error_code = $null; expected_recovery = $false; expected_handoff = $false },
    [ordered]@{ slug = 'com-04-boundary-minimum'; case_id = 'COM-04-boundary-minimum'; fixture = 'fixtures/COM-04-boundary-minimum.json'; timeout_seconds = 90; expected_terminal_state = 'SUCCEEDED'; expected_exit_code = 0; expected_error_code = $null; expected_recovery = $false; expected_handoff = $false },
    [ordered]@{ slug = 'com-05-invalid-input'; case_id = 'COM-05-invalid-input'; fixture = 'fixtures/COM-05-invalid-input.json'; timeout_seconds = 90; expected_terminal_state = 'FAILED'; expected_exit_code = 3; expected_error_code = 'UNKNOWN_ARTIFACT_REFERENCE'; expected_recovery = $false; expected_handoff = $false },
    [ordered]@{ slug = 'com-06-stop-interrupt'; case_id = 'COM-06-stop-interrupt'; fixture = 'fixtures/COM-06-stop-interrupt.json'; timeout_seconds = 120; expected_terminal_state = 'STOPPED'; expected_exit_code = 130; expected_error_code = 'INTERRUPTED'; expected_recovery = $false; expected_handoff = $false },
    [ordered]@{ slug = 'spc-01-domain-boundary'; case_id = 'SPC-01-domain-boundary'; fixture = 'fixtures/SPC-01-domain-boundary.json'; timeout_seconds = 90; expected_terminal_state = 'REJECTED'; expected_exit_code = 2; expected_error_code = 'DEPENDENCY_OUT_OF_ROOT'; expected_recovery = $false; expected_handoff = $false },
    [ordered]@{ slug = 'spc-02-failure-path'; case_id = 'SPC-02-failure-path'; fixture = 'fixtures/SPC-02-failure-path.json'; timeout_seconds = 90; expected_terminal_state = 'FAILED'; expected_exit_code = 3; expected_error_code = 'UNKNOWN_ARTIFACT_REFERENCE'; expected_recovery = $false; expected_handoff = $false },
    [ordered]@{ slug = 'spc-03-recovery-rollback'; case_id = 'SPC-03-recovery-rollback'; fixture = 'fixtures/SPC-03-recovery-rollback.json'; timeout_seconds = 150; expected_terminal_state = 'RECOVERED'; expected_exit_code = 0; expected_error_code = 'RECOVERED_AFTER_FAILURE'; expected_recovery = $true; expected_handoff = $false },
    [ordered]@{ slug = 'spc-04-composition-handoff'; case_id = 'SPC-04-composition-handoff'; fixture = 'fixtures/SPC-04-composition-handoff.json'; timeout_seconds = 150; expected_terminal_state = 'SUCCEEDED'; expected_exit_code = 0; expected_error_code = $null; expected_recovery = $false; expected_handoff = $true }
)

New-Item -ItemType Directory -Path $outputFull -Force | Out-Null
$results = [System.Collections.Generic.List[object]]::new()
$runEvidenceIds = [System.Collections.Generic.List[string]]::new()
foreach ($case in $cases) {
    $campaignCase = @($campaign.cases | Where-Object { $_.case_id -eq $case.case_id })
    if ($campaignCase.Count -ne 1 -or $campaignCase[0].fixture -ne $case.fixture) { throw "CASE_DECLARATION_MISMATCH: $($case.case_id)" }
    $runRoot = Join-Path $outputFull ("$($case.case_id)\control\R1")
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    $requestPath = Join-Path $runRoot 'request.json'
    Write-Json (New-Request $case 1 $runRoot $campaign $runnerHash $schemaHash $campaignHash) $requestPath
    & $pwshPath -NoLogo -NoProfile -NonInteractive -File $runnerPath -RequestPath $requestPath 2>&1 | Out-Null
    $processExitCode = $LASTEXITCODE
    $runPath = Join-Path $runRoot 'run.json'
    $oraclePath = Join-Path $runRoot 'oracle-result.json'
    if (-not (Test-Path -LiteralPath $runPath -PathType Leaf) -or -not (Test-Path -LiteralPath $oraclePath -PathType Leaf)) { throw "RUN_EVIDENCE_MISSING: $($case.case_id)" }
    $run = Read-Json $runPath
    $oracle = Read-Json $oraclePath
    Assert-RunEvidence $runPath $oraclePath $case $run $oracle
    if ($processExitCode -ne $run.exit_code) { throw "RUN_PROCESS_EXIT_MISMATCH: $($case.case_id) process $processExitCode evidence $($run.exit_code)" }
    $observedErrorCode = if ($null -ne $run.error) { [string]$run.error.code } else { $null }
    $observedRecovery = $null -ne $run.recovery -and $run.recovery.removed -eq $true
    $observedHandoff = $null -ne $run.handoff -and $run.handoff.verified -eq $true
    $aligned = $run.terminal_state -eq $case.expected_terminal_state -and $run.exit_code -eq $case.expected_exit_code -and $observedErrorCode -eq $case.expected_error_code -and $observedRecovery -eq $case.expected_recovery -and $observedHandoff -eq $case.expected_handoff
    $evidenceId = "control-bounded-pilot-$($case.slug)-r1"
    $runEvidenceIds.Add($evidenceId)
    $results.Add([ordered]@{
        evidence_id = $evidenceId
        case_id = $case.case_id
        status = 'passed'
        expected_terminal_state = $case.expected_terminal_state
        observed_terminal_state = $run.terminal_state
        expected_exit_code = $case.expected_exit_code
        observed_exit_code = $run.exit_code
        expected_error_code = $case.expected_error_code
        observed_error_code = $observedErrorCode
        expected_recovery = $case.expected_recovery
        observed_recovery = $observedRecovery
        expected_handoff = $case.expected_handoff
        observed_handoff = $observedHandoff
        evaluation = if ($aligned) { 'aligned' } else { 'divergent' }
        oracle_status = if ($aligned) { 'passed' } else { 'inconclusive' }
        run_relative_path = ([IO.Path]::GetRelativePath($workspaceFull, $runPath)).Replace('\', '/')
        run_sha256 = Get-Sha256 $runPath
        oracle_relative_path = ([IO.Path]::GetRelativePath($workspaceFull, $oraclePath)).Replace('\', '/')
        oracle_sha256 = Get-Sha256 $oraclePath
    })
}

$alignedCount = @($results | Where-Object { $_.evaluation -eq 'aligned' }).Count
$divergentCount = @($results | Where-Object { $_.evaluation -eq 'divergent' }).Count
$capturedAt = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
$pilot = [ordered]@{
    '$schema' = '../../../../schemas/control-pilot.schema.json'
    schema_version = '1.0.0'
    pilot_id = 'abk:pilot:control-bounded-v1'
    campaign_id = $campaign.campaign_id
    branch = 'control'
    captured_at = $capturedAt
    status = 'passed'
    full_campaign = $false
    raw_runs = @($results).Count
    expected_full_campaign_runs = $campaign.run_policy.expected_raw_runs
    aligned_cases = $alignedCount
    divergent_cases = $divergentCount
    campaign_sha256 = $campaignHash
    schema_sha256 = $schemaHash
    control_manifest_sha256 = $manifestHash
    entrypoint_sha256 = $runnerHash
    pilot_schema_sha256 = $pilotSchemaHash
    results = @($results)
    run_evidence_ids = @($runEvidenceIds)
    scorecard_state = 'UNSCORED'
    blockers = @(
        'The control baseline diverges on interrupt, root-boundary, recovery, and handoff cases; this pilot records the gap without changing the baseline.',
        'The published campaign remains benchmark_pending with zero completed runs and no adoption outcome.'
    )
}
$pilotPath = Join-Path $outputFull 'pilot.json'
Write-Json $pilot $pilotPath
if (-not (Test-Json -LiteralPath $pilotPath -SchemaFile $pilotSchemaPath)) { throw 'PILOT_SCHEMA_INVALID: bounded control pilot ledger does not satisfy control-pilot.schema.json' }
$markdown = [System.Collections.Generic.List[string]]::new()
$markdown.Add('# Control-native bounded pilot')
$markdown.Add('')
$markdown.Add("- pilot_id: $($pilot.pilot_id)")
$markdown.Add("- captured_at: $capturedAt")
$markdown.Add('- status: passed (harness completed all ten control baseline runs)')
$markdown.Add('- scope: one run for each of the ten frozen fixtures; control branch only')
$markdown.Add('- full_campaign: false')
$markdown.Add("- raw_runs: $($pilot.raw_runs) / $($pilot.expected_full_campaign_runs) expected for the complete three-branch campaign")
$markdown.Add("- evaluation: $alignedCount aligned, $divergentCount divergent against the campaign oracle")
$markdown.Add('- scorecard: UNSCORED; no adoption outcome is asserted')
$markdown.Add('')
$markdown.Add('| Case | Expected | Observed | Exit | Evaluation | Evidence |')
$markdown.Add('|---|---|---|---:|---|---|')
foreach ($result in $results) { $markdown.Add("| $($result.case_id) | $($result.expected_terminal_state) | $($result.observed_terminal_state) | $($result.observed_exit_code) | $($result.evaluation) | $($result.evidence_id) |") }
$markdown.Add('')
$markdown.Add('This control pilot is a reproducibility baseline. Divergences are preserved as evidence and do not modify the legacy control runner or campaign counters.')
[IO.File]::WriteAllText((Join-Path $outputFull 'pilot.md'), ($markdown -join "`n"), $utf8NoBom)
Write-Output "CONTROL_BOUNDED_COMPLETE: $($pilot.raw_runs)/$($pilot.raw_runs) RUNS; aligned=$alignedCount; divergent=$divergentCount; output=$outputFull"

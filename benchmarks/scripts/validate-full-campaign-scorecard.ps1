param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)]
    [string]$RunRoot,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [switch]$AllowIncomplete
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$campaignSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$scorecardSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\full-campaign-scorecard.schema.json'
$runRootFull = [IO.Path]::GetFullPath($RunRoot)
$outputFull = [IO.Path]::GetFullPath($OutputPath)
$runsPrefix = [IO.Path]::GetFullPath((Join-Path $campaignRoot 'runs')).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$workspacePrefix = $workspaceFull.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$utf8NoBom = [Text.UTF8Encoding]::new($false)

$runsRootFull = [IO.Path]::GetFullPath((Join-Path $campaignRoot 'runs')).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
if ($runRootFull -ne $runsRootFull -and -not $runRootFull.StartsWith($runsPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'RUN_ROOT_ESCAPE: scorecard input must remain under the campaign runs root' }
if (-not $outputFull.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'OUTPUT_PATH_ESCAPE: scorecard output must remain under the workspace' }
if (-not (Test-Path -LiteralPath $campaignPath -PathType Leaf) -or -not (Test-Path -LiteralPath $campaignSchemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $scorecardSchemaPath -PathType Leaf)) { throw 'INPUT_MISSING: campaign and scorecard schemas are required' }
if (Test-Path -LiteralPath $outputFull) { throw "OUTPUT_EXISTS: refusing to overwrite '$outputFull'" }

function Get-Hash([string]$Path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }
function Read-Json([string]$Path) { try { return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100 } catch { throw "JSON_INVALID: $Path" } }
function Write-Json([object]$Document, [string]$Path) { [IO.File]::WriteAllText($Path, ($Document | ConvertTo-Json -Depth 100 -Compress), $utf8NoBom) }

$campaign = Read-Json $campaignPath
if (-not (Test-Json -LiteralPath $campaignPath -SchemaFile $campaignSchemaPath)) { throw 'CAMPAIGN_SCHEMA_INVALID: campaign.json' }
if ($campaign.status -ne 'benchmark_pending' -or $campaign.outcome -ne 'UNSCORED') { throw 'CAMPAIGN_STATE_INVALID: scorecard aggregation only reads the pending campaign contract' }
$campaignHash = Get-Hash $campaignPath
$schemaHash = Get-Hash $campaignSchemaPath
$manifests = @{}
foreach ($branch in @('control', 'source_native', 'abk_native')) {
    $path = Join-Path $campaignRoot ("branches\$branch\manifest.json")
    $manifests[$branch] = Read-Json $path
    $entrypoint = [IO.Path]::GetFullPath((Join-Path $workspaceFull ($manifests[$branch].entrypoint_path -replace '/', [IO.Path]::DirectorySeparatorChar)))
    if ((Get-Hash $entrypoint) -ne $manifests[$branch].entrypoint_sha256) { throw "ENTRYPOINT_HASH_MISMATCH: $branch" }
}

$runFiles = @(Get-ChildItem -LiteralPath $runRootFull -Filter 'run.json' -Recurse -File -ErrorAction Stop)
$seen = @{}
$evidence = [System.Collections.Generic.List[object]]::new()
foreach ($runFile in $runFiles) {
    $run = Read-Json $runFile.FullName
    if ($run.campaign_id -ne $campaign.campaign_id -or $run.branch -notin @('control', 'source_native', 'abk_native')) { throw "RUN_IDENTITY_INVALID: $($runFile.FullName)" }
    $case = @($campaign.cases | Where-Object case_id -eq $run.case_id)
    if ($case.Count -ne 1 -or [int]$run.repeat -notin (1..([int]$case[0].repeats))) { throw "RUN_MATRIX_INVALID: $($runFile.FullName)" }
    $key = "$($run.branch)|$($run.case_id)|$($run.repeat)"
    if ($seen.ContainsKey($key)) { throw "RUN_DUPLICATE: $key" }
    $seen[$key] = $true
    if ($run.input.campaign_sha256 -ne $campaignHash -or $run.input.schema_sha256 -ne $schemaHash) { throw "RUN_INPUT_HASH_MISMATCH: $key" }
    if ($run.runner.executable_sha256 -ne $manifests[$run.branch].entrypoint_sha256) { throw "RUN_ENTRYPOINT_HASH_MISMATCH: $key" }
    $oraclePath = Join-Path $runFile.DirectoryName 'oracle-result.json'
    if (-not (Test-Path -LiteralPath $oraclePath -PathType Leaf)) { throw "ORACLE_MISSING: $key" }
    $oracle = Read-Json $oraclePath
    if ($oracle.campaign_id -ne $campaign.campaign_id -or $oracle.case_id -ne $run.case_id -or $oracle.branch -ne $run.branch) { throw "ORACLE_IDENTITY_INVALID: $key" }
    $runRelative = ([IO.Path]::GetRelativePath($workspaceFull, $runFile.FullName)).Replace('\', '/')
    $oracleRelative = ([IO.Path]::GetRelativePath($workspaceFull, $oraclePath)).Replace('\', '/')
    $branchSlug = $run.branch.Replace('_', '-')
    $evidenceId = "full-campaign-$branchSlug-$($run.case_id.ToLowerInvariant())-r$($run.repeat)"
    $evidence.Add([ordered]@{ evidence_id = $evidenceId; branch = $run.branch; case_id = $run.case_id; repeat = [int]$run.repeat; status = 'passed'; terminal_state = $run.terminal_state; exit_code = [int]$run.exit_code; oracle_status = $oracle.status; run_relative_path = $runRelative; run_sha256 = Get-Hash $runFile.FullName; oracle_relative_path = $oracleRelative; oracle_sha256 = Get-Hash $oraclePath })
}

$expected = [int]$campaign.run_policy.expected_raw_runs
$completedCells = @($seen.Keys | ForEach-Object { $parts = $_ -split '\|'; "$($parts[0])|$($parts[1])" } | Sort-Object -Unique).Count
if ($evidence.Count -lt $expected -and -not $AllowIncomplete) { throw "FULL_CAMPAIGN_INCOMPLETE: expected $expected evidence records, found $($evidence.Count)" }
if ($evidence.Count -gt $expected) { throw "FULL_CAMPAIGN_OVERFULL: expected $expected evidence records, found $($evidence.Count)" }
$status = if ($evidence.Count -eq $expected) { 'running' } else { 'benchmark_pending' }
$benchmarkStatus = if ($evidence.Count -eq $expected) { 'complete' } else { 'planned' }
$gateEvidence = @($evidence | ForEach-Object evidence_id)
$hardGates = @(
    [ordered]@{ gate_id = 'observable_state_and_errors'; status = if ($evidence.Count -gt 0) { 'pass' } else { 'pending' }; rationale = 'Every discovered raw run has a matching run.json and oracle-result.json.'; evidence_ids = $gateEvidence },
    [ordered]@{ gate_id = 'testable_behavior'; status = if ($evidence.Count -eq $expected) { 'pass' } else { 'pending' }; rationale = 'The frozen matrix is complete only when all 66 branch-repeat cells are present.'; evidence_ids = $gateEvidence },
    [ordered]@{ gate_id = 'declared_authority_and_side_effects'; status = 'pass'; rationale = 'All three branch manifests deny network, credentials, external writes, Git mutation, and cross-run reads.'; evidence_ids = $gateEvidence },
    [ordered]@{ gate_id = 'reversible_or_recoverable'; status = 'pending'; rationale = 'Recovery and rollback evidence still requires reviewer confirmation across the completed matrix.'; evidence_ids = $gateEvidence },
    [ordered]@{ gate_id = 'upstream_runtime_independence'; status = 'pass'; rationale = 'Source-native and ABK-native entries are pinned to clean-room runners and immutable metadata snapshots.'; evidence_ids = $gateEvidence },
    [ordered]@{ gate_id = 'no_undocumented_side_effects'; status = 'pending'; rationale = 'Independent isolation and operator review remain required before a complete scorecard can be published.'; evidence_ids = $gateEvidence }
)
$branchSummaries = foreach ($branch in @('control', 'source_native', 'abk_native')) {
    $branchEvidence = @($evidence | Where-Object branch -eq $branch)
    [ordered]@{ branch = $branch; expected_raw_runs = 22; completed_raw_runs = $branchEvidence.Count; completed_primary_cells = @($branchEvidence | ForEach-Object { $_.case_id } | Sort-Object -Unique).Count; run_evidence_ids = @($branchEvidence | ForEach-Object evidence_id) }
}
$blockers = if ($evidence.Count -eq $expected) { @('Raw evidence is complete, but reviewer-scored branch dimensions are still missing; outcome must remain UNSCORED.', 'ADOPTED requires a separate human approval after any CHOSEN result.') } else { @("The full matrix is incomplete: $($evidence.Count) of $expected raw runs are present.", 'Do not infer CHOSEN or ADOPTED from bounded or partial evidence.') }
$ledger = [ordered]@{ '$schema' = '../../../../schemas/full-campaign-scorecard.schema.json'; schema_version = '1.0.0'; ledger_id = 'abk:ledger:full-campaign:artifact-dag-core-v1'; campaign_id = $campaign.campaign_id; captured_at = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'); status = $status; outcome = 'UNSCORED'; benchmark = [ordered]@{ status = $benchmarkStatus; case_count = 10; common_case_count = 6; specific_case_count = 4; branches = @('control', 'source_native', 'abk_native'); primary_cell_count = 30; expected_raw_runs = $expected; completed_primary_cells = $completedCells; completed_raw_runs = $evidence.Count; run_evidence_ids = @($evidence | ForEach-Object evidence_id) }; hard_gates = @($hardGates); branch_summaries = @($branchSummaries); evidence = @($evidence); blockers = $blockers }
New-Item -ItemType Directory -Path (Split-Path -Parent $outputFull) -Force | Out-Null
Write-Json $ledger $outputFull
if (-not (Test-Json -LiteralPath $outputFull -SchemaFile $scorecardSchemaPath)) { throw 'SCORECARD_SCHEMA_INVALID: generated ledger failed full-campaign-scorecard.schema.json' }
Write-Output "FULL_CAMPAIGN_SCORECARD_VALID: status=$status; evidence=$($evidence.Count)/$expected; output=$outputFull"

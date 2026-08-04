param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)]
    [string]$OutputRoot,
    [switch]$ValidationOnly
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$campaignSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$branchSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\branch-manifest.schema.json'
$outputFull = [IO.Path]::GetFullPath($OutputRoot)
$campaignPrefix = [IO.Path]::GetFullPath((Join-Path $campaignRoot 'runs')).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
$utf8NoBom = [Text.UTF8Encoding]::new($false)

if (-not $outputFull.StartsWith($campaignPrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'OUTPUT_ROOT_ESCAPE: full campaign output must remain under benchmarks/campaigns/artifact-dag-core-v1/runs' }
if (-not $ValidationOnly -and (Test-Path -LiteralPath $outputFull)) { throw "OUTPUT_ROOT_EXISTS: refusing to overwrite '$outputFull'" }
foreach ($path in @($campaignPath, $campaignSchemaPath, $branchSchemaPath)) { if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "INPUT_MISSING: required contract file is missing: $path" } }

function Get-Hash([string]$Path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }
function Write-Json([object]$Document, [string]$Path) { [IO.File]::WriteAllText($Path, ($Document | ConvertTo-Json -Depth 100 -Compress), $utf8NoBom) }
function Read-Json([string]$Path) { return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100 }
function Assert-Relative([string]$Path, [string]$Field) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:|^[\\/]' -or $Path -match '(^|[\\/])\.\.([\\/]|$)' -or $Path -match '[\x00-\x1f]') { throw "PATH_INVALID: $Field must be a safe repository-relative path" }
}
function Resolve-RepositoryPath([string]$RelativePath, [string]$Field) {
    Assert-Relative $RelativePath $Field
    $candidate = [IO.Path]::GetFullPath((Join-Path $workspaceFull ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)))
    $prefix = $workspaceFull.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw "PATH_ESCAPE: $Field escapes the workspace" }
    return $candidate
}

$campaign = Read-Json $campaignPath
if (-not (Test-Json -LiteralPath $campaignPath -SchemaFile $campaignSchemaPath)) { throw 'CAMPAIGN_SCHEMA_INVALID: campaign.json does not satisfy its pinned schema' }
if ($campaign.status -ne 'benchmark_pending' -or $campaign.outcome -ne 'UNSCORED' -or $campaign.completed_primary_cells -ne 0 -or $campaign.completed_raw_runs -ne 0 -or @($campaign.run_evidence_ids).Count -ne 0) { throw 'CAMPAIGN_NOT_PRISTINE: full campaign requires the frozen benchmark_pending zero-counter campaign' }
$campaignHash = Get-Hash $campaignPath
$schemaHash = Get-Hash $campaignSchemaPath
$branchIds = @('control', 'source_native', 'abk_native')
$branchPlans = [System.Collections.Generic.List[object]]::new()

foreach ($branchId in $branchIds) {
    $manifestPath = Join-Path $campaignRoot ("branches\$branchId\manifest.json")
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "MANIFEST_MISSING: $branchId" }
    if (-not (Test-Json -LiteralPath $manifestPath -SchemaFile $branchSchemaPath)) { throw "MANIFEST_SCHEMA_INVALID: $branchId" }
    $manifest = Read-Json $manifestPath
    if ($branchId -ne 'control' -and ($manifest.status -ne 'READY_FOR_EXECUTION' -or $manifest.disposition.candidate_disposition -ne 'RUNNABLE')) { throw "MANIFEST_NOT_RUNNABLE: $branchId" }
    $entrypointPath = Resolve-RepositoryPath $manifest.entrypoint_path "${branchId}.entrypoint_path"
    if (-not (Test-Path -LiteralPath $entrypointPath -PathType Leaf) -or (Get-Hash $entrypointPath) -ne $manifest.entrypoint_sha256) { throw "ENTRYPOINT_HASH_MISMATCH: $branchId" }
    if ($branchId -ne 'control') {
        $snapshotPath = Resolve-RepositoryPath $manifest.snapshot_path "${branchId}.snapshot_path"
        if (-not (Test-Path -LiteralPath $snapshotPath -PathType Leaf) -or (Get-Hash $snapshotPath) -ne $manifest.snapshot_sha256) { throw "SNAPSHOT_HASH_MISMATCH: $branchId" }
    }
    $branchPlans.Add([pscustomobject]@{ branch = $branchId; manifest_path = $manifestPath; manifest = $manifest; entrypoint_path = $entrypointPath; runner_hash = $manifest.entrypoint_sha256; snapshot_hash = if ($branchId -eq 'control') { $null } else { $manifest.snapshot_sha256 } })
}

$cases = @($campaign.cases)
$matrix = [System.Collections.Generic.List[object]]::new()
foreach ($case in $cases) {
    $fixturePath = Join-Path $campaignRoot ($case.fixture -replace '/', '\')
    Assert-Relative $case.fixture "case.$($case.case_id).fixture"
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf) -or (Get-Hash $fixturePath) -ne $case.fixture_sha256) { throw "FIXTURE_HASH_MISMATCH: $($case.case_id)" }
    foreach ($branch in $branchPlans) {
        foreach ($repeat in 1..([int]$case.repeats)) {
            $runRoot = Join-Path $outputFull ("$($case.case_id)\$($branch.branch)\R$repeat")
            $matrix.Add([pscustomobject]@{ case = $case; branch = $branch; repeat = $repeat; run_root = $runRoot; fixture_path = $fixturePath })
        }
    }
}
if ($matrix.Count -ne $campaign.run_policy.expected_raw_runs -or $matrix.Count -ne 66) { throw "MATRIX_COUNT_MISMATCH: expected 66 raw runs, got $($matrix.Count)" }
if (@($matrix | ForEach-Object { "$($_.case.case_id)|$($_.branch.branch)|$($_.repeat)" } | Sort-Object -Unique).Count -ne 66) { throw 'MATRIX_DUPLICATE: raw run matrix contains duplicate cells' }

if ($ValidationOnly) {
    Write-Output "FULL_CAMPAIGN_MATRIX_VALID: primary_cells=$($campaign.run_policy.primary_cell_count); expected_raw_runs=$($matrix.Count); branches=3; cases=10; validation_only=true"
    exit 0
}

New-Item -ItemType Directory -Path $outputFull -Force | Out-Null
$index = [System.Collections.Generic.List[object]]::new()
foreach ($cell in $matrix) {
    New-Item -ItemType Directory -Path $cell.run_root -Force | Out-Null
    $relativeRunRoot = ([IO.Path]::GetRelativePath($campaignRoot, $cell.run_root)).Replace('\', '/')
    $branchSlug = $cell.branch.branch.Replace('_', '-')
    $request = [ordered]@{
        schema_version = '1.0.0'
        request_id = "abk:run-request:artifact-dag-core-v1-$branchSlug-$($cell.case.case_id.ToLowerInvariant())-r$($cell.repeat)"
        campaign_id = $campaign.campaign_id
        branch = $cell.branch.branch
        case_id = $cell.case.case_id
        repeat = $cell.repeat
        fixture = [ordered]@{ relative_path = $cell.case.fixture; sha256 = $cell.case.fixture_sha256 }
        contracts = [ordered]@{ campaign_relative_path = ([IO.Path]::GetRelativePath($cell.run_root, $campaignPath)).Replace('\', '/'); campaign_sha256 = $campaignHash; schema_relative_path = ([IO.Path]::GetRelativePath($cell.run_root, $campaignSchemaPath)).Replace('\', '/'); schema_sha256 = $schemaHash }
        run = [ordered]@{ run_id = "abk:run:artifact-dag-core-v1-$branchSlug-$($cell.case.case_id.ToLowerInvariant())-r$($cell.repeat)"; relative_run_root = $relativeRunRoot; timeout_seconds = $cell.case.timeout_seconds; stop_condition_id = 'full-campaign-case-oracle' }
        authority = [ordered]@{ read_roots = if ($cell.branch.branch -eq 'abk_native') { @('campaign', 'fixture', 'schema', 'metadata_snapshot') } elseif ($cell.branch.branch -eq 'source_native') { @('campaign', 'fixture', 'schema', 'source_snapshot') } else { @('campaign', 'fixture', 'schema') }; write_root = 'run'; network = $false; credentials = $false; production_resources = $false; external_writes = $false; git_mutation = $false; process_spawn = $false }
        environment = [ordered]@{ HOME = 'env/HOME'; USERPROFILE = 'env/USERPROFILE'; APPDATA = 'env/APPDATA'; LOCALAPPDATA = 'env/LOCALAPPDATA'; XDG_CONFIG_HOME = 'env/XDG_CONFIG_HOME'; XDG_DATA_HOME = 'env/XDG_DATA_HOME' }
        runner = [ordered]@{ contract_version = if ($cell.branch.branch -eq 'control') { 'control-runner-v1' } elseif ($cell.branch.branch -eq 'source_native') { 'source-native-runner-v1' } else { 'abk-native-runner-v2' }; executable_sha256 = $cell.branch.runner_hash; host = 'codex' }
    }
    if ($cell.branch.branch -eq 'abk_native') { $request.snapshot = [ordered]@{ relative_path = $cell.branch.manifest.snapshot_path; sha256 = $cell.branch.snapshot_hash } }
    $requestPath = Join-Path $cell.run_root 'request.json'
    Write-Json $request $requestPath
    & $pwshPath -NoLogo -NoProfile -NonInteractive -File $cell.branch.entrypoint_path -RequestPath $requestPath 2>&1 | Out-Null
    $processExit = $LASTEXITCODE
    $runPath = Join-Path $cell.run_root 'run.json'; $oraclePath = Join-Path $cell.run_root 'oracle-result.json'
    foreach ($required in @($runPath, $oraclePath, (Join-Path $cell.run_root 'stdout.log'), (Join-Path $cell.run_root 'stderr.log'), (Join-Path $cell.run_root 'tool-events.jsonl'), (Join-Path $cell.run_root 'output-inventory.json'))) { if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "RUN_EVIDENCE_MISSING: $($cell.branch.branch)/$($cell.case.case_id)/R$($cell.repeat): $required" } }
    $run = Read-Json $runPath
    if ($run.branch -ne $cell.branch.branch -or $run.case_id -ne $cell.case.case_id -or [int]$run.repeat -ne $cell.repeat -or [int]$run.exit_code -ne $processExit) { throw "RUN_CONTRACT_MISMATCH: $($cell.branch.branch)/$($cell.case.case_id)/R$($cell.repeat)" }
    $index.Add([ordered]@{ evidence_id = "full-campaign-$branchSlug-$($cell.case.case_id.ToLowerInvariant())-r$($cell.repeat)"; branch = $cell.branch.branch; case_id = $cell.case.case_id; repeat = $cell.repeat; terminal_state = $run.terminal_state; exit_code = $processExit; run_relative_path = ([IO.Path]::GetRelativePath($workspaceFull, $runPath)).Replace('\', '/'); run_sha256 = Get-Hash $runPath; oracle_relative_path = ([IO.Path]::GetRelativePath($workspaceFull, $oraclePath)).Replace('\', '/'); oracle_sha256 = Get-Hash $oraclePath })
}
Write-Json ([ordered]@{ schema_version = '1.0.0'; campaign_id = $campaign.campaign_id; campaign_sha256 = $campaignHash; expected_raw_runs = $matrix.Count; completed_raw_runs = $index.Count; run_evidence_ids = @($index | ForEach-Object evidence_id); results = @($index) }) (Join-Path $outputFull 'campaign-run-index.json')
Write-Output "FULL_CAMPAIGN_COMPLETE: raw_runs=$($index.Count); output=$outputFull; scorecard=UNSCORED"

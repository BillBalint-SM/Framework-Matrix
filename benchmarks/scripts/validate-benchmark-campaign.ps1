param(
    [Parameter(Mandatory = $true)]
    [string]$CampaignPath,
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Code, [string]$Message) {
    throw ('{0}: {1}' -f $Code, $Message)
}

function Read-Json([string]$Path) {
    try {
        return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100 -ErrorAction Stop
    } catch {
        Fail 'JSON_INVALID' "Unable to parse '$Path'"
    }
}

function Assert-Unique([object[]]$Values, [string]$Code, [string]$Label) {
    if (@($Values | Sort-Object -Unique).Count -ne $Values.Count) {
        Fail $Code "Duplicate $Label"
    }
}

function Assert-SafeRelativePath([string]$Path, [string]$Code, [string]$Label) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:|^[\\/]' -or $Path -match '[\x00-\x1f]') {
        Fail $Code "$Label must be a relative path"
    }
    $normalized = $Path -replace '\\', '/'
    $segments = @($normalized -split '/')
    if (@($segments | Where-Object { $_ -in @('', '.', '..') }).Count -gt 0) {
        Fail $Code "$Label contains an unsafe path segment"
    }
    return $normalized
}

function Resolve-InRoot([string]$Root, [string]$RelativePath, [string]$Code, [string]$Label) {
    $normalized = Assert-SafeRelativePath $RelativePath $Code $Label
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull ($normalized -replace '/', [IO.Path]::DirectorySeparatorChar)))
    $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        Fail $Code "$Label escapes its allowed root"
    }
    return $candidate
}

function Assert-ExactSet([object[]]$Actual, [string[]]$Expected, [string]$Code, [string]$Label) {
    if ($Actual.Count -ne $Expected.Count -or @($Actual | Where-Object { $_ -notin $Expected }).Count -gt 0 -or @($Expected | Where-Object { $_ -notin $Actual }).Count -gt 0) {
        Fail $Code "$Label does not match the fixed contract"
    }
}

if (-not (Test-Path -LiteralPath $CampaignPath -PathType Leaf)) {
    Fail 'CAMPAIGN_MISSING' "Campaign file '$CampaignPath' does not exist"
}
if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
    Fail 'WORKSPACE_MISSING' "Workspace root '$WorkspaceRoot' does not exist"
}

$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
$campaignFull = [IO.Path]::GetFullPath($CampaignPath)
$workspacePrefix = $workspaceFull + [IO.Path]::DirectorySeparatorChar
if (-not $campaignFull.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase)) {
    Fail 'CAMPAIGN_PATH_ESCAPE' 'Campaign must be inside the declared workspace root'
}

$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
    Fail 'SCHEMA_MISSING' "Campaign schema '$schemaPath' does not exist"
}
$document = Read-Json $CampaignPath
$expectedFiles = @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'output-inventory.json', 'oracle-result.json')
Assert-ExactSet @($document.evidence_layout.required_files) $expectedFiles 'EVIDENCE_LAYOUT_INVALID' 'required evidence files'
if (-not (Test-Json -LiteralPath $CampaignPath -SchemaFile $schemaPath -ErrorAction Stop)) {
    Fail 'SCHEMA_INVALID' "Campaign '$CampaignPath' does not satisfy the benchmark schema"
}

$campaignRoot = Split-Path -Parent $campaignFull
$expectedCaseIds = @(
    'COM-01-normal-primary',
    'COM-02-normal-variant',
    'COM-03-normal-repeat',
    'COM-04-boundary-minimum',
    'COM-05-invalid-input',
    'COM-06-stop-interrupt',
    'SPC-01-domain-boundary',
    'SPC-02-failure-path',
    'SPC-03-recovery-rollback',
    'SPC-04-composition-handoff'
)
if ($document.status -ne 'benchmark_pending') { Fail 'STATUS_NOT_SUPPORTED' 'This validator only accepts a pre-execution benchmark_pending campaign' }
if ($document.outcome -ne 'UNSCORED') { Fail 'PREMATURE_OUTCOME' 'A pending campaign must remain UNSCORED' }
if ($document.completed_primary_cells -ne 0 -or $document.completed_raw_runs -ne 0 -or @($document.run_evidence_ids).Count -ne 0) {
    Fail 'PREMATURE_RUN_COUNT' 'A pending campaign cannot contain completed cells, raw runs, or run evidence IDs'
}

Assert-ExactSet @($document.branches) @('control', 'source_native', 'abk_native') 'BRANCH_SET_INVALID' 'branch set'
Assert-Unique @($document.cases | ForEach-Object { $_.case_id }) 'CASE_DUPLICATE' 'case ID'
Assert-ExactSet @($document.cases | ForEach-Object { $_.case_id }) $expectedCaseIds 'CASE_SET_INVALID' 'case set'
if (@($document.cases | Where-Object case_class -eq 'common').Count -ne 6 -or @($document.cases | Where-Object case_class -eq 'component_specific').Count -ne 4) {
    Fail 'CASE_CLASS_COUNT_INVALID' 'Cases must contain six common and four component_specific entries'
}

$expectedRawRuns = 0
foreach ($case in @($document.cases)) {
    $expectedPrefix = if ($case.case_class -eq 'common') { 'COM-' } else { 'SPC-' }
    if (-not $case.case_id.StartsWith($expectedPrefix, [StringComparison]::Ordinal)) {
        Fail 'CASE_CLASS_ID_MISMATCH' "Case '$($case.case_id)' does not match class '$($case.case_class)'"
    }
    $expectedRepeats = if ($case.model_dependent) { 3 } else { 1 }
    if ($case.repeats -ne $expectedRepeats) {
        Fail 'REPEAT_POLICY_INVALID' "Case '$($case.case_id)' has repeats=$($case.repeats), expected $expectedRepeats"
    }
    $expectedRawRuns += 3 * $expectedRepeats
    $fixturePath = Resolve-InRoot $campaignRoot $case.fixture 'FIXTURE_PATH_ESCAPE' "Fixture for '$($case.case_id)'"
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf)) {
        Fail 'FIXTURE_MISSING' "Fixture for '$($case.case_id)' does not exist"
    }
    $fixtureHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $fixturePath).Hash.ToLowerInvariant()
    if ($fixtureHash -ne $case.fixture_sha256) {
        Fail 'FIXTURE_HASH_MISMATCH' "Fixture hash mismatch for '$($case.case_id)'"
    }
    $fixture = Read-Json $fixturePath
    if ($fixture.case_id -ne $case.case_id) {
        Fail 'FIXTURE_CASE_ID_MISMATCH' "Fixture case_id does not match '$($case.case_id)'"
    }
}

if ($document.run_policy.primary_cell_count -ne 30) { Fail 'PRIMARY_CELL_COUNT_INVALID' 'Primary cell count must be 30' }
if ($document.run_policy.expected_raw_runs -ne $expectedRawRuns) { Fail 'RAW_RUN_COUNT_MISMATCH' "Expected $expectedRawRuns raw runs" }
if ($document.isolation.external_network -or $document.isolation.credentials -or $document.isolation.production_resources -or $document.isolation.external_writes -or $document.isolation.git_mutation) {
    Fail 'ISOLATION_POLICY_INVALID' 'Network, credentials, production resources, external writes, and Git mutation must all be disabled'
}
Assert-SafeRelativePath $document.isolation.workspace_root 'ISOLATION_PATH_INVALID' 'Isolation workspace root' | Out-Null
Assert-SafeRelativePath $document.evidence_layout.root 'EVIDENCE_PATH_INVALID' 'Evidence root' | Out-Null
Assert-ExactSet @($document.evidence_layout.required_files) $expectedFiles 'EVIDENCE_LAYOUT_INVALID' 'required evidence files'
if ($document.evidence_layout.run_path_template -match '\.\.|^[\\/]' -or $document.evidence_layout.run_path_template -notlike 'runs/*') {
    Fail 'EVIDENCE_LAYOUT_INVALID' 'Run path template must remain under runs/'
}
Assert-SafeRelativePath $document.source_pattern.path 'SOURCE_PATH_INVALID' 'Source pattern path' | Out-Null
Assert-SafeRelativePath $document.source_pattern.evidence_locator 'EVIDENCE_LOCATOR_INVALID' 'Source evidence locator' | Out-Null

Write-Output ('BENCHMARK_VALID: {0}; cases=10; primary_cells=30; expected_raw_runs={1}' -f $document.campaign_id, $expectedRawRuns)

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)]
    [string]$RecordPath
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Code, [string]$Detail) {
    throw "ADOPTION_VALIDATION_FAILURE: $Code; $Detail"
}

function Assert-UnderRoot([string]$Path, [string]$Root, [string]$Field, [bool]$AllowExact) {
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [IO.Path]::GetFullPath($Path)
    if (($AllowExact -and $pathFull -eq $rootFull) -or $pathFull.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { return }
    Fail 'PATH_ESCAPE' "$Field is outside the workspace root"
}

function Assert-NoReparsePoint([string]$Path, [string]$Root, [string]$Field, [bool]$AllowExact) {
    Assert-UnderRoot $Path $Root $Field $AllowExact
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [IO.Path]::GetFullPath($Path)
    $relativePath = [IO.Path]::GetRelativePath($rootFull, $pathFull)
    $currentPath = $rootFull
    $pathsToInspect = @($currentPath)

    if ($relativePath -ne '.') {
        foreach ($segment in ($relativePath -split '[\\/]')) {
            if ([string]::IsNullOrWhiteSpace($segment)) { continue }
            $currentPath = Join-Path $currentPath $segment
            $pathsToInspect += $currentPath
        }
    }

    foreach ($pathToInspect in $pathsToInspect) {
        if (-not (Test-Path -LiteralPath $pathToInspect)) { break }
        try {
            $item = Get-Item -LiteralPath $pathToInspect -Force -ErrorAction Stop
        } catch {
            Fail 'PATH_UNREADABLE' "$Field cannot be inspected: $pathToInspect"
        }
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            Fail 'PATH_REPARSE_POINT' "$Field traverses a reparse point"
        }
    }
}

function Assert-RelativePath([string]$Path, [string]$Field) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:|^[\\/]' -or $Path -match '(^|[\\/])\.\.([\\/]|$)' -or $Path -match '[\x00-\x1f]') {
        Fail 'PATH_INVALID' "$Field must be a safe repository-relative path"
    }
}

function Resolve-WorkspacePath([string]$RelativePath, [string]$Field, [string]$WorkspacePath) {
    Assert-RelativePath $RelativePath $Field
    $candidate = [IO.Path]::GetFullPath((Join-Path $WorkspacePath ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)))
    Assert-UnderRoot $candidate $WorkspacePath $Field $false
    return $candidate
}

function Get-Hash([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Read-Json([string]$Path, [string]$Field) {
    try {
        return Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -Depth 100 -ErrorAction Stop
    } catch {
        Fail 'JSON_INVALID' "$Field is not valid JSON"
    }
}

function Test-Schema([string]$Path, [string]$SchemaPath, [string]$Code) {
    try {
        $valid = Test-Json -LiteralPath $Path -SchemaFile $SchemaPath -ErrorAction Stop
    } catch {
        Fail $Code "schema validation failed for $Path"
    }
    if (-not $valid) { Fail $Code "schema validation failed for $Path" }
}

$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$recordFull = [IO.Path]::GetFullPath($RecordPath)
$adoptionSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\adoption-decision-v1.schema.json'
$comparisonSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\comparison-scorecard-v2.schema.json'

if (-not (Test-Path -LiteralPath $workspaceFull -PathType Container)) { Fail 'WORKSPACE_MISSING' 'WorkspaceRoot does not exist' }
Assert-NoReparsePoint $workspaceFull $workspaceFull 'WorkspaceRoot' $true
Assert-NoReparsePoint $recordFull $workspaceFull 'RecordPath' $false
if (-not (Test-Path -LiteralPath $recordFull -PathType Leaf)) { Fail 'RECORD_MISSING' 'RecordPath does not exist' }
foreach ($requiredPath in @($adoptionSchemaPath, $comparisonSchemaPath)) {
    Assert-NoReparsePoint $requiredPath $workspaceFull 'schema path' $false
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) { Fail 'INPUT_MISSING' "required schema is missing: $requiredPath" }
}

Test-Schema $recordFull $adoptionSchemaPath 'RECORD_SCHEMA_INVALID'
$record = Read-Json $recordFull 'RecordPath'
$scorecardPath = Resolve-WorkspacePath $record.basis.scorecard_relative_path 'basis.scorecard_relative_path' $workspaceFull
Assert-NoReparsePoint $scorecardPath $workspaceFull 'basis.scorecard_relative_path' $false
if (-not (Test-Path -LiteralPath $scorecardPath -PathType Leaf)) { Fail 'SCORECARD_MISSING' 'referenced scorecard does not exist' }
if ((Get-Hash $scorecardPath) -ne $record.basis.scorecard_sha256) { Fail 'SCORECARD_HASH_MISMATCH' 'referenced scorecard hash differs from the adoption basis' }

Test-Schema $scorecardPath $comparisonSchemaPath 'SCORECARD_SCHEMA_INVALID'
$scorecard = Read-Json $scorecardPath 'referenced scorecard'
if ($scorecard.comparison_id -ne $record.basis.comparison_id) { Fail 'COMPARISON_ID_MISMATCH' 'referenced scorecard comparison ID differs from the adoption basis' }
if ($scorecard.status -ne $record.basis.required_status) { Fail 'SCORECARD_STATUS_INVALID' 'referenced scorecard status differs from the adoption basis' }
if ($scorecard.outcome -ne $record.basis.required_outcome) { Fail 'SCORECARD_OUTCOME_INVALID' 'referenced scorecard outcome differs from the adoption basis' }
if ($record.approval.kind -ne 'human_user_confirmation') { Fail 'APPROVAL_KIND_INVALID' 'adoption record does not declare human user confirmation' }
if ($record.selected_branch -notin @($scorecard.eligible_branches)) { Fail 'SELECTED_BRANCH_INELIGIBLE' 'selected branch is not eligible in the referenced scorecard' }

Write-Output "ADOPTION_DECISION_VALID: $($record.decision_id); branch=$($record.selected_branch)"

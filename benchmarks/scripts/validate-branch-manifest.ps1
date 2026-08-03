param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Code, [string]$Message) {
    throw ('{0}: {1}' -f $Code, $Message)
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Assert-SafeRelativePath([string]$Path, [string]$Code, [string]$Field) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:|^[\\/]' -or $Path -match '[\x00-\x1f]' -or $Path -match '[*?;&|<>]') {
        Fail $Code "$Field is not a safe relative path"
    }
    $segments = @($Path.Replace('\', '/') -split '/')
    if (@($segments | Where-Object { $_ -eq '' -or $_ -eq '.' -or $_ -eq '..' }).Count -gt 0) {
        Fail $Code "$Field contains an unsafe path segment"
    }
}

function Assert-InWorkspace([string]$Workspace, [string]$Candidate, [string]$Code, [string]$Field) {
    $workspaceFull = [IO.Path]::GetFullPath($Workspace).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $candidateFull = [IO.Path]::GetFullPath($Candidate)
    $prefix = $workspaceFull + [IO.Path]::DirectorySeparatorChar
    if (-not $candidateFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        Fail $Code "$Field escapes the workspace"
    }
    return $candidateFull
}

function Assert-NoReparsePoints([string]$Path, [string]$Field) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($true) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -Force -LiteralPath $cursor
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                Fail 'PATH_REPARSE_POINT' "$Field contains a reparse point"
            }
        }
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) { break }
        $cursor = $parent
        if ($cursor -eq [IO.Path]::GetPathRoot($cursor)) { break }
    }
}

$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$manifestFull = Assert-InWorkspace $workspaceFull $ManifestPath 'MANIFEST_PATH_ESCAPE' 'manifest'
if (-not (Test-Path -LiteralPath $manifestFull -PathType Leaf)) { Fail 'MANIFEST_MISSING' "Manifest '$manifestFull' does not exist" }
Assert-NoReparsePoints $manifestFull 'manifest'

$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\branch-manifest.schema.json'
if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) { Fail 'SCHEMA_MISSING' "Branch manifest schema '$schemaPath' does not exist" }
try {
    if (-not (Test-Json -LiteralPath $manifestFull -SchemaFile $schemaPath)) { Fail 'SCHEMA_INVALID' 'Manifest does not satisfy branch-manifest.schema.json' }
} catch {
    if ($_.Exception.Message -like 'SCHEMA_INVALID:*') { throw }
    Fail 'SCHEMA_INVALID' 'Manifest does not satisfy branch-manifest.schema.json'
}

$manifest = Get-Content -Raw -LiteralPath $manifestFull | ConvertFrom-Json
$campaignRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $manifestFull))
$campaignPath = Join-Path $campaignRoot 'campaign.json'
if (-not (Test-Path -LiteralPath $campaignPath -PathType Leaf)) { Fail 'CAMPAIGN_MISSING' "Campaign '$campaignPath' does not exist" }
$campaign = Get-Content -Raw -LiteralPath $campaignPath | ConvertFrom-Json
if ($manifest.campaign_id -ne $campaign.campaign_id) { Fail 'CAMPAIGN_ID_MISMATCH' 'Manifest campaign_id does not match campaign.json' }

Assert-SafeRelativePath $manifest.entrypoint_path 'ENTRYPOINT_PATH_INVALID' 'entrypoint_path'
$entrypointFull = Assert-InWorkspace $workspaceFull (Join-Path $workspaceFull ($manifest.entrypoint_path -replace '/', [IO.Path]::DirectorySeparatorChar)) 'ENTRYPOINT_PATH_ESCAPE' 'entrypoint_path'
if (-not (Test-Path -LiteralPath $entrypointFull -PathType Leaf)) { Fail 'ENTRYPOINT_MISSING' "Entrypoint '$entrypointFull' does not exist" }
Assert-NoReparsePoints $entrypointFull 'entrypoint_path'
$entrypointHash = Get-Sha256 $entrypointFull
if ($entrypointHash -ne $manifest.entrypoint_sha256) { Fail 'ENTRYPOINT_HASH_MISMATCH' 'Entrypoint SHA-256 does not match manifest' }
if ($entrypointHash -ne $manifest.snapshot_sha256) { Fail 'SNAPSHOT_HASH_MISMATCH' 'Control snapshot SHA-256 does not match entrypoint' }
if ($manifest.runtime.powershell_major -ne $PSVersionTable.PSVersion.Major) { Fail 'RUNTIME_VERSION_MISMATCH' 'Manifest PowerShell major does not match the validating host' }

foreach ($field in @('network', 'credentials', 'production_resources', 'external_writes', 'git_mutation', 'child_processes', 'cross_run_reads', 'cross_branch_reads', 'real_user_config_reads_or_writes')) {
    if ($manifest.$field -ne 'DENY') { Fail 'AUTHORITY_POLICY_INVALID' "$field must remain DENY" }
}
if ($manifest.undocumented_effect_policy -ne 'STOPPED') { Fail 'UNDOCUMENTED_EFFECT_POLICY_INVALID' 'Undocumented effects must stop the run' }

Write-Output ('BRANCH_MANIFEST_VALID: {0}; entrypoint_sha256={1}; powershell_major={2}' -f $manifest.manifest_id, $entrypointHash, $PSVersionTable.PSVersion.Major)

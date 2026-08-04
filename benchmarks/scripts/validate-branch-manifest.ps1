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

$branchProperty = $manifest.PSObject.Properties['branch_id']
$branchId = if ($null -eq $branchProperty) { 'control' } else { [string]$manifest.branch_id }
if ($branchId -notin @('control', 'source_native', 'abk_native')) { Fail 'BRANCH_ID_INVALID' "Unsupported branch_id '$branchId'" }
$expectedWriteRoot = 'runs/<case-id>/{0}/R<n>/**' -f $branchId
if (@($manifest.writes).Count -ne 1 -or [string]$manifest.writes[0] -ne $expectedWriteRoot) {
    Fail 'WRITE_ROOT_INVALID' "writes must contain exactly '$expectedWriteRoot' for branch '$branchId'"
}

Assert-SafeRelativePath $manifest.entrypoint_path 'ENTRYPOINT_PATH_INVALID' 'entrypoint_path'
$entrypointFull = Assert-InWorkspace $workspaceFull (Join-Path $workspaceFull ($manifest.entrypoint_path -replace '/', [IO.Path]::DirectorySeparatorChar)) 'ENTRYPOINT_PATH_ESCAPE' 'entrypoint_path'
if (-not (Test-Path -LiteralPath $entrypointFull -PathType Leaf)) { Fail 'ENTRYPOINT_MISSING' "Entrypoint '$entrypointFull' does not exist" }
Assert-NoReparsePoints $entrypointFull 'entrypoint_path'
$entrypointHash = Get-Sha256 $entrypointFull
if ($entrypointHash -ne $manifest.entrypoint_sha256) { Fail 'ENTRYPOINT_HASH_MISMATCH' 'Entrypoint SHA-256 does not match manifest' }

$snapshotPathProperty = $manifest.PSObject.Properties['snapshot_path']
$snapshotPath = if ($null -eq $snapshotPathProperty) { $null } else { [string]$manifest.snapshot_path }
if ([string]::IsNullOrWhiteSpace($snapshotPath)) {
    if ($branchId -ne 'control') { Fail 'SNAPSHOT_PATH_REQUIRED' "Branch '$branchId' must declare snapshot_path" }
    if ($entrypointHash -ne $manifest.snapshot_sha256) { Fail 'SNAPSHOT_HASH_MISMATCH' 'Legacy control snapshot SHA-256 does not match entrypoint' }
} else {
    Assert-SafeRelativePath $snapshotPath 'SNAPSHOT_PATH_INVALID' 'snapshot_path'
    $snapshotFull = Assert-InWorkspace $workspaceFull (Join-Path $workspaceFull ($snapshotPath -replace '/', [IO.Path]::DirectorySeparatorChar)) 'SNAPSHOT_PATH_ESCAPE' 'snapshot_path'
    if (-not (Test-Path -LiteralPath $snapshotFull -PathType Leaf)) { Fail 'SNAPSHOT_MISSING' "Snapshot '$snapshotFull' does not exist" }
    Assert-NoReparsePoints $snapshotFull 'snapshot_path'
    $snapshotHash = Get-Sha256 $snapshotFull
    if ($snapshotHash -ne $manifest.snapshot_sha256) { Fail 'SNAPSHOT_HASH_MISMATCH' 'Snapshot SHA-256 does not match snapshot_path' }
}

$runtime = $manifest.runtime
$runtimeKindProperty = $runtime.PSObject.Properties['kind']
$hasGenericRuntime = $null -ne $runtimeKindProperty
if ($branchId -ne 'control' -or $hasGenericRuntime) {
    if ($branchId -ne 'control' -and ($null -ne $runtime.PSObject.Properties['powershell_executable'] -or $null -ne $runtime.PSObject.Properties['powershell_major'])) {
        Fail 'RUNTIME_DESCRIPTOR_INVALID' "Branch '$branchId' must use the generic local runtime descriptor"
    }
    foreach ($field in @('kind', 'executable', 'version', 'command_template')) {
        if ($null -eq $runtime.PSObject.Properties[$field] -or [string]::IsNullOrWhiteSpace([string]$runtime.$field)) {
            Fail 'RUNTIME_DESCRIPTOR_INVALID' "runtime.$field is required for branch '$branchId'"
        }
    }
    if ($runtime.kind -notin @('powershell', 'node', 'python', 'custom_local')) { Fail 'RUNTIME_DESCRIPTOR_INVALID' "Unsupported runtime kind '$($runtime.kind)'" }
    if ([string]$runtime.executable -notmatch '^[A-Za-z0-9._-]+$') { Fail 'RUNTIME_DESCRIPTOR_INVALID' 'runtime.executable must be a local executable name' }
    if ([string]$runtime.version -notmatch '^[0-9]+(?:\.[0-9]+){0,2}$') { Fail 'RUNTIME_DESCRIPTOR_INVALID' 'runtime.version must be a numeric local runtime version' }
    $commandTemplate = [string]$runtime.command_template
    if ($commandTemplate -match '[\x00-\x1f;&|<>`$]' -or $commandTemplate -notmatch '\{entrypoint_path\}' -or $commandTemplate -notmatch '\{run_root\}') {
        Fail 'RUNTIME_DESCRIPTOR_INVALID' 'runtime.command_template must be local-only and contain {entrypoint_path} and {run_root}'
    }
    if ($runtime.kind -eq 'powershell') {
        if ([string]$runtime.executable -ne 'pwsh.exe') { Fail 'RUNTIME_DESCRIPTOR_INVALID' 'PowerShell runtime must declare pwsh.exe' }
        $runtimeMajor = [int]([string]$runtime.version).Split('.')[0]
        if ($runtimeMajor -ne $PSVersionTable.PSVersion.Major) { Fail 'RUNTIME_VERSION_MISMATCH' 'Manifest PowerShell major does not match the validating host' }
    }
} else {
    if ([string]$runtime.powershell_executable -ne 'pwsh.exe') { Fail 'RUNTIME_DESCRIPTOR_INVALID' 'Legacy control runtime must declare pwsh.exe' }
    if ($runtime.powershell_major -ne $PSVersionTable.PSVersion.Major) { Fail 'RUNTIME_VERSION_MISMATCH' 'Manifest PowerShell major does not match the validating host' }
    if ([string]$runtime.command_template -ne 'pwsh.exe -NoLogo -NoProfile -NonInteractive -File {entrypoint_path} -RequestPath {run_root}/request.json') {
        Fail 'RUNTIME_DESCRIPTOR_INVALID' 'Legacy control runtime command_template is not the pinned local command'
    }
}

$executionStatusProperty = $manifest.PSObject.Properties['execution_status']
if ($null -ne $executionStatusProperty -and [string]$manifest.execution_status -ne 'NOT_EXECUTED') { Fail 'EXECUTION_STATUS_INVALID' 'Branch manifests must remain NOT_EXECUTED until an approved entrypoint exists' }
$statusProperty = $manifest.PSObject.Properties['status']
$dispositionProperty = $manifest.PSObject.Properties['disposition']
if ($null -ne $statusProperty -or $null -ne $dispositionProperty) {
    if ($null -eq $statusProperty -or $null -eq $dispositionProperty) { Fail 'DISPOSITION_INVALID' 'status and disposition must be declared together' }
    $expectedDisposition = switch ([string]$manifest.status) {
        'READY_FOR_ENTRYPOINT' { 'READY_FOR_CLEAN_ROOM_ENTRYPOINT'; break }
        'READY_FOR_EXECUTION' { 'RUNNABLE'; break }
        'BLOCKED' { 'BLOCKED'; break }
        'NOT_COMPARABLE' { 'NOT_COMPARABLE'; break }
        'REJECTED' { 'REJECTED'; break }
        default { Fail 'STATUS_INVALID' "Unsupported status '$($manifest.status)'" }
    }
    if ([string]$manifest.disposition.candidate_disposition -ne $expectedDisposition) {
        Fail 'DISPOSITION_INVALID' 'disposition.candidate_disposition does not match status'
    }
}

foreach ($field in @('network', 'credentials', 'production_resources', 'external_writes', 'git_mutation', 'child_processes', 'cross_run_reads', 'cross_branch_reads', 'real_user_config_reads_or_writes')) {
    if ($manifest.$field -ne 'DENY') { Fail 'AUTHORITY_POLICY_INVALID' "$field must remain DENY" }
}
if ($manifest.undocumented_effect_policy -ne 'STOPPED') { Fail 'UNDOCUMENTED_EFFECT_POLICY_INVALID' 'Undocumented effects must stop the run' }

$executionOutput = if ($null -eq $executionStatusProperty) { 'LEGACY_CONTROL' } else { [string]$manifest.execution_status }
Write-Output ('BRANCH_MANIFEST_VALID: {0}; branch_id={1}; entrypoint_sha256={2}; snapshot_sha256={3}; execution_status={4}' -f $manifest.manifest_id, $branchId, $entrypointHash, $manifest.snapshot_sha256, $executionOutput)

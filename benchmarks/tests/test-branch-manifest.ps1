param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\branch-manifest.schema.json'
$manifestPath = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\branches\control\manifest.json'
$sourceManifestPath = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\branches\source_native\manifest.json'
$abkManifestPath = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\branches\abk_native\manifest.json'
$campaignPath = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\campaign.json'
$entrypointPath = Join-Path $workspaceFull 'benchmarks\runners\control\run.ps1'
$validatorPath = Join-Path $workspaceFull 'benchmarks\scripts\validate-branch-manifest.ps1'

if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or -not (Test-Path -LiteralPath $sourceManifestPath -PathType Leaf) -or -not (Test-Path -LiteralPath $abkManifestPath -PathType Leaf) -or -not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
    throw 'TEST_FAILURE: branch manifest schema, validator, and all three branch manifests must exist'
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Test-ManifestSchema([string]$Path) {
    try { return [bool](Test-Json -LiteralPath $Path -SchemaFile $schemaPath) } catch { return $false }
}

function Assert-InvalidManifest([string]$Name, [scriptblock]$Mutate, [string]$TempRoot) {
    $document = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    & $Mutate $document
    $path = Join-Path $TempRoot ($Name + '.json')
    $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path -Encoding utf8NoBOM
    if (Test-ManifestSchema $path) { throw "TEST_FAILURE: invalid manifest '$Name' was accepted" }
}

function New-BranchManifest([string]$BranchId, [string]$Status, [string]$CandidateDisposition, [string]$SnapshotPath, [string]$RuntimeKind) {
    $document = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $snapshotFull = Join-Path $workspaceFull ($SnapshotPath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $document | Add-Member -NotePropertyName branch_id -NotePropertyValue $null
    $document | Add-Member -NotePropertyName snapshot_path -NotePropertyValue $null
    $document | Add-Member -NotePropertyName status -NotePropertyValue $null
    $document | Add-Member -NotePropertyName disposition -NotePropertyValue $null
    $document | Add-Member -NotePropertyName execution_status -NotePropertyValue $null
    $document.manifest_id = 'abk:branch-manifest:{0}-artifact-dag-core-v1' -f ($BranchId -replace '_', '-')
    $document.branch_id = $BranchId
    $document.writes = @('runs/<case-id>/{0}/R<n>/**' -f $BranchId)
    $document.snapshot_ref = 'abk:branch-snapshot:{0}-artifact-dag-core-v1' -f ($BranchId -replace '_', '-')
    $document.snapshot_path = $SnapshotPath
    $document.snapshot_sha256 = Get-Sha256 $snapshotFull
    $document.status = $Status
    $document.disposition = [pscustomobject]@{
        candidate_disposition = $CandidateDisposition
        reason = 'This branch descriptor is explicit, bounded, and awaits an approved clean-room entrypoint.'
        next_action = 'Keep execution stopped until the branch entrypoint is implemented and separately hash-pinned.'
    }
    $document.execution_status = 'NOT_EXECUTED'
    $executable = switch ($RuntimeKind) {
        'powershell' { 'pwsh.exe' }
        'node' { 'node.exe' }
        'python' { 'python.exe' }
        'custom_local' { 'local-runner.exe' }
        default { throw "TEST_FAILURE: unsupported test runtime kind '$RuntimeKind'" }
    }
    $version = if ($RuntimeKind -eq 'powershell') { [string]$PSVersionTable.PSVersion.Major } else { '22' }
    $document.runtime = [pscustomobject]@{
        kind = $RuntimeKind
        executable = $executable
        version = $version
        command_template = "$executable --entrypoint {entrypoint_path} --run-root {run_root}"
    }
    return $document
}

function Assert-InvalidBranchManifest([string]$Name, [object]$Document) {
    $path = Join-Path (Split-Path -Parent $manifestPath) ($Name + '-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        $Document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $path -Encoding utf8NoBOM
        if (Test-ManifestSchema $path) { throw "TEST_FAILURE: invalid branch manifest '$Name' was accepted" }
    } finally {
        Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    }
}

$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$campaign = Get-Content -Raw -LiteralPath $campaignPath | ConvertFrom-Json
if (-not (Test-ManifestSchema $manifestPath)) { throw 'TEST_FAILURE: control manifest does not satisfy branch-manifest.schema.json' }
if ($manifest.campaign_id -ne $campaign.campaign_id) { throw 'TEST_FAILURE: manifest campaign_id mismatch' }
if ($manifest.entrypoint_sha256 -ne (Get-Sha256 $entrypointPath)) { throw 'TEST_FAILURE: entrypoint SHA-256 is not current' }
if ($manifest.runtime.powershell_major -ne 7) { throw 'TEST_FAILURE: PowerShell major version is not pinned to 7' }
$authorityFields = @('network', 'credentials', 'production_resources', 'external_writes', 'git_mutation', 'child_processes', 'cross_run_reads', 'cross_branch_reads', 'real_user_config_reads_or_writes')
if (@($authorityFields | Where-Object { $manifest.$_ -ne 'DENY' }).Count -gt 0) {
    throw 'TEST_FAILURE: control manifest must deny external authority, cross-run/branch reads, and real-user configuration access'
}
if ($manifest.entrypoint_path -match 'PENDING|[*?;&|<>]|^[A-Za-z]:|^[\\/]') { throw 'TEST_FAILURE: entrypoint path is not a safe concrete relative path' }
& $validatorPath -ManifestPath $manifestPath -WorkspaceRoot $workspaceFull | Out-Null
foreach ($concreteManifestPath in @($sourceManifestPath, $abkManifestPath)) {
    if (-not (Test-ManifestSchema $concreteManifestPath)) { throw "TEST_FAILURE: concrete manifest '$concreteManifestPath' does not satisfy branch-manifest.schema.json" }
    & $validatorPath -ManifestPath $concreteManifestPath -WorkspaceRoot $workspaceFull | Out-Null
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('framework-matrix-branch-manifest-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
    Assert-InvalidManifest 'pending-entrypoint' { param($d) $d.entrypoint_path = 'PENDING' } $tempRoot
    Assert-InvalidManifest 'network-allow' { param($d) $d.network = 'ALLOW' } $tempRoot
    $wrongHash = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    $wrongHash.entrypoint_sha256 = ('0' * 64)
    $wrongHashPath = Join-Path (Split-Path -Parent $manifestPath) ('test-entrypoint-hash-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        $wrongHash | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $wrongHashPath -Encoding utf8NoBOM
        $caught = $null
        try { & $validatorPath -ManifestPath $wrongHashPath -WorkspaceRoot $workspaceFull | Out-Null } catch { $caught = $_.Exception.Message.Split(':')[0] }
        if ($caught -ne 'ENTRYPOINT_HASH_MISMATCH') { throw "TEST_FAILURE: entrypoint hash mismatch expected ENTRYPOINT_HASH_MISMATCH but got $caught" }
    } finally {
        Remove-Item -LiteralPath $wrongHashPath -Force -ErrorAction SilentlyContinue
    }

    $sourceSnapshotPath = 'benchmarks/snapshots/source-native-openspec-artifact-graph.json'
    $abkSnapshotPath = 'benchmarks/snapshots/abk-native-ai-booster-kit-feature.json'
    $sourceBranch = New-BranchManifest 'source_native' 'READY_FOR_ENTRYPOINT' 'READY_FOR_CLEAN_ROOM_ENTRYPOINT' $sourceSnapshotPath 'node'
    $abkBranch = New-BranchManifest 'abk_native' 'READY_FOR_EXECUTION' 'RUNNABLE' $abkSnapshotPath 'node'
    $sourcePath = Join-Path (Split-Path -Parent $manifestPath) ('test-source-branch-' + [guid]::NewGuid().ToString('N') + '.json')
    $abkPath = Join-Path (Split-Path -Parent $manifestPath) ('test-abk-branch-' + [guid]::NewGuid().ToString('N') + '.json')
    try {
        $sourceBranch | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $sourcePath -Encoding utf8NoBOM
        $abkBranch | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $abkPath -Encoding utf8NoBOM
        if (-not (Test-ManifestSchema $sourcePath) -or -not (Test-ManifestSchema $abkPath)) { throw 'TEST_FAILURE: explicit source_native and abk_native manifests must satisfy branch-manifest.schema.json' }
        & $validatorPath -ManifestPath $sourcePath -WorkspaceRoot $workspaceFull | Out-Null
        & $validatorPath -ManifestPath $abkPath -WorkspaceRoot $workspaceFull | Out-Null

        $wrongBranchPath = $sourceBranch | ConvertTo-Json -Depth 30 | ConvertFrom-Json
        $wrongBranchPath.writes = @('runs/<case-id>/control/R<n>/**')
        Assert-InvalidBranchManifest 'wrong-branch-write-root' $wrongBranchPath

        $driftedSnapshot = $sourceBranch | ConvertTo-Json -Depth 30 | ConvertFrom-Json
        $driftedSnapshot.snapshot_sha256 = '0' * 64
        $driftPath = Join-Path (Split-Path -Parent $manifestPath) ('test-snapshot-drift-' + [guid]::NewGuid().ToString('N') + '.json')
        try {
            $driftedSnapshot | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $driftPath -Encoding utf8NoBOM
            $caught = $null
            try { & $validatorPath -ManifestPath $driftPath -WorkspaceRoot $workspaceFull | Out-Null } catch { $caught = $_.Exception.Message.Split(':')[0] }
            if ($caught -ne 'SNAPSHOT_HASH_MISMATCH') { throw "TEST_FAILURE: snapshot hash drift expected SNAPSHOT_HASH_MISMATCH but got $caught" }
        } finally {
            Remove-Item -LiteralPath $driftPath -Force -ErrorAction SilentlyContinue
        }

        $badExecutionStatus = $sourceBranch | ConvertTo-Json -Depth 30 | ConvertFrom-Json
        $badExecutionStatus.execution_status = 'EXECUTED'
        Assert-InvalidBranchManifest 'executable-status' $badExecutionStatus

        $widenedAuthority = $sourceBranch | ConvertTo-Json -Depth 30 | ConvertFrom-Json
        $widenedAuthority.external_writes = 'ALLOW'
        Assert-InvalidBranchManifest 'authority-widening' $widenedAuthority
    } finally {
        Remove-Item -LiteralPath $sourcePath, $abkPath -Force -ErrorAction SilentlyContinue
    }
    Write-Output 'BRANCH_MANIFEST_TESTS: 9/9 PASS'
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

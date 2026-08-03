param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\branch-manifest.schema.json'
$manifestPath = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\branches\control\manifest.json'
$campaignPath = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\campaign.json'
$entrypointPath = Join-Path $workspaceFull 'benchmarks\runners\control\run.ps1'
$validatorPath = Join-Path $workspaceFull 'benchmarks\scripts\validate-branch-manifest.ps1'

if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or -not (Test-Path -LiteralPath $validatorPath -PathType Leaf)) {
    throw 'TEST_FAILURE: branch manifest schema, validator, and control manifest must exist'
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
    Write-Output 'BRANCH_MANIFEST_TESTS: 3/3 PASS'
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

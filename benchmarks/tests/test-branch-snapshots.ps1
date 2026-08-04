param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,

    [Parameter(Mandatory = $true)]
    [string]$AiBoosterKitRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$abkFull = [IO.Path]::GetFullPath($AiBoosterKitRoot)
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\branch-snapshot.schema.json'
$sourceDescriptorPath = Join-Path $workspaceFull 'benchmarks\snapshots\source-native-openspec-artifact-graph.json'
$abkDescriptorPath = Join-Path $workspaceFull 'benchmarks\snapshots\abk-native-ai-booster-kit-feature.json'
$sourcePinningPath = Join-Path $workspaceFull 'sources\SOURCE-PINNING.md'

foreach ($path in @($schemaPath, $sourceDescriptorPath, $abkDescriptorPath, $sourcePinningPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "TEST_FAILURE: required snapshot file is missing: $path" }
}
if (-not (Test-Path -LiteralPath $abkFull -PathType Container)) { throw "TEST_FAILURE: AI Booster Kit root is missing: $abkFull" }

function Get-Hash([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-InventoryHash([object]$Descriptor) {
    $canonical = (($Descriptor.inventory.entries | ForEach-Object {
        '{0}|{1}|{2}|{3}' -f $_.path, $_.digest, $_.digest_algorithm, $_.size
    }) -join "`n") + "`n"
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical))) -replace '-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-GitBlob([string]$Root, [string]$Revision, [string]$RelativePath) {
    $lines = @(& git -C $Root ls-tree $Revision -- $RelativePath)
    if ($LASTEXITCODE -ne 0 -or $lines.Count -ne 1) { throw "TEST_FAILURE: git tree lookup failed for $RelativePath" }
    $metadata = ($lines[0] -split "`t", 2)[0] -split ' '
    if ($metadata.Count -ne 3 -or $metadata[1] -ne 'blob') { throw "TEST_FAILURE: expected blob entry for $RelativePath" }
    return $metadata[2]
}

function Assert-Descriptor([string]$Path, [string]$ExpectedBranch) {
    if (-not (Test-Json -LiteralPath $Path -SchemaFile $schemaPath)) { throw "TEST_FAILURE: snapshot descriptor is not schema-valid: $Path" }
    $descriptor = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    if ($descriptor.branch -ne $ExpectedBranch) { throw "TEST_FAILURE: descriptor branch mismatch for $Path" }
    if ($descriptor.execution_status -ne 'NOT_EXECUTED') { throw "TEST_FAILURE: descriptor must not claim execution: $Path" }
    if ($descriptor.scope.source_code_copied_into_framework_matrix -or $descriptor.scope.git_linked_into_framework_matrix -or $descriptor.scope.runtime_included) {
        throw "TEST_FAILURE: snapshot descriptor broadens Framework-Matrix scope: $Path"
    }
    if ((Get-InventoryHash $descriptor) -ne $descriptor.inventory.inventory_sha256) { throw "TEST_FAILURE: inventory hash mismatch: $Path" }
    return $descriptor
}

$source = Assert-Descriptor $sourceDescriptorPath 'source_native'
$abk = Assert-Descriptor $abkDescriptorPath 'abk_native'

$pinning = Get-Content -Raw -LiteralPath $sourcePinningPath
if ($pinning -notmatch ('OpenSpec.*' + [regex]::Escape($source.provenance.revision))) {
    throw 'TEST_FAILURE: source_native revision does not match SOURCE-PINNING.md'
}
$sourceRoot = Join-Path $workspaceFull 'sources\fission-openspec'
foreach ($entry in $source.inventory.entries) {
    $path = Join-Path $sourceRoot ($entry.path -replace '/', '\')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "TEST_FAILURE: source snapshot file is missing: $($entry.path)" }
    if ((Get-Hash $path) -ne $entry.digest -or (Get-Item -LiteralPath $path).Length -ne $entry.size) {
        throw "TEST_FAILURE: source snapshot inventory drift: $($entry.path)"
    }
}

$pinnedRevision = [string]$abk.provenance.revision
$revisionCheck = (& git -C $abkFull rev-parse ("$pinnedRevision^{commit}")).Trim()
if ($LASTEXITCODE -ne 0 -or $revisionCheck -ne $pinnedRevision) { throw 'TEST_FAILURE: pinned AI Booster Kit revision is not available as an immutable commit' }
foreach ($entry in $abk.inventory.entries) {
    if ((Get-GitBlob $abkFull $pinnedRevision $entry.path) -ne $entry.digest) { throw "TEST_FAILURE: AI Booster Kit pinned Git blob drift: $($entry.path)" }
    $size = [int64](& git -C $abkFull cat-file -s ("${pinnedRevision}:" + $entry.path))
    if ($LASTEXITCODE -ne 0 -or $size -ne $entry.size) { throw "TEST_FAILURE: AI Booster Kit blob size drift: $($entry.path)" }
}

if ($source.status -ne 'READY_FOR_ENTRYPOINT' -or $source.disposition.candidate_disposition -ne 'READY_FOR_CLEAN_ROOM_ENTRYPOINT') {
    throw 'TEST_FAILURE: source_native descriptor must be ready for entrypoint creation'
}
if ($abk.status -ne 'NOT_COMPARABLE' -or $abk.disposition.candidate_disposition -ne 'NOT_COMPARABLE') {
    throw 'TEST_FAILURE: abk_native descriptor must remain NOT_COMPARABLE'
}

Write-Output 'BRANCH_SNAPSHOT_TESTS: 2/2 PASS'

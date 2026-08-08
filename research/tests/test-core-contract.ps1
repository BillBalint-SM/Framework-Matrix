[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "TEST_FAILURE: $Message" }
}

function Invoke-Validator([string]$WorkspacePath, [string]$IndexPath) {
    $arguments = @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-File', $validator,
        '-WorkspaceRoot', $WorkspacePath,
        '-IndexPath', $IndexPath
    )
    $output = @(& $pwshPath @arguments 2>&1)
    return [pscustomobject]@{ code = $LASTEXITCODE; output = $output }
}

function Assert-Rejected([object]$Result, [string]$Code, [string]$Message) {
    Assert-True ($Result.code -ne 0) $Message
    Assert-True ((@($Result.output) -join ' ') -match "CORE_CONTRACT_VALIDATION_FAILURE: $Code") $Message
}

function Write-Json([string]$Path, [object]$Value) {
    $content = $Value | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText(
        $Path,
        $content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function New-TemporaryWorkspace([string]$SourceWorkspace, [string]$Guid) {
    $temporaryWorkspace = Join-Path $SourceWorkspace "contracts/test-core-contract-$Guid"
    $temporaryContracts = Join-Path $temporaryWorkspace 'contracts'
    New-Item -ItemType Directory -Path $temporaryContracts -Force | Out-Null

    foreach ($fileName in @('CORE-CONTRACT.md', 'core-contract.schema.json', 'core-contract-index.json')) {
        Copy-Item -LiteralPath (Join-Path $SourceWorkspace "contracts/$fileName") -Destination (Join-Path $temporaryContracts $fileName)
    }

    return $temporaryWorkspace
}

function Remove-TemporaryWorkspace([string]$SourceWorkspace, [string]$TemporaryWorkspace) {
    $contractsRoot = [System.IO.Path]::GetFullPath((Join-Path $SourceWorkspace 'contracts'))
    $resolvedTemporaryWorkspace = [System.IO.Path]::GetFullPath($TemporaryWorkspace)
    $allowedPrefix = "$contractsRoot$([System.IO.Path]::DirectorySeparatorChar)test-core-contract-"
    Assert-True ($resolvedTemporaryWorkspace.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) 'Cleanup target must be a GUID test workspace beneath contracts.'
    Assert-True (Test-Path -LiteralPath $resolvedTemporaryWorkspace) 'Cleanup target must exist before removal.'
    Remove-Item -LiteralPath $resolvedTemporaryWorkspace -Recurse -Force
}

$resolvedWorkspaceRoot = [System.IO.Path]::GetFullPath($WorkspaceRoot)
$validator = Join-Path $resolvedWorkspaceRoot 'research/scripts/validate-core-contract.ps1'
$pwshPath = (Get-Command pwsh -ErrorAction Stop).Source
$realIndex = Join-Path $resolvedWorkspaceRoot 'contracts/core-contract-index.json'
$successLine = 'CORE_CONTRACT_VALID: version=1.0.0; dimensions=15; work_unit_types=3'
$passed = 0

$result = Invoke-Validator $resolvedWorkspaceRoot $realIndex
Assert-True ($result.code -eq 0) 'The real core-contract index must validate successfully.'
Assert-True ((@($result.output) -join ' ') -match [regex]::Escape($successLine)) 'The validator must emit the exact success line.'
$passed++

$temporaryWorkspace = $null
try {
    $temporaryWorkspace = New-TemporaryWorkspace $resolvedWorkspaceRoot ([guid]::NewGuid().ToString())
    $temporaryIndex = Join-Path $temporaryWorkspace 'contracts/core-contract-index.json'
    $index = Get-Content -Raw -LiteralPath $temporaryIndex | ConvertFrom-Json
    $index.contract_sha256 = ('0' * 64)
    Write-Json $temporaryIndex $index
    Assert-Rejected (Invoke-Validator $temporaryWorkspace $temporaryIndex) 'CONTRACT_HASH_MISMATCH' 'A mismatched contract hash must be rejected.'
    $passed++
}
finally {
    if ($null -ne $temporaryWorkspace -and (Test-Path -LiteralPath $temporaryWorkspace)) {
        Remove-TemporaryWorkspace $resolvedWorkspaceRoot $temporaryWorkspace
    }
}

$temporaryWorkspace = $null
try {
    $temporaryWorkspace = New-TemporaryWorkspace $resolvedWorkspaceRoot ([guid]::NewGuid().ToString())
    $temporaryIndex = Join-Path $temporaryWorkspace 'contracts/core-contract-index.json'
    $index = Get-Content -Raw -LiteralPath $temporaryIndex | ConvertFrom-Json
    $index.dimensions[13] = 'CC-15'
    $index.dimensions[14] = 'CC-14'
    Write-Json $temporaryIndex $index
    Assert-Rejected (Invoke-Validator $temporaryWorkspace $temporaryIndex) 'DIMENSION_SET_INVALID' 'A reordered but unique dimension list must be rejected.'
    $passed++
}
finally {
    if ($null -ne $temporaryWorkspace -and (Test-Path -LiteralPath $temporaryWorkspace)) {
        Remove-TemporaryWorkspace $resolvedWorkspaceRoot $temporaryWorkspace
    }
}

$temporaryWorkspace = $null
try {
    $temporaryWorkspace = New-TemporaryWorkspace $resolvedWorkspaceRoot ([guid]::NewGuid().ToString())
    $temporaryContracts = Join-Path $temporaryWorkspace 'contracts'
    $temporaryContract = Join-Path $temporaryContracts 'CORE-CONTRACT.md'
    $temporaryIndex = Join-Path $temporaryContracts 'core-contract-index.json'
    $markdown = Get-Content -Raw -LiteralPath $temporaryContract
    [System.IO.File]::WriteAllText(
        $temporaryContract,
        $markdown.Replace('| `CC-15` |', '| `CC-16` |'),
        [System.Text.UTF8Encoding]::new($false)
    )
    $index = Get-Content -Raw -LiteralPath $temporaryIndex | ConvertFrom-Json
    $index.contract_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $temporaryContract).Hash.ToLowerInvariant()
    Write-Json $temporaryIndex $index
    Assert-Rejected (Invoke-Validator $temporaryWorkspace $temporaryIndex) 'DOCUMENT_DIMENSION_MISMATCH' 'A hash-matching document with a renamed dimension must be rejected.'
    $passed++
}
finally {
    if ($null -ne $temporaryWorkspace -and (Test-Path -LiteralPath $temporaryWorkspace)) {
        Remove-TemporaryWorkspace $resolvedWorkspaceRoot $temporaryWorkspace
    }
}

$temporaryWorkspace = $null
try {
    $temporaryWorkspace = New-TemporaryWorkspace $resolvedWorkspaceRoot ([guid]::NewGuid().ToString())
    $temporaryIndex = Join-Path $temporaryWorkspace 'contracts/core-contract-index.json'
    $index = Get-Content -Raw -LiteralPath $temporaryIndex | ConvertFrom-Json
    $index.contract_path = '../README.md'
    Write-Json $temporaryIndex $index
    Assert-Rejected (Invoke-Validator $temporaryWorkspace $temporaryIndex) 'PATH_INVALID' 'A traversal contract path must be rejected.'
    $index.contract_path = 'contracts/CORE-CONTRACT.md;Invoke-Expression'
    Write-Json $temporaryIndex $index
    Assert-Rejected (Invoke-Validator $temporaryWorkspace $temporaryIndex) 'PATH_INVALID' 'A shell-metacharacter contract path must be rejected.'
    $passed++
}
finally {
    if ($null -ne $temporaryWorkspace -and (Test-Path -LiteralPath $temporaryWorkspace)) {
        Remove-TemporaryWorkspace $resolvedWorkspaceRoot $temporaryWorkspace
    }
}

$temporaryWorkspace = $null
try {
    $temporaryWorkspace = New-TemporaryWorkspace $resolvedWorkspaceRoot ([guid]::NewGuid().ToString())
    $temporaryIndex = Join-Path $temporaryWorkspace 'contracts/core-contract-index.json'
    $index = Get-Content -Raw -LiteralPath $temporaryIndex | ConvertFrom-Json
    $index | Add-Member -NotePropertyName 'unexpected_root_property' -NotePropertyValue 'unexpected'
    Write-Json $temporaryIndex $index
    Assert-Rejected (Invoke-Validator $temporaryWorkspace $temporaryIndex) 'INDEX_SCHEMA_INVALID' 'An extra index root property must be rejected by the schema.'
    $passed++
}
finally {
    if ($null -ne $temporaryWorkspace -and (Test-Path -LiteralPath $temporaryWorkspace)) {
        Remove-TemporaryWorkspace $resolvedWorkspaceRoot $temporaryWorkspace
    }
}

$temporaryWorkspace = $null
try {
    $temporaryWorkspace = New-TemporaryWorkspace $resolvedWorkspaceRoot ([guid]::NewGuid().ToString())
    $temporaryContracts = Join-Path $temporaryWorkspace 'contracts'
    $junctionPath = Join-Path $temporaryContracts 'index-junction'
    New-Item -ItemType Junction -Path $junctionPath -Target $temporaryContracts | Out-Null
    $junctionIndex = Join-Path $junctionPath 'core-contract-index.json'
    Assert-Rejected (Invoke-Validator $temporaryWorkspace $junctionIndex) 'PATH_REPARSE_POINT' 'An index reached through a junction must be rejected.'
    Remove-Item -LiteralPath $junctionPath -Force
    Assert-True (Test-Path -LiteralPath $temporaryContracts) 'Removing a junction must not remove its target.'
    $passed++
}
finally {
    if ($null -ne $temporaryWorkspace -and (Test-Path -LiteralPath $temporaryWorkspace)) {
        Remove-TemporaryWorkspace $resolvedWorkspaceRoot $temporaryWorkspace
    }
}

Write-Output "CORE_CONTRACT_TESTS: $passed/7 PASS"

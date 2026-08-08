[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,

    [Parameter(Mandatory = $true)]
    [string]$ReceiptPath
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Code, [string]$Detail) {
    throw "CONTRACT_RECEIPT_FAILURE: $Code; $Detail"
}

function Test-IsChildPath([string]$RootPath, [string]$CandidatePath) {
    $rootWithSeparator = if (
        $RootPath.EndsWith([System.IO.Path]::DirectorySeparatorChar) -or
        $RootPath.EndsWith([System.IO.Path]::AltDirectorySeparatorChar)
    ) {
        $RootPath
    }
    else {
        "$RootPath$([System.IO.Path]::DirectorySeparatorChar)"
    }
    return $CandidatePath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-IsUnsafeRelativePath([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return $true }
    if ([System.IO.Path]::IsPathRooted($Path)) { return $true }
    if ($Path -match '[\x00-\x1F]') { return $true }
    if ($Path.IndexOfAny([char[]]'<>:"|?*;&$`(){}!') -ge 0) { return $true }
    foreach ($segment in ($Path -split '[\\/]')) {
        if ($segment -eq '' -or $segment -eq '.' -or $segment -eq '..') { return $true }
    }
    return $false
}

function Assert-NoReparsePoint([string]$RootPath, [string]$CandidatePath) {
    $relativePath = [System.IO.Path]::GetRelativePath($RootPath, $CandidatePath)
    $currentPath = $RootPath
    $rootItem = Get-Item -Force -LiteralPath $currentPath
    if (($rootItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        Fail 'PATH_REPARSE_POINT' 'Workspace root is a reparse point.'
    }
    if ($relativePath -eq '.') { return }

    foreach ($segment in ($relativePath -split '[\\/]')) {
        if ([string]::IsNullOrWhiteSpace($segment)) { continue }
        $currentPath = Join-Path $currentPath $segment
        if (Test-Path -LiteralPath $currentPath) {
            $item = Get-Item -Force -LiteralPath $currentPath
            if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                Fail 'PATH_REPARSE_POINT' "Reparse point is not allowed: $relativePath"
            }
        }
    }
}

function Get-ConfinedReceiptPath([string]$WorkspacePath, [string]$RelativeReceiptPath) {
    if (Test-IsUnsafeRelativePath $RelativeReceiptPath) {
        Fail 'PATH_INVALID' 'Receipt path is not a safe relative path.'
    }
    $receiptsRoot = [System.IO.Path]::GetFullPath((Join-Path $WorkspacePath 'registry/contract-receipts'))
    $candidatePath = [System.IO.Path]::GetFullPath((Join-Path $WorkspacePath $RelativeReceiptPath))
    if (-not (Test-IsChildPath $receiptsRoot $candidatePath)) {
        Fail 'PATH_INVALID' 'Receipt path must be beneath registry/contract-receipts.'
    }
    Assert-NoReparsePoint $WorkspacePath $candidatePath
    return $candidatePath
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

try {
    if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
        Fail 'INPUT_MISSING' 'Workspace root is missing.'
    }

    $workspacePath = [System.IO.Path]::TrimEndingDirectorySeparator([System.IO.Path]::GetFullPath($WorkspaceRoot))
    Assert-NoReparsePoint $workspacePath $workspacePath
    $receiptFullPath = Get-ConfinedReceiptPath $workspacePath $ReceiptPath
    if (-not (Test-Path -LiteralPath $receiptFullPath -PathType Leaf)) {
        Fail 'INPUT_MISSING' 'Receipt is missing.'
    }

    $schemaPath = Join-Path $workspacePath 'schemas/contract-receipt.schema.json'
    Assert-NoReparsePoint $workspacePath $schemaPath
    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
        Fail 'INPUT_MISSING' 'Receipt schema is missing.'
    }
    try {
        $schemaValid = Test-Json -LiteralPath $receiptFullPath -SchemaFile $schemaPath -ErrorAction Stop
    }
    catch {
        Fail 'RECEIPT_SCHEMA_INVALID' 'Receipt does not satisfy the receipt schema.'
    }
    if (-not $schemaValid) {
        Fail 'RECEIPT_SCHEMA_INVALID' 'Receipt does not satisfy the receipt schema.'
    }
    try {
        $receipt = Get-Content -Raw -LiteralPath $receiptFullPath | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Fail 'RECEIPT_SCHEMA_INVALID' 'Receipt cannot be parsed.'
    }
    if ($receipt.receipt_id -cne $receipt.work_unit_id) {
        Fail 'RECEIPT_ID_MISMATCH' 'receipt_id must equal work_unit_id.'
    }

    $contractValidator = Join-Path $workspacePath 'research/scripts/validate-core-contract.ps1'
    if (-not (Test-Path -LiteralPath $contractValidator -PathType Leaf)) {
        Fail 'INPUT_MISSING' 'Core-contract validator is missing.'
    }
    $contractOutput = @(& $contractValidator -WorkspaceRoot $workspacePath -IndexPath 'contracts/core-contract-index.json' 2>&1)
    $contractSucceeded = $?
    if (-not $contractSucceeded) {
        Fail 'CONTRACT_VALIDATION_FAILED' 'Current core contract did not validate.'
    }

    $indexPath = Join-Path $workspacePath 'contracts/core-contract-index.json'
    Assert-NoReparsePoint $workspacePath $indexPath
    $index = Get-Content -Raw -LiteralPath $indexPath | ConvertFrom-Json -ErrorAction Stop
    if ($receipt.contract.version -cne $index.contract_version) {
        Fail 'CONTRACT_VERSION_MISMATCH' 'Receipt contract version is not current.'
    }
    if ($receipt.contract.path -cne $index.contract_path) {
        Fail 'CONTRACT_PATH_MISMATCH' 'Receipt contract path is not current.'
    }
    $contractPath = Join-Path $workspacePath $index.contract_path
    Assert-NoReparsePoint $workspacePath $contractPath
    if ($receipt.contract.sha256 -cne (Get-Sha256 $contractPath)) {
        Fail 'CONTRACT_HASH_MISMATCH' 'Receipt contract hash is not current.'
    }
    foreach ($dimensionId in @($receipt.dimensions)) {
        if ($dimensionId -notin @($index.dimensions)) {
            Fail 'DIMENSION_UNKNOWN' 'Receipt contains a dimension that is not current.'
        }
    }
    if ($receipt.dependencies_checked -ne $true -or $receipt.gate_status -cne 'PASSED') {
        Fail 'GATE_STATUS_INVALID' 'Receipt gate fields are invalid.'
    }

    Write-Output 'CONTRACT_RECEIPT_VALID: framework-matrix-core-contract-foundation; contract=1.0.0'
}
catch {
    if ($_.Exception.Message -match '^CONTRACT_RECEIPT_FAILURE:') {
        Write-Error $_.Exception.Message
        exit 1
    }
    Write-Error 'CONTRACT_RECEIPT_FAILURE: UNEXPECTED_ERROR; Receipt validation could not complete.'
    exit 1
}

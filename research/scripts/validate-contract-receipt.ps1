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

function Get-NormalizedRelativeReceiptPath([string]$Path) {
    $normalizedPath = $Path
    if ($normalizedPath.StartsWith('.\', [System.StringComparison]::Ordinal) -or $normalizedPath.StartsWith('./', [System.StringComparison]::Ordinal)) {
        $normalizedPath = $normalizedPath.Substring(2)
    }
    return $normalizedPath
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
                Fail 'PATH_REPARSE_POINT' 'A reparse point exists on the checked path.'
            }
        }
    }
}

function Get-ConfinedReceiptPath([string]$WorkspacePath, [string]$RelativeReceiptPath) {
    $normalizedReceiptPath = Get-NormalizedRelativeReceiptPath $RelativeReceiptPath
    if (Test-IsUnsafeRelativePath $normalizedReceiptPath) {
        Fail 'PATH_INVALID' 'Receipt path is not a safe relative path.'
    }
    $receiptsRoot = [System.IO.Path]::GetFullPath((Join-Path $WorkspacePath 'registry/contract-receipts'))
    $candidatePath = [System.IO.Path]::GetFullPath((Join-Path $WorkspacePath $normalizedReceiptPath))
    if (-not (Test-IsChildPath $receiptsRoot $candidatePath)) {
        Fail 'PATH_INVALID' 'Receipt path must be beneath registry/contract-receipts.'
    }
    Assert-NoReparsePoint $WorkspacePath $candidatePath
    return $candidatePath
}

function Get-ConfinedWorkspacePath([string]$WorkspacePath, [string]$RelativePath) {
    if (Test-IsUnsafeRelativePath $RelativePath) {
        Fail 'PATH_INVALID' 'Required workspace path is not a safe relative path.'
    }
    $candidatePath = [System.IO.Path]::GetFullPath((Join-Path $WorkspacePath $RelativePath))
    if (-not (Test-IsChildPath $WorkspacePath $candidatePath)) {
        Fail 'PATH_INVALID' 'Required workspace path escapes the workspace.'
    }
    Assert-NoReparsePoint $WorkspacePath $candidatePath
    return $candidatePath
}

function Invoke-CoreContractValidator([string]$ContractValidatorPath, [string]$WorkspacePath) {
    $pwshPath = (Get-Process -Id $PID -ErrorAction Stop).Path
    $arguments = @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-File', $ContractValidatorPath,
        '-WorkspaceRoot', $WorkspacePath,
        '-IndexPath', 'contracts/core-contract-index.json'
    )
    try {
        & $pwshPath @arguments *> $null
    }
    catch {
        Fail 'CONTRACT_VALIDATION_FAILED' 'Current core contract did not validate.'
    }
    if ($LASTEXITCODE -ne 0) {
        Fail 'CONTRACT_VALIDATION_FAILED' 'Current core contract did not validate.'
    }
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

    $contractValidator = Get-ConfinedWorkspacePath $workspacePath 'research/scripts/validate-core-contract.ps1'
    if (-not (Test-Path -LiteralPath $contractValidator -PathType Leaf)) {
        Fail 'INPUT_MISSING' 'Core-contract validator is missing.'
    }
    Invoke-CoreContractValidator $contractValidator $workspacePath

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

    Write-Output "CONTRACT_RECEIPT_VALID: $($receipt.receipt_id); contract=$($receipt.contract.version)"
}
catch {
    if ($_.Exception.Message -match '^CONTRACT_RECEIPT_FAILURE:') {
        Write-Error $_.Exception.Message
        exit 1
    }
    Write-Error 'CONTRACT_RECEIPT_FAILURE: UNEXPECTED_ERROR; Receipt validation could not complete.'
    exit 1
}

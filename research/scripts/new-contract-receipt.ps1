[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,

    [Parameter(Mandatory = $true)]
    [string]$WorkUnitId,

    [Parameter(Mandatory = $true)]
    [ValidateSet('session', 'task', 'work_part')]
    [string]$WorkUnitType,

    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [string[]]$DimensionIds,

    [Parameter(Mandatory = $true)]
    [string[]]$ExpectedEvidence,

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
    if (Test-Path -LiteralPath $receiptFullPath) {
        Fail 'RECEIPT_EXISTS' 'Receipt path already exists.'
    }

    $receiptsRoot = Join-Path $workspacePath 'registry/contract-receipts'
    if (-not (Test-Path -LiteralPath $receiptsRoot)) {
        New-Item -ItemType Directory -Path $receiptsRoot -Force | Out-Null
    }
    Assert-NoReparsePoint $workspacePath $receiptFullPath
    if (-not (Test-Path -LiteralPath (Split-Path -Parent $receiptFullPath) -PathType Container)) {
        Fail 'INPUT_MISSING' 'Receipt parent directory is missing.'
    }

    $schemaPath = Join-Path $workspacePath 'schemas/contract-receipt.schema.json'
    Assert-NoReparsePoint $workspacePath $schemaPath
    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
        Fail 'INPUT_MISSING' 'Receipt schema is missing.'
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

    if ($WorkUnitId -notmatch '^[a-z0-9][a-z0-9._:-]{0,199}$') {
        Fail 'WORK_UNIT_ID_INVALID' 'Work unit ID is invalid.'
    }
    if ($DimensionIds.Count -eq 0 -or @($DimensionIds | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -ne 0) {
        Fail 'DIMENSION_REQUIRED' 'At least one non-empty dimension is required.'
    }
    if ($ExpectedEvidence.Count -eq 0 -or @($ExpectedEvidence | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count -ne 0) {
        Fail 'EVIDENCE_REQUIRED' 'At least one non-empty expected evidence value is required.'
    }

    $indexPath = Join-Path $workspacePath 'contracts/core-contract-index.json'
    Assert-NoReparsePoint $workspacePath $indexPath
    $index = Get-Content -Raw -LiteralPath $indexPath | ConvertFrom-Json -ErrorAction Stop
    $knownDimensions = @($index.dimensions)
    $uniqueDimensions = @($DimensionIds | Sort-Object -Unique)
    if ($uniqueDimensions.Count -ne $DimensionIds.Count) {
        Fail 'DIMENSION_DUPLICATE' 'Dimensions must be unique.'
    }
    foreach ($dimensionId in $uniqueDimensions) {
        if ($dimensionId -notin $knownDimensions) {
            Fail 'DIMENSION_UNKNOWN' 'Dimension is not declared by the current contract.'
        }
    }

    $evidenceSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $uniqueEvidence = [System.Collections.Generic.List[string]]::new()
    foreach ($evidenceItem in $ExpectedEvidence) {
        if (-not $evidenceSet.Add($evidenceItem)) {
            Fail 'EVIDENCE_DUPLICATE' 'Expected evidence values must be unique.'
        }
        $uniqueEvidence.Add($evidenceItem)
    }

    $contractPath = Join-Path $workspacePath $index.contract_path
    Assert-NoReparsePoint $workspacePath $contractPath
    $receipt = [ordered]@{
        '$schema' = '../../schemas/contract-receipt.schema.json'
        schema_version = '1.0.0'
        receipt_id = $WorkUnitId
        work_unit_id = $WorkUnitId
        work_unit_type = $WorkUnitType
        created_at = [datetime]::UtcNow.ToString('o')
        contract = [ordered]@{
            version = $index.contract_version
            path = $index.contract_path
            sha256 = Get-Sha256 $contractPath
        }
        dimensions = $uniqueDimensions
        expected_evidence = @($uniqueEvidence)
        dependencies_checked = $true
        gate_status = 'PASSED'
    }
    $temporaryPath = "$receiptFullPath.$([guid]::NewGuid().ToString('N')).tmp"
    try {
        $json = ($receipt | ConvertTo-Json -Depth 10) -replace "`r`n", "`n"
        [System.IO.File]::WriteAllText($temporaryPath, $json, [System.Text.UTF8Encoding]::new($false))
        $isValid = Test-Json -LiteralPath $temporaryPath -SchemaFile $schemaPath -ErrorAction Stop
        if (-not $isValid) {
            Fail 'RECEIPT_SCHEMA_INVALID' 'Generated receipt does not satisfy the receipt schema.'
        }
        Move-Item -LiteralPath $temporaryPath -Destination $receiptFullPath -ErrorAction Stop
    }
    finally {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }

    Write-Output 'CONTRACT_RECEIPT_CREATED: framework-matrix-core-contract-foundation; dimensions=15'
}
catch {
    if ($_.Exception.Message -match '^CONTRACT_RECEIPT_FAILURE:') {
        Write-Error $_.Exception.Message
        exit 1
    }
    Write-Error 'CONTRACT_RECEIPT_FAILURE: UNEXPECTED_ERROR; Receipt creation could not complete.'
    exit 1
}

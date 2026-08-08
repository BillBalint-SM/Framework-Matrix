[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,

    [Parameter(Mandatory = $true)]
    [string]$IndexPath
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Code, [string]$Detail) {
    throw "CORE_CONTRACT_VALIDATION_FAILURE: $Code; $Detail"
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Test-IsChildPath([string]$RootPath, [string]$CandidatePath) {
    $rootWithSeparator = "$RootPath$([System.IO.Path]::DirectorySeparatorChar)"
    return $CandidatePath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)
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

function Assert-ExplicitRegistryPath([string]$WorkspacePath, [string]$RegistryPath) {
    if (Test-IsUnsafeRelativePath $RegistryPath) {
        Fail 'PATH_INVALID' 'dependency_registry_paths contains an unsafe path.'
    }
    $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path $WorkspacePath $RegistryPath))
    if (-not (Test-IsChildPath $WorkspacePath $resolvedPath)) {
        Fail 'PATH_INVALID' 'dependency_registry_paths escapes the workspace.'
    }
    Assert-NoReparsePoint $WorkspacePath $resolvedPath
}

try {
    if (-not (Test-Path -LiteralPath $WorkspaceRoot -PathType Container)) {
        Fail 'INPUT_MISSING' 'Workspace root is missing.'
    }

    $workspacePath = [System.IO.Path]::TrimEndingDirectorySeparator(
        [System.IO.Path]::GetFullPath($WorkspaceRoot)
    )
    $indexFullPath = if ([System.IO.Path]::IsPathRooted($IndexPath)) {
        [System.IO.Path]::GetFullPath($IndexPath)
    }
    else {
        [System.IO.Path]::GetFullPath((Join-Path $workspacePath $IndexPath))
    }

    if (-not (Test-IsChildPath $workspacePath $indexFullPath)) {
        Fail 'PATH_INVALID' 'Index path escapes the workspace.'
    }
    Assert-NoReparsePoint $workspacePath $indexFullPath

    $schemaPath = Join-Path $workspacePath 'contracts/core-contract.schema.json'
    Assert-NoReparsePoint $workspacePath $schemaPath
    if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) {
        Fail 'INPUT_MISSING' 'Core-contract schema is missing.'
    }
    if (-not (Test-Path -LiteralPath $indexFullPath -PathType Leaf)) {
        Fail 'INPUT_MISSING' 'Core-contract index is missing.'
    }

    try {
        $indexIsValid = Test-Json -Path $indexFullPath -SchemaFile $schemaPath -ErrorAction Stop
    }
    catch {
        Fail 'INDEX_SCHEMA_INVALID' 'Index does not satisfy the core-contract schema.'
    }
    if (-not $indexIsValid) {
        Fail 'INDEX_SCHEMA_INVALID' 'Index does not satisfy the core-contract schema.'
    }

    try {
        $index = Get-Content -Raw -LiteralPath $indexFullPath | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Fail 'INDEX_SCHEMA_INVALID' 'Index cannot be parsed.'
    }

    if (Test-IsUnsafeRelativePath $index.contract_path) {
        Fail 'PATH_INVALID' 'contract_path is unsafe.'
    }
    if ($index.contract_path -cne 'contracts/CORE-CONTRACT.md') {
        Fail 'CONTRACT_PATH_INVALID' 'contract_path must be contracts/CORE-CONTRACT.md.'
    }

    $contractPath = [System.IO.Path]::GetFullPath((Join-Path $workspacePath $index.contract_path))
    if (-not (Test-IsChildPath $workspacePath $contractPath)) {
        Fail 'PATH_INVALID' 'contract_path escapes the workspace.'
    }
    Assert-NoReparsePoint $workspacePath $contractPath
    if (-not (Test-Path -LiteralPath $contractPath -PathType Leaf)) {
        Fail 'INPUT_MISSING' 'Core contract is missing.'
    }

    if ((Get-Sha256 $contractPath) -cne $index.contract_sha256) {
        Fail 'CONTRACT_HASH_MISMATCH' 'contract_sha256 does not match contracts/CORE-CONTRACT.md.'
    }

    $expectedDimensions = @(
        'CC-01', 'CC-02', 'CC-03', 'CC-04', 'CC-05',
        'CC-06', 'CC-07', 'CC-08', 'CC-09', 'CC-10',
        'CC-11', 'CC-12', 'CC-13', 'CC-14', 'CC-15'
    )
    $actualDimensions = @($index.dimensions)
    if ($actualDimensions.Count -ne $expectedDimensions.Count -or (@($actualDimensions | Where-Object { $_ -notin $expectedDimensions }).Count -ne 0)) {
        Fail 'DIMENSION_SET_INVALID' 'dimensions must contain CC-01 through CC-15 exactly once.'
    }
    for ($position = 0; $position -lt $expectedDimensions.Count; $position++) {
        if ($actualDimensions[$position] -cne $expectedDimensions[$position]) {
            Fail 'DIMENSION_SET_INVALID' 'dimensions must be in canonical order.'
        }
    }

    $documentDimensions = @([regex]::Matches(
        (Get-Content -Raw -LiteralPath $contractPath),
        '(?m)^\|\s*`(?<id>CC-\d{2})`\s*\|'
    ) | ForEach-Object { $_.Groups['id'].Value })
    if ($documentDimensions.Count -ne $expectedDimensions.Count) {
        Fail 'DOCUMENT_DIMENSION_MISMATCH' 'CORE-CONTRACT.md must declare all canonical dimensions exactly once.'
    }
    for ($position = 0; $position -lt $expectedDimensions.Count; $position++) {
        if ($documentDimensions[$position] -cne $expectedDimensions[$position]) {
            Fail 'DOCUMENT_DIMENSION_MISMATCH' 'CORE-CONTRACT.md dimensions do not match the canonical ordered set.'
        }
    }

    $expectedTypes = @('session', 'task', 'work_part')
    $expectedRulePaths = @(
        'research/scripts/validate-core-contract.ps1',
        'research/scripts/new-contract-receipt.ps1',
        'research/scripts/validate-contract-receipt.ps1'
    )
    $workUnitTypes = @($index.work_unit_types)
    if ($workUnitTypes.Count -ne $expectedTypes.Count) {
        Fail 'WORK_UNIT_RULE_INVALID' 'work_unit_types must contain three canonical entries.'
    }
    for ($position = 0; $position -lt $expectedTypes.Count; $position++) {
        $workUnitType = $workUnitTypes[$position]
        if (
            $workUnitType.type -cne $expectedTypes[$position] -or
            $workUnitType.requires_receipt -ne $true -or
            $workUnitType.minimum_dimension_count -ne 1 -or
            $workUnitType.dimension_policy -cne 'affected_explicit' -or
            $workUnitType.requires_dependency_check -ne $true -or
            $workUnitType.contract_validator_path -cne $expectedRulePaths[0] -or
            $workUnitType.receipt_creator_path -cne $expectedRulePaths[1] -or
            $workUnitType.receipt_validator_path -cne $expectedRulePaths[2]
        ) {
            Fail 'WORK_UNIT_RULE_INVALID' 'work_unit_types contains a drifted rule.'
        }
        foreach ($rulePath in @($workUnitType.contract_validator_path, $workUnitType.receipt_creator_path, $workUnitType.receipt_validator_path)) {
            if (Test-IsUnsafeRelativePath $rulePath) {
                Fail 'WORK_UNIT_RULE_INVALID' 'work_unit_types contains an unsafe script path.'
            }
        }
    }

    foreach ($registryPath in @($index.dependency_registry_paths)) {
        Assert-ExplicitRegistryPath $workspacePath $registryPath
    }

    Write-Output 'CORE_CONTRACT_VALID: version=1.0.0; dimensions=15; dependencies=0'
}
catch {
    if ($_.Exception.Message -match '^CORE_CONTRACT_VALIDATION_FAILURE:') {
        Write-Error $_.Exception.Message
        exit 1
    }
    Write-Error 'CORE_CONTRACT_VALIDATION_FAILURE: UNEXPECTED_ERROR; Validation could not complete.'
    exit 1
}

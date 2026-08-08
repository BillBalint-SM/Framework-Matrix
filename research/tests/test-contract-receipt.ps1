[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "TEST_FAILURE: $Message" }
}

function Assert-Rejected([object]$Result, [string]$Code, [string]$Message) {
    Assert-True ($Result.code -ne 0) $Message
    Assert-True ((@($Result.output) -join ' ') -match "CONTRACT_RECEIPT_FAILURE: $Code") $Message
}

function Assert-OutputExcludes([object]$Result, [string]$SensitiveValue, [string]$Message) {
    Assert-True ((@($Result.output) -join ' ') -notmatch [regex]::Escape($SensitiveValue)) $Message
}

function ConvertTo-PowerShellLiteral([string]$Value) {
    return "'$($Value.Replace("'", "''"))'"
}

function New-CreatorCommand(
    [string]$WorkspacePath,
    [string]$WorkUnitId,
    [string]$WorkUnitType,
    [string[]]$DimensionIds,
    [string[]]$ExpectedEvidence,
    [string]$ReceiptPath
) {
    $dimensionLiteral = '@(' + (($DimensionIds | ForEach-Object { ConvertTo-PowerShellLiteral $_ }) -join ',') + ')'
    $evidenceLiteral = '@(' + (($ExpectedEvidence | ForEach-Object { ConvertTo-PowerShellLiteral $_ }) -join ',') + ')'
    return '& ' + (ConvertTo-PowerShellLiteral $creator) +
        ' -WorkspaceRoot ' + (ConvertTo-PowerShellLiteral $WorkspacePath) +
        ' -WorkUnitId ' + (ConvertTo-PowerShellLiteral $WorkUnitId) +
        ' -WorkUnitType ' + (ConvertTo-PowerShellLiteral $WorkUnitType) +
        ' -DimensionIds ' + $dimensionLiteral +
        ' -ExpectedEvidence ' + $evidenceLiteral +
        ' -ReceiptPath ' + (ConvertTo-PowerShellLiteral $ReceiptPath)
}

function Invoke-Creator(
    [string]$WorkspacePath,
    [string]$WorkUnitId,
    [string]$WorkUnitType,
    [string[]]$DimensionIds,
    [string[]]$ExpectedEvidence,
    [string]$ReceiptPath
) {
    $command = New-CreatorCommand $WorkspacePath $WorkUnitId $WorkUnitType $DimensionIds $ExpectedEvidence $ReceiptPath
    $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-Command', $command)
    $output = @(& $pwshPath @arguments 2>&1)
    return [pscustomobject]@{ code = $LASTEXITCODE; output = $output }
}

function Invoke-CreatorWithPublicationRace(
    [string]$WorkspacePath,
    [string]$WorkUnitId,
    [string]$WorkUnitType,
    [string[]]$DimensionIds,
    [string[]]$ExpectedEvidence,
    [string]$ReceiptPath,
    [byte[]]$OriginalBytes,
    [string]$FixtureDirectory
) {
    $command = New-CreatorCommand $WorkspacePath $WorkUnitId $WorkUnitType $DimensionIds $ExpectedEvidence $ReceiptPath
    $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))
    $driverPath = Join-Path $FixtureDirectory "publication-race-driver-$([guid]::NewGuid().ToString('N')).ps1"
    $stdoutPath = Join-Path $FixtureDirectory 'publication-race.stdout.txt'
    $stderrPath = Join-Path $FixtureDirectory 'publication-race.stderr.txt'
    $targetFullPath = Join-Path $WorkspacePath $ReceiptPath
    $originalBytesBase64 = [Convert]::ToBase64String($OriginalBytes)
    $driver = @'
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CreatorPath,
    [Parameter(Mandatory = $true)][string]$CreatorCommandBase64,
    [Parameter(Mandatory = $true)][string]$TargetFullPath,
    [Parameter(Mandatory = $true)][string]$OriginalBytesBase64
)

$ErrorActionPreference = 'Stop'
$breakpoint = $null
$failureStage = 'INITIALIZE'
try {
    $failureStage = 'MOVE_LINE_LOOKUP'
    $movePattern = '[System.IO.File]::Move($temporaryPath, $receiptFullPath, $false)'
    $moveMatches = @(Select-String -LiteralPath $CreatorPath -SimpleMatch $movePattern)
    if ($moveMatches.Count -ne 1) {
        throw 'MOVE_LINE_NOT_UNIQUE'
    }

    $global:ContractReceiptRaceTargetPath = $TargetFullPath
    $global:ContractReceiptRaceOriginalBytes = [Convert]::FromBase64String($OriginalBytesBase64)
    $failureStage = 'BREAKPOINT_REGISTRATION'
    $breakpoint = Set-PSBreakpoint -Script $CreatorPath -Line $moveMatches[0].LineNumber -Action {
        $stream = [System.IO.FileStream]::new(
            $global:ContractReceiptRaceTargetPath,
            [System.IO.FileMode]::CreateNew,
            [System.IO.FileAccess]::Write,
            [System.IO.FileShare]::None
        )
        try {
            $stream.Write(
                $global:ContractReceiptRaceOriginalBytes,
                0,
                $global:ContractReceiptRaceOriginalBytes.Length
            )
        }
        finally {
            $stream.Dispose()
        }
    }

    $commandText = [System.Text.Encoding]::Unicode.GetString(
        [Convert]::FromBase64String($CreatorCommandBase64)
    )
    $failureStage = 'CREATOR_INVOCATION'
    & ([scriptblock]::Create($commandText))
}
catch {
    if (
        $failureStage -ceq 'CREATOR_INVOCATION' -and
        $_.Exception.Message -match '^CONTRACT_RECEIPT_FAILURE: RECEIPT_EXISTS;'
    ) {
        [Console]::Error.WriteLine('CONTRACT_RECEIPT_FAILURE: RECEIPT_EXISTS; Receipt path already exists.')
        exit 1
    }
    $failureCode = if ($_.Exception.Message -ceq 'MOVE_LINE_NOT_UNIQUE') { 'MOVE_LINE_NOT_UNIQUE' } else { $failureStage }
    Write-Error "RACE_DRIVER_FAILURE: $failureCode"
    exit 97
}
finally {
    if ($null -ne $breakpoint) {
        Remove-PSBreakpoint -Breakpoint $breakpoint -ErrorAction SilentlyContinue
    }
    Remove-Variable -Name ContractReceiptRaceTargetPath -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name ContractReceiptRaceOriginalBytes -Scope Global -ErrorAction SilentlyContinue
}
'@ -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($driverPath, $driver, [System.Text.UTF8Encoding]::new($false))

    $process = $null
    try {
        $process = Start-Process -FilePath $pwshPath -ArgumentList @(
            '-NoLogo', '-NoProfile', '-NonInteractive', '-File', $driverPath,
            '-CreatorPath', $creator,
            '-CreatorCommandBase64', $encodedCommand,
            '-TargetFullPath', $targetFullPath,
            '-OriginalBytesBase64', $originalBytesBase64
        ) -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit(10000)) {
            $process.Kill($true)
            if (-not $process.WaitForExit(5000)) {
                throw 'TEST_FAILURE: Publication-race child did not stop within the bounded timeout.'
            }
            throw 'TEST_FAILURE: Publication-race child exceeded the bounded timeout.'
        }
        $output = @(
            @(Get-Content -LiteralPath $stdoutPath -ErrorAction SilentlyContinue)
            @(Get-Content -LiteralPath $stderrPath -ErrorAction SilentlyContinue)
        )
        return [pscustomobject]@{ code = $process.ExitCode; output = $output }
    }
    finally {
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                $process.Kill($true)
                if (-not $process.WaitForExit(5000)) {
                    throw 'TEST_FAILURE: Publication-race child cleanup exceeded the bounded timeout.'
                }
            }
            $process.Dispose()
        }
        foreach ($knownFixturePath in @($driverPath, $stdoutPath, $stderrPath)) {
            if (Test-Path -LiteralPath $knownFixturePath) {
                Remove-Item -LiteralPath $knownFixturePath -Force
            }
        }
    }
}

function Invoke-Validator([string]$WorkspacePath, [string]$ReceiptPath) {
    $arguments = @(
        '-NoLogo', '-NoProfile', '-NonInteractive', '-File', $validator,
        '-WorkspaceRoot', $WorkspacePath,
        '-ReceiptPath', $ReceiptPath
    )
    $output = @(& $pwshPath @arguments 2>&1)
    return [pscustomobject]@{ code = $LASTEXITCODE; output = $output }
}

function Write-Json([string]$Path, [object]$Value) {
    $content = $Value | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText(
        $Path,
        $content,
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Remove-TemporaryReceiptDirectory([string]$ReceiptsRoot, [string]$TemporaryPath) {
    $resolvedReceiptsRoot = [System.IO.Path]::GetFullPath($ReceiptsRoot)
    $resolvedTemporaryPath = [System.IO.Path]::GetFullPath($TemporaryPath)
    $allowedPrefix = "$resolvedReceiptsRoot$([System.IO.Path]::DirectorySeparatorChar)test-receipt-"
    Assert-True ($resolvedTemporaryPath.StartsWith($allowedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) 'Cleanup target must be a GUID directory beneath registry/contract-receipts.'
    Assert-True (Test-Path -LiteralPath $resolvedTemporaryPath) 'Cleanup target must exist before removal.'
    Remove-Item -LiteralPath $resolvedTemporaryPath -Recurse -Force
}

$resolvedWorkspaceRoot = [System.IO.Path]::GetFullPath($WorkspaceRoot)
$creator = Join-Path $resolvedWorkspaceRoot 'research/scripts/new-contract-receipt.ps1'
$validator = Join-Path $resolvedWorkspaceRoot 'research/scripts/validate-contract-receipt.ps1'
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
$receiptsRoot = Join-Path $resolvedWorkspaceRoot 'registry/contract-receipts'
$temporaryDirectory = Join-Path $receiptsRoot "test-receipt-$([guid]::NewGuid())"
$successWorkUnitId = 'contract-receipt-integration'
$successPath = '.\registry\contract-receipts\test-receipt-placeholder\receipt.json'
$successCreateLine = 'CONTRACT_RECEIPT_CREATED: contract-receipt-integration; dimensions=15'
$successValidateLine = 'CONTRACT_RECEIPT_VALID: contract-receipt-integration; contract=1.0.0'
$passed = 0

New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null
$temporaryDirectoryName = Split-Path -Leaf $temporaryDirectory
$successPath = ".\registry\contract-receipts\$temporaryDirectoryName\receipt.json"
$dimensions = @(
    'CC-01', 'CC-02', 'CC-03', 'CC-04', 'CC-05',
    'CC-06', 'CC-07', 'CC-08', 'CC-09', 'CC-10',
    'CC-11', 'CC-12', 'CC-13', 'CC-14', 'CC-15'
)
$evidence = @('Task 2 focused integration verification')

try {
    $createResult = Invoke-Creator $resolvedWorkspaceRoot $successWorkUnitId 'task' $dimensions $evidence $successPath
    Assert-True ($createResult.code -eq 0) 'A valid task receipt must be created successfully.'
    Assert-True ((@($createResult.output)).Count -eq 1) 'The creator must emit exactly one success line.'
    Assert-True ($createResult.output[0] -ceq $successCreateLine) 'The creator must emit the exact success line.'
    Assert-True (([System.IO.File]::ReadAllText((Join-Path $resolvedWorkspaceRoot $successPath))) -notmatch "`r`n") 'A created receipt must use LF line endings for repository checks.'
    $passed++

    $validateResult = Invoke-Validator $resolvedWorkspaceRoot $successPath
    Assert-True ($validateResult.code -eq 0) 'A newly created task receipt must validate successfully.'
    Assert-True ((@($validateResult.output)).Count -eq 1) 'The validator must emit exactly one success line.'
    Assert-True ($validateResult.output[0] -ceq $successValidateLine) 'The validator must emit the exact success line.'
    $passed++

    Assert-Rejected (Invoke-Creator $resolvedWorkspaceRoot 'unknown-dimension' 'task' @('CC-16') $evidence "registry/contract-receipts/$temporaryDirectoryName/unknown.json") 'DIMENSION_UNKNOWN' 'CC-16 must be rejected.'
    $passed++

    Assert-Rejected (Invoke-Creator $resolvedWorkspaceRoot 'empty-dimension' 'task' @('') $evidence "registry/contract-receipts/$temporaryDirectoryName/empty.json") 'DIMENSION_REQUIRED' 'An explicit empty dimension must be rejected without a mandatory-parameter prompt.'
    $passed++

    Assert-Rejected (Invoke-Creator $resolvedWorkspaceRoot 'absolute-path' 'task' @('CC-01') $evidence (Join-Path $resolvedWorkspaceRoot 'registry/contract-receipts/absolute.json')) 'PATH_INVALID' 'An absolute receipt path must be rejected.'
    Assert-Rejected (Invoke-Creator $resolvedWorkspaceRoot 'traversal-path' 'task' @('CC-01') $evidence ".\registry\contract-receipts\$temporaryDirectoryName\..\traversal.json") 'PATH_INVALID' 'A traversal receipt path must be rejected.'
    Assert-Rejected (Invoke-Creator $resolvedWorkspaceRoot 'repeated-dot-prefix' 'task' @('CC-01') $evidence ".\.\registry\contract-receipts\$temporaryDirectoryName\repeated-dot-prefix.json") 'PATH_INVALID' 'A repeated same-form dot-relative creator prefix must be rejected.'
    Assert-Rejected (Invoke-Creator $resolvedWorkspaceRoot 'mixed-dot-prefix' 'task' @('CC-01') $evidence ".\./registry/contract-receipts/$temporaryDirectoryName/mixed-dot-prefix.json") 'PATH_INVALID' 'A repeated mixed dot-relative creator prefix must be rejected.'
    Assert-Rejected (Invoke-Validator $resolvedWorkspaceRoot "././registry/contract-receipts/$temporaryDirectoryName/receipt.json") 'PATH_INVALID' 'A repeated same-form dot-relative validator prefix must be rejected.'
    Assert-Rejected (Invoke-Validator $resolvedWorkspaceRoot "./.\registry\contract-receipts\$temporaryDirectoryName\receipt.json") 'PATH_INVALID' 'A repeated mixed dot-relative validator prefix must be rejected.'
    $passed++

    $originalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $resolvedWorkspaceRoot $successPath)).Hash
    Assert-Rejected (Invoke-Creator $resolvedWorkspaceRoot $successWorkUnitId 'task' $dimensions $evidence $successPath) 'RECEIPT_EXISTS' 'A second create at the same path must be rejected.'
    $currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $resolvedWorkspaceRoot $successPath)).Hash
    Assert-True ($currentHash -ceq $originalHash) 'A rejected overwrite must preserve the original receipt hash.'

    $racePath = "registry/contract-receipts/$temporaryDirectoryName/publication-race.json"
    $raceFullPath = Join-Path $resolvedWorkspaceRoot $racePath
    $raceOriginalBytes = [System.Text.Encoding]::UTF8.GetBytes('original publication-race target bytes')
    $raceResult = Invoke-CreatorWithPublicationRace $resolvedWorkspaceRoot 'publication-race' 'task' @('CC-01') $evidence $racePath $raceOriginalBytes $temporaryDirectory
    $raceResultOutput = @($raceResult.output) -join ' '
    Assert-Rejected $raceResult 'RECEIPT_EXISTS' "A destination created at the final publication boundary must be rejected deterministically. Child output: $raceResultOutput"
    $raceOriginalBase64 = [Convert]::ToBase64String($raceOriginalBytes)
    $raceCurrentBase64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($raceFullPath))
    Assert-True ($raceCurrentBase64 -ceq $raceOriginalBase64) 'A publication race must preserve the original target bytes.'
    $raceOriginalHash = [Convert]::ToHexString([System.Security.Cryptography.SHA256]::HashData($raceOriginalBytes)).ToLowerInvariant()
    $raceCurrentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $raceFullPath).Hash.ToLowerInvariant()
    Assert-True ($raceCurrentHash -ceq $raceOriginalHash) 'A publication race must preserve the original target hash.'
    $raceTemporaryFiles = @(Get-ChildItem -LiteralPath $temporaryDirectory -Filter 'publication-race.json.*.tmp' -File -Force)
    Assert-True ($raceTemporaryFiles.Count -eq 0) 'A rejected publication race must remove only its known temporary sibling.'
    $raceHarnessFiles = @(Get-ChildItem -LiteralPath $temporaryDirectory -File -Force | Where-Object {
        $_.Name -like 'publication-race-driver-*.ps1' -or
        $_.Name -in @('publication-race.stdout.txt', 'publication-race.stderr.txt')
    })
    Assert-True ($raceHarnessFiles.Count -eq 0) 'The publication-race harness must remove its driver and captured-output files immediately.'
    $passed++

    $stalePath = "./registry/contract-receipts/$temporaryDirectoryName/stale.json"
    $staleCreate = Invoke-Creator $resolvedWorkspaceRoot 'stale-contract-hash' 'task' @('CC-01') $evidence $stalePath
    Assert-True ($staleCreate.code -eq 0) 'A receipt fixture for stale hash validation must be created.'
    Assert-True ($staleCreate.output[0] -ceq 'CONTRACT_RECEIPT_CREATED: stale-contract-hash; dimensions=1') 'Creator success must report the actual work-unit ID and dimension count.'
    $staleFullPath = Join-Path $resolvedWorkspaceRoot $stalePath
    $staleReceipt = Get-Content -Raw -LiteralPath $staleFullPath | ConvertFrom-Json
    $staleReceipt.contract.sha256 = ('0' * 64)
    Write-Json $staleFullPath $staleReceipt
    Assert-Rejected (Invoke-Validator $resolvedWorkspaceRoot $stalePath) 'CONTRACT_HASH_MISMATCH' 'A receipt with a stale contract hash must be rejected.'
    $passed++

    $extraPath = "registry/contract-receipts/$temporaryDirectoryName/extra.json"
    $extraCreate = Invoke-Creator $resolvedWorkspaceRoot 'extra-property' 'task' @('CC-01') $evidence $extraPath
    Assert-True ($extraCreate.code -eq 0) 'A receipt fixture for schema validation must be created.'
    $extraFullPath = Join-Path $resolvedWorkspaceRoot $extraPath
    $extraReceipt = Get-Content -Raw -LiteralPath $extraFullPath | ConvertFrom-Json
    $extraReceipt | Add-Member -NotePropertyName 'unexpected_root_property' -NotePropertyValue 'unexpected'
    Write-Json $extraFullPath $extraReceipt
    Assert-Rejected (Invoke-Validator $resolvedWorkspaceRoot $extraPath) 'RECEIPT_SCHEMA_INVALID' 'A receipt with an extra property must be rejected.'
    $passed++

    $junctionTarget = Join-Path $temporaryDirectory 'junction-target'
    $junctionPath = Join-Path $temporaryDirectory 'junction-parent'
    New-Item -ItemType Directory -Path $junctionTarget -Force | Out-Null
    New-Item -ItemType Junction -Path $junctionPath -Target $junctionTarget | Out-Null
    $junctionReceiptPath = "registry/contract-receipts/$temporaryDirectoryName/junction-parent/receipt.json"
    $junctionCreateResult = Invoke-Creator $resolvedWorkspaceRoot 'junction-create' 'task' @('CC-01') $evidence $junctionReceiptPath
    Assert-Rejected $junctionCreateResult 'PATH_REPARSE_POINT' 'A receipt parent reached through a junction must be rejected.'
    Assert-OutputExcludes $junctionCreateResult $temporaryDirectoryName 'Creator reparse errors must not disclose untrusted receipt path segments.'
    $junctionTargetReceipt = Join-Path $junctionTarget 'receipt.json'
    [System.IO.File]::Copy((Join-Path $resolvedWorkspaceRoot $successPath), $junctionTargetReceipt)
    $junctionValidateResult = Invoke-Validator $resolvedWorkspaceRoot $junctionReceiptPath
    Assert-Rejected $junctionValidateResult 'PATH_REPARSE_POINT' 'A receipt reached through a junction must be rejected.'
    Assert-OutputExcludes $junctionValidateResult $temporaryDirectoryName 'Validator reparse errors must not disclose untrusted receipt path segments.'
    Remove-Item -LiteralPath $junctionPath -Force
    Assert-True (Test-Path -LiteralPath $junctionTarget) 'Removing a junction must not remove its target.'
    $passed++
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-TemporaryReceiptDirectory $receiptsRoot $temporaryDirectory
    }
}

Write-Output "CONTRACT_RECEIPT_TESTS: $passed/9 PASS"

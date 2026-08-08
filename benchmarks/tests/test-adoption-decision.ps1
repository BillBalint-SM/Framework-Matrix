param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$adoptionsRoot = Join-Path $campaignRoot 'adoptions'
$resolutionRoot = Join-Path $campaignRoot 'resolution-v2'
$recordPath = Join-Path $adoptionsRoot 'abk-native-v2.json'
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\adoption-decision-v1.schema.json'
$validator = Join-Path $workspaceFull 'benchmarks\scripts\validate-adoption-decision.ps1'
$token = [guid]::NewGuid().ToString('N')
$temporaryRoot = Join-Path $adoptionsRoot "test-adoption-$token"
$scorecardLinkPath = Join-Path $temporaryRoot 'scorecard-link'
$recordTargetRoot = Join-Path $temporaryRoot 'record-target'
$recordLinkPath = Join-Path $temporaryRoot 'record-link'
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "TEST_FAILURE: $Message" }
}

function Invoke-Validator([string]$RecordPath) {
    $arguments = @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $validator, '-WorkspaceRoot', $workspaceFull, '-RecordPath', $RecordPath)
    $output = @(& $pwshPath @arguments 2>&1)
    return [pscustomobject]@{ code = $LASTEXITCODE; output = $output }
}

function Assert-Rejected([object]$Result, [string]$Code, [string]$Message) {
    Assert-True ($Result.code -ne 0) $Message
    Assert-True ((@($Result.output) -join ' ') -match "ADOPTION_VALIDATION_FAILURE: $Code") $Message
}

function New-MutatedRecord([string]$Name, [scriptblock]$Mutation) {
    $path = Join-Path $temporaryRoot $Name
    $document = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
    & $Mutation $document
    $document | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $path -Encoding utf8NoBOM
    return $path
}

try {
    Assert-True (Test-Json -LiteralPath $recordPath -SchemaFile $schemaPath) 'approved adoption record is not schema-valid'
    $positive = Invoke-Validator $recordPath
    Assert-True ($positive.code -eq 0 -and ((@($positive.output) -join ' ') -match 'ADOPTION_DECISION_VALID')) 'positive adoption decision validation failed'

    New-Item -ItemType Directory -Path $temporaryRoot -Force | Out-Null

    $badHashPath = New-MutatedRecord 'bad-hash.json' {
        param($document)
        $document.basis.scorecard_sha256 = [string]::new([char]'0', 64)
    }
    Assert-Rejected (Invoke-Validator $badHashPath) 'SCORECARD_HASH_MISMATCH' 'changed scorecard hash was accepted'

    $badBranchPath = New-MutatedRecord 'bad-branch.json' {
        param($document)
        $document.selected_branch = 'control'
    }
    Assert-Rejected (Invoke-Validator $badBranchPath) 'SELECTED_BRANCH_INELIGIBLE' 'non-eligible branch was accepted'

    $badApprovalPath = New-MutatedRecord 'bad-approval.json' {
        param($document)
        $document.approval.kind = 'automated'
    }
    Assert-Rejected (Invoke-Validator $badApprovalPath) 'RECORD_SCHEMA_INVALID' 'non-human approval was accepted'

    $badPathPath = New-MutatedRecord 'bad-path.json' {
        param($document)
        $document.basis.scorecard_relative_path = '../README.md'
    }
    Assert-Rejected (Invoke-Validator $badPathPath) 'PATH_INVALID' 'workspace-escaping scorecard path was accepted'

    New-Item -ItemType Junction -Path $scorecardLinkPath -Target $resolutionRoot | Out-Null
    $reparseScorecardRecordPath = New-MutatedRecord 'reparse-scorecard.json' {
        param($document)
        $linkedScorecardPath = Join-Path $scorecardLinkPath 'comparison-scorecard.json'
        $document.basis.scorecard_relative_path = ([IO.Path]::GetRelativePath($workspaceFull, $linkedScorecardPath)).Replace('\', '/')
    }
    Assert-Rejected (Invoke-Validator $reparseScorecardRecordPath) 'PATH_REPARSE_POINT' 'reparse-point scorecard path was accepted'

    New-Item -ItemType Directory -Path $recordTargetRoot -Force | Out-Null
    Copy-Item -LiteralPath $recordPath -Destination (Join-Path $recordTargetRoot 'abk-native-v2.json')
    New-Item -ItemType Junction -Path $recordLinkPath -Target $recordTargetRoot | Out-Null
    Assert-Rejected (Invoke-Validator (Join-Path $recordLinkPath 'abk-native-v2.json')) 'PATH_REPARSE_POINT' 'reparse-point record path was accepted'

    Write-Output 'ADOPTION_DECISION_TESTS: 7/7 PASS'
    $global:LASTEXITCODE = 0
} finally {
    foreach ($linkPath in @($scorecardLinkPath, $recordLinkPath)) {
        if (Test-Path -LiteralPath $linkPath -PathType Container) { [IO.Directory]::Delete($linkPath, $false) }
    }
    if (-not (Test-Path -LiteralPath $resolutionRoot -PathType Container)) { throw 'TEST_CLEANUP_TARGET_MISSING: scorecard junction target was removed' }
    $temporaryRootFull = [IO.Path]::GetFullPath($temporaryRoot)
    $adoptionsRootFull = [IO.Path]::GetFullPath($adoptionsRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    if (-not $temporaryRootFull.StartsWith($adoptionsRootFull + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "TEST_CLEANUP_PATH_INVALID: $temporaryRootFull" }
    if (Test-Path -LiteralPath $temporaryRoot -PathType Container) { [IO.Directory]::Delete($temporaryRootFull, $true) }
}

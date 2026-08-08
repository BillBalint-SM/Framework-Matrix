[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'

function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "TEST_FAILURE: $Message" }
}

$workspacePath = [System.IO.Path]::TrimEndingDirectorySeparator(
    [System.IO.Path]::GetFullPath($WorkspaceRoot)
)
$agentsPath = Join-Path $workspacePath 'AGENTS.md'
$creatorPath = Join-Path $workspacePath 'research/scripts/new-contract-receipt.ps1'
$receiptValidatorPath = Join-Path $workspacePath 'research/scripts/validate-contract-receipt.ps1'
$receiptId = "agent-core-contract-gate-$([guid]::NewGuid().ToString('N'))"
$receiptPath = "registry/contract-receipts/$receiptId.json"
$receiptFullPath = Join-Path $workspacePath $receiptPath
$receiptCreatedByThisInvocation = $false
$passed = 0

try {
    Assert-True (Test-Path -LiteralPath $agentsPath -PathType Leaf) 'Root AGENTS.md is required.'
    $passed++

    $agentsContent = Get-Content -Raw -LiteralPath $agentsPath
    $normalizedAgentsContent = $agentsContent.Replace("`r`n", "`n")
    Assert-True (
        $normalizedAgentsContent.Contains('contracts/CORE-CONTRACT.md') -and
        $normalizedAgentsContent -match '(?s)& \.\\research\\scripts\\validate-core-contract\.ps1\s+`\s*\n\s*-WorkspaceRoot \(Get-Location\)\.Path\s+`\s*\n\s*-IndexPath \.\\contracts\\core-contract-index\.json'
    ) 'Root AGENTS.md must use the canonical contract path and exact validator command.'
    $passed++

    Assert-True (
        $normalizedAgentsContent -match '\$workUnitId\s*=\s*"work-unit-\$\(\[guid\]::NewGuid\(\)\.ToString\(''N''\)\.ToLowerInvariant\(\)\)"' -and
        $normalizedAgentsContent -match '\$workUnitType\s*=\s*''(session|task|work_part)''' -and
        $normalizedAgentsContent -match '\$dimensionIds\s*=\s*@\(' -and
        $normalizedAgentsContent -match '\$expectedEvidence\s*=\s*@\(' -and
        $normalizedAgentsContent -match '\$receiptPath\s*=\s*"\.\\registry\\contract-receipts\\\$workUnitId\.json"' -and
        $normalizedAgentsContent -match '(?s)& \.\\research\\scripts\\new-contract-receipt\.ps1\s+`\s*\n\s*-WorkspaceRoot \(Get-Location\)\.Path\s+`\s*\n\s*-WorkUnitId \$workUnitId\s+`\s*\n\s*-WorkUnitType \$workUnitType\s+`\s*\n\s*-DimensionIds \$dimensionIds\s+`\s*\n\s*-ExpectedEvidence \$expectedEvidence\s+`\s*\n\s*-ReceiptPath \$receiptPath\s*\n& \.\\research\\scripts\\validate-contract-receipt\.ps1\s+`\s*\n\s*-WorkspaceRoot \(Get-Location\)\.Path\s+`\s*\n\s*-ReceiptPath \$receiptPath' -and
        -not $normalizedAgentsContent.Contains('-WorkUnitId framework-matrix-core-contract-foundation')
    ) 'Root AGENTS.md must document a unique lowercase work-unit receipt procedure with exact creator and dynamic validator parameters.'
    $passed++

    Assert-True (
        $normalizedAgentsContent -match '(?s)& \.\\research\\scripts\\validate-contract-receipt\.ps1\s+`\s*\n\s*-WorkspaceRoot \(Get-Location\)\.Path\s+`\s*\n\s*-ReceiptPath \.\\registry\\contract-receipts\\core-contract-foundation\.json' -and
        ([regex]::Matches($normalizedAgentsContent, [regex]::Escape('.\registry\contract-receipts\core-contract-foundation.json'))).Count -eq 1
    ) 'Root AGENTS.md must present the durable foundation receipt only in its exact validator command.'
    $passed++

    Assert-True (
        $agentsContent.Contains('Step 0') -and
        $agentsContent -match 'Stop before the task if validation fails'
    ) 'Root AGENTS.md must identify Step 0 and stop work when validation fails.'
    $passed++

    Assert-True ($agentsContent -match 'Inspect every research-dependency registry') 'Root AGENTS.md must require dependency-registry inspection.'
    $passed++

    Assert-True ($agentsContent -match 'do not copy or reinterpret its descriptions') 'Root AGENTS.md must prohibit copied or reinterpreted dimension descriptions.'
    $passed++

    Assert-True (
        -not $agentsContent.Contains('Funkció és felhasználói cél') -and
        -not $agentsContent.Contains('Dokumentáció–kód–config–teszt konzisztencia')
    ) 'Root AGENTS.md must not copy core-contract dimension descriptions.'
    $passed++

    Assert-True (-not (Test-Path -LiteralPath $receiptFullPath)) 'The GUID receipt path must not exist before this test creates it.'

    & $creatorPath `
        -WorkspaceRoot $workspacePath `
        -WorkUnitId $receiptId `
        -WorkUnitType task `
        -DimensionIds @('CC-01') `
        -ExpectedEvidence @('agent-gate-tests') `
        -ReceiptPath $receiptPath
    $creatorSucceeded = $?
    Assert-True $creatorSucceeded 'The agent-gate receipt must be created successfully.'
    $receiptCreatedByThisInvocation = $true

    & $receiptValidatorPath `
        -WorkspaceRoot $workspacePath `
        -ReceiptPath $receiptPath
    $receiptValidatorSucceeded = $?
    Assert-True $receiptValidatorSucceeded 'The agent-gate receipt must validate successfully.'

    Write-Output "AGENT_CORE_CONTRACT_GATE_TESTS: $passed/8 PASS"
}
finally {
    if ($receiptCreatedByThisInvocation -and (Test-Path -LiteralPath $receiptFullPath -PathType Leaf)) {
        Remove-Item -LiteralPath $receiptFullPath -Force
    }
}

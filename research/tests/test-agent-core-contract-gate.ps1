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
$passed = 0

try {
    Assert-True (Test-Path -LiteralPath $agentsPath -PathType Leaf) 'Root AGENTS.md is required.'
    $passed++

    $agentsContent = Get-Content -Raw -LiteralPath $agentsPath
    $normalizedAgentsContent = $agentsContent.Replace('\', '/')
    Assert-True (
        $normalizedAgentsContent.Contains('contracts/CORE-CONTRACT.md') -and
        $normalizedAgentsContent.Contains('contracts/core-contract-index.json')
    ) 'Root AGENTS.md must use the canonical contract and index paths.'
    $passed++

    Assert-True (
        $normalizedAgentsContent.Contains('research/scripts/validate-core-contract.ps1') -and
        $normalizedAgentsContent.Contains('research/scripts/new-contract-receipt.ps1') -and
        $normalizedAgentsContent.Contains('research/scripts/validate-contract-receipt.ps1')
    ) 'Root AGENTS.md must name all three core-contract scripts.'
    $passed++

    Assert-True ($agentsContent.Contains('Step 0')) 'Root AGENTS.md must identify the core-contract gate as Step 0.'
    $passed++

    Assert-True ($agentsContent -match 'Stop before the task if validation fails') 'Root AGENTS.md must stop work when validation fails.'
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

    & $creatorPath `
        -WorkspaceRoot $workspacePath `
        -WorkUnitId $receiptId `
        -WorkUnitType task `
        -DimensionIds @('CC-01') `
        -ExpectedEvidence @('agent-gate-tests') `
        -ReceiptPath $receiptPath
    $creatorSucceeded = $?
    Assert-True $creatorSucceeded 'The agent-gate receipt must be created successfully.'

    & $receiptValidatorPath `
        -WorkspaceRoot $workspacePath `
        -ReceiptPath $receiptPath
    $receiptValidatorSucceeded = $?
    Assert-True $receiptValidatorSucceeded 'The agent-gate receipt must validate successfully.'

    Write-Output "AGENT_CORE_CONTRACT_GATE_TESTS: $passed/8 PASS"
}
finally {
    if (Test-Path -LiteralPath $receiptFullPath -PathType Leaf) {
        Remove-Item -LiteralPath $receiptFullPath -Force
    }
}

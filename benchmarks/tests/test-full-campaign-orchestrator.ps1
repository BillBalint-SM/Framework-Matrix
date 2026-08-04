param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$scriptPath = Join-Path $workspaceFull 'benchmarks\scripts\run-full-campaign.ps1'
$runsRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\runs'
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
$token = [guid]::NewGuid().ToString('N')
$validationRoot = Join-Path $runsRoot ("test-full-orchestrator-validation-$token")
$existingRoot = Join-Path $runsRoot ("test-full-orchestrator-existing-$token")
$outsideRoot = Join-Path $workspaceFull ("test-full-orchestrator-outside-$token")

if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw 'TEST_FAILURE: full campaign orchestrator is missing' }
try {
    $validationOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $scriptPath -WorkspaceRoot $workspaceFull -OutputRoot $validationRoot -ValidationOnly 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (@($validationOutput) -match 'FULL_CAMPAIGN_MATRIX_VALID: primary_cells=30; expected_raw_runs=66')) { throw 'TEST_FAILURE: validation-only matrix check did not pass' }
    if (Test-Path -LiteralPath $validationRoot) { throw 'TEST_FAILURE: validation-only mode created an output directory' }

    New-Item -ItemType Directory -Path $existingRoot -Force | Out-Null
    $existingOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $scriptPath -WorkspaceRoot $workspaceFull -OutputRoot $existingRoot 2>&1
    if ($LASTEXITCODE -eq 0 -or -not (@($existingOutput) -match 'OUTPUT_ROOT_EXISTS')) { throw 'TEST_FAILURE: existing output root was not rejected' }

    $outsideOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $scriptPath -WorkspaceRoot $workspaceFull -OutputRoot $outsideRoot -ValidationOnly 2>&1
    if ($LASTEXITCODE -eq 0 -or -not (@($outsideOutput) -match 'OUTPUT_ROOT_ESCAPE')) { throw 'TEST_FAILURE: output root escape was not rejected' }
    Write-Output 'FULL_CAMPAIGN_ORCHESTRATOR_TESTS: 3/3 PASS'
} finally {
    foreach ($path in @($validationRoot, $existingRoot, $outsideRoot)) {
        if (Test-Path -LiteralPath $path -PathType Container) { [IO.Directory]::Delete([IO.Path]::GetFullPath($path), $true) }
    }
}

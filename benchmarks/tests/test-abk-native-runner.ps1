param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$pilotScript = Join-Path $workspaceFull 'benchmarks\scripts\run-abk-native-bounded.ps1'
$runSchema = Join-Path $workspaceFull 'benchmarks\schemas\abk-native-run.schema.json'
$testRoot = Join-Path $campaignRoot ('runs\test-abk-native-' + [guid]::NewGuid().ToString('N'))
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $pilotScript -PathType Leaf) -or -not (Test-Path -LiteralPath $runSchema -PathType Leaf)) { throw 'TEST_FAILURE: ABK-native runner and run schema must exist' }
try {
    & $pwshPath -NoLogo -NoProfile -NonInteractive -File $pilotScript -WorkspaceRoot $workspaceFull -OutputRoot $testRoot 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "TEST_FAILURE: bounded ABK-native runner harness exited with $LASTEXITCODE" }
    $runFiles = @(Get-ChildItem -LiteralPath $testRoot -Filter 'run.json' -Recurse -File)
    if ($runFiles.Count -ne 10) { throw "TEST_FAILURE: expected 10 ABK-native run records, got $($runFiles.Count)" }
    $expected = @{
        'COM-01-normal-primary' = @('SUCCEEDED', 0, $null)
        'COM-05-invalid-input' = @('FAILED', 3, 'UNKNOWN_ARTIFACT_REFERENCE')
        'COM-06-stop-interrupt' = @('STOPPED', 130, 'INTERRUPTED')
        'SPC-01-domain-boundary' = @('REJECTED', 2, 'DEPENDENCY_OUT_OF_ROOT')
        'SPC-03-recovery-rollback' = @('RECOVERED', 0, 'RECOVERED_AFTER_FAILURE')
        'SPC-04-composition-handoff' = @('SUCCEEDED', 0, $null)
    }
    foreach ($runFile in $runFiles) {
        if (-not (Test-Json -LiteralPath $runFile.FullName -SchemaFile $runSchema)) { throw "TEST_FAILURE: run schema rejected '$($runFile.FullName)'" }
        $run = Get-Content -Raw -LiteralPath $runFile.FullName | ConvertFrom-Json
        if ($run.branch -ne 'abk_native' -or $run.runner.contract_version -ne 'abk-native-runner-v2') { throw "TEST_FAILURE: ABK-native runner contract mismatch for $($run.case_id)" }
        $provenance = Get-Content -Raw -LiteralPath (Join-Path $runFile.DirectoryName 'provenance.json') | ConvertFrom-Json
        if ($provenance.external_project_read -ne $false -or $provenance.git_linked_into_framework_matrix -ne $false -or [string]::IsNullOrWhiteSpace([string]$provenance.snapshot_revision)) { throw "TEST_FAILURE: snapshot-bound provenance invalid for $($run.case_id)" }
        if ($expected.ContainsKey($run.case_id)) {
            $expectation = $expected[$run.case_id]
            if ($run.terminal_state -ne $expectation[0] -or $run.exit_code -ne $expectation[1]) { throw "TEST_FAILURE: terminal contract mismatch for $($run.case_id)" }
            $actualError = if ($null -ne $run.error) { $run.error.code } else { $null }
            if ($actualError -ne $expectation[2]) { throw "TEST_FAILURE: typed error mismatch for $($run.case_id): $actualError" }
            if ($run.case_id -eq 'SPC-03-recovery-rollback' -and $run.recovery.removed -ne $true) { throw 'TEST_FAILURE: recovery evidence missing' }
            if ($run.case_id -eq 'SPC-04-composition-handoff' -and $run.handoff.verified -ne $true) { throw 'TEST_FAILURE: handoff evidence missing' }
        }
    }
    Write-Output 'ABK_NATIVE_RUNNER_TESTS: 10/10 PASS'
} finally {
    if (Test-Path -LiteralPath $testRoot) { [IO.Directory]::Delete($testRoot, $true) }
}

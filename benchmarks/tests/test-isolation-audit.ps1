param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\isolation-audit.schema.json'
$manifestPath = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\branches\control\manifest.json'
$auditScriptPath = Join-Path $workspaceFull 'benchmarks\scripts\run-control-isolation-audit.ps1'

if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $manifestPath -PathType Leaf) -or -not (Test-Path -LiteralPath $auditScriptPath -PathType Leaf)) {
    throw 'TEST_FAILURE: isolation-audit schema and harness must exist'
}

function Test-AuditSchema([string]$Path) {
    try { return [bool](Test-Json -LiteralPath $Path -SchemaFile $schemaPath) } catch { return $false }
}

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('framework-matrix-isolation-audit-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
$auditPath = Join-Path $tempRoot 'audit.json'
try {
    & $auditScriptPath -ManifestPath $manifestPath -WorkspaceRoot $workspaceFull -AuditId 'abk:isolation-audit:test-control-artifact-dag-core-v1' -OutputPath $auditPath | Out-Null
    if (-not (Test-Path -LiteralPath $auditPath -PathType Leaf)) { throw 'TEST_FAILURE: isolation audit did not emit its JSON record' }
    if (-not (Test-AuditSchema $auditPath)) { throw 'TEST_FAILURE: isolation audit record does not satisfy isolation-audit.schema.json' }

    $audit = Get-Content -Raw -LiteralPath $auditPath | ConvertFrom-Json
    if ($audit.status -ne 'INCONCLUSIVE') { throw "TEST_FAILURE: audit status must be INCONCLUSIVE without OS network-denial proof, got $($audit.status)" }
    if (-not $audit.environment.sanitized -or $audit.environment.credential_values_inherited -or $audit.environment.real_config_inherited) {
        throw 'TEST_FAILURE: audit did not prove sanitized environment and no inherited credentials/configuration'
    }
    if ($audit.process.child_processes_observed -ne 0) { throw 'TEST_FAILURE: audit observed an undeclared child process' }
    if (-not $audit.scope.repository_unchanged -or -not $audit.scope.git_unchanged -or -not $audit.scope.owner_run_only) {
        throw 'TEST_FAILURE: audit did not prove repository, Git, and owner-run boundaries'
    }

    $insideWorkspace = Join-Path $workspaceFull 'benchmarks\isolation-audit-test.json'
    $caught = $null
    try {
        & $auditScriptPath -ManifestPath $manifestPath -WorkspaceRoot $workspaceFull -AuditId 'abk:isolation-audit:test-output-escape' -OutputPath $insideWorkspace | Out-Null
    } catch { $caught = $_.Exception.Message.Split(':')[0] }
    if ($caught -ne 'OUTPUT_PATH_IN_WORKSPACE') { throw "TEST_FAILURE: workspace output escape expected OUTPUT_PATH_IN_WORKSPACE but got $caught" }
    if (Test-Path -LiteralPath $insideWorkspace) { throw 'TEST_FAILURE: rejected audit output path was created' }

    Write-Output 'ISOLATION_AUDIT_TESTS: 2/2 PASS'
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\network-policy-audit.schema.json'
$auditScriptPath = Join-Path $workspaceFull 'benchmarks\scripts\run-network-policy-audit.ps1'

if (-not (Test-Path -LiteralPath $schemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $auditScriptPath -PathType Leaf)) {
    throw 'TEST_FAILURE: network-policy audit schema and harness must exist'
}

function Test-AuditSchema([string]$Path) {
    try { return [bool](Test-Json -LiteralPath $Path -SchemaFile $schemaPath) } catch { return $false }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('framework-matrix-network-policy-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
$auditPath = Join-Path $tempRoot 'audit.json'
try {
    & $auditScriptPath -WorkspaceRoot $workspaceFull -AuditId 'abk:network-policy-audit:test-control-artifact-dag-core-v1' -OutputPath $auditPath | Out-Null
    $exitCode = $LASTEXITCODE
    if (-not (Test-Path -LiteralPath $auditPath -PathType Leaf)) { throw 'TEST_FAILURE: network-policy audit did not emit its JSON record' }
    if (-not (Test-AuditSchema $auditPath)) { throw 'TEST_FAILURE: network-policy audit record is not schema-valid' }
    $audit = Get-Content -Raw -LiteralPath $auditPath | ConvertFrom-Json
    if ($isAdmin) {
        if ($exitCode -ne 0 -or $audit.status -ne 'PASS') { throw "TEST_FAILURE: elevated policy audit must PASS/0, got $($audit.status)/$exitCode" }
    } else {
        if ($exitCode -ne 75 -or $audit.status -ne 'BLOCKED' -or $audit.error_code -ne 'FIREWALL_ADMIN_REQUIRED') {
            throw "TEST_FAILURE: non-admin policy audit must be BLOCKED/75/FIREWALL_ADMIN_REQUIRED, got $($audit.status)/$exitCode/$($audit.error_code)"
        }
    }
    if (-not $audit.rule.cleanup_verified) { throw 'TEST_FAILURE: firewall rule cleanup was not verified' }
    if (Get-NetFirewallRule -DisplayName $audit.rule.display_name -ErrorAction SilentlyContinue) { throw 'TEST_FAILURE: temporary firewall rule remains after audit' }

    $insideWorkspace = Join-Path $workspaceFull 'benchmarks\network-policy-audit-test.json'
    $caught = $null
    try { & $auditScriptPath -WorkspaceRoot $workspaceFull -AuditId 'abk:network-policy-audit:test-output-escape' -OutputPath $insideWorkspace | Out-Null } catch { $caught = $_.Exception.Message.Split(':')[0] }
    if ($caught -ne 'OUTPUT_PATH_IN_WORKSPACE') { throw "TEST_FAILURE: workspace output escape expected OUTPUT_PATH_IN_WORKSPACE but got $caught" }
    if (Test-Path -LiteralPath $insideWorkspace) { throw 'TEST_FAILURE: rejected policy audit output path was created' }

    Write-Output 'NETWORK_POLICY_AUDIT_TESTS: 2/2 PASS'
} finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)]
    [string]$AuditId,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Code, [string]$Message) {
    throw ('{0}: {1}' -f $Code, $Message)
}

function Add-Finding([System.Collections.Generic.List[object]]$Findings, [string]$Check, [string]$Status, [string]$Detail) {
    $Findings.Add([ordered]@{ check = $Check; status = $Status; detail = $Detail })
}

$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
$outputFull = [IO.Path]::GetFullPath($OutputPath)
$workspacePrefix = $workspaceFull + [IO.Path]::DirectorySeparatorChar
if ($outputFull.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase) -or $outputFull -eq $workspaceFull) {
    Fail 'OUTPUT_PATH_IN_WORKSPACE' 'Network-policy audit evidence must be written outside the repository workspace.'
}
if (Test-Path -LiteralPath $outputFull) { Fail 'OUTPUT_EXISTS' 'Network-policy audit evidence path already exists.' }
if ($AuditId -notmatch '^abk:network-policy-audit:[a-z][a-z0-9-]*$') { Fail 'AUDIT_ID_INVALID' 'Audit ID is not a safe concrete reference.' }

$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\network-policy-audit.schema.json'
$isolationAuditPath = Join-Path $workspaceFull 'benchmarks\scripts\run-control-isolation-audit.ps1'
$startedAt = [DateTime]::UtcNow
$ruleName = 'Framework-Matrix-Temp-Deny-' + [guid]::NewGuid().ToString('N')
$programPath = (Get-Command pwsh.exe -ErrorAction Stop).Source
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$status = 'BLOCKED'
$errorCode = $null
$created = $false
$removed = $false
$cleanupVerified = $false
$runnerProbeStatus = 'NOT_RUN'
$runnerProbeConnections = 0
$findings = [System.Collections.Generic.List[object]]::new()
$limitations = [System.Collections.Generic.List[string]]::new()
$probeOutput = Join-Path ([IO.Path]::GetTempPath()) ('framework-matrix-network-policy-probe-' + [guid]::NewGuid().ToString('N') + '.json')

try {
    if (-not $isAdmin) {
        $errorCode = 'FIREWALL_ADMIN_REQUIRED'
        Add-Finding $findings 'admin-privilege' 'BLOCKED' 'The current PowerShell session is not elevated; no firewall rule was created.'
        $limitations.Add('Run this audit from an elevated PowerShell session to exercise the temporary OS-level deny rule.')
    } else {
        if (-not (Test-Path -LiteralPath $isolationAuditPath -PathType Leaf)) { Fail 'ISOLATION_AUDIT_MISSING' 'The control isolation audit harness is missing.' }
        New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block -Program $programPath -Profile Any -Description 'Temporary Framework-Matrix isolation audit rule; remove after probe' -ErrorAction Stop | Out-Null
        $created = $true
        $rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
        if ($rule.Direction -ne 'Outbound' -or $rule.Action -ne 'Block' -or -not [bool]$rule.Enabled) { Fail 'FIREWALL_RULE_READBACK_FAILED' 'Temporary firewall rule read-back did not match the requested outbound block.' }
        Add-Finding $findings 'firewall-rule-readback' 'PASS' 'The exact temporary outbound block rule was read back before the runner probe.'

        & $isolationAuditPath -ManifestPath (Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1\branches\control\manifest.json') -WorkspaceRoot $workspaceFull -AuditId 'abk:isolation-audit:network-policy-probe' -OutputPath $probeOutput | Out-Null
        if ($LASTEXITCODE -ne 0) { Fail 'ISOLATION_AUDIT_FAILED' "Control isolation audit exited with code $LASTEXITCODE under the firewall rule." }
        $probe = Get-Content -Raw -LiteralPath $probeOutput | ConvertFrom-Json
        $runnerProbeConnections = [int]$probe.network.connections_observed
        if ($probe.scope.repository_unchanged -ne $true -or $probe.scope.git_unchanged -ne $true -or $probe.scope.owner_run_only -ne $true -or $runnerProbeConnections -ne 0) {
            Fail 'NETWORK_DENY_PROBE_FAILED' 'The runner probe did not preserve scope or observed a process socket under the deny rule.'
        }
        $runnerProbeStatus = 'PASS'
        Add-Finding $findings 'runner-network-probe' 'PASS' 'The sanitized control runner observed zero process sockets while the exact outbound block rule was active.'
        $status = 'PASS'
    }
} catch {
    $status = 'FAILED'
    if ($null -eq $errorCode) { $errorCode = $_.Exception.Message.Split(':')[0] }
    Add-Finding $findings 'network-policy-audit' 'FAILED' $_.Exception.Message
} finally {
    if ($created) {
        try {
            Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction Stop
            $removed = $true
        } catch {
            $status = 'FAILED'
            $errorCode = 'FIREWALL_CLEANUP_FAILED'
            Add-Finding $findings 'firewall-cleanup' 'FAILED' 'The temporary firewall rule could not be removed.'
        }
    }
    try {
        $remaining = @(Get-NetFirewallRule -ErrorAction Stop | Where-Object { $_.DisplayName -eq $ruleName })
        $cleanupVerified = $remaining.Count -eq 0
    } catch {
        $status = 'FAILED'
        $errorCode = 'FIREWALL_CLEANUP_READBACK_FAILED'
        Add-Finding $findings 'firewall-cleanup' 'FAILED' 'The temporary firewall rule cleanup could not be independently read back.'
    }
    if ($cleanupVerified) {
        Add-Finding $findings 'firewall-cleanup' 'PASS' 'No temporary firewall rule with the generated display name remains.'
    } elseif ($status -ne 'FAILED') {
        $status = 'FAILED'
        $errorCode = 'FIREWALL_CLEANUP_FAILED'
        Add-Finding $findings 'firewall-cleanup' 'FAILED' 'A temporary firewall rule remains after the audit.'
    }
    if (Test-Path -LiteralPath $probeOutput) { [IO.File]::Delete($probeOutput) }
}

$endedAt = [DateTime]::UtcNow
$record = [ordered]@{
    '$schema' = [IO.Path]::GetRelativePath((Split-Path -Parent $outputFull), $schemaPath).Replace('\', '/')
    schema_version = '1.0.0'
    audit_id = $AuditId
    campaign_id = 'abk:benchmark-campaign:artifact-dag-core-v1'
    host = 'codex'
    status = $status
    started_at = $startedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
    ended_at = $endedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
    is_admin = $isAdmin
    rule = [ordered]@{
        display_name = $ruleName
        program = $programPath
        direction = 'Outbound'
        action = 'Block'
        profile = 'Any'
        created = $created
        removed = $removed
        cleanup_verified = $cleanupVerified
    }
    runner_probe_status = $runnerProbeStatus
    runner_probe_connections_observed = $runnerProbeConnections
    error_code = $errorCode
    findings = @($findings)
    limitations = @($limitations)
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $outputFull) -PathType Container)) { New-Item -ItemType Directory -Path (Split-Path -Parent $outputFull) -Force | Out-Null }
$record | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $outputFull -Encoding utf8NoBOM
Write-Output ('NETWORK_POLICY_AUDIT_WRITTEN: {0}; status={1}; rule_created={2}; cleanup_verified={3}' -f $AuditId, $status, $created, $cleanupVerified)
if ($status -eq 'PASS') { exit 0 }
if ($status -eq 'BLOCKED') { exit 75 }
exit 3

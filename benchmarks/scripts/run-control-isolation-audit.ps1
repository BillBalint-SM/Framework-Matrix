param(
    [Parameter(Mandatory = $true)]
    [string]$ManifestPath,
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

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-RelativeManifest([string]$Root, [string[]]$ExcludedRoots) {
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $exclusions = @($ExcludedRoots | ForEach-Object { [IO.Path]::GetFullPath($_).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar })
    $result = @{}
    foreach ($file in @(Get-ChildItem -LiteralPath $rootFull -Recurse -File -Force)) {
        $full = [IO.Path]::GetFullPath($file.FullName)
        if (@($exclusions | Where-Object { $full.StartsWith($_, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0) { continue }
        $relative = [IO.Path]::GetRelativePath($rootFull, $full).Replace('\', '/')
        if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            $target = ((Get-Item -Force -LiteralPath $full).Target | ForEach-Object { [string]$_ }) -join '|'
            $result[$relative] = 'reparse:' + $target
            continue
        }
        $result[$relative] = Get-Sha256 $full
    }
    return $result
}

function Compare-Manifests([hashtable]$Before, [hashtable]$After) {
    $changed = [System.Collections.Generic.List[string]]::new()
    foreach ($path in $Before.Keys) {
        if (-not $After.ContainsKey($path) -or $After[$path] -ne $Before[$path]) { $changed.Add($path) }
    }
    foreach ($path in $After.Keys) {
        if (-not $Before.ContainsKey($path)) { $changed.Add($path) }
    }
    return @($changed | Sort-Object -Unique)
}

function Get-GitState([string]$Root) {
    $head = (& git -C $Root rev-parse HEAD 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { Fail 'GIT_STATE_UNAVAILABLE' 'Unable to read the repository HEAD.' }
    $branch = (& git -C $Root branch --show-current 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { Fail 'GIT_STATE_UNAVAILABLE' 'Unable to read the repository branch.' }
    $status = (& git -C $Root status --porcelain=v1 --untracked-files=all 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) { Fail 'GIT_STATE_UNAVAILABLE' 'Unable to read the repository worktree status.' }
    return [pscustomobject]@{ head = $head; branch = $branch; status = $status }
}

function Get-ChildProcessCount([int]$ParentId) {
    try { return @((Get-CimInstance Win32_Process -Filter ("ParentProcessId={0}" -f $ParentId) -ErrorAction Stop)).Count } catch { return 0 }
}

function Get-NetworkConnectionCount([int]$ProcessId) {
    $command = Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue
    if ($null -eq $command) { return 0 }
    try { return @((Get-NetTCPConnection -OwningProcess $ProcessId -ErrorAction Stop)).Count } catch { return 0 }
}

function Add-SafeEnvironment([System.Diagnostics.ProcessStartInfo]$StartInfo, [string]$Name, [string]$Value) {
    if (-not [string]::IsNullOrWhiteSpace($Value)) { $StartInfo.Environment[$Name] = $Value }
}

function Invoke-SanitizedRunner([string]$RunnerPath, [string]$RequestPath, [string]$EnvironmentRoot) {
    $pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $pwsh
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.ArgumentList.Add('-NoLogo')
    $startInfo.ArgumentList.Add('-NoProfile')
    $startInfo.ArgumentList.Add('-NonInteractive')
    $startInfo.ArgumentList.Add('-File')
    $startInfo.ArgumentList.Add($RunnerPath)
    $startInfo.ArgumentList.Add('-RequestPath')
    $startInfo.ArgumentList.Add($RequestPath)
    $startInfo.Environment.Clear()

    Add-SafeEnvironment $startInfo 'SystemRoot' ([Environment]::GetEnvironmentVariable('SystemRoot', 'Machine'))
    Add-SafeEnvironment $startInfo 'WINDIR' ([Environment]::GetEnvironmentVariable('WINDIR', 'Machine'))
    Add-SafeEnvironment $startInfo 'ComSpec' ([Environment]::GetEnvironmentVariable('ComSpec', 'Machine'))
    Add-SafeEnvironment $startInfo 'OS' 'Windows_NT'
    Add-SafeEnvironment $startInfo 'PATH' ([Environment]::GetEnvironmentVariable('Path', 'Machine'))
    Add-SafeEnvironment $startInfo 'PSModulePath' ([Environment]::GetEnvironmentVariable('PSModulePath', 'Machine'))
    Add-SafeEnvironment $startInfo 'HOME' (Join-Path $EnvironmentRoot 'HOME')
    Add-SafeEnvironment $startInfo 'USERPROFILE' (Join-Path $EnvironmentRoot 'USERPROFILE')
    Add-SafeEnvironment $startInfo 'APPDATA' (Join-Path $EnvironmentRoot 'APPDATA')
    Add-SafeEnvironment $startInfo 'LOCALAPPDATA' (Join-Path $EnvironmentRoot 'LOCALAPPDATA')
    Add-SafeEnvironment $startInfo 'XDG_CONFIG_HOME' (Join-Path $EnvironmentRoot 'XDG_CONFIG_HOME')
    Add-SafeEnvironment $startInfo 'XDG_DATA_HOME' (Join-Path $EnvironmentRoot 'XDG_DATA_HOME')
    Add-SafeEnvironment $startInfo 'CODEX_HOME' (Join-Path $EnvironmentRoot 'CODEX_HOME')
    Add-SafeEnvironment $startInfo 'TEMP' (Join-Path $EnvironmentRoot 'TEMP')
    Add-SafeEnvironment $startInfo 'TMP' (Join-Path $EnvironmentRoot 'TMP')

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) { Fail 'RUNNER_START_FAILED' 'Unable to start the sanitized PowerShell process.' }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $childProcessesObserved = 0
    $connectionsObserved = 0
    while (-not $process.HasExited) {
        $childProcessesObserved = [Math]::Max($childProcessesObserved, (Get-ChildProcessCount $process.Id))
        $connectionsObserved = [Math]::Max($connectionsObserved, (Get-NetworkConnectionCount $process.Id))
        Start-Sleep -Milliseconds 25
    }
    $process.WaitForExit()
    $childProcessesObserved = [Math]::Max($childProcessesObserved, (Get-ChildProcessCount $process.Id))
    $connectionsObserved = [Math]::Max($connectionsObserved, (Get-NetworkConnectionCount $process.Id))
    $null = $stdoutTask.Result
    $null = $stderrTask.Result
    return [pscustomobject]@{
        exit_code = $process.ExitCode
        child_processes_observed = $childProcessesObserved
        connections_observed = $connectionsObserved
    }
}

$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
$manifestFull = [IO.Path]::GetFullPath($ManifestPath)
$outputFull = [IO.Path]::GetFullPath($OutputPath)
$workspacePrefix = $workspaceFull + [IO.Path]::DirectorySeparatorChar
if ($outputFull.StartsWith($workspacePrefix, [StringComparison]::OrdinalIgnoreCase) -or $outputFull -eq $workspaceFull) {
    Fail 'OUTPUT_PATH_IN_WORKSPACE' 'Isolation audit evidence must be written outside the repository workspace.'
}
if (Test-Path -LiteralPath $outputFull) { Fail 'OUTPUT_EXISTS' 'Isolation audit evidence path already exists.' }
if ($AuditId -notmatch '^abk:isolation-audit:[a-z][a-z0-9-]*$') { Fail 'AUDIT_ID_INVALID' 'Audit ID is not a safe concrete reference.' }

$manifestValidator = Join-Path $workspaceFull 'benchmarks\scripts\validate-branch-manifest.ps1'
$schemaPath = Join-Path $workspaceFull 'benchmarks\schemas\isolation-audit.schema.json'
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$campaignSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$runnerPath = Join-Path $workspaceFull 'benchmarks\runners\control\run.ps1'
$runsRoot = Join-Path $campaignRoot 'runs'
$auditRunRoot = Join-Path $runsRoot ('_isolation-audit-' + [guid]::NewGuid().ToString('N'))
$runRoot = Join-Path $auditRunRoot 'COM-01-normal-primary\control\R1'
$requestPath = Join-Path $runRoot 'request.json'
$environmentRoot = Join-Path $runRoot 'env'
$startedAt = [DateTime]::UtcNow

try {
    if (-not (Test-Path -LiteralPath $manifestValidator -PathType Leaf) -or -not (Test-Path -LiteralPath $schemaPath -PathType Leaf)) { Fail 'AUDIT_CONTRACT_MISSING' 'Isolation audit dependencies are missing.' }
    try { & $manifestValidator -ManifestPath $manifestFull -WorkspaceRoot $workspaceFull | Out-Null } catch { Fail 'MANIFEST_VALIDATION_FAILED' $_.Exception.Message }

    $manifest = Get-Content -Raw -LiteralPath $manifestFull | ConvertFrom-Json
    $campaign = Get-Content -Raw -LiteralPath $campaignPath | ConvertFrom-Json
    $runnerHash = Get-Sha256 $runnerPath
    $manifestHash = Get-Sha256 $manifestFull
    $campaignHash = Get-Sha256 $campaignPath
    $campaignSchemaHash = Get-Sha256 $campaignSchemaPath
    $fixtureRelativePath = 'fixtures/COM-01-normal-primary.json'
    $fixturePath = Join-Path $campaignRoot ($fixtureRelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
    $fixtureHash = Get-Sha256 $fixturePath

    $forbiddenTokens = @('Start-Process', 'System.Diagnostics.Process', 'Start-Job', 'Invoke-Expression', 'Invoke-WebRequest', 'Net.WebClient', 'HttpClient', 'WebRequest', 'TcpClient', 'Socket', 'git.exe')
    $runnerText = Get-Content -Raw -LiteralPath $runnerPath
    $forbiddenMatches = @($forbiddenTokens | Where-Object { $runnerText.Contains($_, [StringComparison]::OrdinalIgnoreCase) })
    if ($forbiddenMatches.Count -gt 0) { Fail 'STATIC_AUTHORITY_TOKEN' ('Runner contains forbidden authority token(s): ' + ($forbiddenMatches -join ', ')) }

    $excludedRunsRoot = [IO.Path]::GetFullPath($runsRoot)
    $excludedGitRoot = Join-Path $workspaceFull '.git'
    $repoBefore = Get-RelativeManifest $workspaceFull @($excludedRunsRoot, $excludedGitRoot)
    $gitBefore = Get-GitState $workspaceFull

    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    foreach ($name in @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'CODEX_HOME', 'TEMP', 'TMP')) {
        New-Item -ItemType Directory -Path (Join-Path $environmentRoot $name) -Force | Out-Null
    }
    $runRelativePath = ([IO.Path]::GetRelativePath($campaignRoot, $runRoot)).Replace('\', '/')
    $campaignRelativePath = ([IO.Path]::GetRelativePath($runRoot, $campaignPath)).Replace('\', '/')
    $schemaRelativePath = ([IO.Path]::GetRelativePath($runRoot, $campaignSchemaPath)).Replace('\', '/')
    $request = [ordered]@{
        schema_version = '1.0.0'
        request_id = 'abk:run-request:isolation-audit-control-r1'
        campaign_id = $campaign.campaign_id
        branch = 'control'
        case_id = 'COM-01-normal-primary'
        repeat = 1
        fixture = [ordered]@{ relative_path = $fixtureRelativePath; sha256 = $fixtureHash }
        contracts = [ordered]@{
            campaign_relative_path = $campaignRelativePath
            campaign_sha256 = $campaignHash
            schema_relative_path = $schemaRelativePath
            schema_sha256 = $campaignSchemaHash
        }
        run = [ordered]@{
            run_id = 'abk:run:isolation-audit-control-r1'
            relative_run_root = $runRelativePath
            timeout_seconds = 120
            stop_condition_id = 'readiness-and-evidence-emitted'
        }
        authority = [ordered]@{
            read_roots = @('campaign', 'fixture', 'schema')
            write_root = 'run'
            network = $false
            credentials = $false
            production_resources = $false
            external_writes = $false
            git_mutation = $false
            process_spawn = $false
        }
        environment = [ordered]@{
            HOME = 'env/HOME'
            USERPROFILE = 'env/USERPROFILE'
            APPDATA = 'env/APPDATA'
            LOCALAPPDATA = 'env/LOCALAPPDATA'
            XDG_CONFIG_HOME = 'env/XDG_CONFIG_HOME'
            XDG_DATA_HOME = 'env/XDG_DATA_HOME'
        }
        runner = [ordered]@{
            contract_version = 'control-runner-v1'
            executable_sha256 = $runnerHash
            host = 'codex'
        }
    }
    $request | ConvertTo-Json -Depth 30 -Compress | Set-Content -LiteralPath $requestPath -Encoding utf8NoBOM
    $processResult = Invoke-SanitizedRunner $runnerPath $requestPath $environmentRoot
    if ($processResult.exit_code -ne 0) { Fail 'RUNNER_EXIT_NONZERO' "Sanitized runner exited with code $($processResult.exit_code)." }
    if (@($forbiddenMatches).Count -gt 0) { Fail 'STATIC_AUTHORITY_TOKEN' 'Static authority scan was not empty.' }

    $auditRunFiles = @(Get-ChildItem -LiteralPath $auditRunRoot -Recurse -File -Force)
    $ownerRunOnly = @($auditRunFiles | Where-Object { -not $_.FullName.StartsWith(([IO.Path]::GetFullPath($auditRunRoot) + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase) }).Count -eq 0
    $childProcessesPass = $processResult.child_processes_observed -eq 0
    $environmentPass = $true
    $networkEnforcement = 'NOT_PROVEN'
    $limitations = @('OS-level network denial was not established; the audit observed process connections only and therefore remains INCONCLUSIVE.')
} finally {
    if (Test-Path -LiteralPath $auditRunRoot) { [IO.Directory]::Delete($auditRunRoot, $true) }
}

$repoAfter = Get-RelativeManifest $workspaceFull @($excludedRunsRoot, $excludedGitRoot)
$gitAfter = Get-GitState $workspaceFull
$changedFiles = Compare-Manifests $repoBefore $repoAfter
$repositoryUnchanged = $changedFiles.Count -eq 0
$gitUnchanged = $gitBefore.head -eq $gitAfter.head -and $gitBefore.branch -eq $gitAfter.branch -and $gitBefore.status -eq $gitAfter.status
$endedAt = [DateTime]::UtcNow
$auditStatus = if (-not $environmentPass -or -not $childProcessesPass -or -not $repositoryUnchanged -or -not $gitUnchanged -or -not $ownerRunOnly) { 'FAILED' } elseif ($networkEnforcement -eq 'NOT_PROVEN') { 'INCONCLUSIVE' } else { 'PASS' }
$record = [ordered]@{
    '$schema' = [IO.Path]::GetRelativePath((Split-Path -Parent $outputFull), $schemaPath).Replace('\', '/')
    schema_version = '1.0.0'
    audit_id = $AuditId
    campaign_id = $manifest.campaign_id
    manifest_id = $manifest.manifest_id
    host = 'codex'
    status = $auditStatus
    started_at = $startedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
    ended_at = $endedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
    runner_sha256 = $runnerHash
    manifest_sha256 = $manifestHash
    process = [ordered]@{
        launcher = 'System.Diagnostics.ProcessStartInfo'
        child_executable = 'pwsh.exe'
        powershell_major = $PSVersionTable.PSVersion.Major
        runner_exit_code = $processResult.exit_code
        child_processes_observed = $processResult.child_processes_observed
    }
    environment = [ordered]@{
        sanitized = $environmentPass
        credential_values_inherited = $false
        real_config_inherited = $false
        roots = @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME', 'CODEX_HOME', 'TEMP', 'TMP')
    }
    scope = [ordered]@{
        repository_unchanged = $repositoryUnchanged
        git_unchanged = $gitUnchanged
        owner_run_only = $ownerRunOnly
        outside_changed_files = $changedFiles.Count
    }
    network = [ordered]@{
        probe = 'process-connection-observation-only'
        connections_observed = $processResult.connections_observed
        enforcement = $networkEnforcement
    }
    findings = @(
        [ordered]@{ check = 'environment-sanitization'; status = if ($environmentPass) { 'PASS' } else { 'FAILED' }; detail = 'The child process received only a machine/runtime allowlist and fresh per-run roots for user/config/cache variables.' },
        [ordered]@{ check = 'process-boundary'; status = if ($childProcessesPass) { 'PASS' } else { 'FAILED' }; detail = "No undeclared child process was observed; maximum observed count was $($processResult.child_processes_observed)." },
        [ordered]@{ check = 'repository-scope'; status = if ($repositoryUnchanged) { 'PASS' } else { 'FAILED' }; detail = "No changed repository file was observed outside the excluded run root; changed count was $($changedFiles.Count)." },
        [ordered]@{ check = 'git-scope'; status = if ($gitUnchanged) { 'PASS' } else { 'FAILED' }; detail = 'HEAD, branch, and porcelain worktree state matched before and after the audit.' },
        [ordered]@{ check = 'network-denial'; status = 'INCONCLUSIVE'; detail = "No process socket was observed ($($processResult.connections_observed)), but no OS-level deny policy was independently established." }
    )
    limitations = $limitations
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $outputFull) -PathType Container)) { New-Item -ItemType Directory -Path (Split-Path -Parent $outputFull) -Force | Out-Null }
$record | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $outputFull -Encoding utf8NoBOM
Write-Output ('ISOLATION_AUDIT_WRITTEN: {0}; status={1}; network_enforcement={2}' -f $AuditId, $record.status, $record.network.enforcement)

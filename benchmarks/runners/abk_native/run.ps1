param(
    [Parameter(Mandatory = $true)]
    [string]$RequestPath
)

$ErrorActionPreference = 'Stop'

$scriptPath = [IO.Path]::GetFullPath($PSCommandPath)
$benchmarksRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$repositoryRoot = Split-Path -Parent $benchmarksRoot
$requestFullPath = [IO.Path]::GetFullPath($RequestPath)
$runRoot = Split-Path -Parent $requestFullPath
$startedAt = [DateTime]::UtcNow
$request = $null
$requestSha256 = $null
$runnerSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $scriptPath).Hash.ToLowerInvariant()
$events = [System.Collections.Generic.List[object]]::new()
$stdoutLines = [System.Collections.Generic.List[string]]::new()
$stderrLines = [System.Collections.Generic.List[string]]::new()
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$repositoryPrefix = $repositoryRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$runRootIsAllowed = $runRoot.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)

function New-RunnerException([string]$Code, [string]$Message, [string]$Field, [int]$ExitCode, [string]$TerminalState) {
    $exception = [System.Exception]::new($Message)
    $exception.Data['code'] = $Code
    $exception.Data['field'] = $Field
    $exception.Data['exit_code'] = $ExitCode
    $exception.Data['terminal_state'] = $TerminalState
    return $exception
}

function Throw-RunnerError([string]$Code, [string]$Message, [string]$Field, [int]$ExitCode, [string]$TerminalState) {
    throw (New-RunnerException $Code $Message $Field $ExitCode $TerminalState)
}

function Get-Value([object]$Object, [string]$Name, [object]$Default) {
    if ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name]) { return $Object.$Name }
    return $Default
}

function Get-Hash([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Write-Text([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function Write-Json([object]$Document, [string]$Path) {
    Write-Text $Path ($Document | ConvertTo-Json -Depth 100 -Compress)
}

function Read-Json([string]$Path, [string]$Field) {
    try {
        return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100 -ErrorAction Stop
    } catch {
        Throw-RunnerError 'JSON_INVALID' "Unable to parse JSON for '$Field'." $Field 2 'REJECTED'
    }
}

function Add-Event([string]$Event, [string]$Detail) {
    $events.Add([ordered]@{ event = $Event; detail = $Detail })
}

function Add-Stdout([string]$Line) { $stdoutLines.Add($Line) }
function Add-Stderr([string]$Line) { $stderrLines.Add($Line) }

function Assert-InRepository([string]$Path, [string]$Field) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-RunnerError 'PATH_OUT_OF_ROOT' "Resolved path for '$Field' is outside the repository root." $Field 2 'REJECTED'
    }
    $cursor = $full
    while ($true) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -Force -LiteralPath $cursor
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                Throw-RunnerError 'PATH_REPARSE_POINT' "Reparse point detected for '$Field'." $Field 2 'REJECTED'
            }
        }
        if ($cursor -eq $repositoryRoot) { break }
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) { break }
        $cursor = $parent
    }
    return $full
}

function Assert-RelativePath([string]$Path, [string]$Field, [bool]$AllowParent) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:|^[\\/]' -or $Path -match '[\x00-\x1f]') {
        Throw-RunnerError 'PATH_OUT_OF_ROOT' "Path for '$Field' is not a safe relative path." $Field 2 'REJECTED'
    }
    $segments = @($Path.Replace('\', '/') -split '/')
    if (@($segments | Where-Object { $_ -eq '' -or $_ -eq '.' }).Count -gt 0) {
        Throw-RunnerError 'PATH_OUT_OF_ROOT' "Path for '$Field' contains an empty or current-directory segment." $Field 2 'REJECTED'
    }
    if (-not $AllowParent -and @($segments | Where-Object { $_ -eq '..' }).Count -gt 0) {
        Throw-RunnerError 'PATH_OUT_OF_ROOT' "Path for '$Field' contains an out-of-root parent segment." $Field 2 'REJECTED'
    }
}

function Resolve-UnderRoot([string]$Root, [string]$RelativePath, [string]$Field, [bool]$AllowParent) {
    Assert-RelativePath $RelativePath $Field $AllowParent
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)))
    if (-not $AllowParent) {
        $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
        if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
            Throw-RunnerError 'PATH_OUT_OF_ROOT' "Path for '$Field' escapes its declared root." $Field 2 'REJECTED'
        }
    }
    Assert-InRepository $candidate $Field | Out-Null
    return $candidate
}

function Resolve-PinnedFile([string]$RelativePath, [string]$ExpectedHash, [string]$Field, [string]$CanonicalPath) {
    Assert-RelativePath $RelativePath $Field $true
    $candidates = @(
        [IO.Path]::GetFullPath((Join-Path $runRoot ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar))),
        [IO.Path]::GetFullPath((Join-Path $repositoryRoot ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar))),
        [IO.Path]::GetFullPath($CanonicalPath)
    ) | Select-Object -Unique
    $matching = [System.Collections.Generic.List[string]]::new()
    foreach ($candidate in $candidates) {
        if (-not $candidate.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) { continue }
        if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and ((Get-Hash $candidate) -eq $ExpectedHash)) {
            Assert-InRepository $candidate $Field | Out-Null
            $matching.Add($candidate)
        }
    }
    if ($matching.Count -ne 1) { Throw-RunnerError 'CONTRACT_PATH_INVALID' "Unable to resolve one pinned file for '$Field'." $Field 2 'REJECTED' }
    return $matching[0]
}

function Get-ErrorObject([System.Exception]$Exception) {
    $code = if ($Exception.Data.Contains('code')) { [string]$Exception.Data['code'] } else { 'RUNNER_FAILURE' }
    $field = if ($Exception.Data.Contains('field')) { [string]$Exception.Data['field'] } else { 'runner' }
    return [ordered]@{ code = $code; retryable = $false; message = $Exception.Message; field = $field }
}

function Get-ExitCode([System.Exception]$Exception) {
    if ($Exception.Data.Contains('exit_code')) { return [int]$Exception.Data['exit_code'] }
    return 3
}

function Get-TerminalState([System.Exception]$Exception) {
    if ($Exception.Data.Contains('terminal_state')) { return [string]$Exception.Data['terminal_state'] }
    return 'FAILED'
}

function Write-Inventory([string]$Path) {
    $entries = [System.Collections.Generic.List[object]]::new()
    $inventoryFull = [IO.Path]::GetFullPath($Path)
    foreach ($file in @(Get-ChildItem -LiteralPath $runRoot -Recurse -File | Sort-Object FullName)) {
        if ([IO.Path]::GetFullPath($file.FullName) -eq $inventoryFull) { continue }
        $relative = ([IO.Path]::GetRelativePath($runRoot, $file.FullName)).Replace('\', '/')
        if ($relative -eq 'request.json') { continue }
        $entries.Add([ordered]@{ relative_path = $relative; owner = 'abk-native-runner'; disposition = 'blocked'; size = [int64]$file.Length; sha256 = Get-Hash $file.FullName })
    }
    Write-Json ([ordered]@{ schema_version = '1.0.0'; run_id = Get-Value (Get-Value $request 'run' $null) 'run_id' 'abk:run:unknown'; projection_sha256 = $null; files = @($entries) }) $Path
}

function Write-Evidence([string]$TerminalState, [int]$ExitCode, [object]$ErrorObject, [object]$Readiness, [object]$Provenance) {
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    $run = Get-Value $request 'run' $null
    $fixture = Get-Value $request 'fixture' $null
    $contracts = Get-Value $request 'contracts' $null
    $runId = Get-Value $run 'run_id' 'abk:run:unknown'
    $requestId = Get-Value $request 'request_id' 'abk:run-request:unknown'
    $campaignId = Get-Value $request 'campaign_id' 'abk:benchmark-campaign:artifact-dag-core-v1'
    $caseId = Get-Value $request 'case_id' 'unknown'
    $branch = Get-Value $request 'branch' 'abk_native'
    $repeat = Get-Value $request 'repeat' 1
    Write-Text (Join-Path $runRoot 'stdout.log') ($stdoutLines -join [Environment]::NewLine)
    Write-Text (Join-Path $runRoot 'stderr.log') ($stderrLines -join [Environment]::NewLine)
    Write-Text (Join-Path $runRoot 'tool-events.jsonl') ((@($events | ForEach-Object { $_ | ConvertTo-Json -Depth 30 -Compress }) -join [Environment]::NewLine))
    Write-Json $Readiness (Join-Path $runRoot 'readiness.json')
    Write-Json $Provenance (Join-Path $runRoot 'provenance.json')
    Write-Json ([ordered]@{ schema_version = '1.0.0'; campaign_id = $campaignId; case_id = $caseId; branch = $branch; status = 'inconclusive'; terminal_state = $TerminalState; error = $ErrorObject; evidence_ids = @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'readiness.json', 'provenance.json') }) (Join-Path $runRoot 'oracle-result.json')
    $lines = @(
        '# ABK-native runner result', '',
        "- terminal_state: $TerminalState",
        "- campaign_id: $campaignId",
        "- case_id: $caseId",
        "- branch: $branch",
        "- repeat: $repeat", '',
        '- result: NOT_COMPARABLE; the separate AI Booster Kit project is not executed or linked.',
        '- next_action: obtain an approved immutable ABK-native Artifact DAG snapshot and a local runtime boundary before scoring.', '',
        '- readiness: readiness.json',
        '- provenance: provenance.json', '',
        '- authority: campaign, schema, fixture, and metadata-only snapshot reads; run-root writes only.',
        '- side_effects: external project reads, network, credentials, production resources, external writes, Git mutation, and child processes denied.', ''
    )
    if ($null -ne $ErrorObject) { $lines += "- error: $($ErrorObject.code) ($($ErrorObject.field))"; $lines += '' }
    $lines += @('- links: run.json, oracle-result.json, stdout.log, stderr.log, tool-events.jsonl, output-inventory.json', '- links: readiness.json, provenance.json, operator.md')
    Write-Text (Join-Path $runRoot 'operator.md') ($lines -join [Environment]::NewLine)
    $endedAt = [DateTime]::UtcNow
    Write-Json ([ordered]@{
        schema_version = '1.0.0'
        run_id = $runId
        request_id = $requestId
        campaign_id = $campaignId
        branch = $branch
        branch_id = $branch
        case_id = $caseId
        repeat = $repeat
        runner = [ordered]@{ contract_version = 'abk-native-runner-v1'; executable_sha256 = $runnerSha256; host = 'codex' }
        input = [ordered]@{ fixture_sha256 = Get-Value $fixture 'sha256' ('0' * 64); campaign_sha256 = Get-Value $contracts 'campaign_sha256' ('0' * 64); schema_sha256 = Get-Value $contracts 'schema_sha256' ('0' * 64); request_sha256 = if ($null -ne $requestSha256) { $requestSha256 } else { ('0' * 64) } }
        started_at = $startedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
        ended_at = $endedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
        duration_ms = [int][Math]::Max(0, ($endedAt - $startedAt).TotalMilliseconds)
        terminal_state = $TerminalState
        exit_code = $ExitCode
        error = $ErrorObject
        readiness = [ordered]@{ relative_path = 'readiness.json'; sha256 = Get-Hash (Join-Path $runRoot 'readiness.json') }
        provenance = [ordered]@{ relative_path = 'provenance.json'; sha256 = Get-Hash (Join-Path $runRoot 'provenance.json') }
        state_before = [ordered]@{ manifest_sha256 = $null }
        state_after = [ordered]@{ manifest_sha256 = $null }
        recovery = $null
        handoff = $null
    }) (Join-Path $runRoot 'run.json')
    Write-Inventory (Join-Path $runRoot 'output-inventory.json')
}

function Invoke-AbkNativeValidation {
    $required = @('schema_version', 'request_id', 'campaign_id', 'branch', 'case_id', 'repeat', 'fixture', 'contracts', 'snapshot', 'run', 'authority', 'runner')
    if ($null -eq $request) { Throw-RunnerError 'REQUEST_JSON_INVALID' 'Request JSON could not be loaded.' 'request' 2 'REJECTED' }
    foreach ($name in $required) { if ($null -eq $request.PSObject.Properties[$name]) { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' "Request is missing '$name'." $name 2 'REJECTED' } }
    if ($request.schema_version -ne '1.0.0') { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Unsupported request schema version.' 'schema_version' 2 'REJECTED' }
    if ($request.branch -ne 'abk_native') { Throw-RunnerError 'BRANCH_NOT_ALLOWED' 'Only the abk_native branch is executable by this runner.' 'branch' 2 'REJECTED' }
    if ($request.campaign_id -ne 'abk:benchmark-campaign:artifact-dag-core-v1') { Throw-RunnerError 'CAMPAIGN_ID_INVALID' 'Request campaign_id is not the pinned campaign.' 'campaign_id' 2 'REJECTED' }
    if ($request.repeat -notin @(1, 2, 3)) { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Request repeat must be 1, 2, or 3.' 'repeat' 2 'REJECTED' }
    if ($request.runner.executable_sha256 -and $request.runner.executable_sha256 -ne $runnerSha256) { Throw-RunnerError 'RUNNER_HASH_MISMATCH' 'Runner executable hash does not match the request.' 'runner.executable_sha256' 2 'REJECTED' }
    foreach ($name in @('network', 'credentials', 'production_resources', 'external_writes', 'git_mutation', 'process_spawn')) { if ($request.authority.$name -ne $false) { Throw-RunnerError 'AUTHORITY_POLICY_VIOLATION' "Authority '$name' must be false." "authority.$name" 2 'REJECTED' } }
    Add-Event 'request_validated' 'abk-native-run-request-v1'

    $campaignCanonical = Join-Path $benchmarksRoot 'campaigns\artifact-dag-core-v1\campaign.json'
    $schemaCanonical = Join-Path $benchmarksRoot 'schemas\benchmark-campaign.schema.json'
    $campaignPath = Resolve-PinnedFile $request.contracts.campaign_relative_path $request.contracts.campaign_sha256 'contracts.campaign_relative_path' $campaignCanonical
    $schemaPath = Resolve-PinnedFile $request.contracts.schema_relative_path $request.contracts.schema_sha256 'contracts.schema_relative_path' $schemaCanonical
    $campaign = Read-Json $campaignPath 'campaign'
    $null = Read-Json $schemaPath 'campaign_schema'
    if ($campaign.campaign_id -ne $request.campaign_id) { Throw-RunnerError 'CAMPAIGN_ID_MISMATCH' 'Campaign identifier does not match the request.' 'campaign_id' 2 'REJECTED' }
    $campaignRoot = Split-Path -Parent $campaignPath
    if (([IO.Path]::GetRelativePath($campaignRoot, $runRoot)).Replace('\', '/') -ne $request.run.relative_run_root) { Throw-RunnerError 'RUN_ROOT_MISMATCH' 'Request run root does not match the owner directory.' 'run.relative_run_root' 2 'REJECTED' }
    $caseMatches = @($campaign.cases | Where-Object { $_.case_id -eq $request.case_id })
    if ($caseMatches.Count -ne 1) { Throw-RunnerError 'CASE_NOT_DECLARED' "Case '$($request.case_id)' is not declared exactly once." 'case_id' 2 'REJECTED' }
    $case = $caseMatches[0]
    if ($case.fixture -ne $request.fixture.relative_path) { Throw-RunnerError 'FIXTURE_DECLARATION_MISMATCH' 'Request fixture path does not match campaign.json.' 'fixture.relative_path' 2 'REJECTED' }
    $fixturePath = Resolve-UnderRoot $campaignRoot $request.fixture.relative_path 'fixture.relative_path' $false
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf) -or (Get-Hash $fixturePath) -ne $request.fixture.sha256 -or $case.fixture_sha256 -ne $request.fixture.sha256) { Throw-RunnerError 'FIXTURE_HASH_MISMATCH' 'Fixture SHA-256 does not match the request and campaign.' 'fixture.sha256' 2 'REJECTED' }
    Add-Event 'inputs_verified' 'campaign-schema-fixture-hashes'

    $snapshotCanonical = Join-Path $benchmarksRoot 'snapshots\abk-native-ai-booster-kit-feature.json'
    $snapshotPath = Resolve-PinnedFile $request.snapshot.relative_path $request.snapshot.sha256 'snapshot.relative_path' $snapshotCanonical
    $snapshot = Read-Json $snapshotPath 'abk_snapshot'
    if ($snapshot.branch -ne 'abk_native' -or $snapshot.status -ne 'NOT_COMPARABLE' -or $snapshot.execution_status -ne 'NOT_EXECUTED') { Throw-RunnerError 'SNAPSHOT_INVALID' 'Pinned ABK-native snapshot is not the explicit non-comparable descriptor.' 'snapshot' 2 'REJECTED' }
    if ($snapshot.scope.source_code_copied_into_framework_matrix -ne $false -or $snapshot.scope.git_linked_into_framework_matrix -ne $false -or $snapshot.scope.runtime_included -ne $false) { Throw-RunnerError 'SNAPSHOT_LINKAGE_FORBIDDEN' 'ABK-native snapshot linkage/runtime flags must remain false.' 'snapshot.scope' 2 'REJECTED' }
    Add-Event 'abk_snapshot_verified' 'external-project-not-read'
}

try {
    if (-not $runRootIsAllowed) { Throw-RunnerError 'REQUEST_ROOT_ESCAPE' 'Request owner directory is outside the repository workspace.' 'request' 2 'REJECTED' }
    Assert-InRepository $runRoot 'request_owner_root' | Out-Null
    if (-not (Test-Path -LiteralPath $requestFullPath -PathType Leaf)) { Throw-RunnerError 'REQUEST_MISSING' 'Request file does not exist.' 'request' 2 'REJECTED' }
    $requestSha256 = Get-Hash $requestFullPath
    $request = Read-Json $requestFullPath 'request'
    Invoke-AbkNativeValidation
    Throw-RunnerError 'NOT_COMPARABLE' 'The separate AI Booster Kit project is intentionally not executed or linked; an ABK-native Artifact DAG comparison cannot be proven.' 'branch.abk_native' 2 'REJECTED'
} catch {
    $exception = $_.Exception
    $errorObject = Get-ErrorObject $exception
    $terminalState = Get-TerminalState $exception
    $exitCode = Get-ExitCode $exception
    Add-Stderr ("$($errorObject.code): $($errorObject.message)")
    Add-Event 'terminal' $terminalState
    Add-Stdout "abk_native terminal state: $terminalState"
    $campaignId = Get-Value $request 'campaign_id' 'abk:benchmark-campaign:artifact-dag-core-v1'
    $caseId = Get-Value $request 'case_id' 'unknown'
    $fixture = Get-Value $request 'fixture' $null
    $contracts = Get-Value $request 'contracts' $null
    $snapshot = Get-Value $request 'snapshot' $null
    $readiness = [ordered]@{ schema_version = '1.0.0'; campaign_id = $campaignId; case_id = $caseId; branch = 'abk_native'; validation_state = 'not_comparable'; roots = @(); ready_set = @(); artifacts = @(); edges = @(); graph_sha256 = $null; error = $errorObject }
    $provenance = [ordered]@{ schema_version = '1.0.0'; campaign_id = $campaignId; case_id = $caseId; branch = 'abk_native'; comparable = $false; fixture_relative_path = Get-Value $fixture 'relative_path' $null; fixture_sha256 = Get-Value $fixture 'sha256' ('0' * 64); campaign_sha256 = Get-Value $contracts 'campaign_sha256' ('0' * 64); schema_sha256 = Get-Value $contracts 'schema_sha256' ('0' * 64); snapshot_relative_path = Get-Value $snapshot 'relative_path' 'benchmarks/snapshots/abk-native-ai-booster-kit-feature.json'; snapshot_sha256 = Get-Value $snapshot 'sha256' ('0' * 64); external_project_read = $false; source_code_copied_into_framework_matrix = $false; git_linked_into_framework_matrix = $false; graph_sha256 = $null; root_artifact_ids = @(); error = $errorObject }
    if ($runRootIsAllowed) { try { Write-Evidence $terminalState $exitCode $errorObject $readiness $provenance } catch { Add-Stderr "EVIDENCE_WRITE_FAILED: $($_.Exception.Message)"; $exitCode = 3 } }
    exit $exitCode
}

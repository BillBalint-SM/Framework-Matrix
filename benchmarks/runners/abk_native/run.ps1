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
$global:AbkNativeFixture = $null
$global:AbkNativeSnapshot = $null
$global:AbkNativeSnapshotPath = $null
$global:AbkNativeSnapshotHash = $null
$global:AbkNativeReadiness = $null
$global:AbkNativeProvenance = $null
$global:AbkNativeRecovery = $null
$global:AbkNativeHandoff = $null

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

function Get-TextHash([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))) -replace '-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}

function Get-InventoryHash([object]$Descriptor) {
    $canonical = (($Descriptor.inventory.entries | ForEach-Object { '{0}|{1}|{2}|{3}' -f $_.path, $_.digest, $_.digest_algorithm, $_.size }) -join "`n") + "`n"
    return Get-TextHash $canonical
}

function Write-Text([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

function Write-Json([object]$Document, [string]$Path) {
    Write-Text $Path ($Document | ConvertTo-Json -Depth 100 -Compress)
}

function Read-Json([string]$Path, [string]$Field) {
    try { return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100 -ErrorAction Stop }
    catch { Throw-RunnerError 'JSON_INVALID' "Unable to parse JSON for '$Field'." $Field 2 'REJECTED' }
}

function Add-Event([string]$Event, [string]$Detail) { $events.Add([ordered]@{ event = $Event; detail = $Detail }) }
function Add-Stdout([string]$Line) { $stdoutLines.Add($Line) }
function Add-Stderr([string]$Line) { $stderrLines.Add($Line) }

function Assert-InRepository([string]$Path, [string]$Field) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) { Throw-RunnerError 'PATH_OUT_OF_ROOT' "Resolved path for '$Field' is outside the repository root." $Field 2 'REJECTED' }
    $cursor = $full
    while ($true) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -Force -LiteralPath $cursor
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { Throw-RunnerError 'PATH_REPARSE_POINT' "Reparse point detected for '$Field'." $Field 2 'REJECTED' }
        }
        if ($cursor -eq $repositoryRoot) { break }
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) { break }
        $cursor = $parent
    }
    return $full
}

function Assert-RelativePath([string]$Path, [string]$Field, [bool]$AllowParent) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:|^[\\/]' -or $Path -match '[\x00-\x1f]') { Throw-RunnerError 'PATH_OUT_OF_ROOT' "Path for '$Field' is not a safe relative path." $Field 2 'REJECTED' }
    $segments = @($Path.Replace('\', '/') -split '/')
    if (@($segments | Where-Object { $_ -eq '' -or $_ -eq '.' }).Count -gt 0) { Throw-RunnerError 'PATH_OUT_OF_ROOT' "Path for '$Field' contains an empty or current-directory segment." $Field 2 'REJECTED' }
    if (-not $AllowParent -and @($segments | Where-Object { $_ -eq '..' }).Count -gt 0) { Throw-RunnerError 'PATH_OUT_OF_ROOT' "Path for '$Field' contains an out-of-root parent segment." $Field 2 'REJECTED' }
}

function Resolve-UnderRoot([string]$Root, [string]$RelativePath, [string]$Field, [bool]$AllowParent) {
    Assert-RelativePath $RelativePath $Field $AllowParent
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)))
    if (-not $AllowParent) {
        $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
        if (-not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { Throw-RunnerError 'PATH_OUT_OF_ROOT' "Path for '$Field' escapes its declared root." $Field 2 'REJECTED' }
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
        if ((Test-Path -LiteralPath $candidate -PathType Leaf) -and ((Get-Hash $candidate) -eq $ExpectedHash)) { Assert-InRepository $candidate $Field | Out-Null; $matching.Add($candidate) }
    }
    if ($matching.Count -ne 1) { Throw-RunnerError 'CONTRACT_PATH_INVALID' "Unable to resolve one pinned file for '$Field'." $Field 2 'REJECTED' }
    return $matching[0]
}

function Get-ErrorObject([System.Exception]$Exception) {
    $code = if ($Exception.Data.Contains('code')) { [string]$Exception.Data['code'] } else { 'RUNNER_FAILURE' }
    $field = if ($Exception.Data.Contains('field')) { [string]$Exception.Data['field'] } else { 'runner' }
    return [ordered]@{ code = $code; retryable = $false; message = $Exception.Message; field = $field }
}

function Get-ExitCode([System.Exception]$Exception) { if ($Exception.Data.Contains('exit_code')) { return [int]$Exception.Data['exit_code'] }; return 3 }
function Get-TerminalState([System.Exception]$Exception) { if ($Exception.Data.Contains('terminal_state')) { return [string]$Exception.Data['terminal_state'] }; return 'FAILED' }

function Get-OracleStatus([object]$ErrorObject, [string]$TerminalState) {
    if ($null -eq $ErrorObject) { return 'passed' }
    if ($ErrorObject.code -eq 'INTERRUPTED') { return 'stopped' }
    if ($ErrorObject.code -eq 'DEPENDENCY_OUT_OF_ROOT') { return 'inconclusive' }
    if ($ErrorObject.code -in @('UNKNOWN_ARTIFACT_REFERENCE', 'DUPLICATE_DEPENDENCY')) { return 'failed' }
    if ($ErrorObject.code -eq 'RECOVERED_AFTER_FAILURE') { return 'passed' }
    return 'inconclusive'
}

function Write-Inventory([string]$Path) {
    $entries = [System.Collections.Generic.List[object]]::new()
    $inventoryFull = [IO.Path]::GetFullPath($Path)
    foreach ($file in @(Get-ChildItem -LiteralPath $runRoot -Recurse -File | Sort-Object FullName)) {
        if ([IO.Path]::GetFullPath($file.FullName) -eq $inventoryFull) { continue }
        $relative = ([IO.Path]::GetRelativePath($runRoot, $file.FullName)).Replace('\', '/')
        if ($relative -eq 'request.json') { continue }
        $entries.Add([ordered]@{ relative_path = $relative; owner = 'abk-native-runner'; disposition = 'behavior_reproduced'; size = [int64]$file.Length; sha256 = Get-Hash $file.FullName })
    }
    Write-Json ([ordered]@{ schema_version = '1.0.0'; run_id = Get-Value (Get-Value $request 'run' $null) 'run_id' 'abk:run:unknown'; projection_sha256 = $null; files = @($entries) }) $Path
}

function Write-Evidence([string]$TerminalState, [int]$ExitCode, [object]$ErrorObject, [object]$Readiness, [object]$Provenance, [object]$Recovery, [object]$Handoff) {
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
    $oracleStatus = Get-OracleStatus $ErrorObject $TerminalState
    Write-Text (Join-Path $runRoot 'stdout.log') ($stdoutLines -join [Environment]::NewLine)
    Write-Text (Join-Path $runRoot 'stderr.log') ($stderrLines -join [Environment]::NewLine)
    Write-Text (Join-Path $runRoot 'tool-events.jsonl') ((@($events | ForEach-Object { $_ | ConvertTo-Json -Depth 30 -Compress }) -join [Environment]::NewLine))
    Write-Json $Readiness (Join-Path $runRoot 'readiness.json')
    Write-Json $Provenance (Join-Path $runRoot 'provenance.json')
    Write-Json ([ordered]@{ schema_version = '1.0.0'; campaign_id = $campaignId; case_id = $caseId; branch = $branch; status = $oracleStatus; terminal_state = $TerminalState; error = $ErrorObject; evidence_ids = @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'readiness.json', 'provenance.json') }) (Join-Path $runRoot 'oracle-result.json')
    $resultLine = if ($null -eq $ErrorObject) { '- result: ABK-native clean-room formation graph executed with snapshot-bound provenance.' } else { '- result: typed terminal evidence preserved; external AI Booster Kit project was not executed or linked.' }
    $lines = @(
        '# ABK-native runner result', '',
        "- terminal_state: $TerminalState", "- campaign_id: $campaignId", "- case_id: $caseId", "- branch: $branch", "- repeat: $repeat", '',
        $resultLine,
        '- implementation: framework-matrix-abk-native-clean-room-v1',
        '- authority: campaign, schema, fixture, and metadata-only snapshot reads; run-root writes only.',
        '- side_effects: external project reads, network, credentials, production resources, external writes, Git mutation, and child processes denied.', '',
        '- readiness: readiness.json', '- provenance: provenance.json', '',
        '- links: run.json, oracle-result.json, stdout.log, stderr.log, tool-events.jsonl, output-inventory.json', '- links: readiness.json, provenance.json, operator.md'
    )
    if ($null -ne $ErrorObject) { $lines += "- error: $($ErrorObject.code) ($($ErrorObject.field))" }
    Write-Text (Join-Path $runRoot 'operator.md') ($lines -join [Environment]::NewLine)
    $endedAt = [DateTime]::UtcNow
    Write-Json ([ordered]@{
        schema_version = '1.0.0'; run_id = $runId; request_id = $requestId; campaign_id = $campaignId; branch = $branch; branch_id = $branch; case_id = $caseId; repeat = $repeat
        runner = [ordered]@{ contract_version = 'abk-native-runner-v2'; executable_sha256 = $runnerSha256; host = 'codex' }
        input = [ordered]@{ fixture_sha256 = Get-Value $fixture 'sha256' ('0' * 64); campaign_sha256 = Get-Value $contracts 'campaign_sha256' ('0' * 64); schema_sha256 = Get-Value $contracts 'schema_sha256' ('0' * 64); request_sha256 = if ($null -ne $requestSha256) { $requestSha256 } else { ('0' * 64) } }
        started_at = $startedAt.ToString('yyyy-MM-ddTHH:mm:ssZ'); ended_at = $endedAt.ToString('yyyy-MM-ddTHH:mm:ssZ'); duration_ms = [int][Math]::Max(0, ($endedAt - $startedAt).TotalMilliseconds)
        terminal_state = $TerminalState; exit_code = $ExitCode; error = $ErrorObject
        readiness = [ordered]@{ relative_path = 'readiness.json'; sha256 = Get-Hash (Join-Path $runRoot 'readiness.json') }
        provenance = [ordered]@{ relative_path = 'provenance.json'; sha256 = Get-Hash (Join-Path $runRoot 'provenance.json') }
        state_before = [ordered]@{ manifest_sha256 = ('0' * 64) }; state_after = [ordered]@{ manifest_sha256 = ('0' * 64) }; recovery = $Recovery; handoff = $Handoff
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
    Add-Event 'request_validated' 'abk-native-run-request-v2'

    $campaignCanonical = Join-Path $benchmarksRoot 'campaigns\artifact-dag-core-v1\campaign.json'
    $schemaCanonical = Join-Path $benchmarksRoot 'schemas\benchmark-campaign.schema.json'
    $campaignPath = Resolve-PinnedFile $request.contracts.campaign_relative_path $request.contracts.campaign_sha256 'contracts.campaign_relative_path' $campaignCanonical
    $schemaPath = Resolve-PinnedFile $request.contracts.schema_relative_path $request.contracts.schema_sha256 'contracts.schema_relative_path' $schemaCanonical
    $campaign = Read-Json $campaignPath 'campaign'; if (-not (Test-Json -LiteralPath $campaignPath -SchemaFile $schemaPath)) { Throw-RunnerError 'CAMPAIGN_SCHEMA_INVALID' 'Campaign does not satisfy the pinned schema.' 'campaign' 2 'REJECTED' }
    if ($campaign.campaign_id -ne $request.campaign_id) { Throw-RunnerError 'CAMPAIGN_ID_MISMATCH' 'Campaign identifier does not match the request.' 'campaign_id' 2 'REJECTED' }
    $campaignRoot = Split-Path -Parent $campaignPath
    if (([IO.Path]::GetRelativePath($campaignRoot, $runRoot)).Replace('\', '/') -ne $request.run.relative_run_root) { Throw-RunnerError 'RUN_ROOT_MISMATCH' 'Request run root does not match the owner directory.' 'run.relative_run_root' 2 'REJECTED' }
    $caseMatches = @($campaign.cases | Where-Object { $_.case_id -eq $request.case_id }); if ($caseMatches.Count -ne 1) { Throw-RunnerError 'CASE_NOT_DECLARED' "Case '$($request.case_id)' is not declared exactly once." 'case_id' 2 'REJECTED' }
    $case = $caseMatches[0]; if ($case.fixture -ne $request.fixture.relative_path) { Throw-RunnerError 'FIXTURE_DECLARATION_MISMATCH' 'Request fixture path does not match campaign.json.' 'fixture.relative_path' 2 'REJECTED' }
    $fixturePath = Resolve-UnderRoot $campaignRoot $request.fixture.relative_path 'fixture.relative_path' $false
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf) -or (Get-Hash $fixturePath) -ne $request.fixture.sha256 -or $case.fixture_sha256 -ne $request.fixture.sha256) { Throw-RunnerError 'FIXTURE_HASH_MISMATCH' 'Fixture SHA-256 does not match the request and campaign.' 'fixture.sha256' 2 'REJECTED' }
    $global:AbkNativeFixture = Read-Json $fixturePath 'fixture'
    Add-Event 'inputs_verified' 'campaign-schema-fixture-hashes'

    $snapshotCanonical = Join-Path $benchmarksRoot 'snapshots\abk-native-ai-booster-kit-feature.json'
    $snapshotPath = Resolve-PinnedFile $request.snapshot.relative_path $request.snapshot.sha256 'snapshot.relative_path' $snapshotCanonical
    $snapshot = Read-Json $snapshotPath 'abk_snapshot'
    if ($snapshot.branch -ne 'abk_native' -or $snapshot.status -ne 'READY_FOR_ENTRYPOINT' -or $snapshot.execution_status -ne 'NOT_EXECUTED') { Throw-RunnerError 'SNAPSHOT_INVALID' 'Pinned ABK-native snapshot is not entrypoint-ready.' 'snapshot' 2 'REJECTED' }
    if ($snapshot.disposition.candidate_disposition -ne 'READY_FOR_CLEAN_ROOM_ENTRYPOINT' -or $snapshot.provenance.worktree_status -ne 'clean-snapshot') { Throw-RunnerError 'SNAPSHOT_INVALID' 'Pinned ABK-native snapshot is not an immutable clean-snapshot descriptor.' 'snapshot' 2 'REJECTED' }
    if ((Get-InventoryHash $snapshot) -ne $snapshot.inventory.inventory_sha256) { Throw-RunnerError 'SNAPSHOT_INVENTORY_MISMATCH' 'ABK snapshot inventory hash is invalid.' 'snapshot.inventory' 2 'REJECTED' }
    if ($snapshot.scope.source_code_copied_into_framework_matrix -ne $false -or $snapshot.scope.git_linked_into_framework_matrix -ne $false -or $snapshot.scope.runtime_included -ne $false) { Throw-RunnerError 'SNAPSHOT_LINKAGE_FORBIDDEN' 'ABK-native snapshot linkage/runtime flags must remain false.' 'snapshot.scope' 2 'REJECTED' }
    $global:AbkNativeSnapshot = $snapshot; $global:AbkNativeSnapshotPath = ([IO.Path]::GetRelativePath($repositoryRoot, $snapshotPath)).Replace('\', '/'); $global:AbkNativeSnapshotHash = Get-Hash $snapshotPath
    Add-Event 'abk_snapshot_verified' 'immutable-metadata-only'
}

function Invoke-AbkNativeGraph {
    $fixture = $global:AbkNativeFixture
    if ($null -eq $fixture -or $null -eq $fixture.project -or $null -eq $fixture.project.artifacts) { Throw-RunnerError 'FIXTURE_GRAPH_INVALID' 'Fixture does not contain a project graph.' 'project.artifacts' 3 'FAILED' }
    $artifactList = @($fixture.project.artifacts); if ($artifactList.Count -eq 0) { Throw-RunnerError 'EMPTY_FORMATION_GRAPH' 'ABK formation graph must contain at least one formation.' 'project.artifacts' 3 'FAILED' }
    $formationsById = @{}; $declarationIds = [System.Collections.Generic.List[string]]::new()
    foreach ($artifact in $artifactList) {
        $id = [string](Get-Value $artifact 'id' '')
        if ([string]::IsNullOrWhiteSpace($id) -or $id -notmatch '^[a-z][a-z0-9-]*$') { Throw-RunnerError 'FORMATION_ID_INVALID' 'ABK formation id is invalid.' 'project.artifacts.id' 3 'FAILED' }
        if ($formationsById.ContainsKey($id)) { Throw-RunnerError 'DUPLICATE_FORMATION_ID' "Formation '$id' is duplicated." 'project.artifacts.id' 3 'FAILED' }
        $formationsById[$id] = [pscustomobject]@{ formation_id = $id; prerequisites = @((Get-Value $artifact 'depends_on' @())) }; $declarationIds.Add($id)
    }
    $edges = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $declarationIds) {
        $formation = $formationsById[$id]; $normalized = [System.Collections.Generic.List[string]]::new(); $seen = @{}
        foreach ($dependencyValue in @($formation.prerequisites)) {
            $dependency = [string]$dependencyValue
            if ([string]::IsNullOrWhiteSpace($dependency) -or $dependency -match '(^\.+)|[\\/]') { Throw-RunnerError 'DEPENDENCY_OUT_OF_ROOT' "Formation '$id' contains an out-of-root prerequisite '$dependency'." 'project.artifacts.depends_on' 2 'REJECTED' }
            if ($seen.ContainsKey($dependency)) { Throw-RunnerError 'DUPLICATE_DEPENDENCY' "Formation '$id' repeats prerequisite '$dependency'." 'project.artifacts.depends_on' 3 'FAILED' }
            if (-not $formationsById.ContainsKey($dependency)) { Throw-RunnerError 'UNKNOWN_ARTIFACT_REFERENCE' "Formation '$id' depends on unknown formation '$dependency'." 'project.artifacts.depends_on' 3 'FAILED' }
            $seen[$dependency] = $true; $normalized.Add($dependency); $edges.Add("$id -> $dependency")
        }
        $formation.prerequisites = @($normalized)
    }
    $declarationIndex = @{}; for ($index = 0; $index -lt $declarationIds.Count; $index++) { $declarationIndex[$declarationIds[$index]] = $index }
    $inDegree = @{}; $dependents = @{}
    foreach ($id in $declarationIds) { $inDegree[$id] = @($formationsById[$id].prerequisites).Count; $dependents[$id] = [System.Collections.Generic.List[string]]::new() }
    foreach ($id in $declarationIds) { foreach ($dependency in @($formationsById[$id].prerequisites)) { $dependents[$dependency].Add($id) } }
    $roots = @($declarationIds | Where-Object { $inDegree[$_] -eq 0 }); $queue = [System.Collections.Generic.List[string]]::new(); foreach ($id in $roots) { $queue.Add($id) }; $order = [System.Collections.Generic.List[string]]::new()
    while ($queue.Count -gt 0) { $current = $queue[0]; $queue.RemoveAt(0); $order.Add($current); foreach ($dependent in @($dependents[$current])) { $inDegree[$dependent] = [int]$inDegree[$dependent] - 1; if ($inDegree[$dependent] -eq 0) { $queue.Add($dependent) } }; $orderedQueue = @($queue | Sort-Object { $declarationIndex[$_] }); $queue.Clear(); foreach ($id in $orderedQueue) { $queue.Add($id) } }
    if ($order.Count -ne $declarationIds.Count) { Throw-RunnerError 'FORMATION_CYCLE_DETECTED' 'ABK formation graph contains a cyclic prerequisite.' 'project.artifacts' 3 'FAILED' }
    $formations = [System.Collections.Generic.List[object]]::new(); $blocked = [ordered]@{}
    foreach ($id in $declarationIds) { $prerequisites = @($formationsById[$id].prerequisites); $formations.Add([ordered]@{ formation_id = $id; prerequisites = @($prerequisites); relations = @($prerequisites | ForEach-Object { [ordered]@{ kind = 'depends_on'; target = $_ } }); state = 'valid' }); if ($prerequisites.Count -gt 0) { $blocked[$id] = @($prerequisites) } }
    $graph = [ordered]@{ formations = @($formations); relations = @($edges); root_formations = @($roots); formation_order = @($order) }; $graphHash = Get-TextHash ($graph | ConvertTo-Json -Depth 50 -Compress)
    $readiness = [ordered]@{ schema_version = '1.0.0'; campaign_id = $request.campaign_id; case_id = $request.case_id; branch = 'abk_native'; representation = 'abk-formation-graph-v1'; validation_state = 'valid'; root_formations = @($roots); ready_formations = @($roots); next_formations = @($roots); completed = @(); blocked = $blocked; formations = @($formations); relations = @($edges); formation_order = @($order); graph_sha256 = $graphHash; error = $null }
    $provenance = [ordered]@{ schema_version = '1.0.0'; campaign_id = $request.campaign_id; case_id = $request.case_id; branch = 'abk_native'; comparable = $true; implementation = 'framework-matrix-abk-native-clean-room-v1'; mapping = 'campaign.project.artifacts -> ABK formation.prerequisites'; fixture_relative_path = $request.fixture.relative_path; fixture_sha256 = $request.fixture.sha256; campaign_sha256 = $request.contracts.campaign_sha256; schema_sha256 = $request.contracts.schema_sha256; snapshot_relative_path = $global:AbkNativeSnapshotPath; snapshot_sha256 = $global:AbkNativeSnapshotHash; snapshot_revision = $global:AbkNativeSnapshot.provenance.revision; external_project_read = $false; source_code_copied_into_framework_matrix = $false; git_linked_into_framework_matrix = $false; graph_sha256 = $graphHash; root_formation_ids = @($roots); error = $null }
    $global:AbkNativeReadiness = $readiness; $global:AbkNativeProvenance = $provenance
    Add-Event 'formation_graph_validated' 'abk-native-formation-prerequisite-graph'
    if ((Get-Value $fixture.project 'interrupt_after' '') -eq 'plan-read') { Add-Event 'interrupt_received' 'plan-read'; Throw-RunnerError 'INTERRUPTED' 'The declared plan-read interrupt stopped the ABK-native run.' 'project.interrupt_after' 130 'STOPPED' }
    if ((Get-Value $fixture.project 'failure_after' '') -eq 'derived-state-write') { $derived = Join-Path $runRoot 'derived-state.json'; Write-Json ([ordered]@{ graph_sha256 = $graphHash; owner = 'abk-native-runner' }) $derived; Add-Event 'derived_state_written' 'owned-run-root'; Remove-Item -LiteralPath $derived -Force; $global:AbkNativeRecovery = [ordered]@{ status = 'recovered'; strategy = (Get-Value $fixture.project 'recovery' 'owned-state-only'); owned_paths = @('derived-state.json'); removed = $true; graph_sha256 = $graphHash }; Add-Event 'recovery_completed' 'owned-state-only'; Throw-RunnerError 'RECOVERED_AFTER_FAILURE' 'Owned derived state was rolled back and the run is resumable.' 'project.failure_after' 0 'RECOVERED' }
    if ((Get-Value $fixture.project 'handoff' '') -eq 'validated-graph') { $global:AbkNativeHandoff = [ordered]@{ status = 'validated'; receiver = 'abk-native-oracle'; graph_sha256 = $graphHash; provenance_sha256 = Get-TextHash ($provenance | ConvertTo-Json -Depth 50 -Compress); verified = $true }; Add-Event 'handoff_validated' 'provenance-bound-formation-graph' }
    Add-Stdout "abk_native clean-room completed $($request.case_id)"; Add-Event 'output_emitted' 'readiness-provenance-operator'
}

try {
    if (-not $runRootIsAllowed) { Throw-RunnerError 'REQUEST_ROOT_ESCAPE' 'Request owner directory is outside the repository workspace.' 'request' 2 'REJECTED' }
    Assert-InRepository $runRoot 'request_owner_root' | Out-Null
    if (-not (Test-Path -LiteralPath $requestFullPath -PathType Leaf)) { Throw-RunnerError 'REQUEST_MISSING' 'Request file does not exist.' 'request' 2 'REJECTED' }
    $requestSha256 = Get-Hash $requestFullPath; $request = Read-Json $requestFullPath 'request'; Invoke-AbkNativeValidation; Invoke-AbkNativeGraph
    Add-Event 'terminal' 'SUCCEEDED'; Write-Evidence 'SUCCEEDED' 0 $null $global:AbkNativeReadiness $global:AbkNativeProvenance $global:AbkNativeRecovery $global:AbkNativeHandoff; exit 0
} catch {
    $exception = $_.Exception; $errorObject = Get-ErrorObject $exception; $terminalState = Get-TerminalState $exception; $exitCode = Get-ExitCode $exception; Add-Stderr ("$($errorObject.code): $($errorObject.message)"); Add-Event 'terminal' $terminalState; Add-Stdout "abk_native terminal state: $terminalState"
    $campaignId = Get-Value $request 'campaign_id' 'abk:benchmark-campaign:artifact-dag-core-v1'; $caseId = Get-Value $request 'case_id' 'unknown'; $fixture = Get-Value $request 'fixture' $null; $contracts = Get-Value $request 'contracts' $null; $snapshot = Get-Value $request 'snapshot' $null
    $readiness = if ($null -ne $global:AbkNativeReadiness) { $global:AbkNativeReadiness } else { [ordered]@{ schema_version = '1.0.0'; campaign_id = $campaignId; case_id = $caseId; branch = 'abk_native'; representation = 'abk-formation-graph-v1'; validation_state = 'blocked'; root_formations = @(); ready_formations = @(); formations = @(); relations = @(); graph_sha256 = $null; error = $errorObject } }
    $provenance = if ($null -ne $global:AbkNativeProvenance) { $global:AbkNativeProvenance } else { [ordered]@{ schema_version = '1.0.0'; campaign_id = $campaignId; case_id = $caseId; branch = 'abk_native'; comparable = $false; implementation = 'framework-matrix-abk-native-clean-room-v1'; mapping = 'campaign.project.artifacts -> ABK formation.prerequisites'; fixture_relative_path = Get-Value $fixture 'relative_path' $null; fixture_sha256 = Get-Value $fixture 'sha256' ('0' * 64); campaign_sha256 = Get-Value $contracts 'campaign_sha256' ('0' * 64); schema_sha256 = Get-Value $contracts 'schema_sha256' ('0' * 64); snapshot_relative_path = Get-Value $snapshot 'relative_path' 'benchmarks/snapshots/abk-native-ai-booster-kit-feature.json'; snapshot_sha256 = Get-Value $snapshot 'sha256' ('0' * 64); snapshot_revision = Get-Value $global:AbkNativeSnapshot.provenance 'revision' $null; external_project_read = $false; source_code_copied_into_framework_matrix = $false; git_linked_into_framework_matrix = $false; graph_sha256 = $null; root_formation_ids = @(); error = $errorObject } }
    if ($runRootIsAllowed) { try { Write-Evidence $terminalState $exitCode $errorObject $readiness $provenance $global:AbkNativeRecovery $global:AbkNativeHandoff } catch { Add-Stderr "EVIDENCE_WRITE_FAILED: $($_.Exception.Message)"; $exitCode = 3 } }
    exit $exitCode
}

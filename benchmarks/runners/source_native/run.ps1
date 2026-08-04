param(
    [Parameter(Mandatory = $true)]
    [string]$RequestPath
)

$ErrorActionPreference = 'Stop'

$scriptPath = [IO.Path]::GetFullPath($PSCommandPath)
$scriptRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$benchmarksRoot = Split-Path -Parent (Split-Path -Parent $scriptRoot)
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
$repositoryPrefix = $repositoryRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$runRootIsAllowed = $runRoot.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$global:SourceNativeSnapshot = $null
$global:SourceNativeSnapshotPath = $null
$global:SourceNativeSnapshotHash = $null
$global:SourceNativeFixture = $null
$global:SourceNativeReadiness = $null
$global:SourceNativeProvenance = $null
$global:SourceNativeRecovery = $null
$global:SourceNativeHandoff = $null

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

function Get-Hash([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-TextHash([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($utf8NoBom.GetBytes($Text))) -replace '-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Read-Json([string]$Path, [string]$Field) {
    try {
        return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100 -ErrorAction Stop
    } catch {
        Throw-RunnerError 'JSON_INVALID' "Unable to parse JSON for '$Field'." $Field 2 'REJECTED'
    }
}

function Write-Text([string]$Path, [string]$Text) {
    $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
    [IO.File]::WriteAllText($Path, $normalized, $utf8NoBom)
}

function Write-Json([object]$Document, [string]$Path) {
    Write-Text $Path ($Document | ConvertTo-Json -Depth 100 -Compress)
}

function Add-Event([string]$Event, [string]$Detail) {
    $events.Add([ordered]@{ event = $Event; detail = $Detail })
}

function Add-Stdout([string]$Line) {
    $stdoutLines.Add($Line)
}

function Add-Stderr([string]$Line) {
    $stderrLines.Add($Line)
}

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

function Resolve-ContractFile([string]$RelativePath, [string]$Field, [string]$ExpectedHash, [string]$CanonicalPath) {
    Assert-RelativePath $RelativePath $Field $true
    $bases = @(
        $runRoot,
        (Split-Path -Parent $runRoot),
        (Split-Path -Parent (Split-Path -Parent $runRoot)),
        $repositoryRoot
    )
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($base in $bases) {
        $candidate = [IO.Path]::GetFullPath((Join-Path $base ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)))
        if (-not $candidate.StartsWith($repositoryPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        Assert-InRepository $candidate $Field | Out-Null
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            $candidates.Add($candidate)
        }
    }
    $matching = @($candidates | Where-Object { (Get-Hash $_) -eq $ExpectedHash } | Select-Object -Unique)
    if ($matching.Count -ne 1) {
        Throw-RunnerError 'CONTRACT_PATH_INVALID' "Unable to resolve one pinned file for '$Field'." $Field 2 'REJECTED'
    }
    return $matching[0]
}

function Get-ErrorObject([System.Exception]$Exception) {
    $code = if ($Exception.Data.Contains('code')) { [string]$Exception.Data['code'] } else { 'RUNNER_FAILURE' }
    $field = if ($Exception.Data.Contains('field')) { [string]$Exception.Data['field'] } else { 'runner' }
    return [ordered]@{
        code = $code
        retryable = $false
        message = $Exception.Message
        field = $field
    }
}

function Get-ExitCode([System.Exception]$Exception) {
    if ($Exception.Data.Contains('exit_code')) { return [int]$Exception.Data['exit_code'] }
    return 3
}

function Get-TerminalState([System.Exception]$Exception) {
    if ($Exception.Data.Contains('terminal_state')) { return [string]$Exception.Data['terminal_state'] }
    return 'FAILED'
}

function Get-Value([object]$Object, [string]$Name, [object]$Default) {
    if ($null -ne $Object -and $null -ne $Object.PSObject.Properties[$Name]) { return $Object.$Name }
    return $Default
}

function Assert-AllowedProperties([object]$Object, [string[]]$Allowed, [string]$Field) {
    if ($null -eq $Object) { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' "Request object '$Field' is missing." $Field 2 'REJECTED' }
    foreach ($property in @($Object.PSObject.Properties.Name)) {
        if ($property -notin $Allowed) {
            Throw-RunnerError 'REQUEST_SCHEMA_INVALID' "Unknown request field '$Field.$property'." "$Field.$property" 2 'REJECTED'
        }
    }
}

function Write-Operator([string]$Path, [string]$TerminalState, [object]$ErrorObject, [object]$Readiness, [object]$Provenance) {
    $campaignId = Get-Value $request 'campaign_id' 'unknown'
    $caseId = Get-Value $request 'case_id' 'unknown'
    $branch = Get-Value $request 'branch' 'source_native'
    $repeat = Get-Value $request 'repeat' 1
    $resultLine = '- result: NOT_COMPARABLE or FAILED; no upstream OpenSpec runtime or package was executed.'
    $nextActionLine = '- next_action: inspect typed evidence and keep the branch out of scoring until the boundary is resolved.'
    if ($TerminalState -eq 'SUCCEEDED') {
        $resultLine = '- result: SUCCEEDED; the Framework-Matrix clean-room implementation processed the fixture graph.'
        $nextActionLine = '- next_action: compare readiness/provenance evidence against the control branch.'
    } elseif ($TerminalState -eq 'RECOVERED') {
        $resultLine = '- result: RECOVERED; the owned derived-state failure was rolled back.'
    } elseif ($TerminalState -eq 'STOPPED') {
        $resultLine = '- result: STOPPED; the declared interrupt was persisted without ambiguous success.'
    }
    $lines = @(
        '# Source-native runner result',
        '',
        "- terminal_state: $TerminalState",
        "- campaign_id: $campaignId",
        "- case_id: $caseId",
        "- branch: $branch",
        "- repeat: $repeat",
        '',
        $resultLine,
        $nextActionLine,
        '',
        '- readiness/provenance: emitted when graph validation reaches a comparable state.',
        '',
        '- authority: fixture, campaign, schema, and pinned source snapshot reads only; run-root writes only.',
        '- side_effects: network, credentials, production resources, external writes, Git mutation, and child processes denied.',
        ''
    )
    if ($null -ne $ErrorObject) {
        $lines += "- error: $($ErrorObject.code) ($($ErrorObject.field))"
        $lines += ''
    }
    $lines += '- links: run.json, oracle-result.json, stdout.log, stderr.log, tool-events.jsonl, output-inventory.json'
    if ($null -ne $Readiness) { $lines += '- link: readiness.json' }
    if ($null -ne $Provenance) { $lines += '- link: provenance.json' }
    if ($null -ne $global:SourceNativeRecovery) { $lines += '- link: recovery.json' }
    if ($null -ne $global:SourceNativeHandoff) { $lines += '- link: handoff.json' }
    $lines += '- link: operator.md'
    Write-Text $Path ($lines -join [Environment]::NewLine)
}

function Write-Inventory([string]$Path) {
    $entries = [System.Collections.Generic.List[object]]::new()
    $inventoryFull = [IO.Path]::GetFullPath($Path)
    foreach ($file in @(Get-ChildItem -LiteralPath $runRoot -Recurse -File | Sort-Object FullName)) {
        if ([IO.Path]::GetFullPath($file.FullName) -eq $inventoryFull) { continue }
        $relative = ([IO.Path]::GetRelativePath($runRoot, $file.FullName)).Replace('\', '/')
        if ($relative -eq 'request.json') { continue }
        $entries.Add([ordered]@{
            relative_path = $relative
            owner = 'source-native-runner'
            disposition = 'behavior_reproduced'
            size = [int64]$file.Length
            sha256 = Get-Hash $file.FullName
        })
    }
    $projectionSha256 = $null
    $operatorPath = Join-Path $runRoot 'operator.md'
    if (Test-Path -LiteralPath $operatorPath -PathType Leaf) { $projectionSha256 = Get-Hash $operatorPath }
    Write-Json ([ordered]@{
        schema_version = '1.0.0'
        run_id = Get-Value (Get-Value $request 'run' $null) 'run_id' 'abk:run:unknown'
        projection_sha256 = $projectionSha256
        files = @($entries)
    }) $Path
}

function Write-Evidence([string]$TerminalState, [int]$ExitCode, [object]$ErrorObject, [object]$Readiness, [object]$Provenance) {
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    $runId = Get-Value (Get-Value $request 'run' $null) 'run_id' 'abk:run:unknown'
    $requestId = Get-Value $request 'request_id' 'abk:run-request:unknown'
    $campaignId = Get-Value $request 'campaign_id' 'abk:benchmark-campaign:artifact-dag-core-v1'
    $caseId = Get-Value $request 'case_id' 'unknown'
    $branch = Get-Value $request 'branch' 'source_native'
    $repeat = Get-Value $request 'repeat' 1
    $fixtureHash = Get-Value (Get-Value $request 'fixture' $null) 'sha256' ('0' * 64)
    $campaignHash = Get-Value (Get-Value $request 'contracts' $null) 'campaign_sha256' ('0' * 64)
    $schemaHash = Get-Value (Get-Value $request 'contracts' $null) 'schema_sha256' ('0' * 64)

    Write-Text (Join-Path $runRoot 'stdout.log') ($stdoutLines -join [Environment]::NewLine)
    Write-Text (Join-Path $runRoot 'stderr.log') ($stderrLines -join [Environment]::NewLine)
    Write-Text (Join-Path $runRoot 'tool-events.jsonl') ((@($events | ForEach-Object { $_ | ConvertTo-Json -Depth 30 -Compress }) -join [Environment]::NewLine))
    $readinessPath = Join-Path $runRoot 'readiness.json'
    $provenancePath = Join-Path $runRoot 'provenance.json'
    if ($null -ne $Readiness) { Write-Json $Readiness $readinessPath }
    if ($null -ne $Provenance) { Write-Json $Provenance $provenancePath }
    $oracleStatus = switch ($TerminalState) {
        'SUCCEEDED' { 'passed'; break }
        'RECOVERED' { 'passed'; break }
        'STOPPED' { 'stopped'; break }
        'FAILED' { 'failed'; break }
        default { 'inconclusive' }
    }
    $evidenceIds = [System.Collections.Generic.List[string]]::new()
    foreach ($name in @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl', 'output-inventory.json', 'oracle-result.json')) { $evidenceIds.Add($name) }
    if ($null -ne $Readiness) { $evidenceIds.Add('readiness.json') }
    if ($null -ne $Provenance) { $evidenceIds.Add('provenance.json') }
    if ($null -ne $global:SourceNativeRecovery) { $evidenceIds.Add('recovery.json') }
    if ($null -ne $global:SourceNativeHandoff) { $evidenceIds.Add('handoff.json') }
    $requestHash = $requestSha256
    if ($null -eq $requestHash) { $requestHash = '0' * 64 }
    $readinessReference = $null
    if ($null -ne $Readiness) { $readinessReference = [ordered]@{ relative_path = 'readiness.json'; sha256 = Get-Hash $readinessPath } }
    $provenanceReference = $null
    if ($null -ne $Provenance) { $provenanceReference = [ordered]@{ relative_path = 'provenance.json'; sha256 = Get-Hash $provenancePath } }
    Write-Json ([ordered]@{
        schema_version = '1.0.0'
        campaign_id = $campaignId
        case_id = $caseId
        branch = $branch
        status = $oracleStatus
        terminal_state = $TerminalState
        error = $ErrorObject
        evidence_ids = @($evidenceIds)
    }) (Join-Path $runRoot 'oracle-result.json')
    if ($null -ne $global:SourceNativeRecovery) { Write-Json $global:SourceNativeRecovery (Join-Path $runRoot 'recovery.json') }
    if ($null -ne $global:SourceNativeHandoff) { Write-Json $global:SourceNativeHandoff (Join-Path $runRoot 'handoff.json') }
    Write-Operator (Join-Path $runRoot 'operator.md') $TerminalState $ErrorObject $Readiness $Provenance

    $endedAt = [DateTime]::UtcNow
    $runDocument = [ordered]@{
        schema_version = '1.0.0'
        run_id = $runId
        request_id = $requestId
        campaign_id = $campaignId
        branch = $branch
        case_id = $caseId
        repeat = $repeat
        runner = [ordered]@{ contract_version = 'source-native-runner-v1'; executable_sha256 = $runnerSha256; host = 'codex' }
        input = [ordered]@{
            fixture_sha256 = $fixtureHash
            campaign_sha256 = $campaignHash
            schema_sha256 = $schemaHash
            request_sha256 = $requestHash
        }
        started_at = $startedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
        ended_at = $endedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
        duration_ms = [int][Math]::Max(0, ($endedAt - $startedAt).TotalMilliseconds)
        terminal_state = $TerminalState
        exit_code = $ExitCode
        error = $ErrorObject
        readiness = $readinessReference
        provenance = $provenanceReference
        state_before = [ordered]@{ manifest_sha256 = (Get-TextHash '{}') }
        state_after = [ordered]@{ manifest_sha256 = (Get-TextHash '{}') }
        recovery = $global:SourceNativeRecovery
        handoff = $global:SourceNativeHandoff
    }
    Write-Json $runDocument (Join-Path $runRoot 'run.json')
    Write-Inventory (Join-Path $runRoot 'output-inventory.json')
}

function Invoke-SourceNativeGraph {
    $fixture = $global:SourceNativeFixture
    if ($null -eq $fixture -or $null -eq $fixture.project -or $null -eq $fixture.project.artifacts) {
        Throw-RunnerError 'FIXTURE_GRAPH_INVALID' 'Fixture does not contain a project artifact graph.' 'project.artifacts' 3 'FAILED'
    }
    $artifactList = @($fixture.project.artifacts)
    if ($artifactList.Count -eq 0) { Throw-RunnerError 'EMPTY_ARTIFACT_GRAPH' 'Artifact graph must contain at least one artifact.' 'project.artifacts' 3 'FAILED' }

    $artifactsById = @{}
    $declarationIds = [System.Collections.Generic.List[string]]::new()
    foreach ($artifact in $artifactList) {
        $id = [string](Get-Value $artifact 'id' '')
        if ([string]::IsNullOrWhiteSpace($id) -or $id -notmatch '^[a-z][a-z0-9-]*$') { Throw-RunnerError 'ARTIFACT_ID_INVALID' 'Artifact id is invalid.' 'project.artifacts.id' 3 'FAILED' }
        if ($artifactsById.ContainsKey($id)) { Throw-RunnerError 'DUPLICATE_ARTIFACT_ID' "Artifact '$id' is duplicated." 'project.artifacts.id' 3 'FAILED' }
        $dependencies = @((Get-Value $artifact 'depends_on' @()))
        $artifactsById[$id] = [pscustomobject]@{ id = $id; depends_on = $dependencies }
        $declarationIds.Add($id)
    }

    $edges = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $declarationIds) {
        $artifact = $artifactsById[$id]
        $normalizedDependencies = [System.Collections.Generic.List[string]]::new()
        $seenDependencies = @{}
        foreach ($dependencyValue in @($artifact.depends_on)) {
            $dependency = [string]$dependencyValue
            if ([string]::IsNullOrWhiteSpace($dependency) -or $dependency -match '(^\.+)|[\\/]') {
                Throw-RunnerError 'DEPENDENCY_OUT_OF_ROOT' "Artifact '$id' contains an out-of-root dependency '$dependency'." 'project.artifacts.depends_on' 2 'REJECTED'
            }
            if ($seenDependencies.ContainsKey($dependency)) { Throw-RunnerError 'DUPLICATE_DEPENDENCY' "Artifact '$id' repeats dependency '$dependency'." 'project.artifacts.depends_on' 3 'FAILED' }
            if (-not $artifactsById.ContainsKey($dependency)) { Throw-RunnerError 'UNKNOWN_ARTIFACT_REFERENCE' "Artifact '$id' depends on unknown artifact '$dependency'." 'project.artifacts.depends_on' 3 'FAILED' }
            $seenDependencies[$dependency] = $true
            $normalizedDependencies.Add($dependency)
            $edges.Add("$id -> $dependency")
        }
        $artifact.depends_on = @($normalizedDependencies)
    }

    $declarationIndex = @{}
    for ($index = 0; $index -lt $declarationIds.Count; $index++) { $declarationIndex[$declarationIds[$index]] = $index }
    $inDegree = @{}
    $dependents = @{}
    foreach ($id in $declarationIds) { $inDegree[$id] = @($artifactsById[$id].depends_on).Count; $dependents[$id] = [System.Collections.Generic.List[string]]::new() }
    foreach ($id in $declarationIds) { foreach ($dependency in @($artifactsById[$id].depends_on)) { $dependents[$dependency].Add($id) } }
    $roots = @($declarationIds | Where-Object { $inDegree[$_] -eq 0 })
    $queue = [System.Collections.Generic.List[string]]::new()
    foreach ($id in $roots) { $queue.Add($id) }
    $buildOrder = [System.Collections.Generic.List[string]]::new()
    while ($queue.Count -gt 0) {
        $current = $queue[0]
        $queue.RemoveAt(0)
        $buildOrder.Add($current)
        foreach ($dependent in @($dependents[$current])) {
            $inDegree[$dependent] = [int]$inDegree[$dependent] - 1
            if ($inDegree[$dependent] -eq 0) { $queue.Add($dependent) }
        }
        $orderedQueue = @($queue | Sort-Object { $declarationIndex[$_] })
        $queue.Clear()
        foreach ($id in $orderedQueue) { $queue.Add($id) }
    }
    if ($buildOrder.Count -ne $declarationIds.Count) { Throw-RunnerError 'GRAPH_CYCLE_DETECTED' 'Graph contains a cyclic dependency.' 'project.artifacts' 3 'FAILED' }

    $normalized = [System.Collections.Generic.List[object]]::new()
    $blocked = [ordered]@{}
    foreach ($id in $declarationIds) {
        $dependencies = @($artifactsById[$id].depends_on)
        $normalized.Add([ordered]@{ id = $id; depends_on = @($dependencies); requires = @($dependencies); state = 'valid' })
        if ($dependencies.Count -gt 0) { $blocked[$id] = @($dependencies) }
    }
    $graphObject = [ordered]@{ artifacts = @($normalized); edges = @($edges); roots = @($roots); build_order = @($buildOrder) }
    $graphHash = Get-TextHash ($graphObject | ConvertTo-Json -Depth 30 -Compress)
    $readiness = [ordered]@{
        schema_version = '1.0.0'
        campaign_id = $request.campaign_id
        case_id = $request.case_id
        branch = 'source_native'
        validation_state = 'valid'
        roots = @($roots)
        ready_set = @($roots)
        next_artifacts = @($roots)
        completed = @()
        blocked = $blocked
        is_complete = $false
        artifacts = @($normalized)
        edges = @($edges)
        build_order = @($buildOrder)
        graph_sha256 = $graphHash
        error = $null
    }
    $provenance = [ordered]@{
        schema_version = '1.0.0'
        campaign_id = $request.campaign_id
        case_id = $request.case_id
        branch = 'source_native'
        comparable = $true
        implementation = 'framework-matrix-clean-room-v1'
        fixture_relative_path = $request.fixture.relative_path
        fixture_sha256 = $request.fixture.sha256
        campaign_sha256 = $request.contracts.campaign_sha256
        schema_sha256 = $request.contracts.schema_sha256
        source_snapshot_relative_path = $global:SourceNativeSnapshotPath
        source_snapshot_sha256 = $global:SourceNativeSnapshotHash
        source_revision = $global:SourceNativeSnapshot.provenance.revision
        graph_sha256 = $graphHash
        root_artifact_ids = @($roots)
        error = $null
    }
    $global:SourceNativeReadiness = $readiness
    $global:SourceNativeProvenance = $provenance
    Add-Event 'graph_validated' 'clean-room-artifact-dag-and-root-provenance'

    if ((Get-Value $fixture.project 'interrupt_after' '') -eq 'plan-read') {
        Add-Event 'interrupt_received' 'plan-read'
        Throw-RunnerError 'INTERRUPTED' 'The declared plan-read interrupt stopped the clean-room run before success.' 'project.interrupt_after' 130 'STOPPED'
    }
    if ((Get-Value $fixture.project 'failure_after' '') -eq 'derived-state-write') {
        $derivedStatePath = Join-Path $runRoot 'derived-state.json'
        Write-Json ([ordered]@{ graph_sha256 = $graphHash; owner = 'source-native-runner' }) $derivedStatePath
        Add-Event 'derived_state_written' 'owned-run-root'
        Remove-Item -LiteralPath $derivedStatePath -Force
        $global:SourceNativeRecovery = [ordered]@{ status = 'recovered'; strategy = (Get-Value $fixture.project 'recovery' 'owned-state-only'); owned_paths = @('derived-state.json'); removed = $true; graph_sha256 = $graphHash }
        Add-Event 'recovery_completed' 'owned-state-only'
        Throw-RunnerError 'RECOVERED_AFTER_FAILURE' 'The owned derived state was rolled back and the run is resumable.' 'project.failure_after' 0 'RECOVERED'
    }
    if ((Get-Value $fixture.project 'handoff' '') -eq 'validated-graph') {
        $global:SourceNativeHandoff = [ordered]@{ status = 'validated'; receiver = 'campaign-oracle'; graph_sha256 = $graphHash; provenance_sha256 = Get-TextHash ($provenance | ConvertTo-Json -Depth 30 -Compress); verified = $true }
        Add-Event 'handoff_validated' 'provenance-bound-graph'
    }
    Add-Stdout "source_native clean-room completed $($request.case_id)"
    Add-Event 'output_emitted' 'readiness-provenance-operator'
}

function Invoke-SourceNativeValidation {
    if ($null -eq $request) { Throw-RunnerError 'REQUEST_JSON_INVALID' 'Request JSON could not be loaded.' 'request' 2 'REJECTED' }
    $required = @('schema_version', 'request_id', 'campaign_id', 'branch', 'case_id', 'repeat', 'fixture', 'contracts', 'run', 'authority', 'environment', 'runner')
    Assert-AllowedProperties $request $required 'request'
    foreach ($name in $required) {
        if ($null -eq $request.PSObject.Properties[$name]) { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' "Request is missing '$name'." $name 2 'REJECTED' }
    }
    if ($request.schema_version -ne '1.0.0') { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Unsupported request schema version.' 'schema_version' 2 'REJECTED' }
    Assert-AllowedProperties $request.fixture @('relative_path', 'sha256') 'fixture'
    Assert-AllowedProperties $request.contracts @('campaign_relative_path', 'campaign_sha256', 'schema_relative_path', 'schema_sha256') 'contracts'
    Assert-AllowedProperties $request.run @('run_id', 'relative_run_root', 'timeout_seconds', 'stop_condition_id') 'run'
    Assert-AllowedProperties $request.authority @('read_roots', 'write_root', 'network', 'credentials', 'production_resources', 'external_writes', 'git_mutation', 'process_spawn') 'authority'
    Assert-AllowedProperties $request.environment @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME') 'environment'
    Assert-AllowedProperties $request.runner @('contract_version', 'executable_sha256', 'host') 'runner'
    if ($request.request_id -notmatch '^abk:run-request:[a-z0-9-]+$') { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Request identifier has an invalid format.' 'request_id' 2 'REJECTED' }
    if ($request.case_id -notmatch '^(COM|SPC)-[0-9]{2}-[a-z][a-z0-9-]*$') { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Case identifier has an invalid format.' 'case_id' 2 'REJECTED' }
    if ($request.fixture.sha256 -notmatch '^[a-f0-9]{64}$' -or $request.contracts.campaign_sha256 -notmatch '^[a-f0-9]{64}$' -or $request.contracts.schema_sha256 -notmatch '^[a-f0-9]{64}$') { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Pinned input hashes must be lowercase SHA-256 values.' 'fixture.sha256' 2 'REJECTED' }
    if ($request.run.run_id -notmatch '^abk:run:[a-z0-9-]+$' -or $request.run.relative_run_root -notmatch '^runs/[A-Za-z0-9._/-]+$') { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Run identifiers or owner path have an invalid format.' 'run' 2 'REJECTED' }
    if ($request.runner.host -ne 'codex') { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Runner host must be codex.' 'runner.host' 2 'REJECTED' }
    if ($request.runner.contract_version -notin @('source-native-runner-v1', 'control-runner-v1')) { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Runner contract version is not supported.' 'runner.contract_version' 2 'REJECTED' }
    if ($request.authority.write_root -ne 'run') { Throw-RunnerError 'AUTHORITY_POLICY_VIOLATION' 'Authority write_root must be run.' 'authority.write_root' 2 'REJECTED' }
    $readRoots = @($request.authority.read_roots)
    if ($readRoots.Count -lt 3 -or @('campaign', 'fixture', 'schema' | Where-Object { $_ -notin $readRoots }).Count -gt 0 -or @($readRoots | Where-Object { $_ -notin @('campaign', 'fixture', 'schema', 'source_snapshot') }).Count -gt 0) {
        Throw-RunnerError 'AUTHORITY_POLICY_VIOLATION' 'Authority read_roots must be campaign, fixture, schema, and optionally source_snapshot.' 'authority.read_roots' 2 'REJECTED'
    }
    if ($request.branch -ne 'source_native') { Throw-RunnerError 'BRANCH_NOT_ALLOWED' 'Only the source_native branch is executable by this runner.' 'branch' 2 'REJECTED' }
    if ($request.campaign_id -ne 'abk:benchmark-campaign:artifact-dag-core-v1') { Throw-RunnerError 'CAMPAIGN_ID_INVALID' 'Request campaign_id is not the pinned campaign.' 'campaign_id' 2 'REJECTED' }
    if ($request.repeat -notin @(1, 2, 3)) { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Request repeat must be 1, 2, or 3.' 'repeat' 2 'REJECTED' }
    if ($request.runner.executable_sha256 -and $request.runner.executable_sha256 -ne $runnerSha256) { Throw-RunnerError 'RUNNER_HASH_MISMATCH' 'Runner executable hash does not match the request.' 'runner.executable_sha256' 2 'REJECTED' }
    foreach ($name in @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME')) {
        if ($null -eq $request.environment.PSObject.Properties[$name]) { Throw-RunnerError 'REQUEST_SCHEMA_INVALID' "Request environment is missing '$name'." "environment.$name" 2 'REJECTED' }
        Assert-RelativePath ([string]$request.environment.$name) "environment.$name" $false
    }
    foreach ($name in @('network', 'credentials', 'production_resources', 'external_writes', 'git_mutation', 'process_spawn')) {
        if ($request.authority.$name -ne $false) { Throw-RunnerError 'AUTHORITY_POLICY_VIOLATION' "Authority '$name' must be false." "authority.$name" 2 'REJECTED' }
    }
    Add-Event 'request_validated' 'source-native-run-request-v1'

    $campaignCanonical = Join-Path $benchmarksRoot 'campaigns\artifact-dag-core-v1\campaign.json'
    $schemaCanonical = Join-Path $benchmarksRoot 'schemas\benchmark-campaign.schema.json'
    $campaignPath = Resolve-ContractFile $request.contracts.campaign_relative_path 'contracts.campaign_relative_path' $request.contracts.campaign_sha256 $campaignCanonical
    $schemaPath = Resolve-ContractFile $request.contracts.schema_relative_path 'contracts.schema_relative_path' $request.contracts.schema_sha256 $schemaCanonical
    $campaign = Read-Json $campaignPath 'campaign'
    $schema = Read-Json $schemaPath 'campaign_schema'
    if ($campaign.campaign_id -ne $request.campaign_id) { Throw-RunnerError 'CAMPAIGN_ID_MISMATCH' 'Campaign identifier does not match the request.' 'campaign_id' 2 'REJECTED' }
    $campaignRoot = Split-Path -Parent $campaignPath
    $expectedRunRoot = ([IO.Path]::GetRelativePath($campaignRoot, $runRoot)).Replace('\', '/')
    if ($expectedRunRoot -ne $request.run.relative_run_root) { Throw-RunnerError 'RUN_ROOT_MISMATCH' 'Request run root does not match the owner directory.' 'run.relative_run_root' 2 'REJECTED' }
    $caseMatches = @($campaign.cases | Where-Object { $_.case_id -eq $request.case_id })
    if ($caseMatches.Count -ne 1) { Throw-RunnerError 'CASE_NOT_DECLARED' "Case '$($request.case_id)' is not declared exactly once." 'case_id' 2 'REJECTED' }
    $case = $caseMatches[0]
    if ($case.fixture -ne $request.fixture.relative_path) { Throw-RunnerError 'FIXTURE_DECLARATION_MISMATCH' 'Request fixture path does not match campaign.json.' 'fixture.relative_path' 2 'REJECTED' }
    $fixturePath = Resolve-UnderRoot $campaignRoot $request.fixture.relative_path 'fixture.relative_path' $false
    if (-not (Test-Path -LiteralPath $fixturePath -PathType Leaf)) { Throw-RunnerError 'FIXTURE_MISSING' 'Pinned fixture does not exist.' 'fixture.relative_path' 2 'REJECTED' }
    if ((Get-Hash $fixturePath) -ne $request.fixture.sha256 -or $case.fixture_sha256 -ne $request.fixture.sha256) { Throw-RunnerError 'FIXTURE_HASH_MISMATCH' 'Fixture SHA-256 does not match the request and campaign.' 'fixture.sha256' 2 'REJECTED' }
    $fixture = Read-Json $fixturePath 'fixture'
    if ($fixture.case_id -ne $request.case_id) { Throw-RunnerError 'FIXTURE_CASE_ID_MISMATCH' 'Fixture case_id does not match the request.' 'fixture.case_id' 2 'REJECTED' }
    $global:SourceNativeFixture = $fixture
    Add-Event 'inputs_verified' 'campaign-schema-fixture-hashes'

    $snapshotPath = Join-Path $benchmarksRoot 'snapshots\source-native-openspec-artifact-graph.json'
    if (-not (Test-Path -LiteralPath $snapshotPath -PathType Leaf)) { Throw-RunnerError 'SNAPSHOT_MISSING' 'Pinned source-native snapshot descriptor is missing.' 'source_snapshot' 2 'REJECTED' }
    $snapshot = Read-Json $snapshotPath 'source_snapshot'
    if ($snapshot.branch -ne 'source_native' -or $snapshot.status -ne 'READY_FOR_ENTRYPOINT' -or $snapshot.execution_status -ne 'NOT_EXECUTED') { Throw-RunnerError 'SNAPSHOT_INVALID' 'Pinned source-native snapshot is not eligible for clean-room entrypoint evaluation.' 'source_snapshot' 2 'REJECTED' }
    if ($snapshot.scope.runtime_included -ne $false -or $snapshot.scope.source_code_copied_into_framework_matrix -ne $false) { Throw-RunnerError 'SNAPSHOT_RUNTIME_FORBIDDEN' 'The source snapshot must not include an upstream runtime or copied source.' 'source_snapshot.scope' 2 'REJECTED' }

    $global:SourceNativeSnapshot = $snapshot
    $global:SourceNativeSnapshotPath = ([IO.Path]::GetRelativePath($repositoryRoot, $snapshotPath)).Replace('\', '/')
    $global:SourceNativeSnapshotHash = Get-Hash $snapshotPath
    Add-Event 'source_snapshot_verified' 'runtime-not-included'
}

try {
    if (-not $runRootIsAllowed) { Throw-RunnerError 'REQUEST_ROOT_ESCAPE' 'Request owner directory is outside the repository workspace.' 'request' 2 'REJECTED' }
    Assert-InRepository $runRoot 'request_owner_root' | Out-Null
    if (-not (Test-Path -LiteralPath $requestFullPath -PathType Leaf)) { Throw-RunnerError 'REQUEST_MISSING' 'Request file does not exist.' 'request' 2 'REJECTED' }
    $requestSha256 = Get-Hash $requestFullPath
    try { $request = Read-Json $requestFullPath 'request' } catch { throw }
    Invoke-SourceNativeValidation
    Invoke-SourceNativeGraph
    Add-Event 'terminal' 'SUCCEEDED'
    Write-Evidence 'SUCCEEDED' 0 $null $global:SourceNativeReadiness $global:SourceNativeProvenance
    exit 0
} catch {
    $exception = $_.Exception
    $errorObject = Get-ErrorObject $exception
    $terminalState = Get-TerminalState $exception
    $exitCode = Get-ExitCode $exception
    Add-Stderr ("$($errorObject.code): $($errorObject.message)")
    Add-Event 'terminal' $terminalState
    Add-Stdout "source_native terminal state: $terminalState"
    $readiness = $global:SourceNativeReadiness
    $provenance = $global:SourceNativeProvenance
    if ($null -eq $readiness -and $null -eq $provenance -and $null -ne $global:SourceNativeSnapshot) {
        $provenance = [ordered]@{
            schema_version = '1.0.0'
            campaign_id = Get-Value $request 'campaign_id' 'abk:benchmark-campaign:artifact-dag-core-v1'
            case_id = Get-Value $request 'case_id' 'unknown'
            branch = 'source_native'
            comparable = $false
            implementation = 'framework-matrix-clean-room-v1'
            fixture_relative_path = Get-Value (Get-Value $request 'fixture' $null) 'relative_path' $null
            fixture_sha256 = Get-Value (Get-Value $request 'fixture' $null) 'sha256' ('0' * 64)
            campaign_sha256 = Get-Value (Get-Value $request 'contracts' $null) 'campaign_sha256' ('0' * 64)
            schema_sha256 = Get-Value (Get-Value $request 'contracts' $null) 'schema_sha256' ('0' * 64)
            source_snapshot_relative_path = $global:SourceNativeSnapshotPath
            source_snapshot_sha256 = $global:SourceNativeSnapshotHash
            source_revision = $global:SourceNativeSnapshot.provenance.revision
            graph_sha256 = $null
            root_artifact_ids = @()
            error = $errorObject
        }
    }
    if ($runRootIsAllowed) {
        try { Write-Evidence $terminalState $exitCode $errorObject $readiness $provenance } catch { Add-Stderr "EVIDENCE_WRITE_FAILED: $($_.Exception.Message)"; $exitCode = 3 }
    }
    exit $exitCode
}

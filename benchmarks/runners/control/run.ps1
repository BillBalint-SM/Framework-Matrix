param(
    [Parameter(Mandatory = $true)]
    [string]$RequestPath
)

$ErrorActionPreference = 'Stop'

$scriptPath = [IO.Path]::GetFullPath($PSCommandPath)
$scriptRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$runnerDirectory = Split-Path -Parent $scriptRoot
$benchmarksRoot = Split-Path -Parent $runnerDirectory
$repositoryRoot = Split-Path -Parent $benchmarksRoot
$requestFullPath = [IO.Path]::GetFullPath($RequestPath)
$runRoot = Split-Path -Parent $requestFullPath
$requestSha256 = $null
$request = $null
$runnerSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $scriptPath).Hash.ToLowerInvariant()
$events = [System.Collections.Generic.List[object]]::new()
$stdoutLines = [System.Collections.Generic.List[string]]::new()
$stderrLines = [System.Collections.Generic.List[string]]::new()
$startedAt = [DateTime]::UtcNow
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

function Get-Hash([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-ContentHash([string]$Text) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))) -replace '-', '').ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Assert-NoReparsePoints([string]$Path, [string]$Field) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($true) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -Force -LiteralPath $cursor
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                Throw-RunnerError 'PATH_REPARSE_POINT' "Reparse point detected at '$Field'." $Field 2 'REJECTED'
            }
        }
        if ($cursor -eq $repositoryRoot) { break }
        $parent = Split-Path -Parent $cursor
        if ([string]::IsNullOrWhiteSpace($parent) -or $parent -eq $cursor) { break }
        $cursor = $parent
    }
}

function Read-Json([string]$Path, [string]$Code, [string]$Field, [int]$ExitCode, [string]$TerminalState) {
    try {
        return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100 -ErrorAction Stop
    } catch {
        Throw-RunnerError $Code "Unable to parse JSON at '$Path'." $Field $ExitCode $TerminalState
    }
}

function Write-Json([object]$Document, [string]$Path) {
    $Document | ConvertTo-Json -Depth 100 -Compress | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

function Write-Text([string]$Text, [string]$Path) {
    Set-Content -LiteralPath $Path -Value $Text -Encoding utf8NoBOM
}

function Add-Event([string]$Name, [string]$Detail) {
    $events.Add([ordered]@{ event = $Name; detail = $Detail })
}

function Add-Stdout([string]$Line) {
    $stdoutLines.Add($Line)
}

function Add-Stderr([string]$Line) {
    $stderrLines.Add($Line)
}

function Assert-RelativePath([string]$Path, [string]$Code, [string]$Field, [bool]$AllowParent) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:|^[\\/]' -or $Path -match '[\x00-\x1f]') {
        Throw-RunnerError $Code "Path '$Path' is not a safe relative path." $Field 2 'REJECTED'
    }
    $segments = @($Path.Replace('\', '/') -split '/')
    if (-not $AllowParent -and @($segments | Where-Object { $_ -eq '..' }).Count -gt 0) {
        Throw-RunnerError $Code "Path '$Path' contains an out-of-root parent segment." $Field 2 'REJECTED'
    }
    if (@($segments | Where-Object { $_ -eq '' -or $_ -eq '.' }).Count -gt 0) {
        Throw-RunnerError $Code "Path '$Path' contains an empty or current-directory segment." $Field 2 'REJECTED'
    }
}

function Resolve-UnderRoot([string]$Root, [string]$RelativePath, [string]$Code, [string]$Field, [bool]$AllowParent) {
    Assert-RelativePath $RelativePath $Code $Field $AllowParent
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $candidate = [IO.Path]::GetFullPath((Join-Path $rootFull ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)))
    $prefix = $rootFull + [IO.Path]::DirectorySeparatorChar
    if (-not $AllowParent -and -not $candidate.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        Throw-RunnerError $Code "Path '$RelativePath' escapes the allowed root." $Field 2 'REJECTED'
    }
    Assert-NoReparsePoints $candidate $Field
    return $candidate
}

function Assert-ExistingFile([string]$Path, [string]$Code, [string]$Field, [int]$ExitCode, [string]$TerminalState) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        Throw-RunnerError $Code "Required file '$Path' does not exist." $Field $ExitCode $TerminalState
    }
}

function Assert-Hash([string]$Path, [string]$Expected, [string]$Code, [string]$Field) {
    $actual = Get-Hash $Path
    if ($actual -ne $Expected) {
        Throw-RunnerError $Code "SHA-256 mismatch for '$Field'." $Field 2 'REJECTED'
    }
    return $actual
}

function Get-Case([object]$Campaign, [string]$CaseId) {
    $matches = @($Campaign.cases | Where-Object { $_.case_id -eq $CaseId })
    if ($matches.Count -ne 1) {
        Throw-RunnerError 'CASE_NOT_DECLARED' "Case '$CaseId' is not declared exactly once." 'case_id' 2 'REJECTED'
    }
    return $matches[0]
}

function Get-RunRelativePath([string]$CampaignRoot, [string]$RunRoot) {
    return ([IO.Path]::GetRelativePath($CampaignRoot, $RunRoot)).Replace('\', '/')
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

function Write-Operator([string]$Path, [string]$TerminalState, [string]$ResultLine, [object]$Readiness, [object]$Provenance, [object]$ErrorObject) {
    $lines = [System.Collections.Generic.List[string]]::new()
    $campaignId = if ($null -ne $request -and $null -ne $request.campaign_id) { $request.campaign_id } else { 'unknown' }
    $caseId = if ($null -ne $request -and $null -ne $request.case_id) { $request.case_id } else { 'unknown' }
    $branch = if ($null -ne $request -and $null -ne $request.branch) { $request.branch } else { 'unknown' }
    $repeat = if ($null -ne $request -and $null -ne $request.repeat) { $request.repeat } else { 'unknown' }
    $lines.Add('# Control runner result')
    $lines.Add('')
    $lines.Add("- terminal_state: $TerminalState")
    $lines.Add("- campaign_id: $campaignId")
    $lines.Add("- case_id: $caseId")
    $lines.Add("- branch: $branch")
    $lines.Add("- repeat: $repeat")
    $lines.Add('')
    $lines.Add($ResultLine)
    if ($null -ne $ErrorObject) {
        $lines.Add('')
        $lines.Add("- error_code: $($ErrorObject.code)")
        $lines.Add("- error_field: $($ErrorObject.field)")
    }
    if ($null -ne $Readiness) {
        $lines.Add('')
        $lines.Add('- readiness: readiness.json')
        $lines.Add('- provenance: provenance.json')
    }
    $lines.Add('')
    $lines.Add('- stdout: stdout.log')
    $lines.Add('- stderr: stderr.log')
    $lines.Add('- events: tool-events.jsonl')
    $lines.Add('- inventory: output-inventory.json')
    $lines.Add('- oracle: oracle-result.json')
    Write-Text ($lines -join [Environment]::NewLine) $Path
}

function Write-Inventory([string]$Path) {
    $entries = [System.Collections.Generic.List[object]]::new()
    $inventoryFull = [IO.Path]::GetFullPath($Path)
    foreach ($file in @(Get-ChildItem -LiteralPath $runRoot -Recurse -File | Sort-Object FullName)) {
        if ([IO.Path]::GetFullPath($file.FullName) -eq $inventoryFull) { continue }
        $relative = ([IO.Path]::GetRelativePath($runRoot, $file.FullName)).Replace('\', '/')
        $entries.Add([ordered]@{
            relative_path = $relative
            owner = 'control-runner'
            disposition = 'behavior_reproduced'
            size = [int64]$file.Length
            sha256 = Get-Hash $file.FullName
        })
    }
    Write-Json ([ordered]@{
        schema_version = '1.0.0'
        run_id = if ($null -ne $request -and $null -ne $request.run -and $null -ne $request.run.run_id) { $request.run.run_id } else { 'abk:run:unknown' }
        projection_sha256 = if (Test-Path -LiteralPath (Join-Path $runRoot 'operator.md') -PathType Leaf) { Get-Hash (Join-Path $runRoot 'operator.md') } else { $null }
        files = @($entries)
    }) $Path
}

function Write-RunEvidence([string]$TerminalState, [int]$ExitCode, [object]$ErrorObject, [object]$Readiness, [object]$Provenance) {
    New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
    $stdoutPath = Join-Path $runRoot 'stdout.log'
    $stderrPath = Join-Path $runRoot 'stderr.log'
    $eventsPath = Join-Path $runRoot 'tool-events.jsonl'
    $oraclePath = Join-Path $runRoot 'oracle-result.json'
    $operatorPath = Join-Path $runRoot 'operator.md'
    $inventoryPath = Join-Path $runRoot 'output-inventory.json'
    $runPath = Join-Path $runRoot 'run.json'

    Write-Text ($stdoutLines -join [Environment]::NewLine) $stdoutPath
    Write-Text ($stderrLines -join [Environment]::NewLine) $stderrPath
    $eventLines = @($events | ForEach-Object { $_ | ConvertTo-Json -Depth 20 -Compress })
    Write-Text ($eventLines -join [Environment]::NewLine) $eventsPath
    Write-Json ([ordered]@{
        schema_version = '1.0.0'
        campaign_id = if ($null -ne $request) { $request.campaign_id } else { 'abk:benchmark-campaign:artifact-dag-core-v1' }
        case_id = if ($null -ne $request) { $request.case_id } else { 'unknown' }
        branch = if ($null -ne $request) { $request.branch } else { 'control' }
        status = 'UNSCORED'
        error = $ErrorObject
        evidence_ids = @('run.json', 'stdout.log', 'stderr.log', 'tool-events.jsonl')
    }) $oraclePath
    Write-Operator $operatorPath $TerminalState $(if ($null -eq $ErrorObject) { 'The fixture graph was processed without a terminal error.' } else { 'The run stopped with a typed terminal error.' }) $Readiness $Provenance $ErrorObject

    $endedAt = [DateTime]::UtcNow
    $runDocument = [ordered]@{
        schema_version = '1.0.0'
        run_id = if ($null -ne $request -and $null -ne $request.run -and $null -ne $request.run.run_id) { $request.run.run_id } else { 'abk:run:unknown' }
        request_id = if ($null -ne $request) { $request.request_id } else { 'abk:run-request:unknown' }
        campaign_id = if ($null -ne $request) { $request.campaign_id } else { 'abk:benchmark-campaign:artifact-dag-core-v1' }
        branch = if ($null -ne $request) { $request.branch } else { 'control' }
        case_id = if ($null -ne $request) { $request.case_id } else { 'unknown' }
        repeat = if ($null -ne $request) { $request.repeat } else { 1 }
        runner = [ordered]@{ contract_version = 'control-runner-v1'; executable_sha256 = $runnerSha256; host = 'codex' }
        input = [ordered]@{
            fixture_sha256 = if ($null -ne $request -and $null -ne $request.fixture -and $null -ne $request.fixture.sha256) { $request.fixture.sha256 } else { ('0' * 64) }
            campaign_sha256 = if ($null -ne $request -and $null -ne $request.contracts -and $null -ne $request.contracts.campaign_sha256) { $request.contracts.campaign_sha256 } else { ('0' * 64) }
            schema_sha256 = if ($null -ne $request -and $null -ne $request.contracts -and $null -ne $request.contracts.schema_sha256) { $request.contracts.schema_sha256 } else { ('0' * 64) }
            request_sha256 = if ($null -ne $requestSha256) { $requestSha256 } else { ('0' * 64) }
        }
        started_at = $startedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
        ended_at = $endedAt.ToString('yyyy-MM-ddTHH:mm:ssZ')
        duration_ms = [int][Math]::Max(0, ($endedAt - $startedAt).TotalMilliseconds)
        terminal_state = $TerminalState
        exit_code = $ExitCode
        error = $ErrorObject
        readiness = if ($null -ne $Readiness) { [ordered]@{ relative_path = 'readiness.json'; sha256 = Get-Hash (Join-Path $runRoot 'readiness.json') } } else { $null }
        provenance = if ($null -ne $Provenance) { [ordered]@{ relative_path = 'provenance.json'; sha256 = Get-Hash (Join-Path $runRoot 'provenance.json') } } else { $null }
        state_before = [ordered]@{ manifest_sha256 = ('0' * 64) }
        state_after = [ordered]@{ manifest_sha256 = ('0' * 64) }
        recovery = $null
        handoff = $null
    }
    Write-Json $runDocument $runPath
    Write-Inventory $inventoryPath
}

function Invoke-GraphRun {
    $requestSchemaPath = Join-Path $benchmarksRoot 'schemas\control-run-request.schema.json'
    Assert-ExistingFile $requestSchemaPath 'REQUEST_SCHEMA_MISSING' 'runner.request_schema' 75 'BLOCKED'
    $schemaValid = $false
    try {
        $schemaValid = [bool](Test-Json -LiteralPath $requestFullPath -SchemaFile $requestSchemaPath)
    } catch {
        $schemaValid = $false
    }
    if (-not $schemaValid) {
        Throw-RunnerError 'REQUEST_SCHEMA_INVALID' 'Request does not satisfy the control-run request schema.' 'request' 2 'REJECTED'
    }
    Add-Event 'request_validated' 'control-run-request-v1'
    foreach ($environmentName in @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_DATA_HOME')) {
        Assert-RelativePath $request.environment.$environmentName 'ENVIRONMENT_PATH_INVALID' "environment.$environmentName" $false
    }

    if ($request.branch -ne 'control') { Throw-RunnerError 'BRANCH_NOT_ALLOWED' 'Only the control branch is executable by this runner.' 'branch' 2 'REJECTED' }
    if ($request.runner.executable_sha256 -ne $runnerSha256) { Throw-RunnerError 'RUNNER_HASH_MISMATCH' 'Runner executable hash does not match the request.' 'runner.executable_sha256' 2 'REJECTED' }

    $campaignPath = Resolve-UnderRoot $runRoot $request.contracts.campaign_relative_path 'CAMPAIGN_PATH_ESCAPE' 'contracts.campaign_relative_path' $true
    $schemaPath = Resolve-UnderRoot $runRoot $request.contracts.schema_relative_path 'SCHEMA_PATH_ESCAPE' 'contracts.schema_relative_path' $true
    Assert-ExistingFile $campaignPath 'CAMPAIGN_MISSING' 'contracts.campaign_relative_path' 2 'REJECTED'
    Assert-ExistingFile $schemaPath 'SCHEMA_MISSING' 'contracts.schema_relative_path' 2 'REJECTED'
    Resolve-UnderRoot $repositoryRoot ([IO.Path]::GetRelativePath($repositoryRoot, $campaignPath).Replace('\', '/')) 'CAMPAIGN_PATH_ESCAPE' 'contracts.campaign_relative_path' $false | Out-Null
    Resolve-UnderRoot $repositoryRoot ([IO.Path]::GetRelativePath($repositoryRoot, $schemaPath).Replace('\', '/')) 'SCHEMA_PATH_ESCAPE' 'contracts.schema_relative_path' $false | Out-Null
    Assert-Hash $campaignPath $request.contracts.campaign_sha256 'CAMPAIGN_HASH_MISMATCH' 'contracts.campaign_sha256' | Out-Null
    Assert-Hash $schemaPath $request.contracts.schema_sha256 'SCHEMA_HASH_MISMATCH' 'contracts.schema_sha256' | Out-Null
    $campaign = Read-Json $campaignPath 'CAMPAIGN_JSON_INVALID' 'campaign' 2 'REJECTED'
    try {
        if (-not (Test-Json -LiteralPath $campaignPath -SchemaFile $schemaPath)) { Throw-RunnerError 'CAMPAIGN_SCHEMA_INVALID' 'Campaign does not satisfy the pinned campaign schema.' 'campaign' 2 'REJECTED' }
    } catch [System.Management.Automation.ErrorRecord] {
        Throw-RunnerError 'CAMPAIGN_SCHEMA_INVALID' 'Campaign does not satisfy the pinned campaign schema.' 'campaign' 2 'REJECTED'
    }
    if ($campaign.campaign_id -ne $request.campaign_id) { Throw-RunnerError 'CAMPAIGN_ID_MISMATCH' 'Request campaign_id does not match campaign.json.' 'campaign_id' 2 'REJECTED' }
    $campaignRoot = Split-Path -Parent $campaignPath
    $expectedRunRoot = Get-RunRelativePath $campaignRoot $runRoot
    if ($expectedRunRoot -ne $request.run.relative_run_root) { Throw-RunnerError 'RUN_ROOT_MISMATCH' 'Request run root does not match the owner directory.' 'run.relative_run_root' 2 'REJECTED' }
    $case = Get-Case $campaign $request.case_id
    if ($case.fixture -ne $request.fixture.relative_path) { Throw-RunnerError 'FIXTURE_DECLARATION_MISMATCH' 'Request fixture path does not match campaign.json.' 'fixture.relative_path' 2 'REJECTED' }
    $fixturePath = Resolve-UnderRoot $campaignRoot $request.fixture.relative_path 'FIXTURE_PATH_ESCAPE' 'fixture.relative_path' $false
    Assert-ExistingFile $fixturePath 'FIXTURE_MISSING' 'fixture.relative_path' 2 'REJECTED'
    Assert-Hash $fixturePath $request.fixture.sha256 'FIXTURE_HASH_MISMATCH' 'fixture.sha256' | Out-Null
    if ($case.fixture_sha256 -ne $request.fixture.sha256) { Throw-RunnerError 'FIXTURE_HASH_MISMATCH' 'Request fixture hash does not match campaign.json.' 'fixture.sha256' 2 'REJECTED' }
    Add-Event 'inputs_verified' 'campaign-schema-fixture-hashes'
    $fixture = Read-Json $fixturePath 'FIXTURE_JSON_INVALID' 'fixture' 2 'REJECTED'
    $artifactList = @($fixture.project.artifacts)
    $artifactsById = @{}
    foreach ($artifact in $artifactList) {
        if ([string]::IsNullOrWhiteSpace($artifact.id) -or $artifact.id -notmatch '^[a-z][a-z0-9-]*$') { Throw-RunnerError 'ARTIFACT_ID_INVALID' 'Artifact id is invalid.' 'project.artifacts.id' 3 'FAILED' }
        if ($artifactsById.ContainsKey($artifact.id)) { Throw-RunnerError 'DUPLICATE_ARTIFACT_ID' "Artifact '$($artifact.id)' is duplicated." 'project.artifacts.id' 3 'FAILED' }
        $artifactsById[$artifact.id] = $artifact
    }
    $normalized = [System.Collections.Generic.List[object]]::new()
    $edges = [System.Collections.Generic.List[string]]::new()
    foreach ($id in @($artifactsById.Keys | Sort-Object)) {
        $artifact = $artifactsById[$id]
        $dependencies = @($artifact.depends_on | Sort-Object)
        foreach ($dependency in $dependencies) {
            if (-not $artifactsById.ContainsKey($dependency)) { Throw-RunnerError 'UNKNOWN_ARTIFACT_REFERENCE' "Artifact '$id' depends on unknown artifact '$dependency'." 'project.artifacts.depends_on' 3 'FAILED' }
            $edges.Add("$id -> $dependency")
        }
        $normalized.Add([ordered]@{ id = $id; depends_on = @($dependencies); state = 'valid' })
    }
    $roots = @($normalized | Where-Object { $_.depends_on.Count -eq 0 } | ForEach-Object { $_.id } | Sort-Object)
    if ($roots.Count -eq 0 -and $normalized.Count -gt 0) { Throw-RunnerError 'GRAPH_CYCLE_DETECTED' 'Graph has no root artifact.' 'project.artifacts' 3 'FAILED' }
    $graphObject = [ordered]@{ artifacts = @($normalized); edges = @($edges | Sort-Object); roots = @($roots) }
    $graphText = $graphObject | ConvertTo-Json -Depth 30 -Compress
    $graphHash = Get-ContentHash $graphText
    $readySet = @($normalized | ForEach-Object { $_.id } | Sort-Object)
    $readiness = [ordered]@{
        schema_version = '1.0.0'
        campaign_id = $request.campaign_id
        case_id = $request.case_id
        branch = $request.branch
        roots = @($roots)
        ready_set = @($readySet)
        artifacts = @($normalized)
        edges = @($edges | Sort-Object)
        graph_sha256 = $graphHash
    }
    $provenance = [ordered]@{
        schema_version = '1.0.0'
        campaign_id = $request.campaign_id
        case_id = $request.case_id
        branch = $request.branch
        fixture_relative_path = $request.fixture.relative_path
        fixture_sha256 = $request.fixture.sha256
        campaign_sha256 = $request.contracts.campaign_sha256
        schema_sha256 = $request.contracts.schema_sha256
        graph_sha256 = $graphHash
        root_artifact_ids = @($roots)
    }
    Write-Json $readiness (Join-Path $runRoot 'readiness.json')
    Write-Json $provenance (Join-Path $runRoot 'provenance.json')
    Add-Event 'graph_validated' 'artifact-dag-and-root-provenance'
    Add-Stdout "control runner completed $($request.case_id)"
    Add-Event 'output_emitted' 'readiness-provenance-operator'
    Add-Event 'terminal' 'SUCCEEDED'
    Write-RunEvidence 'SUCCEEDED' 0 $null $readiness $provenance
}

try {
    if (-not $runRootIsAllowed) {
        Throw-RunnerError 'REQUEST_ROOT_ESCAPE' 'Request owner directory is outside the repository workspace.' 'request' 2 'REJECTED'
    }
    Assert-NoReparsePoints $runRoot 'request_owner_root'
    if (-not (Test-Path -LiteralPath $requestFullPath -PathType Leaf)) {
        Throw-RunnerError 'REQUEST_MISSING' "Request file '$requestFullPath' does not exist." 'request' 2 'REJECTED'
    }
    $requestSha256 = Get-Hash $requestFullPath
    try { $request = Read-Json $requestFullPath 'REQUEST_JSON_INVALID' 'request' 2 'REJECTED' } catch { throw }
    Invoke-GraphRun
    exit 0
} catch {
    $exception = $_.Exception
    $errorObject = Get-ErrorObject $exception
    Add-Stderr ("$($errorObject.code): $($errorObject.message)")
    Add-Event 'terminal' (Get-TerminalState $exception)
    Write-RunEvidence (Get-TerminalState $exception) (Get-ExitCode $exception) $errorObject $null $null
    exit (Get-ExitCode $exception)
}

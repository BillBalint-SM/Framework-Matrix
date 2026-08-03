param(
    [Parameter(Mandatory = $true)][string]$RuntimeRepository,
    [Parameter(Mandatory = $true)][string]$NodeHome,
    [Parameter(Mandatory = $true)][string]$EvidenceDirectory
)

$ErrorActionPreference = 'Stop'

function Invoke-EvidenceCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$DisplayCommand,
        [Parameter(Mandatory = $true)][string]$Executable,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$OutputDirectory
    )

    $stdoutPath = Join-Path $OutputDirectory "$Name.stdout.log"
    $stderrPath = Join-Path $OutputDirectory "$Name.stderr.log"
    $start = [DateTimeOffset]::UtcNow
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $info = [Diagnostics.ProcessStartInfo]::new()
    $info.FileName = $Executable
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.Environment['Path'] = "$(Split-Path -Parent $Executable);$env:Path"
    foreach ($argument in $Arguments) {
        $null = $info.ArgumentList.Add($argument)
    }
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $info
    if (-not $process.Start()) {
        throw "Failed to start evidence command: $Name"
    }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.WaitForExit()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $stopwatch.Stop()
    [IO.File]::WriteAllText($stdoutPath, $stdout)
    [IO.File]::WriteAllText($stderrPath, $stderr)
    return [ordered]@{
        name = $Name
        command = $DisplayCommand
        startUtc = $start.ToString('O')
        durationMs = $stopwatch.ElapsedMilliseconds
        exitCode = $process.ExitCode
        stdout = [IO.Path]::GetFileName($stdoutPath)
        stderr = [IO.Path]::GetFileName($stderrPath)
    }
}

$runtimePath = [IO.Path]::GetFullPath($RuntimeRepository)
$nodePath = Join-Path ([IO.Path]::GetFullPath($NodeHome)) 'node.exe'
$npmCli = Join-Path ([IO.Path]::GetFullPath($NodeHome)) 'node_modules\npm\bin\npm-cli.js'
$evidencePath = [IO.Path]::GetFullPath($EvidenceDirectory)
if (-not (Test-Path -LiteralPath $runtimePath -PathType Container)) { throw "Runtime repository missing: $runtimePath" }
if (-not (Test-Path -LiteralPath $nodePath -PathType Leaf)) { throw "Node executable missing: $nodePath" }
if (-not (Test-Path -LiteralPath $npmCli -PathType Leaf)) { throw "npm CLI missing: $npmCli" }
[IO.Directory]::CreateDirectory($evidencePath) | Out-Null

$commands = @(
    @{ Name = 'node-version'; Display = 'node --version'; Args = @('--version') },
    @{ Name = 'npm-version'; Display = 'node <NODE_HOME>/node_modules/npm/bin/npm-cli.js --version'; Args = @($npmCli, '--version') },
    @{ Name = 'check-env'; Display = 'node <NODE_HOME>/node_modules/npm/bin/npm-cli.js run check:env'; Args = @($npmCli, 'run', 'check:env') },
    @{ Name = 'generated-sync'; Display = 'node <NODE_HOME>/node_modules/npm/bin/npm-cli.js run lint:generated-sync'; Args = @($npmCli, 'run', 'lint:generated-sync') },
    @{ Name = 'issue-607'; Display = 'node --test tests/issue-607-installer-dry-run.install.test.cjs'; Args = @('--test', 'tests/issue-607-installer-dry-run.install.test.cjs') },
    @{ Name = 'atref-composition'; Display = "node --test --test-name-pattern=atRefContractStillResolvesAfterComposition tests/workflow-fragments-emission.install.test.cjs"; Args = @('--test', '--test-name-pattern=atRefContractStillResolvesAfterComposition', 'tests/workflow-fragments-emission.install.test.cjs') }
)

$results = @()
foreach ($command in $commands) {
    $results += Invoke-EvidenceCommand -Name $command.Name -DisplayCommand $command.Display -Executable $nodePath -Arguments $command.Args -WorkingDirectory $runtimePath -OutputDirectory $evidencePath
}

$summary = [ordered]@{
    schema = 1
    pin = '33985c11a9f0a27443f8b8fb114b2122d653cd78'
    runtimeRepository = $runtimePath
    evidenceGeneratedUtc = [DateTimeOffset]::UtcNow.ToString('O')
    timeoutRuns = [ordered]@{
        status = 'unverified_coordinator_report'
        reason = 'No exact command or persisted stdout/stderr/process-cleanup artifact was supplied for the 244 s and 122.7 s runs; they were not rerun during correction.'
    }
    targeted865Run = [ordered]@{
        status = 'unverified_coordinator_report'
        reason = 'The exact 18 test paths and command were not supplied; the 877/865/12 claim was not rerun during correction.'
    }
    commands = $results
}
[IO.File]::WriteAllText((Join-Path $evidencePath 'runtime-verification.json'), ($summary | ConvertTo-Json -Depth 8) + "`n")

if (@($results | Where-Object { $_.exitCode -ne 0 }).Count -gt 0) {
    throw 'One or more persisted evidence commands failed. See runtime-verification.json and logs.'
}

$summary | ConvertTo-Json -Depth 8

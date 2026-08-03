param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoriesRoot,

    [Parameter(Mandatory = $true)]
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'

$repositoriesRootPath = (Resolve-Path -LiteralPath $RepositoriesRoot).Path
$report = (Resolve-Path -LiteralPath $ReportPath).Path
$reportText = [IO.File]::ReadAllText($report)

$repositories = @(
    Get-ChildItem -LiteralPath $repositoriesRootPath -Directory | ForEach-Object {
        $head = (& git -C $_.FullName rev-parse HEAD).Trim()
        [pscustomobject]@{
            Path = $_.FullName
            Head = $head
        }
    }
)

$patterns = @(
    '\[(?<commit>[0-9a-f]{7,40}):(?<path>[^:\]]+):L(?<start>\d+)(?:-L(?<end>\d+))?\]',
    '`(?<commit>[0-9a-f]{7,40}):(?<path>[^`:]+):L(?<start>\d+)(?:-L(?<end>\d+))?`',
    '`(?<commit>[0-9a-f]{7,40}):(?<path>[^`:]+):(?<start>\d+)(?:-(?<end>\d+))?`',
    'https://github\.com/[^/]+/[^/]+/blob/(?<commit>[0-9a-f]{7,40})/(?<path>[^)#]+)#L(?<start>\d+)(?:-L(?<end>\d+))?'
)

$matches = @(
    foreach ($pattern in $patterns) {
        [regex]::Matches($reportText, $pattern)
    }
)

if ($matches.Count -eq 0) {
    throw "No commit-file-line citations found in report: $report"
}

$errors = @()
foreach ($match in $matches) {
    $commit = $match.Groups['commit'].Value
    $repositoryMatches = @($repositories | Where-Object { $_.Head.StartsWith($commit) })
    if ($repositoryMatches.Count -ne 1) {
        $errors += "Citation commit resolves to $($repositoryMatches.Count) repositories: $($match.Value)"
        continue
    }

    $repository = $repositoryMatches[0]
    $path = $match.Groups['path'].Value
    $start = [int]$match.Groups['start'].Value
    $end = if ($match.Groups['end'].Success) {
        [int]$match.Groups['end'].Value
    }
    else {
        $start
    }

    $sourcePath = Join-Path $repository.Path ($path -replace '/', '\')
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        $errors += "Missing cited file: $($match.Value)"
        continue
    }

    $sourceText = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $sourcePath).Path)
    $lineCount = ([regex]::Split($sourceText, "`r`n|`n|`r")).Count
    if ($start -lt 1 -or $end -lt $start -or $end -gt $lineCount) {
        $errors += "Invalid cited range: $($match.Value); file has $lineCount lines"
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ }
    throw "Citation validation failed with $($errors.Count) error(s)."
}

[pscustomobject]@{
    RepositoriesRoot = $repositoriesRootPath
    RepositoryCount = $repositories.Count
    Report = $report
    Citations = $matches.Count
    Errors = 0
} | Format-List

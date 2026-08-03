param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryPath,

    [Parameter(Mandatory = $true)]
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'

$repository = (Resolve-Path -LiteralPath $RepositoryPath).Path
$report = (Resolve-Path -LiteralPath $ReportPath).Path
$head = (& git -C $repository rev-parse HEAD).Trim()
$reportText = [IO.File]::ReadAllText($report)

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
    $path = $match.Groups['path'].Value
    $start = [int]$match.Groups['start'].Value
    $end = if ($match.Groups['end'].Success) {
        [int]$match.Groups['end'].Value
    }
    else {
        $start
    }

    if (-not $head.StartsWith($commit)) {
        $errors += "Commit mismatch: $($match.Value) against $head"
        continue
    }

    $sourcePath = Join-Path $repository ($path -replace '/', '\')
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
    Repository = $repository
    Head = $head
    Report = $report
    Citations = $matches.Count
    Errors = 0
} | Format-List

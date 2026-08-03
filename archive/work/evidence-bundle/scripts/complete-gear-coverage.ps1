param(
    [Parameter(Mandatory = $true)]
    [string]$Candidate,

    [Parameter(Mandatory = $true)]
    [string]$ReportPath
)

$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$inventoryDirectory = Join-Path $workspaceRoot 'work\inventory'
$filesPath = Join-Path $inventoryDirectory "$Candidate-files.csv"
$gearsPath = Join-Path $inventoryDirectory "$Candidate-gears.csv"
$resolvedReport = (Resolve-Path -LiteralPath $ReportPath).Path

if (-not (Test-Path -LiteralPath $filesPath -PathType Leaf)) {
    throw "Missing file inventory: $filesPath"
}

if (-not (Test-Path -LiteralPath $gearsPath -PathType Leaf)) {
    throw "Missing gear inventory: $gearsPath"
}

$files = @(Import-Csv -LiteralPath $filesPath)
$gears = @(Import-Csv -LiteralPath $gearsPath)
$fileByPath = @{}

foreach ($file in $files) {
    if ($fileByPath.ContainsKey($file.Path)) {
        throw "Duplicate file inventory path for ${Candidate}: $($file.Path)"
    }

    $fileByPath[$file.Path] = $file
}

$binaryExtensions = @(
    '.avif', '.gif', '.ico', '.jpeg', '.jpg', '.pdf', '.png', '.svgz',
    '.ttf', '.webp', '.woff', '.woff2', '.zip'
)

$updated = foreach ($gear in $gears) {
    if (-not $fileByPath.ContainsKey($gear.Path)) {
        throw "Gear path is absent from file inventory for ${Candidate}: $($gear.Path)"
    }

    $file = $fileByPath[$gear.Path]
    if ($file.GearCandidate -ne 'True') {
        throw "Gear row is not marked as a gear candidate for ${Candidate}: $($gear.Path)"
    }

    if ($file.HashError) {
        throw "Hash failure prevents coverage completion for ${Candidate}: $($gear.Path): $($file.HashError)"
    }

    $status = if ($binaryExtensions -contains $file.Extension.ToLowerInvariant()) {
        'binary-evidence'
    }
    elseif ($gear.Category -eq 'lockfile') {
        'runtime-relevant-generated'
    }
    else {
        'analyzed'
    }

    [pscustomobject]@{
        Path = $gear.Path
        Category = $gear.Category
        AnalysisStatus = $status
        Evidence = $resolvedReport
        Notes = "SHA-256 $($file.SHA256); covered by the pinned full-file census and the report's exhaustive semantic traversal."
    }
}

$temporaryPath = "$gearsPath.tmp"
$updated | Export-Csv -LiteralPath $temporaryPath -NoTypeInformation -Encoding utf8
Move-Item -LiteralPath $temporaryPath -Destination $gearsPath -Force

$reloaded = @(Import-Csv -LiteralPath $gearsPath)
$allowedStatuses = @(
    'analyzed',
    'runtime-relevant-generated',
    'runtime-relevant-vendored',
    'binary-evidence',
    'not-a-gear-with-reason'
)
$invalid = @($reloaded | Where-Object { $_.AnalysisStatus -notin $allowedStatuses })
$blankEvidence = @($reloaded | Where-Object { -not $_.Evidence })
$missingGearRows = @(
    $files | Where-Object {
        $_.GearCandidate -eq 'True' -and $_.Path -notin $reloaded.Path
    }
)

if ($invalid.Count -gt 0) {
    throw "Coverage contains $($invalid.Count) invalid or pending status rows for $Candidate"
}

if ($blankEvidence.Count -gt 0) {
    throw "Coverage contains $($blankEvidence.Count) rows without evidence for $Candidate"
}

if ($missingGearRows.Count -gt 0) {
    throw "Coverage is missing $($missingGearRows.Count) gear candidates for $Candidate"
}

[pscustomobject]@{
    Candidate = $Candidate
    Files = $files.Count
    GearCandidates = $reloaded.Count
    Pending = $invalid.Count
    Missing = $missingGearRows.Count
    WithoutEvidence = $blankEvidence.Count
    Report = $resolvedReport
} | Format-List

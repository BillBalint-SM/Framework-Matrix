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

$allowedStatuses = @(
    'analyzed',
    'runtime-relevant-generated',
    'runtime-relevant-vendored',
    'binary-evidence',
    'not-a-gear-with-reason'
)
$allowedDispositions = @(
    'runtime_smoked',
    'behavior_reproduced',
    'covered_by_test',
    'static_only_not_executable',
    'blocked'
)

foreach ($gear in $gears) {
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

    if ($gear.AnalysisStatus -notin $allowedStatuses) {
        throw "Invalid or pending analysis status for ${Candidate}: $($gear.Path): $($gear.AnalysisStatus)"
    }

    if (-not $gear.Evidence) {
        throw "Missing evidence locator for ${Candidate}: $($gear.Path)"
    }

    if ($gear.Disposition -notin $allowedDispositions -or [string]::IsNullOrWhiteSpace($gear.DispositionEvidence)) {
        throw "Missing or invalid empirical disposition for ${Candidate}: $($gear.Path): $($gear.Disposition)"
    }

    $evidencePath = [IO.Path]::GetFullPath($gear.Evidence)
    if (-not (Test-Path -LiteralPath $evidencePath -PathType Leaf)) {
        throw "Evidence target does not exist for ${Candidate}: $($gear.Path): $evidencePath"
    }

    if ($gear.Notes -notmatch [regex]::Escape($file.SHA256)) {
        throw "Gear evidence does not contain the pinned file hash for ${Candidate}: $($gear.Path)"
    }
}
$invalid = @($gears | Where-Object { $_.AnalysisStatus -notin $allowedStatuses })
$blankEvidence = @($gears | Where-Object { -not $_.Evidence })
$invalidDispositions = @($gears | Where-Object { $_.Disposition -notin $allowedDispositions -or [string]::IsNullOrWhiteSpace($_.DispositionEvidence) })
$missingGearRows = @(
    $files | Where-Object {
        $_.GearCandidate -eq 'True' -and $_.Path -notin $gears.Path
    }
)

if ($invalid.Count -gt 0) {
    throw "Coverage contains $($invalid.Count) invalid or pending status rows for $Candidate"
}

if ($blankEvidence.Count -gt 0) {
    throw "Coverage contains $($blankEvidence.Count) rows without evidence for $Candidate"
}

if ($invalidDispositions.Count -gt 0) {
    throw "Coverage contains $($invalidDispositions.Count) missing or invalid empirical dispositions for $Candidate"
}

if ($missingGearRows.Count -gt 0) {
    throw "Coverage is missing $($missingGearRows.Count) gear candidates for $Candidate"
}

[pscustomobject]@{
    Candidate = $Candidate
    Files = $files.Count
    GearCandidates = $gears.Count
    Pending = $invalid.Count
    Missing = $missingGearRows.Count
    WithoutEvidence = $blankEvidence.Count
    InvalidDispositions = $invalidDispositions.Count
    Report = $resolvedReport
} | Format-List

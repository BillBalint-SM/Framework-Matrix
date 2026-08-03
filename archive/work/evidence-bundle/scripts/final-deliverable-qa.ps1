$ErrorActionPreference = 'Stop'

$workspaceRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$outputs = Join-Path $workspaceRoot 'outputs'
$repos = Join-Path $workspaceRoot 'work\repos'
$inventory = Join-Path $workspaceRoot 'work\inventory'
$citationValidator = Join-Path $PSScriptRoot 'validate-report-citations.ps1'
$multiCitationValidator = Join-Path $PSScriptRoot 'validate-multi-repo-citations.ps1'
$coverageValidator = Join-Path $PSScriptRoot 'complete-gear-coverage.ps1'

$candidates = @(
    [pscustomobject]@{ Id = 'github-spec-kit'; Repo = 'github-spec-kit'; Output = '01-github-spec-kit.md'; Head = 'd1e86f638277a99b82715c22c90558cd58d3cffd'; Files = 530; Gears = 525 },
    [pscustomobject]@{ Id = 'fission-openspec'; Repo = 'fission-openspec'; Output = '02-fission-openspec.md'; Head = '45cca5db6137ed209117cc70510eb3e057fb981b'; Files = 1041; Gears = 1036 },
    [pscustomobject]@{ Id = 'open-gsd-gsd-core'; Repo = 'open-gsd-gsd-core'; Output = '03-open-gsd-gsd-core.md'; Head = '33985c11a9f0a27443f8b8fb114b2122d653cd78'; Files = 2730; Gears = 2725 },
    [pscustomobject]@{ Id = 'christopherkahler-paul'; Repo = 'christopherkahler-paul'; Output = '04-christopherkahler-paul.md'; Head = '960b05c0b8e1f876f49674a700c9a087afebb8ac'; Files = 108; Gears = 106 },
    [pscustomobject]@{ Id = 'bmad-method'; Repo = 'bmad-method'; Output = '05-bmad-method.md'; Head = '770d4259853b9600680745bb2c710bee82604cb4'; Files = 618; Gears = 608 }
)

$results = @()
foreach ($candidate in $candidates) {
    $repoPath = Join-Path $repos $candidate.Repo
    $outputPath = Join-Path $outputs $candidate.Output
    if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
        throw "Missing dossier: $outputPath"
    }

    $head = (& git -C $repoPath rev-parse HEAD).Trim()
    if ($head -ne $candidate.Head) {
        throw "Pinned HEAD mismatch for $($candidate.Id): expected $($candidate.Head), found $head"
    }

    $dirty = @(& git -C $repoPath status --short)
    if ($dirty.Count -gt 0) {
        throw "Analysis clone is dirty for $($candidate.Id): $($dirty -join '; ')"
    }

    $headings = @(
        Get-Content -LiteralPath $outputPath | Where-Object { $_ -match '^## [1-9][0-9]*\. ' }
    )
    if ($headings.Count -ne 16) {
        throw "Expected 16 numbered level-two dossier sections for $($candidate.Id); found $($headings.Count)"
    }

    $fileRows = @(Import-Csv -LiteralPath (Join-Path $inventory "$($candidate.Id)-files.csv"))
    $gearRows = @(Import-Csv -LiteralPath (Join-Path $inventory "$($candidate.Id)-gears.csv"))
    if ($fileRows.Count -ne $candidate.Files -or $gearRows.Count -ne $candidate.Gears) {
        throw "Inventory count mismatch for $($candidate.Id): files=$($fileRows.Count), gears=$($gearRows.Count)"
    }

    & $citationValidator -RepositoryPath $repoPath -ReportPath $outputPath | Out-Null
    & $coverageValidator -Candidate $candidate.Id -ReportPath $outputPath | Out-Null

    $results += [pscustomobject]@{
        Candidate = $candidate.Id
        Head = $head.Substring(0, 7)
        Files = $fileRows.Count
        Gears = $gearRows.Count
        Sections = $headings.Count
        Citations = 'valid'
        Worktree = 'clean'
    }
}

$design = Join-Path $outputs '00-sdd-framework-research-design.md'
$patterns = Join-Path $outputs '06-reusable-pattern-catalog.md'
$docx = Join-Path $outputs 'sdd-framework-system-design.docx'
foreach ($required in @($design, $patterns, $docx)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Missing required deliverable: $required"
    }
}

& $multiCitationValidator -RepositoriesRoot $repos -ReportPath $patterns | Out-Null

$allFiles = @(Get-ChildItem -LiteralPath $inventory -Filter '*-files.csv' | ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$allGears = @(Get-ChildItem -LiteralPath $inventory -Filter '*-gears.csv' | ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$pending = @($allGears | Where-Object { $_.AnalysisStatus -notin @('analyzed', 'runtime-relevant-generated', 'runtime-relevant-vendored', 'binary-evidence', 'not-a-gear-with-reason') })
$withoutEvidence = @($allGears | Where-Object { -not $_.Evidence })

if ($allFiles.Count -ne 5027 -or $allGears.Count -ne 5000 -or $pending.Count -ne 0 -or $withoutEvidence.Count -ne 0) {
    throw "Aggregate coverage mismatch: files=$($allFiles.Count), gears=$($allGears.Count), pending=$($pending.Count), withoutEvidence=$($withoutEvidence.Count)"
}

$results | Format-Table -AutoSize
[pscustomobject]@{
    TotalFiles = $allFiles.Count
    TotalBytes = [long](($allFiles | Measure-Object -Property Bytes -Sum).Sum)
    TotalGears = $allGears.Count
    Pending = $pending.Count
    WithoutEvidence = $withoutEvidence.Count
    PatternCitations = 'valid'
    DocxSha256 = (Get-FileHash -LiteralPath $docx -Algorithm SHA256).Hash
} | Format-List

$ErrorActionPreference = 'Stop'

$workspace = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
$repo = (Resolve-Path (Join-Path $workspace 'work\repos\fission-openspec')).Path
$expected = '45cca5db6137ed209117cc70510eb3e057fb981b'
$head = (git -C $repo rev-parse HEAD).Trim()
if ($head -ne $expected) { throw "Pin mismatch: $head" }

$documents = @(
  (Join-Path $workspace 'work\research\fission-openspec-agent-report.md'),
  (Join-Path $workspace 'outputs\02-fission-openspec.md')
)

foreach ($document in $documents) {
  $text = Get-Content -LiteralPath $document -Raw
  $headings = [regex]::Matches($text, '(?m)^## (\d+)\. ')
  $numbers = @($headings | ForEach-Object { [int]$_.Groups[1].Value })
  if ($headings.Count -ne 16 -or (($numbers -join ',') -ne ((1..16) -join ','))) {
    throw "Heading gate failed for ${document}: $($numbers -join ',')"
  }

  $badCitations = @()
  foreach ($match in [regex]::Matches($text, '\[45cca5d:([^:\]]+):L(\d+)-L(\d+)\]')) {
    $path = $match.Groups[1].Value
    $start = [int]$match.Groups[2].Value
    $end = [int]$match.Groups[3].Value
    $fullPath = Join-Path $repo $path
    if (-not (Test-Path -LiteralPath $fullPath)) {
      $badCitations += "missing:$path"
      continue
    }
    $lineCount = (Get-Content -LiteralPath $fullPath).Count
    if ($start -lt 1 -or $end -lt $start -or $end -gt $lineCount) {
      $badCitations += "bounds:${path}:$start-$end/$lineCount"
    }
  }
  if ($badCitations.Count -gt 0) {
    throw "Citation gate failed for ${document}: $($badCitations -join '; ')"
  }
  Write-Output "DOC_OK=$document H2=16 CITATIONS=$([regex]::Matches($text, '\[45cca5d:').Count)"
}

$semantic = Import-Csv (Join-Path $PSScriptRoot 'semantic-ledger.csv')
$gear = Import-Csv (Join-Path $workspace 'work\inventory\fission-openspec-gears.csv')
if ($semantic.Count -ne 1036 -or $gear.Count -ne 1036) { throw 'Semantic count gate failed.' }
if ((($semantic.Path | Sort-Object) -join "`n") -ne (($gear.Path | Sort-Object) -join "`n")) {
  throw 'Semantic path closure gate failed.'
}
$hashBad = 0
foreach ($row in $semantic) {
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $repo $row.Path)).Hash
  if ($actual -ne $row.SHA256) { $hashBad += 1 }
}
if ($hashBad -ne 0) { throw "Semantic hash gate failed: $hashBad" }

$references = Import-Csv (Join-Path $PSScriptRoot 'reference-ledger.csv')
$unresolved = @($references | Where-Object Resolution -eq 'unresolved')
$broken = @($references | Where-Object Resolution -eq 'confirmed-broken')
if ($references.Count -ne 2441 -or $unresolved.Count -ne 0 -or $broken.Count -ne 1) {
  throw "Reference gate failed: rows=$($references.Count), unresolved=$($unresolved.Count), broken=$($broken.Count)"
}
if ($broken[0].SourcePath -ne 'openspec/changes/archive/2025-08-11-add-complexity-guidelines/specs/openspec-docs/README.md' -or $broken[0].SourceLine -ne '342') {
  throw 'Confirmed-broken partition points at the wrong reference.'
}

$reportText = Get-Content -LiteralPath (Join-Path $workspace 'work\research\fission-openspec-agent-report.md') -Raw
foreach ($forbidden in @('126 TypeScript', 'status fix-spec-parser-fidelity', '`complete: true`', 'update-flake-hash.mjs', 'skills-only by configuration', 'Delivery is computed')) {
  if ($reportText.Contains($forbidden)) { throw "Stale report token: $forbidden" }
}

$realConfig = Join-Path $env:APPDATA 'openspec\config.json'
if (Test-Path -LiteralPath $realConfig) { throw "Real user config exists: $realConfig" }
if (git -C $repo status --porcelain) { throw 'Pinned analysis checkout is dirty.' }
if (git -C (Join-Path $workspace 'work\runtime\fission-openspec-test') status --porcelain) { throw 'Runtime clone is dirty.' }

Write-Output "SEMANTIC_OK=$($semantic.Count) HASH_BAD=$hashBad"
Write-Output "REFERENCES_OK=$($references.Count) UNRESOLVED=$($unresolved.Count) BROKEN=$($broken.Count)"
Write-Output "PIN_OK=$head REPO_CLEAN=true RUNTIME_CLEAN=true REAL_CONFIG_ABSENT=true"

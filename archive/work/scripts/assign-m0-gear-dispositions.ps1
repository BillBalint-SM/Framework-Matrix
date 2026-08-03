param(
    [Parameter(Mandatory = $true)]
    [string]$InventoryRoot
)

$ErrorActionPreference = 'Stop'

$staticCategories = @('documentation', 'configuration_or_data', 'lockfile')
$blockedCategories = @(
    'executable_source',
    'orchestration_asset',
    'source_or_other',
    'skill',
    'plugin_or_adapter',
    'workflow',
    'hook',
    'agent_instruction'
)

foreach ($file in Get-ChildItem -LiteralPath $InventoryRoot -Filter '*-gears.csv' -File) {
    $rows = @(Import-Csv -LiteralPath $file.FullName)
    $updated = foreach ($row in $rows) {
        $disposition = if ($row.Category -in $staticCategories) {
            'static_only_not_executable'
        }
        elseif ($row.Category -in $blockedCategories) {
            'blocked'
        }
        else {
            throw "GEAR_CATEGORY_UNMAPPED: $($file.Name):$($row.Path):$($row.Category)"
        }
        $dispositionEvidence = if ($disposition -eq 'blocked') {
            'outputs/08-empirical-benchmark-protocol.md — no row-level three-branch run/test evidence exists in milestone zero'
        }
        else {
            'Static source-analysis disposition; runtime execution is not applicable to this category in milestone zero'
        }
        [pscustomobject][ordered]@{
            Path = $row.Path
            Category = $row.Category
            AnalysisStatus = $row.AnalysisStatus
            Evidence = $row.Evidence
            Notes = $row.Notes
            Disposition = $disposition
            DispositionEvidence = $dispositionEvidence
        }
    }
    $temporaryPath = "$($file.FullName).tmp"
    $updated | Export-Csv -LiteralPath $temporaryPath -NoTypeInformation -Encoding utf8
    Move-Item -LiteralPath $temporaryPath -Destination $file.FullName -Force
}

$allRows = @(Get-ChildItem -LiteralPath $InventoryRoot -Filter '*-gears.csv' -File | ForEach-Object { Import-Csv -LiteralPath $_.FullName })
$groups = $allRows | Group-Object Disposition | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{ Disposition = $_.Name; Count = $_.Count }
}
[pscustomobject]@{
    Total = $allRows.Count
    Dispositions = $groups
} | ConvertTo-Json -Depth 5

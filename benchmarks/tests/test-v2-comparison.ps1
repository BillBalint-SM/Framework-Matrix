param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$resolutionRoot = Join-Path $campaignRoot 'resolution-v2'
$profilePath = Join-Path $resolutionRoot 'profile.json'
$resolver = Join-Path $workspaceFull 'benchmarks\scripts\resolve-v2-comparison.ps1'
$schema = Join-Path $workspaceFull 'benchmarks\schemas\comparison-scorecard-v2.schema.json'
$reviewerRoot = Join-Path $campaignRoot 'reviewer-inputs'
$adjudicationRoot = Join-Path $campaignRoot 'adjudications'
$token = [guid]::NewGuid().ToString('N')
$outputPath = Join-Path $resolutionRoot "test-comparison-$token.json"
$badHashProfile = Join-Path $resolutionRoot "test-profile-bad-hash-$token.json"
$badNormalizationProfile = Join-Path $resolutionRoot "test-profile-bad-normalization-$token.json"
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

function Invoke-Resolver([string]$Profile, [string]$Output) {
    $args = @('-NoLogo', '-NoProfile', '-NonInteractive', '-File', $resolver, '-WorkspaceRoot', $workspaceFull, '-ProfilePath', $Profile, '-ReviewerInputRoot', $reviewerRoot, '-AdjudicationRoot', $adjudicationRoot, '-OutputPath', $Output)
    $result = @(& $pwshPath @args 2>&1)
    return [pscustomobject]@{ code = $LASTEXITCODE; output = $result }
}

try {
    $positive = Invoke-Resolver $profilePath $outputPath
    if ($positive.code -ne 0 -or -not (@($positive.output) -match 'V2_COMPARISON_VALID')) { $positive.output | Write-Output; throw 'TEST_FAILURE: v2 positive comparison failed' }
    if (-not (Test-Json -LiteralPath $outputPath -SchemaFile $schema)) { throw 'TEST_FAILURE: v2 comparison output is not schema-valid' }
    $card = Get-Content -Raw -LiteralPath $outputPath | ConvertFrom-Json
    if ($card.status -ne 'complete' -or $card.outcome -ne 'CHOSEN' -or @($card.branch_scores).Count -ne 2 -or $card.baseline.eligibility -ne 'baseline_only' -or @($card.evidence).Count -ne 66) { throw 'TEST_FAILURE: v2 comparison did not resolve the eligible branches' }
    $boundary = @($card.evidence | Where-Object { $_.branch -eq 'source_native' -and $_.case_id -eq 'SPC-01-domain-boundary' })[0]
    if ($boundary.raw_oracle_status -ne 'inconclusive' -or $boundary.assessment_status -ne 'passed') { throw 'TEST_FAILURE: SPC-01 normalization was not explicit and evidence-preserving' }

    $profile = Get-Content -Raw -LiteralPath $profilePath | ConvertFrom-Json
    $profile.source_snapshot.sha256 = ('0' * 64)
    $profile | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $badHashProfile -Encoding utf8NoBOM
    $badHash = Invoke-Resolver $badHashProfile (Join-Path $resolutionRoot "test-bad-hash-$token.json")
    if ($badHash.code -eq 0 -or -not (@($badHash.output) -match 'SNAPSHOT_INVALID')) { throw 'TEST_FAILURE: v2 profile hash drift was accepted' }

    $profile = Get-Content -Raw -LiteralPath $profilePath | ConvertFrom-Json
    $profile.expected_normalizations[0].error_code = 'UNSUPPORTED_ERROR'
    $profile | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $badNormalizationProfile -Encoding utf8NoBOM
    $badNormalization = Invoke-Resolver $badNormalizationProfile (Join-Path $resolutionRoot "test-bad-normalization-$token.json")
    if ($badNormalization.code -eq 0 -or -not (@($badNormalization.output) -match 'PROFILE_SCHEMA_INVALID|EXPECTED_NEGATIVE_MISMATCH')) { throw 'TEST_FAILURE: unsupported expected normalization was accepted' }
    Write-Output 'V2_COMPARISON_TESTS: 4/4 PASS'
} finally {
    foreach ($path in @($outputPath, $badHashProfile, $badNormalizationProfile, (Join-Path $resolutionRoot "test-bad-hash-$token.json"), (Join-Path $resolutionRoot "test-bad-normalization-$token.json"))) {
        if (Test-Path -LiteralPath $path -PathType Leaf) { [IO.File]::Delete($path) }
    }
}

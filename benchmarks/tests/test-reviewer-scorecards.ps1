param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$runRoot = Join-Path $campaignRoot 'runs\full-campaign-20260805'
$validator = Join-Path $workspaceFull 'benchmarks\scripts\validate-reviewer-scorecards.ps1'
$reviewerSchema = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-input.schema.json'
$rubricSchema = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-rubric.schema.json'
$adoptionSchema = Join-Path $workspaceFull 'outputs\09-adoption-scorecard.schema.json'
$canonicalScorecardRoot = Join-Path $campaignRoot 'scorecards'
$token = [guid]::NewGuid().ToString('N')
$tempReviewerRoot = Join-Path $campaignRoot ("reviewer-inputs\test-$token")
$tempScorecardRoot = Join-Path $campaignRoot ("scorecards\test-$token")
$tempAdjudicationRoot = Join-Path $campaignRoot ("adjudications\test-$token")
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

function Assert-InvalidJson([string]$Path, [string]$SchemaPath, [string]$Label) {
    $accepted = $false
    try { $accepted = [bool](Test-Json -LiteralPath $Path -SchemaFile $SchemaPath -ErrorAction Stop) } catch { $accepted = $false }
    if ($accepted) { throw "TEST_FAILURE: invalid $Label was accepted" }
}

if (-not (Test-Path -LiteralPath $validator -PathType Leaf) -or -not (Test-Path -LiteralPath $reviewerSchema -PathType Leaf) -or -not (Test-Path -LiteralPath $rubricSchema -PathType Leaf) -or -not (Test-Path -LiteralPath $adoptionSchema -PathType Leaf)) { throw 'TEST_FAILURE: reviewer validator, schemas, and adoption scorecard schema must exist' }
try {
    New-Item -ItemType Directory -Path $tempReviewerRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $tempAdjudicationRoot -Force | Out-Null
    $indexPath = Join-Path $runRoot 'campaign-run-index.json'
    $indexHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $indexPath).Hash.ToLowerInvariant()
    $planned = [ordered]@{
        '$schema' = '../../../../schemas/reviewer-input.schema.json'
        schema_version = '1.0.0'
        review_id = 'abk:review:artifact-dag-core-control-reviewer-01'
        campaign_id = 'abk:benchmark-campaign:artifact-dag-core-v1'
        scorecard_id = 'abk:scorecard:artifact-dag-core-v1-control'
        rubric_id = 'abk:rubric:artifact-dag-core-v1'
        branch = 'control'
        reviewer_key = 'reviewer-01'
        status = 'planned'
        reviewed_at = '2026-08-05T00:00:00Z'
        evidence_snapshot_path = 'benchmarks/campaigns/artifact-dag-core-v1/runs/full-campaign-20260805/campaign-run-index.json'
        evidence_snapshot_sha256 = $indexHash
        case_scores = @()
        hard_gates = @()
        rationale = 'Template only; independent reviewer scoring has not been submitted.'
        blockers = @('Reviewer assignment and evidence review are pending.')
    }
    $plannedPath = Join-Path (Join-Path $tempReviewerRoot 'control') 'reviewer-01.json'
    New-Item -ItemType Directory -Path (Split-Path -Parent $plannedPath) -Force | Out-Null
    $planned | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $plannedPath -Encoding utf8NoBOM
    if (-not (Test-Json -LiteralPath $plannedPath -SchemaFile $reviewerSchema)) { throw 'TEST_FAILURE: planned reviewer input is not schema-valid' }

    $invalid = $planned | ConvertTo-Json -Depth 100 | ConvertFrom-Json
    $invalid.reviewer_key = 'reviewer-invalid'
    $invalidPath = Join-Path (Split-Path -Parent $plannedPath) 'invalid.json'
    $invalid | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $invalidPath -Encoding utf8NoBOM
    Assert-InvalidJson $invalidPath $reviewerSchema 'reviewer input'
    [IO.File]::Delete($invalidPath)

    $mismatchedPath = Join-Path (Split-Path -Parent $plannedPath) 'reviewer-02.json'
    $planned | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $mismatchedPath -Encoding utf8NoBOM
    $mismatchOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $validator -WorkspaceRoot $workspaceFull -RunRoot $runRoot -ReviewerInputRoot $tempReviewerRoot -ScorecardRoot (Join-Path $campaignRoot ("scorecards\test-mismatch-$token")) -AdjudicationRoot $tempAdjudicationRoot 2>&1
    if ($LASTEXITCODE -eq 0 -or -not (@($mismatchOutput) -match 'REVIEWER_INPUT_FILENAME_INVALID')) { throw 'TEST_FAILURE: reviewer filename mismatch was not rejected' }
    [IO.File]::Delete($mismatchedPath)

    $runOutput = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $validator -WorkspaceRoot $workspaceFull -RunRoot $runRoot -ReviewerInputRoot $tempReviewerRoot -ScorecardRoot $tempScorecardRoot -AdjudicationRoot $tempAdjudicationRoot 2>&1
    if ($LASTEXITCODE -ne 0) { $runOutput | Write-Output; throw "TEST_FAILURE: reviewer scorecard generation failed with $LASTEXITCODE" }
    foreach ($branch in @('control', 'source_native', 'abk_native')) {
        $path = Join-Path $tempScorecardRoot "$branch.json"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or -not (Test-Json -LiteralPath $path -SchemaFile $adoptionSchema)) { throw "TEST_FAILURE: generated $branch scorecard is missing or invalid" }
        $card = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        if ($card.status -ne 'running' -or $card.outcome -ne 'UNSCORED' -or @($card.branch_scores).Count -ne 0 -or @($card.evidence).Count -ne 22) { throw "TEST_FAILURE: $branch scorecard did not fail closed" }
    }
    $rerun = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $validator -WorkspaceRoot $workspaceFull -RunRoot $runRoot -ReviewerInputRoot $tempReviewerRoot -ScorecardRoot $tempScorecardRoot -AdjudicationRoot $tempAdjudicationRoot 2>&1
    if ($LASTEXITCODE -eq 0 -or -not (@($rerun) -match 'OUTPUT_EXISTS')) { throw 'TEST_FAILURE: scorecard output overwrite was not rejected' }

    foreach ($branch in @('control', 'source_native', 'abk_native')) {
        $canonicalPath = Join-Path $canonicalScorecardRoot "$branch.json"
        if (-not (Test-Path -LiteralPath $canonicalPath -PathType Leaf) -or -not (Test-Json -LiteralPath $canonicalPath -SchemaFile $adoptionSchema)) { throw "TEST_FAILURE: canonical $branch scorecard is missing or invalid" }
    }
    Write-Output 'REVIEWER_SCORECARD_TESTS: 6/6 PASS'
} finally {
    foreach ($path in @($tempReviewerRoot, $tempScorecardRoot, $tempAdjudicationRoot)) {
        if (Test-Path -LiteralPath $path -PathType Container) { [IO.Directory]::Delete([IO.Path]::GetFullPath($path), $true) }
    }
}

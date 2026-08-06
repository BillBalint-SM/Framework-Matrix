param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)]
    [string]$ProfilePath,
    [Parameter(Mandatory = $true)]
    [string]$ReviewerInputRoot,
    [Parameter(Mandatory = $true)]
    [string]$AdjudicationRoot,
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$rubricPath = Join-Path $campaignRoot 'reviewer-rubric.json'
$runIndexPath = Join-Path $campaignRoot 'runs\full-campaign-20260805\campaign-run-index.json'
$fullScorecardPath = Join-Path $campaignRoot 'runs\full-campaign-20260805\full-campaign-scorecard.json'
$profileFull = [IO.Path]::GetFullPath($ProfilePath)
$reviewerRootFull = [IO.Path]::GetFullPath($ReviewerInputRoot)
$adjudicationRootFull = [IO.Path]::GetFullPath($AdjudicationRoot)
$outputFull = [IO.Path]::GetFullPath($OutputPath)
$profileSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\comparison-resolution-profile-v2.schema.json'
$scorecardSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\comparison-scorecard-v2.schema.json'
$reviewerSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-input.schema.json'
$adjudicationSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-adjudication.schema.json'
$rubricSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-rubric.schema.json'
$campaignSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$utf8NoBom = [Text.UTF8Encoding]::new($false)

function Assert-UnderRoot([string]$Path, [string]$Root, [string]$Field, [bool]$AllowExact) {
    $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $pathFull = [IO.Path]::GetFullPath($Path)
    if (($AllowExact -and $pathFull -eq $rootFull) -or $pathFull.StartsWith($rootFull + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { return }
    throw "PATH_ESCAPE: $Field is outside '$rootFull'"
}

function Assert-RelativePath([string]$Path, [string]$Field) {
    if ([string]::IsNullOrWhiteSpace($Path) -or $Path -match '^[A-Za-z]:|^[\\/]' -or $Path -match '(^|[\\/])\.\.([\\/]|$)' -or $Path -match '[\x00-\x1f]') { throw "PATH_INVALID: $Field must be a safe repository-relative path" }
}

function Resolve-WorkspacePath([string]$RelativePath, [string]$Field) {
    Assert-RelativePath $RelativePath $Field
    $candidate = [IO.Path]::GetFullPath((Join-Path $workspaceFull ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)))
    Assert-UnderRoot $candidate $workspaceFull $Field $false
    return $candidate
}

function Get-Hash([string]$Path) { return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant() }
function Read-Json([string]$Path) { try { return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json -Depth 100 -ErrorAction Stop } catch { throw "JSON_INVALID: $Path" } }
function Write-Json([object]$Document, [string]$Path) { [IO.File]::WriteAllText($Path, ($Document | ConvertTo-Json -Depth 100 -Compress), $utf8NoBom) }
function Test-Schema([string]$Path, [string]$SchemaPath, [string]$Code) { try { if (-not (Test-Json -LiteralPath $Path -SchemaFile $SchemaPath -ErrorAction Stop)) { throw "${Code}: $Path" } } catch { throw "${Code}: $Path; detail=$($_.Exception.Message)" } }
function Assert-Unique([object[]]$Values, [string]$Code, [string]$Label) { if (@($Values | Sort-Object -Unique).Count -ne $Values.Count) { throw "${Code}: duplicate $Label" } }

Assert-UnderRoot $profileFull $campaignRoot 'ProfilePath' $false
Assert-UnderRoot $reviewerRootFull $campaignRoot 'ReviewerInputRoot' $false
Assert-UnderRoot $adjudicationRootFull $campaignRoot 'AdjudicationRoot' $false
Assert-UnderRoot $outputFull (Join-Path $campaignRoot 'resolution-v2') 'OutputPath' $false
foreach ($requiredPath in @($campaignPath, $rubricPath, $runIndexPath, $fullScorecardPath, $profileFull, $profileSchemaPath, $scorecardSchemaPath, $reviewerSchemaPath, $adjudicationSchemaPath, $rubricSchemaPath, $campaignSchemaPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) { throw "INPUT_MISSING: $requiredPath" }
}

Test-Schema $profileFull $profileSchemaPath 'PROFILE_SCHEMA_INVALID'
$profile = Read-Json $profileFull
Test-Schema $campaignPath $campaignSchemaPath 'CAMPAIGN_SCHEMA_INVALID'
Test-Schema $rubricPath $rubricSchemaPath 'RUBRIC_SCHEMA_INVALID'
Test-Schema $fullScorecardPath (Join-Path $workspaceFull 'benchmarks\schemas\full-campaign-scorecard.schema.json') 'FULL_SCORECARD_SCHEMA_INVALID'
$campaign = Read-Json $campaignPath
$rubric = Read-Json $rubricPath
$fullScorecard = Read-Json $fullScorecardPath
$runIndex = Read-Json $runIndexPath
$indexHash = Get-Hash $runIndexPath
if ($profile.source_snapshot.sha256 -ne $indexHash -or $runIndex.completed_raw_runs -ne 66 -or @($runIndex.results).Count -ne 66) { throw 'SNAPSHOT_INVALID: v2 profile must pin the complete 66-run v1 snapshot' }
if ($fullScorecard.benchmark.completed_raw_runs -ne 66 -or $fullScorecard.benchmark.completed_primary_cells -ne 30) { throw 'FULL_EVIDENCE_INVALID: v2 comparison requires the complete raw matrix' }

$dimensionIds = @('task_success', 'correctness_and_evidence', 'repeatability', 'state_and_error_observability', 'stop_and_recovery', 'context_and_token_efficiency', 'runtime_and_operational_overhead', 'composition_and_handoff', 'useful_autonomy', 'understandability_and_maintainability')
$criticalIds = @('task_success', 'correctness_and_evidence', 'repeatability', 'state_and_error_observability', 'stop_and_recovery')
$gateIds = @('observable_state_and_errors', 'testable_behavior', 'declared_authority_and_side_effects', 'reversible_or_recoverable', 'upstream_runtime_independence', 'no_undocumented_side_effects')
$allBranches = @('control', 'source_native', 'abk_native')
$eligibleBranches = @($profile.eligible_branches)
$rubricById = @{}
foreach ($dimension in @($rubric.dimensions)) { $rubricById[$dimension.dimension_id] = $dimension }
$normalization = @($profile.expected_normalizations)[0]
$overrideByBranch = @{}
foreach ($branch in $eligibleBranches) { $overrideByBranch[$branch] = @{}; foreach ($override in @($profile.gate_overrides.$branch)) { $overrideByBranch[$branch][$override.gate_id] = $override } }

$branchEvidence = @{}
foreach ($branch in $allBranches) { $branchEvidence[$branch] = [System.Collections.Generic.List[object]]::new() }
$evidenceById = @{}
foreach ($item in @($runIndex.results)) {
    if ($item.branch -notin $allBranches) { throw "EVIDENCE_BRANCH_INVALID: $($item.evidence_id)" }
    $runPath = Resolve-WorkspacePath $item.run_relative_path "evidence.$($item.evidence_id).run_relative_path"
    $oraclePath = Resolve-WorkspacePath $item.oracle_relative_path "evidence.$($item.evidence_id).oracle_relative_path"
    if (-not (Test-Path -LiteralPath $runPath -PathType Leaf) -or -not (Test-Path -LiteralPath $oraclePath -PathType Leaf)) { throw "EVIDENCE_MISSING: $($item.evidence_id)" }
    if ((Get-Hash $runPath) -ne $item.run_sha256 -or (Get-Hash $oraclePath) -ne $item.oracle_sha256) { throw "EVIDENCE_HASH_MISMATCH: $($item.evidence_id)" }
    $run = Read-Json $runPath
    $oracle = Read-Json $oraclePath
    if ($run.branch -ne $item.branch -or $run.case_id -ne $item.case_id -or [int]$run.repeat -ne [int]$item.repeat -or $oracle.branch -ne $item.branch -or $oracle.case_id -ne $item.case_id) { throw "EVIDENCE_IDENTITY_INVALID: $($item.evidence_id)" }
    $assessmentStatus = [string]$oracle.status
    $assessmentReason = 'Raw oracle status is preserved as the v2 assessment status.'
    $errorCode = if ($null -ne $oracle.error) { [string]$oracle.error.code } else { $null }
    if ($item.branch -eq 'control' -and $assessmentStatus -ne 'UNSCORED') { throw "CONTROL_BASELINE_STATUS_INVALID: $($item.evidence_id)" }
    if ($item.branch -in $eligibleBranches -and $item.case_id -eq $normalization.case_id) {
        if ($assessmentStatus -ne $normalization.raw_status -or $errorCode -ne $normalization.error_code) { throw "EXPECTED_NEGATIVE_MISMATCH: $($item.evidence_id)" }
        $assessmentStatus = $normalization.assessment_status
        $assessmentReason = $normalization.rationale
    }
    $evidence = [ordered]@{ evidence_id = $item.evidence_id; branch = $item.branch; case_id = $item.case_id; raw_oracle_status = [string]$oracle.status; assessment_status = $assessmentStatus; assessment_reason = $assessmentReason; run_relative_path = $item.run_relative_path; oracle_relative_path = $item.oracle_relative_path; run_sha256 = $item.run_sha256; oracle_sha256 = $item.oracle_sha256 }
    $branchEvidence[$item.branch].Add($evidence)
    $evidenceById[$item.evidence_id] = $evidence
}
foreach ($branch in $allBranches) { if ($branchEvidence[$branch].Count -ne 22) { throw "BRANCH_EVIDENCE_COUNT_INVALID: $branch" } }

function Get-ReviewDimensionScore([object]$Review, [string]$CaseId, [string]$DimensionId) {
    $caseScore = @($Review.case_scores | Where-Object case_id -eq $CaseId)[0]
    $dimension = @($caseScore.dimensions | Where-Object dimension_id -eq $DimensionId)[0]
    if ($null -eq $dimension) { throw "REVIEW_DIMENSION_MISSING: $($Review.review_id)/$CaseId/$DimensionId" }
    return [double]$dimension.score
}

function Get-Review([string]$Branch, [string]$ReviewerKey) {
    $path = Join-Path (Join-Path $reviewerRootFull $Branch) "$ReviewerKey.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "REVIEW_MISSING: $path" }
    Test-Schema $path $reviewerSchemaPath 'REVIEW_SCHEMA_INVALID'
    $review = Read-Json $path
    if ($review.status -ne 'submitted' -or $review.branch -ne $Branch -or $review.evidence_snapshot_sha256 -ne $indexHash) { throw "REVIEW_INVALID: $path" }
    if (@($review.case_scores).Count -ne 10 -or @($review.hard_gates).Count -ne 6) { throw "REVIEW_INCOMPLETE: $review.review_id" }
    return $review
}

function Get-Adjudication([string]$Branch) {
    $path = Join-Path (Join-Path $adjudicationRootFull $Branch) 'adjudicator-01.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "ADJUDICATION_MISSING: $path" }
    Test-Schema $path $adjudicationSchemaPath 'ADJUDICATION_SCHEMA_INVALID'
    return Read-Json $path
}

$branchScores = [System.Collections.Generic.List[object]]::new()
$eligibleReviewIds = [System.Collections.Generic.List[string]]::new()
$eligibleAdjudicationIds = [System.Collections.Generic.List[string]]::new()
foreach ($branch in $eligibleBranches) {
    $firstReview = Get-Review $branch 'reviewer-01'
    $secondReview = Get-Review $branch 'reviewer-02'
    $adjudication = Get-Adjudication $branch
    $actualReviewIds = (@($adjudication.review_ids) | Sort-Object) -join '|'
    $expectedReviewIds = (@($firstReview.review_id, $secondReview.review_id) | Sort-Object) -join '|'
    if ($actualReviewIds -ne $expectedReviewIds) { throw "ADJUDICATION_REVIEW_IDS_INVALID: $branch" }
    $eligibleReviewIds.Add($firstReview.review_id); $eligibleReviewIds.Add($secondReview.review_id); $eligibleAdjudicationIds.Add($adjudication.adjudication_id)
    $decisionMap = @{}
    foreach ($decision in @($adjudication.decisions)) { $decisionMap["$($decision.case_id)|$($decision.dimension_id)"] = $decision }
    $caseMap = @{}
    foreach ($case in @($campaign.cases)) {
        $caseMap[$case.case_id] = @{}
        foreach ($dimensionId in $dimensionIds) {
            $left = Get-ReviewDimensionScore $firstReview $case.case_id $dimensionId
            $right = Get-ReviewDimensionScore $secondReview $case.case_id $dimensionId
            $difference = [math]::Abs($left - $right)
            $key = "$($case.case_id)|$dimensionId"
            if ($difference -le 1) { $caseMap[$case.case_id][$dimensionId] = [math]::Round((($left + $right) / 2), 1); continue }
            if (-not $decisionMap.ContainsKey($key)) { throw "ADJUDICATION_DECISION_MISSING: $branch/$key" }
            $decision = $decisionMap[$key]
            if ($decision.resolution -ne 'median' -and -not ($case.case_id -eq $normalization.case_id -and $decision.resolution -eq 'inconclusive')) { throw "ADJUDICATION_RESOLUTION_INVALID: $branch/$key" }
            if (@($decision.reviewer_scores | Where-Object { $_.review_id -eq $firstReview.review_id -and [double]$_.score -eq $left }).Count -ne 1 -or @($decision.reviewer_scores | Where-Object { $_.review_id -eq $secondReview.review_id -and [double]$_.score -eq $right }).Count -ne 1) { throw "ADJUDICATION_REVIEWER_SCORE_MISMATCH: $branch/$key" }
            $scores = @($left, $right, [double]$decision.adjudicator_score) | Sort-Object
            $caseMap[$case.case_id][$dimensionId] = [math]::Round([double]$scores[1], 1)
        }
    }
    $dimensions = [System.Collections.Generic.List[object]]::new()
    foreach ($dimensionId in $dimensionIds) {
        $scores = @($campaign.cases | ForEach-Object { [double]$caseMap[$_.case_id][$dimensionId] })
        $score = [math]::Round((($scores | Measure-Object -Average).Average), 1)
        $evidenceIds = @($branchEvidence[$branch] | ForEach-Object evidence_id)
        $dimensions.Add([ordered]@{ dimension_id = $dimensionId; critical = [bool]$rubricById[$dimensionId].critical; score = $score; weight = [double]$rubricById[$dimensionId].weight; rationale = "V2 median-of-three adjudication over ten frozen case scores for $dimensionId."; evidence_ids = $evidenceIds })
    }
    $weighted = [math]::Round((($dimensions | ForEach-Object { $_.score * $_.weight } | Measure-Object -Sum).Sum), 3)
    $criticalMinimum = (($dimensions | Where-Object critical | ForEach-Object { [double]$_.score }) | Measure-Object -Minimum).Minimum
    $branchScores.Add([ordered]@{ branch = $branch; dimensions = @($dimensions); critical_minimum = [double]$criticalMinimum; weighted_average = [double]$weighted; evidence_ids = @($branchEvidence[$branch] | ForEach-Object evidence_id) })
    foreach ($gateId in $gateIds) {
        $baseGate = @($fullScorecard.hard_gates | Where-Object gate_id -eq $gateId)[0]
        if ($baseGate.status -ne 'pass' -and -not $overrideByBranch[$branch].ContainsKey($gateId)) { throw "GATE_UNRESOLVED: $branch/$gateId" }
    }
}

$abkScore = @($branchScores | Where-Object branch -eq 'abk_native')[0]
$outcome = if ($abkScore.critical_minimum -le 4) { 'REJECTED' } elseif ($abkScore.weighted_average -lt 8) { 'CANDIDATE' } else { 'CHOSEN' }
$gateEvidence = @($eligibleBranches | ForEach-Object { @($branchEvidence[$_] | ForEach-Object evidence_id) } | Sort-Object -Unique)
$hardGates = foreach ($gateId in $gateIds) {
    $rationales = @($eligibleBranches | ForEach-Object { if ($overrideByBranch[$_].ContainsKey($gateId)) { $overrideByBranch[$_][$gateId].rationale } else { 'The pinned raw evidence marks this gate as pass.' } })
    [ordered]@{ gate_id = $gateId; status = 'pass'; rationale = ($rationales -join ' '); evidence_ids = $gateEvidence }
}
$evidence = @($allBranches | ForEach-Object { @($branchEvidence[$_] | ForEach-Object { $_ }) })
$baselineIds = @($branchEvidence.control | ForEach-Object evidence_id)
$card = [ordered]@{
    '$schema' = '../../../schemas/comparison-scorecard-v2.schema.json'
    schema_version = '1.0.0'
    comparison_id = 'abk:comparison:artifact-dag-core-v2'
    protocol_id = 'abk:benchmark:pattern-adoption-v2'
    evaluated_at = [DateTime]::UtcNow.ToString('o')
    status = 'complete'
    source_snapshot = [ordered]@{ path = $profile.source_snapshot.path; sha256 = $indexHash; raw_runs = 66 }
    baseline = [ordered]@{ branch = 'control'; eligibility = 'baseline_only'; raw_oracle_status = 'UNSCORED'; evidence_ids = $baselineIds; rationale = 'The legacy control runner is retained as a pinned baseline reference and is excluded from v2 adoption eligibility.' }
    eligible_branches = @('source_native', 'abk_native')
    hard_gates = @($hardGates)
    branch_scores = @($branchScores)
    outcome = $outcome
    outcome_formula = 'baseline-only control; critical_min<=4=>REJECTED; weighted_average<8=>CANDIDATE; weighted_average>=8=>CHOSEN'
    rationale = "V2 compares source_native and abk_native against the pinned control baseline. SPC-01 expected boundary rejection is normalized only in the assessment layer; raw oracle evidence remains preserved. ABK-native weighted_average=$($abkScore.weighted_average), critical_minimum=$($abkScore.critical_minimum), outcome=$outcome. ADOPTED still requires separate human approval."
    review_ids = @($eligibleReviewIds)
    adjudication_ids = @($eligibleAdjudicationIds)
    evidence = @($evidence)
}
New-Item -ItemType Directory -Path (Split-Path -Parent $outputFull) -Force | Out-Null
if (Test-Path -LiteralPath $outputFull) { throw "OUTPUT_EXISTS: refusing to overwrite '$outputFull'" }
Write-Json $card $outputFull
Test-Schema $outputFull $scorecardSchemaPath 'V2_SCORECARD_SCHEMA_INVALID'
Write-Output "V2_COMPARISON_VALID: outcome=$outcome; eligible_branches=$($branchScores.Count)/2; evidence=$($evidence.Count)/66; output=$outputFull"

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot,
    [Parameter(Mandatory = $true)]
    [string]$RunRoot,
    [Parameter(Mandatory = $true)]
    [string]$ReviewerInputRoot,
    [Parameter(Mandatory = $true)]
    [string]$ScorecardRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$campaignPath = Join-Path $campaignRoot 'campaign.json'
$campaignSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\benchmark-campaign.schema.json'
$fullScorecardSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\full-campaign-scorecard.schema.json'
$reviewerSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-input.schema.json'
$rubricSchemaPath = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-rubric.schema.json'
$adoptionSchemaPath = Join-Path $workspaceFull 'outputs\09-adoption-scorecard.schema.json'
$rubricPath = Join-Path $campaignRoot 'reviewer-rubric.json'
$runRootFull = [IO.Path]::GetFullPath($RunRoot)
$reviewerRootFull = [IO.Path]::GetFullPath($ReviewerInputRoot)
$scorecardRootFull = [IO.Path]::GetFullPath($ScorecardRoot)
$runsRootFull = [IO.Path]::GetFullPath((Join-Path $campaignRoot 'runs')).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
$campaignPrefix = $campaignRoot.TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
$runsPrefix = $runsRootFull + [IO.Path]::DirectorySeparatorChar
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
function Assert-Unique([object[]]$Values, [string]$Code, [string]$Label) { if (@($Values | Sort-Object -Unique).Count -ne $Values.Count) { throw "${Code}: duplicate $Label" } }
function Test-Schema([string]$Path, [string]$SchemaPath, [string]$Code) { try { if (-not (Test-Json -LiteralPath $Path -SchemaFile $SchemaPath -ErrorAction Stop)) { throw "${Code}: $Path" } } catch { throw "${Code}: $Path" } }

Assert-UnderRoot $runRootFull $runsRootFull 'RunRoot' $true
Assert-UnderRoot $reviewerRootFull $campaignRoot 'ReviewerInputRoot' $false
Assert-UnderRoot $scorecardRootFull $campaignRoot 'ScorecardRoot' $false
if (-not (Test-Path -LiteralPath $campaignPath -PathType Leaf) -or -not (Test-Path -LiteralPath $campaignSchemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $fullScorecardSchemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $reviewerSchemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $rubricSchemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $adoptionSchemaPath -PathType Leaf) -or -not (Test-Path -LiteralPath $rubricPath -PathType Leaf)) { throw 'INPUT_MISSING: campaign, rubric, schemas, and adoption scorecard contract are required' }

$campaign = Read-Json $campaignPath
Test-Schema $campaignPath $campaignSchemaPath 'CAMPAIGN_SCHEMA_INVALID'
if ($campaign.status -ne 'benchmark_pending' -or $campaign.outcome -ne 'UNSCORED' -or $campaign.completed_primary_cells -ne 0 -or $campaign.completed_raw_runs -ne 0 -or @($campaign.run_evidence_ids).Count -ne 0) { throw 'CAMPAIGN_NOT_PRISTINE: reviewer scorecards require the frozen pending campaign contract' }
$fullScorecardPath = Join-Path $runRootFull 'full-campaign-scorecard.json'
$indexPath = Join-Path $runRootFull 'campaign-run-index.json'
if (-not (Test-Path -LiteralPath $fullScorecardPath -PathType Leaf) -or -not (Test-Path -LiteralPath $indexPath -PathType Leaf)) { throw 'FULL_CAMPAIGN_EVIDENCE_MISSING: scorecard and run index are required' }
Test-Schema $fullScorecardPath $fullScorecardSchemaPath 'FULL_SCORECARD_SCHEMA_INVALID'
$fullScorecard = Read-Json $fullScorecardPath
$index = Read-Json $indexPath
if ($fullScorecard.campaign_id -ne $campaign.campaign_id -or $fullScorecard.benchmark.completed_raw_runs -ne 66 -or $fullScorecard.benchmark.completed_primary_cells -ne 30 -or $fullScorecard.status -ne 'running' -or $fullScorecard.outcome -ne 'UNSCORED') { throw 'FULL_CAMPAIGN_STATE_INVALID: expected the complete raw matrix with an UNSCORED reviewer gate' }
if ($index.campaign_id -ne $campaign.campaign_id -or $index.completed_raw_runs -ne 66 -or @($index.results).Count -ne 66) { throw 'RUN_INDEX_INVALID: expected 66 indexed raw runs' }
$indexRelativePath = ([IO.Path]::GetRelativePath($workspaceFull, $indexPath)).Replace('\', '/')
$indexHash = Get-Hash $indexPath

Test-Schema $rubricPath $rubricSchemaPath 'RUBRIC_SCHEMA_INVALID'
$rubric = Read-Json $rubricPath
$dimensionIds = @('task_success', 'correctness_and_evidence', 'repeatability', 'state_and_error_observability', 'stop_and_recovery', 'context_and_token_efficiency', 'runtime_and_operational_overhead', 'composition_and_handoff', 'useful_autonomy', 'understandability_and_maintainability')
$criticalIds = @('task_success', 'correctness_and_evidence', 'repeatability', 'state_and_error_observability', 'stop_and_recovery')
$gateIds = @('observable_state_and_errors', 'testable_behavior', 'declared_authority_and_side_effects', 'reversible_or_recoverable', 'upstream_runtime_independence', 'no_undocumented_side_effects')
if (@($rubric.dimensions).Count -ne 10 -or $rubric.reviewer_count -ne 2) { throw 'RUBRIC_INVALID: exactly ten dimensions and two reviewers are required' }
Assert-Unique @($rubric.dimensions | ForEach-Object dimension_id) 'RUBRIC_DIMENSION_DUPLICATE' 'rubric dimension'
$rubricById = @{}
foreach ($dimension in @($rubric.dimensions)) {
    if ($dimension.dimension_id -notin $dimensionIds -or $dimension.critical -ne ($dimension.dimension_id -in $criticalIds)) { throw "RUBRIC_DIMENSION_INVALID: $($dimension.dimension_id)" }
    $rubricById[$dimension.dimension_id] = $dimension
}
$weightSum = [math]::Round((@($rubric.dimensions | Measure-Object -Property weight -Sum).Sum), 6)
if ([math]::Abs($weightSum - 1) -gt 0.000001) { throw "RUBRIC_WEIGHT_SUM_INVALID: $weightSum" }

$branches = @('control', 'source_native', 'abk_native')
$scorecardIds = @{ control = 'abk:scorecard:artifact-dag-core-v1-control'; source_native = 'abk:scorecard:artifact-dag-core-v1-source-native'; abk_native = 'abk:scorecard:artifact-dag-core-v1-abk-native' }
$manifestIds = @{}
foreach ($branch in $branches) { $manifestIds[$branch] = (Read-Json (Join-Path $campaignRoot ("branches\$branch\manifest.json"))).manifest_id }

$branchEvidence = @{}
foreach ($branch in $branches) { $branchEvidence[$branch] = [System.Collections.Generic.List[object]]::new() }
$fullEvidenceIds = @($fullScorecard.evidence | ForEach-Object evidence_id)
Assert-Unique $fullEvidenceIds 'FULL_EVIDENCE_DUPLICATE' 'full-campaign evidence ID'
foreach ($item in @($fullScorecard.evidence)) {
    if ($item.branch -notin $branches) { throw "FULL_EVIDENCE_BRANCH_INVALID: $($item.evidence_id)" }
    $runPath = Resolve-WorkspacePath $item.run_relative_path "evidence.$($item.evidence_id).run_relative_path"
    $oraclePath = Resolve-WorkspacePath $item.oracle_relative_path "evidence.$($item.evidence_id).oracle_relative_path"
    if (-not (Test-Path -LiteralPath $runPath -PathType Leaf) -or -not (Test-Path -LiteralPath $oraclePath -PathType Leaf)) { throw "EVIDENCE_MISSING: $($item.evidence_id)" }
    if ((Get-Hash $runPath) -ne $item.run_sha256 -or (Get-Hash $oraclePath) -ne $item.oracle_sha256) { throw "EVIDENCE_HASH_MISMATCH: $($item.evidence_id)" }
    $run = Read-Json $runPath
    $oracle = Read-Json $oraclePath
    if ($run.campaign_id -ne $campaign.campaign_id -or $run.branch -ne $item.branch -or $run.case_id -ne $item.case_id -or [int]$run.repeat -ne [int]$item.repeat -or $oracle.campaign_id -ne $campaign.campaign_id -or $oracle.branch -ne $item.branch -or $oracle.case_id -ne $item.case_id) { throw "EVIDENCE_IDENTITY_INVALID: $($item.evidence_id)" }
    $branchEvidence[$item.branch].Add($item)
}
foreach ($branch in $branches) { if ($branchEvidence[$branch].Count -ne 22) { throw "BRANCH_EVIDENCE_COUNT_INVALID: $branch has $($branchEvidence[$branch].Count)" } }

$reviewInputs = [System.Collections.Generic.List[object]]::new()
if (Test-Path -LiteralPath $reviewerRootFull -PathType Container) {
    foreach ($reviewFile in @(Get-ChildItem -LiteralPath $reviewerRootFull -Recurse -Filter '*.json' -File)) {
        Test-Schema $reviewFile.FullName $reviewerSchemaPath 'REVIEWER_INPUT_SCHEMA_INVALID'
        $review = Read-Json $reviewFile.FullName
        if ($review.campaign_id -ne $campaign.campaign_id -or $review.rubric_id -ne $rubric.rubric_id -or $review.scorecard_id -ne $scorecardIds[$review.branch] -or $review.evidence_snapshot_path -ne $indexRelativePath -or $review.evidence_snapshot_sha256 -ne $indexHash) { throw "REVIEWER_INPUT_SNAPSHOT_INVALID: $($reviewFile.FullName)" }
        if ($review.branch -notin $branches) { throw "REVIEWER_INPUT_BRANCH_INVALID: $($reviewFile.FullName)" }
        $expectedFolder = Join-Path $reviewerRootFull $review.branch
        $expectedFile = Join-Path $expectedFolder ("$($review.reviewer_key).json")
        if ([IO.Path]::GetFullPath($reviewFile.FullName) -ne [IO.Path]::GetFullPath($expectedFile)) { throw "REVIEWER_INPUT_FILENAME_INVALID: expected '$expectedFile'" }
        Assert-UnderRoot $reviewFile.DirectoryName $expectedFolder "reviewer.$($review.review_id).folder" $true
        $reviewInputs.Add([pscustomobject]@{ path = $reviewFile.FullName; document = $review })
    }
}
$reviewIds = @($reviewInputs | ForEach-Object { $_.document.review_id })
Assert-Unique $reviewIds 'REVIEW_ID_DUPLICATE' 'review ID'
foreach ($branch in $branches) {
    $branchReviews = @($reviewInputs | Where-Object { $_.document.branch -eq $branch })
    if ($branchReviews.Count -gt 2) { throw "REVIEWER_COUNT_INVALID: $branch has $($branchReviews.Count) reviewer inputs" }
    Assert-Unique @($branchReviews | ForEach-Object { $_.document.reviewer_key }) 'REVIEWER_KEY_DUPLICATE' "reviewer key for $branch"
}

function Assert-SubmittedReview([object]$Review, [string[]]$EvidenceIds, [string]$Branch) {
    if ($Review.status -ne 'submitted') { return }
    if (@($Review.case_scores).Count -ne 10 -or @($Review.hard_gates).Count -ne 6) { throw "REVIEW_SUBMISSION_INCOMPLETE: $($Review.review_id)" }
    $cases = @($campaign.cases | ForEach-Object case_id)
    Assert-Unique @($Review.case_scores | ForEach-Object case_id) 'REVIEW_CASE_DUPLICATE' $Review.review_id
    if (@($Review.case_scores | Where-Object { $_.case_id -notin $cases }).Count -gt 0) { throw "REVIEW_CASE_INVALID: $($Review.review_id)" }
    foreach ($caseScore in @($Review.case_scores)) {
        if (@($caseScore.dimensions).Count -ne 10) { throw "REVIEW_DIMENSION_COUNT_INVALID: $($Review.review_id)/$($caseScore.case_id)" }
        Assert-Unique @($caseScore.dimensions | ForEach-Object dimension_id) 'REVIEW_DIMENSION_DUPLICATE' "$($Review.review_id)/$($caseScore.case_id)"
        if (@($caseScore.dimensions | Where-Object { $_.dimension_id -notin $dimensionIds }).Count -gt 0) { throw "REVIEW_DIMENSION_INVALID: $($Review.review_id)/$($caseScore.case_id)" }
        foreach ($dimension in @($caseScore.dimensions)) { if (@($dimension.evidence_ids | Where-Object { $_ -notin $EvidenceIds }).Count -gt 0) { throw "REVIEW_EVIDENCE_REFERENCE_INVALID: $($Review.review_id)/$($caseScore.case_id)/$($dimension.dimension_id)" } }
        if (@($caseScore.evidence_ids | Where-Object { $_ -notin $EvidenceIds }).Count -gt 0) { throw "REVIEW_EVIDENCE_REFERENCE_INVALID: $($Review.review_id)/$($caseScore.case_id)" }
    }
    Assert-Unique @($Review.hard_gates | ForEach-Object gate_id) 'REVIEW_GATE_DUPLICATE' $Review.review_id
    if (@($Review.hard_gates | Where-Object { $_.gate_id -notin $gateIds }).Count -gt 0) { throw "REVIEW_GATE_INVALID: $($Review.review_id)" }
    foreach ($gate in @($Review.hard_gates)) { if (@($gate.evidence_ids | Where-Object { $_ -notin $EvidenceIds }).Count -gt 0) { throw "REVIEW_GATE_EVIDENCE_INVALID: $($Review.review_id)/$($gate.gate_id)" } }
}

function New-BranchScore([object]$FirstReview, [object]$SecondReview, [object[]]$Evidence, [string]$Branch, [System.Collections.Generic.List[string]]$Blockers) {
    if ($FirstReview.status -ne 'submitted' -or $SecondReview.status -ne 'submitted') { $Blockers.Add("REVIEWER_INPUTS_PENDING: $Branch requires two submitted reviewer inputs"); return $null }
    $caseMap = @{}
    foreach ($caseId in @($campaign.cases | ForEach-Object case_id)) {
        $left = @($FirstReview.case_scores | Where-Object case_id -eq $caseId)[0]
        $right = @($SecondReview.case_scores | Where-Object case_id -eq $caseId)[0]
        $leftByDimension = @{}; $rightByDimension = @{}
        foreach ($d in @($left.dimensions)) { $leftByDimension[$d.dimension_id] = $d }
        foreach ($d in @($right.dimensions)) { $rightByDimension[$d.dimension_id] = $d }
        $caseMap[$caseId] = @{}
        foreach ($dimensionId in $dimensionIds) {
            $difference = [math]::Abs(([double]$leftByDimension[$dimensionId].score) - ([double]$rightByDimension[$dimensionId].score))
            if ($difference -gt 1) { $Blockers.Add("REVIEW_ADJUDICATION_REQUIRED: $Branch/$caseId/$dimensionId difference=$difference"); continue }
            $caseMap[$caseId][$dimensionId] = [math]::Round((([double]$leftByDimension[$dimensionId].score + [double]$rightByDimension[$dimensionId].score) / 2), 1)
        }
    }
    if ($Blockers.Count -gt 0) { return $null }
    $dimensions = [System.Collections.Generic.List[object]]::new()
    foreach ($dimensionId in $dimensionIds) {
        $caseScores = @($campaign.cases | ForEach-Object { $caseMap[$_.case_id][$dimensionId] })
        $score = [math]::Round((($caseScores | Measure-Object -Average).Average), 1)
        $dimensionEvidence = [System.Collections.Generic.List[string]]::new()
        foreach ($review in @($FirstReview, $SecondReview)) { foreach ($caseScore in @($review.case_scores)) { $d = @($caseScore.dimensions | Where-Object dimension_id -eq $dimensionId)[0]; foreach ($evidenceId in @($d.evidence_ids)) { if ($evidenceId -notin $dimensionEvidence) { $dimensionEvidence.Add($evidenceId) } } } }
        $dimensions.Add([ordered]@{ dimension_id = $dimensionId; critical = [bool]$rubricById[$dimensionId].critical; score = $score; weight = [double]$rubricById[$dimensionId].weight; rationale = "Mean of two independent reviews over the ten frozen case scores for $dimensionId."; evidence_ids = @($dimensionEvidence) })
    }
    $weighted = [math]::Round((($dimensions | ForEach-Object { $_.score * $_.weight } | Measure-Object -Sum).Sum), 3)
    $criticalMinimum = ($dimensions | Where-Object critical | Measure-Object -Property score -Minimum).Minimum
    [ordered]@{ branch = $Branch; dimensions = @($dimensions); critical_minimum = [double]$criticalMinimum; weighted_average = [double]$weighted; calculation = 'round3(sum(score*weight))'; evidence_ids = @($Evidence | ForEach-Object evidence_id) }
}

$branchScores = @{}
$branchBlockerMap = @{}
$branchHardGates = @{}
foreach ($branch in $branches) {
    $currentBlockers = [System.Collections.Generic.List[string]]::new()
    $evidenceIds = @($branchEvidence[$branch] | ForEach-Object evidence_id)
    $reviews = @($reviewInputs | Where-Object { $_.document.branch -eq $branch } | ForEach-Object document)
    foreach ($review in $reviews) { Assert-SubmittedReview $review $evidenceIds $branch }
    if ($reviews.Count -eq 2) { $branchScores[$branch] = New-BranchScore $reviews[0] $reviews[1] @($branchEvidence[$branch]) $branch $currentBlockers } else { $currentBlockers.Add("REVIEWER_COUNT_PENDING: $branch requires exactly two reviewer inputs") }
    if ($reviews.Count -eq 2 -and @($reviews | Where-Object status -eq 'submitted').Count -eq 2) {
        $gateMap = @{}
        foreach ($gateId in $gateIds) {
            $left = @($reviews[0].hard_gates | Where-Object gate_id -eq $gateId)[0]; $right = @($reviews[1].hard_gates | Where-Object gate_id -eq $gateId)[0]
            if ($null -eq $left -or $null -eq $right) { $currentBlockers.Add("REVIEW_GATE_PENDING: $branch/$gateId"); continue }
            if ($left.status -ne $right.status) { $currentBlockers.Add("REVIEW_GATE_DISAGREEMENT: $branch/$gateId"); continue }
            $gateMap[$gateId] = [ordered]@{ gate_id = $gateId; status = $left.status; rationale = "Both independent reviewers reported $($left.status) for $gateId."; evidence_ids = @($evidenceIds) }
        }
        $branchHardGates[$branch] = $gateMap
    } else { $branchHardGates[$branch] = @{} }
    if ($branchScores[$branch] -eq $null) { $currentBlockers.Add("BRANCH_SCORE_PENDING: $branch has no agreeing submitted score vector") }
    $branchBlockerMap[$branch] = @($currentBlockers | Sort-Object -Unique)
}

$allBranchScores = @($branches | ForEach-Object { $branchScores[$_] } | Where-Object { $null -ne $_ })
$allGatesPass = $true
$aggregateGateStatus = @{}
foreach ($gateId in $gateIds) {
    $base = @($fullScorecard.hard_gates | Where-Object gate_id -eq $gateId)[0]
    $statuses = @($branches | ForEach-Object { if ($branchHardGates[$_].ContainsKey($gateId)) { $branchHardGates[$_][$gateId].status } else { $null } })
    $reviewerFailure = @($statuses | Where-Object { $_ -eq 'fail' }).Count -gt 0
    $reviewerAllPass = $statuses.Count -eq 3 -and @($statuses | Where-Object { $_ -ne 'pass' }).Count -eq 0
    if ($base.status -eq 'fail' -or $reviewerFailure -or ($base.status -eq 'pending' -and -not $reviewerAllPass)) { $allGatesPass = $false }
    $status = if ($base.status -eq 'fail' -or $reviewerFailure) { 'fail' } elseif ($base.status -eq 'pass' -or ($base.status -eq 'pending' -and $reviewerAllPass)) { 'pass' } else { 'pending' }
    $aggregateGateStatus[$gateId] = $status
}
$campaignComplete = $allBranchScores.Count -eq 3 -and $allGatesPass
$globalOutcome = 'UNSCORED'
if ($campaignComplete) {
    $abkScore = $branchScores['abk_native']
    $globalOutcome = if ($abkScore.critical_minimum -le 4) { 'REJECTED' } elseif ($abkScore.weighted_average -lt 8) { 'CANDIDATE' } else { 'CHOSEN' }
}

New-Item -ItemType Directory -Path $scorecardRootFull -Force | Out-Null
foreach ($branch in $branches) {
    $evidenceIds = @($branchEvidence[$branch] | ForEach-Object evidence_id)
    $gates = foreach ($gateId in $gateIds) {
        $status = $aggregateGateStatus[$gateId]
        $rationale = if ($status -eq 'pass') { "The frozen raw evidence and reviewer gate inputs support $gateId." } elseif ($status -eq 'fail') { "A reviewer or raw contract failed $gateId; the scorecard remains fail-closed." } else { "The reviewer gate for $gateId is missing or not unanimously passed." }
        [ordered]@{ gate_id = $gateId; status = $status; rationale = $rationale; evidence_ids = $evidenceIds }
    }
    $branchEvidenceOutput = @($branchEvidence[$branch] | ForEach-Object { [ordered]@{ evidence_id = $_.evidence_id; status = 'passed'; locator = $_.run_relative_path; content_sha256 = $_.run_sha256; summary = "Raw run evidence is hash-verified; oracle status is $($_.oracle_status)." } })
    $blockers = [System.Collections.Generic.List[string]]::new()
    foreach ($item in @($branchBlockerMap[$branch])) { $blockers.Add($item) }
    if (-not $campaignComplete) { $blockers.Add('Campaign remains UNSCORED until all three branches have two agreeing submitted reviews and all six hard gates pass.') }
    $blockers.Add('ADOPTED requires a separate human approval after any CHOSEN result.')
    $benchmark = [ordered]@{ status = 'complete'; case_count = 10; common_case_count = 6; specific_case_count = 4; branches = $branches; primary_cell_count = 30; case_repeat_policy = @($campaign.cases | ForEach-Object { [ordered]@{ case_id = $_.case_id; case_class = $_.case_class; model_dependent = [bool]$_.model_dependent; repeats = [int]$_.repeats } }); expected_raw_runs = 66; completed_primary_cells = 10; completed_raw_runs = 22; run_evidence_ids = $evidenceIds }
    $cardOutcome = if ($campaignComplete -and $branch -eq 'abk_native') { $globalOutcome } else { 'UNSCORED' }
    $branchScoreList = [System.Collections.Generic.List[object]]::new()
    if ($null -ne $branchScores[$branch]) { $branchScoreList.Add($branchScores[$branch]) }
    $rationale = "Branch '$branch' scorecard generated from the immutable 66-run evidence snapshot. Reviewer inputs are independent and fail closed until complete. Blockers: $($blockers -join '; ')"
    $card = [ordered]@{ schema_version = '1.0.0'; scorecard_id = $scorecardIds[$branch]; candidate_manifest_id = $manifestIds[$branch]; protocol_id = 'abk:benchmark:pattern-adoption-v1'; evaluated_at = [DateTime]::UtcNow.ToString('o'); status = if ($campaignComplete) { 'complete' } else { 'running' }; host = 'codex'; hard_gates = @($gates); benchmark = $benchmark; branch_scores = $branchScoreList; outcome = $cardOutcome; outcome_formula = 'incomplete=>UNSCORED;critical_min<=4=>REJECTED;weighted_average<8=>CANDIDATE;weighted_average>=8=>CHOSEN'; rationale = $rationale; evidence = $branchEvidenceOutput }
    $outputPath = Join-Path $scorecardRootFull ("$branch.json")
    if (Test-Path -LiteralPath $outputPath) { throw "OUTPUT_EXISTS: refusing to overwrite '$outputPath'" }
    Write-Json $card $outputPath
    Test-Schema $outputPath $adoptionSchemaPath 'SCORECARD_SCHEMA_INVALID'
}
Write-Output "REVIEW_SCORECARDS_VALID: status=$(if ($campaignComplete) { 'complete' } else { 'running' }); branch_scores=$($allBranchScores.Count)/3; outcome=$globalOutcome; output=$scorecardRootFull"

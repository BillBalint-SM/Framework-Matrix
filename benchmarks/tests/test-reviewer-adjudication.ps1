param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$workspaceFull = [IO.Path]::GetFullPath($WorkspaceRoot)
$campaignRoot = Join-Path $workspaceFull 'benchmarks\campaigns\artifact-dag-core-v1'
$runRoot = Join-Path $campaignRoot 'runs\full-campaign-20260805'
$validator = Join-Path $workspaceFull 'benchmarks\scripts\validate-reviewer-scorecards.ps1'
$reviewSchema = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-input.schema.json'
$adjudicationSchema = Join-Path $workspaceFull 'benchmarks\schemas\reviewer-adjudication.schema.json'
$adoptionSchema = Join-Path $workspaceFull 'outputs\09-adoption-scorecard.schema.json'
$indexPath = Join-Path $runRoot 'campaign-run-index.json'
$indexHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $indexPath).Hash.ToLowerInvariant()
$campaign = Get-Content -Raw -LiteralPath (Join-Path $campaignRoot 'campaign.json') | ConvertFrom-Json
$fullScorecard = Get-Content -Raw -LiteralPath (Join-Path $runRoot 'full-campaign-scorecard.json') | ConvertFrom-Json
$branches = @('control', 'source_native', 'abk_native')
$dimensions = @('task_success', 'correctness_and_evidence', 'repeatability', 'state_and_error_observability', 'stop_and_recovery', 'context_and_token_efficiency', 'runtime_and_operational_overhead', 'composition_and_handoff', 'useful_autonomy', 'understandability_and_maintainability')
$gates = @('observable_state_and_errors', 'testable_behavior', 'declared_authority_and_side_effects', 'reversible_or_recoverable', 'upstream_runtime_independence', 'no_undocumented_side_effects')
$scorecardIds = @{ control = 'abk:scorecard:artifact-dag-core-v1-control'; source_native = 'abk:scorecard:artifact-dag-core-v1-source-native'; abk_native = 'abk:scorecard:artifact-dag-core-v1-abk-native' }
$evidenceByBranch = @{}
foreach ($branch in $branches) { $evidenceByBranch[$branch] = @($fullScorecard.evidence | Where-Object branch -eq $branch | ForEach-Object evidence_id) }
$pwshPath = (Get-Command pwsh.exe -ErrorAction Stop).Source

function Write-Json([object]$Document, [string]$Path) { $Document | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $Path -Encoding utf8NoBOM }
function Assert-True([bool]$Condition, [string]$Message) { if (-not $Condition) { throw "TEST_FAILURE: $Message" } }

function New-ReviewDocument([string]$Branch, [string]$ReviewerKey, [hashtable]$Overrides) {
    $reviewSuffix = if ($ReviewerKey -eq 'reviewer-01') { '01' } else { '02' }
    $branchToken = $Branch.Replace('_', '-')
    $caseScores = foreach ($case in @($campaign.cases)) {
        $caseEvidence = @($evidenceByBranch[$Branch] | Where-Object { $_ -match "-$($case.case_id.ToLowerInvariant().Replace('_','-'))-" })
        if ($caseEvidence.Count -eq 0) { $caseEvidence = @($evidenceByBranch[$Branch][0]) }
        $dimensionScores = foreach ($dimensionId in $dimensions) {
            $key = "$($case.case_id)|$dimensionId"
            $score = if ($Overrides.ContainsKey($key)) { [double]$Overrides[$key] } else { 7 }
            [ordered]@{ dimension_id = $dimensionId; score = $score; rationale = "Synthetic test reviewer rationale for $dimensionId."; evidence_ids = @($caseEvidence[0]) }
        }
        [ordered]@{ case_id = $case.case_id; dimensions = @($dimensionScores); evidence_ids = @($caseEvidence[0]) }
    }
    $hardGates = foreach ($gateId in $gates) { [ordered]@{ gate_id = $gateId; status = 'pass'; rationale = "Synthetic test reviewer confirms $gateId."; evidence_ids = @($evidenceByBranch[$Branch][0]) } }
    [ordered]@{
        '$schema' = '../../../../schemas/reviewer-input.schema.json'
        schema_version = '1.0.0'
        review_id = "abk:review:artifact-dag-core-v1-$branchToken-$ReviewerKey"
        campaign_id = $campaign.campaign_id
        scorecard_id = $scorecardIds[$Branch]
        rubric_id = 'abk:rubric:artifact-dag-core-v1'
        branch = $Branch
        reviewer_key = $ReviewerKey
        status = 'submitted'
        reviewed_at = '2026-08-05T07:00:00Z'
        evidence_snapshot_path = 'benchmarks/campaigns/artifact-dag-core-v1/runs/full-campaign-20260805/campaign-run-index.json'
        evidence_snapshot_sha256 = $indexHash
        case_scores = @($caseScores)
        hard_gates = @($hardGates)
        rationale = 'Synthetic integration fixture exercises the frozen reviewer contract and does not represent a human score.'
        blockers = @('Synthetic test input only; not a canonical human review.')
    }
}

function New-AdjudicationDocument([string]$Branch, [string]$ReviewOneId, [string]$ReviewTwoId, [object[]]$Decisions) {
    [ordered]@{
        '$schema' = '../../../../schemas/reviewer-adjudication.schema.json'
        schema_version = '1.0.0'
        adjudication_id = "abk:adjudication:artifact-dag-core-v1-$Branch"
        campaign_id = $campaign.campaign_id
        scorecard_id = $scorecardIds[$Branch]
        rubric_id = 'abk:rubric:artifact-dag-core-v1'
        branch = $Branch
        adjudicator_key = 'adjudicator-01'
        status = 'submitted'
        adjudicated_at = '2026-08-05T07:05:00Z'
        evidence_snapshot_path = 'benchmarks/campaigns/artifact-dag-core-v1/runs/full-campaign-20260805/campaign-run-index.json'
        evidence_snapshot_sha256 = $indexHash
        review_ids = @($ReviewOneId, $ReviewTwoId)
        decisions = @($Decisions)
        rationale = 'Synthetic integration fixture exercises numeric median and inconclusive dispute handling.'
        blockers = @('Synthetic test input only; not a canonical adjudication.')
    }
}

function New-Decision([string]$CaseId, [string]$DimensionId, [string]$DisputeType, [string]$Resolution, [double]$FirstScore, [double]$SecondScore, [double]$AdjudicatorScore, [string]$ReviewOneId, [string]$ReviewTwoId, [string]$EvidenceId) {
    [ordered]@{ case_id = $CaseId; dimension_id = $DimensionId; dispute_type = $DisputeType; reviewer_scores = @([ordered]@{ review_id = $ReviewOneId; score = $FirstScore }, [ordered]@{ review_id = $ReviewTwoId; score = $SecondScore }); adjudicator_score = $AdjudicatorScore; resolution = $Resolution; evidence_ids = @($EvidenceId); rationale = 'Synthetic adjudicator rationale cites the pinned branch evidence.' }
}

function Invoke-Scenario([string]$Token, [hashtable]$ControlOverridesOne, [hashtable]$ControlOverridesTwo, [object[]]$Decisions, [string]$ExpectedMode) {
    $reviewerRoot = Join-Path $campaignRoot "reviewer-inputs\test-adjudication-$Token"
    $adjudicationRoot = Join-Path $campaignRoot "adjudications\test-adjudication-$Token"
    $scorecardRoot = Join-Path $campaignRoot "scorecards\test-adjudication-$Token"
    try {
        foreach ($path in @($reviewerRoot, $adjudicationRoot)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
        foreach ($branch in $branches) {
            $branchReviewerRoot = Join-Path $reviewerRoot $branch
            New-Item -ItemType Directory -Path $branchReviewerRoot -Force | Out-Null
            $oneOverrides = @{}
            $twoOverrides = @{}
            if ($branch -eq 'control') { $oneOverrides = $ControlOverridesOne; $twoOverrides = $ControlOverridesTwo }
            $one = New-ReviewDocument $branch 'reviewer-01' $oneOverrides
            $two = New-ReviewDocument $branch 'reviewer-02' $twoOverrides
            Write-Json $one (Join-Path $branchReviewerRoot 'reviewer-01.json')
            Write-Json $two (Join-Path $branchReviewerRoot 'reviewer-02.json')
            Assert-True (Test-Json -LiteralPath (Join-Path $branchReviewerRoot 'reviewer-01.json') -SchemaFile $reviewSchema) "$branch reviewer-01 schema"
            Assert-True (Test-Json -LiteralPath (Join-Path $branchReviewerRoot 'reviewer-02.json') -SchemaFile $reviewSchema) "$branch reviewer-02 schema"
        }
        $controlOneId = 'abk:review:artifact-dag-core-v1-control-reviewer-01'
        $controlTwoId = 'abk:review:artifact-dag-core-v1-control-reviewer-02'
        if ($null -ne $Decisions) {
            $controlAdjudicationRoot = Join-Path $adjudicationRoot 'control'
            New-Item -ItemType Directory -Path $controlAdjudicationRoot -Force | Out-Null
            $adjudication = New-AdjudicationDocument 'control' $controlOneId $controlTwoId $Decisions
            $adjudicationPath = Join-Path $controlAdjudicationRoot 'adjudicator-01.json'
            Write-Json $adjudication $adjudicationPath
            Assert-True (Test-Json -LiteralPath $adjudicationPath -SchemaFile $adjudicationSchema) 'adjudication schema'
        }
        $output = & $pwshPath -NoLogo -NoProfile -NonInteractive -File $validator -WorkspaceRoot $workspaceFull -RunRoot $runRoot -ReviewerInputRoot $reviewerRoot -AdjudicationRoot $adjudicationRoot -ScorecardRoot $scorecardRoot 2>&1
        Assert-True ($LASTEXITCODE -eq 0) "validator failed: $(@($output) -join ' ' )"
        $controlCard = Get-Content -Raw -LiteralPath (Join-Path $scorecardRoot 'control.json') | ConvertFrom-Json
        $abkCard = Get-Content -Raw -LiteralPath (Join-Path $scorecardRoot 'abk_native.json') | ConvertFrom-Json
        if ($ExpectedMode -eq 'numeric') {
            Assert-True ($controlCard.status -eq 'complete' -and $abkCard.status -eq 'complete') 'numeric adjudication did not complete scorecards'
            Assert-True ($controlCard.branch_scores.Count -eq 3 -and $abkCard.branch_scores.Count -eq 3) 'numeric adjudication did not produce complete branch scores'
            $controlScore = @($controlCard.branch_scores | Where-Object branch -eq 'control')[0]
            $controlTaskSuccess = @($controlScore.dimensions | Where-Object dimension_id -eq 'task_success')[0]
            Assert-True ($controlTaskSuccess.score -eq 7) "numeric adjudication median expected 7, got $($controlTaskSuccess.score)"
            Assert-True ($abkCard.outcome -eq 'CANDIDATE') "expected synthetic all-7 abk outcome CANDIDATE, got $($abkCard.outcome)"
        } else {
            Assert-True ($controlCard.status -eq 'running' -and $controlCard.outcome -eq 'UNSCORED') 'inconclusive adjudication did not fail closed'
            Assert-True ($controlCard.branch_scores.Count -eq 0) 'inconclusive adjudication produced a branch score'
            Assert-True ($controlCard.rationale -match 'REVIEW_ADJUDICATION_INCONCLUSIVE') 'inconclusive blocker is missing'
        }
        foreach ($card in Get-ChildItem -LiteralPath $scorecardRoot -Filter '*.json' -File) { Assert-True (Test-Json -LiteralPath $card.FullName -SchemaFile $adoptionSchema) "$($card.Name) adoption schema" }
    } finally {
        foreach ($path in @($reviewerRoot, $adjudicationRoot, $scorecardRoot)) { if (Test-Path -LiteralPath $path -PathType Container) { [IO.Directory]::Delete([IO.Path]::GetFullPath($path), $true) } }
    }
}

try {
    $numericDecision = New-Decision 'COM-01-normal-primary' 'task_success' 'numeric' 'median' 4 9 7 'abk:review:artifact-dag-core-v1-control-reviewer-01' 'abk:review:artifact-dag-core-v1-control-reviewer-02' $evidenceByBranch['control'][0]
    Invoke-Scenario ([guid]::NewGuid().ToString('N')) @{ 'COM-01-normal-primary|task_success' = 4 } @{ 'COM-01-normal-primary|task_success' = 9 } @($numericDecision) 'numeric'

    $inconclusiveDecision = New-Decision 'COM-01-normal-primary' 'task_success' 'authority' 'inconclusive' 4 9 7 'abk:review:artifact-dag-core-v1-control-reviewer-01' 'abk:review:artifact-dag-core-v1-control-reviewer-02' $evidenceByBranch['control'][0]
    Invoke-Scenario ([guid]::NewGuid().ToString('N')) @{ 'COM-01-normal-primary|task_success' = 4 } @{ 'COM-01-normal-primary|task_success' = 9 } @($inconclusiveDecision) 'inconclusive'
    Write-Output 'REVIEWER_ADJUDICATION_TESTS: 2/2 PASS'
} catch {
    throw
}

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'

$validatorPath = Join-Path $WorkspaceRoot 'work\scripts\validate-adoption-contracts.ps1'
$validatorSource = Get-Content -Raw -LiteralPath $validatorPath
$definitionStart = $validatorSource.IndexOf("`$ErrorActionPreference")
$definitionBoundary = $validatorSource.IndexOf("`n`$outputs =")
if ($definitionStart -lt 0 -or $definitionBoundary -lt 0 -or $definitionStart -ge $definitionBoundary) {
    throw 'TEST_HARNESS_INVALID: validator definition boundary was not found'
}
Invoke-Expression $validatorSource.Substring($definitionStart, $definitionBoundary - $definitionStart)

$outputs = Join-Path $WorkspaceRoot 'outputs'
$examples = Join-Path $WorkspaceRoot 'work\evidence-bundle\examples'
$manifestSchema = Read-Json (Join-Path $outputs '07-capability-component-pattern-adoption.schema.json')
$scorecardSchema = Read-Json (Join-Path $outputs '09-adoption-scorecard.schema.json')
$manifestBase = Read-Json (Join-Path $examples 'capability-component-pattern-adoption.example.json')
$scorecardBase = Read-Json (Join-Path $examples 'adoption-scorecard.pending.example.json')

function Clone-Document($Document) {
    return $Document | ConvertTo-Json -Depth 100 | ConvertFrom-Json
}

function Set-Property($Document, [string]$Path, $Value) {
    Apply-Mutation $Document ([pscustomobject]@{ operation = 'set'; path = $Path; value = $Value })
}

function New-BranchScore([string]$Branch, [double]$Score, [string]$EvidenceId) {
    $ids = @(
        'task_success',
        'correctness_and_evidence',
        'repeatability',
        'state_and_error_observability',
        'stop_and_recovery',
        'context_and_token_efficiency',
        'runtime_and_operational_overhead',
        'composition_and_handoff',
        'useful_autonomy',
        'understandability_and_maintainability'
    )
    $dimensions = for ($index = 0; $index -lt $ids.Count; $index++) {
        [pscustomobject]@{
            dimension_id = $ids[$index]
            critical = $index -lt 5
            score = $Score
            weight = 0.1
            rationale = 'Synthetic regression input proving that pending hard gates cannot produce CHOSEN.'
            evidence_ids = @($EvidenceId)
        }
    }
    return [pscustomobject]@{
        branch = $Branch
        dimensions = $dimensions
        critical_minimum = $Score
        weighted_average = $Score
        calculation = 'round3(sum(score*weight))'
        evidence_ids = @($EvidenceId)
    }
}

function New-CompleteScorecard([double]$Score, [string]$Outcome) {
    $document = Clone-Document $scorecardBase
    foreach ($gate in $document.hard_gates) { $gate.status = 'pass' }
    $runIds = 1..66 | ForEach-Object { 'run_{0:d3}' -f $_ }
    $document.status = 'complete'
    $document.benchmark.status = 'complete'
    $document.benchmark.completed_primary_cells = 30
    $document.benchmark.completed_raw_runs = 66
    $document.benchmark.run_evidence_ids = @($runIds)
    $document.branch_scores = @(
        (New-BranchScore 'control' $Score $runIds[0]),
        (New-BranchScore 'source_native' $Score $runIds[0]),
        (New-BranchScore 'abk_native' $Score $runIds[0])
    )
    $document.outcome = $Outcome
    $protocolHash = $document.evidence[0].content_sha256
    $runEvidence = foreach ($runId in $runIds) {
        [pscustomobject]@{
            evidence_id = $runId
            status = 'passed'
            locator = "benchmarks/synthetic/runs/$runId/run.json"
            content_sha256 = $protocolHash
            summary = 'Synthetic contract fixture used only to verify complete-campaign validation invariants.'
        }
    }
    $document.evidence = @($document.evidence) + @($runEvidence)
    return $document
}

function Assert-Rejected($Document, [string]$Kind, [string]$ExpectedError, [string]$Name) {
    $caught = $null
    try {
        if ($Kind -eq 'manifest') { Validate-Manifest $Document $manifestSchema }
        else { Validate-Scorecard $Document $scorecardSchema }
    }
    catch { $caught = $_.Exception.Message.Split(':')[0] }
    if ($caught -ne $ExpectedError) {
        throw "REGRESSION_BYPASS: $Name expected $ExpectedError but got $caught"
    }
    [pscustomobject]@{ Test = $Name; Expected = $ExpectedError; Result = 'PASS' }
}

function Assert-Accepted($Document, [string]$ExpectedOutcome, [string]$Name) {
    if (-not (Test-Json -Json ($Document | ConvertTo-Json -Depth 100) -SchemaFile (Join-Path $outputs '09-adoption-scorecard.schema.json') -ErrorAction Stop)) {
        throw "REGRESSION_SCHEMA_FAILURE: $Name"
    }
    Validate-Scorecard $Document $scorecardSchema
    if ($Document.outcome -ne $ExpectedOutcome) { throw "REGRESSION_OUTCOME_MISMATCH: $Name" }
    [pscustomobject]@{ Test = $Name; Expected = $ExpectedOutcome; Result = 'PASS' }
}

$results = @()

$runningChosen = Clone-Document $scorecardBase
Set-Property $runningChosen '/status' 'running'
Set-Property $runningChosen '/benchmark' ([pscustomobject]@{
    status = 'running'
    case_count = 10
    common_case_count = 6
    specific_case_count = 4
    branches = @('control', 'source_native', 'abk_native')
    primary_cell_count = 30
    case_repeat_policy = $scorecardBase.benchmark.case_repeat_policy
    expected_raw_runs = 66
    completed_primary_cells = 0
    completed_raw_runs = 0
    run_evidence_ids = @()
})
Set-Property $runningChosen '/outcome' 'CHOSEN'
$results += Assert-Rejected $runningChosen 'scorecard' 'PREMATURE_OUTCOME' 'running scorecard cannot be CHOSEN'

$directAdopted = Clone-Document $manifestBase
Set-Property $directAdopted '/runtime_independence' ([pscustomobject]@{
    upstream_runtime_required = $false
    upstream_package_required = $false
    codex_local_reproducible = $true
    independence_evidence_ids = @('benchmark_protocol')
})
Set-Property $directAdopted '/lifecycle' ([pscustomobject]@{
    current_state = 'ADOPTED'
    history = @([pscustomobject]@{
        sequence = 1
        from = 'DISCOVERED'
        to = 'ADOPTED'
        occurred_at = '2026-08-02T20:00:00Z'
        approval_id = 'approval_m0'
        evidence_ids = @('benchmark_protocol')
    })
})
$results += Assert-Rejected $directAdopted 'manifest' 'LIFECYCLE_TRANSITION_INVALID' 'ADOPTED must transition from CHOSEN'

$pendingGateChosen = Clone-Document $scorecardBase
Set-Property $pendingGateChosen '/status' 'complete'
Set-Property $pendingGateChosen '/benchmark' ([pscustomobject]@{
    status = 'complete'
    case_count = 10
    common_case_count = 6
    specific_case_count = 4
    branches = @('control', 'source_native', 'abk_native')
    primary_cell_count = 30
    case_repeat_policy = $scorecardBase.benchmark.case_repeat_policy
    expected_raw_runs = 66
    completed_primary_cells = 30
    completed_raw_runs = 66
    run_evidence_ids = @()
})
Set-Property $pendingGateChosen '/branch_scores' @(
    (New-BranchScore 'control' 8 'benchmark_protocol'),
    (New-BranchScore 'source_native' 8 'benchmark_protocol'),
    (New-BranchScore 'abk_native' 8 'benchmark_protocol')
)
Set-Property $pendingGateChosen '/outcome' 'CHOSEN'
$results += Assert-Rejected $pendingGateChosen 'scorecard' 'HARD_GATE_NOT_PASSED' 'complete CHOSEN requires all hard gates to pass'

$undeclaredSideEffect = Clone-Document $manifestBase
$undeclaredSideEffect.side_effect_profile.operations[0].declared = $false
$results += Assert-Rejected $undeclaredSideEffect 'manifest' 'SIDE_EFFECT_UNDECLARED' 'undeclared side effects fail closed'

$incompleteRunEvidence = New-CompleteScorecard 8 'CHOSEN'
$incompleteRunEvidence.benchmark.run_evidence_ids = @($incompleteRunEvidence.benchmark.run_evidence_ids | Select-Object -First 65)
$results += Assert-Rejected $incompleteRunEvidence 'scorecard' 'RUN_EVIDENCE_COUNT_INVALID' 'complete campaign requires one evidence ID per raw run'

$invalidScore = New-CompleteScorecard 11 'CHOSEN'
$results += Assert-Rejected $invalidScore 'scorecard' 'SCORE_RANGE_INVALID' 'dimension scores outside 1..10 fail closed'

$results += Assert-Accepted (New-CompleteScorecard 3 'REJECTED') 'REJECTED' 'critical score at most 4 is REJECTED'
$results += Assert-Accepted (New-CompleteScorecard 7 'CANDIDATE') 'CANDIDATE' 'weighted average below 8 is CANDIDATE'
$results += Assert-Accepted (New-CompleteScorecard 8 'CHOSEN') 'CHOSEN' 'weighted average at least 8 is CHOSEN'

$escapedEvidence = Clone-Document $manifestBase
$escapedEvidence.evidence[0].locator = '../outside-workspace.json'
$caught = $null
try { Assert-LocalEvidenceFiles $escapedEvidence $WorkspaceRoot }
catch { $caught = $_.Exception.Message.Split(':')[0] }
if ($caught -ne 'EVIDENCE_PATH_ESCAPE') {
    throw "REGRESSION_BYPASS: evidence locator path escape expected EVIDENCE_PATH_ESCAPE but got $caught"
}
$results += [pscustomobject]@{ Test = 'evidence locator cannot escape workspace'; Expected = 'EVIDENCE_PATH_ESCAPE'; Result = 'PASS' }

$unearnedAdoption = Clone-Document $manifestBase
$unearnedAdoption.runtime_independence.codex_local_reproducible = $true
$unearnedAdoption.lifecycle = [pscustomobject]@{
    current_state = 'ADOPTED'
    history = @(
        [pscustomobject]@{ sequence = 1; from = 'DISCOVERED'; to = 'VALIDATED'; occurred_at = '2026-08-02T20:00:00Z'; approval_id = $null; evidence_ids = @('benchmark_protocol') },
        [pscustomobject]@{ sequence = 2; from = 'VALIDATED'; to = 'CHOSEN'; occurred_at = '2026-08-02T20:01:00Z'; approval_id = $null; evidence_ids = @('benchmark_protocol') },
        [pscustomobject]@{ sequence = 3; from = 'CHOSEN'; to = 'ADOPTED'; occurred_at = '2026-08-02T20:02:00Z'; approval_id = 'approval_m0'; evidence_ids = @('benchmark_protocol') }
    )
}
$caught = $null
try { Validate-AdoptionLink $unearnedAdoption $scorecardBase }
catch { $caught = $_.Exception.Message.Split(':')[0] }
if ($caught -ne 'LINKED_SCORECARD_NOT_CHOSEN') {
    throw "REGRESSION_BYPASS: ADOPTED manifest with pending scorecard expected LINKED_SCORECARD_NOT_CHOSEN but got $caught"
}
$results += [pscustomobject]@{ Test = 'CHOSEN or ADOPTED requires linked complete CHOSEN scorecard'; Expected = 'LINKED_SCORECARD_NOT_CHOSEN'; Result = 'PASS' }

$wrongBackReference = Clone-Document $scorecardBase
$wrongBackReference.candidate_manifest_id = 'abk:pattern-adoption:different-candidate'
$caught = $null
try { Validate-AdoptionLink $manifestBase $wrongBackReference }
catch { $caught = $_.Exception.Message.Split(':')[0] }
if ($caught -ne 'LINKED_MANIFEST_ID_MISMATCH') {
    throw "REGRESSION_BYPASS: scorecard back-reference mismatch expected LINKED_MANIFEST_ID_MISMATCH but got $caught"
}
$results += [pscustomobject]@{ Test = 'scorecard must point back to the same manifest'; Expected = 'LINKED_MANIFEST_ID_MISMATCH'; Result = 'PASS' }

$results | ConvertTo-Json -Depth 6

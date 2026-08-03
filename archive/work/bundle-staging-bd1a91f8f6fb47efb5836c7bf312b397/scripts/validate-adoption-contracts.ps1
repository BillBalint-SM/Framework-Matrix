param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Code, [string]$Message) {
    throw [InvalidOperationException]::new("${Code}: $Message")
}

function Read-Json([string]$Path) {
    try {
        return Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    }
    catch {
        Fail 'JSON_INVALID' "Cannot parse ${Path}: $($_.Exception.Message)"
    }
}

function Assert-ExactRoot($Document, $Schema) {
    $actual = @($Document.psobject.Properties.Name)
    $allowed = @($Schema.properties.psobject.Properties.Name)
    foreach ($required in @($Schema.required)) {
        if ($required -notin $actual) { Fail 'ROOT_REQUIRED_MISSING' "Missing root property '$required'" }
    }
    foreach ($name in $actual) {
        if ($name -notin $allowed) { Fail 'ROOT_ADDITIONAL_PROPERTY' "Unknown root property '$name'" }
    }
}

function Assert-NoExtensionProperties($Value, [string]$Path) {
    if ($null -eq $Value) { return }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string] -and $Value -isnot [pscustomobject]) {
        $index = 0
        foreach ($item in $Value) { Assert-NoExtensionProperties $item "$Path[$index]"; $index++ }
        return
    }
    if ($Value -is [pscustomobject]) {
        foreach ($property in $Value.psobject.Properties) {
            if ($property.Name -eq 'extensions' -or $property.Name -match '^x[-_]') {
                Fail 'VENDOR_EXTENSION_FORBIDDEN' "Vendor extension property at $Path.$($property.Name)"
            }
            Assert-NoExtensionProperties $property.Value "$Path.$($property.Name)"
        }
    }
}

function Assert-Unique([object[]]$Values, [string]$Code, [string]$Label) {
    if (@($Values | Sort-Object -Unique).Count -ne @($Values).Count) { Fail $Code "Duplicate $Label" }
}

function Assert-EvidenceReferences($Document) {
    $ids = @($Document.evidence | ForEach-Object { $_.evidence_id })
    Assert-Unique $ids 'EVIDENCE_DUPLICATE' 'evidence ID'
    $references = [System.Collections.Generic.List[string]]::new()
    function Visit($Value) {
        if ($null -eq $Value) { return }
        if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string] -and $Value -isnot [pscustomobject]) {
            foreach ($item in $Value) { Visit $item }
            return
        }
        if ($Value -is [pscustomobject]) {
            foreach ($property in $Value.psobject.Properties) {
                if ($property.Name -in @('evidence_ids', 'independence_evidence_ids', 'decision_evidence_ids', 'run_evidence_ids')) {
                    foreach ($id in @($property.Value)) { if ($id) { $references.Add([string]$id) } }
                }
                else { Visit $property.Value }
            }
        }
    }
    Visit $Document
    foreach ($reference in $references) {
        if ($reference -notin $ids) { Fail 'EVIDENCE_REFERENCE_DANGLING' "Unknown evidence ID '$reference'" }
    }
}

function Assert-LocalEvidenceFiles($Document, [string]$Root) {
    $resolvedRoot = [IO.Path]::GetFullPath($Root).TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    foreach ($item in @($Document.evidence)) {
        $relativeLocator = ([string]$item.locator).Replace('/', [IO.Path]::DirectorySeparatorChar)
        $resolvedLocator = [IO.Path]::GetFullPath((Join-Path $resolvedRoot $relativeLocator))
        if (-not $resolvedLocator.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
            Fail 'EVIDENCE_PATH_ESCAPE' "Evidence '$($item.evidence_id)' escapes the workspace"
        }
        if (-not (Test-Path -LiteralPath $resolvedLocator -PathType Leaf)) {
            Fail 'EVIDENCE_FILE_MISSING' "Evidence '$($item.evidence_id)' file does not exist: $($item.locator)"
        }
        $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedLocator).Hash.ToLowerInvariant()
        if ($actualHash -ne ([string]$item.content_sha256).ToLowerInvariant()) {
            Fail 'EVIDENCE_HASH_MISMATCH' "Evidence '$($item.evidence_id)' hash does not match $($item.locator)"
        }
    }
}

function Validate-Manifest($Document, $Schema) {
    Assert-ExactRoot $Document $Schema
    Assert-NoExtensionProperties $Document '$'
    if ($Document.schema_version -ne '1.0.0') { Fail 'SCHEMA_VERSION_INVALID' 'Manifest schema_version must be 1.0.0' }
    if ($Document.runtime_independence.upstream_runtime_required -ne $false) { Fail 'UPSTREAM_RUNTIME_FORBIDDEN' 'Upstream runtime dependency is forbidden' }
    if ($Document.runtime_independence.upstream_package_required -ne $false) { Fail 'UPSTREAM_PACKAGE_FORBIDDEN' 'Upstream package dependency is forbidden' }
    if ($Document.provenance.license_is_quality_gate -ne $false) { Fail 'LICENSE_SCORE_FORBIDDEN' 'License cannot be an empirical quality gate' }
    if ($Document.side_effect_profile.undocumented_effect_policy -ne 'STOPPED') { Fail 'UNDOCUMENTED_EFFECT_POLICY_INVALID' 'Undocumented side effects must stop execution' }
    foreach ($operation in @($Document.side_effect_profile.operations)) {
        if ($operation.declared -ne $true) { Fail 'SIDE_EFFECT_UNDECLARED' "Side effect '$($operation.effect_id)' is not declared" }
        if (-not $operation.reversible -and [string]::IsNullOrWhiteSpace($operation.recovery)) { Fail 'RECOVERY_MISSING' "Side effect '$($operation.effect_id)' lacks recovery" }
    }
    $evidenceIds = @($Document.evidence | ForEach-Object { $_.evidence_id })
    Assert-Unique $evidenceIds 'EVIDENCE_DUPLICATE' 'evidence ID'
    $history = @($Document.lifecycle.history)
    $previous = 'DISCOVERED'
    for ($i = 0; $i -lt $history.Count; $i++) {
        $transition = $history[$i]
        if ($transition.sequence -ne ($i + 1)) { Fail 'LIFECYCLE_SEQUENCE_INVALID' 'Lifecycle sequence is not contiguous' }
        if ($transition.from -ne $previous) { Fail 'LIFECYCLE_CHAIN_INVALID' "Expected lifecycle from '$previous'" }
        if ($transition.to -eq 'CHOSEN' -and $transition.from -ne 'VALIDATED') { Fail 'LIFECYCLE_TRANSITION_INVALID' 'CHOSEN must transition from VALIDATED' }
        if ($transition.to -eq 'ADOPTED' -and $transition.from -ne 'CHOSEN') { Fail 'LIFECYCLE_TRANSITION_INVALID' 'ADOPTED must transition from CHOSEN' }
        $previous = $transition.to
    }
    if ($history.Count -gt 0 -and $previous -ne $Document.lifecycle.current_state) { Fail 'LIFECYCLE_CURRENT_STATE_MISMATCH' 'Lifecycle current_state does not match history' }
    if ($Document.lifecycle.current_state -in @('REPRODUCED','ISOLATED_TRIAL','ABK_NATIVE_PROTOTYPE','COMPARATIVE_PILOT','VALIDATED','CHOSEN','ADOPTED') -and -not $Document.runtime_independence.codex_local_reproducible) {
        Fail 'CODEX_REPRODUCTION_REQUIRED' 'Advanced lifecycle state requires Codex-local reproduction'
    }
    if ($Document.lifecycle.current_state -in @('CHOSEN','ADOPTED') -and $null -eq $Document.benchmark_scorecard_id) { Fail 'SCORECARD_REQUIRED' 'CHOSEN/ADOPTED requires a scorecard' }
    if ($Document.lifecycle.current_state -eq 'ADOPTED') {
        if ($history.Count -eq 0 -or $null -eq $history[-1].approval_id) { Fail 'ADOPTION_APPROVAL_REQUIRED' 'ADOPTED requires explicit approval' }
    }
    Assert-EvidenceReferences $Document
}

function Validate-Scorecard($Document, $Schema) {
    Assert-ExactRoot $Document $Schema
    Assert-NoExtensionProperties $Document '$'
    if ($Document.schema_version -ne '1.0.0') { Fail 'SCHEMA_VERSION_INVALID' 'Scorecard schema_version must be 1.0.0' }
    if ($Document.host -ne 'codex') { Fail 'HOST_INVALID' 'Only Codex is allowed' }
    $requiredGates = @('observable_state_and_errors','testable_behavior','declared_authority_and_side_effects','reversible_or_recoverable','upstream_runtime_independence','no_undocumented_side_effects')
    $gateIds = @($Document.hard_gates | ForEach-Object { $_.gate_id })
    if ($gateIds.Count -ne 6) { Fail 'HARD_GATE_COUNT_INVALID' 'Exactly six hard gates are required' }
    Assert-Unique $gateIds 'HARD_GATE_DUPLICATE' 'hard gate'
    foreach ($gate in $requiredGates) { if ($gate -notin $gateIds) { Fail 'HARD_GATE_MISSING' "Missing hard gate '$gate'" } }

    $benchmark = $Document.benchmark
    if ($benchmark.case_count -ne 10 -or $benchmark.common_case_count -ne 6 -or $benchmark.specific_case_count -ne 4) { Fail 'CASE_COUNT_INVALID' 'Benchmark must contain 6 common + 4 specific cases' }
    $branches = @($benchmark.branches)
    if ($branches.Count -ne 3 -or @($branches | Sort-Object -Unique).Count -ne 3 -or @('control','source_native','abk_native' | Where-Object { $_ -notin $branches }).Count -gt 0) { Fail 'BRANCH_SET_INVALID' 'Required branches are control, source_native, abk_native' }
    if ($benchmark.primary_cell_count -ne 30) { Fail 'PRIMARY_CELL_COUNT_INVALID' 'Primary cell count must be 30' }
    $policies = @($benchmark.case_repeat_policy)
    if ($policies.Count -ne 10) { Fail 'CASE_POLICY_COUNT_INVALID' 'Exactly ten case repeat policies are required' }
    $caseIds = @($policies | ForEach-Object { $_.case_id })
    Assert-Unique $caseIds 'CASE_DUPLICATE' 'case ID'
    if (@($policies | Where-Object case_class -eq 'common').Count -ne 6 -or @($policies | Where-Object case_class -eq 'component_specific').Count -ne 4) { Fail 'CASE_CLASS_COUNT_INVALID' 'Case classes must be 6 common + 4 component_specific' }
    $expectedRaw = 0
    foreach ($policy in $policies) {
        $expectedRepeat = if ($policy.model_dependent) { 3 } else { 1 }
        if ($policy.repeats -ne $expectedRepeat) { Fail 'REPEAT_POLICY_INVALID' "Case '$($policy.case_id)' has the wrong repeat count" }
        $expectedRaw += 3 * $expectedRepeat
    }
    if ($benchmark.expected_raw_runs -ne $expectedRaw) { Fail 'RAW_RUN_COUNT_MISMATCH' "Expected $expectedRaw raw runs" }

    if ($Document.status -ne 'complete') {
        if ($Document.outcome -ne 'UNSCORED') { Fail 'PREMATURE_OUTCOME' 'Pending benchmark must remain UNSCORED' }
        if ($Document.status -eq 'benchmark_pending') {
            if (@($Document.branch_scores).Count -ne 0) { Fail 'PREMATURE_SCORE' 'Pending benchmark cannot contain branch scores' }
            if ($benchmark.completed_primary_cells -ne 0 -or $benchmark.completed_raw_runs -ne 0) { Fail 'PREMATURE_RUN_COUNT' 'Pending benchmark cannot contain completed runs' }
            if ($benchmark.status -ne 'planned') { Fail 'BENCHMARK_STATUS_MISMATCH' 'benchmark_pending requires planned benchmark state' }
        }
        if ($Document.status -eq 'running' -and $benchmark.status -notin @('running', 'inconclusive')) { Fail 'BENCHMARK_STATUS_MISMATCH' 'running scorecard requires running or inconclusive benchmark state' }
    }

    if ($Document.status -eq 'complete') {
        if ($benchmark.status -ne 'complete') { Fail 'BENCHMARK_STATUS_MISMATCH' 'Complete scorecard requires complete benchmark state' }
        $unpassedGates = @($Document.hard_gates | Where-Object status -ne 'pass')
        if ($unpassedGates.Count -gt 0) { Fail 'HARD_GATE_NOT_PASSED' 'Complete scorecard requires all six hard gates to pass' }
        if ($benchmark.completed_primary_cells -ne 30 -or $benchmark.completed_raw_runs -ne $expectedRaw) { Fail 'COMPLETE_RUN_COUNT_INVALID' 'Complete benchmark has incomplete run counts' }
        $runEvidenceIds = @($benchmark.run_evidence_ids)
        if ($runEvidenceIds.Count -ne $expectedRaw) { Fail 'RUN_EVIDENCE_COUNT_INVALID' "Complete benchmark requires $expectedRaw unique run evidence IDs" }
        $evidenceById = @{}
        foreach ($item in @($Document.evidence)) { $evidenceById[$item.evidence_id] = $item }
        foreach ($runEvidenceId in $runEvidenceIds) {
            if (-not $evidenceById.ContainsKey($runEvidenceId) -or $evidenceById[$runEvidenceId].status -ne 'passed') {
                Fail 'RUN_EVIDENCE_INVALID' "Run evidence '$runEvidenceId' must exist and have passed status"
            }
        }
        $branchScores = @($Document.branch_scores)
        if ($branchScores.Count -ne 3) { Fail 'BRANCH_SCORE_COUNT_INVALID' 'Complete benchmark requires three branch scores' }
        $branchIds = @($branchScores | ForEach-Object { $_.branch })
        Assert-Unique $branchIds 'BRANCH_SCORE_DUPLICATE' 'branch score'
        $dimensionIds = @('task_success','correctness_and_evidence','repeatability','state_and_error_observability','stop_and_recovery','context_and_token_efficiency','runtime_and_operational_overhead','composition_and_handoff','useful_autonomy','understandability_and_maintainability')
        $criticalIds = @($dimensionIds[0..4])
        foreach ($branch in $branchScores) {
            $dimensions = @($branch.dimensions)
            if ($dimensions.Count -ne 10) { Fail 'DIMENSION_COUNT_INVALID' "Branch '$($branch.branch)' requires ten dimensions" }
            $ids = @($dimensions | ForEach-Object { $_.dimension_id })
            Assert-Unique $ids 'DIMENSION_DUPLICATE' 'dimension'
            foreach ($id in $dimensionIds) { if ($id -notin $ids) { Fail 'DIMENSION_MISSING' "Missing dimension '$id'" } }
            foreach ($dimension in $dimensions) {
                if ($dimension.score -lt 1 -or $dimension.score -gt 10) { Fail 'SCORE_RANGE_INVALID' "Score outside 1..10 for '$($dimension.dimension_id)'" }
                $shouldBeCritical = $dimension.dimension_id -in $criticalIds
                if ($dimension.critical -ne $shouldBeCritical) { Fail 'CRITICAL_FLAG_INVALID' "Wrong critical flag for '$($dimension.dimension_id)'" }
            }
            $weightSum = [math]::Round((($dimensions | Measure-Object -Property weight -Sum).Sum), 6)
            if ([math]::Abs($weightSum - 1) -gt 0.000001) { Fail 'WEIGHT_SUM_INVALID' "Weights sum to $weightSum" }
            $weighted = [math]::Round((($dimensions | ForEach-Object { $_.score * $_.weight } | Measure-Object -Sum).Sum), 3)
            if ([math]::Abs($weighted - $branch.weighted_average) -gt 0.000001) { Fail 'WEIGHTED_AVERAGE_MISMATCH' "Expected weighted average $weighted" }
            $criticalMinimum = ($dimensions | Where-Object critical | Measure-Object -Property score -Minimum).Minimum
            if ($criticalMinimum -ne $branch.critical_minimum) { Fail 'CRITICAL_MINIMUM_MISMATCH' "Expected critical minimum $criticalMinimum" }
        }
        $abk = $branchScores | Where-Object branch -eq 'abk_native'
        if ($null -eq $abk) { Fail 'ABK_BRANCH_MISSING' 'ABK-native score is required' }
        $gateFailed = @($Document.hard_gates | Where-Object status -eq 'fail').Count -gt 0
        $expectedOutcome = if ($gateFailed -or $abk.critical_minimum -le 4) { 'REJECTED' } elseif ($abk.weighted_average -lt 8) { 'CANDIDATE' } else { 'CHOSEN' }
        if ($Document.outcome -ne $expectedOutcome) { Fail 'OUTCOME_MISMATCH' "Expected outcome $expectedOutcome" }
    }
    Assert-EvidenceReferences $Document
}

function Validate-AdoptionLink($Manifest, $Scorecard) {
    if ($null -eq $Scorecard) { Fail 'LINKED_SCORECARD_MISSING' "Manifest '$($Manifest.manifest_id)' has no linked scorecard" }
    if ($Manifest.benchmark_scorecard_id -ne $Scorecard.scorecard_id) {
        Fail 'LINKED_SCORECARD_ID_MISMATCH' "Manifest scorecard ID does not match '$($Scorecard.scorecard_id)'"
    }
    if ($Scorecard.candidate_manifest_id -ne $Manifest.manifest_id) {
        Fail 'LINKED_MANIFEST_ID_MISMATCH' "Scorecard candidate_manifest_id does not point back to '$($Manifest.manifest_id)'"
    }
    if ($Manifest.lifecycle.current_state -in @('CHOSEN', 'ADOPTED')) {
        if ($Scorecard.status -ne 'complete' -or $Scorecard.benchmark.status -ne 'complete' -or $Scorecard.outcome -ne 'CHOSEN') {
            Fail 'LINKED_SCORECARD_NOT_CHOSEN' "Manifest state '$($Manifest.lifecycle.current_state)' requires a complete CHOSEN scorecard"
        }
    }
}

function Apply-Mutation($Document, $Mutation) {
    $segments = @($Mutation.path.Trim('/') -split '/')
    $target = $Document
    for ($i = 0; $i -lt $segments.Count - 1; $i++) {
        $name = $segments[$i]
        if ($name -notin @($target.psobject.Properties.Name)) { Fail 'FIXTURE_PATH_INVALID' "Missing mutation path segment '$name'" }
        $target = $target.$name
    }
    $leaf = $segments[-1]
    if ($Mutation.operation -eq 'add') {
        if ($leaf -in @($target.psobject.Properties.Name)) { Fail 'FIXTURE_MUTATION_INVALID' "Property '$leaf' already exists" }
        $target | Add-Member -NotePropertyName $leaf -NotePropertyValue $Mutation.value
    }
    elseif ($Mutation.operation -eq 'set') {
        if ($leaf -notin @($target.psobject.Properties.Name)) { Fail 'FIXTURE_MUTATION_INVALID' "Property '$leaf' does not exist" }
        $target.$leaf = $Mutation.value
    }
    else { Fail 'FIXTURE_MUTATION_INVALID' "Unsupported mutation '$($Mutation.operation)'" }
}

$outputs = Join-Path $WorkspaceRoot 'outputs'
$examples = Join-Path $WorkspaceRoot 'work\evidence-bundle\examples'
$manifestSchema = Read-Json (Join-Path $outputs '07-capability-component-pattern-adoption.schema.json')
$scorecardSchema = Read-Json (Join-Path $outputs '09-adoption-scorecard.schema.json')
$manifestPath = Join-Path $examples 'capability-component-pattern-adoption.example.json'
$scorecardPath = Join-Path $examples 'adoption-scorecard.pending.example.json'
$manifest = Read-Json $manifestPath
$scorecard = Read-Json $scorecardPath
if (-not (Test-Json -LiteralPath $manifestPath -SchemaFile (Join-Path $outputs '07-capability-component-pattern-adoption.schema.json') -ErrorAction Stop)) {
    Fail 'MANIFEST_SCHEMA_INVALID' 'Positive manifest example failed Draft 7 JSON Schema validation'
}
if (-not (Test-Json -LiteralPath $scorecardPath -SchemaFile (Join-Path $outputs '09-adoption-scorecard.schema.json') -ErrorAction Stop)) {
    Fail 'SCORECARD_SCHEMA_INVALID' 'Positive scorecard example failed Draft 7 JSON Schema validation'
}
Validate-Manifest $manifest $manifestSchema
Validate-Scorecard $scorecard $scorecardSchema
Validate-AdoptionLink $manifest $scorecard
Assert-LocalEvidenceFiles $manifest $WorkspaceRoot
Assert-LocalEvidenceFiles $scorecard $WorkspaceRoot

$negativeResults = @()
foreach ($fixturePath in Get-ChildItem -LiteralPath (Join-Path $examples 'negative') -Filter '*.json' | Sort-Object Name) {
    $fixture = Read-Json $fixturePath.FullName
    $basePath = [IO.Path]::GetFullPath((Join-Path $fixturePath.DirectoryName $fixture.base))
    $document = Read-Json $basePath
    Apply-Mutation $document $fixture.mutation
    $caught = $null
    try {
        if ($basePath.EndsWith('adoption-scorecard.pending.example.json')) { Validate-Scorecard $document $scorecardSchema }
        else { Validate-Manifest $document $manifestSchema }
    }
    catch { $caught = $_.Exception.Message.Split(':')[0] }
    if ($null -eq $caught) { Fail 'NEGATIVE_FIXTURE_PASSED' "Negative fixture '$($fixturePath.Name)' unexpectedly passed" }
    if ($caught -ne $fixture.expected_error) { Fail 'NEGATIVE_ERROR_MISMATCH' "Fixture '$($fixturePath.Name)' expected '$($fixture.expected_error)' but got '$caught'" }
    $negativeResults += [pscustomobject]@{ Fixture = $fixturePath.Name; Expected = $fixture.expected_error; Result = 'PASS' }
}

$scorecardDocuments = @(Get-ChildItem -LiteralPath $examples -Filter 'adoption-scorecard*.json' -File | ForEach-Object { Read-Json $_.FullName })
$manifestDocuments = @(Get-ChildItem -LiteralPath $examples -Filter '*pattern-adoption*.json' -File | ForEach-Object { Read-Json $_.FullName })
$completedCampaigns = @($scorecardDocuments | Where-Object status -eq 'complete').Count
$chosenCount = @($scorecardDocuments | Where-Object outcome -eq 'CHOSEN').Count
$adoptedCount = @($manifestDocuments | Where-Object { $_.lifecycle.current_state -eq 'ADOPTED' }).Count

[pscustomobject]@{
    ManifestExample = 'PASS'
    ScorecardExample = 'PASS'
    JsonSchemaExamples = 2
    NegativeFixtures = $negativeResults.Count
    NegativeResults = $negativeResults
    EmpiricalCampaignExecuted = $completedCampaigns -gt 0
    CompletedCampaigns = $completedCampaigns
    Chosen = $chosenCount
    Adopted = $adoptedCount
} | ConvertTo-Json -Depth 6

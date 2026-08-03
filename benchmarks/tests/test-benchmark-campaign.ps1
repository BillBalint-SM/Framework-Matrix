param(
    [Parameter(Mandatory = $true)]
    [string]$WorkspaceRoot
)

$ErrorActionPreference = 'Stop'
$campaignPath = Join-Path $WorkspaceRoot 'benchmarks\campaigns\artifact-dag-core-v1\campaign.json'
$validatorPath = Join-Path $WorkspaceRoot 'benchmarks\scripts\validate-benchmark-campaign.ps1'

function Invoke-Validator([string]$Path, [string]$Root) {
    & $validatorPath -CampaignPath $Path -WorkspaceRoot $Root
}

function Assert-ValidPendingCampaign {
    Invoke-Validator $campaignPath $WorkspaceRoot | Out-Null
    [pscustomobject]@{ Test = 'valid pending campaign is accepted'; Result = 'PASS' }
}

function Assert-CanonicalEvidenceLayout {
    $document = Get-Content -Raw -LiteralPath $campaignPath | ConvertFrom-Json
    $expected = @(
        'run.json',
        'stdout.log',
        'stderr.log',
        'tool-events.jsonl',
        'output-inventory.json',
        'oracle-result.json'
    )
    $actual = @($document.evidence_layout.required_files)
    if ((Compare-Object -ReferenceObject $expected -DifferenceObject $actual).Count -ne 0) {
        throw "TEST_FAILURE: canonical evidence layout must be stdout.log/stderr.log plus tool-events.jsonl and oracle-result.json"
    }
    [pscustomobject]@{ Test = 'canonical evidence layout is declared'; Result = 'PASS' }
}

function Assert-InvalidCampaign([string]$Name, [string]$ExpectedCode, [scriptblock]$Mutate) {
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('framework-matrix-benchmark-test-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    try {
        New-Item -ItemType Directory -Path (Join-Path $tempRoot 'benchmarks\campaigns') -Force | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $tempRoot 'benchmarks\schemas') -Force | Out-Null
        Copy-Item -LiteralPath (Split-Path $campaignPath) -Destination (Join-Path $tempRoot 'benchmarks\campaigns') -Recurse
        Copy-Item -LiteralPath (Join-Path $WorkspaceRoot 'benchmarks\schemas\benchmark-campaign.schema.json') -Destination (Join-Path $tempRoot 'benchmarks\schemas')
        $tempCampaign = Join-Path $tempRoot 'benchmarks\campaigns\artifact-dag-core-v1\campaign.json'
        $document = Get-Content -Raw -LiteralPath $tempCampaign | ConvertFrom-Json
        & $Mutate $document
        $document | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $tempCampaign -Encoding utf8NoBOM
        $caught = $null
        try { Invoke-Validator $tempCampaign $tempRoot | Out-Null }
        catch { $caught = $_.Exception.Message.Split(':')[0] }
        if ($caught -ne $ExpectedCode) {
            throw "TEST_FAILURE: $Name expected $ExpectedCode but got $caught"
        }
        [pscustomobject]@{ Test = $Name; Result = 'PASS' }
    } finally {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$results = @()
$results += Assert-ValidPendingCampaign
$results += Assert-CanonicalEvidenceLayout
$results += Assert-InvalidCampaign 'legacy txt evidence layout fails closed' 'EVIDENCE_LAYOUT_INVALID' { param($d) $d.evidence_layout.required_files = @('run.json', 'stdout.txt', 'stderr.txt', 'output-inventory.json') }
$results += Assert-InvalidCampaign 'duplicate case IDs fail closed' 'CASE_DUPLICATE' { param($d) $d.cases[1].case_id = $d.cases[0].case_id }
$results += Assert-InvalidCampaign 'model-dependent repeat count is enforced' 'REPEAT_POLICY_INVALID' { param($d) $d.cases[0].repeats = 1 }
$results += Assert-InvalidCampaign 'fixture path escape fails closed' 'FIXTURE_PATH_ESCAPE' { param($d) $d.cases[0].fixture = '../outside.json' }
$results += Assert-InvalidCampaign 'fixture hash drift fails closed' 'FIXTURE_HASH_MISMATCH' { param($d) $d.cases[0].fixture_sha256 = ('0' * 64) }
$results += Assert-InvalidCampaign 'pending campaign cannot claim an outcome' 'PREMATURE_OUTCOME' { param($d) $d.outcome = 'CHOSEN' }
$results += Assert-InvalidCampaign 'pending campaign cannot claim completed runs' 'PREMATURE_RUN_COUNT' { param($d) $d.completed_raw_runs = 1 }
$results | Format-Table -AutoSize

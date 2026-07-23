[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$manifestPath = "docs/verification/manifests/D0.5-v2.yml"
$invalidationPath = "docs/verification/invalidations/D0.5-v1.json"
$implementationPath = "tools/verification/Test-DependencyQualification.ps1"
$workflowPath = ".github/workflows/ci.yml"
$expectedManifestHash = "96d9dc5d2029846b0447b2bfb5f09f5e0a30699915138713ec1c6a84249197c4"
$failures = [System.Collections.Generic.List[string]]::new()
$passes = 0

function Get-NormalizedHash {
    param([string]$Path)

    $content = (Get-Content -Raw -Encoding UTF8 -LiteralPath $Path).
        Replace("`r`n", "`n").Replace("`r", "`n")
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($content))
        )).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Test-ReviewCondition {
    param(
        [bool]$Condition,
        [string]$Id,
        [string]$Message
    )

    if ($Condition) {
        $script:passes++
        Write-Host "PASS $Id $Message"
    } else {
        $script:failures.Add("$Id $Message")
        Write-Host "FAIL $Id $Message"
    }
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$invalidation = Get-Content -Raw -Encoding UTF8 -LiteralPath $invalidationPath | ConvertFrom-Json
$implementation = Get-Content -Raw -Encoding UTF8 -LiteralPath $implementationPath
$workflow = Get-Content -Raw -Encoding UTF8 -LiteralPath $workflowPath

Test-ReviewCondition `
    ((Get-NormalizedHash $manifestPath) -ceq $expectedManifestHash -and
        $manifest.manifestId -ceq "D0.5-v2" -and
        $manifest.previousManifestId -ceq "D0.5-v1" -and
        $invalidation.frozenArtifactSha256 -ceq
            "3ba590b540db3838e69ade6a9f298bc139ecc567f9feccae630fd940e103a716" -and
        $invalidation.replacementManifestId -ceq "D0.5-v2") `
    "REVIEW-FREEZE" `
    "v2 and the v1 invalidation are immutable and linked"

Test-ReviewCondition `
    ($implementation.Contains("DOWNLOADED_CHECKPOINT_WHEEL") -and
        $implementation.Contains("installedWheelSha256") -and
        -not $implementation.Contains(
            '@("-m", "pip", "install", "langgraph-checkpoint-sqlite==3.1.0")'
        )) `
    "REVIEW-WHEEL" `
    "the installed wheel is the exact downloaded and hashed file"

Test-ReviewCondition `
    ($implementation.Contains("Invoke-BoundedCapturedCommand") -and
        $implementation.Contains("TimeoutSeconds") -and
        $implementation.Contains("attemptNumber") -and
        $implementation.Contains("processTreeTerminated") -and
        $implementation.Contains('retryPolicy = "none"')) `
    "REVIEW-BOUNDS" `
    "every external operation has a timeout, attempt record, tree termination, and no-retry policy"

Test-ReviewCondition `
    ($implementation.Contains('"AuditEvidence"') -and
        $implementation.Contains("Get-EvidencePrivacyFailures") -and
        $implementation.Contains("URL-CREDENTIALS") -and
        $implementation.Contains("MACHINE-IDENTITY") -and
        $workflow.Contains("steps.evidence_audit.outcome == 'success'")) `
    "REVIEW-PRIVACY" `
    "complete and partial evidence is audited before CI upload"

Test-ReviewCondition `
    ($implementation.Contains("dependency-tool-versions-v1.schema.json") -and
        $implementation.Contains("dependency-wheel-evidence-v1.schema.json") -and
        $implementation.Contains("DOTNET-RESTORE-LOG") -and
        $implementation.Contains("PIP-CHECK-LOG") -and
        $implementation.Contains("IMPORT-SMOKE-LOG") -and
        $implementation.Contains("TOOL-VERSION") -and
        $implementation.Contains("generated result satisfies Draft 2020-12 schema")) `
    "REVIEW-SEMANTICS" `
    "tool, wheel, result, and success logs have schema/semantic mutation oracles"

Test-ReviewCondition `
    ($implementation.Contains('$capturedSourceSha') -and
        $implementation.Contains('git archive --format=zip --output=$archivePath $capturedSourceSha') -and
        $implementation.Contains("SOURCE-DRIFT") -and
        $implementation.Contains("SOURCE-IDENTITY-MISMATCH")) `
    "REVIEW-SOURCE" `
    "one SHA is captured, archived explicitly, drift-checked, and bound to source identity"

if ($failures.Count -gt 0) {
    throw "D0.5 integration-review RED ($($failures.Count) gaps): $($failures -join '; ')"
}

Write-Host "D0.5 integration-review contract passed ($passes probes; unexpected skips=0)."

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$manifestPath = "docs/verification/manifests/D0.5-v3.yml"
$invalidationPath = "docs/verification/invalidations/D0.5-v2.json"
$implementationPath = "tools/verification/Test-DependencyQualification.ps1"
$workflowPath = ".github/workflows/ci.yml"
$requiredChecksPath = ".github/ci/required-checks.json"
$attributesPath = ".gitattributes"
$attributeTestPath = "tools/ci/Test-DependencyEvidenceAttributes.ps1"
$ciDeliveryTestPath = "tools/ci/Test-CiDelivery.ps1"
$ciVerifierPath = "tools/ci/Verify-CiWorkflow.ps1"
$expectedManifestHash = "990073c5256b333e6845c54b1376325df6042884d656d42d7cde11563da736f6"
$expectedManifestV1Hash = "3ba590b540db3838e69ade6a9f298bc139ecc567f9feccae630fd940e103a716"
$expectedManifestV2Hash = "96d9dc5d2029846b0447b2bfb5f09f5e0a30699915138713ec1c6a84249197c4"
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

function Get-WorkflowJobBlock {
    param([string]$JobId, [string]$Content)

    $lines = $Content -split "\r?\n"
    $start = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match "^  $([regex]::Escape($JobId)):\s*$") {
            $start = $index
            break
        }
    }
    if ($start -lt 0) { return "" }

    $end = $lines.Count
    for ($index = $start + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^  [A-Za-z0-9_-]+:\s*$') {
            $end = $index
            break
        }
    }
    return ($lines[$start..($end - 1)] -join "`n")
}

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
$invalidation = Get-Content -Raw -Encoding UTF8 -LiteralPath $invalidationPath | ConvertFrom-Json
$implementation = Get-Content -Raw -Encoding UTF8 -LiteralPath $implementationPath
$workflow = Get-Content -Raw -Encoding UTF8 -LiteralPath $workflowPath
$requiredChecks = Get-Content -Raw -Encoding UTF8 -LiteralPath $requiredChecksPath
$attributes = if (Test-Path -LiteralPath $attributesPath -PathType Leaf) {
    Get-Content -Raw -Encoding UTF8 -LiteralPath $attributesPath
} else {
    ""
}
$attributeTest = if (Test-Path -LiteralPath $attributeTestPath -PathType Leaf) {
    Get-Content -Raw -Encoding UTF8 -LiteralPath $attributeTestPath
} else {
    ""
}
$dependencyAttributeLines = @($attributes -split "\r?\n" |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -match '^docs/verification/dependencies/\*\*\s+' })
$ciDeliveryTest = Get-Content -Raw -Encoding UTF8 -LiteralPath $ciDeliveryTestPath
$ciVerifier = Get-Content -Raw -Encoding UTF8 -LiteralPath $ciVerifierPath
$verificationJob = Get-WorkflowJobBlock "verification-contracts" $workflow
$qualificationJob = Get-WorkflowJobBlock "dependency-qualification" $workflow

Test-ReviewCondition `
    ((Get-NormalizedHash $manifestPath) -ceq $expectedManifestHash -and
        $manifest.manifestId -ceq "D0.5-v3" -and
        $manifest.previousManifestId -ceq "D0.5-v2" -and
        $invalidation.invalidatedManifestId -ceq "D0.5-v2" -and
        $invalidation.frozenArtifactSha256 -ceq
            "96d9dc5d2029846b0447b2bfb5f09f5e0a30699915138713ec1c6a84249197c4" -and
        $invalidation.replacementManifestId -ceq "D0.5-v3") `
    "V3-FREEZE" `
    "v3 and the v2 invalidation are immutable and linked"

Test-ReviewCondition `
    ($implementation.Contains('"direct_url.json"') -and
        $implementation.Contains("pep610ArchiveSha256") -and
        $implementation.Contains("pep610UrlRetained") -and
        $implementation.Contains("Test-SupplementalInstallArguments") -and
        $implementation.Contains("PYTHON-INSTALL-LOG") -and
        $implementation.Contains("index-resolution actual-argument mutant")) `
    "V3-WHEEL-RUNTIME" `
    "runtime PEP 610 provenance, install-log semantics, and actual pip argument mutation are enforced"

Test-ReviewCondition `
    (-not $implementation.Contains("& git cat-file") -and
        -not $implementation.Contains('$output = & $python.Source') -and
        $implementation.Contains("CapturedProcessIds") -and
        $implementation.Contains("TerminationVerified") -and
        $implementation.Contains("parent-spawns-child") -and
        $implementation.Contains("both captured timeout PIDs exited")) `
    "V3-PROCESS-TREE" `
    "git/schema subprocesses are bounded and a real parent-child timeout proves every PID exited"

$ubuntuProbe = @($manifest.probes | Where-Object id -eq "D0.5-V-STATIC-UBUNTU")
$windowsProbe = @($manifest.probes | Where-Object id -eq "D0.5-V-STATIC-WINDOWS")
Test-ReviewCondition `
    ($ubuntuProbe.Count -eq 1 -and
        $ubuntuProbe[0].command -ceq
            "pwsh -NoProfile -File tools/verification/Test-DependencyQualification.ps1 -Mode Static" -and
        (@($ubuntuProbe[0].environmentIds) -join "|") -ceq "ENV-GHA-UBUNTU" -and
        $windowsProbe.Count -eq 1 -and
        $windowsProbe[0].command.StartsWith("powershell.exe ") -and
        (@($windowsProbe[0].environmentIds) -join "|") -ceq "ENV-WINDOWS-LOCAL" -and
        $workflow.Contains("Run D0.5 static probes on Ubuntu") -and
        $workflow.Contains(
            "./tools/verification/Test-DependencyQualification.ps1 -Mode Static"
        ) -and
        $workflow.Contains("dependency-qualification-static-tests.log") -and
        $requiredChecks.Contains("dependency-qualification-static-tests.log")) `
    "V3-UBUNTU-TRUTH" `
    "separate truthful commands exist and CI executes and archives Ubuntu pwsh static evidence"

Test-ReviewCondition `
    ($verificationJob -match '(?ms)uses:\s*actions/checkout@[0-9a-f]{40}.+?with:\s*\r?\n\s+ref:\s*\$\{\{\s*env\.SOURCE_SHA\s*\}\}\s*\r?\n\s+fetch-depth:\s*0\s*$' -and
        $qualificationJob -match '(?ms)uses:\s*actions/checkout@[0-9a-f]{40}.+?with:\s*\r?\n\s+ref:\s*\$\{\{\s*env\.SOURCE_SHA\s*\}\}\s*\r?\n\s+fetch-depth:\s*0\s*$' -and
        $implementation.Contains("historical-baseline jobs use full-history checkout") -and
        $implementation.Contains("shallow historical-baseline checkout mutant")) `
    "V3-HISTORICAL-CHECKOUT" `
    "both baseline-validating CI jobs fetch history and exact workflow mutations are rejected"

Test-ReviewCondition `
    ($implementation.Contains("manifest-invalidation-v1.schema.json") -and
        $implementation.Contains("docs/verification/manifests/D0.5-v1.yml") -and
        $implementation.Contains("docs/verification/manifests/D0.5-v2.yml") -and
        $implementation.Contains($expectedManifestV1Hash) -and
        $implementation.Contains($expectedManifestV2Hash) -and
        $implementation.Contains("historical manifest payload mutation") -and
        $implementation.Contains("immutable v1-v3 payload and invalidation chain")) `
    "V3-INVALIDATION-CHAIN" `
    "actual v1/v2 bytes, both schemas, full chronology, and historical-byte mutation are enforced"

Test-ReviewCondition `
    ($dependencyAttributeLines.Count -eq 1 -and
        $dependencyAttributeLines[0] -ceq "docs/verification/dependencies/** -text" -and
        $attributeTest.Contains("git check-attr text") -and
        $attributeTest.Contains("git hash-object") -and
        $attributeTest.Contains("Missing dependency-evidence attribute mutation survived") -and
        $attributeTest.Contains("Text-normalizing dependency-evidence attribute mutation survived") -and
        $implementation.Contains("Get-DependencyAttributeContractFailures") -and
        $implementation.Contains("missing dependency-evidence byte preservation") -and
        $implementation.Contains("text-normalized dependency evidence") -and
        $ciDeliveryTest.Contains("missing dependency-evidence byte-preservation rule") -and
        $ciDeliveryTest.Contains("text-normalized dependency evidence") -and
        $ciVerifier.Contains("dependency evidence must be declared -text")) `
    "V3-BYTE-PRESERVATION" `
    "raw generated evidence bytes survive Git checkout and missing/text mutations are rejected"

if ($failures.Count -gt 0) {
    throw "D0.5 v3 review RED ($($failures.Count) blocking gaps): $($failures -join '; ')"
}

Write-Host "D0.5 v3 review contract passed ($passes probes; unexpected skips=0)."

[CmdletBinding()]
param(
    [ValidateSet("Static", "HostedWindows")]
    [string]$Mode = "Static",
    [string]$EvidenceDirectory = "artifacts/ci/delivery-environment"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$readinessPath = "docs/verification/environments/D0.4-readiness-v1.json"
$readinessSchemaPath = "docs/verification/schemas/environment-readiness-v1.schema.json"
$riskSchemaPath = "docs/verification/schemas/risk-lane-manifest-v1.schema.json"
$riskManifestPath = "docs/verification/manifests/D0.4-v3.yml"
$riskManifestV1Path = "docs/verification/manifests/D0.4-v1.yml"
$riskManifestV1InvalidationPath = "docs/verification/invalidations/D0.4-v1.json"
$riskManifestV2Path = "docs/verification/manifests/D0.4-v2.yml"
$riskManifestV2InvalidationPath = "docs/verification/invalidations/D0.4-v2.json"
$invalidationSchemaPath = "docs/verification/schemas/manifest-invalidation-v1.schema.json"
$riskManifestV1RedEvidencePath = "docs/verification/evidence/D0.4-red.md"
$riskManifestV2RedEvidencePath = "docs/verification/evidence/D0.4-v2-red.md"
$riskManifestV3RedEvidencePath = "docs/verification/evidence/D0.4-v3-red.md"
$snapshotPath = "docs/verification/evidence/D0.4-github-snapshot.md"
$sourceIdentitySchemaPath = "docs/verification/schemas/delivery-source-identity-v1.schema.json"
$sourceIdentityPath = "docs/verification/evidence/D0.4-source-identity.json"
$schemaFallbackPath = "tools/verification/Validate-JsonSchema.py"
$requiredChecksPath = ".github/ci/required-checks.json"
$workflowPath = ".github/workflows/ci.yml"
$frozenRiskManifestSha256 = "3747f8520497b65544ef0cd1bb386b8e72866284001da408de111f454f0d614a"
$frozenBaselineSha = "b7eafb683d37d80bd60b59e850311acd79d2a569"
$expectedCapabilityIds = @(
    "CAP-BRANCH-PROTECTION",
    "CAP-CI-ARTIFACT-RETENTION",
    "CAP-CODE-SIGNING",
    "CAP-GHA-UBUNTU-EXACT-SHA",
    "CAP-GHA-WINDOWS-CAPABILITY-PROBE",
    "CAP-GHA-WINDOWS-RELEASE-BUILD",
    "CAP-INTERACTIVE-WIN10",
    "CAP-INTERACTIVE-WIN11",
    "CAP-LONG-TERM-ARCHIVE",
    "CAP-PILOT-HARDWARE-PARTICIPANTS",
    "CAP-PROVIDER-TERMS-CREDENTIALS",
    "CAP-SELF-HOSTED-RUNNER-LABELS"
)
$probeCount = 0
$hostedProbeCount = 0
$unexpectedSkips = 0
$activeRiskManifest = $null

function Write-ProbePass {
    param([string]$Message)
    $script:probeCount++
    Write-Host "PASS $Message"
}

function Write-HostedProbePass {
    param([string]$Message)
    $script:hostedProbeCount++
    Write-ProbePass $Message
}

function Get-NormalizedTextHash {
    param([string]$Path)

    $content = (Get-Content -Raw -Encoding UTF8 -LiteralPath $Path).Replace("`r`n", "`n").Replace("`r", "`n")
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($content)))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Test-InstanceAgainstSchema {
    param([string]$SchemaPath, [string]$InstancePath)

    $testJson = Get-Command Test-Json -ErrorAction SilentlyContinue
    if ($null -ne $testJson -and $PSVersionTable.PSVersion -ge [Version]"7.4") {
        $schema = Get-Content -Raw -Encoding UTF8 -LiteralPath $SchemaPath
        $instance = Get-Content -Raw -Encoding UTF8 -LiteralPath $InstancePath
        try {
            return ($instance | Test-Json -Schema $schema -ErrorAction Stop)
        } catch {
            return $false
        }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $python) {
        throw "Draft 2020-12 validation requires PowerShell 7.4+ or Python with pinned jsonschema."
    }
    $output = & $python.Source $schemaFallbackPath $SchemaPath $InstancePath 2>&1
    $exitCode = $LASTEXITCODE
    $global:LASTEXITCODE = 0
    if ($exitCode -eq 0) { return $true }
    if ($exitCode -eq 2) { return $false }
    throw "Draft 2020-12 validator could not run: $($output | Out-String)"
}

function Copy-JsonObject {
    param([object]$Value)
    return ($Value | ConvertTo-Json -Depth 20) | ConvertFrom-Json
}

function Test-RedEvidenceChronology {
    param([string]$Content, [DateTimeOffset]$ExpectedFrozenAt)

    $frozenMatch = [regex]::Match($Content, '(?m)^- Frozen at: `([^`]+)`$')
    $redMatch = [regex]::Match($Content, '(?m)^- RED completed at: `([^`]+)`$')
    $frozenAt = [DateTimeOffset]::MinValue
    $redAt = [DateTimeOffset]::MinValue
    return $frozenMatch.Success -and $redMatch.Success -and
        [DateTimeOffset]::TryParse($frozenMatch.Groups[1].Value, [ref]$frozenAt) -and
        [DateTimeOffset]::TryParse($redMatch.Groups[1].Value, [ref]$redAt) -and
        $frozenAt -eq $ExpectedFrozenAt -and $frozenAt -le $redAt
}

function Get-HostedBindingFailures {
    param([object]$Readiness, [object]$RuntimeEvidence, [object]$SourceIdentity, [string]$GreenContent)

    $failures = [System.Collections.Generic.List[string]]::new()
    $sourceSha = [string]$Readiness.verifiedSourceSha
    $runId = [string]$Readiness.verifiedRunId
    if ($RuntimeEvidence.sourceSha -cne $sourceSha -or
        $SourceIdentity.expectedSha -cne $sourceSha -or
        $SourceIdentity.actualSha -cne $sourceSha) {
        $failures.Add("HOSTED-SOURCE-MISMATCH")
    }
    if ($SourceIdentity.event -cne "push" -or [string]$SourceIdentity.runId -cne $runId) {
        $failures.Add("HOSTED-RUN-MISMATCH")
    }
    $expectedRunUrl = "https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/$runId"
    $requiredGreenLines = @(
        "- Implementation SHA: ``$sourceSha``",
        "- Push run ID: ``$runId``",
        "- Push run URL: ``$expectedRunUrl``",
        "- Hosted runtime evidence SHA-256: ``$($Readiness.hostedRuntimeEvidenceSha256)``",
        "- Source identity evidence SHA-256: ``$($Readiness.sourceIdentitySha256)``"
    )
    if (@($requiredGreenLines | Where-Object { -not $GreenContent.Contains($_) }).Count -gt 0) {
        $failures.Add("HOSTED-GREEN-BINDING")
    }
    return $failures.ToArray()
}

function Get-ReadinessFailures {
    param([object]$Readiness)

    $failures = [System.Collections.Generic.List[string]]::new()
    if ($Readiness.schemaVersion -ne 1 -or $Readiness.documentType -ne "delivery-environment-readiness" -or
        $Readiness.manifestId -ne "D0.4-READINESS-v1" -or $Readiness.riskManifestId -ne "D0.4-v3" -or
        $Readiness.baselineSha -ne $frozenBaselineSha -or
        $Readiness.riskManifestSha256 -ne $frozenRiskManifestSha256) {
        $failures.Add("READINESS-IDENTITY")
    }

    $capabilities = @($Readiness.capabilities)
    $actualIds = @($capabilities | ForEach-Object { $_.id } | Sort-Object)
    if (($actualIds -join "|") -cne (($expectedCapabilityIds | Sort-Object) -join "|") -or
        @($actualIds | Group-Object | Where-Object Count -gt 1).Count -gt 0) {
        $failures.Add("READINESS-CAPABILITY-SET")
    }

    $contracts = @($script:activeRiskManifest.capabilityContracts)
    $contractIds = @($contracts | ForEach-Object id | Sort-Object)
    if (($contractIds -join "|") -cne (($expectedCapabilityIds | Sort-Object) -join "|")) {
        $failures.Add("READINESS-CAPABILITY-CONTRACT")
    }
    foreach ($contract in $contracts) {
        $matches = @($capabilities | Where-Object id -eq $contract.id)
        if ($matches.Count -ne 1) { continue }
        $capability = $matches[0]
        $allowedStates = if ($Readiness.phase -eq "closure") { @($contract.closureStates) } else { @($contract.preflightStates) }
        if ($capability.ownerRole -cne $contract.ownerRole -or
            ((@($capability.requiredForSteps | Sort-Object) -join "|") -cne (@($contract.requiredForSteps | Sort-Object) -join "|")) -or
            [string]$capability.firstBlockingStep -cne [string]$contract.firstBlockingStep -or
            $allowedStates -notcontains $capability.state) {
            $failures.Add("READINESS-CAPABILITY-CONTRACT")
        }
    }

    foreach ($capability in $capabilities) {
        if ([string]::IsNullOrWhiteSpace([string]$capability.ownerRole) -or
            @($capability.requiredForSteps).Count -lt 1 -or
            $capability.containsPersonalData -ne $false -or $capability.containsSecretValues -ne $false) {
            $failures.Add("READINESS-OWNER-OR-DATA")
        }
        if ($capability.state -eq "ready") {
            if (@($capability.evidenceRefs).Count -lt 1 -or $null -eq $capability.verifiedAt -or
                [string]::IsNullOrWhiteSpace([string]$capability.observation)) {
                $failures.Add("READINESS-UNPROVEN-READY")
            }
        } elseif ($capability.state -in @("blocked", "pending")) {
            if ([string]::IsNullOrWhiteSpace([string]$capability.blockerReason) -or
                [string]::IsNullOrWhiteSpace([string]$capability.remediation) -or
                [string]::IsNullOrWhiteSpace([string]$capability.firstBlockingStep)) {
                $failures.Add("READINESS-FAIL-OPEN-BLOCKER")
            }
        }
    }

    $summary = $Readiness.summary
    $ready = @($capabilities | Where-Object state -eq "ready").Count
    $blocked = @($capabilities | Where-Object state -eq "blocked").Count
    $pending = @($capabilities | Where-Object state -eq "pending").Count
    if ([int]$summary.total -ne $capabilities.Count -or [int]$summary.ready -ne $ready -or
        [int]$summary.blocked -ne $blocked -or [int]$summary.pending -ne $pending -or
        ([int]$summary.ready + [int]$summary.blocked + [int]$summary.pending) -ne [int]$summary.total) {
        $failures.Add("READINESS-SUMMARY")
    }

    if ($Readiness.repository.nameWithOwner -ne "RickyT715/Aemeath_Desktop_Pet" -or
        $Readiness.repository.visibility -ne "PUBLIC" -or $Readiness.repository.defaultBranch -ne "main" -or
        [int]$Readiness.repository.rulesetCount -ne 0 -or
        [int]$Readiness.repository.selfHostedRunnerCount -ne 0 -or
        [int]$Readiness.repository.actionsSecretCount -ne 0 -or
        [int]$Readiness.repository.environmentCount -ne 0 -or
        $Readiness.repository.branchProtectionPermission -ne "ADMIN") {
        $failures.Add("READINESS-REPOSITORY-SNAPSHOT")
    }
    if ($Readiness.repository.snapshotPath -cne $script:snapshotPath -or
        -not (Test-Path -LiteralPath $script:snapshotPath -PathType Leaf) -or
        $Readiness.repository.snapshotSha256 -cne (Get-NormalizedTextHash $script:snapshotPath)) {
        $failures.Add("READINESS-SNAPSHOT-BINDING")
    }
    $branchCapabilities = @($capabilities | Where-Object id -eq "CAP-BRANCH-PROTECTION")
    if ($branchCapabilities.Count -eq 1 -and ($branchCapabilities[0].state -eq "ready") -and
        ($Readiness.repository.branchProtected -ne $true -or $Readiness.repository.branchProtectionPermission -ne "ADMIN")) {
        $failures.Add("READINESS-BRANCH-POLICY")
    }
    $runnerCapabilities = @($capabilities | Where-Object { $_.id -in @("CAP-INTERACTIVE-WIN10", "CAP-INTERACTIVE-WIN11", "CAP-SELF-HOSTED-RUNNER-LABELS") })
    if (@($runnerCapabilities | Where-Object state -eq "ready").Count -gt 0 -and
        [int]$Readiness.repository.selfHostedRunnerCount -lt 1) {
        $failures.Add("READINESS-RUNNER-CROSS-FIELD")
    }
    $hostedContract = $script:activeRiskManifest.hostedRuntimeContract
    $hostedCapabilities = @($capabilities | Where-Object id -eq $hostedContract.capabilityId)
    if ($hostedCapabilities.Count -eq 1 -and $hostedCapabilities[0].state -eq "ready") {
        $hostedEvidenceRefs = @($hostedCapabilities[0].evidenceRefs)
        if ([string]$Readiness.verifiedSourceSha -notmatch '^[0-9a-f]{40}$' -or
            [string]$Readiness.verifiedRunId -notmatch '^[1-9][0-9]*$' -or
            [string]$Readiness.hostedRuntimeEvidenceSha256 -notmatch '^[0-9a-f]{64}$' -or
            [string]$Readiness.sourceIdentitySha256 -notmatch '^[0-9a-f]{64}$' -or
            $Readiness.sourceIdentityPath -cne $script:sourceIdentityPath -or
            $hostedEvidenceRefs -notcontains [string]$hostedContract.evidencePath -or
            $hostedEvidenceRefs -notcontains [string]$hostedContract.greenEvidencePath -or
            $hostedEvidenceRefs -notcontains $script:sourceIdentityPath -or
            -not (Test-Path -LiteralPath ([string]$hostedContract.evidencePath) -PathType Leaf -ErrorAction SilentlyContinue) -or
            -not (Test-Path -LiteralPath ([string]$hostedContract.greenEvidencePath) -PathType Leaf -ErrorAction SilentlyContinue) -or
            -not (Test-Path -LiteralPath $script:sourceIdentityPath -PathType Leaf -ErrorAction SilentlyContinue) -or
            ((Test-Path -LiteralPath ([string]$hostedContract.evidencePath) -PathType Leaf -ErrorAction SilentlyContinue) -and
                $Readiness.hostedRuntimeEvidenceSha256 -cne (Get-NormalizedTextHash ([string]$hostedContract.evidencePath))) -or
            ((Test-Path -LiteralPath $script:sourceIdentityPath -PathType Leaf -ErrorAction SilentlyContinue) -and
                $Readiness.sourceIdentitySha256 -cne (Get-NormalizedTextHash $script:sourceIdentityPath))) {
            $failures.Add("READINESS-HOSTED-RUNTIME-EVIDENCE")
        }
    }

    if ($Readiness.dataHandling.personalDataStored -ne $false -or
        $Readiness.dataHandling.secretValuesStored -ne $false -or
        $Readiness.review.status -notin @("independently-reviewed", "pending-independent-review")) {
        $failures.Add("READINESS-DATA-OR-REVIEW")
    }
    return $failures.ToArray()
}

function Get-DiscoveryFailures {
    param([int]$TotalCount, [int]$HostedCount, [string]$ProbeMode)

    $failures = [System.Collections.Generic.List[string]]::new()
    $minimumStatic = [int]$script:activeRiskManifest.thresholds.minimumStaticDiscovery
    $minimumHosted = [int]$script:activeRiskManifest.hostedRuntimeContract.minimumHostedDiscovery
    if ($ProbeMode -eq "HostedWindows") {
        if ($HostedCount -lt $minimumHosted) { $failures.Add("DISCOVERY-HOSTED") }
        if (($TotalCount - $HostedCount) -lt $minimumStatic) { $failures.Add("DISCOVERY-STATIC") }
    } elseif ($TotalCount -lt $minimumStatic) {
        $failures.Add("DISCOVERY-STATIC")
    }
    return $failures.ToArray()
}

function Assert-MutationRejected {
    param([string]$Label, [scriptblock]$Mutate, [string]$ExpectedCode, [object]$Baseline)

    $copy = Copy-JsonObject $Baseline
    & $Mutate $copy
    $codes = @(Get-ReadinessFailures $copy)
    if ($codes -notcontains $ExpectedCode) {
        throw "Readiness mutation '$Label' did not produce '$ExpectedCode'; got '$($codes -join ', ')'."
    }
    Write-ProbePass "readiness mutation: $Label -> $ExpectedCode"
}

$requiredInputs = @(
    $readinessPath, $readinessSchemaPath, $riskSchemaPath, $riskManifestPath,
    $riskManifestV1Path, $riskManifestV1InvalidationPath,
    $riskManifestV2Path, $riskManifestV2InvalidationPath,
    $invalidationSchemaPath, $riskManifestV1RedEvidencePath, $riskManifestV2RedEvidencePath,
    $riskManifestV3RedEvidencePath,
    $snapshotPath, $sourceIdentitySchemaPath,
    $schemaFallbackPath, $requiredChecksPath, $workflowPath
)
$missing = @($requiredInputs | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missing.Count -gt 0) {
    throw "Delivery-environment contract inputs are missing: $($missing -join ', ')."
}

if (-not (Test-InstanceAgainstSchema $riskSchemaPath $riskManifestPath)) {
    throw "D0.4 frozen risk/lane manifest fails schema."
}
$activeRiskManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestPath | ConvertFrom-Json
if ((Get-NormalizedTextHash $riskManifestPath) -cne $frozenRiskManifestSha256) {
    throw "D0.4 frozen risk/lane manifest bytes changed after RED freeze."
}
Write-ProbePass "frozen D0.4 risk/lane manifest"
$hostedRuntimeSchemaPath = [string]$activeRiskManifest.hostedRuntimeContract.schemaPath
if (-not (Test-Path -LiteralPath $hostedRuntimeSchemaPath -PathType Leaf)) {
    throw "Frozen hosted-runtime schema is missing: $hostedRuntimeSchemaPath"
}
$hostedProbeContract = @($activeRiskManifest.probes | Where-Object id -eq "D0.4-V-REAL-E2E-HOSTED-WINDOWS")[0]
$expectedRequiredRuntimeAssertions = @(
    "cleanupVerified", "githubNetworkAllowed", "isolatedStorageRoundTrip",
    "personalDataCollectedFalse", "secretValuesCollectedFalse", "timeoutEnforced",
    "uiaAssembliesLoaded"
) | Sort-Object
$expectedObservationOnlyFields = @("displayProbeAvailable", "narratorObserved", "userInteractive") | Sort-Object
if ($activeRiskManifest.hostedRuntimeContract.capabilityId -cne "CAP-GHA-WINDOWS-CAPABILITY-PROBE" -or
    [int]$activeRiskManifest.hostedRuntimeContract.minimumHostedDiscovery -ne 9 -or
    [int]$hostedProbeContract.minimumDiscovery -ne 9 -or
    [int]$hostedProbeContract.thresholds.minimumHostedDiscovery -ne 9 -or
    ((@($activeRiskManifest.hostedRuntimeContract.requiredTrueFields | Sort-Object) -join "|") -cne ($expectedRequiredRuntimeAssertions -join "|")) -or
    ((@($activeRiskManifest.hostedRuntimeContract.observationOnlyFields | Sort-Object) -join "|") -cne ($expectedObservationOnlyFields -join "|"))) {
    throw "Frozen hosted-runtime evidence/discovery contract is not exact."
}

$frozenRiskManifestV1Sha256 = "de4d61a836e30c35e2c265c76bf48509506b0b797cc1d79b5aaff7c952490959"
$frozenRiskManifestV2Sha256 = "2f5d46d694443fc6d1c91ce594c9a4a43d03a91971773ec80e641a68bccbba0d"
$v2FrozenAt = [DateTimeOffset]::Parse("2026-07-22T12:07:56Z")
$v3FrozenAt = [DateTimeOffset]::Parse("2026-07-22T12:22:00Z")
$manifestV1 = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestV1Path | ConvertFrom-Json
$manifestV2 = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestV2Path | ConvertFrom-Json
if ($manifestV1.manifestId -cne "D0.4-v1" -or $manifestV1.status -cne "frozen-before-red" -or
    $manifestV2.previousManifestId -cne "D0.4-v1" -or
    $activeRiskManifest.previousManifestId -cne "D0.4-v2" -or
    (Get-NormalizedTextHash $riskManifestV1Path) -cne $frozenRiskManifestV1Sha256 -or
    (Get-NormalizedTextHash $riskManifestV2Path) -cne $frozenRiskManifestV2Sha256 -or
    -not (Test-InstanceAgainstSchema $invalidationSchemaPath $riskManifestV1InvalidationPath) -or
    -not (Test-InstanceAgainstSchema $invalidationSchemaPath $riskManifestV2InvalidationPath)) {
    throw "D0.4 v1-v3 immutable manifest chain is incomplete."
}
$invalidationV1 = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestV1InvalidationPath | ConvertFrom-Json
$invalidationV2 = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestV2InvalidationPath | ConvertFrom-Json
$invalidationV1At = [DateTimeOffset]::MinValue
$invalidationV2At = [DateTimeOffset]::MinValue
if ($invalidationV1.recordId -cne "D0.4-v1-invalidated-by-v2" -or
    $invalidationV1.invalidatedManifestId -cne "D0.4-v1" -or
    $invalidationV1.frozenArtifactPath -cne $riskManifestV1Path -or
    $invalidationV1.frozenArtifactSha256 -cne $frozenRiskManifestV1Sha256 -or
    $invalidationV1.replacementManifestId -cne "D0.4-v2" -or
    -not [DateTimeOffset]::TryParse([string]$invalidationV1.invalidatedAt, [ref]$invalidationV1At) -or
    $invalidationV1At -gt $v2FrozenAt -or
    $invalidationV2.recordId -cne "D0.4-v2-invalidated-by-v3" -or
    $invalidationV2.invalidatedManifestId -cne "D0.4-v2" -or
    $invalidationV2.frozenArtifactPath -cne $riskManifestV2Path -or
    $invalidationV2.frozenArtifactSha256 -cne $frozenRiskManifestV2Sha256 -or
    $invalidationV2.replacementManifestId -cne "D0.4-v3" -or
    -not [DateTimeOffset]::TryParse([string]$invalidationV2.invalidatedAt, [ref]$invalidationV2At) -or
    $invalidationV2At -gt $v3FrozenAt -or $invalidationV2At -lt $invalidationV1At) {
    throw "D0.4 invalidations do not bind their identities, bytes, replacements, and chronology."
}
Write-ProbePass "immutable D0.4 v1-v3 manifest/invalidation chain"

$v1RedEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestV1RedEvidencePath
$v2RedEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestV2RedEvidencePath
$v3RedEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestV3RedEvidencePath
$v1ChronologyMutation = $v1RedEvidence -replace '(?m)^- Frozen at: `[^`]+`$', '- Frozen at: `2099-01-01T00:00:00Z`'
$v1FrozenAt = [DateTimeOffset]::Parse("2026-07-22T11:55:09Z")
if (Test-RedEvidenceChronology $v1ChronologyMutation $v1FrozenAt) {
    throw "D0.4-v1 chronology mutation was accepted."
}
Write-ProbePass "D0.4-v1 RED chronology mutation"
$v2FrozenAtMatch = [regex]::Match($v2RedEvidence, '(?m)^- Frozen at: `([^`]+)`$')
$v2FirstRedMatch = [regex]::Match($v2RedEvidence, '(?m)^- RED completed at: `([^`]+)`$')
$parsedFrozenAt = [DateTimeOffset]::MinValue
$parsedRedAt = [DateTimeOffset]::MinValue
$v3FrozenAtMatch = [regex]::Match($v3RedEvidence, '(?m)^- Frozen at: `([^`]+)`$')
$v3FirstRedMatch = [regex]::Match($v3RedEvidence, '(?m)^- RED completed at: `([^`]+)`$')
$parsedV3FrozenAt = [DateTimeOffset]::MinValue
$parsedV3RedAt = [DateTimeOffset]::MinValue
if ($v1RedEvidence -notmatch '(?m)^- Frozen manifest: `D0\.4-v1`$' -or
    $v1RedEvidence -notmatch "(?m)^- Frozen manifest SHA-256: ``$frozenRiskManifestV1Sha256``$" -or
    $v1RedEvidence -notmatch '(?m)^- Exit code: `1` \(expected RED\)$' -or
    -not (Test-RedEvidenceChronology $v1RedEvidence $v1FrozenAt) -or
    $v2RedEvidence -notmatch '(?m)^- Frozen manifest: `D0\.4-v2`$' -or
    $v2RedEvidence -notmatch "(?m)^- Frozen manifest SHA-256: ``$frozenRiskManifestV2Sha256``$" -or
    $v2RedEvidence -notmatch '(?m)^- Previous frozen manifest: `D0\.4-v1`$' -or
    -not $v2FrozenAtMatch.Success -or -not $v2FirstRedMatch.Success -or
    -not [DateTimeOffset]::TryParse($v2FrozenAtMatch.Groups[1].Value, [ref]$parsedFrozenAt) -or
    -not [DateTimeOffset]::TryParse($v2FirstRedMatch.Groups[1].Value, [ref]$parsedRedAt) -or
    $parsedFrozenAt -ne $v2FrozenAt -or $parsedFrozenAt -gt $parsedRedAt -or
    $v2RedEvidence -notmatch '(?m)^- Exit code: `1` \(expected RED\)$' -or
    $v3RedEvidence -notmatch '(?m)^- Frozen manifest: `D0\.4-v3`$' -or
    $v3RedEvidence -notmatch "(?m)^- Frozen manifest SHA-256: ``$frozenRiskManifestSha256``$" -or
    $v3RedEvidence -notmatch '(?m)^- Previous frozen manifest: `D0\.4-v2`$' -or
    -not $v3FrozenAtMatch.Success -or -not $v3FirstRedMatch.Success -or
    -not [DateTimeOffset]::TryParse($v3FrozenAtMatch.Groups[1].Value, [ref]$parsedV3FrozenAt) -or
    -not [DateTimeOffset]::TryParse($v3FirstRedMatch.Groups[1].Value, [ref]$parsedV3RedAt) -or
    $parsedV3FrozenAt -ne $v3FrozenAt -or $parsedV3FrozenAt -gt $parsedV3RedAt -or
    $v3RedEvidence -notmatch '(?m)^- Exit code: `1` \(expected RED\)$') {
    throw "D0.4 RED evidence does not bind the immutable v1-v3 manifests and freeze-before-RED chronology."
}
Write-ProbePass "D0.4 v1/v3 frozen-before-RED provenance"

if (-not (Test-InstanceAgainstSchema $readinessSchemaPath $readinessPath)) {
    throw "Delivery-environment readiness inventory fails Draft 2020-12 schema."
}
Write-ProbePass "delivery-environment readiness schema"

$readiness = Get-Content -Raw -Encoding UTF8 -LiteralPath $readinessPath | ConvertFrom-Json
$baselineFailures = @(Get-ReadinessFailures $readiness)
if ($baselineFailures.Count -gt 0) {
    throw "Delivery-environment readiness semantics failed: $($baselineFailures -join ', ')."
}
Write-ProbePass "12-capability owner/state/blocker inventory"

$snapshot = Get-Content -Raw -Encoding UTF8 -LiteralPath $snapshotPath
$expectedProtectionFact = if ($readiness.repository.branchProtected) {
    '`200 protected`'
} else {
    '`404 Branch not protected`'
}
if (-not $snapshot.Contains($expectedProtectionFact) -or
    -not $snapshot.Contains('`0` rulesets') -or
    -not $snapshot.Contains('`0` self-hosted runners') -or
    -not $snapshot.Contains('`0` repository secret names') -or
    -not $snapshot.Contains('`0` protected environments') -or
    -not $snapshot.Contains('Authenticated repository permission: `ADMIN`') -or
    -not $snapshot.Contains('public owner handle') -or
    -not $snapshot.Contains('No token, secret value, local username/profile path')) {
    throw "Hash-bound GitHub snapshot does not support the readiness repository facts and data classification."
}
Write-ProbePass "hash-bound GitHub facts, permission, and public-metadata classification"

$hostedCapability = @($readiness.capabilities | Where-Object id -eq $activeRiskManifest.hostedRuntimeContract.capabilityId)[0]
if ($hostedCapability.state -eq "ready") {
    $committedRuntimePath = [string]$activeRiskManifest.hostedRuntimeContract.evidencePath
    if (-not (Test-InstanceAgainstSchema $hostedRuntimeSchemaPath $committedRuntimePath)) {
        throw "Committed hosted Windows runtime evidence fails its frozen schema."
    }
    $committedRuntime = Get-Content -Raw -Encoding UTF8 -LiteralPath $committedRuntimePath | ConvertFrom-Json
    if (-not (Test-InstanceAgainstSchema $sourceIdentitySchemaPath $sourceIdentityPath)) {
        throw "Committed delivery source identity fails its frozen schema."
    }
    $committedSourceIdentity = Get-Content -Raw -Encoding UTF8 -LiteralPath $sourceIdentityPath | ConvertFrom-Json
    $greenContent = Get-Content -Raw -Encoding UTF8 -LiteralPath ([string]$activeRiskManifest.hostedRuntimeContract.greenEvidencePath)
    $bindingFailures = @(Get-HostedBindingFailures $readiness $committedRuntime $committedSourceIdentity $greenContent)
    if ($bindingFailures.Count -gt 0) {
        throw "Committed hosted evidence source/run binding failed: $($bindingFailures -join ', ')."
    }
    Write-ProbePass "schema-valid committed hosted runtime/source identity bound to Green run"
}

Assert-MutationRejected "missing capability" {
    param($value)
    $value.capabilities = @($value.capabilities | Select-Object -Skip 1)
    $value.summary.total--
    if ($value.capabilities[0].state -eq "ready") { $value.summary.ready-- }
    elseif ($value.capabilities[0].state -eq "blocked") { $value.summary.blocked-- }
    else { $value.summary.pending-- }
} "READINESS-CAPABILITY-SET" $readiness

Assert-MutationRejected "ready without evidence" {
    param($value)
    $target = @($value.capabilities | Where-Object state -eq "ready")[0]
    $target.evidenceRefs = @()
} "READINESS-UNPROVEN-READY" $readiness

Assert-MutationRejected "blocked without remediation" {
    param($value)
    $target = @($value.capabilities | Where-Object state -eq "blocked")[0]
    $target.remediation = ""
} "READINESS-FAIL-OPEN-BLOCKER" $readiness

Assert-MutationRejected "secret-value claim" {
    param($value)
    $value.capabilities[0].containsSecretValues = $true
} "READINESS-OWNER-OR-DATA" $readiness

Assert-MutationRejected "summary drift" {
    param($value)
    $value.summary.ready++
} "READINESS-SUMMARY" $readiness

Assert-MutationRejected "repository snapshot drift" {
    param($value)
    $value.repository.selfHostedRunnerCount = 1
} "READINESS-REPOSITORY-SNAPSHOT" $readiness

Assert-MutationRejected "repository ruleset-count drift" {
    param($value)
    $value.repository.rulesetCount = 1
} "READINESS-REPOSITORY-SNAPSHOT" $readiness

Assert-MutationRejected "repository permission drift" {
    param($value)
    $value.repository.branchProtectionPermission = "WRITE"
} "READINESS-REPOSITORY-SNAPSHOT" $readiness

Assert-MutationRejected "repository snapshot hash drift" {
    param($value)
    $value.repository.snapshotSha256 = "0000000000000000000000000000000000000000000000000000000000000000"
} "READINESS-SNAPSHOT-BINDING" $readiness

Assert-MutationRejected "first blocking step drift" {
    param($value)
    (@($value.capabilities | Where-Object id -eq "CAP-INTERACTIVE-WIN11")[0]).firstBlockingStep = "P11.1"
} "READINESS-CAPABILITY-CONTRACT" $readiness

Assert-MutationRejected "owner and required-step drift" {
    param($value)
    $target = @($value.capabilities | Where-Object id -eq "CAP-SELF-HOSTED-RUNNER-LABELS")[0]
    $target.ownerRole = "delivery owner"
    $target.requiredForSteps = @("P11.1")
} "READINESS-CAPABILITY-CONTRACT" $readiness

Assert-MutationRejected "false branch readiness" {
    param($value)
    $target = @($value.capabilities | Where-Object id -eq "CAP-BRANCH-PROTECTION")[0]
    $target.state = "ready"
    $target.firstBlockingStep = $null
    $target.verifiedAt = "2026-07-22T12:00:00Z"
    $target.evidenceRefs = @("docs/verification/evidence/D0.4-github-snapshot.md")
    $target.blockerReason = $null
    $target.remediation = $null
    $value.summary.blocked--
    $value.summary.ready++
} "READINESS-BRANCH-POLICY" $readiness

Assert-MutationRejected "false self-hosted readiness" {
    param($value)
    $target = @($value.capabilities | Where-Object id -eq "CAP-SELF-HOSTED-RUNNER-LABELS")[0]
    $target.state = "ready"
    $target.firstBlockingStep = $null
    $target.verifiedAt = "2026-07-22T12:00:00Z"
    $target.evidenceRefs = @("docs/verification/evidence/D0.4-github-snapshot.md")
    $target.blockerReason = $null
    $target.remediation = $null
    $value.summary.blocked--
    $value.summary.ready++
} "READINESS-RUNNER-CROSS-FIELD" $readiness

Assert-MutationRejected "false hosted-Windows readiness without runtime evidence" {
    param($value)
    $target = @($value.capabilities | Where-Object id -eq "CAP-GHA-WINDOWS-CAPABILITY-PROBE")[0]
    $target.state = "ready"
    $target.verifiedAt = "2026-07-22T12:00:00Z"
    $target.evidenceRefs = @("docs/verification/evidence/D0.4-github-snapshot.md")
    $target.blockerReason = $null
    $target.remediation = $null
    $value.summary.pending--
    $value.summary.ready++
} "READINESS-HOSTED-RUNTIME-EVIDENCE" $readiness

$hostedDiscoveryMutation = @(Get-DiscoveryFailures 100 8 "HostedWindows")
if ($hostedDiscoveryMutation -notcontains "DISCOVERY-HOSTED") {
    throw "Hosted-specific discovery mutation was accepted by the global discovery floor."
}
Write-ProbePass "hosted-specific discovery-floor mutation"

$syntheticRuntime = [PSCustomObject][ordered]@{
    schemaVersion = 1; documentType = "hosted-windows-capabilities"
    sourceSha = ("b" * 40); runnerOs = "Windows"; runnerArch = "X64"; imageOs = "win22"
    osVersion = "10.0.20348.0"; processSessionId = 0; userInteractive = $false
    uiaAssembliesLoaded = $true; primaryDisplayWidth = 0; primaryDisplayHeight = 0
    displayProbeAvailable = $false; dpiProbeAvailable = $false; systemDpiX = 0; systemDpiY = 0
    systemScalePercent = 0; narratorObserved = $false; minimumFreeBytes = 5368709120
    actualFreeBytesAtProbe = 5368709120; isolatedStorageRoundTrip = $true
    cleanupVerified = $true; githubNetworkAllowed = $true; timeoutEnforced = $true
    personalDataCollected = $false; secretValuesCollected = $false
}
$syntheticSourceIdentity = [PSCustomObject][ordered]@{
    schemaVersion = 1; expectedSha = ("a" * 40); actualSha = ("a" * 40)
    event = "push"; runId = "123"; runAttempt = "1"
}
$syntheticRuntimePath = Join-Path ([IO.Path]::GetTempPath()) ("aemeath-hosted-runtime-" + [guid]::NewGuid().ToString("N") + ".json")
$syntheticSourcePath = Join-Path ([IO.Path]::GetTempPath()) ("aemeath-source-identity-" + [guid]::NewGuid().ToString("N") + ".json")
try {
    [IO.File]::WriteAllText($syntheticRuntimePath, ($syntheticRuntime | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
    [IO.File]::WriteAllText($syntheticSourcePath, ($syntheticSourceIdentity | ConvertTo-Json -Depth 8), (New-Object Text.UTF8Encoding($false)))
    if (-not (Test-InstanceAgainstSchema $hostedRuntimeSchemaPath $syntheticRuntimePath) -or
        -not (Test-InstanceAgainstSchema $sourceIdentitySchemaPath $syntheticSourcePath)) {
        throw "Wrong-source mutation fixtures are not schema-valid."
    }
    $syntheticReadiness = [PSCustomObject]@{
        verifiedSourceSha = "b" * 40
        verifiedRunId = "123"
        hostedRuntimeEvidenceSha256 = "c" * 64
        sourceIdentitySha256 = "d" * 64
    }
    $syntheticGreen = @"
- Implementation SHA: ``$($syntheticReadiness.verifiedSourceSha)``
- Push run ID: ``123``
- Push run URL: ``https://github.com/RickyT715/Aemeath_Desktop_Pet/actions/runs/123``
- Hosted runtime evidence SHA-256: ``$($syntheticReadiness.hostedRuntimeEvidenceSha256)``
- Source identity evidence SHA-256: ``$($syntheticReadiness.sourceIdentitySha256)``
"@
    $validSyntheticSource = Copy-JsonObject $syntheticSourceIdentity
    $validSyntheticSource.expectedSha = "b" * 40
    $validSyntheticSource.actualSha = "b" * 40
    if (@(Get-HostedBindingFailures $syntheticReadiness $syntheticRuntime $validSyntheticSource $syntheticGreen).Count -ne 0) {
        throw "Valid synthetic hosted source/run binding was rejected."
    }
    $wrongSourceFailures = @(Get-HostedBindingFailures $syntheticReadiness $syntheticRuntime $syntheticSourceIdentity $syntheticGreen)
    if ($wrongSourceFailures -notcontains "HOSTED-SOURCE-MISMATCH") {
        throw "Schema-valid wrong-source mutation was accepted."
    }
    Write-ProbePass "schema-valid wrong-source runtime/source-identity mutation"
} finally {
    if (Test-Path -LiteralPath $syntheticRuntimePath) { Remove-Item -LiteralPath $syntheticRuntimePath -Force }
    if (Test-Path -LiteralPath $syntheticSourcePath) { Remove-Item -LiteralPath $syntheticSourcePath -Force }
}

$requiredChecks = Get-Content -Raw -Encoding UTF8 -LiteralPath $requiredChecksPath | ConvertFrom-Json
$jobs = @($requiredChecks.jobs | Where-Object id -eq "delivery-environment")
$workflow = Get-Content -Raw -Encoding UTF8 -LiteralPath $workflowPath
$jobBlock = [regex]::Match($workflow, '(?ms)^  delivery-environment:\s*(.+?)(?=^  [a-z0-9-]+:\s|\z)').Value
$hostedProbe = @($activeRiskManifest.probes | Where-Object id -eq "D0.4-V-REAL-E2E-HOSTED-WINDOWS")[0]
$hostedEnvironment = @($activeRiskManifest.environments | Where-Object id -eq "ENV-GHA-WINDOWS")[0]
$expectedEvidence = @($activeRiskManifest.expectedArtifacts | Sort-Object)
$expectedHostedJobDiscovery = [int]$activeRiskManifest.thresholds.minimumStaticDiscovery +
    [int]$activeRiskManifest.hostedRuntimeContract.minimumHostedDiscovery
if ($jobs.Count -ne 1 -or $jobs[0].runner -ne $hostedEnvironment.os -or
    $jobs[0].discovery.kind -ne "powershell-probe" -or
    [int]$jobs[0].discovery.minimumDiscoveredTests -ne $expectedHostedJobDiscovery -or
    [int]$hostedProbe.minimumDiscovery -ne [int]$activeRiskManifest.hostedRuntimeContract.minimumHostedDiscovery -or
    ([string]$jobs[0].discovery.command).Trim() -cne ([string]$hostedProbe.command).Trim() -or
    ((@($jobs[0].evidenceFiles.path | Sort-Object) -join "|") -ne (($expectedEvidence | Sort-Object) -join "|")) -or
    [int]$requiredChecks.minimumRetentionDays -ne [int]$activeRiskManifest.thresholds.artifactRetentionDays -or
    [string]::IsNullOrWhiteSpace($jobBlock) -or
    $jobBlock -notmatch [regex]::Escape([string]$hostedProbe.command) -or
    $jobBlock -notmatch "retention-days:\s*$([int]$activeRiskManifest.thresholds.artifactRetentionDays)\b") {
    throw "Delivery-environment required-check and workflow contracts are not aligned."
}
Write-ProbePass "delivery-environment CI command, runner, evidence, and retention"

$traceability = Get-Content -Raw -Encoding UTF8 -LiteralPath "docs/verification/traceability-v1.yml" | ConvertFrom-Json
$traceEntry = @($traceability.entries | Where-Object id -eq "PRD:RISK-012")[0]
$traceProbeIds = @($traceability.testCatalog | Where-Object ownerStep -eq "D0.4" | ForEach-Object id | Sort-Object)
$manifestProbeIds = @($activeRiskManifest.probes | ForEach-Object id | Sort-Object)
if (($traceProbeIds -join "|") -cne ($manifestProbeIds -join "|") -or
    ((@($traceEntry.testIds | Sort-Object) -join "|") -cne ($manifestProbeIds -join "|")) -or
    @($traceEntry.lanes | Where-Object { $_ -in @("V-STATIC", "V-REAL-E2E") }).Count -ne 2) {
    throw "D0.4 manifest probes and authoritative trace backlinks differ."
}
Write-ProbePass "D0.4 manifest and trace probe/backlink scope"

$serialized = $readiness | ConvertTo-Json -Depth 20 -Compress
$localProfile = [string]$env:USERPROFILE
if ($serialized -match '(?i)-----BEGIN [A-Z ]*PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}' -or
    (-not [string]::IsNullOrWhiteSpace($localProfile) -and $serialized -match [regex]::Escape($localProfile))) {
    throw "Readiness inventory contains a secret-like value or local user identity."
}
Write-ProbePass "redacted capability evidence"

if ($Mode -eq "HostedWindows") {
    $sourceSha = if (-not [string]::IsNullOrWhiteSpace($env:SOURCE_SHA)) { $env:SOURCE_SHA.ToLowerInvariant() } else { (git rev-parse HEAD).Trim().ToLowerInvariant() }
    $actualSha = (git rev-parse HEAD).Trim().ToLowerInvariant()
    if ($sourceSha -cne $actualSha) { throw "Hosted Windows probe source SHA mismatch." }
    Write-HostedProbePass "hosted Windows exact source SHA"

    if ($env:RUNNER_OS -ne "Windows" -or -not [Environment]::Is64BitOperatingSystem -or
        [Environment]::OSVersion.Version.Major -lt 10) {
        throw "Hosted Windows OS/architecture contract failed."
    }
    Write-HostedProbePass "hosted Windows OS and x64 architecture"

    $uiaLoaded = $true
    try {
        Add-Type -AssemblyName UIAutomationClient
        Add-Type -AssemblyName UIAutomationTypes
    } catch {
        $uiaLoaded = $false
    }
    if (-not $uiaLoaded) { throw "Hosted Windows cannot load UI Automation assemblies." }
    Write-HostedProbePass "hosted Windows UI Automation assemblies"

    $displayProbeAvailable = $true
    $primaryWidth = 0
    $primaryHeight = 0
    try {
        Add-Type -AssemblyName PresentationFramework
        $primaryWidth = [int][Math]::Round([System.Windows.SystemParameters]::PrimaryScreenWidth)
        $primaryHeight = [int][Math]::Round([System.Windows.SystemParameters]::PrimaryScreenHeight)
        $displayProbeAvailable = $primaryWidth -gt 0 -and $primaryHeight -gt 0
    } catch {
        $displayProbeAvailable = $false
    }

    $dpiProbeAvailable = $false
    $systemDpiX = 0
    $systemDpiY = 0
    $systemScalePercent = 0
    try {
        if ($null -eq ("Aemeath.Verification.DisplayProbe" -as [Type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
namespace Aemeath.Verification {
    public static class DisplayProbe {
        [DllImport("user32.dll")]
        public static extern uint GetDpiForSystem();
    }
}
"@
        }
        $systemDpi = [int][Aemeath.Verification.DisplayProbe]::GetDpiForSystem()
        if ($systemDpi -gt 0) {
            $systemDpiX = $systemDpi
            $systemDpiY = $systemDpi
            $systemScalePercent = [int][Math]::Round(($systemDpi * 100.0) / 96.0)
            $dpiProbeAvailable = $true
        }
    } catch {
        $dpiProbeAvailable = $false
    }
    Write-HostedProbePass "hosted Windows display and DPI observation"

    $drive = Get-PSDrive -Name ([IO.Path]::GetPathRoot((Get-Location).Path).TrimEnd(':', '\'))
    $minimumFreeBytes = 5368709120
    if ([int64]$drive.Free -lt $minimumFreeBytes) { throw "Hosted Windows has insufficient isolated storage." }
    Write-HostedProbePass "hosted Windows storage budget"

    $probeRoot = Join-Path $env:RUNNER_TEMP ("aemeath-readiness-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $probeRoot | Out-Null
    try {
        $sentinel = Join-Path $probeRoot "sentinel.txt"
        [IO.File]::WriteAllText($sentinel, "canary-only")
        if ([IO.File]::ReadAllText($sentinel) -ne "canary-only") { throw "Isolated storage round trip failed." }
    } finally {
        if (Test-Path -LiteralPath $probeRoot -PathType Container) { Remove-Item -LiteralPath $probeRoot -Recurse -Force }
    }
    if (Test-Path -LiteralPath $probeRoot) { throw "Hosted Windows cleanup/reset probe left residue." }
    Write-HostedProbePass "hosted Windows cleanup and reset"

    $networkAllowed = $false
    $networkFailureType = $null
    $networkClient = $null
    $networkStream = $null
    try {
        $networkClient = New-Object Net.Sockets.TcpClient
        $connectTask = $networkClient.ConnectAsync("api.github.com", 443)
        if (-not $connectTask.Wait(15000)) { throw "GitHub TLS connect timeout." }
        $networkStream = New-Object Net.Security.SslStream($networkClient.GetStream(), $false)
        $networkStream.ReadTimeout = 15000
        $networkStream.WriteTimeout = 15000
        $networkStream.AuthenticateAsClient("api.github.com")
        $networkAllowed = $networkClient.Connected -and $networkStream.IsAuthenticated -and $networkStream.IsEncrypted
    } catch {
        $networkAllowed = $false
        $networkFailureType = $_.Exception.GetType().FullName
    } finally {
        if ($null -ne $networkStream) { $networkStream.Dispose() }
        if ($null -ne $networkClient) { $networkClient.Dispose() }
    }
    if (-not $networkAllowed) { throw "Hosted Windows GitHub network policy probe failed ($networkFailureType)." }
    Write-HostedProbePass "hosted Windows network policy"

    $currentEnginePath = (Get-Process -Id $PID).Path
    $timeoutProcess = Start-Process -FilePath $currentEnginePath -ArgumentList @("-NoProfile", "-Command", "Start-Sleep -Seconds 10") -PassThru -WindowStyle Hidden
    try {
        if ($timeoutProcess.WaitForExit(500)) { throw "Timeout sentinel exited before its deadline." }
        $timeoutProcess.Kill()
        $timeoutProcess.WaitForExit()
    } finally {
        if (-not $timeoutProcess.HasExited) { $timeoutProcess.Kill() }
        $timeoutProcess.Dispose()
    }
    Write-HostedProbePass "hosted Windows timeout enforcement"

    $narratorObserved = @(Get-Process -Name Narrator -ErrorAction SilentlyContinue).Count -gt 0
    $sessionId = (Get-Process -Id $PID).SessionId
    $runtimeEvidence = [PSCustomObject][ordered]@{
        schemaVersion = 1
        documentType = "hosted-windows-capabilities"
        sourceSha = $actualSha
        runnerOs = $env:RUNNER_OS
        runnerArch = $env:RUNNER_ARCH
        imageOs = $env:ImageOS
        osVersion = [Environment]::OSVersion.Version.ToString()
        processSessionId = $sessionId
        userInteractive = [Environment]::UserInteractive
        uiaAssembliesLoaded = $uiaLoaded
        primaryDisplayWidth = $primaryWidth
        primaryDisplayHeight = $primaryHeight
        displayProbeAvailable = $displayProbeAvailable
        dpiProbeAvailable = $dpiProbeAvailable
        systemDpiX = $systemDpiX
        systemDpiY = $systemDpiY
        systemScalePercent = $systemScalePercent
        narratorObserved = $narratorObserved
        minimumFreeBytes = $minimumFreeBytes
        actualFreeBytesAtProbe = [int64]$drive.Free
        isolatedStorageRoundTrip = $true
        cleanupVerified = $true
        githubNetworkAllowed = $networkAllowed
        timeoutEnforced = $true
        personalDataCollected = $false
        secretValuesCollected = $false
    }
    New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null
    $runtimeEvidence | ConvertTo-Json -Depth 8 | Set-Content -Encoding UTF8 -LiteralPath (Join-Path $EvidenceDirectory "hosted-windows-capabilities.json")
    $runtimeEvidencePath = Join-Path $EvidenceDirectory "hosted-windows-capabilities.json"
    if (-not (Test-InstanceAgainstSchema $hostedRuntimeSchemaPath $runtimeEvidencePath)) {
        throw "Generated hosted Windows capability evidence fails its frozen schema."
    }
    Write-HostedProbePass "redacted hosted Windows capability artifact"
}

$discoveryFailures = @(Get-DiscoveryFailures $probeCount $hostedProbeCount $Mode)
if ($discoveryFailures.Count -gt 0 -or $unexpectedSkips -ne 0) {
    throw "Environment readiness discovery failed ($($discoveryFailures -join ', ')); total=$probeCount, hosted=$hostedProbeCount, skips=$unexpectedSkips."
}
Write-Host "Environment readiness tests passed ($probeCount total probes; $hostedProbeCount hosted probes; zero skips)."

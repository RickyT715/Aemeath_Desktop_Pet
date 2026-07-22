[CmdletBinding()]
param(
    [string]$WorkflowPath = ".github/workflows/ci.yml",
    [string]$RequiredChecksPath = ".github/ci/required-checks.json"
)

$ErrorActionPreference = "Stop"
$failures = [System.Collections.Generic.List[string]]::new()

function Add-ContractFailure {
    param([string]$Message)

    $script:failures.Add($Message)
}

function Assert-ContractMatch {
    param(
        [string]$Name,
        [string]$Pattern,
        [string]$Content
    )

    if ($Content -notmatch $Pattern) {
        Add-ContractFailure $Name
    }
}

function Assert-ContractNotMatch {
    param(
        [string]$Name,
        [string]$Pattern,
        [string]$Content
    )

    if ($Content -match $Pattern) {
        Add-ContractFailure $Name
    }
}

function Get-WorkflowJobBlock {
    param(
        [string]$JobId,
        [string]$Content
    )

    $lines = $Content -split "\r?\n"
    $start = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match "^  $([regex]::Escape($JobId)):\s*$") {
            $start = $index
            break
        }
    }

    if ($start -lt 0) {
        return ""
    }

    $end = $lines.Count
    for ($index = $start + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^  [A-Za-z0-9_-]+:\s*$') {
            $end = $index
            break
        }
    }

    return ($lines[$start..($end - 1)] -join "`n")
}

function Get-WorkflowStepBlocks {
    param([string]$JobBlock)

    $lines = $JobBlock -split "\r?\n"
    $starts = [System.Collections.Generic.List[int]]::new()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^      -\s+') {
            $starts.Add($index)
        }
    }

    for ($stepIndex = 0; $stepIndex -lt $starts.Count; $stepIndex++) {
        $start = $starts[$stepIndex]
        $end = if ($stepIndex + 1 -lt $starts.Count) {
            $starts[$stepIndex + 1]
        } else {
            $lines.Count
        }
        $lines[$start..($end - 1)] -join "`n"
    }
}

if (-not (Test-Path -LiteralPath $WorkflowPath -PathType Leaf)) {
    throw "CI workflow not found: $WorkflowPath"
}

$workflow = Get-Content -Raw -LiteralPath $WorkflowPath

Assert-ContractMatch "workflow_dispatch trigger is required" "(?m)^\s{2}workflow_dispatch:\s*$" $workflow
Assert-ContractMatch "agent/** push trigger is required" '(?m)^\s{6}-\s+[''"]?agent/\*\*[''"]?\s*$' $workflow
Assert-ContractMatch "read-only contents permission is required" "(?ms)^permissions:\s*\r?\n\s{2}contents:\s*read\s*$" $workflow
Assert-ContractMatch "top-level SOURCE_SHA must select pull-request head or github.sha" "(?ms)^env:\s*\r?\n\s{2}SOURCE_SHA:\s*\$\{\{\s*github\.event\.pull_request\.head\.sha\s*\|\|\s*github\.sha\s*\}\}\s*(?:\r?\n|$)" $workflow
Assert-ContractMatch "concurrency must include the workflow" "(?m)^\s*group:.+github\.workflow" $workflow
Assert-ContractMatch "concurrency must separate events" "(?m)^\s*group:.+github\.event_name" $workflow
Assert-ContractMatch "concurrency must select the pull-request head or github.sha" "(?m)^\s*group:.+github\.event\.pull_request\.head\.sha\s*\|\|\s*github\.sha" $workflow
Assert-ContractMatch "checkout must use SOURCE_SHA" "(?ms)uses:\s*actions/checkout@[0-9a-f]{40}.+?with:\s*\r?\n\s+ref:\s*\$\{\{\s*env\.SOURCE_SHA\s*\}\}" $workflow
Assert-ContractMatch "checkout identity must be verified" "git rev-parse HEAD" $workflow
Assert-ContractMatch "delivery contract self-tests must run in CI" "tools/ci/Test-CiDelivery\.ps1" $workflow
Assert-ContractNotMatch "continue-on-error is forbidden in required jobs" "continue-on-error:\s*true" $workflow
Assert-ContractNotMatch "pull_request_target is forbidden" "(?m)^\s{2}pull_request_target:\s*$" $workflow

if (-not (Test-Path -LiteralPath $RequiredChecksPath -PathType Leaf)) {
    Add-ContractFailure "required-check manifest is missing: $RequiredChecksPath"
} else {
    try {
        $requiredChecks = Get-Content -Raw -LiteralPath $RequiredChecksPath | ConvertFrom-Json
        if ($requiredChecks.schemaVersion -ne 1) {
            Add-ContractFailure "required-check manifest schemaVersion must be 1"
        }

        if ($requiredChecks.workflowName -ne "CI") {
            Add-ContractFailure "required-check manifest workflowName must be CI"
        }

        if ($requiredChecks.requiredEvent -ne "push") {
            Add-ContractFailure "required-check manifest must select the push event"
        }

        if ([int]$requiredChecks.minimumRetentionDays -lt 90) {
            Add-ContractFailure "required-check manifest retention must be at least 90 days"
        }

        $trustedActions = @{}
        foreach ($trustedAction in @($requiredChecks.trustedActions)) {
            if ([string]$trustedAction.sha -notmatch '^[0-9a-f]{40}$') {
                Add-ContractFailure "trusted action has no full commit SHA: $($trustedAction.name)"
                continue
            }

            if ([string]::IsNullOrWhiteSpace($trustedAction.releaseTag)) {
                Add-ContractFailure "trusted action has no reviewed release tag: $($trustedAction.name)"
            }

            if ($trustedActions.ContainsKey([string]$trustedAction.name)) {
                Add-ContractFailure "trusted action is duplicated: $($trustedAction.name)"
            } else {
                $trustedActions[[string]$trustedAction.name] = $trustedAction
            }
        }

        $allUses = [regex]::Matches($workflow, '(?m)^\s*uses:\s*(\S+)(?:\s*#\s*(\S+))?\s*$')
        $usedTrustedActions = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($actionUse in $allUses) {
            $target = $actionUse.Groups[1].Value
            $releaseComment = $actionUse.Groups[2].Value
            if ($target -match '^\.[\\/]') {
                continue
            }

            if ($target.StartsWith('docker://', [StringComparison]::OrdinalIgnoreCase)) {
                if ($target -notmatch '^docker://.+@sha256:[0-9a-fA-F]{64}$') {
                    Add-ContractFailure "Docker action is not pinned to a sha256 digest: $target"
                }
                continue
            }

            $separator = $target.LastIndexOf('@')
            if ($separator -lt 1) {
                Add-ContractFailure "unrecognized or mutable action reference: $target"
                continue
            }

            $actionName = $target.Substring(0, $separator)
            $actionSha = $target.Substring($separator + 1)
            if ($actionSha -notmatch '^[0-9a-f]{40}$') {
                Add-ContractFailure "action is not pinned to a full commit SHA: $actionName@$actionSha"
                continue
            }

            if (-not $trustedActions.ContainsKey($actionName)) {
                Add-ContractFailure "action is absent from trustedActions: $actionName"
                continue
            }

            $trustedAction = $trustedActions[$actionName]
            if ($actionSha -ne $trustedAction.sha) {
                Add-ContractFailure "action SHA differs from reviewed pin: $actionName"
            }

            if ($releaseComment -ne $trustedAction.releaseTag) {
                Add-ContractFailure "action pin comment differs from reviewed tag: $actionName"
            }

            $null = $usedTrustedActions.Add($actionName)
        }

        foreach ($trustedAction in @($requiredChecks.trustedActions)) {
            if (-not $usedTrustedActions.Contains([string]$trustedAction.name)) {
                Add-ContractFailure "reviewed action is not used by the workflow: $($trustedAction.name)"
            }
        }

        $jobs = @($requiredChecks.jobs)
        if ($jobs.Count -eq 0) {
            Add-ContractFailure "required-check manifest must contain at least one job"
        }

        $jobIds = [System.Collections.Generic.HashSet[string]]::new()
        $jobNames = [System.Collections.Generic.HashSet[string]]::new()
        $artifactPrefixes = [System.Collections.Generic.HashSet[string]]::new()
        foreach ($job in $jobs) {
            if (-not $jobIds.Add([string]$job.id)) {
                Add-ContractFailure "required job id is duplicated: $($job.id)"
            }

            if (-not $jobNames.Add([string]$job.name)) {
                Add-ContractFailure "required job name is duplicated: $($job.name)"
            }

            $jobBlock = Get-WorkflowJobBlock -JobId $job.id -Content $workflow
            if ([string]::IsNullOrWhiteSpace($jobBlock)) {
                Add-ContractFailure "required job is absent from workflow: $($job.id)"
                continue
            }

            Assert-ContractMatch "required job name is absent: $($job.name)" "(?m)^\s{4}name:\s*$([regex]::Escape($job.name))\s*$" $jobBlock
            Assert-ContractMatch "required runner differs for $($job.id)" "(?m)^\s{4}runs-on:\s*$([regex]::Escape($job.runner))\s*$" $jobBlock
            Assert-ContractMatch "required job does not check out SOURCE_SHA: $($job.id)" "(?ms)uses:\s*actions/checkout@[0-9a-f]{40}.+?with:\s*\r?\n\s+ref:\s*\$\{\{\s*env\.SOURCE_SHA\s*\}\}" $jobBlock
            Assert-ContractNotMatch "required job is advisory: $($job.id)" "continue-on-error:\s*true" $jobBlock

            if ($job.executionModel -ne "single" -or [int]$job.expectedInstances -ne 1) {
                Add-ContractFailure "D0.2 job must declare one single execution instance: $($job.id)"
            }

            Assert-ContractNotMatch "single-instance job unexpectedly defines a matrix: $($job.id)" "(?m)^\s+matrix:\s*$" $jobBlock

            if ($job.discovery.kind -ne "not-applicable" -or
                [int]$job.discovery.minimumDiscoveredTests -ne 0 -or
                [string]::IsNullOrWhiteSpace($job.discovery.rationale)) {
                Add-ContractFailure "D0.2 job must explicitly justify zero test discovery: $($job.id)"
            }

            if ([string]::IsNullOrWhiteSpace($job.artifactPrefix)) {
                Add-ContractFailure "required job has no artifact prefix: $($job.id)"
            } else {
                if (-not $artifactPrefixes.Add([string]$job.artifactPrefix)) {
                    Add-ContractFailure "artifact prefix is duplicated: $($job.artifactPrefix)"
                }

            }

            if ([string]::IsNullOrWhiteSpace($job.artifactPath) -or
                [IO.Path]::IsPathRooted([string]$job.artifactPath) -or
                [string]$job.artifactPath -match '(^|[\\/])\.\.([\\/]|$)') {
                Add-ContractFailure "required job has an invalid artifact path: $($job.id)"
            }

            $stepBlocks = @(Get-WorkflowStepBlocks -JobBlock $jobBlock)
            $uploadPin = [regex]::Escape([string]$trustedActions['actions/upload-artifact'].sha)
            $uploadSteps = @($stepBlocks | Where-Object {
                    $_ -match "(?m)^\s+uses:\s*actions/upload-artifact@$uploadPin(?:\s|$)"
                })
            if ($uploadSteps.Count -ne 1) {
                Add-ContractFailure "required job must contain exactly one reviewed upload step: $($job.id)"
            } else {
                $uploadStep = $uploadSteps[0]
                Assert-ContractMatch "upload step does not use if: always(): $($job.id)" "(?m)^\s{8}if:\s*always\(\)\s*$" $uploadStep
                Assert-ContractMatch "upload step does not fail on missing evidence: $($job.id)" "(?m)^\s+if-no-files-found:\s*error\s*$" $uploadStep
                Assert-ContractMatch "upload step has the wrong artifact name: $($job.id)" "(?m)^\s+name:\s*$([regex]::Escape($job.artifactPrefix))\$\{\{\s*env\.SOURCE_SHA\s*\}\}\s*$" $uploadStep
                Assert-ContractMatch "upload step has the wrong artifact path: $($job.id)" "(?m)^\s+path:\s*$([regex]::Escape($job.artifactPath))\s*$" $uploadStep
            }

            if ([long]$job.minimumArtifactBytes -lt 1 -or $job.digestAlgorithm -ne "sha256") {
                Add-ContractFailure "artifact size/digest contract is invalid: $($job.id)"
            }

            $retentionMatches = if ($uploadSteps.Count -eq 1) {
                [regex]::Matches($uploadSteps[0], 'retention-days:\s*(\d+)')
            } else {
                @()
            }
            if ($retentionMatches.Count -ne 1 -or
                [int]$retentionMatches[0].Groups[1].Value -lt [int]$requiredChecks.minimumRetentionDays) {
                Add-ContractFailure "required job retention is missing or too short: $($job.id)"
            }

            $evidencePaths = [System.Collections.Generic.HashSet[string]]::new()
            foreach ($evidenceFile in @($job.evidenceFiles)) {
                $path = [string]$evidenceFile.path
                if ([string]::IsNullOrWhiteSpace($path) -or
                    [IO.Path]::IsPathRooted($path) -or
                    $path -match '(^|[\\/])\.\.([\\/]|$)' -or
                    [long]$evidenceFile.minimumBytes -lt 1) {
                    Add-ContractFailure "invalid evidence-file contract in job: $($job.id)"
                    continue
                }

                if (-not $evidencePaths.Add($path)) {
                    Add-ContractFailure "evidence path is duplicated in job $($job.id): $path"
                }

                Assert-ContractMatch "workflow never creates required evidence for $($job.id): $path" ([regex]::Escape($path)) $jobBlock
            }

            if ($evidencePaths.Count -eq 0) {
                Add-ContractFailure "required job defines no evidence files: $($job.id)"
            }
        }
    } catch {
        Add-ContractFailure "required-check manifest is invalid: $($_.Exception.Message)"
    }
}

foreach ($requiredPath in @(
        "tools/ci/Wait-ForCi.ps1",
        "tools/ci/Test-CiDelivery.ps1",
        "tools/ci/CiDeliveryContract.psm1"
    )) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        Add-ContractFailure "required CI tool is missing: $requiredPath"
    }
}

if ($failures.Count -gt 0) {
    Write-Error ("CI contract failed:`n - " + ($failures -join "`n - "))
    exit 1
}

Write-Host "CI workflow contract passed."

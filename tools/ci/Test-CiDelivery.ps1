[CmdletBinding()]
param(
    [string]$WorkflowPath = ".github/workflows/ci.yml",
    [string]$RequiredChecksPath = ".github/ci/required-checks.json"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$verifyScript = Join-Path $PSScriptRoot "Verify-CiWorkflow.ps1"
$contractModule = Join-Path $PSScriptRoot "CiDeliveryContract.psm1"
Import-Module $contractModule -Force

$workflow = Get-Content -Raw -LiteralPath $WorkflowPath
$manifestText = Get-Content -Raw -LiteralPath $RequiredChecksPath
$requiredChecks = $manifestText | ConvertFrom-Json
$enginePath = (Get-Process -Id $PID).Path
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("aemeath-ci-contract-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

function Invoke-StaticContract {
    param(
        [string]$WorkflowContent,
        [object]$Manifest
    )

    $caseId = [guid]::NewGuid().ToString("N")
    $caseRoot = Join-Path $tempRoot $caseId
    New-Item -ItemType Directory -Path $caseRoot | Out-Null
    $workflowFile = Join-Path $caseRoot "ci.yml"
    $manifestFile = Join-Path $caseRoot "required-checks.json"
    Set-Content -LiteralPath $workflowFile -Value $WorkflowContent -Encoding UTF8
    $Manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestFile -Encoding UTF8

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $enginePath -NoProfile -ExecutionPolicy Bypass -File $verifyScript `
            -WorkflowPath $workflowFile -RequiredChecksPath $manifestFile 2>&1
        $exitCode = $LASTEXITCODE
        $global:LASTEXITCODE = 0
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        Output = ($output | Out-String)
    }
}

function Copy-Manifest {
    return $manifestText | ConvertFrom-Json
}

function Normalize-DiagnosticText {
    param([string]$Text)

    $escape = [string][char]27
    $withoutAnsi = [regex]::Replace($Text, "$escape\[[0-?]*[ -/]*[@-~]", "")
    $withoutMargins = [regex]::Replace($withoutAnsi, '\s+\|\s+', ' ')
    return [regex]::Replace($withoutMargins, '\s+', ' ').Trim()
}

function Get-WorkflowJobText {
    param([string]$JobId, [string]$Content)

    $pattern = "(?ms)^  $([regex]::Escape($JobId)):\s*\r?\n.*?(?=^  [A-Za-z0-9_-]+:\s*\r?$|\z)"
    $match = [regex]::Match($Content, $pattern)
    if (-not $match.Success) {
        throw "Workflow job '$JobId' is absent from the mutation fixture."
    }
    return $match.Value
}

function Assert-StaticMutationRejected {
    param(
        [string]$Name,
        [string]$WorkflowContent,
        [object]$Manifest,
        [string]$ExpectedMessage
    )

    $result = Invoke-StaticContract -WorkflowContent $WorkflowContent -Manifest $Manifest
    $normalizedOutput = Normalize-DiagnosticText $result.Output
    if ($result.ExitCode -eq 0 -or
        $normalizedOutput.IndexOf($ExpectedMessage, [StringComparison]::Ordinal) -lt 0) {
        throw "Static mutation '$Name' was not rejected with '$ExpectedMessage'. Output: $($result.Output)"
    }

    Write-Host "PASS static mutation: $Name"
}

function New-ValidResultFixture {
    $sha = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    $fixtureRoot = Join-Path $tempRoot ([guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
    $jobs = [System.Collections.Generic.List[object]]::new()
    $artifacts = [System.Collections.Generic.List[object]]::new()
    $evidenceRoots = @{}
    $createdAt = [DateTimeOffset]::Parse("2026-07-22T00:00:00Z")
    $expiresAt = $createdAt.AddDays([int]$requiredChecks.minimumRetentionDays)

    foreach ($requiredJob in @($requiredChecks.jobs)) {
        $jobs.Add([PSCustomObject]@{
                name = $requiredJob.name
                status = "completed"
                conclusion = "success"
            })

        $artifactName = "$($requiredJob.artifactPrefix)$sha"
        $artifacts.Add([PSCustomObject]@{
                name = $artifactName
                expired = $false
                size_in_bytes = [long]$requiredJob.minimumArtifactBytes + 50
                digest = "sha256:" + ("b" * 64)
                created_at = $createdAt.ToString("O")
                expires_at = $expiresAt.ToString("O")
                workflow_run = [PSCustomObject]@{ head_sha = $sha }
            })

        $evidenceRoot = Join-Path $fixtureRoot $requiredJob.id
        New-Item -ItemType Directory -Path $evidenceRoot | Out-Null
        foreach ($evidenceFile in @($requiredJob.evidenceFiles)) {
            $path = Join-Path $evidenceRoot ([string]$evidenceFile.path)
            $parent = Split-Path -Parent $path
            if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
                New-Item -ItemType Directory -Path $parent | Out-Null
            }

            [IO.File]::WriteAllText($path, "x" * ([int]$evidenceFile.minimumBytes + 10))
        }

        $evidenceRoots[$artifactName] = $evidenceRoot
    }

    return [PSCustomObject]@{
        Sha = $sha
        Run = [PSCustomObject]@{
            headSha = $sha
            event = $requiredChecks.requiredEvent
            status = "completed"
            conclusion = "success"
            jobs = $jobs.ToArray()
        }
        Artifacts = $artifacts.ToArray()
        EvidenceRoots = $evidenceRoots
    }
}

function Assert-ResultMutationRejected {
    param(
        [string]$Name,
        [scriptblock]$Mutate,
        [string]$ExpectedMessage
    )

    $fixture = New-ValidResultFixture
    & $Mutate $fixture
    $failures = @(Test-CiDeliveryResult -RequiredChecks $requiredChecks -Sha $fixture.Sha `
            -RunDetails $fixture.Run -Artifacts $fixture.Artifacts `
            -EvidenceRoots $fixture.EvidenceRoots)
    if ($failures.Count -eq 0 -or ($failures -join "`n") -notmatch [regex]::Escape($ExpectedMessage)) {
        throw "Result mutation '$Name' was not rejected with '$ExpectedMessage'. Failures: $($failures -join '; ')"
    }

    Write-Host "PASS result mutation: $Name"
}

try {
    $wrappedDiagnostic = ([char]27).ToString() +
        "[31;1mtop-level SOURCE_SHA must select pull-request`n | head or github.sha" +
        ([char]27).ToString() + "[0m"
    $normalizedDiagnostic = Normalize-DiagnosticText $wrappedDiagnostic
    if ($normalizedDiagnostic -ne "top-level SOURCE_SHA must select pull-request head or github.sha") {
        throw "PowerShell diagnostic normalization failed: '$normalizedDiagnostic'"
    }
    Write-Host "PASS wrapped/ANSI diagnostic normalization"

    $baseline = Invoke-StaticContract -WorkflowContent $workflow -Manifest (Copy-Manifest)
    if ($baseline.ExitCode -ne 0) {
        throw "Valid static CI contract failed: $($baseline.Output)"
    }
    Write-Host "PASS valid static contract"

    Assert-StaticMutationRejected -Name "missing implementation-branch trigger" `
        -WorkflowContent ($workflow -replace '(?m)^\s*-\s+[''"]agent/\*\*[''"]\s*$', '') `
        -Manifest (Copy-Manifest) -ExpectedMessage "agent/** push trigger is required"

    Assert-StaticMutationRejected -Name "missing exact checkout" `
        -WorkflowContent ($workflow -replace '(?m)^\s+ref:\s*\$\{\{\s*env\.SOURCE_SHA\s*\}\}\s*$', '') `
        -Manifest (Copy-Manifest) -ExpectedMessage "checkout must use SOURCE_SHA"

    foreach ($jobId in @("verification-contracts", "dependency-qualification")) {
        $jobText = Get-WorkflowJobText $jobId $workflow
        $shallowJobText = [regex]::Replace(
            $jobText, '(?m)^(\s+fetch-depth:)\s*0\s*$', '$1 1', 1
        )
        if ($shallowJobText -ceq $jobText) {
            throw "Could not create full-history checkout mutation for '$jobId'."
        }
        Assert-StaticMutationRejected -Name "shallow historical checkout in $jobId" `
            -WorkflowContent ($workflow.Replace($jobText, $shallowJobText)) `
            -Manifest (Copy-Manifest) `
            -ExpectedMessage "historical-baseline checkout must fetch full history: $jobId"
    }

    $mergeShaSource = $workflow.Replace(
        '  SOURCE_SHA: ${{ github.event.pull_request.head.sha || github.sha }}',
        '  SOURCE_SHA: ${{ github.sha }}'
    )
    Assert-StaticMutationRejected -Name "PR merge SHA substituted for source SHA" `
        -WorkflowContent $mergeShaSource -Manifest (Copy-Manifest) `
        -ExpectedMessage "top-level SOURCE_SHA must select pull-request head or github.sha"

    Assert-StaticMutationRejected -Name "reduced required job set" `
        -WorkflowContent ($workflow -replace '(?ms)^  dotnet-build:.*\z', '') `
        -Manifest (Copy-Manifest) -ExpectedMessage "required job is absent from workflow: dotnet-build"

    Assert-StaticMutationRejected -Name "advisory required job" `
        -WorkflowContent ($workflow -replace '    name: \.NET Release Build', "    name: .NET Release Build`n    continue-on-error: true") `
        -Manifest (Copy-Manifest) -ExpectedMessage "continue-on-error is forbidden"

    Assert-StaticMutationRejected -Name "failure evidence disabled" `
        -WorkflowContent ($workflow -replace 'if: always\(\)', 'if: success()') `
        -Manifest (Copy-Manifest) -ExpectedMessage "upload step does not use if: always()"

    $relocatedAlways = $workflow -replace '(?m)^(\s*- name: Run delivery contract tests\s*)$', "`$1`n        if: always()"
    $relocatedAlways = $relocatedAlways -replace '(?ms)(- name: Upload delivery evidence\s*\r?\n)\s*if:\s*always\(\)', "`$1        if: success()"
    Assert-StaticMutationRejected -Name "always condition moved off upload step" `
        -WorkflowContent $relocatedAlways -Manifest (Copy-Manifest) `
        -ExpectedMessage "upload step does not use if: always()"

    $unauditedDependencyUpload = $workflow.Replace(
        "if: always() && steps.evidence_audit.outcome == 'success'",
        "if: always()"
    )
    Assert-StaticMutationRejected -Name "dependency evidence uploaded without audit success" `
        -WorkflowContent $unauditedDependencyUpload -Manifest (Copy-Manifest) `
        -ExpectedMessage "upload step does not require successful evidence audit: dependency-qualification"

    Assert-StaticMutationRejected -Name "short artifact retention" `
        -WorkflowContent ($workflow -replace 'retention-days: 90', 'retention-days: 30') `
        -Manifest (Copy-Manifest) -ExpectedMessage "retention is missing or too short"

    Assert-StaticMutationRejected -Name "mutable action tag" `
        -WorkflowContent ($workflow -replace 'actions/checkout@[0-9a-f]{40}', 'actions/checkout@v4') `
        -Manifest (Copy-Manifest) -ExpectedMessage "action is not pinned to a full commit SHA"

    $mutableDocker = $workflow -replace '(?m)^(\s*- name: Run delivery contract tests\s*)$', "      - name: Mutable container action`n        uses: docker://alpine:latest`n`$1"
    Assert-StaticMutationRejected -Name "mutable Docker action" `
        -WorkflowContent $mutableDocker -Manifest (Copy-Manifest) `
        -ExpectedMessage "Docker action is not pinned to a sha256 digest"

    $mutatedManifest = Copy-Manifest
    $mutatedManifest.jobs[0].expectedInstances = 2
    Assert-StaticMutationRejected -Name "reduced matrix expectation" -WorkflowContent $workflow `
        -Manifest $mutatedManifest -ExpectedMessage "must declare one single execution instance"

    $mutatedManifest = Copy-Manifest
    $mutatedManifest.jobs[0].discovery.rationale = ""
    Assert-StaticMutationRejected -Name "unjustified zero discovery" -WorkflowContent $workflow `
        -Manifest $mutatedManifest -ExpectedMessage "explain its discovery contract"

    $mutatedManifest = Copy-Manifest
    $mutatedManifest.jobs[0].evidenceFiles = @()
    Assert-StaticMutationRejected -Name "empty evidence contract" -WorkflowContent $workflow `
        -Manifest $mutatedManifest -ExpectedMessage "defines no evidence files"

    $validFixture = New-ValidResultFixture
    $validFailures = @(Test-CiDeliveryResult -RequiredChecks $requiredChecks -Sha $validFixture.Sha `
            -RunDetails $validFixture.Run -Artifacts $validFixture.Artifacts `
            -EvidenceRoots $validFixture.EvidenceRoots)
    if ($validFailures.Count -ne 0) {
        throw "Valid delivery result failed: $($validFailures -join '; ')"
    }
    Write-Host "PASS valid delivery result"

    Assert-ResultMutationRejected -Name "missing job" `
        -Mutate { param($f) $f.Run.jobs = @($f.Run.jobs | Select-Object -Skip 1) } `
        -ExpectedMessage "appeared 0 times"
    Assert-ResultMutationRejected -Name "skipped job" `
        -Mutate { param($f) $f.Run.jobs[0].conclusion = "skipped" } `
        -ExpectedMessage "completed/skipped"
    Assert-ResultMutationRejected -Name "neutral job" `
        -Mutate { param($f) $f.Run.jobs[0].conclusion = "neutral" } `
        -ExpectedMessage "completed/neutral"
    Assert-ResultMutationRejected -Name "cancelled run" `
        -Mutate { param($f) $f.Run.conclusion = "cancelled" } `
        -ExpectedMessage "completed/cancelled"
    Assert-ResultMutationRejected -Name "timed-out incomplete run" `
        -Mutate { param($f) $f.Run.status = "queued" } `
        -ExpectedMessage "queued/success"
    Assert-ResultMutationRejected -Name "mismatched source SHA" `
        -Mutate { param($f) $f.Run.headSha = "cccccccccccccccccccccccccccccccccccccccc" } `
        -ExpectedMessage "does not equal"
    Assert-ResultMutationRejected -Name "merge-only event" `
        -Mutate { param($f) $f.Run.event = "pull_request" } `
        -ExpectedMessage "does not equal 'push'"
    Assert-ResultMutationRejected -Name "missing artifact" `
        -Mutate { param($f) $f.Artifacts = @($f.Artifacts | Select-Object -Skip 1) } `
        -ExpectedMessage "artifact 'delivery-contract-"
    Assert-ResultMutationRejected -Name "empty artifact" `
        -Mutate { param($f) $f.Artifacts[0].size_in_bytes = 0 } `
        -ExpectedMessage "minimum is"
    Assert-ResultMutationRejected -Name "missing artifact digest" `
        -Mutate { param($f) $f.Artifacts[0].digest = "" } `
        -ExpectedMessage "missing or invalid sha256 digest"
    Assert-ResultMutationRejected -Name "short actual retention" `
        -Mutate { param($f) $f.Artifacts[0].expires_at = "2026-08-21T00:00:00Z" } `
        -ExpectedMessage "retention is 30 days"
    Assert-ResultMutationRejected -Name "artifact bound to another SHA" `
        -Mutate { param($f) $f.Artifacts[0].workflow_run.head_sha = "dddddddddddddddddddddddddddddddddddddddd" } `
        -ExpectedMessage "is not bound to source SHA"
    Assert-ResultMutationRejected -Name "missing evidence file" `
        -Mutate {
            param($f)
            $artifactName = $f.Artifacts[0].name
            $target = Join-Path $f.EvidenceRoots[$artifactName] $requiredChecks.jobs[0].evidenceFiles[0].path
            Remove-Item -LiteralPath $target
        } -ExpectedMessage "is missing evidence file"
    Assert-ResultMutationRejected -Name "zero-length evidence file" `
        -Mutate {
            param($f)
            $artifactName = $f.Artifacts[0].name
            $target = Join-Path $f.EvidenceRoots[$artifactName] $requiredChecks.jobs[0].evidenceFiles[0].path
            [IO.File]::WriteAllText($target, "")
        } -ExpectedMessage "minimum is"
    Assert-ResultMutationRejected -Name "unexpected evidence file" `
        -Mutate {
            param($f)
            $artifactName = $f.Artifacts[0].name
            $target = Join-Path $f.EvidenceRoots[$artifactName] "unexpected.txt"
            [IO.File]::WriteAllText($target, "unexpected")
        } -ExpectedMessage "has unexpected evidence file"

    Write-Host "CI delivery contract tests passed."
} finally {
    $resolvedTemp = [IO.Path]::GetFullPath($tempRoot)
    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemp.StartsWith($systemTemp, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedTemp) -like "aemeath-ci-contract-*") {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

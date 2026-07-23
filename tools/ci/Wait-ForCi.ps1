[CmdletBinding()]
param(
    [string]$Sha = "",
    [string]$RequiredChecksPath = ".github/ci/required-checks.json",
    [ValidateRange(30, 7200)]
    [int]$TimeoutSeconds = 1800,
    [ValidateRange(2, 60)]
    [int]$PollSeconds = 10
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-Gh {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        [switch]$Json
    )

    $attempt = 0
    do {
        $attempt++
        $output = & gh @Arguments 2>&1
        if ($LASTEXITCODE -eq 0) {
            $text = ($output | Out-String).Trim()
            if ($Json) {
                if ([string]::IsNullOrWhiteSpace($text)) {
                    return $null
                }

                return $text | ConvertFrom-Json
            }

            return $text
        }

        if ($attempt -lt 3) {
            Start-Sleep -Seconds 2
        }
    } while ($attempt -lt 3)

    throw "gh $($Arguments -join ' ') failed after $attempt attempts: $($output | Out-String)"
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    throw "GitHub CLI (gh) is required."
}

if (-not (Test-Path -LiteralPath $RequiredChecksPath -PathType Leaf)) {
    throw "Required-check manifest not found: $RequiredChecksPath"
}

$requiredChecks = Get-Content -Raw -LiteralPath $RequiredChecksPath | ConvertFrom-Json
if ($requiredChecks.schemaVersion -ne 1) {
    throw "Unsupported required-check manifest schema: $($requiredChecks.schemaVersion)"
}

if (@($requiredChecks.jobs).Count -eq 0) {
    throw "The required-check manifest contains no jobs."
}

if ([string]::IsNullOrWhiteSpace($Sha)) {
    $Sha = ((& git rev-parse HEAD 2>&1) | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to resolve the current Git SHA."
    }
}

$Sha = $Sha.Trim().ToLowerInvariant()
if ($Sha -notmatch '^[0-9a-f]{40}$') {
    throw "Sha must be a complete 40-character commit SHA; received '$Sha'."
}

$workflowFile = Split-Path -Leaf ([string]$requiredChecks.workflowFile)
$requiredEvent = [string]$requiredChecks.requiredEvent
if ([string]::IsNullOrWhiteSpace($workflowFile) -or
    [string]::IsNullOrWhiteSpace($requiredEvent)) {
    throw "The required-check manifest must define workflowFile and requiredEvent."
}

$repository = Invoke-Gh -Arguments @("repo", "view", "--json", "nameWithOwner", "--jq", ".nameWithOwner")
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$run = $null

Write-Host "Waiting for workflow '$workflowFile', event '$requiredEvent', exact SHA '$Sha'."
while ($timer.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
    try {
        $listedRuns = Invoke-Gh -Json -Arguments @(
            "run", "list",
            "--workflow", $workflowFile,
            "--commit", $Sha,
            "--event", $requiredEvent,
            "--limit", "20",
            "--json", "databaseId,status,conclusion,headSha,event,url,createdAt"
        )

        $matchingRuns = @($listedRuns | Where-Object {
                $_.headSha.ToLowerInvariant() -eq $Sha -and $_.event -eq $requiredEvent
            } | Sort-Object -Property createdAt -Descending)

        if ($matchingRuns.Count -gt 0) {
            $run = $matchingRuns[0]
            Write-Host "Run $($run.databaseId): status=$($run.status), conclusion=$($run.conclusion)."
            if ($run.status -eq "completed") {
                break
            }
        } else {
            Write-Host "No matching run is visible yet."
        }
    } catch {
        Write-Warning "Transient workflow query failure: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds $PollSeconds
}

if ($null -eq $run -or $run.status -ne "completed") {
    throw "Timed out after $TimeoutSeconds seconds waiting for exact-SHA CI."
}

$runDetails = Invoke-Gh -Json -Arguments @(
    "run", "view", ([string]$run.databaseId),
    "--json", "jobs,status,conclusion,headSha,event,url"
)
$artifactResponse = Invoke-Gh -Json -Arguments @(
    "api",
    "-H", "Accept: application/vnd.github+json",
    "-H", "X-GitHub-Api-Version: 2026-03-10",
    "repos/$repository/actions/runs/$($run.databaseId)/artifacts?per_page=100"
)
$artifacts = @($artifactResponse.artifacts)
$downloadRoot = Join-Path ([IO.Path]::GetTempPath()) ("aemeath-ci-evidence-" + [guid]::NewGuid().ToString("N"))
$evidenceRoots = @{}

try {
    New-Item -ItemType Directory -Path $downloadRoot | Out-Null
    foreach ($requiredJob in @($requiredChecks.jobs)) {
        $artifactName = "$($requiredJob.artifactPrefix)$Sha"
        $jobRoot = Join-Path $downloadRoot $requiredJob.id
        New-Item -ItemType Directory -Path $jobRoot | Out-Null
        $null = Invoke-Gh -Arguments @(
            "run", "download", ([string]$run.databaseId),
            "--name", $artifactName,
            "--dir", $jobRoot
        )
        $evidenceRoots[$artifactName] = $jobRoot
    }

    Import-Module (Join-Path $PSScriptRoot "CiDeliveryContract.psm1") -Force
    $failures = @(Test-CiDeliveryResult -RequiredChecks $requiredChecks -Sha $Sha `
            -RunDetails $runDetails -Artifacts $artifacts -EvidenceRoots $evidenceRoots)
    if ($failures.Count -gt 0) {
        throw ("Exact-SHA CI verification failed:`n - " + ($failures -join "`n - "))
    }

    $jobSummaries = foreach ($requiredJob in @($requiredChecks.jobs)) {
        $job = @($runDetails.jobs | Where-Object { $_.name -eq $requiredJob.name })[0]
        $artifactName = "$($requiredJob.artifactPrefix)$Sha"
        $artifact = @($artifacts | Where-Object { $_.name -eq $artifactName })[0]
        [PSCustomObject]@{
            id = $requiredJob.id
            name = $requiredJob.name
            conclusion = $job.conclusion
            artifact = $artifactName
            artifactBytes = $artifact.size_in_bytes
            artifactDigest = $artifact.digest
            artifactExpiresAt = $artifact.expires_at
            evidenceFiles = @($requiredJob.evidenceFiles.path)
        }
    }

    [PSCustomObject]@{
        schemaVersion = 1
        repository = $repository
        sha = $Sha
        event = $requiredEvent
        runId = $run.databaseId
        runUrl = $run.url
        conclusion = $run.conclusion
        jobs = @($jobSummaries)
    } | ConvertTo-Json -Depth 6
} finally {
    $resolvedDownloadRoot = [IO.Path]::GetFullPath($downloadRoot)
    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedDownloadRoot.StartsWith($systemTemp, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedDownloadRoot) -like "aemeath-ci-evidence-*") {
        Remove-Item -LiteralPath $resolvedDownloadRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

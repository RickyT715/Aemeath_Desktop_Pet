Set-StrictMode -Version Latest

function Test-CiDeliveryResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$RequiredChecks,
        [Parameter(Mandatory = $true)]
        [string]$Sha,
        [Parameter(Mandatory = $true)]
        [object]$RunDetails,
        [Parameter(Mandatory = $true)]
        [object[]]$Artifacts,
        [hashtable]$EvidenceRoots = @{}
    )

    $failures = [System.Collections.Generic.List[string]]::new()
    $normalizedSha = $Sha.ToLowerInvariant()
    $requiredEvent = [string]$RequiredChecks.requiredEvent

    if ([string]$RunDetails.headSha -notmatch '^[0-9a-fA-F]{40}$' -or
        $RunDetails.headSha.ToLowerInvariant() -ne $normalizedSha) {
        $failures.Add("run head SHA '$($RunDetails.headSha)' does not equal '$normalizedSha'")
    }

    if ($RunDetails.event -ne $requiredEvent) {
        $failures.Add("run event '$($RunDetails.event)' does not equal '$requiredEvent'")
    }

    if ($RunDetails.status -ne "completed" -or $RunDetails.conclusion -ne "success") {
        $failures.Add("workflow status/conclusion is '$($RunDetails.status)/$($RunDetails.conclusion)'")
    }

    foreach ($requiredJob in @($RequiredChecks.jobs)) {
        $matchingJobs = @($RunDetails.jobs | Where-Object { $_.name -eq $requiredJob.name })
        if ($matchingJobs.Count -ne [int]$requiredJob.expectedInstances) {
            $failures.Add(
                "required job '$($requiredJob.name)' appeared $($matchingJobs.Count) times; " +
                "expected $($requiredJob.expectedInstances)"
            )
            continue
        }

        foreach ($job in $matchingJobs) {
            if ($job.status -ne "completed" -or $job.conclusion -ne "success") {
                $failures.Add("required job '$($requiredJob.name)' is '$($job.status)/$($job.conclusion)'")
            }
        }

        $artifactName = "$($requiredJob.artifactPrefix)$normalizedSha"
        $matchingArtifacts = @($Artifacts | Where-Object { $_.name -eq $artifactName })
        if ($matchingArtifacts.Count -ne 1) {
            $failures.Add("artifact '$artifactName' appeared $($matchingArtifacts.Count) times")
            continue
        }

        $artifact = $matchingArtifacts[0]
        if ($artifact.expired -ne $false) {
            $failures.Add("artifact '$artifactName' is expired or has no explicit non-expired state")
        }

        if ([long]$artifact.size_in_bytes -lt [long]$requiredJob.minimumArtifactBytes) {
            $failures.Add(
                "artifact '$artifactName' has $($artifact.size_in_bytes) bytes; " +
                "minimum is $($requiredJob.minimumArtifactBytes)"
            )
        }

        $digestPattern = "^$([regex]::Escape([string]$requiredJob.digestAlgorithm)):[0-9a-fA-F]{64}$"
        if ([string]$artifact.digest -notmatch $digestPattern) {
            $failures.Add("artifact '$artifactName' has missing or invalid $($requiredJob.digestAlgorithm) digest")
        }

        if ($null -eq $artifact.workflow_run -or
            [string]$artifact.workflow_run.head_sha -notmatch '^[0-9a-fA-F]{40}$' -or
            $artifact.workflow_run.head_sha.ToLowerInvariant() -ne $normalizedSha) {
            $failures.Add("artifact '$artifactName' is not bound to source SHA '$normalizedSha'")
        }

        try {
            $createdAt = [DateTimeOffset]::Parse([string]$artifact.created_at)
            $expiresAt = [DateTimeOffset]::Parse([string]$artifact.expires_at)
            $retentionDays = ($expiresAt - $createdAt).TotalDays
            if ($retentionDays -lt ([double]$RequiredChecks.minimumRetentionDays - 0.01)) {
                $failures.Add(
                    "artifact '$artifactName' retention is $([math]::Round($retentionDays, 2)) days; " +
                    "minimum is $($RequiredChecks.minimumRetentionDays)"
                )
            }
        } catch {
            $failures.Add("artifact '$artifactName' has invalid created_at/expires_at timestamps")
        }

        if (-not $EvidenceRoots.ContainsKey($artifactName)) {
            $failures.Add("artifact '$artifactName' was not downloaded for evidence inspection")
            continue
        }

        $evidenceRoot = [IO.Path]::GetFullPath([string]$EvidenceRoots[$artifactName]).TrimEnd(
            [IO.Path]::DirectorySeparatorChar,
            [IO.Path]::AltDirectorySeparatorChar
        )
        if (-not (Test-Path -LiteralPath $evidenceRoot -PathType Container)) {
            $failures.Add("artifact '$artifactName' evidence root is missing")
            continue
        }

        $expectedPaths = [System.Collections.Generic.HashSet[string]]::new(
            [StringComparer]::OrdinalIgnoreCase
        )
        foreach ($evidenceFile in @($requiredJob.evidenceFiles)) {
            $relativePath = ([string]$evidenceFile.path).Replace('\', '/')
            $null = $expectedPaths.Add($relativePath)
            $candidate = [IO.Path]::GetFullPath((Join-Path $evidenceRoot $relativePath))
            $rootPrefix = $evidenceRoot + [IO.Path]::DirectorySeparatorChar
            if (-not $candidate.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                $failures.Add("artifact '$artifactName' contains an unsafe expected path '$relativePath'")
                continue
            }

            if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
                $failures.Add("artifact '$artifactName' is missing evidence file '$relativePath'")
                continue
            }

            $length = (Get-Item -LiteralPath $candidate).Length
            if ($length -lt [long]$evidenceFile.minimumBytes) {
                $failures.Add(
                    "artifact '$artifactName' evidence '$relativePath' has $length bytes; " +
                    "minimum is $($evidenceFile.minimumBytes)"
                )
            }
        }

        foreach ($actualFile in @(Get-ChildItem -LiteralPath $evidenceRoot -Recurse -File)) {
            $relativePath = $actualFile.FullName.Substring($evidenceRoot.Length).TrimStart(
                [IO.Path]::DirectorySeparatorChar,
                [IO.Path]::AltDirectorySeparatorChar
            ).Replace('\', '/')
            if (-not $expectedPaths.Contains($relativePath)) {
                $failures.Add("artifact '$artifactName' has unexpected evidence file '$relativePath'")
            }
        }
    }

    return $failures.ToArray()
}

Export-ModuleMember -Function Test-CiDeliveryResult

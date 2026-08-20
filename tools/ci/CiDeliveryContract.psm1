Set-StrictMode -Version Latest
$script:CiDiscoveryMarkerPrefix = "AEMEATH_CI_DISCOVERY_V1="
$script:CiDiscoveryMarkerFields = @("schemaVersion", "resultId", "sourceSha", "actualDiscovery", "failed", "skipped")

function Write-CiDiscoveryMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResultId,
        [Parameter(Mandatory = $true)]
        [long]$ActualDiscovery,
        [string]$RepositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
    )

    if ($ActualDiscovery -lt 0) {
        throw "Discovery count cannot be negative."
    }

    try {
        $resolvedRoot = [IO.Path]::GetFullPath($RepositoryRoot)
    } catch {
        throw "Discovery marker repository root is invalid: $RepositoryRoot"
    }
    if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
        throw "Discovery marker repository root does not exist: $resolvedRoot"
    }

    $shaOutput = @(& git -C $resolvedRoot rev-parse --verify HEAD 2>&1)
    $gitExitCode = $LASTEXITCODE
    if ($gitExitCode -ne 0 -or $shaOutput.Count -ne 1 -or
        [string]::IsNullOrWhiteSpace([string]$shaOutput[0])) {
        throw "Could not resolve the Git HEAD for discovery evidence."
    }
    $sourceSha = ([string]$shaOutput[0]).Trim().ToLowerInvariant()
    if ($sourceSha -cnotmatch '^[0-9a-f]{40}$') {
        throw "Git HEAD was not a lowercase 40-character SHA."
    }

    $record = [ordered]@{
        schemaVersion = 1
        resultId = $ResultId
        sourceSha = $sourceSha
        actualDiscovery = $ActualDiscovery
        failed = 0
        skipped = 0
    }
    Write-Output ($script:CiDiscoveryMarkerPrefix + ($record | ConvertTo-Json -Compress))
}

function Get-CiObjectPropertyValue {
    param([object]$InputObject, [string]$Name)
    if ($null -eq $InputObject) { return $null }; $property = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}
function Test-CiJsonInteger { param([object]$Value); return $Value -is [int] -or $Value -is [long] }
function Get-CiJsonTopLevelPropertyNames { param([string]$Json)
    $names = [System.Collections.Generic.List[string]]::new(); $depth = 0
    for ($index = 0; $index -lt $Json.Length; $index++) {
        $character = $Json[$index]
        if ($character -eq '{' -or $character -eq '[') { $depth++; continue }
        if ($character -eq '}' -or $character -eq ']') { $depth--; continue }
        if ($character -ne '"') { continue }
        $start = $index; $escaped = $false
        for ($index++; $index -lt $Json.Length; $index++) {
            $character = $Json[$index]
            if ($escaped) { $escaped = $false; continue }
            if ($character -eq '\') { $escaped = $true; continue }
            if ($character -eq '"') { break }
        }
        if ($index -ge $Json.Length) { return $null }
        $next = $index + 1; while ($next -lt $Json.Length -and [char]::IsWhiteSpace($Json[$next])) { $next++ }
        if ($depth -ne 1 -or $next -ge $Json.Length -or $Json[$next] -ne ':') { continue }
        try {
            $decoded = $Json.Substring($start, $index - $start + 1) | ConvertFrom-Json -ErrorAction Stop
        } catch {
            return $null
        }
        if ($decoded -isnot [string]) { return $null }
        $names.Add([string]$decoded)
    }
    return [string[]]$names.ToArray()
}
function New-CiDiscoveryResultObject {
    param([System.Collections.Generic.List[string]]$Failures, [long]$ActualDiscoveredTests, [System.Collections.Generic.List[object]]$Results)
    return [PSCustomObject]@{ failures = [string[]]$Failures.ToArray(); actualDiscoveredTests = [long]$ActualDiscoveredTests; results = [object[]]$Results.ToArray() }
}
function Get-CiDiscoveryResult {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object]$RequiredJob, [Parameter(Mandatory = $true)][string]$Sha,
        [Parameter(Mandatory = $true)][string]$EvidenceRoot)
    $failures = [System.Collections.Generic.List[string]]::new()
    $results = [System.Collections.Generic.List[object]]::new()
    $jobId = [string](Get-CiObjectPropertyValue $RequiredJob "id")
    $discovery = Get-CiObjectPropertyValue $RequiredJob "discovery"
    if ($null -eq $discovery) { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' has no discovery contract"); return New-CiDiscoveryResultObject $failures 0 $results }
    $kind = [string](Get-CiObjectPropertyValue $discovery "kind")
    if ($kind -ceq "not-applicable") { return New-CiDiscoveryResultObject $failures 0 $results }
    if ($kind -cne "powershell-probe") { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' has unsupported discovery kind '$kind'"); return New-CiDiscoveryResultObject $failures 0 $results }
    $normalizedSha = $Sha.ToLowerInvariant()
    if ($Sha -notmatch '^[0-9a-fA-F]{40}$') { $failures.Add("[DISCOVERY-MARKER-SHA] job '$jobId' requested an invalid source SHA '$Sha'") }
    $states = [System.Collections.Generic.List[object]]::new()
    $stateByResultId = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
    $declaredResults = @(Get-CiObjectPropertyValue $discovery "results")
    if ($declaredResults.Count -eq 0) { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' declares no discovery results") }
    foreach ($declaredResult in $declaredResults) {
        $resultIdValue = Get-CiObjectPropertyValue $declaredResult "resultId"
        $evidencePathValue = Get-CiObjectPropertyValue $declaredResult "evidencePath"
        $minimumValue = Get-CiObjectPropertyValue $declaredResult "minimum"
        $includedValue = Get-CiObjectPropertyValue $declaredResult "includedInJobMinimum"
        $malformed = $resultIdValue -isnot [string] -or [string]::IsNullOrWhiteSpace($resultIdValue) -or
            $evidencePathValue -isnot [string] -or [string]::IsNullOrWhiteSpace($evidencePathValue) -or
            -not (Test-CiJsonInteger $minimumValue) -or [long]$minimumValue -le 0 -or $includedValue -isnot [bool]
        if ($malformed) { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' has a malformed result declaration"); continue }
        $resultId = [string]$resultIdValue
        $evidencePath = ([string]$evidencePathValue).Replace('\', '/')
        if ($stateByResultId.ContainsKey($resultId)) { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' declares result '$resultId' more than once"); continue }
        $state = [PSCustomObject]@{
            ResultId = $resultId; EvidencePath = $evidencePath; Minimum = [long]$minimumValue
            IncludedInJobMinimum = [bool]$includedValue
            Observations = [System.Collections.Generic.List[object]]::new()
        }
        $stateByResultId.Add($resultId, $state)
        $states.Add($state)
    }
    [long]$includedMinimum = 0
    $includedCount = 0
    foreach ($state in $states) {
        if ([bool]$state.IncludedInJobMinimum) { $includedCount++; $includedMinimum += [long]$state.Minimum }
    }
    $parentMinimum = Get-CiObjectPropertyValue $discovery "minimumDiscoveredTests"
    if (-not (Test-CiJsonInteger $parentMinimum) -or [long]$parentMinimum -lt 1 -or
        $includedCount -lt 1 -or [long]$parentMinimum -ne $includedMinimum) {
        $failures.Add("[DISCOVERY-CONTRACT-TOTAL] job '$jobId' parent minimum '$parentMinimum' does not equal the included component minimum '$includedMinimum'")
    }
    $comparison = [StringComparison]::Ordinal
    if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) { $comparison = [StringComparison]::OrdinalIgnoreCase }
    try { $resolvedRoot = [IO.Path]::GetFullPath($EvidenceRoot) }
    catch { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' has invalid evidence root '$EvidenceRoot'"); return New-CiDiscoveryResultObject $failures 0 $results }
    if (-not (Test-Path -LiteralPath $resolvedRoot -PathType Container)) {
        $failures.Add("[DISCOVERY-MARKER-MISSING] job '$jobId' evidence root is missing")
        foreach ($state in $states) {
            $results.Add([PSCustomObject]@{
                    resultId = $state.ResultId; evidencePath = $state.EvidencePath; minimum = [long]$state.Minimum
                    includedInJobMinimum = [bool]$state.IncludedInJobMinimum; actualDiscovery = [long]0
                })
        }
        return New-CiDiscoveryResultObject $failures 0 $results
    }
    $rootPrefix = $resolvedRoot
    if (-not $rootPrefix.EndsWith([IO.Path]::DirectorySeparatorChar.ToString()) -and
        -not $rootPrefix.EndsWith([IO.Path]::AltDirectorySeparatorChar.ToString())) {
        $rootPrefix += [IO.Path]::DirectorySeparatorChar
    }
    $scanPaths = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::Ordinal)
    foreach ($evidenceFile in @(Get-CiObjectPropertyValue $RequiredJob "evidenceFiles")) {
        $pathValue = Get-CiObjectPropertyValue $evidenceFile "path"
        if ($pathValue -is [string] -and -not [string]::IsNullOrWhiteSpace([string]$pathValue)) {
            $logicalPath = ([string]$pathValue).Replace('\', '/')
            if (-not $scanPaths.ContainsKey($logicalPath)) { $scanPaths.Add($logicalPath, $logicalPath) }
        }
    }
    foreach ($state in $states) {
        if (-not $scanPaths.ContainsKey([string]$state.EvidencePath)) {
            $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' result '$($state.ResultId)' uses undeclared evidence path '$($state.EvidencePath)'")
            $scanPaths.Add([string]$state.EvidencePath, [string]$state.EvidencePath)
        }
    }
    foreach ($logicalPath in @($scanPaths.Keys)) {
        if ([IO.Path]::IsPathRooted($logicalPath)) { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' has unsafe evidence path '$logicalPath'"); continue }
        try { $candidate = [IO.Path]::GetFullPath((Join-Path $resolvedRoot $logicalPath)) }
        catch { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' has invalid evidence path '$logicalPath'"); continue }
        if (-not $candidate.StartsWith($rootPrefix, $comparison)) { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' has unsafe evidence path '$logicalPath'"); continue }
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { continue }
        try { $content = [IO.File]::ReadAllText($candidate) }
        catch { $failures.Add("[DISCOVERY-MARKER-MISSING] job '$jobId' cannot read evidence '$logicalPath'"); continue }
        $lines = $content.Split([string[]]@("`n"), [StringSplitOptions]::None)
        for ($lineIndex = 0; $lineIndex -lt $lines.Length; $lineIndex++) {
            $line = [string]$lines[$lineIndex]
            if ($line.EndsWith("`r")) { $line = $line.Substring(0, $line.Length - 1) }
            if (-not $line.StartsWith($script:CiDiscoveryMarkerPrefix, [StringComparison]::Ordinal)) { continue }
            $payload = $line.Substring($script:CiDiscoveryMarkerPrefix.Length)
            try { $marker = $payload | ConvertFrom-Json -ErrorAction Stop }
            catch { $failures.Add("[DISCOVERY-MARKER-JSON] job '$jobId' evidence '$logicalPath' line $($lineIndex + 1) has malformed discovery marker JSON"); continue }
            $rawKeyNames = @(Get-CiJsonTopLevelPropertyNames $payload)
            $rawKeys = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            $rawShapeIsValid = $rawKeyNames.Count -eq $script:CiDiscoveryMarkerFields.Count
            foreach ($rawKeyName in $rawKeyNames) {
                if (-not $rawKeys.Add([string]$rawKeyName)) { $rawShapeIsValid = $false }
            }
            foreach ($field in $script:CiDiscoveryMarkerFields) { if (-not $rawKeys.Contains($field)) { $rawShapeIsValid = $false } }
            if (-not $rawShapeIsValid) { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' evidence '$logicalPath' line $($lineIndex + 1) has malformed discovery marker shape"); continue }
            $properties = @($marker.PSObject.Properties)
            $propertyNames = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
            foreach ($property in $properties) { $null = $propertyNames.Add([string]$property.Name) }
            $shapeIsValid = $marker -is [PSCustomObject] -and
                $properties.Count -eq $script:CiDiscoveryMarkerFields.Count -and
                $propertyNames.Count -eq $script:CiDiscoveryMarkerFields.Count
            foreach ($field in $script:CiDiscoveryMarkerFields) { if (-not $propertyNames.Contains($field)) { $shapeIsValid = $false } }
            if ($shapeIsValid) {
                $shapeIsValid = (Test-CiJsonInteger $marker.schemaVersion) -and
                    [long]$marker.schemaVersion -eq 1 -and
                    $marker.resultId -is [string] -and
                    $marker.sourceSha -is [string] -and
                    (Test-CiJsonInteger $marker.actualDiscovery) -and
                    (Test-CiJsonInteger $marker.failed) -and
                    (Test-CiJsonInteger $marker.skipped)
            }
            if (-not $shapeIsValid) { $failures.Add("[DISCOVERY-MARKER-SHAPE] job '$jobId' evidence '$logicalPath' line $($lineIndex + 1) has malformed discovery marker shape"); continue }
            $resultId = [string]$marker.resultId
            if (-not $stateByResultId.ContainsKey($resultId)) { $failures.Add("[DISCOVERY-MARKER-UNEXPECTED] job '$jobId' evidence '$logicalPath' has unexpected discovery result '$resultId'"); continue }
            $state = $stateByResultId[$resultId]
            $observation = [PSCustomObject]@{
                EvidencePath = $logicalPath; Line = $lineIndex + 1; SourceSha = [string]$marker.sourceSha
                ActualDiscovery = [long]$marker.actualDiscovery; Failed = [long]$marker.failed
                Skipped = [long]$marker.skipped
            }
            $state.Observations.Add($observation)
            if ($logicalPath -cne [string]$state.EvidencePath) { $failures.Add("[DISCOVERY-MARKER-UNEXPECTED] job '$jobId' result '$resultId' appeared in '$logicalPath'; expected '$($state.EvidencePath)'") }
        }
    }
    [long]$actualDiscoveredTests = 0
    foreach ($state in $states) {
        $expectedObservations = @($state.Observations | Where-Object {
                [string]$_.EvidencePath -ceq [string]$state.EvidencePath })
        if ($expectedObservations.Count -eq 0) { $failures.Add("[DISCOVERY-MARKER-MISSING] job '$jobId' result '$($state.ResultId)' marker appeared 0 times; expected 1 in '$($state.EvidencePath)'") }
        if ($state.Observations.Count -gt 1) { $failures.Add("[DISCOVERY-MARKER-DUPLICATE] job '$jobId' result '$($state.ResultId)' marker appeared $($state.Observations.Count) times; expected 1") }
        [long]$actualDiscovery = 0
        if ($expectedObservations.Count -gt 0) {
            $observation = $expectedObservations[0]
            $actualDiscovery = [long]$observation.ActualDiscovery
            if ([string]$observation.SourceSha -notmatch '^[0-9a-f]{40}$' -or
                [string]$observation.SourceSha -cne $normalizedSha) {
                $failures.Add("[DISCOVERY-MARKER-SHA] job '$jobId' result '$($state.ResultId)' discovery source SHA '$($observation.SourceSha)' does not equal '$normalizedSha'")
            }
            if ($actualDiscovery -lt [long]$state.Minimum) { $failures.Add("[DISCOVERY-MARKER-COUNTS] job '$jobId' result '$($state.ResultId)' discovered $actualDiscovery; minimum is $($state.Minimum)") }
            if ([long]$observation.Failed -ne 0) { $failures.Add("[DISCOVERY-MARKER-COUNTS] job '$jobId' result '$($state.ResultId)' reported $($observation.Failed) failed") }
            if ([long]$observation.Skipped -ne 0) { $failures.Add("[DISCOVERY-MARKER-COUNTS] job '$jobId' result '$($state.ResultId)' reported $($observation.Skipped) skipped") }
        }
        if ([bool]$state.IncludedInJobMinimum) {
            if ($actualDiscovery -gt [long]::MaxValue - $actualDiscoveredTests) {
                $failures.Add("[DISCOVERY-MARKER-COUNTS] job '$jobId' actual discovery total overflowed")
            } else {
                $actualDiscoveredTests += $actualDiscovery
            }
        }
        $results.Add([PSCustomObject]@{
                resultId = [string]$state.ResultId; evidencePath = [string]$state.EvidencePath
                minimum = [long]$state.Minimum; includedInJobMinimum = [bool]$state.IncludedInJobMinimum
                actualDiscovery = [long]$actualDiscovery
            })
    }
    return New-CiDiscoveryResultObject $failures $actualDiscoveredTests $results
}
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

        $containmentComparison = [StringComparison]::Ordinal
        if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
            $containmentComparison = [StringComparison]::OrdinalIgnoreCase
        }
        $expectedPaths = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
        foreach ($evidenceFile in @($requiredJob.evidenceFiles)) {
            $relativePath = ([string]$evidenceFile.path).Replace('\', '/')
            $null = $expectedPaths.Add($relativePath)
            $candidate = [IO.Path]::GetFullPath((Join-Path $evidenceRoot $relativePath))
            $rootPrefix = $evidenceRoot + [IO.Path]::DirectorySeparatorChar
            if (-not $candidate.StartsWith($rootPrefix, $containmentComparison)) {
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

        $discoveryResult = Get-CiDiscoveryResult -RequiredJob $requiredJob `
            -Sha $normalizedSha -EvidenceRoot $evidenceRoot
        foreach ($discoveryFailure in @($discoveryResult.failures)) {
            $failures.Add([string]$discoveryFailure)
        }
    }

    return $failures.ToArray()
}

Export-ModuleMember -Function Test-CiDeliveryResult, Get-CiDiscoveryResult, Write-CiDiscoveryMarker

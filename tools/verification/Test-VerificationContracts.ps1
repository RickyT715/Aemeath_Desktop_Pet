[CmdletBinding()]
param(
    [string]$TraceabilityPath = "docs/verification/traceability-v1.yml",
    [string]$FixtureDirectory = "tests/fixtures/verification/v1/invalid"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$requiredSchemaPaths = @(
    "docs/verification/schemas/traceability-v1.schema.json",
    "docs/verification/schemas/risk-lane-manifest-v1.schema.json",
    "docs/verification/schemas/evidence-manifest-v1.schema.json",
    "docs/verification/schemas/exact-sha-manifest-v1.schema.json"
)
$invalidationSchemaPath = "docs/verification/schemas/manifest-invalidation-v1.schema.json"
$schemaInstancePairs = @(
    @("docs/verification/schemas/risk-lane-manifest-v1.schema.json", "docs/verification/examples/risk-lane-manifest-v1.example.json"),
    @("docs/verification/schemas/evidence-manifest-v1.schema.json", "docs/verification/examples/evidence-manifest-v1.example.json"),
    @("docs/verification/schemas/exact-sha-manifest-v1.schema.json", "docs/verification/examples/exact-sha-manifest-v1.example.json")
)
$manifestV1Path = "docs/verification/manifests/D0.3-v1.yml"
$manifestV2Path = "docs/verification/manifests/D0.3-v2.yml"
$manifestV3Path = "docs/verification/manifests/D0.3-v3.yml"
$manifestV4Path = "docs/verification/manifests/D0.3-v4.yml"
$manifestV5Path = "docs/verification/manifests/D0.3-v5.yml"
$manifestV1InvalidationPath = "docs/verification/invalidations/D0.3-v1.json"
$manifestV2InvalidationPath = "docs/verification/invalidations/D0.3-v2.json"
$manifestV3InvalidationPath = "docs/verification/invalidations/D0.3-v3.json"
$manifestV4InvalidationPath = "docs/verification/invalidations/D0.3-v4.json"
$manifestV5RedEvidencePath = "docs/verification/evidence/D0.3-v5-red.md"
$generatorPath = "tools/verification/New-Traceability.ps1"
$schemaFallbackPath = "tools/verification/Validate-JsonSchema.py"
$requiredFixtureMutations = @(
    "missing-requirement", "duplicate-requirement", "stale-source-hash",
    "stale-entry-hash", "invalid-disposition", "orphan-test", "orphan-acceptance-criterion",
    "bare-nfr-reference"
)
$allowedLanes = @(
    "V-UNIT", "V-COMPONENT", "V-CONTRACT", "V-WPF", "V-UIA", "V-FIXTURE-E2E",
    "V-REAL-E2E", "V-SECURITY", "V-ACCESS", "V-PERF", "V-PACKAGE", "V-STATIC",
    "V-MANUAL-WIN", "V-LEGACY"
)
$allowedBehaviorIds = @(1..18 | ForEach-Object { "PB-{0:D3}" -f $_ })
$stepIdPattern = '(?:D0\.[1-5]|H0\.[1-6]|P0[AB]\.[1-9][a-z]?|P[1-9][0-9]*\.[1-9][0-9]*[a-z]?)'
$nonExecutableParentSteps = @(
    "P0A.3", "P0A.4", "P0A.5", "P0B.1", "P0B.2", "P0B.3",
    "P3.1", "P4.1", "P4.5", "P7.2", "P9.1", "P11.1"
)
$markdownAnchorCounts = @{}
$discoveredProbes = 0
$schemaNegativeControlsExecuted = 0
$semanticNegativeControlsExecuted = 0
$unexpectedSkips = 0

function Write-ProbePass {
    param([string]$Message)
    $script:discoveredProbes++
    Write-Host "PASS $Message"
}

function Get-TextHash {
    param([string]$Text)
    $normalized = $Text.Replace("`r`n", "`n").Replace("`r", "`n")
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($normalized)
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
}

function Get-NormalizedTextHash {
    param([string]$Path, [string]$Mode)
    $content = (Get-Content -Raw -Encoding UTF8 -LiteralPath $Path).Replace("`r`n", "`n").Replace("`r", "`n")
    if ($Mode -eq "normalized-checkbox-text") {
        $content = [regex]::Replace($content, '(?m)^(-\s+\[)[xX](\])', '$1 $2')
    } elseif ($Mode -ne "normalized-text") {
        throw "Unsupported hash mode '$Mode'."
    }
    return Get-TextHash $content
}

function Get-OrdinalUniqueStrings {
    param([object[]]$Values)
    $set = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($value in $Values) { $null = $set.Add([string]$value) }
    $result = [string[]]@($set)
    [Array]::Sort($result, [StringComparer]::Ordinal)
    return $result
}

function Get-ExpectedRequirementIds {
    $values = [System.Collections.Generic.List[string]]::new()
    $requirementsLines = @(Get-Content -Encoding UTF8 -LiteralPath "REQUIREMENTS.md")
    foreach ($line in $requirementsLines) {
        if ($line -match '^\|\s*((?:AR|FR-(?:PET|AI|VOICE|VISION|MEM|FUT)|PR|NFR)-\d{3})\s*\|') {
            $parentId = $Matches[1]
            $values.Add("CURRENT:$parentId")
            $acceptance = [regex]::Match($line, '(?<![A-Z0-9-])(AC-(?:AR|PET|AI|VOICE|VISION|MEM|FUT)-\d{3})(?![A-Z0-9-])')
            if ($acceptance.Success) {
                $acceptanceId = $acceptance.Groups[1].Value
                $expectedAcceptance = if ($parentId -match '^AR-(\d{3})$') {
                    "AC-AR-$($Matches[1])"
                } elseif ($parentId -match '^FR-(PET|AI|VOICE|VISION|MEM|FUT)-(\d{3})$') {
                    "AC-$($Matches[1])-$($Matches[2])"
                } else { "" }
                if ($acceptanceId -eq $expectedAcceptance) {
                    $values.Add("CURRENT:$acceptanceId")
                }
            }
        }
    }

    $checklist = Get-Content -Raw -Encoding UTF8 -LiteralPath "docs/plans/20260722-jarvis-assistant-tdd-checklist.md"
    foreach ($match in [regex]::Matches($checklist, '\|\s*REQMAP-CURRENT-([A-Z]+)\s*\|')) {
        $values.Add("CURRENT:LOC-$($match.Groups[1].Value)")
    }

    $prdLines = @(Get-Content -Encoding UTF8 -LiteralPath "docs/prd/jarvis_assistant_prd.md")
    foreach ($line in $prdLines) {
        $match = [regex]::Match($line, '^(?:###\s+|\d+\.\s+|-\s+|\|\s*)(AC-FR-\d{3}-\d{2}|NFR-JA-\d{3}(?:-\d{2})?|GATE-(?:0|[A-E])-\d{2}|RISK-\d{3})(?=[:\s|])')
        if ($match.Success) { $values.Add("PRD:$($match.Groups[1].Value)") }
    }

    $duplicateIds = @($values | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name)
    if ($duplicateIds.Count -gt 0) {
        throw "Normative sources contain duplicate authoritative IDs: $($duplicateIds -join ', ')."
    }
    $unique = @($values | Sort-Object -Unique)
    if ($unique.Count -ne 352) {
        throw "Expected exactly 352 authoritative IDs, found $($unique.Count)."
    }
    return $unique
}

function Test-MarkdownLocator {
    param([string]$Locator)
    if ($Locator -notmatch '^([^#]+\.md)#([a-z0-9][a-z0-9-]*)$') { return $false }
    $path = $Matches[1]
    $anchor = $Matches[2]
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    if (-not $script:markdownAnchorCounts.ContainsKey($path)) {
        $counts = @{}
        foreach ($heading in @(Get-Content -Encoding UTF8 -LiteralPath $path | Where-Object { $_ -match '^#{1,6}\s+' })) {
            $text = ($heading -replace '^#{1,6}\s+', '').Trim().ToLowerInvariant()
            $slug = [regex]::Replace($text, '[^a-z0-9\s-]', '')
            $slug = [regex]::Replace($slug, '\s+', '-').Trim('-')
            if (-not $counts.ContainsKey($slug)) { $counts[$slug] = 0 }
            $counts[$slug]++
        }
        $script:markdownAnchorCounts[$path] = $counts
    }
    $anchorCounts = $script:markdownAnchorCounts[$path]
    return $anchorCounts.ContainsKey($anchor) -and $anchorCounts[$anchor] -eq 1
}

function Get-TestIdParts {
    param([string]$TestId)
    foreach ($lane in @($allowedLanes | Sort-Object { $_.Length } -Descending)) {
        $pattern = "^($stepIdPattern)-$([regex]::Escape($lane))-([A-Z0-9-]+)$"
        if ($TestId -match $pattern) {
            return [PSCustomObject]@{ step = $Matches[1]; lane = $lane; token = $Matches[2] }
        }
    }
    return $null
}

function Add-ValidationFailure {
    param([System.Collections.Generic.List[object]]$Failures, [string]$Code, [string]$Message)
    $Failures.Add([PSCustomObject]@{ code = $Code; message = $Message })
}

function Test-TraceabilityObject {
    param([object]$Traceability)
    $failures = [System.Collections.Generic.List[object]]::new()
    $expectedIds = @(Get-ExpectedRequirementIds)
    if ($Traceability.schemaVersion -ne 1 -or $Traceability.documentType -ne "requirement-traceability") {
        Add-ValidationFailure $failures "TRACE-SCHEMA-VERSION" "Traceability identity is invalid."
    }
    if ($Traceability.baselineSha -ne "a6c15496cf2893a24e560c01ef4e598a635859cc" -or
        $Traceability.currentRequirementsOriginSha -ne "c2e3dbfd5e90bb40ea5006b702bbbc32d24a1ae7") {
        Add-ValidationFailure $failures "TRACE-BASELINE" "Frozen source revisions are missing or changed."
    }

    $sourceById = @{}
    foreach ($source in @($Traceability.sources)) {
        if ($sourceById.ContainsKey([string]$source.id)) {
            Add-ValidationFailure $failures "TRACE-DUPLICATE-SOURCE" "Duplicate source '$($source.id)'."
            continue
        }
        $sourceById[[string]$source.id] = $source
        if ([string]$source.revision -notmatch '^[0-9a-f]{40}$') {
            Add-ValidationFailure $failures "TRACE-SOURCE-REVISION" "Source '$($source.id)' has no full revision."
        }
        if (-not (Test-Path -LiteralPath $source.path -PathType Leaf)) {
            Add-ValidationFailure $failures "TRACE-MISSING-SOURCE" "Missing source '$($source.path)'."
            continue
        }
        try {
            if ((Get-NormalizedTextHash $source.path $source.hashMode) -ne $source.sha256) {
                Add-ValidationFailure $failures "TRACE-STALE-SOURCE-HASH" "Stale source hash for '$($source.id)'."
            }
        } catch {
            Add-ValidationFailure $failures "TRACE-SOURCE-HASH-MODE" $_.Exception.Message
        }
    }

    $entryIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $referencedTests = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $entryById = @{}
    foreach ($entry in @($Traceability.entries)) {
        $id = [string]$entry.id
        $entryById[$id] = $entry
        if (-not $entryIds.Add($id)) { Add-ValidationFailure $failures "TRACE-DUPLICATE-ID" "Duplicate requirement '$id'." }
        if ($expectedIds -notcontains $id) {
            $code = if ($id -like "PRD:AC-FR-*") { "TRACE-ORPHAN-AC" } else { "TRACE-ORPHAN-REQUIREMENT" }
            Add-ValidationFailure $failures $code "Unknown requirement '$id'."
        }
        $expectedNamespace = if ($id.StartsWith("CURRENT:")) { "CURRENT" } elseif ($id.StartsWith("PRD:")) { "PRD" } else { "" }
        if ([string]$entry.namespace -ne $expectedNamespace) {
            Add-ValidationFailure $failures "TRACE-NAMESPACE-MISMATCH" "Requirement '$id' has a mismatched namespace."
        }
        $expectedSourceId = if ($expectedNamespace -eq "CURRENT") { "CURRENT:REQUIREMENTS" } else { "PRD:JARVIS" }
        if ([string]$entry.sourceId -ne $expectedSourceId -or -not $sourceById.ContainsKey([string]$entry.sourceId)) {
            Add-ValidationFailure $failures "TRACE-UNKNOWN-SOURCE" "Requirement '$id' has the wrong source."
        } else {
            $source = $sourceById[[string]$entry.sourceId]
            if ([string]$entry.sourcePath -ne [string]$source.path -or
                [int]$entry.sourceLine -lt 1 -or [int]$entry.sourceEndLine -lt [int]$entry.sourceLine) {
                Add-ValidationFailure $failures "TRACE-SOURCE-LOCATOR" "Requirement '$id' has an invalid source range."
            } else {
                $lines = @(Get-Content -Encoding UTF8 -LiteralPath $entry.sourcePath)
                if ([int]$entry.sourceEndLine -gt $lines.Count) {
                    Add-ValidationFailure $failures "TRACE-SOURCE-LOCATOR" "Requirement '$id' source range exceeds its file."
                } else {
                    $text = $lines[([int]$entry.sourceLine - 1)..([int]$entry.sourceEndLine - 1)] -join "`n"
                    if ((Get-TextHash $text) -ne [string]$entry.sourceTextSha256) {
                        Add-ValidationFailure $failures "TRACE-STALE-ENTRY-HASH" "Requirement '$id' source statement hash is stale."
                    }
                    if ($id -match ':' -and $id -notlike "CURRENT:LOC-*" -and
                        $text -notmatch ('(?<![A-Z0-9-])' + [regex]::Escape(($id -split ':', 2)[1]) + '(?![A-Z0-9-])')) {
                        Add-ValidationFailure $failures "TRACE-SOURCE-TOKEN-RANGE" "Requirement '$id' source range does not contain its normative token."
                    }
                    if ($id -like "CURRENT:LOC-*" -and [int]$entry.sourceEndLine -le [int]$entry.sourceLine) {
                        Add-ValidationFailure $failures "TRACE-AGGREGATE-RANGE" "Aggregate locator '$id' hashes only its heading."
                    }
                }
            }
        }
        if ([string]$entry.sourceToken -ne $id) {
            Add-ValidationFailure $failures "TRACE-SOURCE-TOKEN" "Requirement '$id' lacks its qualified source token."
        }

        if ($expectedNamespace -eq "CURRENT") {
            if ($entry.disposition -ne "preserve" -or [string]::IsNullOrWhiteSpace([string]$entry.mapId)) {
                Add-ValidationFailure $failures "TRACE-INVALID-DISPOSITION" "Current item '$id' is not effectively Preserve with a map ID."
            }
            $approvalMap = @{
                "CURRENT:AR-003" = @("change", "APP-001"); "CURRENT:FR-AI-006" = @("change", "APP-002")
                "CURRENT:FR-MEM-001" = @("change", "APP-003"); "CURRENT:FR-MEM-002" = @("change", "APP-004")
                "CURRENT:FR-MEM-003" = @("change", "APP-005"); "CURRENT:FR-MEM-005" = @("change", "APP-006")
                "CURRENT:FR-FUT-001" = @("defer", "APP-007"); "CURRENT:FR-FUT-002" = @("defer", "APP-008")
                "CURRENT:FR-FUT-003" = @("defer", "APP-009")
            }
            $canonicalId = $id
            if ($id -match '^CURRENT:AC-AR-(\d{3})$') { $canonicalId = "CURRENT:AR-$($Matches[1])" }
            if ($id -match '^CURRENT:AC-(PET|AI|VOICE|VISION|MEM|FUT)-(\d{3})$') { $canonicalId = "CURRENT:FR-$($Matches[1])-$($Matches[2])" }
            if ($approvalMap.ContainsKey($canonicalId)) {
                $expectedApproval = $approvalMap[$canonicalId]
                if ($entry.proposedDisposition -ne $expectedApproval[0] -or $entry.approvalId -ne $expectedApproval[1] -or $entry.approvalStatus -ne "pending") {
                    Add-ValidationFailure $failures "TRACE-APPROVAL-METADATA" "Current item '$id' loses its pending proposed exception."
                }
            } elseif ($entry.proposedDisposition -ne "preserve" -or $entry.approvalStatus -ne "not-required") {
                Add-ValidationFailure $failures "TRACE-APPROVAL-METADATA" "Current item '$id' has an unauthorized proposal."
            }
        } elseif ($entry.disposition -ne "target" -or $entry.proposedDisposition -ne "target") {
            Add-ValidationFailure $failures "TRACE-INVALID-DISPOSITION" "PRD item '$id' is not a target."
        }

        $behaviorIds = @($entry.behaviorIds)
        if ($behaviorIds.Count -eq 0 -or @($behaviorIds | Where-Object { $allowedBehaviorIds -notcontains $_ }).Count -gt 0) {
            Add-ValidationFailure $failures "TRACE-INVALID-BEHAVIOR" "Requirement '$id' has no valid PB mapping."
        }
        foreach ($field in @("designSections", "uiSections", "checklistSteps")) {
            $locators = @($entry.$field)
            if ($locators.Count -eq 0) { Add-ValidationFailure $failures "TRACE-MISSING-MAPPING" "Requirement '$id' has no $field mapping." }
            foreach ($locator in $locators) {
                if (-not (Test-MarkdownLocator $locator)) { Add-ValidationFailure $failures "TRACE-INVALID-LOCATOR" "Requirement '$id' has invalid locator '$locator'." }
            }
        }
        $lanes = @($entry.lanes)
        if ($lanes.Count -eq 0 -or @($lanes | Where-Object { $allowedLanes -notcontains $_ }).Count -gt 0) {
            Add-ValidationFailure $failures "TRACE-INVALID-LANE" "Requirement '$id' has an empty or unknown lane."
        }
        foreach ($testId in @($entry.testIds)) {
            $parts = Get-TestIdParts ([string]$testId)
            if ($null -eq $parts) {
                Add-ValidationFailure $failures "TRACE-INVALID-TEST-ID" "Invalid stable test ID '$testId'."
            } elseif ($lanes -notcontains $parts.lane) {
                Add-ValidationFailure $failures "TRACE-TEST-LANE-MISMATCH" "Test '$testId' uses a lane not mapped by '$id'."
            }
            $null = $referencedTests.Add([string]$testId)
        }
        $evidencePaths = @($entry.evidencePaths)
        if ($evidencePaths.Count -eq 0 -or @($evidencePaths | Where-Object { $_ -notmatch '^docs/verification/evidence/[a-z0-9./-]+\.(json|md)$' -or $_ -match '(^|/)\.\.(/|$)' }).Count -gt 0) {
            Add-ValidationFailure $failures "TRACE-INVALID-EVIDENCE" "Requirement '$id' has no safe evidence path."
        }
    }
    foreach ($expectedId in $expectedIds) {
        if (-not $entryIds.Contains($expectedId)) { Add-ValidationFailure $failures "TRACE-MISSING-ID" "Missing requirement '$expectedId'." }
    }

    $currentMap = @($Traceability.dispositionMaps | Where-Object { $_.id -eq "REQMAP-CURRENT-V1" })
    $currentEntries = @($Traceability.entries | Where-Object { $_.namespace -eq "CURRENT" })
    if ($currentMap.Count -ne 1 -or [int]$currentMap[0].entryCount -ne $currentEntries.Count -or
        $currentMap[0].sourceId -ne "CURRENT:REQUIREMENTS") {
        Add-ValidationFailure $failures "TRACE-DISPOSITION-MAP" "Canonical current disposition-map identity is absent or inconsistent."
    } else {
        $mapRecords = Get-OrdinalUniqueStrings @($currentEntries | ForEach-Object {
                "$($_.id)|$($_.mapId)|$($_.currentStatus)|$($_.disposition)|$($_.proposedDisposition)|$($_.approvalId)|$($_.approvalStatus)|$($_.baselineTreatment)|$($_.sourceTextSha256)"
            })
        if ((Get-TextHash ($mapRecords -join "`n")) -ne $currentMap[0].recordsSha256) {
            Add-ValidationFailure $failures "TRACE-DISPOSITION-MAP" "Canonical current disposition-record hash is stale."
        }
    }

    foreach ($pair in @(
            @("AR", 1, 5), @("PET", 1, 14), @("AI", 1, 8), @("VOICE", 1, 3),
            @("VISION", 1, 4), @("MEM", 1, 7), @("FUT", 1, 3))) {
        $category = $pair[0]
        foreach ($number in $pair[1]..$pair[2]) {
            $suffix = "{0:D3}" -f $number
            $parentId = if ($category -eq "AR") { "CURRENT:AR-$suffix" } else { "CURRENT:FR-$category-$suffix" }
            $acceptanceId = "CURRENT:AC-$category-$suffix"
            $parent = $entryById[$parentId]
            $acceptance = $entryById[$acceptanceId]
            if ($null -ne $parent -and $null -ne $acceptance -and
                ((@($parent.behaviorIds) -join '|') -ne (@($acceptance.behaviorIds) -join '|') -or
                 (@($parent.testIds) -join '|') -ne (@($acceptance.testIds) -join '|'))) {
                Add-ValidationFailure $failures "TRACE-CURRENT-AC-INHERITANCE" "Acceptance '$acceptanceId' differs from '$parentId'."
            }
        }
    }

    $catalogIds = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $catalogById = @{}
    foreach ($test in @($Traceability.testCatalog)) {
        $testId = [string]$test.id
        $catalogById[$testId] = $test
        if (-not $catalogIds.Add($testId)) { Add-ValidationFailure $failures "TRACE-DUPLICATE-TEST" "Duplicate test '$testId'." }
        $parts = Get-TestIdParts $testId
        if ($null -eq $parts) {
            Add-ValidationFailure $failures "TRACE-INVALID-TEST-ID" "Invalid catalog test ID '$testId'."
        } else {
            if ($test.ownerStep -ne $parts.step -or $test.lane -ne $parts.lane) {
                Add-ValidationFailure $failures "TRACE-TEST-OWNER-MISMATCH" "Test '$testId' has inconsistent owner/lane metadata."
            }
            if ($nonExecutableParentSteps -contains $parts.step) {
                Add-ValidationFailure $failures "TRACE-NONEXECUTABLE-OWNER" "Test '$testId' is assigned to non-executable parent '$($parts.step)'."
            }
        }
        foreach ($requirementId in @($test.requirementIds)) {
            if (-not $entryIds.Contains([string]$requirementId)) {
                Add-ValidationFailure $failures "TRACE-TEST-UNKNOWN-REQUIREMENT" "Test '$testId' references unknown '$requirementId'."
            } elseif (@($entryById[[string]$requirementId].testIds) -notcontains $testId) {
                Add-ValidationFailure $failures "TRACE-TEST-BACKLINK" "Test '$testId' lacks a backlink from '$requirementId'."
            }
        }
    }
    foreach ($testId in $referencedTests) {
        if (-not $catalogIds.Contains($testId)) { Add-ValidationFailure $failures "TRACE-UNKNOWN-TEST" "Unknown test '$testId'." }
    }
    foreach ($testId in $catalogIds) {
        if (-not $referencedTests.Contains($testId)) { Add-ValidationFailure $failures "TRACE-ORPHAN-TEST" "Orphan test '$testId'." }
    }

    $d03Tests = @($Traceability.testCatalog | Where-Object { $_.ownerStep -eq "D0.3" })
    if ($d03Tests.Count -ne 1 -or [string]$d03Tests[0].id -ne "D0.3-V-STATIC-001" -or
        [string]$d03Tests[0].lane -ne "V-STATIC") {
        Add-ValidationFailure $failures "TRACE-ACTIVE-MANIFEST-DRIFT" "D0.3 catalog tests do not match its frozen static probe."
    }

    foreach ($entry in @($Traceability.entries | Where-Object { $_.baselineTreatment -eq "future-red-only" })) {
        $gateZeroTests = @($entry.testIds | Where-Object {
                $parts = Get-TestIdParts ([string]$_)
                $null -ne $parts -and $parts.step -match '^P0[AB]\.'
            })
        if ($gateZeroTests.Count -gt 0) {
            Add-ValidationFailure $failures "TRACE-FUTURE-RED-GATE0" "Future-only '$($entry.id)' is incorrectly treated as a Gate 0 pass case."
        }
    }

    $sharedFutureCases = @($Traceability.testCatalog | Where-Object {
            @($_.requirementIds | Where-Object { $_ -like "PRD:AC-FR-*" }).Count -gt 1
        })
    if ($sharedFutureCases.Count -lt 10) {
        Add-ValidationFailure $failures "TRACE-COLLAPSED-JOURNEYS" "Future criteria are encoded as one synthetic test per criterion instead of reusable cases."
    }
    $voiceRagProactiveFixtureE2e = @($Traceability.testCatalog | Where-Object {
            $_.ownerStep -match '^P9\.[123]' -and $_.lane -eq "V-FIXTURE-E2E"
        })
    if ($voiceRagProactiveFixtureE2e.Count -ne 3) {
        Add-ValidationFailure $failures "TRACE-E2E-BUDGET" "Voice/RAG/proactivity must expose exactly its three selected fixture journeys."
    }
    $requiredJourneyIds = @(
        "P0A.2-V-REAL-E2E-PET-VISIBILITY", "P0A.2-V-REAL-E2E-KEYBOARD-SURFACE",
        "P10.3-V-REAL-E2E-CONSENTED-READ", "P10.3-V-REAL-E2E-REVOCATION-SCHEMA-LIFECYCLE"
    )
    foreach ($journeyId in $requiredJourneyIds) {
        if (-not $catalogIds.Contains($journeyId)) {
            Add-ValidationFailure $failures "TRACE-MISSING-JOURNEY" "Selected journey '$journeyId' is absent."
        }
    }
    foreach ($owner in @("P4.1b", "P4.2", "P4.4", "P3.4", "P3.5", "P5.4", "P6.4", "P7.4", "P8.2", "P8.3", "P9.1a", "P9.2", "P9.3")) {
        $productJourney = @($Traceability.testCatalog | Where-Object {
                $_.ownerStep -eq $owner -and $_.lane -eq "V-FIXTURE-E2E" -and
                @($_.requirementIds | Where-Object { $_ -like "PRD:AC-FR-*" -and $_ -notlike "PRD:AC-FR-02[1-4]-*" }).Count -gt 0
            })
        if ($productJourney.Count -ne 1) {
            Add-ValidationFailure $failures "TRACE-MISSING-PHASE-JOURNEY" "Executable owner '$owner' lacks one reusable product fixture journey."
        }
    }
    foreach ($owner in @("P0A.3a", "P0A.4d", "P0A.4e")) {
        if (@($Traceability.testCatalog | Where-Object { $_.ownerStep -eq $owner }).Count -lt 1) {
            Add-ValidationFailure $failures "TRACE-UNMAPPED-EXECUTABLE-CHILD" "Executable checklist child '$owner' has no planned test."
        }
    }
    $gate0FixtureJourneys = @($Traceability.testCatalog | Where-Object {
            $_.ownerStep -match '^P0A\.' -and $_.lane -eq "V-FIXTURE-E2E"
        })
    $gate0RealJourneys = @($Traceability.testCatalog | Where-Object {
            $_.ownerStep -match '^P0A\.' -and $_.lane -eq "V-REAL-E2E"
        })
    if ($gate0FixtureJourneys.Count -ne 3 -or $gate0RealJourneys.Count -ne 2) {
        Add-ValidationFailure $failures "TRACE-E2E-BUDGET" "Gate 0 must contain exactly three fixture and two real-boundary E2E journeys across the complete phase."
    }
    $p0a4bCases = @($Traceability.testCatalog | Where-Object { $_.ownerStep -eq "P0A.4b" })
    $p0a5aCases = @($Traceability.testCatalog | Where-Object { $_.ownerStep -eq "P0A.5a" })
    $misownedPetIntegration = @($Traceability.testCatalog | Where-Object {
            $_.ownerStep -eq "P0A.5e" -and
            @($_.requirementIds | Where-Object { $_ -in @("CURRENT:FR-PET-014", "CURRENT:AC-PET-014") }).Count -gt 0
        })
    if (@($p0a4bCases | Where-Object { $_.behaviorIds -contains "PB-003" }).Count -lt 1 -or
        @($p0a5aCases | Where-Object { $_.behaviorIds -contains "PB-001" }).Count -lt 1 -or
        $misownedPetIntegration.Count -gt 0) {
        Add-ValidationFailure $failures "TRACE-CHILD-PB-OWNERSHIP" "Gate 0 executable children do not own their declared preservation-boundary responsibilities."
    }
    if (@($entryById["PRD:AC-FR-021-07"].lanes | Where-Object { $_ -in @("V-STATIC", "V-CONTRACT") }).Count -gt 0) {
        Add-ValidationFailure $failures "TRACE-PHANTOM-OWNER-LANE" "AC-FR-021-07 assigns static/contract work to its real-boundary owner."
    }

    $requiredLaneSets = @{
        "PRD:AC-FR-024-02" = @("V-UNIT", "V-COMPONENT", "V-CONTRACT", "V-WPF", "V-UIA", "V-FIXTURE-E2E", "V-REAL-E2E", "V-SECURITY", "V-ACCESS", "V-PERF", "V-PACKAGE", "V-STATIC")
        "PRD:GATE-0-03" = @("V-UNIT", "V-COMPONENT", "V-WPF", "V-UIA", "V-FIXTURE-E2E", "V-REAL-E2E")
        "PRD:GATE-0-04" = @("V-CONTRACT", "V-SECURITY", "V-ACCESS", "V-PERF", "V-PACKAGE", "V-STATIC")
    }
    foreach ($requiredId in $requiredLaneSets.Keys) {
        foreach ($lane in $requiredLaneSets[$requiredId]) {
            if (@($entryById[$requiredId].lanes) -notcontains $lane) {
                Add-ValidationFailure $failures "TRACE-SEMANTIC-LANE" "Requirement '$requiredId' is missing '$lane'."
            }
        }
    }
    foreach ($requiredId in @("PRD:AC-FR-021-03", "PRD:AC-FR-021-12", "PRD:GATE-0-06")) {
        if (@($entryById[$requiredId].lanes) -notcontains "V-LEGACY") {
            Add-ValidationFailure $failures "TRACE-SEMANTIC-LEGACY" "Requirement '$requiredId' lacks the separate legacy lane."
        }
    }
    $semanticExpectations = @{
        "CURRENT:FR-PET-004" = @("p45-complete-retained-pet-gaps-without-regression")
        "CURRENT:FR-MEM-006" = @("p74-build-memory-center")
        "PRD:AC-FR-001-02" = @("p43-create-one-authoritative-assistant-presentation-reducer", "p91-implement-modular-push-to-talk-voice")
        "PRD:AC-FR-007-02" = @("p34-persist-approval-and-resume-safely", "p42-build-task-approval-receipt-and-undo-journeys")
        "PRD:AC-FR-008-04" = @("p36-implement-receipts-and-privacy-safe-activity-history", "p42-build-task-approval-receipt-and-undo-journeys")
        "PRD:AC-FR-020-04" = @("p72-implement-canonical-memory-schemaservice", "p74-build-memory-center")
        "PRD:AC-FR-003-04" = @("p54-build-today-journey-and-pet-cue", "p36-implement-receipts-and-privacy-safe-activity-history")
        "PRD:AC-FR-004-04" = @("p51-implement-reminder-domain-and-persistence", "p36-implement-receipts-and-privacy-safe-activity-history")
        "PRD:AC-FR-005-06" = @("p62-implement-windows-context-adapters", "p43-create-one-authoritative-assistant-presentation-reducer")
        "PRD:AC-FR-008-05" = @("p34-persist-approval-and-resume-safely", "p35-implement-execution-adapters-idempotency-reconciliation-and-undo", "p36-implement-receipts-and-privacy-safe-activity-history", "p42-build-task-approval-receipt-and-undo-journeys")
        "PRD:AC-FR-009-06" = @("p74-build-memory-center", "p75-cut-over-authority-and-retire-legacy-writes")
        "PRD:GATE-A-02" = @("p14-protect-secrets-and-migrate-configuration", "p22-supervise-authenticated-sidecar-startup", "p44-build-diagnostics-and-safe-support-export")
        "PRD:GATE-C-01" = @("p61-implement-protected-context-lifecycle", "p63-implement-redaction-and-route-policy", "p64-build-grounded-conversation-with-citations")
        "PRD:GATE-D-01" = @("p33-implement-policy-grants-and-revocation", "p34-persist-approval-and-resume-safely", "p35-implement-execution-adapters-idempotency-reconciliation-and-undo", "p36-implement-receipts-and-privacy-safe-activity-history", "p83-complete-approval-receipt-and-undo-ux")
        "PRD:GATE-D-02" = @("p35-implement-execution-adapters-idempotency-reconciliation-and-undo", "p84-real-action-pilot-and-adversarial-gate")
        "PRD:GATE-B-02" = @("p36-implement-receipts-and-privacy-safe-activity-history", "p42-build-task-approval-receipt-and-undo-journeys")
        "PRD:RISK-007" = @("p35-implement-execution-adapters-idempotency-reconciliation-and-undo", "p42-build-task-approval-receipt-and-undo-journeys", "p84-real-action-pilot-and-adversarial-gate")
        "PRD:RISK-010" = @("p0a1-freeze-preservation-specification-and-risk-map", "p0a3-build-a-test-only-failure-detecting-preservation-harness")
        "PRD:NFR-JA-004-01" = @("p12-adopt-generic-host-and-owned-lifecycle")
        "PRD:NFR-JA-004-03" = @("p21-define-and-generate-the-protocol")
        "PRD:NFR-JA-006-02" = @("p21-define-and-generate-the-protocol")
    }
    foreach ($requiredId in $semanticExpectations.Keys) {
        $actualSteps = @($entryById[$requiredId].checklistSteps) -join '|'
        foreach ($expectedStep in $semanticExpectations[$requiredId]) {
            if ($actualSteps -notmatch [regex]::Escape($expectedStep)) {
                Add-ValidationFailure $failures "TRACE-SEMANTIC-STEP" "Requirement '$requiredId' is missing execution target '$expectedStep'."
            }
        }
    }
    if (@($entryById["CURRENT:AR-002"].behaviorIds) -notcontains "PB-012" -or
        @($entryById["CURRENT:NFR-004"].behaviorIds | Where-Object { $_ -in @("PB-001", "PB-011", "PB-017", "PB-018") }).Count -ne 4 -or
        @($entryById["PRD:AC-FR-001-02"].behaviorIds) -notcontains "PB-006" -or
        @($entryById["PRD:AC-FR-008-04"].behaviorIds) -notcontains "PB-009" -or
        @($entryById["PRD:AC-FR-020-04"].behaviorIds) -notcontains "PB-014" -or
        @($entryById["PRD:RISK-004"].behaviorIds) -notcontains "PB-014" -or
        @($entryById["PRD:RISK-005"].behaviorIds) -notcontains "PB-012" -or
        @($entryById["PRD:RISK-010"].behaviorIds).Count -ne 18 -or
        @($entryById["CURRENT:NFR-002"].behaviorIds) -notcontains "PB-004" -or
        @($entryById["CURRENT:NFR-003"].behaviorIds | Where-Object { $_ -in @("PB-001", "PB-011", "PB-017", "PB-018") }).Count -ne 4) {
        Add-ValidationFailure $failures "TRACE-SEMANTIC-PB" "Known memory/hybrid risks have incorrect PB mappings."
    }
    if (@($entryById["PRD:RISK-004"].lanes) -notcontains "V-SECURITY" -or
        @($entryById["PRD:RISK-006"].lanes) -notcontains "V-PERF") {
        Add-ValidationFailure $failures "TRACE-SEMANTIC-RISK-LANE" "Known memory/model risks lost their security or performance lane."
    }
    $pb12AllowedMeta = @("PRD:GATE-0-02", "PRD:RISK-005", "PRD:RISK-010")
    foreach ($entry in @($Traceability.entries | Where-Object { $_.namespace -eq "PRD" -and $_.behaviorIds -contains "PB-012" })) {
        $lines = @(Get-Content -Encoding UTF8 -LiteralPath $entry.sourcePath)
        $text = $lines[([int]$entry.sourceLine - 1)..([int]$entry.sourceEndLine - 1)] -join "`n"
        if ($entry.id -notlike "PRD:NFR-JA-005*" -and $pb12AllowedMeta -notcontains $entry.id -and
            $text -notmatch '(?i)\bsidecar\b|\bcross-runtime\b|\bREST\b|\bSSE\b|\bprotocol\b') {
            Add-ValidationFailure $failures "TRACE-FALSE-PB012" "Requirement '$($entry.id)' has a false protocol-boundary inference."
        }
    }
    if (@($entryById["CURRENT:FR-PET-013"].uiSections) -notcontains
        "docs/ui-spec/jarvis_assistant_ui_spec.md#21-gate-0-ui-preservation-contract") {
        Add-ValidationFailure $failures "TRACE-SEMANTIC-UI" "Current Settings is not mapped to its UI preservation contract."
    }
    foreach ($processMemoryId in @("CURRENT:NFR-003", "PRD:NFR-JA-001-07")) {
        $processMemoryEntry = $entryById[$processMemoryId]
        if (@($processMemoryEntry.behaviorIds | Where-Object { $_ -in @("PB-014", "PB-016") }).Count -gt 0 -or
            @($processMemoryEntry.behaviorIds | Where-Object { $_ -in @("PB-017", "PB-018") }).Count -ne 2 -or
            @($processMemoryEntry.designSections | Where-Object { $_ -like "*#18-canonical-memory-architecture" }).Count -gt 0 -or
            @($processMemoryEntry.uiSections | Where-Object { $_ -like "*#12-memory-center" }).Count -gt 0) {
            Add-ValidationFailure $failures "TRACE-PROCESS-MEMORY-INFERENCE" "Process-memory requirement '$processMemoryId' is incorrectly mapped to personal-memory behavior or UI."
        }
    }
    if (@($Traceability.entries | Where-Object { @($_.lanes).Count -gt 1 }).Count -lt 1 -or
        @($Traceability.entries | Where-Object { $_.lanes -contains "V-LEGACY" }).Count -lt 1) {
        Add-ValidationFailure $failures "TRACE-COLLAPSED-GRAPH" "The trace graph collapsed to single-lane or omitted legacy evidence."
    }

    $serialized = $Traceability | ConvertTo-Json -Depth 16
    if ($serialized -cmatch '"NFR-(?:JA-)?\d') {
        Add-ValidationFailure $failures "TRACE-BARE-NFR" "Bare NFR reference found."
    }
    return $failures.ToArray()
}

function Copy-JsonObject {
    param([object]$Value)
    return ($Value | ConvertTo-Json -Depth 20) | ConvertFrom-Json
}

function Invoke-FixtureMutation {
    param([object]$Traceability, [object]$Fixture)
    switch ($Fixture.mutation) {
        "remove-entry" { $Traceability.entries = @($Traceability.entries | Where-Object { $_.id -ne $Fixture.target }) }
        "duplicate-entry" {
            $target = @($Traceability.entries | Where-Object { $_.id -eq $Fixture.target })[0]
            $Traceability.entries = @($Traceability.entries) + @(Copy-JsonObject $target)
        }
        "replace-source-hash" { @($Traceability.sources | Where-Object { $_.id -eq $Fixture.target })[0].sha256 = "0" * 64 }
        "replace-entry-hash" { @($Traceability.entries | Where-Object { $_.id -eq $Fixture.target })[0].sourceTextSha256 = "0" * 64 }
        "replace-disposition" { @($Traceability.entries | Where-Object { $_.id -eq $Fixture.target })[0].disposition = $Fixture.value }
        "append-test" {
            $Traceability.testCatalog = @($Traceability.testCatalog) + @([PSCustomObject]@{
                    id = $Fixture.target; status = "planned"; ownerStep = "D0.3"; lane = "V-STATIC"
                    requirementIds = @("PRD:RISK-014"); behaviorIds = @("PB-017")
                    tddMode = "red-first-unless-characterization"
                    commandStatus = "freeze-in-step-manifest-before-red"
                    oracleStatus = "freeze-in-step-manifest-before-red"
                    environmentStatus = "freeze-in-step-manifest-before-red"
                })
        }
        "append-entry" {
            $template = Copy-JsonObject $Traceability.entries[0]
            $template.id = $Fixture.target
            $template.namespace = "PRD"
            $template.disposition = "target"
            $template.proposedDisposition = "target"
            $template.currentStatus = $null
            $template.mapId = $null
            $template.approvalId = $null
            $template.approvalStatus = "not-required"
            $template.baselineTreatment = "not-applicable"
            $template.testIds = @("D0.3-V-STATIC-PRD-AC-FR-999-99")
            $Traceability.entries = @($Traceability.entries) + @($template)
            $Traceability.testCatalog = @($Traceability.testCatalog) + @([PSCustomObject]@{
                    id = "D0.3-V-STATIC-PRD-AC-FR-999-99"; status = "planned"; ownerStep = "D0.3"; lane = "V-STATIC"
                    requirementIds = @($Fixture.target); behaviorIds = @("PB-017")
                    tddMode = "red-first-unless-characterization"
                    commandStatus = "freeze-in-step-manifest-before-red"
                    oracleStatus = "freeze-in-step-manifest-before-red"
                    environmentStatus = "freeze-in-step-manifest-before-red"
                })
        }
        "replace-id" { @($Traceability.entries | Where-Object { $_.id -eq $Fixture.target })[0].id = $Fixture.value }
        default { throw "Unknown fixture mutation '$($Fixture.mutation)'." }
    }
}

function Test-InstanceAgainstSchema {
    param([string]$SchemaPath, [string]$InstancePath)
    $testJson = Get-Command Test-Json -ErrorAction SilentlyContinue
    if ($null -ne $testJson) {
        try { return [bool](Test-Json -LiteralPath $InstancePath -SchemaFile $SchemaPath -ErrorAction Stop) }
        catch { return $false }
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $python) {
        throw "Draft 2020-12 validation requires PowerShell 7.4+ Test-Json or Python with jsonschema."
    }
    $output = & $python.Source $schemaFallbackPath $SchemaPath $InstancePath 2>&1
    $exitCode = $LASTEXITCODE
    $global:LASTEXITCODE = 0
    if ($exitCode -eq 0) { return $true }
    if ($exitCode -eq 2) { return $false }
    throw "Draft 2020-12 validator could not run: $($output | Out-String)"
}

function Test-RiskManifestLinks {
    param(
        [object]$Manifest,
        [AllowNull()][object]$Traceability
    )
    $riskIds = @($Manifest.risks | ForEach-Object { $_.id })
    $laneIds = @($Manifest.lanes | ForEach-Object { $_.id })
    $probeIds = @($Manifest.probes | ForEach-Object { $_.id })
    $environmentIds = @($Manifest.environments | ForEach-Object { $_.id })
    $fixtureIds = @($Manifest.fixtures | ForEach-Object { $_.id })
    foreach ($risk in @($Manifest.risks)) {
        foreach ($id in @($risk.laneIds)) { if ($laneIds -notcontains $id) { throw "Risk '$($risk.id)' references unknown lane '$id'." } }
        foreach ($id in @($risk.probeIds)) { if ($probeIds -notcontains $id) { throw "Risk '$($risk.id)' references unknown probe '$id'." } }
        foreach ($id in @($risk.laneIds)) {
            $lane = @($Manifest.lanes | Where-Object { $_.id -eq $id })[0]
            if (@($lane.riskIds) -notcontains $risk.id) { throw "Risk '$($risk.id)' has no reciprocal lane link from '$id'." }
        }
        foreach ($id in @($risk.probeIds)) {
            $probe = @($Manifest.probes | Where-Object { $_.id -eq $id })[0]
            if (@($probe.riskIds) -notcontains $risk.id) { throw "Risk '$($risk.id)' has no reciprocal probe link from '$id'." }
        }
    }
    foreach ($lane in @($Manifest.lanes)) {
        foreach ($id in @($lane.riskIds)) {
            if ($riskIds -notcontains $id) { throw "Lane '$($lane.id)' references unknown risk '$id'." }
            $risk = @($Manifest.risks | Where-Object { $_.id -eq $id })[0]
            if (@($risk.laneIds) -notcontains $lane.id) { throw "Lane '$($lane.id)' has no reciprocal risk link from '$id'." }
        }
        foreach ($id in @($lane.probeIds)) {
            if ($probeIds -notcontains $id) { throw "Lane '$($lane.id)' references unknown probe '$id'." }
            $probe = @($Manifest.probes | Where-Object { $_.id -eq $id })[0]
            if (@($probe.laneIds) -notcontains $lane.id) { throw "Lane '$($lane.id)' has no reciprocal probe link from '$id'." }
        }
        foreach ($id in @($lane.environmentIds)) { if ($environmentIds -notcontains $id) { throw "Lane '$($lane.id)' references unknown environment '$id'." } }
    }
    foreach ($probe in @($Manifest.probes)) {
        foreach ($id in @($probe.riskIds)) {
            if ($riskIds -notcontains $id) { throw "Probe '$($probe.id)' references unknown risk '$id'." }
            $risk = @($Manifest.risks | Where-Object { $_.id -eq $id })[0]
            if (@($risk.probeIds) -notcontains $probe.id) { throw "Probe '$($probe.id)' has no reciprocal risk link from '$id'." }
        }
        foreach ($id in @($probe.laneIds)) {
            if ($laneIds -notcontains $id) { throw "Probe '$($probe.id)' references unknown lane '$id'." }
            $lane = @($Manifest.lanes | Where-Object { $_.id -eq $id })[0]
            if (@($lane.probeIds) -notcontains $probe.id) { throw "Probe '$($probe.id)' has no reciprocal lane link from '$id'." }
        }
        foreach ($id in @($probe.environmentIds)) { if ($environmentIds -notcontains $id) { throw "Probe '$($probe.id)' references unknown environment '$id'." } }
        foreach ($id in @($probe.fixtureIds)) { if ($fixtureIds -notcontains $id) { throw "Probe '$($probe.id)' references unknown fixture '$id'." } }
        if ([int]$probe.minimumDiscovery -ne [int]$Manifest.thresholds.minimumDiscovery) {
            throw "Probe '$($probe.id)' and manifest minimum-discovery thresholds differ."
        }
        foreach ($property in @($probe.thresholds.PSObject.Properties)) {
            if ($Manifest.thresholds.PSObject.Properties.Name -contains $property.Name -and
                (($property.Value | ConvertTo-Json -Compress) -cne
                 ($Manifest.thresholds.PSObject.Properties[$property.Name].Value | ConvertTo-Json -Compress))) {
                throw "Probe '$($probe.id)' threshold '$($property.Name)' contradicts the manifest."
            }
        }
        foreach ($id in @($probe.requirementIds)) {
            if (@($Manifest.requirementIds) -notcontains $id) { throw "Probe '$($probe.id)' requirement '$id' is outside manifest scope." }
        }
    }
    if ($null -ne $Traceability) {
        $traceRequirementIds = @($Traceability.entries | ForEach-Object { $_.id })
        $traceDispositionIds = @($Traceability.dispositionMaps | ForEach-Object { $_.id }) +
            @($Traceability.dispositionMaps | ForEach-Object { $_.approvalIds }) +
            @($Traceability.entries | Where-Object { $_.namespace -eq "CURRENT" } | ForEach-Object { $_.mapId })
        foreach ($id in @($Manifest.requirementIds)) {
            if ($traceRequirementIds -notcontains $id) { throw "Manifest references unknown requirement '$id'." }
        }
        foreach ($id in @($Manifest.dispositionIds)) {
            if ($traceDispositionIds -notcontains $id) { throw "Manifest references unknown disposition map '$id'." }
        }
        foreach ($id in @($Manifest.boundaryIds)) {
            if ($allowedBehaviorIds -notcontains $id) { throw "Manifest references unknown preservation boundary '$id'." }
        }
        foreach ($probe in @($Manifest.probes)) {
            foreach ($id in @($probe.requirementIds)) {
                if ($traceRequirementIds -notcontains $id) { throw "Probe '$($probe.id)' references unknown requirement '$id'." }
            }
        }
        if ($Manifest.manifestId -eq "D0.3-v5") {
            $catalogIds = @($Traceability.testCatalog | Where-Object { $_.ownerStep -eq "D0.3" } | ForEach-Object { $_.id } | Sort-Object)
            $manifestProbeIds = @($Manifest.probes | ForEach-Object { $_.id } | Sort-Object)
            if (($catalogIds -join '|') -ne ($manifestProbeIds -join '|')) {
                throw "D0.3 trace catalog and frozen probe IDs differ."
            }
            $catalogProbe = @($Traceability.testCatalog | Where-Object { $_.id -eq "D0.3-V-STATIC-001" })[0]
            $manifestProbe = @($Manifest.probes | Where-Object { $_.id -eq "D0.3-V-STATIC-001" })[0]
            $catalogRequirements = @($catalogProbe.requirementIds | Sort-Object)
            $manifestRequirements = @($Manifest.requirementIds | Sort-Object)
            $probeRequirements = @($manifestProbe.requirementIds | Sort-Object)
            if (($catalogRequirements -join '|') -ne ($manifestRequirements -join '|') -or
                ($catalogRequirements -join '|') -ne ($probeRequirements -join '|')) {
                throw "D0.3 catalog, manifest, and probe requirement scopes differ."
            }
            if ((@($catalogProbe.behaviorIds | Sort-Object) -join '|') -ne (@($Manifest.boundaryIds | Sort-Object) -join '|')) {
                throw "D0.3 catalog and manifest preservation-boundary scopes differ."
            }
            if ([int]$Manifest.thresholds.normativeNodes -ne @($Traceability.entries).Count -or
                @($Traceability.testCatalog).Count -lt [int]$Manifest.thresholds.minimumCatalogItems -or
                [int]$Manifest.thresholds.requiredKnownBadFixtures -ne @($Manifest.fixtures).Count -or
                [int]$Manifest.thresholds.requiredKnownBadFixtures -ne $requiredFixtureMutations.Count) {
                throw "D0.3 frozen numeric thresholds do not match measured collections."
            }
            $p9FixtureCount = @($Traceability.testCatalog | Where-Object { $_.ownerStep -match '^P9\.[123]' -and $_.lane -eq "V-FIXTURE-E2E" }).Count
            $p0a2RealCount = @($Traceability.testCatalog | Where-Object { $_.ownerStep -eq "P0A.2" -and $_.lane -eq "V-REAL-E2E" }).Count
            $mcpRealCount = @($Traceability.testCatalog | Where-Object { $_.ownerStep -eq "P10.3" -and $_.lane -eq "V-REAL-E2E" }).Count
            $gate0FixtureCount = @($Traceability.testCatalog | Where-Object { $_.ownerStep -match '^P0A\.' -and $_.lane -eq "V-FIXTURE-E2E" }).Count
            $gate0RealCount = @($Traceability.testCatalog | Where-Object { $_.ownerStep -match '^P0A\.' -and $_.lane -eq "V-REAL-E2E" }).Count
            if ($p9FixtureCount -ne [int]$Manifest.thresholds.requiredP9FixtureJourneys -or
                $p0a2RealCount -ne [int]$Manifest.thresholds.requiredP0A2RealJourneys -or
                $mcpRealCount -ne [int]$Manifest.thresholds.requiredMcpRealJourneys -or
                $gate0FixtureCount -ne [int]$Manifest.thresholds.requiredGate0FixtureJourneys -or
                $gate0RealCount -ne [int]$Manifest.thresholds.requiredGate0RealJourneys) {
                throw "D0.3 frozen journey thresholds do not match the catalog."
            }
        }
    }
}

function Test-PhaseEvidenceSemantics {
    param([object]$Manifest)

    $started = [DateTimeOffset]::Parse([string]$Manifest.startedAt)
    $completed = [DateTimeOffset]::Parse([string]$Manifest.completedAt)
    $reviewed = [DateTimeOffset]::Parse([string]$Manifest.review.timestamp)
    if ($completed -lt $started -or $reviewed -lt $completed) { throw "Evidence timestamps are not monotonic." }
    if ([int]$Manifest.actualExit -ne [int]$Manifest.expectedExit) { throw "Evidence actual exit does not match its frozen expected exit." }
    $discovery = $Manifest.discovery
    if ([int]$discovery.actual -lt [int]$discovery.minimum -or [int]$discovery.executed -lt 1 -or
        [int]$discovery.executed -ne ([int]$discovery.passed + [int]$discovery.failed + [int]$discovery.skipped)) {
        throw "Evidence discovery/execution counts are contradictory."
    }
    if ([int]$discovery.skipped -gt [int]$Manifest.thresholds.maximumUnexpectedSkips) {
        throw "Evidence exceeds its frozen unexpected-skip threshold."
    }
    if ($Manifest.result -eq "pass") {
        if ($Manifest.review.decision -ne "approved") { throw "Passing evidence lacks an approved review decision." }
        if ($Manifest.phase -eq "RED") {
            if ([int]$Manifest.expectedExit -eq 0 -or [int]$discovery.failed -lt 1 -or
                $Manifest.thresholds.failedAtIntendedOracle -ne $true) {
                throw "Passing RED evidence did not reach a frozen nonzero intended oracle."
            }
        } elseif ([int]$Manifest.expectedExit -ne 0 -or [int]$discovery.failed -ne 0) {
            throw "Passing GREEN/REFACTOR/VERIFY evidence contains a failing result."
        }
    }
}

function Test-ExactShaSemantics {
    param([object]$Manifest)
    if ($Manifest.sourceSha -ne $Manifest.checkedOutSha -or $Manifest.sourceSha -ne $Manifest.workflow.ref) {
        throw "Exact-SHA example permits mismatched source, checkout, or workflow refs."
    }
    if ($Manifest.branch -ne $Manifest.filters.selectedRef -or
        $Manifest.workflow.event -ne $Manifest.filters.selectedEvent) {
        throw "Exact-SHA filters do not identify the selected branch and event."
    }
    foreach ($job in @($Manifest.jobs)) {
        if ([int]$job.expectedInstances -ne [int]$job.actualInstances -or
            (@($job.matrixExpected | ConvertTo-Json -Compress) -join '') -cne (@($job.matrixActual | ConvertTo-Json -Compress) -join '')) {
            throw "Exact-SHA example has a matrix/instance contradiction."
        }
    }
    foreach ($lane in @($Manifest.lanes)) {
        if ([int]$lane.actualDiscovery -lt [int]$lane.minimumDiscovery -or [int]$lane.failed -ne 0 -or [int]$lane.skipped -ne 0) {
            throw "Exact-SHA example has invalid lane discovery/results."
        }
    }
    $actualNames = @($Manifest.artifactsActual.name | Sort-Object)
    $expectedNames = @($Manifest.artifactsExpected | Sort-Object)
    if (($actualNames -join '|') -ne ($expectedNames -join '|')) { throw "Exact-SHA example has artifact mismatch." }
    if ($Manifest.legacyRegression.required -eq $true) {
        if ($Manifest.legacyRegression.result -ne "success" -or [string]::IsNullOrWhiteSpace([string]$Manifest.evidence.legacy)) {
            throw "Required legacy regression is not successful and separately evidenced."
        }
    } elseif ($Manifest.legacyRegression.result -ne "not-applicable") {
        throw "Optional legacy regression has a contradictory result."
    }
}

function Assert-SemanticRejection {
    param([string]$Label, [scriptblock]$Action)
    $rejected = $false
    try { & $Action } catch { $rejected = $true }
    if (-not $rejected) { throw "Semantic negative control was accepted: $Label" }
    $script:semanticNegativeControlsExecuted++
}

function Test-InvalidationSemantics {
    param(
        [object]$Record,
        [string]$InvalidatedManifestId,
        [string]$FrozenHash,
        [string]$ReplacementManifestId,
        [string]$FrozenPath,
        [DateTimeOffset]$ReplacementFrozenAt = [DateTimeOffset]::MaxValue
    )

    $replacementRevision = $ReplacementManifestId -replace '^D0\.3-', ''
    $expectedRecordId = "$InvalidatedManifestId-invalidated-by-$replacementRevision"
    $parsedTimestamp = [DateTimeOffset]::MinValue
    if ($Record.recordId -cne $expectedRecordId -or
        $Record.invalidatedManifestId -cne $InvalidatedManifestId -or
        $Record.frozenArtifactSha256 -cne $FrozenHash -or
        $Record.replacementManifestId -cne $ReplacementManifestId -or
        $Record.frozenArtifactPath -cne $FrozenPath -or
        -not [DateTimeOffset]::TryParse([string]$Record.invalidatedAt, [ref]$parsedTimestamp) -or
        $parsedTimestamp -gt $ReplacementFrozenAt -or
        (Get-NormalizedTextHash $FrozenPath "normalized-text") -cne $FrozenHash) {
        throw "Invalidation record does not bind its identity, time, or immutable artifact."
    }
}

$requiredInputPaths = @(
    $TraceabilityPath, $generatorPath, $schemaFallbackPath,
    $manifestV1Path, $manifestV2Path, $manifestV3Path, $manifestV4Path, $manifestV5Path,
    $manifestV1InvalidationPath, $manifestV2InvalidationPath, $manifestV3InvalidationPath,
    $manifestV4InvalidationPath, $manifestV5RedEvidencePath
) + $requiredSchemaPaths
$requiredInputPaths += $invalidationSchemaPath
foreach ($pair in $schemaInstancePairs) { $requiredInputPaths += $pair[1] }
foreach ($mutation in $requiredFixtureMutations) { $requiredInputPaths += (Join-Path $FixtureDirectory "$mutation.json") }
$missingFiles = @($requiredInputPaths | Where-Object { -not (Test-Path -LiteralPath $_ -PathType Leaf) })
if ($missingFiles.Count -gt 0) { throw "Verification contract inputs are missing: $($missingFiles -join ', ')." }

$activeManifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV5Path | ConvertFrom-Json
$requiredChecks = Get-Content -Raw -Encoding UTF8 -LiteralPath ".github/ci/required-checks.json" | ConvertFrom-Json
$verificationJobs = @($requiredChecks.jobs | Where-Object { $_.id -eq "verification-contracts" })
$manifestMinimum = [int]$activeManifest.thresholds.minimumDiscovery
if ($verificationJobs.Count -ne 1 -or $verificationJobs[0].discovery.kind -ne "powershell-probe" -or
    [int]$verificationJobs[0].discovery.minimumDiscoveredTests -ne $manifestMinimum) {
    throw "D0.3 manifest and required CI discovery thresholds do not match."
}
$ciEvidence = @($verificationJobs[0].evidenceFiles.path | Sort-Object)
$manifestEvidence = @($activeManifest.expectedArtifacts | Sort-Object)
if (($ciEvidence -join '|') -ne ($manifestEvidence -join '|')) { throw "D0.3 manifest and CI evidence artifacts do not match." }
$workflow = Get-Content -Raw -Encoding UTF8 -LiteralPath ".github/workflows/ci.yml"
if ($workflow -notmatch 'tools/verification/Test-VerificationContracts\.ps1') { throw "Required CI does not execute D0.3 verification." }
$activeProbe = @($activeManifest.probes | Where-Object { $_.id -eq "D0.3-V-STATIC-001" })[0]
$ghaEnvironment = @($activeManifest.environments | Where-Object { $_.id -eq "ENV-GHA-UBUNTU" })[0]
$verificationWorkflowBlock = [regex]::Match($workflow, '(?ms)^  verification-contracts:\s*(.+?)\z').Value
$ciProbePath = ([string]$verificationJobs[0].discovery.command).TrimStart('.', '/')
if ([string]::IsNullOrWhiteSpace($verificationWorkflowBlock) -or
    $activeProbe.command -notlike "*$ciProbePath" -or
    $verificationWorkflowBlock -notmatch [regex]::Escape([string]$verificationJobs[0].discovery.command) -or
    [string]$verificationJobs[0].runner -cne [string]$ghaEnvironment.os -or
    [int]$requiredChecks.minimumRetentionDays -ne [int]$activeManifest.thresholds.artifactRetentionDays -or
    $verificationWorkflowBlock -notmatch "retention-days:\s*$([int]$activeManifest.thresholds.artifactRetentionDays)\b") {
    throw "D0.3 active probe command, CI environment, or artifact retention is not aligned."
}

if (-not (Test-InstanceAgainstSchema $requiredSchemaPaths[0] $TraceabilityPath)) { throw "Traceability fails its Draft 2020-12 schema." }
Write-ProbePass "Draft 2020-12 traceability schema"
$traceability = Get-Content -Raw -Encoding UTF8 -LiteralPath $TraceabilityPath | ConvertFrom-Json
$baselineFailures = @(Test-TraceabilityObject $traceability)
if ($baselineFailures.Count -gt 0) {
    throw ("Traceability validation failed:`n - " + (($baselineFailures | ForEach-Object { "$($_.code): $($_.message)" }) -join "`n - "))
}
Write-ProbePass "semantic traceability baseline ($(@($traceability.entries).Count) requirements, $(@($traceability.testCatalog).Count) stable planned tests/probes)"

$temporaryTraceability = Join-Path ([IO.Path]::GetTempPath()) ("aemeath-traceability-" + [guid]::NewGuid().ToString("N") + ".json")
try {
    $enginePath = (Get-Process -Id $PID).Path
    $output = & $enginePath -NoProfile -ExecutionPolicy Bypass -File $generatorPath -OutputPath $temporaryTraceability 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Traceability generator failed: $($output | Out-String)" }
    $committed = [Convert]::ToBase64String([IO.File]::ReadAllBytes([IO.Path]::GetFullPath($TraceabilityPath)))
    $generated = [Convert]::ToBase64String([IO.File]::ReadAllBytes($temporaryTraceability))
    if ($committed -cne $generated) { throw "Committed traceability differs from canonical generator output." }
    Write-ProbePass "canonical traceability regeneration in the current engine"
} finally {
    if (Test-Path -LiteralPath $temporaryTraceability -PathType Leaf) { Remove-Item -LiteralPath $temporaryTraceability -Force }
}

foreach ($mutation in $requiredFixtureMutations) {
    $fixture = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $FixtureDirectory "$mutation.json") | ConvertFrom-Json
    $mutated = Copy-JsonObject $traceability
    Invoke-FixtureMutation $mutated $fixture
    $failures = @(Test-TraceabilityObject $mutated)
    if (@($failures.code) -notcontains $fixture.expectedCode) {
        throw "Known-bad fixture '$mutation' did not produce '$($fixture.expectedCode)'; got '$(@($failures.code) -join ', ')'."
    }
    Write-ProbePass "known-bad fixture: $mutation -> $($fixture.expectedCode)"
}

foreach ($pair in $schemaInstancePairs) {
    if (-not (Test-InstanceAgainstSchema $pair[0] $pair[1])) { throw "Valid example fails schema: $($pair[1])" }
    $instance = Get-Content -Raw -Encoding UTF8 -LiteralPath $pair[1] | ConvertFrom-Json
    if ($instance.manifestType -eq "risk-lane") { Test-RiskManifestLinks $instance $traceability }
    if ($instance.manifestType -eq "phase-evidence") { Test-PhaseEvidenceSemantics $instance }
    if ($instance.manifestType -eq "exact-sha-gate") { Test-ExactShaSemantics $instance }
    Write-ProbePass "schema-valid example with cross-field semantics: $($pair[1])"
}

$riskNegative = Copy-JsonObject (Get-Content -Raw -Encoding UTF8 -LiteralPath $schemaInstancePairs[0][1] | ConvertFrom-Json)
$riskNegative.lanes[0].riskIds = @()
Assert-SemanticRejection "one-sided risk/lane relationship" { Test-RiskManifestLinks $riskNegative $traceability }
Write-ProbePass "semantic negative risk/lane relationship"

$evidenceNegative = Copy-JsonObject (Get-Content -Raw -Encoding UTF8 -LiteralPath $schemaInstancePairs[1][1] | ConvertFrom-Json)
$evidenceNegative.actualExit = 99
$evidenceNegative.completedAt = "2026-07-21T23:59:00Z"
$evidenceNegative.discovery.executed = 0
Assert-SemanticRejection "contradictory phase evidence" { Test-PhaseEvidenceSemantics $evidenceNegative }
Write-ProbePass "semantic negative phase-evidence contradictions"

$exactShaNegative = Copy-JsonObject (Get-Content -Raw -Encoding UTF8 -LiteralPath $schemaInstancePairs[2][1] | ConvertFrom-Json)
$exactShaNegative.filters.selectedEvent = "workflow_dispatch"
$exactShaNegative.legacyRegression.required = $true
Assert-SemanticRejection "filter and legacy exact-SHA contradictions" { Test-ExactShaSemantics $exactShaNegative }
Write-ProbePass "semantic negative exact-SHA contradictions"

$riskSchema = $requiredSchemaPaths[1]
foreach ($path in @($manifestV2Path, $manifestV3Path, $manifestV4Path, $manifestV5Path)) {
    if (-not (Test-InstanceAgainstSchema $riskSchema $path)) { throw "D0.3 manifest fails schema: $path" }
    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json
    Test-RiskManifestLinks $manifest $traceability
    foreach ($fixture in @($manifest.fixtures)) {
        if (-not (Test-Path -LiteralPath $fixture.path -PathType Leaf) -or
            (Get-NormalizedTextHash $fixture.path "normalized-text") -ne $fixture.sha256) {
            throw "Manifest '$($manifest.manifestId)' has stale fixture '$($fixture.id)'."
        }
    }
    Write-ProbePass "schema-valid linked manifest: $($manifest.manifestId) ($($manifest.status))"
}
$historicalV1 = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV1Path | ConvertFrom-Json
$frozenV1Hash = "e7b0e5a89a1e5f6d89be11b5a8eefb06ec0d4b09011bec5eecf068f10714df7d"
$frozenV2Hash = "09e73b9d7f9345d4c362555401298d24ce3b6021194f37f26e5e101c18e29579"
$frozenV3Hash = "aa04d55e8127ef48e0ef1699c41e07d73a0ef5e5d3a3e10d28b879022c21a15c"
$frozenV4Hash = "686633384964721365efb45d564dc1093ad1d7a13a5ac77c4c1a4a4ebf334c2e"
$frozenV5Hash = "6434bee4fdacd897863a2bc5dabe83affe6b862b91cecda7fdd8e3f178f5f61e"
$manifestV2 = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV2Path | ConvertFrom-Json
$manifestV3 = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV3Path | ConvertFrom-Json
$manifestV4 = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV4Path | ConvertFrom-Json
$v5FrozenAtForChronology = [DateTimeOffset]::Parse("2026-07-22T11:29:39Z")
$invalidationRecords = @(
    @($manifestV1InvalidationPath, "D0.3-v1", $frozenV1Hash, "D0.3-v2", $manifestV1Path),
    @($manifestV2InvalidationPath, "D0.3-v2", $frozenV2Hash, "D0.3-v3", $manifestV2Path),
    @($manifestV3InvalidationPath, "D0.3-v3", $frozenV3Hash, "D0.3-v4", $manifestV3Path),
    @($manifestV4InvalidationPath, "D0.3-v4", $frozenV4Hash, "D0.3-v5", $manifestV4Path)
)
$previousInvalidationAt = [DateTimeOffset]::MinValue
foreach ($recordSpec in $invalidationRecords) {
    $recordPath = $recordSpec[0]
    if (-not (Test-InstanceAgainstSchema $invalidationSchemaPath $recordPath)) { throw "Invalidation record fails schema: $recordPath" }
    $record = Get-Content -Raw -Encoding UTF8 -LiteralPath $recordPath | ConvertFrom-Json
    $replacementFrozenAt = if ($recordSpec[3] -eq "D0.3-v5") {
        $v5FrozenAtForChronology
    } else {
        [DateTimeOffset]::MaxValue
    }
    Test-InvalidationSemantics $record $recordSpec[1] $recordSpec[2] $recordSpec[3] $recordSpec[4] $replacementFrozenAt
    $currentInvalidatedAt = [DateTimeOffset]::Parse([string]$record.invalidatedAt)
    if ($currentInvalidatedAt -le $previousInvalidationAt) {
        throw "D0.3 invalidation timestamps are not strictly monotonic: $recordPath"
    }
    $previousInvalidationAt = $currentInvalidatedAt
}
$invalidationNegative = Copy-JsonObject (Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV4InvalidationPath | ConvertFrom-Json)
$invalidationNegative.recordId = "D0.3-v4-invalidated-by-v99"
Assert-SemanticRejection "invalidation identity contradiction" {
    Test-InvalidationSemantics $invalidationNegative "D0.3-v4" $frozenV4Hash "D0.3-v5" $manifestV4Path
}
$invalidationChronologyNegative = Copy-JsonObject (Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV4InvalidationPath | ConvertFrom-Json)
$invalidationChronologyNegative.invalidatedAt = "2099-01-01T00:00:00Z"
$chronologyRejected = $false
try {
    Test-InvalidationSemantics $invalidationChronologyNegative "D0.3-v4" $frozenV4Hash "D0.3-v5" $manifestV4Path $v5FrozenAtForChronology
} catch {
    $chronologyRejected = $true
}
if (-not $chronologyRejected) {
    throw "Schema-valid invalidation chronology beyond the replacement freeze was accepted."
}
Write-ProbePass "semantic negative invalidation identity and chronology"
if ($historicalV1.manifestId -ne "D0.3-v1" -or $historicalV1.status -ne "frozen-before-red" -or
    @($historicalV1.risks).Count -ne 5 -or $manifestV2.previousManifestId -ne "D0.3-v1" -or
    $manifestV3.previousManifestId -ne "D0.3-v2" -or $manifestV4.previousManifestId -ne "D0.3-v3" -or
    $activeManifest.previousManifestId -ne "D0.3-v4" -or $activeManifest.status -ne "frozen-before-red" -or
    (Get-NormalizedTextHash $manifestV5Path "normalized-text") -cne $frozenV5Hash) {
    throw "D0.3 manifest invalidation chain is incomplete."
}
Write-ProbePass "immutable v1-v5 payload and invalidation chain"

$v5RedEvidence = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV5RedEvidencePath
$frozenAtMatch = [regex]::Match($v5RedEvidence, '(?m)^- Frozen at: `([^`]+)`$')
$redCompletedMatch = [regex]::Match($v5RedEvidence, '(?m)^- RED completed at: `([^`]+)`$')
$frozenAt = [DateTimeOffset]::MinValue
$redCompletedAt = [DateTimeOffset]::MinValue
if ($v5RedEvidence -notmatch '(?m)^- Frozen manifest: `D0\.3-v5`$' -or
    $v5RedEvidence -notmatch '(?m)^- Frozen manifest path: `docs/verification/manifests/D0\.3-v5\.yml`$' -or
    $v5RedEvidence -notmatch "(?m)^- Frozen manifest SHA-256: ``$frozenV5Hash``$" -or
    -not $frozenAtMatch.Success -or -not $redCompletedMatch.Success -or
    -not [DateTimeOffset]::TryParse($frozenAtMatch.Groups[1].Value, [ref]$frozenAt) -or
    -not [DateTimeOffset]::TryParse($redCompletedMatch.Groups[1].Value, [ref]$redCompletedAt) -or
    $frozenAt -gt $redCompletedAt -or
    $v5RedEvidence -notmatch '(?m)^- Exit code: `1` \(expected RED\)$') {
    throw "D0.3-v5 RED evidence does not bind the exact frozen manifest bytes and chronology."
}
Write-ProbePass "v5 frozen-before-red provenance"

$negativePairs = @(
    @($requiredSchemaPaths[0], $TraceabilityPath),
    @($requiredSchemaPaths[1], $schemaInstancePairs[0][1]),
    @($requiredSchemaPaths[2], $schemaInstancePairs[1][1]),
    @($requiredSchemaPaths[3], $schemaInstancePairs[2][1])
)
foreach ($pair in $negativePairs) {
    $invalidPath = Join-Path ([IO.Path]::GetTempPath()) ("aemeath-schema-negative-" + [guid]::NewGuid().ToString("N") + ".json")
    try {
        $invalid = Get-Content -Raw -Encoding UTF8 -LiteralPath $pair[1] | ConvertFrom-Json
        $invalid.PSObject.Properties.Remove("manifestType")
        if ($pair[0] -eq $requiredSchemaPaths[0]) { $invalid.PSObject.Properties.Remove("documentType") }
        $invalid | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -LiteralPath $invalidPath
        if (Test-InstanceAgainstSchema $pair[0] $invalidPath) { throw "Schema accepted missing required identity: $($pair[0])" }
        $script:schemaNegativeControlsExecuted++
    } finally {
        if (Test-Path -LiteralPath $invalidPath -PathType Leaf) { Remove-Item -LiteralPath $invalidPath -Force }
    }
}
$invalidTimestampPath = Join-Path ([IO.Path]::GetTempPath()) ("aemeath-invalidation-negative-" + [guid]::NewGuid().ToString("N") + ".json")
try {
    $invalidTimestamp = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestV4InvalidationPath | ConvertFrom-Json
    $invalidTimestamp.invalidatedAt = "not-a-date-time"
    $invalidTimestamp | ConvertTo-Json -Depth 20 | Set-Content -Encoding UTF8 -LiteralPath $invalidTimestampPath
    if (Test-InstanceAgainstSchema $invalidationSchemaPath $invalidTimestampPath) {
        throw "Invalidation schema accepted an invalid invalidatedAt value."
    }
    $script:schemaNegativeControlsExecuted++
} finally {
    if (Test-Path -LiteralPath $invalidTimestampPath -PathType Leaf) { Remove-Item -LiteralPath $invalidTimestampPath -Force }
}
Write-ProbePass "$schemaNegativeControlsExecuted schema-negative controls"

if ($schemaNegativeControlsExecuted -ne [int]$activeManifest.thresholds.requiredSchemaNegativeControls -or
    $semanticNegativeControlsExecuted -ne [int]$activeManifest.thresholds.requiredSemanticNegativeControls -or
    $unexpectedSkips -gt [int]$activeManifest.thresholds.maximumUnexpectedSkips) {
    throw "D0.3 measured negative-control or skip counts differ from frozen thresholds."
}

if ($discoveredProbes -lt $manifestMinimum) {
    throw "D0.3 discovered $discoveredProbes semantic probes; frozen minimum is $manifestMinimum."
}
Write-Host "Verification contract tests passed ($discoveredProbes semantic probes; minimum $manifestMinimum)."

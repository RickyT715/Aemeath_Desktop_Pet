[CmdletBinding()]
param(
    [string]$OutputPath = "docs/verification/traceability-v1.yml"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$requirementsPath = "REQUIREMENTS.md"
$prdPath = "docs/prd/jarvis_assistant_prd.md"
$designPath = "docs/design/jarvis_assistant_design.md"
$uiPath = "docs/ui-spec/jarvis_assistant_ui_spec.md"
$checklistPath = "docs/plans/20260722-jarvis-assistant-tdd-checklist.md"
$adr2Path = "docs/adr/ADR-0002-test-driven-verification-and-exact-sha-delivery.md"
$baselineSha = "a6c15496cf2893a24e560c01ef4e598a635859cc"
$currentRequirementsOriginSha = "c2e3dbfd5e90bb40ea5006b702bbbc32d24a1ae7"
$allowedLanes = @(
    "V-UNIT", "V-COMPONENT", "V-CONTRACT", "V-WPF", "V-UIA", "V-FIXTURE-E2E",
    "V-REAL-E2E", "V-SECURITY", "V-ACCESS", "V-PERF", "V-PACKAGE", "V-STATIC",
    "V-MANUAL-WIN", "V-LEGACY"
)

function Get-NormalizedTextHash {
    param(
        [string]$Path,
        [string]$Mode
    )

    $content = (Get-Content -Raw -Encoding UTF8 -LiteralPath $Path).Replace("`r`n", "`n").Replace("`r", "`n")
    if ($Mode -eq "normalized-checkbox-text") {
        $content = [regex]::Replace($content, '(?m)^(-\s+\[)[xX](\])', '$1 $2')
    } elseif ($Mode -ne "normalized-text") {
        throw "Unsupported hash mode '$Mode'."
    }

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($content)
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
}

function Get-UniqueMatches {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$Prefix = ""
    )

    $values = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($match in [regex]::Matches($Text, $Pattern)) {
        $null = $values.Add("$Prefix$($match.Groups[1].Value)")
    }
    $result = [string[]]@($values)
    [Array]::Sort($result, [StringComparer]::Ordinal)
    return $result
}

function Get-OrdinalUniqueStrings {
    param([object[]]$Values)

    $set = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($value in $Values) { $null = $set.Add([string]$value) }
    $result = [string[]]@($set)
    [Array]::Sort($result, [StringComparer]::Ordinal)
    return $result
}

function ConvertTo-CanonicalJsonString {
    param([string]$Value)

    $builder = New-Object Text.StringBuilder
    $null = $builder.Append('"')
    foreach ($character in $Value.ToCharArray()) {
        $code = [int][char]$character
        switch ($code) {
            8 { $null = $builder.Append('\b'); continue }
            9 { $null = $builder.Append('\t'); continue }
            10 { $null = $builder.Append('\n'); continue }
            12 { $null = $builder.Append('\f'); continue }
            13 { $null = $builder.Append('\r'); continue }
            34 { $null = $builder.Append('\"'); continue }
            92 { $null = $builder.Append('\\'); continue }
        }
        if ($code -lt 32) {
            $null = $builder.Append(('\u{0:x4}' -f $code))
        } else {
            $null = $builder.Append($character)
        }
    }
    $null = $builder.Append('"')
    return $builder.ToString()
}

function ConvertTo-CanonicalJson {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return "null"
    }
    if ($Value -is [string] -or $Value -is [char]) {
        return ConvertTo-CanonicalJsonString ([string]$Value)
    }
    if ($Value -is [bool]) {
        return $(if ($Value) { "true" } else { "false" })
    }
    if ($Value -is [byte] -or $Value -is [sbyte] -or $Value -is [int16] -or
        $Value -is [uint16] -or $Value -is [int32] -or $Value -is [uint32] -or
        $Value -is [int64] -or $Value -is [uint64] -or $Value -is [single] -or
        $Value -is [double] -or $Value -is [decimal]) {
        return ([Convert]::ToString($Value, [Globalization.CultureInfo]::InvariantCulture))
    }
    if ($Value -is [Collections.IDictionary]) {
        $members = [System.Collections.Generic.List[string]]::new()
        foreach ($key in @(Get-OrdinalUniqueStrings @($Value.Keys))) {
            $members.Add("$(ConvertTo-CanonicalJsonString $key):$(ConvertTo-CanonicalJson $Value[$key])")
        }
        return "{$($members -join ',')}"
    }
    if ($Value -is [PSCustomObject]) {
        $members = [System.Collections.Generic.List[string]]::new()
        $propertyNames = Get-OrdinalUniqueStrings @($Value.PSObject.Properties | ForEach-Object { $_.Name })
        foreach ($propertyName in $propertyNames) {
            $propertyValue = $Value.PSObject.Properties[$propertyName].Value
            $members.Add("$(ConvertTo-CanonicalJsonString $propertyName):$(ConvertTo-CanonicalJson $propertyValue)")
        }
        return "{$($members -join ',')}"
    }
    if ($Value -is [Collections.IEnumerable]) {
        $items = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $Value) {
            $items.Add((ConvertTo-CanonicalJson $item))
        }
        return "[$($items -join ',')]"
    }

    throw "Unsupported canonical JSON value type '$($Value.GetType().FullName)'."
}

$stepAnchors = @{
    "D0.2" = "d02-bootstrap-exact-head-sha-ci-test-first"
    "D0.3" = "d03-establish-qualified-traceability-and-manifest-schemas"
    "D0.4" = "d04-provision-and-prove-required-delivery-environments"
    "D0.5" = "d05-freeze-clean-install-dependency-evidence-without-changing-production-manifests"
    "H0.1" = "h01-validate-selected-sources-action-routes-retention-and-hardware-tiers"
    "H0.3" = "h03-protocolreadiness-proof"
    "H0.5" = "h05-sidecar-distribution-bake-off-and-selection"
    "H0.6" = "h06-approvalprivacy-wireframe-study"
    "P0A.1" = "p0a1-freeze-preservation-specification-and-risk-map"
    "P0A.2" = "p0a2-prove-black-box-offline-launch-on-disposable-windows-workers"
    "P0A.3" = "p0a3-build-a-test-only-failure-detecting-preservation-harness"
    "P0A.4" = "p0a4-qualify-retained-domain-and-engine-behavior"
    "P0A.5" = "p0a5-qualify-retained-local-data-and-application-composition"
    "P0A.6" = "p0a6-qualify-retained-wpf-ui-and-current-accessibility-state"
    "P0A.7" = "p0a7-qualify-process-ui-automation-and-fixture-journeys"
    "P0A.8" = "p0a8-qualify-real-windows-boundaries-and-nonfunctional-baseline"
    "P0A.9" = "p0a9-lock-the-unchanged-baseline-independent-evidence"
    "P0B.3" = "p0b3-add-accessibility-and-automation-semantics-in-focused-child-steps"
    "P0B.4" = "p0b4-correct-preservation-discovered-product-and-security-defects"
    "P1.1" = "p11-create-target-projects-and-enforce-dependency-direction"
    "P1.2" = "p12-adopt-generic-host-and-owned-lifecycle"
    "P1.3" = "p13-add-schema-managed-sqlite-and-migration-journal"
    "P1.4" = "p14-protect-secrets-and-migrate-configuration"
    "P1.5" = "p15-expand-the-already-blocking-ci-matrix-for-foundation-lanes"
    "P2.1" = "p21-define-and-generate-the-protocol"
    "P2.2" = "p22-supervise-authenticated-sidecar-startup"
    "P2.3" = "p23-implement-resumable-run-lifecycle"
    "P2.5" = "p25-implement-and-qualify-the-phase-0-selected-sidecar-distribution"
    "P3.1" = "p31-implement-task-ledger-and-reducer"
    "P3.2" = "p32-implement-typed-capability-registry"
    "P3.3" = "p33-implement-policy-grants-and-revocation"
    "P3.4" = "p34-persist-approval-and-resume-safely"
    "P3.5" = "p35-implement-execution-adapters-idempotency-reconciliation-and-undo"
    "P3.6" = "p36-implement-receipts-and-privacy-safe-activity-history"
    "P4.1" = "p41-build-the-accessible-command-center-shell"
    "P4.2" = "p42-build-task-approval-receipt-and-undo-journeys"
    "P4.3" = "p43-create-one-authoritative-assistant-presentation-reducer"
    "P4.4" = "p44-build-diagnostics-and-safe-support-export"
    "P4.5" = "p45-complete-retained-pet-gaps-without-regression"
    "P5.1" = "p51-implement-reminder-domain-and-persistence"
    "P5.2" = "p52-implement-scheduler-and-windows-notifications"
    "P5.3" = "p53-implement-brief-sources-and-grounding"
    "P5.4" = "p54-build-today-journey-and-pet-cue"
    "P6.1" = "p61-implement-protected-context-lifecycle"
    "P6.2" = "p62-implement-windows-context-adapters"
    "P6.3" = "p63-implement-redaction-and-route-policy"
    "P6.4" = "p64-build-grounded-conversation-with-citations"
    "P7.1" = "p71-rehearse-inventory-and-migration"
    "P7.2" = "p72-implement-canonical-memory-schemaservice"
    "P7.3" = "p73-implement-proposalretrieval-protocol-and-invalidation"
    "P7.4" = "p74-build-memory-center"
    "P7.5" = "p75-cut-over-authority-and-retire-legacy-writes"
    "P8.1" = "p81-implement-versioned-scratch-note-adapter"
    "P8.2" = "p82-compose-deterministic-skill-and-constrained-planner"
    "P8.3" = "p83-complete-approval-receipt-and-undo-ux"
    "P8.4" = "p84-real-action-pilot-and-adversarial-gate"
    "P9.1" = "p91-implement-modular-push-to-talk-voice"
    "P9.2" = "p92-implement-selected-source-knowledge-retrieval"
    "P9.3" = "p93-implement-restrained-proactive-rules"
    "P10.1" = "p101-supervise-one-allowlisted-read-only-mcp-server"
    "P10.2" = "p102-import-capabilities-through-consent-and-policy"
    "P10.3" = "p103-complete-live-read-only-mcp-journey"
    "P11.2" = "p112-run-the-bounded-pilot"
    "P11.1" = "p111-build-and-verify-release-packages"
    "P11.3" = "p113-synchronize-all-product-truth"
    "P11.4" = "p114-final-independent-review-and-release-decision"
}

function Get-ChecklistAnchorForStep {
    param([string]$Step)

    $parentStep = $Step -replace '([0-9])([a-z])$', '$1'
    if (-not $stepAnchors.ContainsKey($parentStep)) {
        throw "No checklist anchor is registered for '$Step'."
    }
    return $stepAnchors[$parentStep]
}

function New-Mapping {
    param(
        [string]$Step,
        [string]$Lane,
        [string[]]$BehaviorIds,
        [string]$DesignAnchor,
        [string]$UiAnchor
    )

    $null = Get-ChecklistAnchorForStep $Step
    return [PSCustomObject]@{
        step = $Step
        lane = $Lane
        behaviorIds = @(Get-OrdinalUniqueStrings $BehaviorIds)
        designAnchor = $DesignAnchor
        uiAnchor = $UiAnchor
    }
}

function Get-CurrentMapping {
    param([string]$Id)

    $key = $Id
    if ($key -match '^AC-AR-(\d{3})$') {
        $key = "AR-$($Matches[1])"
    } elseif ($key -match '^AC-(PET|AI|VOICE|VISION|MEM|FUT)-(\d{3})$') {
        $key = "FR-$($Matches[1])-$($Matches[2])"
    }

    if ($key -match '^LOC-(PRIVACY|TRANSMISSION|PORTS)$') {
        $pbs = if ($key -eq "LOC-PRIVACY") { @("PB-007", "PB-012", "PB-014", "PB-016") } else { @("PB-011", "PB-012", "PB-015", "PB-016") }
        return New-Mapping "P0A.1" "V-STATIC" $pbs "22-security-and-threat-model" "14-privacy-page"
    }
    if ($key -eq "LOC-STORAGE") {
        return New-Mapping "P0A.1" "V-STATIC" @("PB-008", "PB-009", "PB-014", "PB-016") "21-persistence-and-data-lifecycle" "14-privacy-page"
    }
    if ($key -match '^LOC-(ASSETS|GAPS)$') {
        return New-Mapping "P0A.1" "V-STATIC" @("PB-002", "PB-004", "PB-018") "2-existing-system-evidence" "7-pet-state-specification"
    }
    if ($key -match '^LOC-(RUNTIME|VERIFY|STATUS)$') {
        return New-Mapping "P0A.1" "V-STATIC" @("PB-017", "PB-018") "28-verification-strategy" "23-ui-quality-gates"
    }
    if ($key -match '^LOC-') {
        return New-Mapping "P0A.1" "V-STATIC" @("PB-001", "PB-018") "2-existing-system-evidence" "24-requirement-traceability"
    }

    $specific = @{
        "AR-001" = @("P0A.2", "V-FIXTURE-E2E", @("PB-001", "PB-011", "PB-018"), "2-existing-system-evidence", "7-pet-state-specification")
        "AR-002" = @("P0A.5", "V-COMPONENT", @("PB-011", "PB-012", "PB-017"), "14-wpfsidecar-protocol", "16-diagnostics")
        "AR-003" = @("P0A.5", "V-CONTRACT", @("PB-012", "PB-016"), "14-wpfsidecar-protocol", "15-activity-and-receipts")
        "AR-004" = @("P0A.5", "V-COMPONENT", @("PB-005", "PB-011"), "13-deterministic-and-agentic-routing", "9-conversation-page")
        "AR-005" = @("P0A.5", "V-SECURITY", @("PB-012", "PB-016"), "22-security-and-threat-model", "14-privacy-page")
        "PR-001" = @("P0A.5", "V-SECURITY", @("PB-007", "PB-016"), "22-security-and-threat-model", "14-privacy-page")
        "PR-002" = @("P0A.6", "V-UIA", @("PB-007", "PB-016", "PB-018"), "22-security-and-threat-model", "14-privacy-page")
        "PR-003" = @("P0A.5", "V-SECURITY", @("PB-007", "PB-016"), "22-security-and-threat-model", "14-privacy-page")
        "PR-004" = @("P0A.6", "V-WPF", @("PB-008", "PB-016", "PB-018"), "22-security-and-threat-model", "14-privacy-page")
        "PR-005" = @("P0A.5", "V-COMPONENT", @("PB-009", "PB-014", "PB-016"), "18-canonical-memory-architecture", "12-memory-center")
        "PR-006" = @("P0A.5", "V-SECURITY", @("PB-012", "PB-016"), "22-security-and-threat-model", "14-privacy-page")
    }
    if ($specific.ContainsKey($key)) {
        $value = $specific[$key]
        return New-Mapping $value[0] $value[1] $value[2] $value[3] $value[4]
    }

    if ($key -match '^FR-PET-(\d{3})$') {
        $number = [int]$Matches[1]
        $map = @{
            1 = @("P0A.6", "V-UIA", @("PB-001", "PB-002", "PB-003", "PB-018"))
            2 = @("P0A.4", "V-UNIT", @("PB-002", "PB-018"))
            3 = @("P0A.4", "V-UNIT", @("PB-002", "PB-018"))
            4 = @("P0A.4", "V-UNIT", @("PB-002", "PB-003", "PB-018"))
            5 = @("P0A.7", "V-UIA", @("PB-003", "PB-004", "PB-018"))
            6 = @("P0A.6", "V-WPF", @("PB-004", "PB-018"))
            7 = @("P0A.8", "V-MANUAL-WIN", @("PB-004", "PB-018"))
            8 = @("P0A.6", "V-WPF", @("PB-004", "PB-018"))
            9 = @("P0A.6", "V-WPF", @("PB-004", "PB-018"))
            10 = @("P0A.8", "V-MANUAL-WIN", @("PB-003", "PB-007", "PB-018"))
            11 = @("P0A.5", "V-COMPONENT", @("PB-008", "PB-009", "PB-014", "PB-018"))
            12 = @("P0A.4", "V-UNIT", @("PB-002", "PB-009", "PB-018"))
            13 = @("P0A.6", "V-WPF", @("PB-008", "PB-018"))
            14 = @("P0A.4", "V-COMPONENT", @("PB-010", "PB-018"))
        }
        $value = $map[$number]
        $uiAnchor = switch ($number) {
            11 { "21-gate-0-ui-preservation-contract" }
            13 { "21-gate-0-ui-preservation-contract" }
            14 { "16-diagnostics" }
            default { "7-pet-state-specification" }
        }
        return New-Mapping $value[0] $value[1] $value[2] "2-existing-system-evidence" $uiAnchor
    }
    if ($key -match '^FR-AI-(\d{3})$') {
        $number = [int]$Matches[1]
        $map = @{
            1 = @("P0A.7", "V-FIXTURE-E2E", @("PB-005", "PB-018"), "9-conversation-page")
            2 = @("P0A.5", "V-CONTRACT", @("PB-005", "PB-011"), "9-conversation-page")
            3 = @("P0A.5", "V-COMPONENT", @("PB-005", "PB-011"), "9-conversation-page")
            4 = @("P0A.5", "V-COMPONENT", @("PB-005", "PB-014"), "9-conversation-page")
            5 = @("P0A.5", "V-COMPONENT", @("PB-001", "PB-011", "PB-012", "PB-017"), "16-diagnostics")
            6 = @("P0A.5", "V-CONTRACT", @("PB-013"), "13-capabilities-and-permissions")
            7 = @("P0A.5", "V-CONTRACT", @("PB-013"), "9-conversation-page")
            8 = @("P0A.5", "V-CONTRACT", @("PB-015"), "13-capabilities-and-permissions")
        }
        $value = $map[$number]
        return New-Mapping $value[0] $value[1] $value[2] "13-deterministic-and-agentic-routing" $value[3]
    }
    if ($key -match '^FR-VOICE-') {
        return New-Mapping "P0A.5" "V-COMPONENT" @("PB-006", "PB-012", "PB-018") "16-voice-pipeline" "9-conversation-page"
    }
    if ($key -match '^FR-VISION-') {
        return New-Mapping "P0A.5" "V-COMPONENT" @("PB-007", "PB-016") "17-context-acquisition-and-grounding" "14-privacy-page"
    }
    if ($key -match '^FR-MEM-(\d{3})$') {
        $number = [int]$Matches[1]
        $pbs = switch ($number) {
            2 { @("PB-007", "PB-009", "PB-014", "PB-016") }
            3 { @("PB-009", "PB-012", "PB-014", "PB-016") }
            6 { @("PB-009", "PB-014", "PB-016", "PB-018") }
            default { @("PB-009", "PB-014", "PB-016") }
        }
        $step = if ($number -eq 6) { "P7.4" } else { "P0A.5" }
        return New-Mapping $step "V-COMPONENT" $pbs "18-canonical-memory-architecture" "12-memory-center"
    }
    if ($key -match '^FR-FUT-') {
        return New-Mapping "P4.5" "V-WPF" @("PB-002", "PB-004", "PB-018") "32-requirement-traceability" "23-ui-quality-gates"
    }
    if ($key -match '^NFR-(\d{3})$') {
        $number = [int]$Matches[1]
        $lane = if ($number -eq 6) { "V-PACKAGE" } elseif ($number -eq 8) { "V-FIXTURE-E2E" } else { "V-PERF" }
        $pbs = switch ($number) {
            2 { @("PB-002", "PB-004", "PB-018") }
            3 { @("PB-001", "PB-011", "PB-017", "PB-018") }
            4 { @("PB-001", "PB-011", "PB-017", "PB-018") }
            6 { @("PB-017") }
            7 { @("PB-002", "PB-018") }
            8 { @("PB-001", "PB-005", "PB-006", "PB-010", "PB-011", "PB-013", "PB-015", "PB-017") }
            default { @("PB-002", "PB-003", "PB-018") }
        }
        $step = if ($number -eq 8) { "P0A.7" } else { "P0A.8" }
        return New-Mapping $step $lane $pbs "28-verification-strategy" "23-ui-quality-gates"
    }

    throw "No current-requirement mapping for '$Id'."
}

function Get-FutureFrMapping {
    param([int]$Number)

    $map = @{
        1 = @("P4.1", "V-FIXTURE-E2E", @("PB-005", "PB-018"), "15-sidecar-orchestration-design", "9-conversation-page")
        2 = @("H0.1", "V-SECURITY", @("PB-011", "PB-016"), "13-deterministic-and-agentic-routing", "13-capabilities-and-permissions")
        3 = @("P5.3", "V-FIXTURE-E2E", @("PB-005", "PB-014"), "19-reminders-brief-and-proactive-system", "8-today-page")
        4 = @("P5.1", "V-COMPONENT", @("PB-014", "PB-018"), "19-reminders-brief-and-proactive-system", "8-today-page")
        5 = @("P6.1", "V-SECURITY", @("PB-007", "PB-016"), "17-context-acquisition-and-grounding", "14-privacy-page")
        6 = @("P8.2", "V-FIXTURE-E2E", @("PB-013", "PB-016"), "13-deterministic-and-agentic-routing", "10-tasks-page-and-task-detail")
        7 = @("P3.3", "V-SECURITY", @("PB-013", "PB-016"), "12-capability-risk-and-policy-model", "11-approval-review")
        8 = @("P3.1", "V-COMPONENT", @("PB-014", "PB-017"), "11-task-and-step-state-machines", "10-tasks-page-and-task-detail")
        9 = @("P7.2", "V-COMPONENT", @("PB-009", "PB-014", "PB-016"), "18-canonical-memory-architecture", "12-memory-center")
        10 = @("P9.3", "V-FIXTURE-E2E", @("PB-004", "PB-016"), "19-reminders-brief-and-proactive-system", "8-today-page")
        11 = @("P9.1", "V-COMPONENT", @("PB-006", "PB-016"), "16-voice-pipeline", "9-conversation-page")
        12 = @("P9.2", "V-FIXTURE-E2E", @("PB-013", "PB-016"), "17-context-acquisition-and-grounding", "9-conversation-page")
        13 = @("P10.2", "V-SECURITY", @("PB-015", "PB-016"), "20-mcp-and-extension-architecture", "13-capabilities-and-permissions")
        14 = @("P0A.2", "V-FIXTURE-E2E", @("PB-001", "PB-011", "PB-017"), "15-sidecar-orchestration-design", "16-diagnostics")
        15 = @("P4.1", "V-UIA", @("PB-001", "PB-018"), "5-target-system-context", "7-pet-state-specification")
        16 = @("P4.4", "V-SECURITY", @("PB-016", "PB-017"), "23-observability-and-diagnostics", "16-diagnostics")
        17 = @("P0B.3", "V-ACCESS", @("PB-018"), "28-verification-strategy", "21-accessibility-acceptance-criteria")
        18 = @("P1.4", "V-SECURITY", @("PB-008", "PB-016"), "22-security-and-threat-model", "14-privacy-page")
        19 = @("P7.1", "V-COMPONENT", @("PB-009", "PB-014", "PB-016"), "21-persistence-and-data-lifecycle", "14-privacy-page")
        20 = @("P4.5", "V-WPF", @("PB-002", "PB-004", "PB-018"), "11-task-and-step-state-machines", "7-pet-state-specification")
        21 = @("P0A.1", "V-STATIC", @("PB-001", "PB-018"), "2-existing-system-evidence", "2-core-interaction-principles")
        22 = @("D0.2", "V-STATIC", @("PB-017", "PB-018"), "28-verification-strategy", "23-ui-quality-gates")
        23 = @("D0.3", "V-STATIC", @("PB-017", "PB-018"), "32-requirement-traceability", "24-requirement-traceability")
        24 = @("D0.3", "V-STATIC", @("PB-017", "PB-018"), "28-verification-strategy", "23-ui-quality-gates")
    }
    $value = $map[$Number]
    if ($null -eq $value) {
        throw "No future FR mapping for '$Number'."
    }
    return New-Mapping $value[0] $value[1] $value[2] $value[3] $value[4]
}

function Get-PrdMapping {
    param([string]$Id)

    if ($Id -match '^AC-FR-(\d{3})-\d{2}$') {
        return Get-FutureFrMapping ([int]$Matches[1])
    }
    if ($Id -match '^NFR-JA-(\d{3})(?:-\d{2})?$') {
        $map = @{
            1 = @("P0A.8", "V-PERF", @("PB-017", "PB-018"), "28-verification-strategy", "23-ui-quality-gates")
            2 = @("P3.1", "V-COMPONENT", @("PB-001", "PB-017"), "24-error-taxonomy", "23-ui-quality-gates")
            3 = @("P0B.4", "V-SECURITY", @("PB-016"), "22-security-and-threat-model", "14-privacy-page")
            4 = @("P1.1", "V-STATIC", @("PB-017"), "8-dependency-rules", "23-ui-quality-gates")
            5 = @("P0A.1", "V-STATIC", @("PB-018"), "28-verification-strategy", "23-ui-quality-gates")
            6 = @("P1.3", "V-COMPONENT", @("PB-014", "PB-017"), "29-migration-and-rollback", "16-diagnostics")
            7 = @("D0.2", "V-STATIC", @("PB-017"), "28-verification-strategy", "23-ui-quality-gates")
            8 = @("D0.3", "V-STATIC", @("PB-017"), "28-verification-strategy", "24-requirement-traceability")
        }
        $value = $map[[int]$Matches[1]]
        return New-Mapping $value[0] $value[1] $value[2] $value[3] $value[4]
    }
    if ($Id -match '^GATE-(0|[A-E])-\d{2}$') {
        $gate = $Matches[1]
        $map = @{
            "0" = @("P0A.1", "V-STATIC")
            "A" = @("P1.1", "V-STATIC")
            "B" = @("P4.1", "V-UIA")
            "C" = @("P7.2", "V-COMPONENT")
            "D" = @("P8.2", "V-REAL-E2E")
            "E" = @("P11.4", "V-PACKAGE")
        }
        $value = $map[$gate]
        return New-Mapping $value[0] $value[1] @("PB-016", "PB-017", "PB-018") "28-verification-strategy" "23-ui-quality-gates"
    }
    if ($Id -match '^RISK-(\d{3})$') {
        $number = [int]$Matches[1]
        $map = @{
            1 = @("H0.1", "V-STATIC", @("PB-017", "PB-018"), "23-ui-quality-gates")
            2 = @("H0.6", "V-FIXTURE-E2E", @("PB-013", "PB-016", "PB-018"), "11-approval-review")
            3 = @("P9.3", "V-FIXTURE-E2E", @("PB-004", "PB-016", "PB-018"), "8-today-page")
            4 = @("P7.4", "V-SECURITY", @("PB-009", "PB-014", "PB-016"), "12-memory-center")
            5 = @("H0.3", "V-CONTRACT", @("PB-011", "PB-012", "PB-017"), "16-diagnostics")
            6 = @("H0.1", "V-PERF", @("PB-011", "PB-013", "PB-017"), "16-diagnostics")
            7 = @("P3.5", "V-SECURITY", @("PB-013", "PB-016", "PB-017"), "11-approval-review")
            8 = @("H0.6", "V-UIA", @("PB-001", "PB-018"), "10-tasks-page-and-task-detail")
            9 = @("P10.1", "V-SECURITY", @("PB-015", "PB-016", "PB-017"), "13-capabilities-and-permissions")
            10 = @("P0A.1", "V-STATIC", @("PB-017", "PB-018"), "23-ui-quality-gates")
            11 = @("D0.3", "V-STATIC", @("PB-017", "PB-018"), "23-ui-quality-gates")
            12 = @("D0.4", "V-STATIC", @("PB-017"), "16-diagnostics")
            13 = @("D0.3", "V-STATIC", @("PB-017", "PB-018"), "24-requirement-traceability")
            14 = @("D0.3", "V-STATIC", @("PB-017", "PB-018"), "24-requirement-traceability")
        }
        $value = $map[$number]
        return New-Mapping $value[0] $value[1] $value[2] "31-risks-and-mitigations" $value[3]
    }

    throw "No PRD mapping for '$Id'."
}

function Get-TextHash {
    param([string]$Text)

    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($Text.Replace("`r`n", "`n").Replace("`r", "`n"))
        return ([BitConverter]::ToString($sha256.ComputeHash($bytes))).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha256.Dispose()
    }
}

function Get-NormativeSourceRecord {
    param(
        [string]$Namespace,
        [string]$Id
    )

    if ($Namespace -eq "CURRENT" -and $Id.StartsWith("LOC-")) {
        $path = $requirementsPath
        $lines = $script:requirementsLines
        $headingMap = @{
            "LOC-STATUS" = '^## 1\. Status Model$'
            "LOC-INTENT" = '^## 2\. Product Intent$'
            "LOC-SCOPE" = '^### Scope boundary$'
            "LOC-STORAGE" = '^### 5\.1 Local storage$'
            "LOC-PORTS" = '^### 5\.2 Loopback communication$'
            "LOC-TRANSMISSION" = '^### 5\.3 External transmission$'
            "LOC-PRIVACY" = '^### 5\.4 Privacy requirements$'
            "LOC-ASSETS" = '^## 6\. Assets and Visual Completeness$'
            "LOC-RUNTIME" = '^## 8\. Runtime and Dependency Requirements$'
            "LOC-VERIFY" = '^## 9\. Verification Requirements$'
            "LOC-GAPS" = '^## 10\. Known Release Gaps$'
        }
        $token = "REQUIREMENTS:$($Id.Substring(4))"
        $pattern = $headingMap[$Id]
        if ([string]::IsNullOrWhiteSpace($pattern)) { throw "No original REQUIREMENTS locator for '$Id'." }
        $kind = "section"
    } elseif ($Namespace -eq "CURRENT") {
        $path = $requirementsPath
        $lines = $script:requirementsLines
        $token = $Id
        if ($Id.StartsWith("AC-")) {
            $parentId = Get-CurrentCanonicalId $Id
            $pattern = '^\|\s*' + [regex]::Escape($parentId) + '\s*\|.*(?<![A-Z0-9-])' + [regex]::Escape($Id) + '(?![A-Z0-9-])'
        } else {
            $pattern = '^\|\s*' + [regex]::Escape($Id) + '\s*\|'
        }
        $kind = "single"
    } else {
        $path = $prdPath
        $lines = $script:prdLines
        $token = $Id
        if ($Id -match '^AC-FR-') {
            $pattern = '^\d+\.\s+' + [regex]::Escape($Id) + ':'
            $kind = "acceptance"
        } elseif ($Id -match '^NFR-JA-\d{3}$') {
            $pattern = '^###\s+' + [regex]::Escape($Id) + ':'
            $kind = "single"
        } elseif ($Id -match '^(?:NFR-JA-\d{3}-\d{2}|GATE-(?:0|[A-E])-\d{2})$') {
            $pattern = '^-\s+' + [regex]::Escape($Id) + ':'
            $kind = "list"
        } else {
            $pattern = '^\|\s*' + [regex]::Escape($Id) + '\s*\|'
            $kind = "single"
        }
    }

    $locatorIndexes = [System.Collections.Generic.List[int]]::new()
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match $pattern) {
            $locatorIndexes.Add($index)
        }
    }
    if ($locatorIndexes.Count -ne 1) {
        throw "Normative source token '$token' has $($locatorIndexes.Count) authoritative locator matches in '$path'."
    }

    $start = $locatorIndexes[0]
    $end = $start
    if ($kind -eq "acceptance") {
        while ($end + 1 -lt $lines.Count -and
            $lines[$end + 1] -notmatch '^\d+\.\s+AC-FR-' -and
            $lines[$end + 1] -notmatch '^###\s+') {
            if ([string]::IsNullOrWhiteSpace($lines[$end + 1])) { break }
            $end++
        }
    } elseif ($kind -eq "list") {
        while ($end + 1 -lt $lines.Count -and
            $lines[$end + 1] -notmatch '^-(?:\s+)(?:NFR-JA-|GATE-)' -and
            $lines[$end + 1] -notmatch '^#{2,3}\s+') {
            if ([string]::IsNullOrWhiteSpace($lines[$end + 1])) { break }
            $end++
        }
    } elseif ($kind -eq "section") {
        $headingLevel = ([regex]::Match($lines[$start], '^#+')).Value.Length
        while ($end + 1 -lt $lines.Count) {
            $nextHeading = [regex]::Match($lines[$end + 1], '^(#+)\s+')
            if ($nextHeading.Success -and $nextHeading.Groups[1].Value.Length -le $headingLevel) { break }
            $end++
        }
        while ($end -gt $start -and [string]::IsNullOrWhiteSpace($lines[$end])) { $end-- }
    }

    $text = $lines[$start..$end] -join "`n"
    return [PSCustomObject]@{
        path = $path
        line = $start + 1
        endLine = $end + 1
        token = $token
        text = $text
        sha256 = Get-TextHash $text
    }
}

function Get-CurrentCanonicalId {
    param([string]$Id)

    if ($Id -match '^AC-AR-(\d{3})$') { return "AR-$($Matches[1])" }
    if ($Id -match '^AC-(PET|AI|VOICE|VISION|MEM|FUT)-(\d{3})$') {
        return "FR-$($Matches[1])-$($Matches[2])"
    }
    return $Id
}

function Get-CurrentDispositionRecord {
    param(
        [string]$Id,
        [string]$SourceText
    )

    $canonicalId = Get-CurrentCanonicalId $Id
    $approvalMap = @{
        "AR-003" = @("change", "APP-001")
        "FR-AI-006" = @("change", "APP-002")
        "FR-MEM-001" = @("change", "APP-003")
        "FR-MEM-002" = @("change", "APP-004")
        "FR-MEM-003" = @("change", "APP-005")
        "FR-MEM-005" = @("change", "APP-006")
        "FR-FUT-001" = @("defer", "APP-007")
        "FR-FUT-002" = @("defer", "APP-008")
        "FR-FUT-003" = @("defer", "APP-009")
    }

    if ($canonicalId.StartsWith("LOC-")) {
        return [PSCustomObject]@{
            mapId = "REQMAP-CURRENT-$($canonicalId.Substring(4))"
            currentStatus = "aggregate normative section"
            effectiveDisposition = "preserve"
            proposedDisposition = "preserve"
            approvalId = $null
            approvalStatus = "not-required"
            baselineTreatment = "contextual-section"
        }
    }

    $statusMatches = [regex]::Matches($SourceText, '\*\*([^*]+)\*\*')
    $status = if ($statusMatches.Count -gt 0) { $statusMatches[$statusMatches.Count - 1].Groups[1].Value } else { "documented" }
    $proposal = if ($approvalMap.ContainsKey($canonicalId)) { $approvalMap[$canonicalId] } else { @("preserve", $null) }
    $treatment = if ($status -match '^Planned$') {
        "future-red-only"
    } elseif ($status -match 'Partial|placeholder|Unverified|pending') {
        "baseline-plus-future-red"
    } else {
        "baseline-qualification"
    }
    return [PSCustomObject]@{
        mapId = "REQMAP-$canonicalId"
        currentStatus = $status
        effectiveDisposition = "preserve"
        proposedDisposition = $proposal[0]
        approvalId = $proposal[1]
        approvalStatus = if ($null -eq $proposal[1]) { "not-required" } else { "pending" }
        baselineTreatment = $treatment
    }
}

function Resolve-ExecutableCurrentStep {
    param(
        [string]$CanonicalId,
        [string]$BaseStep
    )

    if ($BaseStep -eq "P0A.4") {
        if ($CanonicalId -match '^FR-PET-(002|003)$') { return "P0A.4a" }
        if ($CanonicalId -match '^FR-PET-(001|004|005|007|010)$') { return "P0A.4b" }
        if ($CanonicalId -match '^FR-PET-012$') { return "P0A.4c" }
        if ($CanonicalId -match '^FR-PET-(006|008|009)$') { return "P0A.4d" }
        return "P0A.4e"
    }
    if ($BaseStep -eq "P0A.5") {
        if ($CanonicalId -match '^(AR-001|AR-004|FR-AI-003|FR-AI-005)$') { return "P0A.5a" }
        if ($CanonicalId -match '^FR-AI-00[1-4]$') { return "P0A.5b" }
        if ($CanonicalId -match '^(FR-MEM-|FR-PET-011|FR-PET-013|PR-005)') { return "P0A.5c" }
        if ($CanonicalId -match '^(FR-VOICE-|FR-VISION-|PR-00[1-4])') { return "P0A.5d" }
        return "P0A.5e"
    }
    if ($BaseStep -eq "P4.5") { return "P4.5e" }
    return $BaseStep
}

function New-TestTarget {
    param([string]$Step, [string]$Lane, [AllowNull()][string]$Scenario = $null)
    $null = Get-ChecklistAnchorForStep $Step
    return [PSCustomObject]@{ step = $Step; lane = $Lane; scenario = $Scenario }
}

function Add-TestTarget {
    param(
        [System.Collections.Generic.List[object]]$Targets,
        [string]$Step,
        [string]$Lane,
        [AllowNull()][string]$Scenario = $null
    )

    if (@($Targets | Where-Object { $_.step -eq $Step -and $_.lane -eq $Lane -and $_.scenario -eq $Scenario }).Count -eq 0) {
        $Targets.Add((New-TestTarget $Step $Lane $Scenario))
    }
}

$futureOwnerSteps = @{
    1 = @("P4.1b", "P9.1c", "P2.2", "P2.3")
    2 = @("H0.1", "P3.3", "P4.4", "P3.3")
    3 = @("P5.3", "P5.3", "P5.2", "P5.4", "P5.3")
    4 = @("P5.1", "P5.1", "P5.2", "P5.1", "P5.1")
    5 = @("P6.1", "P6.3", "P6.3", "P6.4", "P6.1", "P6.2")
    6 = @("P8.2", "P3.2", "P3.3", "P3.1b", "P8.2")
    7 = @("P3.2", "P3.4", "P3.4", "P3.3", "P3.3", "P3.3")
    8 = @("P3.1a", "P3.4", "P3.5", "P3.6", "P3.5", "P3.1b")
    9 = @("P7.2a", "P7.3", "P7.4", "P7.3", "P7.3", "P7.4")
    10 = @("P9.3", "P9.3", "P9.3", "P9.3", "P9.3", "P9.3")
    11 = @("P9.1a", "P9.1c", "P9.1d", "P9.1b", "P9.1b", "P9.1c")
    12 = @("P9.2", "P9.2", "P9.2", "P9.2", "P9.2")
    13 = @("P10.1", "P10.2", "P10.2", "P10.1", "P10.1")
    14 = @("P2.2", "P3.3", "P2.2", "P2.3")
    15 = @("P4.3", "P4.1a", "P4.2", "P4.3", "P4.3")
    16 = @("P4.4", "P4.4", "P4.4", "P4.4", "P4.4")
    17 = @("P0B.3e", "P0B.3f", "P0B.3e", "P0B.3e", "P0B.3b", "P0B.3e")
    18 = @("P1.4", "P1.4", "P1.4", "P2.2", "P2.2")
    19 = @("P7.4", "P11.3", "P7.4", "P11.3", "P4.4")
    20 = @("P4.3", "P3.3", "P4.3", "P7.2a", "P4.5e")
    21 = @("P0A.1", "P0A.1", "P0A.9", "P0A.9", "P0A.1", "P0A.9", "P0A.8", "P0A.9", "P0A.1", "P0A.1", "P0A.9", "P0A.9")
    22 = @("D0.3", "D0.3", "D0.3", "D0.3", "P11.4", "D0.3", "D0.2", "D0.2", "D0.2", "D0.2", "D0.2", "D0.3", "D0.3", "D0.3")
    23 = @("D0.3", "D0.3", "D0.3", "D0.3", "D0.3", "D0.3")
    24 = @("D0.3", "D0.3", "D0.3", "D0.3", "D0.3", "D0.3", "D0.3", "D0.3")
}

function Get-PrimaryLaneForStep {
    param(
        [string]$Step,
        [string]$Text,
        [string]$FallbackLane
    )

    if ($Step -match '^(D0\.|H0\.1|H0\.2|H0\.4|H0\.5|P0A\.1|P0A\.9|P1\.1|P1\.5|P11\.3|P11\.4)') { return "V-STATIC" }
    if ($Step -match '^P0B\.3') { return "V-ACCESS" }
    if ($Step -match '^P1\.4|^P3\.3|^P10\.') { return "V-SECURITY" }
    if ($Step -match '^P2\.') { return "V-CONTRACT" }
    if ($Step -match '^P1\.2|^P1\.3|^P3\.1|^P3\.2|^P3\.4|^P3\.5|^P3\.6|^P5\.[123]|^P6\.1|^P7\.[1235]|^P8\.[12]|^P9\.[123]') { return "V-COMPONENT" }
    if ($Step -match '^P4\.|^P5\.4|^P6\.4|^P7\.4|^P8\.3') { return "V-WPF" }
    if ($Step -match '^P8\.4|^P11\.2') { return "V-REAL-E2E" }
    if ($Step -match '^P11\.1') { return "V-PACKAGE" }
    if ($Text -match '(?i)\bp95\b|\bperformance\b|\blatency\b|\bmemory regression\b') { return "V-PERF" }
    return $FallbackLane
}

function Add-GateZeroLaneTargets {
    param(
        [System.Collections.Generic.List[object]]$Targets,
        [string[]]$Lanes
    )

    $owners = @{
        "V-UNIT" = "P0A.4a"; "V-COMPONENT" = "P0A.5a"; "V-CONTRACT" = "P0A.5e"
        "V-WPF" = "P0A.6"; "V-UIA" = "P0A.7"; "V-FIXTURE-E2E" = "P0A.7"
        "V-REAL-E2E" = "P0A.2"; "V-SECURITY" = "P0A.5e"; "V-ACCESS" = "P0A.6"
        "V-PERF" = "P0A.8"; "V-PACKAGE" = "P0A.8"; "V-STATIC" = "P0A.1"
        "V-MANUAL-WIN" = "P0A.8"; "V-LEGACY" = "P0A.9"
    }
    foreach ($lane in $Lanes) {
        if ($lane -eq "V-REAL-E2E") {
            Add-TestTarget $Targets "P0A.2" $lane "PET-VISIBILITY"
            Add-TestTarget $Targets "P0A.2" $lane "KEYBOARD-SURFACE"
        } else {
            Add-TestTarget $Targets $owners[$lane] $lane
        }
    }
}

function Get-TraceTargets {
    param(
        [string]$Namespace,
        [string]$Id,
        [string]$Text,
        [string]$CurrentStatus,
        [object]$BaseMapping
    )

    $targets = [System.Collections.Generic.List[object]]::new()
    if ($Namespace -eq "CURRENT") {
        $canonicalId = Get-CurrentCanonicalId $Id
        $step = Resolve-ExecutableCurrentStep $canonicalId $BaseMapping.step
        if ($CurrentStatus -notmatch '^Planned$') { Add-TestTarget $targets $step $BaseMapping.lane }

        $laterTargets = @{
            "FR-PET-004" = @("P4.5a", "V-UNIT")
            "FR-PET-007" = @("P4.5b", "V-WPF")
            "FR-PET-008" = @("P4.5c", "V-WPF")
            "FR-PET-010" = @("P4.5d", "V-MANUAL-WIN")
            "FR-AI-005" = @("P2.2", "V-CONTRACT")
            "FR-AI-007" = @("P9.2", "V-FIXTURE-E2E")
            "FR-VOICE-003" = @("P9.1b", "V-CONTRACT")
            "FR-VISION-004" = @("P6.3", "V-SECURITY")
            "FR-MEM-004" = @("P7.3", "V-COMPONENT")
            "FR-MEM-006" = @("P7.4", "V-WPF")
            "FR-MEM-007" = @("P7.3", "V-COMPONENT")
            "PR-004" = @("P1.4", "V-SECURITY")
            "PR-005" = @("P7.4", "V-WPF")
            "PR-006" = @("P2.2", "V-SECURITY")
            "FR-FUT-001" = @("P4.5e", "V-WPF")
            "FR-FUT-002" = @("P4.5e", "V-WPF")
            "FR-FUT-003" = @("P4.5e", "V-WPF")
        }
        if ($laterTargets.ContainsKey($canonicalId)) {
            $target = $laterTargets[$canonicalId]
            Add-TestTarget $targets $target[0] $target[1]
        }
        if ($canonicalId -eq "FR-PET-001") { Add-TestTarget $targets "P0A.2" "V-REAL-E2E" "PET-VISIBILITY" }
        if ($canonicalId -eq "FR-PET-005") { Add-TestTarget $targets "P0A.2" "V-REAL-E2E" "KEYBOARD-SURFACE" }
        if ($canonicalId -eq "FR-AI-008") { Add-TestTarget $targets "P10.3" "V-REAL-E2E" "CONSENTED-READ" }
        if ($canonicalId -match '^FR-PET-(006|008|009)$') { Add-TestTarget $targets "P0A.4d" "V-UNIT" }
        if ($canonicalId -eq "FR-PET-014") { Add-TestTarget $targets "P0A.4e" "V-COMPONENT" }
        if ($CurrentStatus -notmatch '^Planned$') {
            if ($BaseMapping.behaviorIds -contains "PB-012") { Add-TestTarget $targets "P0A.5e" "V-CONTRACT" }
            if ($BaseMapping.behaviorIds -contains "PB-016") { Add-TestTarget $targets "P0A.5e" "V-SECURITY" }
            if ($BaseMapping.behaviorIds -contains "PB-017") { Add-TestTarget $targets "P0A.8" "V-PACKAGE" }
            if ($Id -notmatch '^LOC-' -and $CurrentStatus -notmatch '^Unverified') {
                Add-TestTarget $targets "P0A.9" "V-LEGACY"
            }
        }
        return $targets.ToArray()
    }

    if ($Id -match '^AC-FR-(\d{3})-(\d{2})$') {
        $fr = [int]$Matches[1]
        $criterion = [int]$Matches[2]
        $owners = $futureOwnerSteps[$fr]
        if ($criterion -lt 1 -or $criterion -gt $owners.Count) {
            throw "No leaf owner for '$Id'."
        }
        $owner = $owners[$criterion - 1]
        $lane = Get-PrimaryLaneForStep $owner $Text $BaseMapping.lane
        if ($Id -ne "AC-FR-021-07") { Add-TestTarget $targets $owner $lane }

        $metaOwner = $owner -match '^(D0\.|P0A\.1|P0A\.9|P11\.4)' -or $Id -eq "AC-FR-021-07"
        if (-not $metaOwner -and $Text -match '(?i)secret|credential|protected|privacy|permission|grant|redact|capture|transmi') {
            Add-TestTarget $targets $owner "V-SECURITY"
        }
        if (-not $metaOwner -and $Text -match '(?i)sidecar|protocol|provider|route|MCP|cross-runtime') {
            Add-TestTarget $targets $owner "V-CONTRACT"
        }
        if (-not $metaOwner -and $Text -match '(?i)keyboard|Narrator|assistive|high contrast|text scal|without a mouse|visible focus') {
            Add-TestTarget $targets $owner "V-ACCESS"
        }
        if (-not $metaOwner -and $Text -match '(?i)\bp95\b|\bperformance\b|\blatency\b|\bmemory regression\b') {
            Add-TestTarget $targets $owner "V-PERF"
        }
        if (-not $metaOwner -and $Text -match '(?i)supported Windows|real boundary|clean machine|package|installer') {
            Add-TestTarget $targets $owner $(if ($Text -match '(?i)package|installer|clean machine') { "V-PACKAGE" } else { "V-REAL-E2E" })
        }

        $explicitLanes = @{
            "AC-FR-021-03" = @("V-LEGACY")
            "AC-FR-021-12" = @("V-LEGACY")
        }
        if ($explicitLanes.ContainsKey($Id)) {
            foreach ($explicitLane in $explicitLanes[$Id]) { Add-TestTarget $targets $owner $explicitLane }
        }

        $additionalTargets = @{
            "AC-FR-001-02" = @("P4.3|V-COMPONENT")
            "AC-FR-007-02" = @("P4.2|V-WPF", "P4.2|V-ACCESS")
            "AC-FR-008-04" = @("P4.2|V-WPF", "P4.2|V-ACCESS")
            "AC-FR-020-04" = @("P7.4|V-WPF", "P7.4|V-ACCESS")
            "AC-FR-003-04" = @("P3.6|V-COMPONENT")
            "AC-FR-004-04" = @("P3.6|V-COMPONENT")
            "AC-FR-005-06" = @("P4.3|V-WPF")
            "AC-FR-008-05" = @("P3.4|V-COMPONENT", "P3.6|V-COMPONENT", "P4.2|V-WPF")
            "AC-FR-009-06" = @("P7.5|V-COMPONENT")
            "AC-FR-021-03" = @("P0A.1|V-STATIC")
            "AC-FR-021-07" = @("P0A.7|V-FIXTURE-E2E")
            "AC-FR-021-11" = @("P0A.3a|V-STATIC", "P0A.3a|V-SECURITY")
            "AC-FR-021-12" = @("P0A.1|V-STATIC")
        }
        if ($additionalTargets.ContainsKey($Id)) {
            foreach ($targetSpec in @($additionalTargets[$Id])) {
                $targetStep, $targetLane = $targetSpec -split '\|', 2
                Add-TestTarget $targets $targetStep $targetLane
            }
        }
        if ($Id -eq "AC-FR-021-07") {
            Add-TestTarget $targets "P0A.2" "V-REAL-E2E" "PET-VISIBILITY"
            Add-TestTarget $targets "P0A.2" "V-REAL-E2E" "KEYBOARD-SURFACE"
        }
        if ($Id -eq "AC-FR-024-02") {
            Add-GateZeroLaneTargets $targets @("V-UNIT", "V-COMPONENT", "V-CONTRACT", "V-WPF", "V-UIA", "V-FIXTURE-E2E", "V-REAL-E2E", "V-SECURITY", "V-ACCESS", "V-PERF", "V-PACKAGE", "V-STATIC")
        }
        $phaseFixtureOwners = @{
            3 = @("P5.4"); 5 = @("P6.4"); 6 = @("P8.2", "P8.3")
            7 = @("P3.4", "P4.2"); 8 = @("P3.5"); 9 = @("P7.4")
            10 = @("P9.3"); 11 = @("P9.1a"); 12 = @("P9.2")
            15 = @("P4.1b"); 16 = @("P4.4")
        }
        if ($phaseFixtureOwners.ContainsKey($fr)) {
            foreach ($fixtureOwner in $phaseFixtureOwners[$fr]) { Add-TestTarget $targets $fixtureOwner "V-FIXTURE-E2E" }
        }
        if ($fr -eq 13) {
            Add-TestTarget $targets "P10.3" "V-REAL-E2E" "CONSENTED-READ"
            Add-TestTarget $targets "P10.3" "V-REAL-E2E" "REVOCATION-SCHEMA-LIFECYCLE"
        }
        return $targets.ToArray()
    }

    if ($Id -match '^GATE-(0|[A-E])-(\d{2})$') {
        $gate = $Matches[1]
        $criterion = [int]$Matches[2]
        $ownerMap = @{
            "0" = @("P0A.1", "P0A.1", "P0A.9", "P0A.9", "P0A.1", "P0A.9", "P0A.9", "P0A.9", "P0A.9")
            "A" = @("P1.2", "P2.2", "P3.1a", "P0A.9", "P1.5")
            "B" = @("P5.3", "P3.6", "P0B.3e", "P11.2")
            "C" = @("P6.3", "P7.3", "P11.4")
            "D" = @("P8.3", "P3.5", "P8.4")
            "E" = @("P11.2", "P9.3", "H0.1", "P11.4")
        }
        $owner = $ownerMap[$gate][$criterion - 1]
        Add-TestTarget $targets $owner (Get-PrimaryLaneForStep $owner $Text $BaseMapping.lane)
        if ($Id -eq "GATE-0-03") { Add-GateZeroLaneTargets $targets @("V-UNIT", "V-COMPONENT", "V-WPF", "V-UIA", "V-FIXTURE-E2E", "V-REAL-E2E") }
        if ($Id -eq "GATE-0-04") { Add-GateZeroLaneTargets $targets @("V-CONTRACT", "V-SECURITY", "V-ACCESS", "V-PERF", "V-PACKAGE", "V-STATIC") }
        if ($Id -eq "GATE-0-06") { Add-GateZeroLaneTargets $targets @("V-STATIC", "V-LEGACY") }
        if ($Id -eq "GATE-0-07") {
            Add-TestTarget $targets "D0.5" "V-STATIC"
            Add-TestTarget $targets "D0.5" "V-PACKAGE"
        }
        if ($Id -eq "GATE-A-05") {
            Add-TestTarget $targets "P1.5" "V-STATIC"
            Add-TestTarget $targets "P11.1a" "V-PACKAGE"
            Add-TestTarget $targets "P0A.9" "V-LEGACY"
        }
        $gateAdditionalTargets = @{
            "GATE-A-01" = @("P1.2|V-COMPONENT")
            "GATE-A-02" = @("P1.4|V-SECURITY", "P4.4|V-COMPONENT")
            "GATE-A-03" = @("P1.3|V-COMPONENT")
            "GATE-B-01" = @("P5.1|V-COMPONENT", "P5.3|V-COMPONENT", "P5.4|V-WPF")
            "GATE-B-02" = @("P3.6|V-COMPONENT", "P4.2|V-WPF")
            "GATE-C-01" = @("P6.1|V-SECURITY", "P6.4|V-WPF")
            "GATE-D-01" = @("P3.3|V-SECURITY", "P3.4|V-COMPONENT", "P3.5|V-COMPONENT", "P3.6|V-COMPONENT")
            "GATE-D-02" = @("P8.4|V-REAL-E2E")
            "GATE-E-02" = @("P9.3|V-COMPONENT", "P11.2|V-REAL-E2E")
        }
        if ($gateAdditionalTargets.ContainsKey($Id)) {
            foreach ($targetSpec in @($gateAdditionalTargets[$Id])) {
                $targetStep, $targetLane = $targetSpec -split '\|', 2
                Add-TestTarget $targets $targetStep $targetLane
            }
        }
        return $targets.ToArray()
    }

    if ($Id -match '^NFR-JA-(\d{3})(?:-(\d{2}))?$') {
        $group = [int]$Matches[1]
        $leaf = if ([string]::IsNullOrWhiteSpace($Matches[2])) { 0 } else { [int]$Matches[2] }
        $leafTargets = @{
            "NFR-JA-001-01" = @("P0A.8|V-PERF"); "NFR-JA-001-02" = @("P4.1b|V-PERF")
            "NFR-JA-001-03" = @("P0A.6|V-PERF"); "NFR-JA-001-04" = @("P9.1a|V-PERF")
            "NFR-JA-001-05" = @("P2.3|V-PERF"); "NFR-JA-001-06" = @("P2.2|V-PERF")
            "NFR-JA-001-07" = @("P1.2|V-PERF")
            "NFR-JA-002-01" = @("P3.1b|V-COMPONENT", "P3.5|V-COMPONENT")
            "NFR-JA-002-02" = @("P3.5|V-COMPONENT"); "NFR-JA-002-03" = @("P1.3|V-COMPONENT")
            "NFR-JA-002-04" = @("P3.1d|V-COMPONENT"); "NFR-JA-002-05" = @("P11.2|V-REAL-E2E")
            "NFR-JA-003-01" = @("P2.2|V-SECURITY"); "NFR-JA-003-02" = @("P3.3|V-SECURITY")
            "NFR-JA-003-03" = @("P1.4|V-SECURITY"); "NFR-JA-003-04" = @("P6.1|V-SECURITY", "P4.3|V-WPF")
            "NFR-JA-003-05" = @("P3.3|V-SECURITY", "P10.2|V-SECURITY"); "NFR-JA-003-06" = @("P3.5|V-SECURITY")
            "NFR-JA-004-01" = @("P1.2|V-COMPONENT"); "NFR-JA-004-02" = @("P1.1|V-STATIC")
            "NFR-JA-004-03" = @("P2.1|V-CONTRACT"); "NFR-JA-004-04" = @("P1.1|V-STATIC")
            "NFR-JA-004-05" = @("P3.2|V-COMPONENT", "P2.1|V-CONTRACT")
            "NFR-JA-005-01" = @("P0A.1|V-STATIC", "P0A.9|V-LEGACY")
            "NFR-JA-005-02" = @("P0A.1|V-STATIC"); "NFR-JA-005-03" = @("P11.4|V-STATIC")
            "NFR-JA-005-04" = @("P0A.3b|V-UNIT", "P2.1|V-CONTRACT")
            "NFR-JA-005-05" = @("P0A.3c|V-FIXTURE-E2E")
            "NFR-JA-005-06" = @("P8.2|V-FIXTURE-E2E"); "NFR-JA-005-07" = @("D0.2|V-STATIC")
            "NFR-JA-006-01" = @("P1.3|V-COMPONENT"); "NFR-JA-006-02" = @("P2.1|V-CONTRACT")
            "NFR-JA-006-03" = @("P1.4|V-COMPONENT"); "NFR-JA-006-04" = @("P0A.9|V-LEGACY", "P7.1|V-COMPONENT")
        }
        if ($leaf -gt 0 -and $leafTargets.ContainsKey($Id)) {
            foreach ($targetSpec in @($leafTargets[$Id])) {
                $targetStep, $targetLane = $targetSpec -split '\|', 2
                Add-TestTarget $targets $targetStep $targetLane
            }
            if ($Id -eq "NFR-JA-005-05") {
                Add-TestTarget $targets "P0A.2" "V-REAL-E2E" "PET-VISIBILITY"
                Add-TestTarget $targets "P0A.2" "V-REAL-E2E" "KEYBOARD-SURFACE"
            }
        } else {
            $owner = switch ($group) {
                1 { "P0A.8" }; 2 { "P3.1b" }; 3 { "P1.4" }; 4 { "P1.1" }
                5 { "P0A.1" }; 6 { "P1.3" }; 7 { "D0.2" }; 8 { "D0.3" }
            }
            Add-TestTarget $targets $owner (Get-PrimaryLaneForStep $owner $Text $BaseMapping.lane)
        }
        return $targets.ToArray()
    }

    if ($Id -match '^RISK-') {
        Add-TestTarget $targets $BaseMapping.step $BaseMapping.lane
        $riskAdditionalTargets = @{
            "RISK-004" = @("P7.3|V-COMPONENT")
            "RISK-005" = @("P2.2|V-CONTRACT", "P11.1a|V-PACKAGE")
            "RISK-007" = @("P3.6|V-COMPONENT", "P4.2|V-WPF", "P8.4|V-REAL-E2E")
            "RISK-010" = @("P0A.3b|V-UNIT", "P0A.3b|V-STATIC", "P0A.9|V-LEGACY")
            "RISK-011" = @("D0.2|V-STATIC", "D0.3|V-STATIC", "D0.5|V-STATIC")
            "RISK-012" = @("D0.4|V-STATIC"); "RISK-013" = @("D0.3|V-STATIC")
            "RISK-014" = @("D0.3|V-STATIC", "D0.5|V-PACKAGE", "P11.4|V-STATIC")
        }
        if ($riskAdditionalTargets.ContainsKey($Id)) {
            foreach ($targetSpec in @($riskAdditionalTargets[$Id])) {
                $targetStep, $targetLane = $targetSpec -split '\|', 2
                Add-TestTarget $targets $targetStep $targetLane
            }
        }
        if ($Id -eq "RISK-012") {
            Add-TestTarget $targets "D0.4" "V-REAL-E2E" "HOSTED-WINDOWS"
        }
        return $targets.ToArray()
    }

    Add-TestTarget $targets $BaseMapping.step $BaseMapping.lane
    if ($Id -match '^NFR-JA-003' -and $BaseMapping.lane -ne "V-SECURITY") {
        Add-TestTarget $targets "P1.4" "V-SECURITY"
    }
    return $targets.ToArray()
}

function Get-PlannedTestId {
    param([string]$Step, [string]$Lane, [AllowNull()][string]$Scenario)

    if ($Step -eq "D0.3" -and $Lane -eq "V-STATIC") { return "D0.3-V-STATIC-001" }
    if ($Step -eq "D0.2" -and $Lane -eq "V-STATIC") { return "D0.2-V-STATIC-001" }
    if ($Step -eq "D0.2" -and $Lane -eq "V-COMPONENT") { return "D0.2-V-COMPONENT-001" }
    if (-not [string]::IsNullOrWhiteSpace($Scenario)) {
        return "$Step-$Lane-$($Scenario.ToUpperInvariant() -replace '[^A-Z0-9-]', '-')"
    }
    $scenarioByLane = @{
        "V-UNIT" = "UNIT-SPEC"; "V-COMPONENT" = "COMPONENT-FLOW"; "V-CONTRACT" = "CONTRACT-COMPATIBILITY"
        "V-WPF" = "WPF-STATE"; "V-UIA" = "UIA-JOURNEY"; "V-FIXTURE-E2E" = "FIXTURE-JOURNEY"
        "V-REAL-E2E" = "REAL-BOUNDARY-JOURNEY"; "V-SECURITY" = "SECURITY-CONTROLS"
        "V-ACCESS" = "ACCESSIBILITY-JOURNEY"; "V-PERF" = "PERFORMANCE-BUDGET"
        "V-PACKAGE" = "PACKAGE-LIFECYCLE"; "V-STATIC" = "STATIC-CONTRACT"
        "V-MANUAL-WIN" = "MANUAL-WINDOWS-BOUNDARY"; "V-LEGACY" = "LEGACY-REGRESSION"
    }
    return "$Step-$Lane-$($scenarioByLane[$Lane])"
}

$requirements = Get-Content -Raw -Encoding UTF8 -LiteralPath $requirementsPath
$checklist = Get-Content -Raw -Encoding UTF8 -LiteralPath $checklistPath
$prd = Get-Content -Raw -Encoding UTF8 -LiteralPath $prdPath
$script:requirementsLines = @(Get-Content -Encoding UTF8 -LiteralPath $requirementsPath)
$script:checklistLines = @(Get-Content -Encoding UTF8 -LiteralPath $checklistPath)
$script:prdLines = @(Get-Content -Encoding UTF8 -LiteralPath $prdPath)

function Assert-NoDuplicateSourceIds {
    param([string]$Text, [string]$Pattern, [string]$Label)
    $values = foreach ($match in [regex]::Matches($Text, $Pattern)) { $match.Groups[1].Value }
    $duplicates = @($values | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name)
    if ($duplicates.Count -gt 0) {
        throw "$Label contains duplicate normative IDs: $($duplicates -join ', ')."
    }
}

Assert-NoDuplicateSourceIds $requirements '(?m)^\|\s*((?:AR|FR-(?:PET|AI|VOICE|VISION|MEM|FUT)|PR|NFR)-\d{3})\s*\|' "REQUIREMENTS.md"
Assert-NoDuplicateSourceIds $checklist '\|\s*REQMAP-CURRENT-([A-Z]+)\s*\|' "Current aggregate locator map"
Assert-NoDuplicateSourceIds $prd '(?m)^(?:\d+\.\s+|-\s+|\|\s*)(AC-FR-\d{3}-\d{2}|NFR-JA-\d{3}(?:-\d{2})?|GATE-(?:0|[A-E])-\d{2}|RISK-\d{3})(?=[:\s|])' "Jarvis PRD"

$ids = [System.Collections.Generic.List[string]]::new()
foreach ($id in Get-UniqueMatches $requirements '(?m)^\|\s*((?:AR|FR-(?:PET|AI|VOICE|VISION|MEM|FUT)|PR|NFR)-\d{3})\s*\|' "CURRENT:") {
    $ids.Add($id)
}
foreach ($id in Get-UniqueMatches $requirements '(?<![A-Z0-9-])(AC-(?:AR|PET|AI|VOICE|VISION|MEM|FUT)-\d{3})(?![A-Z0-9-])' "CURRENT:") {
    $ids.Add($id)
}
foreach ($id in Get-UniqueMatches $checklist '\|\s*REQMAP-CURRENT-([A-Z]+)\s*\|' "CURRENT:LOC-") {
    $ids.Add($id)
}
foreach ($id in Get-UniqueMatches $prd '(?<![A-Z0-9-])(AC-FR-\d{3}-\d{2}|NFR-JA-\d{3}(?:-\d{2})?|GATE-(?:0|[A-E])-\d{2}|RISK-\d{3})(?![A-Z0-9-])' "PRD:") {
    $ids.Add($id)
}
$qualifiedIds = @(Get-OrdinalUniqueStrings @($ids))
if ($qualifiedIds.Count -ne 352) {
    throw "Expected 352 normative trace nodes, found $($qualifiedIds.Count)."
}

$entries = [System.Collections.Generic.List[object]]::new()
$testMetadataById = @{}
foreach ($qualifiedId in $qualifiedIds) {
    $namespace, $unqualifiedId = $qualifiedId -split ':', 2
    $mapping = if ($namespace -eq "CURRENT") {
        Get-CurrentMapping $unqualifiedId
    } else {
        Get-PrdMapping $unqualifiedId
    }
    $sourceRecord = Get-NormativeSourceRecord $namespace $unqualifiedId
    $disposition = if ($namespace -eq "CURRENT") {
        Get-CurrentDispositionRecord $unqualifiedId $sourceRecord.text
    } else {
        [PSCustomObject]@{
            mapId = $null
            currentStatus = $null
            effectiveDisposition = "target"
            proposedDisposition = "target"
            approvalId = $null
            approvalStatus = "not-required"
            baselineTreatment = "not-applicable"
        }
    }
    $targets = @(Get-TraceTargets $namespace $unqualifiedId $sourceRecord.text `
            $disposition.currentStatus $mapping | Sort-Object -Property step, lane, scenario)
    $behaviorIds = @($mapping.behaviorIds)
    $isProcessMemoryRequirement = $sourceRecord.text -match '(?i)\bworking set\b|\bprocess[- ]memory\b|\bidle memory regression\b'
    if ($namespace -eq "PRD" -and -not $isProcessMemoryRequirement -and
        $sourceRecord.text -match '(?i)memory|re-learn|retrieval cache') {
        $behaviorIds += @("PB-014", "PB-016")
    }
    if ($namespace -eq "PRD" -and $sourceRecord.text -match '(?i)voice|audio|transcript|push-to-talk') {
        $behaviorIds += "PB-006"
    }
    if ($namespace -eq "PRD" -and $sourceRecord.text -match '(?i)receipt|activity history|side-effect ledger') {
        $behaviorIds += @("PB-009", "PB-016")
    }
    if ($namespace -eq "PRD" -and $sourceRecord.text -match '(?i)tray|hotkey|click-through|position restore') {
        $behaviorIds += "PB-003"
    }
    if ($namespace -eq "PRD" -and $sourceRecord.text -match '(?i)Pomodoro|activity monitor|companion integration') {
        $behaviorIds += "PB-010"
    }
    if ($namespace -eq "PRD" -and $sourceRecord.text -match '(?i)\bsidecar\b|\bcross-runtime\b|\bREST\b|\bSSE\b|\bprotocol\s+compatibility\b') {
        $behaviorIds += "PB-012"
    }
    if ($unqualifiedId -eq "AC-FR-020-04") {
        $behaviorIds = @("PB-014", "PB-016")
    }
    if ($unqualifiedId -eq "AC-FR-001-02") { $behaviorIds = @("PB-005", "PB-006", "PB-018") }
    if ($unqualifiedId -eq "AC-FR-008-04") { $behaviorIds = @("PB-009", "PB-016") }
    if ($unqualifiedId -eq "NFR-JA-003-04") { $behaviorIds = @("PB-007", "PB-016", "PB-018") }
    if ($unqualifiedId -eq "NFR-JA-003-05") { $behaviorIds = @("PB-013", "PB-015", "PB-016") }
    if ($unqualifiedId -like "NFR-JA-005*" -or $unqualifiedId -eq "GATE-0-02" -or $unqualifiedId -eq "RISK-010") {
        $behaviorIds = @(1..18 | ForEach-Object { "PB-{0:D3}" -f $_ })
    }
    if ($namespace -eq "PRD" -and $sourceRecord.text -match '(?i)receipt') {
        $behaviorIds += "PB-016"
    }
    $behaviorIds = @(Get-OrdinalUniqueStrings $behaviorIds)
    $testIds = [System.Collections.Generic.List[string]]::new()
    foreach ($target in $targets) {
        $testId = Get-PlannedTestId $target.step $target.lane $target.scenario
        if (-not $testIds.Contains($testId)) { $testIds.Add($testId) }
        if (-not $testMetadataById.ContainsKey($testId)) {
            $testMetadataById[$testId] = [PSCustomObject]@{
                ownerStep = $target.step
                lane = $target.lane
            }
        }
    }

    $designAnchors = @($mapping.designAnchor)
    $uiAnchors = @($mapping.uiAnchor)
    if ($sourceRecord.text -match '(?i)approval|grant|permission') {
        $designAnchors += "12-capability-risk-and-policy-model"
        $uiAnchors += "11-approval-review"
    }
    if ($sourceRecord.text -match '(?i)receipt|activity history') {
        $designAnchors += "10-domain-model"
        $uiAnchors += "15-activity-and-receipts"
    }
    if (-not $isProcessMemoryRequirement -and $sourceRecord.text -match '(?i)memory|re-learn|retrieval cache') {
        $designAnchors += "18-canonical-memory-architecture"
        $uiAnchors += "12-memory-center"
    }
    if ($sourceRecord.text -match '(?i)keyboard|Narrator|assistive|high contrast|text scal') {
        $designAnchors += "28-verification-strategy"
        $uiAnchors += "21-accessibility-acceptance-criteria"
    }
    if ($sourceRecord.text -match '(?i)Command Center|Conversation, Today, Tasks') {
        $designAnchors += "5-target-system-context"
        $uiAnchors += "3-information-architecture"
    }
    if ($namespace -eq "PRD" -and ($unqualifiedId -match '^(AC-FR-02[1-4]-|NFR-JA-005|NFR-JA-007|NFR-JA-008|GATE-0-|RISK-01[0-4])')) {
        $designAnchors += "28-verification-strategy"
        $uiAnchors += "23-ui-quality-gates"
    }

    $evidenceName = ($qualifiedId.ToLowerInvariant() -replace '[^a-z0-9.-]', '-')
    $sourceId = if ($namespace -eq "PRD") { "PRD:JARVIS" } else { "CURRENT:REQUIREMENTS" }

    $entries.Add([PSCustomObject][ordered]@{
            id = $qualifiedId
            namespace = $namespace
            sourceId = $sourceId
            sourcePath = $sourceRecord.path
            sourceLine = $sourceRecord.line
            sourceEndLine = $sourceRecord.endLine
            sourceToken = $qualifiedId
            sourceTextSha256 = $sourceRecord.sha256
            mapId = $disposition.mapId
            currentStatus = $disposition.currentStatus
            disposition = $disposition.effectiveDisposition
            proposedDisposition = $disposition.proposedDisposition
            approvalId = $disposition.approvalId
            approvalStatus = $disposition.approvalStatus
            baselineTreatment = $disposition.baselineTreatment
            behaviorIds = $behaviorIds
            designSections = @(Get-OrdinalUniqueStrings @($designAnchors | ForEach-Object { "$designPath#$_" }))
            uiSections = @(Get-OrdinalUniqueStrings @($uiAnchors | ForEach-Object { "$uiPath#$_" }))
            checklistSteps = @(Get-OrdinalUniqueStrings @($targets.step | ForEach-Object { "$checklistPath#$(Get-ChecklistAnchorForStep $_)" }))
            testIds = @(Get-OrdinalUniqueStrings @($testIds))
            lanes = @(Get-OrdinalUniqueStrings @($targets.lane))
            evidencePaths = @("docs/verification/evidence/planned/$evidenceName.json")
        })
}

$entryById = @{}
foreach ($entry in $entries) { $entryById[$entry.id] = $entry }
foreach ($group in 1..8) {
    $parentId = "PRD:NFR-JA-{0:D3}" -f $group
    $childPrefix = "$parentId-"
    $children = @($entries | Where-Object { $_.id.StartsWith($childPrefix) })
    $parent = $entryById[$parentId]
    $parent.testIds = @(Get-OrdinalUniqueStrings @($children.testIds))
    $parent.lanes = @(Get-OrdinalUniqueStrings @($children.lanes))
    $parent.checklistSteps = @(Get-OrdinalUniqueStrings @($children.checklistSteps))
}

$testCatalog = [System.Collections.Generic.List[object]]::new()
$catalogRequirementIds = @{}
foreach ($entry in $entries) {
    foreach ($testId in $entry.testIds) {
        if (-not $catalogRequirementIds.ContainsKey($testId)) {
            $catalogRequirementIds[$testId] = [System.Collections.Generic.List[string]]::new()
        }
        if (-not $catalogRequirementIds[$testId].Contains($entry.id)) {
            $catalogRequirementIds[$testId].Add($entry.id)
        }
    }
}
foreach ($testId in @(Get-OrdinalUniqueStrings @($catalogRequirementIds.Keys))) {
    $metadata = $testMetadataById[$testId]
    if ($null -eq $metadata) { throw "Test '$testId' has no stable metadata." }
    $requirementIds = @(Get-OrdinalUniqueStrings @($catalogRequirementIds[$testId]))
    $behaviorIds = @(Get-OrdinalUniqueStrings @($requirementIds | ForEach-Object { $entryById[$_].behaviorIds }))
    $testCatalog.Add([PSCustomObject][ordered]@{
            id = $testId
            status = "planned"
            ownerStep = $metadata.ownerStep
            lane = $metadata.lane
            testKind = $(if ($metadata.ownerStep -match '^D0\.') { "gate-probe" } elseif ($metadata.lane -match 'E2E|UIA|MANUAL') { "journey" } else { "suite" })
            requirementIds = $requirementIds
            behaviorIds = $behaviorIds
            tddMode = $(if ($metadata.lane -eq "V-LEGACY") { "legacy-regression" } elseif ($metadata.ownerStep -match '^P0[AB]\.') { "characterization-first" } else { "red-first" })
            executionExpectation = $(if ($metadata.lane -eq "V-LEGACY") { "separate-legacy-regression" } elseif ($metadata.ownerStep -match '^P0[AB]\.') { "passing-baseline-or-explicit-gap" } else { "expected-red-before-implementation" })
            commandStatus = "freeze-in-step-manifest-before-red"
            oracleStatus = "freeze-in-step-manifest-before-red"
            environmentStatus = "freeze-in-step-manifest-before-red"
        })
}

$traceability = [PSCustomObject][ordered]@{
    schemaVersion = 1
    documentType = "requirement-traceability"
    generatedDate = "2026-07-22"
    baselineSha = $baselineSha
    currentRequirementsOriginSha = $currentRequirementsOriginSha
    scopeNotes = @(
        "The 352 evidence-bearing nodes comprise 59 current numbered requirements, 44 current acceptance statements, 11 current aggregate locators, 144 PRD acceptance criteria, 8 PRD NFR parents, 44 PRD NFR leaves, 28 gates, and 14 risks.",
        "PRD goals, FR parent headings, advancement rules, and open questions remain contextual grouping nodes; D0.3 requires their normative acceptance leaves, NFRs, gates, and risks.",
        "Every test and evidence path in this initial catalog is planned. A planned mapping never counts as passing evidence."
    )
    sources = @(
        [PSCustomObject][ordered]@{ id = "CURRENT:REQUIREMENTS"; path = $requirementsPath; revision = $currentRequirementsOriginSha; hashMode = "normalized-text"; sha256 = Get-NormalizedTextHash $requirementsPath "normalized-text" },
        [PSCustomObject][ordered]@{ id = "CURRENT:LOCATORS"; path = $checklistPath; revision = $baselineSha; hashMode = "normalized-checkbox-text"; sha256 = Get-NormalizedTextHash $checklistPath "normalized-checkbox-text" },
        [PSCustomObject][ordered]@{ id = "PRD:JARVIS"; path = $prdPath; revision = $baselineSha; hashMode = "normalized-text"; sha256 = Get-NormalizedTextHash $prdPath "normalized-text" },
        [PSCustomObject][ordered]@{ id = "DESIGN:JARVIS"; path = $designPath; revision = $baselineSha; hashMode = "normalized-text"; sha256 = Get-NormalizedTextHash $designPath "normalized-text" },
        [PSCustomObject][ordered]@{ id = "UI:JARVIS"; path = $uiPath; revision = $baselineSha; hashMode = "normalized-text"; sha256 = Get-NormalizedTextHash $uiPath "normalized-text" },
        [PSCustomObject][ordered]@{ id = "ADR:VERIFICATION"; path = $adr2Path; revision = $baselineSha; hashMode = "normalized-text"; sha256 = Get-NormalizedTextHash $adr2Path "normalized-text" }
    )
    dispositionMaps = @(
        [PSCustomObject][ordered]@{
            id = "REQMAP-CURRENT-V1"
            sourceId = "CURRENT:REQUIREMENTS"
            sourceRevision = $currentRequirementsOriginSha
            baselineSha = $baselineSha
            entryCount = @($entries | Where-Object { $_.namespace -eq "CURRENT" }).Count
            recordsSha256 = Get-TextHash ((Get-OrdinalUniqueStrings @($entries | Where-Object { $_.namespace -eq "CURRENT" } | ForEach-Object {
                            "$($_.id)|$($_.mapId)|$($_.currentStatus)|$($_.disposition)|$($_.proposedDisposition)|$($_.approvalId)|$($_.approvalStatus)|$($_.baselineTreatment)|$($_.sourceTextSha256)"
                        })) -join "`n")
            effectiveDefault = "preserve"
            approvalIds = @(Get-OrdinalUniqueStrings @($entries | Where-Object { $_.namespace -eq "CURRENT" -and $null -ne $_.approvalId } | ForEach-Object { $_.approvalId }))
        }
    )
    entries = @($entries)
    testCatalog = @($testCatalog)
}

$resolvedOutputPath = if ([IO.Path]::IsPathRooted($OutputPath)) {
    [IO.Path]::GetFullPath($OutputPath)
} else {
    [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
}
$parent = Split-Path -Parent $resolvedOutputPath
if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $parent
}
$json = ConvertTo-CanonicalJson $traceability
$utf8WithoutBom = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText($resolvedOutputPath, "$json`n", $utf8WithoutBom)
Write-Host "Generated $OutputPath with $($entries.Count) normative nodes and $($testCatalog.Count) planned tests/probes."

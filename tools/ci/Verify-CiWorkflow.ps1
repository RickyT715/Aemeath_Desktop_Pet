[CmdletBinding()]
param(
    [string]$WorkflowPath = ".github/workflows/ci.yml",
    [string]$RequiredChecksPath = ".github/ci/required-checks.json",
    [string]$AttributesPath = ".gitattributes"
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

function Get-WorkflowRunScripts {
    param([string]$JobBlock)

    foreach ($stepBlock in @(Get-WorkflowStepBlocks -JobBlock $JobBlock)) {
        if ($stepBlock -cnotmatch '(?m)^        shell:\s*pwsh\s*$') {
            continue
        }

        $lines = $stepBlock -split "\r?\n"
        for ($index = 0; $index -lt $lines.Count; $index++) {
            if ($lines[$index] -cnotmatch '^        run:\s*\|\s*$') {
                continue
            }

            $scriptLines = [System.Collections.Generic.List[string]]::new()
            for ($scriptIndex = $index + 1;
                $scriptIndex -lt $lines.Count;
                $scriptIndex++) {
                $line = $lines[$scriptIndex]
                if ($line.StartsWith("          ", [StringComparison]::Ordinal)) {
                    $scriptLines.Add($line.Substring(10))
                } elseif ([string]::IsNullOrWhiteSpace($line)) {
                    $scriptLines.Add("")
                } else {
                    break
                }
            }

            if ($scriptLines.Count -gt 0) {
                $scriptLines -join "`n"
            }
        }
    }
}

function Get-TeeObjectSinkPath {
    param([System.Management.Automation.Language.CommandAst]$Command)
    if ($null -eq $Command -or $Command.GetCommandName() -cne "Tee-Object" -or
        $Command.Redirections.Count -ne 0) {
        return $null
    }

    $elements = @($Command.CommandElements)
    $pathAst = $null
    if ($elements.Count -eq 2) {
        $pathAst = $elements[1]
    } elseif ($elements.Count -eq 3 -and
        $elements[1] -is [Management.Automation.Language.CommandParameterAst] -and
        $elements[1].ParameterName -ceq "FilePath") {
        $pathAst = $elements[2]
    }
    if ($pathAst -isnot [Management.Automation.Language.StringConstantExpressionAst]) {
        return $null
    }

    return [string]$pathAst.Value
}

function Test-RootPipelineIsReachable {
    param(
        [Management.Automation.Language.PipelineAst]$Pipeline,
        [Management.Automation.Language.NamedBlockAst]$EndBlock
    )

    if ($null -eq $Pipeline -or $null -eq $EndBlock -or
        -not [object]::ReferenceEquals($Pipeline.Parent, $EndBlock)) {
        return $false
    }
    foreach ($statement in @($EndBlock.Statements)) {
        if ([object]::ReferenceEquals($statement, $Pipeline)) {
            return $true
        }
        if (@("ReturnStatementAst", "ExitStatementAst", "ThrowStatementAst",
                "BreakStatementAst", "ContinueStatementAst") -ccontains
            $statement.GetType().Name) {
            return $false
        }
    }
    return $false
}

function Test-ExactTeeObjectSink {
    param(
        [System.Management.Automation.Language.CommandAst]$Command,
        [string]$ExpectedPath
    )

    $sinkPath = Get-TeeObjectSinkPath -Command $Command
    return $null -ne $sinkPath -and $sinkPath.Replace('\', '/') -ceq
        $ExpectedPath.Replace('\', '/')
}

function Test-ExecutableDiscoveryCommand {
    param(
        [string]$JobBlock,
        [string]$Command,
        [string]$ExpectedRetainedPath = ""
    )

    $configuredCommand = [regex]::Escape($Command)
    $jobPipelinePattern = "(?m)^\s{10}(?:&\s+)?$configuredCommand\s+\*>&1\s+\|\s*$"
    if ($JobBlock -cnotmatch $jobPipelinePattern) {
        return $false
    }

    $scriptPipelinePattern = "^(?:&\s+)?$configuredCommand\s+\*>&1\s+\|\s*$"
    foreach ($runScript in @(Get-WorkflowRunScripts -JobBlock $JobBlock)) {
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseInput(
            $runScript, [ref]$tokens, [ref]$parseErrors)
        if (@($parseErrors).Count -ne 0 -or $null -eq $ast.EndBlock) {
            continue
        }

        $statements = @($ast.EndBlock.Statements)
        if ($statements.Count -eq 0 -or
            $statements[0] -isnot [Management.Automation.Language.PipelineAst]) {
            continue
        }
        $pipelineElements = @($statements[0].PipelineElements)
        if ($pipelineElements.Count -ne 2 -or
            $pipelineElements[0] -isnot [Management.Automation.Language.CommandAst] -or
            $pipelineElements[1] -isnot [Management.Automation.Language.CommandAst]) {
            continue
        }

        $scriptLines = $runScript -split "\r?\n"
        $commandAstPattern = "^(?:&\s+)?$configuredCommand\s+\*>&1\s*$"
        $commandAst = $pipelineElements[0]
        $lineIndex = $commandAst.Extent.StartLineNumber - 1
        if ($commandAst.Extent.Text -cmatch $commandAstPattern -and
            $lineIndex -ge 0 -and $lineIndex -lt $scriptLines.Count -and
            $scriptLines[$lineIndex] -cmatch $scriptPipelinePattern -and
            ([string]::IsNullOrWhiteSpace($ExpectedRetainedPath) -or
                (Test-ExactTeeObjectSink -Command $pipelineElements[1] `
                    -ExpectedPath $ExpectedRetainedPath))) {
            return $true
        }
    }

    return $false
}

function Test-DiscoveryEvidenceSink {
    param(
        [string]$JobBlock,
        [string]$ExpectedPath
    )

    foreach ($runScript in @(Get-WorkflowRunScripts -JobBlock $JobBlock)) {
        $tokens = $null
        $parseErrors = $null
        $ast = [Management.Automation.Language.Parser]::ParseInput(
            $runScript, [ref]$tokens, [ref]$parseErrors)
        if (@($parseErrors).Count -ne 0) {
            continue
        }

        $teeCommands = @($ast.FindAll({
                    param($node)
                    $node -is [Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -ceq "Tee-Object"
                }, $true))
        foreach ($teeCommand in $teeCommands) {
            $pipeline = $teeCommand.Parent
            if ($pipeline -isnot [Management.Automation.Language.PipelineAst] -or
                $pipeline.PipelineElements.Count -ne 2 -or
                $pipeline.PipelineElements[$pipeline.PipelineElements.Count - 1] -ne $teeCommand -or
                $teeCommand.Redirections.Count -ne 0 -or
                -not (Test-RootPipelineIsReachable -Pipeline $pipeline `
                    -EndBlock $ast.EndBlock)) {
                continue
            }

            if (Test-ExactTeeObjectSink -Command $teeCommand -ExpectedPath $ExpectedPath) {
                return $true
            }
        }
    }

    return $false
}

function Get-JsonStringEndIndex {
    param(
        [string]$Json,
        [int]$StartIndex
    )

    if ($StartIndex -ge $Json.Length -or $Json[$StartIndex] -ne '"') {
        throw "Expected a JSON string token."
    }
    $escaped = $false
    for ($index = $StartIndex + 1; $index -lt $Json.Length; $index++) {
        $character = $Json[$index]
        if ($escaped) {
            $escaped = $false
        } elseif ($character -eq '\') {
            $escaped = $true
        } elseif ($character -eq '"') {
            return $index + 1
        }
    }
    throw "JSON string token is unterminated."
}

function Get-JsonValueEndIndex {
    param(
        [string]$Json,
        [int]$StartIndex
    )

    $index = $StartIndex
    while ($index -lt $Json.Length -and [char]::IsWhiteSpace($Json[$index])) {
        $index++
    }
    if ($index -ge $Json.Length) {
        throw "JSON value is missing."
    }
    if ($Json[$index] -eq '"') {
        return Get-JsonStringEndIndex -Json $Json -StartIndex $index
    }
    if ($Json[$index] -ne '{' -and $Json[$index] -ne '[') {
        while ($index -lt $Json.Length -and
            $Json[$index] -ne ',' -and $Json[$index] -ne '}' -and $Json[$index] -ne ']') {
            $index++
        }
        return $index
    }

    $closers = [System.Collections.Generic.List[char]]::new()
    $closers.Add($(if ($Json[$index] -eq '{') { '}' } else { ']' }))
    for ($index++; $index -lt $Json.Length; $index++) {
        $character = $Json[$index]
        if ($character -eq '"') {
            $index = (Get-JsonStringEndIndex -Json $Json -StartIndex $index) - 1
            continue
        }
        if ($character -eq '{' -or $character -eq '[') {
            $closers.Add($(if ($character -eq '{') { '}' } else { ']' }))
            continue
        }
        if ($character -eq '}' -or $character -eq ']') {
            $last = $closers.Count - 1
            if ($last -lt 0 -or $closers[$last] -ne $character) {
                throw "JSON containers are unbalanced."
            }
            $closers.RemoveAt($last)
            if ($closers.Count -eq 0) {
                return $index + 1
            }
        }
    }
    throw "JSON container is unterminated."
}

function Get-JsonObjectPropertyRecords {
    param([string]$JsonObject)

    $json = $JsonObject.Trim()
    if ($json.Length -lt 2 -or $json[0] -ne '{') {
        throw "Expected a JSON object."
    }
    $records = [System.Collections.Generic.List[object]]::new()
    $index = 1
    while ($index -lt $json.Length) {
        while ($index -lt $json.Length -and [char]::IsWhiteSpace($json[$index])) {
            $index++
        }
        if ($index -lt $json.Length -and $json[$index] -eq '}') {
            return [object[]]$records.ToArray()
        }
        $nameStart = $index
        $nameEnd = Get-JsonStringEndIndex -Json $json -StartIndex $nameStart
        $rawName = $json.Substring($nameStart, $nameEnd - $nameStart)
        $name = $rawName | ConvertFrom-Json -ErrorAction Stop
        if (-not ($name -is [string])) {
            throw "JSON property name is not a string."
        }
        $index = $nameEnd
        while ($index -lt $json.Length -and [char]::IsWhiteSpace($json[$index])) {
            $index++
        }
        if ($index -ge $json.Length -or $json[$index] -ne ':') {
            throw "JSON property separator is missing."
        }
        $index++
        while ($index -lt $json.Length -and [char]::IsWhiteSpace($json[$index])) {
            $index++
        }
        $valueStart = $index
        $valueEnd = Get-JsonValueEndIndex -Json $json -StartIndex $valueStart
        $records.Add([PSCustomObject]@{
                Name = [string]$name
                RawValue = $json.Substring($valueStart, $valueEnd - $valueStart).Trim()
            })
        $index = $valueEnd
        while ($index -lt $json.Length -and [char]::IsWhiteSpace($json[$index])) {
            $index++
        }
        if ($index -lt $json.Length -and $json[$index] -eq ',') {
            $index++
            continue
        }
        if ($index -lt $json.Length -and $json[$index] -eq '}') {
            return [object[]]$records.ToArray()
        }
        throw "JSON object delimiter is invalid."
    }
    throw "JSON object is unterminated."
}

function Get-JsonArrayElementTexts {
    param([string]$JsonArray)

    $json = $JsonArray.Trim()
    if ($json.Length -lt 2 -or $json[0] -ne '[') {
        throw "Expected a JSON array."
    }
    $elements = [System.Collections.Generic.List[string]]::new()
    $index = 1
    while ($index -lt $json.Length) {
        while ($index -lt $json.Length -and [char]::IsWhiteSpace($json[$index])) {
            $index++
        }
        if ($index -lt $json.Length -and $json[$index] -eq ']') {
            return [string[]]$elements.ToArray()
        }
        $valueStart = $index
        $valueEnd = Get-JsonValueEndIndex -Json $json -StartIndex $valueStart
        $elements.Add($json.Substring($valueStart, $valueEnd - $valueStart).Trim())
        $index = $valueEnd
        while ($index -lt $json.Length -and [char]::IsWhiteSpace($json[$index])) {
            $index++
        }
        if ($index -lt $json.Length -and $json[$index] -eq ',') {
            $index++
            continue
        }
        if ($index -lt $json.Length -and $json[$index] -eq ']') {
            return [string[]]$elements.ToArray()
        }
        throw "JSON array delimiter is invalid."
    }
    throw "JSON array is unterminated."
}

function Test-RawDiscoveryResultShapes {
    param([string]$ManifestContent)

    $rootProperties = @(Get-JsonObjectPropertyRecords -JsonObject $ManifestContent)
    $jobsProperties = @($rootProperties | Where-Object { $_.Name -ceq "jobs" })
    if ($jobsProperties.Count -eq 0) {
        throw "Raw manifest jobs member is missing."
    }
    $jobsProperty = $jobsProperties[$jobsProperties.Count - 1]
    if (-not $jobsProperty.RawValue.TrimStart().StartsWith(
            "[", [StringComparison]::Ordinal)) {
        throw "Raw manifest jobs member must be an array."
    }
    $rootShapeInvalid = $jobsProperties.Count -ne 1

    $requiredFields = [System.Collections.Generic.HashSet[string]]::new(
        [StringComparer]::Ordinal)
    foreach ($field in @("resultId", "evidencePath", "minimum", "includedInJobMinimum")) {
        $null = $requiredFields.Add($field)
    }
    foreach ($rawJob in @(Get-JsonArrayElementTexts -JsonArray $jobsProperty.RawValue)) {
        if (-not $rawJob.TrimStart().StartsWith("{", [StringComparison]::Ordinal)) {
            throw "Raw manifest jobs elements must be objects."
        }
        $jobProperties = @(Get-JsonObjectPropertyRecords -JsonObject $rawJob)
        $idProperties = @($jobProperties | Where-Object { $_.Name -ceq "id" })
        $discoveryProperties = @($jobProperties | Where-Object { $_.Name -ceq "discovery" })
        if ($idProperties.Count -eq 0) {
            throw "Raw manifest job id member is missing."
        }
        $idProperty = $idProperties[$idProperties.Count - 1]
        $jobIdValue = $idProperty.RawValue | ConvertFrom-Json -ErrorAction Stop
        if (-not ($jobIdValue -is [string]) -or
            [string]::IsNullOrWhiteSpace([string]$jobIdValue)) {
            throw "Raw manifest job id member must be a non-empty string."
        }
        $jobId = [string]$jobIdValue
        $shapeInvalid = $rootShapeInvalid -or $idProperties.Count -ne 1 -or
            $discoveryProperties.Count -ne 1
        if ($discoveryProperties.Count -eq 0) {
            Add-ContractFailure "DISCOVERY-RESULT-SHAPE: $jobId"
            continue
        }
        $discoveryProperty = $discoveryProperties[$discoveryProperties.Count - 1]
        if (-not $discoveryProperty.RawValue.TrimStart().StartsWith(
                "{", [StringComparison]::Ordinal)) {
            Add-ContractFailure "DISCOVERY-RESULT-SHAPE: $jobId"
            continue
        }
        $discoveryFields = @(Get-JsonObjectPropertyRecords `
                -JsonObject $discoveryProperty.RawValue)
        $resultsProperties = @($discoveryFields | Where-Object { $_.Name -ceq "results" })
        if ($resultsProperties.Count -gt 1) {
            $shapeInvalid = $true
        }
        if ($resultsProperties.Count -eq 0) {
            if ($shapeInvalid) {
                Add-ContractFailure "DISCOVERY-RESULT-SHAPE: $jobId"
            }
            continue
        }
        $resultsProperty = $resultsProperties[$resultsProperties.Count - 1]
        if (-not $resultsProperty.RawValue.TrimStart().StartsWith(
                "[", [StringComparison]::Ordinal)) {
            if ($shapeInvalid) {
                Add-ContractFailure "DISCOVERY-RESULT-SHAPE: $jobId"
            }
            continue
        }

        foreach ($rawResult in @(Get-JsonArrayElementTexts `
                    -JsonArray $resultsProperty.RawValue)) {
            if (-not $rawResult.TrimStart().StartsWith("{", [StringComparison]::Ordinal)) {
                $shapeInvalid = $true
                continue
            }
            $resultProperties = @(Get-JsonObjectPropertyRecords -JsonObject $rawResult)
            $fieldNames = [System.Collections.Generic.HashSet[string]]::new(
                [StringComparer]::Ordinal)
            $shapeValid = $resultProperties.Count -eq $requiredFields.Count
            foreach ($property in $resultProperties) {
                if (-not $fieldNames.Add([string]$property.Name)) {
                    $shapeValid = $false
                }
            }
            foreach ($requiredField in $requiredFields) {
                if (-not $fieldNames.Contains($requiredField)) {
                    $shapeValid = $false
                }
            }
            if (-not $shapeValid) {
                $shapeInvalid = $true
            }
        }
        if ($shapeInvalid) {
            Add-ContractFailure "DISCOVERY-RESULT-SHAPE: $jobId"
        }
    }
}

function Test-PortableRelativePath {
    param([string]$Path)

    return -not [string]::IsNullOrWhiteSpace($Path) -and
        -not [IO.Path]::IsPathRooted($Path) -and
        $Path -notmatch '^[A-Za-z]:' -and
        $Path -notmatch '^[\\/]' -and
        $Path -notmatch '(^|[\\/])\.\.([\\/]|$)'
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

if (-not (Test-Path -LiteralPath $AttributesPath -PathType Leaf)) {
    Add-ContractFailure "dependency evidence Git attribute file is missing: $AttributesPath"
} else {
    $attributeLines = @(Get-Content -Encoding UTF8 -LiteralPath $AttributesPath |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith("#") })
    $dependencyAttributeLines = @($attributeLines | Where-Object {
            $_ -match '^docs/verification/dependencies/\*\*\s+'
        })
    if ($dependencyAttributeLines.Count -ne 1 -or
        $dependencyAttributeLines[0] -cne "docs/verification/dependencies/** -text") {
        Add-ContractFailure "dependency evidence must be declared -text"
    }
}

if (-not (Test-Path -LiteralPath $RequiredChecksPath -PathType Leaf)) {
    Add-ContractFailure "required-check manifest is missing: $RequiredChecksPath"
} else {
    try {
        $requiredChecksContent = Get-Content -Raw -LiteralPath $RequiredChecksPath
        Test-RawDiscoveryResultShapes -ManifestContent $requiredChecksContent
        $requiredChecks = $requiredChecksContent | ConvertFrom-Json
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
            if ($job.id -in @("verification-contracts", "dependency-qualification")) {
                Assert-ContractMatch `
                    "historical-baseline checkout must fetch full history: $($job.id)" `
                    "(?ms)uses:\s*actions/checkout@[0-9a-f]{40}.+?with:\s*\r?\n\s+ref:\s*\$\{\{\s*env\.SOURCE_SHA\s*\}\}\s*\r?\n\s+fetch-depth:\s*0\s*$" `
                    $jobBlock
            }
            Assert-ContractNotMatch "required job is advisory: $($job.id)" "continue-on-error:\s*true" $jobBlock

            if ($job.executionModel -ne "single" -or [int]$job.expectedInstances -ne 1) {
                Add-ContractFailure "D0.2 job must declare one single execution instance: $($job.id)"
            }

            Assert-ContractNotMatch "single-instance job unexpectedly defines a matrix: $($job.id)" "(?m)^\s+matrix:\s*$" $jobBlock

            $safeEvidencePaths = [System.Collections.Generic.HashSet[string]]::new(
                [StringComparer]::Ordinal)
            foreach ($evidenceFile in @($job.evidenceFiles)) {
                $declaredPath = [string]$evidenceFile.path
                if (Test-PortableRelativePath -Path $declaredPath) {
                    $null = $safeEvidencePaths.Add($declaredPath)
                }
            }

            if ([string]::IsNullOrWhiteSpace($job.discovery.rationale)) {
                Add-ContractFailure "required job must explain its discovery contract: $($job.id)"
            } elseif ($job.discovery.kind -eq "not-applicable") {
                $notApplicableMinimum = $job.discovery.minimumDiscoveredTests
                $notApplicableResultsProperty = $job.discovery.PSObject.Properties["results"]
                $notApplicableResultsAreValid = $null -eq $notApplicableResultsProperty -or
                    ($notApplicableResultsProperty.Value -is [array] -and
                    @($notApplicableResultsProperty.Value).Count -eq 0)
                if ((-not ($notApplicableMinimum -is [int]) -and
                        -not ($notApplicableMinimum -is [long])) -or
                    [long]$notApplicableMinimum -ne 0 -or
                    -not $notApplicableResultsAreValid) {
                    Add-ContractFailure "DISCOVERY-NOT-APPLICABLE: $($job.id)"
                }
            } elseif ($job.discovery.kind -eq "powershell-probe") {
                $parentMinimum = $job.discovery.minimumDiscoveredTests
                $parentMinimumIsInteger = $parentMinimum -is [int] -or
                    $parentMinimum -is [long]
                $includedPaths = @(@($job.discovery.results) | Where-Object {
                            $_.includedInJobMinimum -is [bool] -and
                            $_.includedInJobMinimum -eq $true -and
                            $_.evidencePath -is [string]
                        } | ForEach-Object {
                            ([string]$_.evidencePath).Replace('\', '/')
                        } | Select-Object -Unique)
                $expectedRetainedPath = ""
                if ($includedPaths.Count -eq 1) {
                    $artifactRoot = ([string]$job.artifactPath).Replace('\', '/').TrimEnd('/')
                    $expectedRetainedPath = "$artifactRoot/$($includedPaths[0])"
                }
                if ([string]::IsNullOrWhiteSpace($job.discovery.command)) {
                    Add-ContractFailure "PowerShell probe discovery contract is incomplete: $($job.id)"
                } elseif (-not (Test-ExecutableDiscoveryCommand -JobBlock $jobBlock `
                        -Command ([string]$job.discovery.command) `
                        -ExpectedRetainedPath $expectedRetainedPath)) {
                    Add-ContractFailure "DISCOVERY-COMMAND-EXECUTABLE: $($job.id)"
                }

                $resultsProperty = $job.discovery.PSObject.Properties["results"]
                $resultsAreArray = $null -ne $resultsProperty -and
                    $resultsProperty.Value -is [array]
                $results = if ($resultsAreArray) {
                    @($resultsProperty.Value)
                } else {
                    @()
                }
                if (-not $resultsAreArray -or $results.Count -eq 0) {
                    Add-ContractFailure "DISCOVERY-RESULTS-REQUIRED: $($job.id)"
                } else {
                    $resultIds = [System.Collections.Generic.HashSet[string]]::new(
                        [StringComparer]::Ordinal)
                    $requiredResultFields = [System.Collections.Generic.HashSet[string]]::new(
                        [StringComparer]::Ordinal)
                    foreach ($requiredField in @(
                            "resultId", "evidencePath", "minimum", "includedInJobMinimum")) {
                        $null = $requiredResultFields.Add($requiredField)
                    }

                    $includedMinimum = [long]0
                    $allResultsValid = $true
                    $sumOverflowed = $false
                    foreach ($result in $results) {
                        $fieldNames = [System.Collections.Generic.HashSet[string]]::new(
                            [StringComparer]::Ordinal)
                        foreach ($property in @($result.PSObject.Properties)) {
                            $null = $fieldNames.Add([string]$property.Name)
                        }
                        $shapeValid = $fieldNames.Count -eq $requiredResultFields.Count
                        foreach ($requiredField in $requiredResultFields) {
                            if (-not $fieldNames.Contains($requiredField)) {
                                $shapeValid = $false
                            }
                        }
                        if (-not $shapeValid) {
                            Add-ContractFailure "DISCOVERY-RESULT-SHAPE: $($job.id)"
                            $allResultsValid = $false
                            continue
                        }

                        $resultIdValue = $result.resultId
                        $resultId = [string]$resultIdValue
                        if (-not ($resultIdValue -is [string]) -or
                            [string]::IsNullOrWhiteSpace($resultId)) {
                            Add-ContractFailure "DISCOVERY-RESULT-ID: $($job.id)"
                            $allResultsValid = $false
                        } elseif (-not $resultIds.Add($resultId)) {
                            Add-ContractFailure "DISCOVERY-RESULT-DUPLICATE: $($job.id): $resultId"
                            $allResultsValid = $false
                        }

                        $evidencePathValue = $result.evidencePath
                        $evidencePath = [string]$evidencePathValue
                        if (-not ($evidencePathValue -is [string]) -or
                            -not (Test-PortableRelativePath -Path $evidencePath) -or
                            -not $safeEvidencePaths.Contains($evidencePath)) {
                            Add-ContractFailure "DISCOVERY-RESULT-EVIDENCE: $($job.id): $evidencePath"
                            $allResultsValid = $false
                        } else {
                            $artifactRoot = ([string]$job.artifactPath).
                                Replace('\', '/').TrimEnd('/')
                            $expectedSinkPath = "$artifactRoot/$evidencePath"
                        }
                        if ($allResultsValid -and
                            -not (Test-DiscoveryEvidenceSink -JobBlock $jobBlock `
                                -ExpectedPath $expectedSinkPath)) {
                            Add-ContractFailure "DISCOVERY-RESULT-SINK: $($job.id): $evidencePath"
                            $allResultsValid = $false
                        }

                        $minimum = $result.minimum
                        $minimumIsInteger = $minimum -is [int] -or $minimum -is [long]
                        if (-not $minimumIsInteger -or [long]$minimum -le 0) {
                            Add-ContractFailure "DISCOVERY-RESULT-MINIMUM: $($job.id): $resultId"
                            $allResultsValid = $false
                        }

                        $inclusion = $result.includedInJobMinimum
                        if (-not ($inclusion -is [bool])) {
                            Add-ContractFailure "DISCOVERY-RESULT-INCLUSION: $($job.id): $resultId"
                            $allResultsValid = $false
                        } elseif ($inclusion -eq $true -and $minimumIsInteger -and
                            [long]$minimum -gt 0) {
                            if ($includedMinimum -gt [long]::MaxValue - [long]$minimum) {
                                $sumOverflowed = $true
                                $allResultsValid = $false
                            } else {
                                $includedMinimum += [long]$minimum
                            }
                        }
                    }

                    if (-not $parentMinimumIsInteger -or [long]$parentMinimum -le 0 -or
                        $sumOverflowed -or
                        ($allResultsValid -and [long]$parentMinimum -ne $includedMinimum)) {
                        Add-ContractFailure "DISCOVERY-CONTRACT-TOTAL: $($job.id)"
                    }
                }
            } else {
                Add-ContractFailure "required job has an unsupported discovery kind: $($job.id)"
            }

            if ([string]::IsNullOrWhiteSpace($job.artifactPrefix)) {
                Add-ContractFailure "required job has no artifact prefix: $($job.id)"
            } else {
                if (-not $artifactPrefixes.Add([string]$job.artifactPrefix)) {
                    Add-ContractFailure "artifact prefix is duplicated: $($job.artifactPrefix)"
                }

            }

            if (-not (Test-PortableRelativePath -Path ([string]$job.artifactPath))) {
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
                if ($job.id -eq "dependency-qualification") {
                    Assert-ContractMatch `
                        "upload step does not require successful evidence audit: $($job.id)" `
                        "(?m)^\s{8}if:\s*always\(\)\s*&&\s*steps\.evidence_audit\.outcome\s*==\s*'success'\s*$" `
                        $uploadStep
                    Assert-ContractMatch `
                        "dependency evidence audit step is missing or not unconditional" `
                        "(?ms)^\s{6}-\s+name:\s*Audit complete or partial dependency evidence\s*\r?\n\s{8}id:\s*evidence_audit\s*\r?\n\s{8}if:\s*always\(\)\s*$" `
                        $jobBlock
                    Assert-ContractMatch `
                        "dependency evidence audit does not execute AuditEvidence mode" `
                        "(?m)^\s+-Mode\s+AuditEvidence(?:\s|$)" `
                        $jobBlock
                } else {
                    Assert-ContractMatch "upload step does not use if: always(): $($job.id)" "(?m)^\s{8}if:\s*always\(\)\s*$" $uploadStep
                }
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

            $evidencePaths = [System.Collections.Generic.HashSet[string]]::new(
                [StringComparer]::Ordinal)
            foreach ($evidenceFile in @($job.evidenceFiles)) {
                $path = [string]$evidenceFile.path
                if (-not (Test-PortableRelativePath -Path $path) -or
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
        "tools/ci/Test-DependencyEvidenceAttributes.ps1",
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

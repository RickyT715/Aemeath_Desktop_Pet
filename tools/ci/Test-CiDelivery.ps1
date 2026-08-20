[CmdletBinding()]
param(
    [string]$WorkflowPath = ".github/workflows/ci.yml",
    [string]$RequiredChecksPath = ".github/ci/required-checks.json",
    [string]$AttributesPath = ".gitattributes"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$verifyScript = Join-Path $PSScriptRoot "Verify-CiWorkflow.ps1"
$evidenceAttributeTest = Join-Path $PSScriptRoot "Test-DependencyEvidenceAttributes.ps1"
$contractModule = Join-Path $PSScriptRoot "CiDeliveryContract.psm1"
$waitScript = Join-Path $PSScriptRoot "Wait-ForCi.ps1"
Import-Module $contractModule -Force

$workflow = Get-Content -Raw -LiteralPath $WorkflowPath
$manifestText = Get-Content -Raw -LiteralPath $RequiredChecksPath
$attributes = Get-Content -Raw -LiteralPath $AttributesPath
$requiredChecks = $manifestText | ConvertFrom-Json
$enginePath = (Get-Process -Id $PID).Path
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ("aemeath-ci-contract-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot | Out-Null
$staticContractCount = 0
$resultContractCount = 0
$staticReviewFixAccepted = [System.Collections.Generic.List[string]]::new()
$discoveryMarkerPrefix = "AEMEATH_CI_DISCOVERY_V1="
$d03FixtureMarker = $discoveryMarkerPrefix +
    '{"schemaVersion":1,"resultId":"D0.3-V-STATIC-001","sourceSha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","actualDiscovery":24,"failed":0,"skipped":0}'
$ubuntuFixtureMarker = $discoveryMarkerPrefix +
    '{"schemaVersion":1,"resultId":"D0.5-V-STATIC-UBUNTU","sourceSha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","actualDiscovery":45,"failed":0,"skipped":0}'

function Write-StaticContractPass {
    param([string]$Message)

    $script:staticContractCount++
    Write-Host "PASS $Message"
}

function Write-ResultContractPass {
    param([string]$Message)

    $script:resultContractCount++
    Write-Host "PASS $Message"
}

function Invoke-StaticContract {
    param(
        [string]$WorkflowContent,
        [object]$Manifest,
        [string]$ManifestContent,
        [string]$AttributesContent = $script:attributes
    )

    $caseId = [guid]::NewGuid().ToString("N")
    $caseRoot = Join-Path $tempRoot $caseId
    New-Item -ItemType Directory -Path $caseRoot | Out-Null
    $workflowFile = Join-Path $caseRoot "ci.yml"
    $manifestFile = Join-Path $caseRoot "required-checks.json"
    $attributesFile = Join-Path $caseRoot ".gitattributes"
    Set-Content -LiteralPath $workflowFile -Value $WorkflowContent -Encoding UTF8
    if ($PSBoundParameters.ContainsKey("ManifestContent")) {
        Set-Content -LiteralPath $manifestFile -Value $ManifestContent -Encoding UTF8
    } else {
        $Manifest | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $manifestFile -Encoding UTF8
    }
    Set-Content -LiteralPath $attributesFile -Value $AttributesContent -Encoding UTF8

    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $enginePath -NoProfile -ExecutionPolicy Bypass -File $verifyScript `
            -WorkflowPath $workflowFile -RequiredChecksPath $manifestFile `
            -AttributesPath $attributesFile 2>&1
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
        [string]$ExpectedMessage,
        [string]$AttributesContent = $script:attributes
    )

    $result = Invoke-StaticContract -WorkflowContent $WorkflowContent -Manifest $Manifest `
        -AttributesContent $AttributesContent
    $normalizedOutput = Normalize-DiagnosticText $result.Output
    if ($result.ExitCode -eq 0 -or
        $normalizedOutput.IndexOf($ExpectedMessage, [StringComparison]::Ordinal) -lt 0) {
        throw "Static mutation '$Name' was not rejected with '$ExpectedMessage'. Output: $($result.Output)"
    }

    Write-StaticContractPass "static mutation: $Name"
}

function Invoke-StaticCommandMutationCensus {
    $d03Pipeline = "          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |"
    if ($workflow.IndexOf($d03Pipeline, [StringComparison]::Ordinal) -lt 0) {
        throw "Could not create D0.3 non-executable command mutations."
    }

    $cases = @(
        [PSCustomObject]@{
            Id = "D02R-SC01"
            Name = "quoted command"
            Replacement = @'
          Write-Output './tools/verification/Test-VerificationContracts.ps1'
          Write-Output 'AEMEATH_CI_DISCOVERY_V1={"schemaVersion":1,"resultId":"D0.3-V-STATIC-001","sourceSha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","actualDiscovery":24,"failed":0,"skipped":0}'
          Write-Output 'fabricated D0.3 output' *>&1 |
'@.TrimEnd()
        }
        [PSCustomObject]@{
            Id = "D02R-SC02"
            Name = "commented command"
            Replacement = @'
          # ./tools/verification/Test-VerificationContracts.ps1
          Write-Output 'fabricated D0.3 output' *>&1 |
'@.TrimEnd()
        }
        [PSCustomObject]@{
            Id = "D02R-SC03"
            Name = "environment-value command"
            Replacement = @'
          $env:D03_COMMAND = './tools/verification/Test-VerificationContracts.ps1'
          Write-Output 'fabricated D0.3 output' *>&1 |
'@.TrimEnd()
        }
        [PSCustomObject]@{
            Id = "D02R-SC04"
            Name = "marker-payload command"
            Replacement = @'
          Write-Output 'AEMEATH_CI_DISCOVERY_V1={"schemaVersion":1,"resultId":"D0.3-V-STATIC-001","sourceSha":"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa","actualDiscovery":24,"failed":0,"skipped":0,"command":"./tools/verification/Test-VerificationContracts.ps1"}'
          Write-Output 'fabricated D0.3 output' *>&1 |
'@.TrimEnd()
        }
        [PSCustomObject]@{
            Id = "D02R-SC05"
            Name = "here-string exact pipeline"
            Replacement = @'
          $fabricatedCommand = @'
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
          '@
          Write-Output $fabricatedCommand *>&1 |
'@.TrimEnd()
        }
        [PSCustomObject]@{
            Id = "D02R-SC06"
            Name = "block-comment exact pipeline"
            Replacement = @'
          <#
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
          #>
          Write-Output 'fabricated D0.3 output' *>&1 |
'@.TrimEnd()
        }
    )

    $accepted = [System.Collections.Generic.List[string]]::new()
    foreach ($case in $cases) {
        $mutatedWorkflow = $workflow.Replace($d03Pipeline, [string]$case.Replacement)
        if ($mutatedWorkflow -ceq $workflow) {
            throw "Could not create D0.3 command mutation '$($case.Id)'."
        }

        $result = Invoke-StaticContract -WorkflowContent $mutatedWorkflow -Manifest (Copy-Manifest)
        $normalizedOutput = Normalize-DiagnosticText $result.Output
        $expectedMessage = "DISCOVERY-COMMAND-EXECUTABLE: verification-contracts"
        if ($result.ExitCode -eq 0) {
            $accepted.Add([string]$case.Id)
            Write-Host "RED accepted static command mutation: $($case.Id) $($case.Name)"
        } elseif ($normalizedOutput.IndexOf($expectedMessage, [StringComparison]::Ordinal) -lt 0) {
            throw "Static command mutation '$($case.Id)' failed for an unrelated reason. Output: $($result.Output)"
        } else {
            Write-StaticContractPass "static command mutation: $($case.Id) $($case.Name)"
        }
    }

    if ($accepted.Count -gt 0) {
        throw "D0.2R command intended RED accepted mutations: $($accepted -join ', ')"
    }
}

function Get-ManifestJobById {
    param(
        [object]$Manifest,
        [string]$JobId
    )

    $matches = @($Manifest.jobs | Where-Object {
            [string]::Equals([string]$_.id, $JobId, [StringComparison]::Ordinal)
        })
    if ($matches.Count -ne 1) {
        throw "Manifest job '$JobId' is not unique."
    }
    return $matches[0]
}

function Invoke-StaticResultSchemaMutationCensus {
    $cases = @(
        [PSCustomObject]@{
            Id = "D02R-SS01"; Name = "missing results"
            ExpectedMessage = "DISCOVERY-RESULTS-REQUIRED: verification-contracts"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.PSObject.Properties.Remove("results")
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS02"; Name = "empty results"
            ExpectedMessage = "DISCOVERY-RESULTS-REQUIRED: verification-contracts"
            Mutate = {
                param($manifest)
                (Get-ManifestJobById $manifest "verification-contracts").discovery.results = @()
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS03"; Name = "missing result field"
            ExpectedMessage = "DISCOVERY-RESULT-SHAPE: verification-contracts"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].PSObject.Properties.Remove("includedInJobMinimum")
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS04"; Name = "extra result field"
            ExpectedMessage = "DISCOVERY-RESULT-SHAPE: verification-contracts"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0] | Add-Member -NotePropertyName extra -NotePropertyValue 0
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS05"; Name = "blank result ID"
            ExpectedMessage = "DISCOVERY-RESULT-ID: verification-contracts"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].resultId = ""
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS06"; Name = "ordinal duplicate result ID"
            ExpectedMessage = "DISCOVERY-RESULT-DUPLICATE: verification-contracts: D0.3-V-STATIC-001"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[1].resultId = "D0.3-V-STATIC-001"
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS07"; Name = "safe undeclared result evidence"
            ExpectedMessage = "DISCOVERY-RESULT-EVIDENCE: verification-contracts: not-retained.log"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].evidencePath = "not-retained.log"
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS08"; Name = "traversal result evidence"
            ExpectedMessage = "DISCOVERY-RESULT-EVIDENCE: verification-contracts: ../escape.log"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].evidencePath = "../escape.log"
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS09"; Name = "portable rooted result evidence"
            ExpectedMessage = "DISCOVERY-RESULT-EVIDENCE: verification-contracts: /escape.log"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].evidencePath = "/escape.log"
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS10"; Name = "zero result minimum"
            ExpectedMessage = "DISCOVERY-RESULT-MINIMUM: verification-contracts: D0.3-V-STATIC-001"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].minimum = [int]0
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS11"; Name = "string result minimum"
            ExpectedMessage = "DISCOVERY-RESULT-MINIMUM: verification-contracts: D0.3-V-STATIC-001"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].minimum = "24"
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS12"; Name = "decimal result minimum"
            ExpectedMessage = "DISCOVERY-RESULT-MINIMUM: verification-contracts: D0.3-V-STATIC-001"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].minimum = [double]24.5
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS13"; Name = "string result inclusion"
            ExpectedMessage = "DISCOVERY-RESULT-INCLUSION: verification-contracts: D0.3-V-STATIC-001"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].includedInJobMinimum = "true"
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS14"; Name = "numeric result inclusion"
            ExpectedMessage = "DISCOVERY-RESULT-INCLUSION: verification-contracts: D0.3-V-STATIC-001"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "verification-contracts"
                $job.discovery.results[0].includedInJobMinimum = 1
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS15"; Name = "included minimum sum mismatch"
            ExpectedMessage = "DISCOVERY-CONTRACT-TOTAL: verification-contracts"
            Mutate = {
                param($manifest)
                (Get-ManifestJobById $manifest `
                    "verification-contracts").discovery.minimumDiscoveredTests = 25
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS16"; Name = "not-applicable results"
            ExpectedMessage = "DISCOVERY-NOT-APPLICABLE: dotnet-build"
            Mutate = {
                param($manifest)
                $job = Get-ManifestJobById $manifest "dotnet-build"
                $job.discovery | Add-Member -NotePropertyName results -NotePropertyValue @(
                    [PSCustomObject]@{
                        resultId = "D0.2R-NOT-APPLICABLE"
                        evidencePath = "source-identity.json"
                        minimum = 1
                        includedInJobMinimum = $false
                    })
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS17"; Name = "not-applicable integer floor"
            ExpectedMessage = "DISCOVERY-NOT-APPLICABLE: dotnet-build"
            Mutate = {
                param($manifest)
                (Get-ManifestJobById $manifest "dotnet-build").discovery.minimumDiscoveredTests = 1
            }
        },
        [PSCustomObject]@{
            Id = "D02R-SS18"; Name = "not-applicable noninteger floor"
            ExpectedMessage = "DISCOVERY-NOT-APPLICABLE: dotnet-build"
            Mutate = {
                param($manifest)
                (Get-ManifestJobById $manifest "dotnet-build").discovery.minimumDiscoveredTests = "0"
            }
        }
    )

    $accepted = [System.Collections.Generic.List[string]]::new()
    foreach ($case in $cases) {
        $manifest = Copy-Manifest
        & $case.Mutate $manifest
        $result = Invoke-StaticContract -WorkflowContent $workflow -Manifest $manifest
        $normalizedOutput = Normalize-DiagnosticText $result.Output
        if ($result.ExitCode -eq 0 -or
            $normalizedOutput.IndexOf(
                [string]$case.ExpectedMessage, [StringComparison]::Ordinal) -lt 0) {
            $accepted.Add([string]$case.Id)
            Write-Host "RED accepted static result mutation: $($case.Id) $($case.Name)"
        } else {
            Write-StaticContractPass "static result mutation: $($case.Id) $($case.Name)"
        }
    }

    $caseSensitiveManifest = Copy-Manifest
    $caseSensitiveJob = Get-ManifestJobById $caseSensitiveManifest "verification-contracts"
    $caseSensitiveJob.discovery.results += [PSCustomObject]@{
        resultId = "d0.3-v-static-001"
        evidencePath = "verification-contract-tests.log"
        minimum = 1
        includedInJobMinimum = $true
    }
    $caseSensitiveJob.discovery.minimumDiscoveredTests = 25
    $caseSensitiveResult = Invoke-StaticContract -WorkflowContent $workflow `
        -Manifest $caseSensitiveManifest
    if ($caseSensitiveResult.ExitCode -ne 0) {
        throw "Case-distinct result IDs were rejected: $($caseSensitiveResult.Output)"
    }
    Write-StaticContractPass "static result positive: case-distinct ordinal IDs"

    if ($accepted.Count -gt 0) {
        throw "D0.2R result-schema intended RED accepted mutations: $($accepted -join ', ')"
    }
}

function Invoke-StaticReviewFixMutation {
    param(
        [string]$Id,
        [string]$Name,
        [string]$WorkflowContent,
        [object]$Manifest,
        [string]$ManifestContent,
        [string]$ExpectedMessage
    )

    $invokeParameters = @{
        WorkflowContent = $WorkflowContent
    }
    if ($PSBoundParameters.ContainsKey("ManifestContent")) {
        $invokeParameters.ManifestContent = $ManifestContent
    } else {
        $invokeParameters.Manifest = $Manifest
    }
    $result = Invoke-StaticContract @invokeParameters
    $normalizedOutput = Normalize-DiagnosticText $result.Output
    if ($result.ExitCode -eq 0) {
        $script:staticReviewFixAccepted.Add($Id)
        Write-Host "RED accepted static review mutation: $Id $Name"
    } elseif ($normalizedOutput.IndexOf($ExpectedMessage, [StringComparison]::Ordinal) -lt 0) {
        throw "Static review mutation '$Id' failed for an unrelated reason. Output: $($result.Output)"
    } else {
        Write-StaticContractPass "static review mutation: $Id $Name"
    }
}

function Add-RawDuplicateD03Minimum {
    param(
        [string]$Content,
        [string]$DuplicateName
    )

    $anchor = '            "resultId": "D0.3-V-STATIC-001",'
    $minimumLine = '            "minimum": 24,'
    $anchorIndex = $Content.IndexOf($anchor, [StringComparison]::Ordinal)
    if ($anchorIndex -lt 0) {
        throw "Could not locate the raw D0.3 result anchor."
    }
    $minimumIndex = $Content.IndexOf(
        $minimumLine, $anchorIndex, [StringComparison]::Ordinal)
    if ($minimumIndex -lt 0) {
        throw "Could not locate the raw D0.3 minimum."
    }
    $lineEnding = if ($Content.IndexOf("`r`n", [StringComparison]::Ordinal) -ge 0) {
        "`r`n"
    } else {
        "`n"
    }
    $duplicateLine = "            `"$DuplicateName`": 0,"
    return $Content.Substring(0, $minimumIndex) + $duplicateLine + $lineEnding +
        $minimumLine + $Content.Substring($minimumIndex + $minimumLine.Length)
}

function Add-RawLineBeforeOnce {
    param(
        [string]$Content,
        [string]$Anchor,
        [string]$Line
    )

    $anchorIndex = $Content.IndexOf($Anchor, [StringComparison]::Ordinal)
    if ($anchorIndex -lt 0 -or
        $Content.IndexOf($Anchor, $anchorIndex + $Anchor.Length,
            [StringComparison]::Ordinal) -ge 0) {
        throw "Raw mutation anchor must occur exactly once: $Anchor"
    }
    $lineEnding = if ($Content.IndexOf("`r`n", [StringComparison]::Ordinal) -ge 0) {
        "`r`n"
    } else {
        "`n"
    }
    return $Content.Substring(0, $anchorIndex) + $Line + $lineEnding +
        $Content.Substring($anchorIndex)
}

function Add-RawDuplicateD03Discovery {
    param([string]$Content)

    $jobAnchor = '      "id": "verification-contracts",'
    $jobIndex = $Content.IndexOf($jobAnchor, [StringComparison]::Ordinal)
    if ($jobIndex -lt 0 -or
        $Content.IndexOf($jobAnchor, $jobIndex + $jobAnchor.Length,
            [StringComparison]::Ordinal) -ge 0) {
        throw "Could not uniquely locate the raw D0.3 job anchor."
    }

    $discoveryAnchor = '      "discovery": {'
    $discoveryIndex = $Content.IndexOf(
        $discoveryAnchor, $jobIndex, [StringComparison]::Ordinal)
    if ($discoveryIndex -lt 0) {
        throw "Could not locate the raw D0.3 discovery anchor."
    }
    $lineEnding = if ($Content.IndexOf("`r`n", [StringComparison]::Ordinal) -ge 0) {
        "`r`n"
    } else {
        "`n"
    }
    return $Content.Substring(0, $discoveryIndex) + '      "discovery": {},' +
        $lineEnding + $Content.Substring($discoveryIndex)
}

function Invoke-StaticReviewFixMutationCensus {
    $d03Pipeline = "          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |"
    $d03Tee = "            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log"
    $lineEnding = if ($workflow.IndexOf("`r`n", [StringComparison]::Ordinal) -ge 0) {
        "`r`n"
    } else {
        "`n"
    }
    $pipelineBlock = $d03Pipeline + $lineEnding + $d03Tee
    if ($workflow.IndexOf($pipelineBlock, [StringComparison]::Ordinal) -lt 0) {
        throw "Could not locate the complete D0.3 pipeline block for review mutations."
    }

    $commandCases = @(
        [PSCustomObject]@{
            Id = "D02R-SC07"
            Name = "parse-invalid recovery AST"
            Replacement = @'
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
          'unterminated
'@.TrimEnd()
        },
        [PSCustomObject]@{
            Id = "D02R-SC08"
            Name = "command nested in false branch"
            Replacement = @'
          if ($false) {
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
          }
          Write-Output 'fabricated D0.3 output' *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
'@.TrimEnd()
        },
        [PSCustomObject]@{
            Id = "D02R-SC09"
            Name = "command inside uncalled function"
            Replacement = @'
          function Invoke-FabricatedD03 {
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
          }
          Write-Output 'fabricated D0.3 output' *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
'@.TrimEnd()
        },
        [PSCustomObject]@{
            Id = "D02R-SC10"
            Name = "command after unconditional return"
            Replacement = @'
          Write-Output 'fabricated D0.3 output' *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
          return
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
'@.TrimEnd()
        },
        [PSCustomObject]@{
            Id = "D02R-SC11"
            Name = "command after top-level break"
            Replacement = @'
          break
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
'@.TrimEnd()
        },
        [PSCustomObject]@{
            Id = "D02R-SC12"
            Name = "command after top-level continue"
            Replacement = @'
          continue
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
'@.TrimEnd()
        },
        [PSCustomObject]@{
            Id = "D02R-SC13"
            Name = "command inside emitted scriptblock"
            Replacement = @'
          Write-Output {
          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |
            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log
          }
'@.TrimEnd()
        }
    )
    foreach ($case in $commandCases) {
        $replacement = [regex]::Replace([string]$case.Replacement, "\r?\n", $lineEnding)
        $mutatedWorkflow = $workflow.Replace($pipelineBlock, $replacement)
        if ($mutatedWorkflow -ceq $workflow) {
            throw "Could not create static review command mutation '$($case.Id)'."
        }
        Invoke-StaticReviewFixMutation -Id $case.Id -Name $case.Name `
            -WorkflowContent $mutatedWorkflow -Manifest (Copy-Manifest) `
            -ExpectedMessage "DISCOVERY-COMMAND-EXECUTABLE: verification-contracts"
    }

    $stepShell = "      - name: Run verification contract probes" + $lineEnding +
        "        shell: pwsh"
    $bashStepShell = "      - name: Run verification contract probes" + $lineEnding +
        "        shell: bash"
    $bashWorkflow = $workflow.Replace($stepShell, $bashStepShell)
    if ($bashWorkflow -ceq $workflow) {
        throw "Could not create static review command mutation 'D02R-SC14'."
    }
    Invoke-StaticReviewFixMutation -Id "D02R-SC14" -Name "owning step uses bash" `
        -WorkflowContent $bashWorkflow -Manifest (Copy-Manifest) `
        -ExpectedMessage "DISCOVERY-COMMAND-EXECUTABLE: verification-contracts"

    $caseDriftPipeline = $d03Pipeline.Replace(
        "Test-VerificationContracts.ps1", "test-VerificationContracts.ps1")
    $caseDriftWorkflow = $workflow.Replace($d03Pipeline, $caseDriftPipeline)
    if ($caseDriftWorkflow -ceq $workflow) {
        throw "Could not create static review command mutation 'D02R-SC15'."
    }
    Invoke-StaticReviewFixMutation -Id "D02R-SC15" -Name "command path case drift" `
        -WorkflowContent $caseDriftWorkflow -Manifest (Copy-Manifest) `
        -ExpectedMessage "DISCOVERY-COMMAND-EXECUTABLE: verification-contracts"

    $literalDuplicate = Add-RawDuplicateD03Minimum -Content $manifestText `
        -DuplicateName "minimum"
    Invoke-StaticReviewFixMutation -Id "D02R-SS19" -Name "literal duplicate result key" `
        -WorkflowContent $workflow -ManifestContent $literalDuplicate `
        -ExpectedMessage "DISCOVERY-RESULT-SHAPE: verification-contracts"

    $escapedDuplicate = Add-RawDuplicateD03Minimum -Content $manifestText `
        -DuplicateName "\u006dinimum"
    Invoke-StaticReviewFixMutation -Id "D02R-SS20" `
        -Name "escaped-semantic duplicate result key" -WorkflowContent $workflow `
        -ManifestContent $escapedDuplicate `
        -ExpectedMessage "DISCOVERY-RESULT-SHAPE: verification-contracts"

    $singleObjectManifest = Copy-Manifest
    $singleObjectJob = Get-ManifestJobById $singleObjectManifest "verification-contracts"
    $singleObjectJob.discovery.results = $singleObjectJob.discovery.results[0]
    Invoke-StaticReviewFixMutation -Id "D02R-SS21" -Name "results single object" `
        -WorkflowContent $workflow -Manifest $singleObjectManifest `
        -ExpectedMessage "DISCOVERY-RESULTS-REQUIRED: verification-contracts"

    $nullResultsManifest = Copy-Manifest
    $nullResultsJob = Get-ManifestJobById $nullResultsManifest "dotnet-build"
    $nullResultsJob.discovery | Add-Member -NotePropertyName results -NotePropertyValue $null
    Invoke-StaticReviewFixMutation -Id "D02R-SS22" -Name "not-applicable null results" `
        -WorkflowContent $workflow -Manifest $nullResultsManifest `
        -ExpectedMessage "DISCOVERY-NOT-APPLICABLE: dotnet-build"

    $pathCases = @(
        [PSCustomObject]@{
            Id = "D02R-SS23"
            Name = "Windows drive-rooted evidence"
            Path = "C:\escape.log"
        },
        [PSCustomObject]@{
            Id = "D02R-SS24"
            Name = "UNC-rooted evidence"
            Path = "\\server\share\escape.log"
        }
    )
    foreach ($case in $pathCases) {
        $pathManifest = Copy-Manifest
        $pathJob = Get-ManifestJobById $pathManifest "verification-contracts"
        $pathResult = @($pathJob.discovery.results | Where-Object {
                [string]$_.resultId -ceq "D0.3-V-STATIC-001"
            })[0]
        $pathEvidence = @($pathJob.evidenceFiles | Where-Object {
                [string]$_.path -ceq "verification-contract-tests.log"
            })[0]
        $pathResult.evidencePath = [string]$case.Path
        $pathEvidence.path = [string]$case.Path

        $jobText = Get-WorkflowJobText "verification-contracts" $workflow
        $mutatedJobText = $jobText.Replace(
            "verification-contract-tests.log", [string]$case.Path)
        if ($mutatedJobText -ceq $jobText) {
            throw "Could not create portable evidence-path mutation '$($case.Id)'."
        }
        $pathWorkflow = $workflow.Replace($jobText, $mutatedJobText)
        Invoke-StaticReviewFixMutation -Id $case.Id -Name $case.Name `
            -WorkflowContent $pathWorkflow -Manifest $pathManifest `
            -ExpectedMessage "DISCOVERY-RESULT-EVIDENCE: verification-contracts: $($case.Path)"
    }

    $duplicateRootJobs = Add-RawDuplicateD03Minimum -Content $manifestText `
        -DuplicateName "minimum"
    $duplicateRootJobs = Add-RawLineBeforeOnce -Content $duplicateRootJobs `
        -Anchor '  "jobs": [' -Line '  "jobs": [],'
    Invoke-StaticReviewFixMutation -Id "D02R-SS25" `
        -Name "duplicate root jobs hides duplicate result key" -WorkflowContent $workflow `
        -ManifestContent $duplicateRootJobs `
        -ExpectedMessage "DISCOVERY-RESULT-SHAPE: verification-contracts"

    $duplicateJobId = Add-RawDuplicateD03Minimum -Content $manifestText `
        -DuplicateName "minimum"
    $duplicateJobId = Add-RawLineBeforeOnce -Content $duplicateJobId `
        -Anchor '      "id": "verification-contracts",' `
        -Line '      "id": "ignored-verification-contracts",'
    Invoke-StaticReviewFixMutation -Id "D02R-SS26" `
        -Name "duplicate job id hides duplicate result key" -WorkflowContent $workflow `
        -ManifestContent $duplicateJobId `
        -ExpectedMessage "DISCOVERY-RESULT-SHAPE: verification-contracts"

    $duplicateDiscovery = Add-RawDuplicateD03Minimum -Content $manifestText `
        -DuplicateName "minimum"
    $duplicateDiscovery = Add-RawDuplicateD03Discovery -Content $duplicateDiscovery
    Invoke-StaticReviewFixMutation -Id "D02R-SS27" `
        -Name "duplicate discovery hides duplicate result key" -WorkflowContent $workflow `
        -ManifestContent $duplicateDiscovery `
        -ExpectedMessage "DISCOVERY-RESULT-SHAPE: verification-contracts"

    $artifactManifest = Copy-Manifest
    $artifactJob = Get-ManifestJobById $artifactManifest "verification-contracts"
    $artifactJob.artifactPath = "C:\artifact-output\"
    $artifactJobText = Get-WorkflowJobText "verification-contracts" $workflow
    $artifactUploadPath = "          path: artifacts/ci/verification-contracts/"
    $portableArtifactUploadPath = "          path: C:\artifact-output\"
    $mutatedArtifactJobText = $artifactJobText.Replace(
        $artifactUploadPath, $portableArtifactUploadPath)
    if ($mutatedArtifactJobText -ceq $artifactJobText) {
        throw "Could not create portable artifact-path mutation 'D02R-SS28'."
    }
    $artifactWorkflow = $workflow.Replace($artifactJobText, $mutatedArtifactJobText)
    Invoke-StaticReviewFixMutation -Id "D02R-SS28" `
        -Name "Windows drive-rooted artifact path" -WorkflowContent $artifactWorkflow `
        -Manifest $artifactManifest `
        -ExpectedMessage "required job has an invalid artifact path: verification-contracts"

    if ($staticReviewFixAccepted.Count -gt 0) {
        throw "D0.2R review-fix intended RED accepted mutations: " +
            ($staticReviewFixAccepted -join ', ')
    }
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

        $markerFiles = [ordered]@{}
        switch -CaseSensitive ([string]$requiredJob.id) {
            "delivery-contract" {
                $markerFiles["delivery-contract-tests.log"] = @(
                    "$discoveryMarkerPrefix{`"schemaVersion`":1,`"resultId`":`"D0.2R-V-STATIC-STATIC-CONTRACT`",`"sourceSha`":`"$sha`",`"actualDiscovery`":21,`"failed`":0,`"skipped`":0}",
                    "$discoveryMarkerPrefix{`"schemaVersion`":1,`"resultId`":`"D0.2R-V-COMPONENT-RESULT-CONTRACT`",`"sourceSha`":`"$sha`",`"actualDiscovery`":26,`"failed`":0,`"skipped`":0}"
                )
            }
            "verification-contracts" {
                $markerFiles["verification-contract-tests.log"] = @(
                    "$discoveryMarkerPrefix{`"schemaVersion`":1,`"resultId`":`"D0.3-V-STATIC-001`",`"sourceSha`":`"$sha`",`"actualDiscovery`":24,`"failed`":0,`"skipped`":0}"
                )
                $markerFiles["dependency-qualification-static-tests.log"] = @(
                    "$discoveryMarkerPrefix{`"schemaVersion`":1,`"resultId`":`"D0.5-V-STATIC-UBUNTU`",`"sourceSha`":`"$sha`",`"actualDiscovery`":45,`"failed`":0,`"skipped`":0}"
                )
            }
            "delivery-environment" {
                $markerFiles["environment-readiness-tests.log"] = @(
                    "$discoveryMarkerPrefix{`"schemaVersion`":1,`"resultId`":`"D0.4-V-STATIC-STATIC-CONTRACT`",`"sourceSha`":`"$sha`",`"actualDiscovery`":16,`"failed`":0,`"skipped`":0}",
                    "$discoveryMarkerPrefix{`"schemaVersion`":1,`"resultId`":`"D0.4-V-REAL-E2E-HOSTED-WINDOWS`",`"sourceSha`":`"$sha`",`"actualDiscovery`":9,`"failed`":0,`"skipped`":0}"
                )
            }
            "dependency-qualification" {
                $markerFiles["dependency-qualification-tests.log"] = @(
                    "$discoveryMarkerPrefix{`"schemaVersion`":1,`"resultId`":`"D0.5-V-STATIC-WINDOWS`",`"sourceSha`":`"$sha`",`"actualDiscovery`":45,`"failed`":0,`"skipped`":0}",
                    "$discoveryMarkerPrefix{`"schemaVersion`":1,`"resultId`":`"D0.5-V-PACKAGE-CLEAN-INSTALL`",`"sourceSha`":`"$sha`",`"actualDiscovery`":15,`"failed`":0,`"skipped`":0}"
                )
            }
        }

        foreach ($markerFile in $markerFiles.GetEnumerator()) {
            $markerPath = Join-Path $evidenceRoot ([string]$markerFile.Key)
            $markerText = [Environment]::NewLine + (@($markerFile.Value) -join [Environment]::NewLine)
            [IO.File]::AppendAllText($markerPath, $markerText)
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

    Write-ResultContractPass "result mutation: $Name"
}

function Assert-DiscoveryPayload {
    param([object]$Fixture)

    $expected = @{
        "delivery-contract" = [PSCustomObject]@{
            Total = 47
            Records = @(
                "D0.2R-V-STATIC-STATIC-CONTRACT|delivery-contract-tests.log|21|True|21",
                "D0.2R-V-COMPONENT-RESULT-CONTRACT|delivery-contract-tests.log|26|True|26"
            )
        }
        "dotnet-build" = [PSCustomObject]@{ Total = 0; Records = @() }
        "verification-contracts" = [PSCustomObject]@{
            Total = 24
            Records = @(
                "D0.3-V-STATIC-001|verification-contract-tests.log|24|True|24",
                "D0.5-V-STATIC-UBUNTU|dependency-qualification-static-tests.log|45|False|45"
            )
        }
        "delivery-environment" = [PSCustomObject]@{
            Total = 25
            Records = @(
                "D0.4-V-STATIC-STATIC-CONTRACT|environment-readiness-tests.log|16|True|16",
                "D0.4-V-REAL-E2E-HOSTED-WINDOWS|environment-readiness-tests.log|9|True|9"
            )
        }
        "dependency-qualification" = [PSCustomObject]@{
            Total = 60
            Records = @(
                "D0.5-V-STATIC-WINDOWS|dependency-qualification-tests.log|45|True|45",
                "D0.5-V-PACKAGE-CLEAN-INSTALL|dependency-qualification-tests.log|15|True|15"
            )
        }
    }

    foreach ($requiredJob in @($requiredChecks.jobs)) {
        $artifactName = "$($requiredJob.artifactPrefix)$($Fixture.Sha)"
        $payload = Get-CiDiscoveryResult -RequiredJob $requiredJob -Sha $Fixture.Sha `
            -EvidenceRoot $Fixture.EvidenceRoots[$artifactName]
        if (@($payload.failures).Count -ne 0) {
            throw "Valid discovery payload failed for '$($requiredJob.id)': $($payload.failures -join '; ')"
        }
        $actualRecords = @(
            foreach ($result in @($payload.results)) {
                "$($result.resultId)|$($result.evidencePath)|$($result.minimum)|" +
                    "$($result.includedInJobMinimum)|$($result.actualDiscovery)"
            }
        )
        $expectedJob = $expected[[string]$requiredJob.id]
        if ([long]$payload.actualDiscoveredTests -ne [long]$expectedJob.Total -or
            ($actualRecords -join "`n") -cne (@($expectedJob.Records) -join "`n")) {
            throw "Discovery payload differs for '$($requiredJob.id)'."
        }
    }
}

function Assert-WaitSummarySelfTest {
    $previousErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $enginePath -NoProfile -ExecutionPolicy Bypass -File $waitScript `
            -SelfTestOnly 2>&1
        $exitCode = $LASTEXITCODE
        $global:LASTEXITCODE = 0
    } finally {
        $ErrorActionPreference = $previousErrorAction
    }
    if ($exitCode -ne 0) {
        throw "Wait summary self-test failed to execute: $($output | Out-String)"
    }
    try {
        $value = ($output | Out-String) | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Wait summary self-test did not return JSON: $($output | Out-String)"
    }
    $probe = @($value.jobs | Where-Object { [string]$_.id -ceq "probe" })
    $notApplicable = @($value.jobs | Where-Object { [string]$_.id -ceq "not-applicable" })
    if ($value.schemaVersion -ne 1 -or $probe.Count -ne 1 -or $notApplicable.Count -ne 1 -or
        $probe[0].discovery.kind -cne "powershell-probe" -or
        [long]$probe[0].discovery.minimumDiscoveredTests -ne 24 -or
        [long]$probe[0].discovery.actualDiscoveredTests -ne 27 -or
        @($probe[0].discovery.results).Count -ne 2 -or
        @($probe[0].discovery.results | Where-Object {
                $_.resultId -ceq "D0.5-V-STATIC-UBUNTU" -and
                $_.includedInJobMinimum -eq $false -and [long]$_.actualDiscovery -eq 67
            }).Count -ne 1 -or
        $notApplicable[0].discovery.kind -cne "not-applicable" -or
        [long]$notApplicable[0].discovery.minimumDiscoveredTests -ne 0 -or
        [long]$notApplicable[0].discovery.actualDiscoveredTests -ne 0 -or
        @($notApplicable[0].discovery.results).Count -ne 0) {
        throw "Wait summary self-test returned an incomplete discovery contract."
    }
}

function Get-ResultFixtureEvidencePath {
    param(
        [object]$Fixture,
        [string]$JobId,
        [string]$EvidencePath
    )

    $jobs = @($requiredChecks.jobs | Where-Object { [string]$_.id -ceq $JobId })
    if ($jobs.Count -ne 1) {
        throw "Result fixture job '$JobId' is not unique."
    }
    $artifactName = "$($jobs[0].artifactPrefix)$($Fixture.Sha)"
    return Join-Path $Fixture.EvidenceRoots[$artifactName] $EvidencePath
}

function Assert-ExcludedDiscoveryResultIsMandatory {
    $fixture = New-ValidResultFixture
    $path = Get-ResultFixtureEvidencePath -Fixture $fixture `
        -JobId "verification-contracts" `
        -EvidencePath "dependency-qualification-static-tests.log"
    $content = [IO.File]::ReadAllText($path)
    [IO.File]::WriteAllText($path, $content.Replace($script:ubuntuFixtureMarker, ""))

    $failures = @(Test-CiDeliveryResult -RequiredChecks $requiredChecks -Sha $fixture.Sha `
            -RunDetails $fixture.Run -Artifacts $fixture.Artifacts `
            -EvidenceRoots $fixture.EvidenceRoots)
    $expected = "[DISCOVERY-MARKER-MISSING] job 'verification-contracts' result " +
        "'D0.5-V-STATIC-UBUNTU' marker appeared 0 times; expected 1 in " +
        "'dependency-qualification-static-tests.log'"
    if ($failures.Count -eq 0 -or
        ($failures -join "`n").IndexOf($expected, [StringComparison]::Ordinal) -lt 0) {
        throw "Excluded discovery result was not mandatory. Failures: $($failures -join '; ')"
    }
    Write-ResultContractPass "excluded discovery result remains mandatory"
}

function Assert-HigherIncludedDiscoveryActualIsReturned {
    $fixture = New-ValidResultFixture
    $path = Get-ResultFixtureEvidencePath -Fixture $fixture `
        -JobId "verification-contracts" -EvidencePath "verification-contract-tests.log"
    $content = [IO.File]::ReadAllText($path)
    [IO.File]::WriteAllText($path, $content.Replace(
            '"actualDiscovery":24', '"actualDiscovery":31'))

    $job = @($requiredChecks.jobs | Where-Object {
            [string]$_.id -ceq "verification-contracts" })[0]
    $artifactName = "$($job.artifactPrefix)$($fixture.Sha)"
    $payload = Get-CiDiscoveryResult -RequiredJob $job -Sha $fixture.Sha `
        -EvidenceRoot $fixture.EvidenceRoots[$artifactName]
    $actualRecords = @(foreach ($result in @($payload.results)) {
            "$($result.resultId)|$($result.evidencePath)|$($result.minimum)|" +
                "$($result.includedInJobMinimum)|$($result.actualDiscovery)"
        })
    $expectedRecords = @(
        "D0.3-V-STATIC-001|verification-contract-tests.log|24|True|31",
        "D0.5-V-STATIC-UBUNTU|dependency-qualification-static-tests.log|45|False|45"
    )
    if (@($payload.failures).Count -ne 0 -or
        [long]$payload.actualDiscoveredTests -ne 31 -or
        ($actualRecords -join "`n") -cne ($expectedRecords -join "`n")) {
        throw "Higher included discovery actual was capped or misreported."
    }
    Write-ResultContractPass "higher included discovery actual is returned uncapped"
}

function Assert-CompensatingDiscoveryCannotMaskBelowFloor {
    $fixture = New-ValidResultFixture
    $path = Get-ResultFixtureEvidencePath -Fixture $fixture `
        -JobId "delivery-contract" -EvidencePath "delivery-contract-tests.log"
    $content = [IO.File]::ReadAllText($path)
    foreach ($needle in @('"actualDiscovery":21', '"actualDiscovery":26')) {
        if ([regex]::Matches($content, [regex]::Escape($needle)).Count -ne 1) {
            throw "Compensating discovery fixture anchor is not unique: $needle"
        }
    }
    $content = $content.Replace('"actualDiscovery":21', '"actualDiscovery":20')
    $content = $content.Replace('"actualDiscovery":26', '"actualDiscovery":27')
    [IO.File]::WriteAllText($path, $content)

    $job = Get-ManifestJobById $requiredChecks "delivery-contract"
    $artifactName = "$($job.artifactPrefix)$($fixture.Sha)"
    $payload = Get-CiDiscoveryResult -RequiredJob $job -Sha $fixture.Sha `
        -EvidenceRoot $fixture.EvidenceRoots[$artifactName]
    $failures = @($payload.failures)
    $expected = "[DISCOVERY-MARKER-COUNTS] job 'delivery-contract' result " +
        "'D0.2R-V-STATIC-STATIC-CONTRACT' discovered 20; minimum is 21"
    if ([long]$payload.actualDiscoveredTests -ne 47 -or $failures.Count -ne 1 -or
        [string]$failures[0] -cne $expected) {
        throw "Compensating discovery total masked a below-floor component. " +
            "Total=$($payload.actualDiscoveredTests); failures=$($failures -join '; ')"
    }
    Write-ResultContractPass "component floor cannot be masked by compensating total"
}

function Invoke-DiscoveryMutationCensus {
    $cases = @(
        [PSCustomObject]@{
            Id = "D02R-M01"; Name = "missing marker"; ExpectedCode = "DISCOVERY-MARKER-MISSING"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace($script:d03FixtureMarker, ""))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M02"; Name = "zero actual discovery"; ExpectedCode = "DISCOVERY-MARKER-COUNTS"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    '"actualDiscovery":24', '"actualDiscovery":0'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M03"; Name = "below-floor actual discovery"; ExpectedCode = "DISCOVERY-MARKER-COUNTS"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    '"actualDiscovery":24', '"actualDiscovery":23'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M04"; Name = "malformed JSON"; ExpectedCode = "DISCOVERY-MARKER-JSON"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    $script:d03FixtureMarker, $script:discoveryMarkerPrefix + "{not-json"))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M05"; Name = "duplicate marker"; ExpectedCode = "DISCOVERY-MARKER-DUPLICATE"
            Mutate = {
                param($fixture, $path)
                [IO.File]::AppendAllText($path, [Environment]::NewLine + $script:d03FixtureMarker)
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M06"; Name = "unexpected result"; ExpectedCode = "DISCOVERY-MARKER-UNEXPECTED"
            Mutate = {
                param($fixture, $path)
                $unknown = $script:d03FixtureMarker.Replace(
                    "D0.3-V-STATIC-001", "D0.3-V-STATIC-000")
                [IO.File]::AppendAllText($path, [Environment]::NewLine + $unknown)
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M07"; Name = "wrong source SHA"; ExpectedCode = "DISCOVERY-MARKER-SHA"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    "a" * 40, "b" * 40))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M08"; Name = "reported skip"; ExpectedCode = "DISCOVERY-MARKER-COUNTS"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace('"skipped":0', '"skipped":1'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M09"; Name = "reported failure"; ExpectedCode = "DISCOVERY-MARKER-COUNTS"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace('"failed":0', '"failed":1'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M10"; Name = "string actual discovery"; ExpectedCode = "DISCOVERY-MARKER-SHAPE"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    '"actualDiscovery":24', '"actualDiscovery":"24"'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M11"; Name = "duplicate JSON key"; ExpectedCode = "DISCOVERY-MARKER-SHAPE"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    '"actualDiscovery":24', '"actualDiscovery":0,"actualDiscovery":24'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M12"; Name = "parent minimum mismatch"; ExpectedCode = "DISCOVERY-CONTRACT-TOTAL"
            Mutate = { param($fixture, $path) }
            MutateContract = {
                param($contract)
                $job = @($contract.jobs | Where-Object { [string]$_.id -ceq "verification-contracts" })[0]
                $job.discovery.minimumDiscoveredTests = 999
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M13"; Name = "all results excluded from parent"; ExpectedCode = "DISCOVERY-CONTRACT-TOTAL"
            Mutate = { param($fixture, $path) }
            MutateContract = {
                param($contract)
                $job = @($contract.jobs | Where-Object { [string]$_.id -ceq "verification-contracts" })[0]
                foreach ($result in @($job.discovery.results)) {
                    $result.includedInJobMinimum = $false
                }
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M14"; Name = "marker in wrong log"; ExpectedCode = "DISCOVERY-MARKER-UNEXPECTED"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace($script:d03FixtureMarker, ""))
                $wrongPath = Get-ResultFixtureEvidencePath -Fixture $fixture `
                    -JobId "verification-contracts" `
                    -EvidencePath "dependency-qualification-static-tests.log"
                [IO.File]::AppendAllText($wrongPath, [Environment]::NewLine + $script:d03FixtureMarker)
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M15"; Name = "missing marker field"; ExpectedCode = "DISCOVERY-MARKER-SHAPE"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace('"failed":0,', ""))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M16"; Name = "extra marker field"; ExpectedCode = "DISCOVERY-MARKER-SHAPE"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    '"failed":0,"skipped":0}', '"failed":0,"skipped":0,"extra":0}'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M17"; Name = "case-drifted result ID"; ExpectedCode = "DISCOVERY-MARKER-UNEXPECTED"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    "D0.3-V-STATIC-001", "d0.3-v-static-001"))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M18"; Name = "ANSI before marker prefix"; ExpectedCode = "DISCOVERY-MARKER-MISSING"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                $ansiPrefix = ([char]27).ToString() + "[0m"
                [IO.File]::WriteAllText($path, $content.Replace(
                    $script:d03FixtureMarker, $ansiPrefix + $script:d03FixtureMarker))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M19"; Name = "exponent actual discovery"; ExpectedCode = "DISCOVERY-MARKER-SHAPE"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    '"actualDiscovery":24', '"actualDiscovery":2.4e1'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M20"; Name = "escaped duplicate key after literal key"
            ExpectedCode = "DISCOVERY-MARKER-SHAPE"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    '"actualDiscovery":24',
                    '"actualDiscovery":0,"\u0061ctualDiscovery":24'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M21"; Name = "escaped duplicate key before literal key"
            ExpectedCode = "DISCOVERY-MARKER-SHAPE"
            Mutate = {
                param($fixture, $path)
                $content = [IO.File]::ReadAllText($path)
                [IO.File]::WriteAllText($path, $content.Replace(
                    '"actualDiscovery":24',
                    '"\u0061ctualDiscovery":24,"actualDiscovery":0'))
            }
        },
        [PSCustomObject]@{
            Id = "D02R-M22"; Name = "physical evidence filename case drift"
            ExpectedCode = "has unexpected evidence file 'Verification-Contract-Tests.LOG'"
            Mutate = {
                param($fixture, $path)
                $temporaryPath = "$path.case-shift"
                $caseDriftPath = Join-Path (Split-Path -Parent $path) `
                    "Verification-Contract-Tests.LOG"
                [IO.File]::Move($path, $temporaryPath)
                [IO.File]::Move($temporaryPath, $caseDriftPath)
            }
        }
    )

    $accepted = [System.Collections.Generic.List[string]]::new()
    foreach ($case in $cases) {
        $fixture = New-ValidResultFixture
        $path = Get-ResultFixtureEvidencePath -Fixture $fixture `
            -JobId "verification-contracts" -EvidencePath "verification-contract-tests.log"
        & $case.Mutate $fixture $path
        $caseRequiredChecks = Copy-Manifest
        $contractMutation = $case.PSObject.Properties["MutateContract"]
        if ($null -ne $contractMutation) {
            & $contractMutation.Value $caseRequiredChecks
        }
        $failures = @(Test-CiDeliveryResult -RequiredChecks $caseRequiredChecks -Sha $fixture.Sha `
                -RunDetails $fixture.Run -Artifacts $fixture.Artifacts `
                -EvidenceRoots $fixture.EvidenceRoots)
        if (($failures -join "`n").IndexOf($case.ExpectedCode, [StringComparison]::Ordinal) -lt 0) {
            $accepted.Add([string]$case.Id)
            Write-Host "RED accepted discovery mutation: $($case.Id) $($case.Name)"
        } else {
            Write-ResultContractPass "discovery mutation: $($case.Id) $($case.Name)"
        }
    }

    if ($accepted.Count -gt 0) {
        throw "D0.2R intended RED accepted discovery mutations: $($accepted -join ', ')"
    }
}

#region Discovery marker producer contract
function Get-CiNamedArgumentExpression {
    param(
        [System.Management.Automation.Language.CommandAst]$Call,
        [string]$Name
    )

    $elements = @($Call.CommandElements)
    for ($index = 1; $index -lt $elements.Count; $index++) {
        $element = $elements[$index]
        if ($element -isnot [System.Management.Automation.Language.CommandParameterAst] -or
            $element.ParameterName -cne $Name) {
            continue
        }
        if ($index + 1 -ge $elements.Count -or
            $elements[$index + 1] -is [System.Management.Automation.Language.CommandParameterAst]) {
            return $null
        }
        return $elements[$index + 1]
    }
    return $null
}

function Get-CiCompactAstText {
    param([System.Management.Automation.Language.Ast]$Ast)

    if ($null -eq $Ast) { return "" }
    return [regex]::Replace($Ast.Extent.Text, '\s+', '')
}

function Get-CiWorkflowRunScripts {
    param([string]$JobBlock)

    $lines = $JobBlock -split "\r?\n"
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -cnotmatch '^        run:\s*\|\s*$') {
            continue
        }
        $stepStart = $index
        while ($stepStart -ge 0 -and $lines[$stepStart] -cnotmatch '^      -\s+') {
            $stepStart--
        }
        if ($stepStart -lt 0 -or
            ($lines[$stepStart..$index] -join "`n") -cnotmatch '(?m)^        shell:\s*pwsh\s*$') {
            continue
        }
        $scriptLines = [System.Collections.Generic.List[string]]::new()
        for ($scriptIndex = $index + 1; $scriptIndex -lt $lines.Count; $scriptIndex++) {
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

function Test-CiMarkerCallIsLive {
    param([System.Management.Automation.Language.Ast]$Ast)

    $allowedAncestors = @(
        "PipelineAst", "StatementBlockAst", "NamedBlockAst", "IfStatementAst",
        "TryStatementAst", "ScriptBlockAst"
    )
    for ($parent = $Ast.Parent; $null -ne $parent; $parent = $parent.Parent) {
        $parentType = $parent.GetType().Name
        if ($allowedAncestors -cnotcontains $parentType) {
            return $false
        }
        if ($parent -is [System.Management.Automation.Language.IfStatementAst]) {
            foreach ($clause in @($parent.Clauses)) {
                if ($Ast.Extent.StartOffset -ge $clause.Item2.Extent.StartOffset -and
                    $Ast.Extent.EndOffset -le $clause.Item2.Extent.EndOffset -and
                    (Get-CiCompactAstText $clause.Item1) -ceq '$false') {
                    return $false
                }
            }
        }
        if ($parent -is [System.Management.Automation.Language.TryStatementAst] -and
            ($null -eq $parent.Body -or
                $Ast.Extent.StartOffset -lt $parent.Body.Extent.StartOffset -or
                $Ast.Extent.EndOffset -gt $parent.Body.Extent.EndOffset)) {
            return $false
        }
        if ($parent -is [System.Management.Automation.Language.StatementBlockAst] -or
            $parent -is [System.Management.Automation.Language.NamedBlockAst]) {
            foreach ($statement in @($parent.Statements)) {
                if ($statement.Extent.EndOffset -gt $Ast.Extent.StartOffset) {
                    continue
                }
                if (@("ReturnStatementAst", "ExitStatementAst", "ThrowStatementAst",
                        "BreakStatementAst", "ContinueStatementAst") -ccontains
                    $statement.GetType().Name) {
                    return $false
                }
            }
        }
    }
    return $true
}

function Get-CiMarkerRouteKeys {
    param([System.Management.Automation.Language.CommandAst]$Call)

    $routes = [System.Collections.Generic.List[string]]::new()
    for ($parent = $Call.Parent; $null -ne $parent; $parent = $parent.Parent) {
        if ($parent -isnot [System.Management.Automation.Language.IfStatementAst]) {
            continue
        }
        foreach ($clause in @($parent.Clauses)) {
            $block = $clause.Item2
            if ($Call.Extent.StartOffset -ge $block.Extent.StartOffset -and
                $Call.Extent.EndOffset -le $block.Extent.EndOffset) {
                $routes.Add((Get-CiCompactAstText $clause.Item1))
            }
        }
        if ($null -ne $parent.ElseClause -and
            $Call.Extent.StartOffset -ge $parent.ElseClause.Extent.StartOffset -and
            $Call.Extent.EndOffset -le $parent.ElseClause.Extent.EndOffset) {
            $routes.Add("<else>")
        }
    }
    return [string[]]$routes.ToArray()
}

function Assert-CiDiscoveryMarkerWriter {
    $markerLines = @(Write-CiDiscoveryMarker `
            -ResultId "D0.2R-V-STATIC-STATIC-CONTRACT" -ActualDiscovery 21)
    if ($markerLines.Count -ne 1 -or
        -not ([string]$markerLines[0]).StartsWith($discoveryMarkerPrefix, [StringComparison]::Ordinal)) {
        throw "Discovery marker writer did not return exactly one marker line."
    }

    $payloadText = ([string]$markerLines[0]).Substring($discoveryMarkerPrefix.Length)
    try {
        $payload = $payloadText | ConvertFrom-Json -ErrorAction Stop
    } catch {
        throw "Discovery marker writer returned malformed JSON: $($_.Exception.Message)"
    }
    $expectedFields = @("schemaVersion", "resultId", "sourceSha", "actualDiscovery", "failed", "skipped")
    if ((@($payload.PSObject.Properties.Name) -join "|") -cne ($expectedFields -join "|") -or
        [long]$payload.schemaVersion -ne 1 -or
        [string]$payload.resultId -cne "D0.2R-V-STATIC-STATIC-CONTRACT" -or
        [string]$payload.sourceSha -cnotmatch '^[0-9a-f]{40}$' -or
        [long]$payload.actualDiscovery -ne 21 -or
        [long]$payload.failed -ne 0 -or
        [long]$payload.skipped -ne 0) {
        throw "Discovery marker writer returned an invalid payload."
    }

    $invalidRoot = Join-Path $tempRoot "not-a-repository"
    New-Item -ItemType Directory -Path $invalidRoot | Out-Null
    $invalidRootRejected = $false
    try {
        $null = Write-CiDiscoveryMarker -ResultId "D0.2R-V-STATIC-STATIC-CONTRACT" `
            -ActualDiscovery 21 -RepositoryRoot $invalidRoot
    } catch {
        $invalidRootRejected = $true
    }
    if (-not $invalidRootRejected) {
        throw "Discovery marker writer accepted a directory without a Git HEAD."
    }

    Write-ResultContractPass "discovery marker writer"
}

function Assert-CiProducerReachabilityGuard {
    $cases = @(
        [PSCustomObject]@{ Name = "top-level"; Source = 'Write-CiDiscoveryMarker -ResultId "x" -ActualDiscovery 1'; Live = $true },
        [PSCustomObject]@{ Name = "false branch"; Source = 'if ($false) { Write-CiDiscoveryMarker -ResultId "x" -ActualDiscovery 1 }'; Live = $false },
        [PSCustomObject]@{ Name = "false loop"; Source = 'while ($false) { Write-CiDiscoveryMarker -ResultId "x" -ActualDiscovery 1 }'; Live = $false },
        [PSCustomObject]@{ Name = "uncalled scriptblock"; Source = '$deferred = { Write-CiDiscoveryMarker -ResultId "x" -ActualDiscovery 1 }'; Live = $false },
        [PSCustomObject]@{ Name = "captured subexpression"; Source = '$null = $(Write-CiDiscoveryMarker -ResultId "x" -ActualDiscovery 1)'; Live = $false },
        [PSCustomObject]@{ Name = "after return"; Source = "return`nWrite-CiDiscoveryMarker -ResultId `"x`" -ActualDiscovery 1"; Live = $false }
    )
    foreach ($case in $cases) {
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseInput(
            [string]$case.Source, [ref]$tokens, [ref]$parseErrors)
        $call = @($ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -ceq "Write-CiDiscoveryMarker"
                }, $true))
        if (@($parseErrors).Count -ne 0 -or $call.Count -ne 1 -or
            (Test-CiMarkerCallIsLive $call[0]) -ne [bool]$case.Live) {
            throw "Producer reachability guard failed '$($case.Name)'."
        }
    }
    Write-ResultContractPass "producer reachability guard"
}

function Assert-CiDependencyQualificationWrapper {
    $path = Join-Path $repositoryRoot "tools/verification/Invoke-DependencyQualification.ps1"
    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $path, [ref]$tokens, [ref]$parseErrors)
    $calls = @($ast.FindAll({
                param($node)
                $node -is [System.Management.Automation.Language.CommandAst] -and
                $node.GetCommandName() -ceq "./tools/verification/Test-DependencyQualification.ps1"
            }, $true))
    $actual = @($calls | ForEach-Object { Get-CiCompactAstText $_ })
    $expected = @(
        '&./tools/verification/Test-DependencyQualification.ps1-ModeStatic',
        '&./tools/verification/Test-DependencyQualification.ps1-ModeQualify-EvidenceDirectory$EvidenceDirectory'
    )
    $invalidShape = @($calls | Where-Object {
            $pipeline = $_.Parent
            -not (Test-CiMarkerCallIsLive $_) -or
            $pipeline -isnot [System.Management.Automation.Language.PipelineAst] -or
            $pipeline.PipelineElements.Count -ne 1 -or $_.Redirections.Count -ne 0 -or
            -not [object]::ReferenceEquals($pipeline.Parent, $ast.EndBlock)
        })
    if (@($parseErrors).Count -ne 0 -or $invalidShape.Count -ne 0 -or
        ($actual -join "`n") -cne ($expected -join "`n")) {
        throw "Dependency qualification wrapper does not forward both producer outputs."
    }
    Write-ResultContractPass "dependency qualification wrapper output forwarding"
}

function Assert-CiDiscoveryWorkflowPipelines {
    param([string]$WorkflowContent = $script:workflow)

    $expected = @(
        [PSCustomObject]@{ Job = "delivery-contract"; Command = "./tools/ci/Test-CiDelivery.ps1"; Sink = "artifacts/ci/delivery-contract/delivery-contract-tests.log" },
        [PSCustomObject]@{ Job = "verification-contracts"; Command = "./tools/verification/Test-VerificationContracts.ps1"; Sink = "artifacts/ci/verification-contracts/verification-contract-tests.log" },
        [PSCustomObject]@{ Job = "verification-contracts"; Command = "./tools/verification/Test-DependencyQualification.ps1 -Mode Static"; Sink = "artifacts/ci/verification-contracts/dependency-qualification-static-tests.log" },
        [PSCustomObject]@{ Job = "delivery-environment"; Command = "./tools/verification/Test-EnvironmentReadiness.ps1 -Mode HostedWindows -EvidenceDirectory artifacts/ci/delivery-environment"; Sink = "artifacts/ci/delivery-environment/environment-readiness-tests.log" },
        [PSCustomObject]@{ Job = "dependency-qualification"; Command = "./tools/verification/Invoke-DependencyQualification.ps1 -EvidenceDirectory artifacts/ci/dependency-qualification"; Sink = "artifacts/ci/dependency-qualification/dependency-qualification-tests.log" }
    )
    foreach ($row in $expected) {
        $jobBlock = Get-WorkflowJobText -JobId $row.Job -Content $WorkflowContent
        $expectedCommand = [regex]::Replace(
            "$($row.Command) *>&1", '\s+', '')
        $expectedSink = [regex]::Replace("Tee-Object $($row.Sink)", '\s+', '')
        $matches = 0
        foreach ($runScript in @(Get-CiWorkflowRunScripts -JobBlock $jobBlock)) {
            $tokens = $null
            $parseErrors = $null
            $ast = [System.Management.Automation.Language.Parser]::ParseInput(
                $runScript, [ref]$tokens, [ref]$parseErrors)
            if (@($parseErrors).Count -ne 0) {
                throw "Workflow job '$($row.Job)' contains an invalid pwsh run block."
            }
            foreach ($statement in @($ast.EndBlock.Statements)) {
                if ($statement -isnot [System.Management.Automation.Language.PipelineAst] -or
                    $statement.PipelineElements.Count -ne 2 -or
                    $statement.PipelineElements[0] -isnot [System.Management.Automation.Language.CommandAst] -or
                    $statement.PipelineElements[1] -isnot [System.Management.Automation.Language.CommandAst] -or
                    -not (Test-CiMarkerCallIsLive $statement)) {
                    continue
                }
                if ((Get-CiCompactAstText $statement.PipelineElements[0]) -ceq $expectedCommand -and
                    (Get-CiCompactAstText $statement.PipelineElements[1]) -ceq $expectedSink) {
                    $matches++
                }
            }
        }
        if ($matches -ne 1) {
            throw "Workflow job '$($row.Job)' does not retain '$($row.Command)' in '$($row.Sink)'."
        }
    }
    Write-ResultContractPass "discovery producer workflow pipelines"
}

function Assert-CiDiscoveryWorkflowNegativeControls {
    $lineEnding = if ($workflow.IndexOf("`r`n", [StringComparison]::Ordinal) -ge 0) {
        "`r`n"
    } else {
        "`n"
    }
    $pipeline = "          ./tools/verification/Test-DependencyQualification.ps1 -Mode Static *>&1 |" +
        $lineEnding +
        "            Tee-Object artifacts/ci/verification-contracts/dependency-qualification-static-tests.log"
    if ([regex]::Matches($workflow, [regex]::Escape($pipeline)).Count -ne 1) {
        throw "Could not locate the Ubuntu dependency discovery pipeline."
    }
    $cases = @(
        [PSCustomObject]@{
            Name = "false branch"
            Replacement = "          if (`$false) {" + $lineEnding + $pipeline +
                $lineEnding + "          }"
        },
        [PSCustomObject]@{
            Name = "after return"
            Replacement = "          return" + $lineEnding + $pipeline
        }
    )
    foreach ($case in $cases) {
        $mutatedWorkflow = $workflow.Replace($pipeline, [string]$case.Replacement)
        $rejected = $false
        try {
            Assert-CiDiscoveryWorkflowPipelines -WorkflowContent $mutatedWorkflow
        } catch {
            $expected = "Workflow job 'verification-contracts' does not retain " +
                "'./tools/verification/Test-DependencyQualification.ps1 -Mode Static'"
            if ($_.Exception.Message.IndexOf($expected, [StringComparison]::Ordinal) -lt 0) {
                throw
            }
            $rejected = $true
        }
        if (-not $rejected) {
            throw "Discovery workflow guard accepted producer pipeline case '$($case.Name)'."
        }
    }
    Write-ResultContractPass "dead discovery workflow pipelines are rejected"
}

function Assert-CiDiscoveryProducerSources {
    $expectedRows = @(
        [PSCustomObject]@{ Path = "tools/ci/Test-CiDelivery.ps1"; ResultId = "D0.2R-V-STATIC-STATIC-CONTRACT"; Actual = '$staticContractCount'; Routes = @() },
        [PSCustomObject]@{ Path = "tools/ci/Test-CiDelivery.ps1"; ResultId = "D0.2R-V-COMPONENT-RESULT-CONTRACT"; Actual = '$resultContractCount'; Routes = @() },
        [PSCustomObject]@{ Path = "tools/verification/Test-VerificationContracts.ps1"; ResultId = "D0.3-V-STATIC-001"; Actual = '$discoveredProbes'; Routes = @() },
        [PSCustomObject]@{ Path = "tools/verification/Test-DependencyQualification.ps1"; ResultId = "D0.5-V-STATIC-UBUNTU"; Actual = '$staticProbeCount'; Routes = @('$Mode-ceq"Static"', '<else>') },
        [PSCustomObject]@{ Path = "tools/verification/Test-EnvironmentReadiness.ps1"; ResultId = "D0.4-V-STATIC-STATIC-CONTRACT"; Actual = '([long]($probeCount-$hostedProbeCount))'; Routes = @() },
        [PSCustomObject]@{ Path = "tools/verification/Test-EnvironmentReadiness.ps1"; ResultId = "D0.4-V-REAL-E2E-HOSTED-WINDOWS"; Actual = '$hostedProbeCount'; Routes = @('$Mode-ceq"HostedWindows"') },
        [PSCustomObject]@{ Path = "tools/verification/Test-DependencyQualification.ps1"; ResultId = "D0.5-V-STATIC-WINDOWS"; Actual = '$staticProbeCount'; Routes = @('$Mode-ceq"Static"', '[Environment]::OSVersion.Platform-eq[PlatformID]::Win32NT') },
        [PSCustomObject]@{ Path = "tools/verification/Test-DependencyQualification.ps1"; ResultId = "D0.5-V-PACKAGE-CLEAN-INSTALL"; Actual = '$packageProbeCount'; Routes = @('$Mode-ceq"Qualify"') }
    )
    $failures = [System.Collections.Generic.List[string]]::new()

    foreach ($path in @($expectedRows.Path | Select-Object -Unique)) {
        $absolutePath = Join-Path $repositoryRoot $path
        $tokens = $null
        $parseErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $absolutePath, [ref]$tokens, [ref]$parseErrors)
        if (@($parseErrors).Count -ne 0) {
            $failures.Add("$path has PowerShell parse errors")
            continue
        }

        $calls = @($ast.FindAll({
                    param($node)
                    $node -is [System.Management.Automation.Language.CommandAst] -and
                    $node.GetCommandName() -ceq "Write-CiDiscoveryMarker"
                }, $true) | Where-Object { Test-CiMarkerCallIsLive $_ })
        $rows = @($expectedRows | Where-Object { $_.Path -ceq $path })
        if ($calls.Count -ne $rows.Count) {
            $failures.Add("$path has $($calls.Count) live marker calls; expected $($rows.Count)")
        }

        foreach ($row in $rows) {
            $matches = @($calls | Where-Object {
                    $resultId = Get-CiNamedArgumentExpression $_ "ResultId"
                    $resultId -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
                    [string]$resultId.Value -ceq [string]$row.ResultId
                })
            if ($matches.Count -ne 1) {
                $failures.Add("$path result '$($row.ResultId)' appeared $($matches.Count) times; expected 1")
                continue
            }

            $call = $matches[0]
            $actual = Get-CiCompactAstText (Get-CiNamedArgumentExpression $call "ActualDiscovery")
            if ($actual -cne [string]$row.Actual) {
                $failures.Add("$path result '$($row.ResultId)' uses '$actual'; expected '$($row.Actual)'")
            }
            $pipeline = $call.Parent
            if ($pipeline -isnot [System.Management.Automation.Language.PipelineAst] -or
                $pipeline.PipelineElements.Count -ne 1 -or $call.Redirections.Count -ne 0 -or
                ($pipeline.Parent -isnot [System.Management.Automation.Language.StatementBlockAst] -and
                    $pipeline.Parent -isnot [System.Management.Automation.Language.NamedBlockAst])) {
                $failures.Add("$path result '$($row.ResultId)' is not a standalone output command")
            }
            $routes = @(Get-CiMarkerRouteKeys $call)
            if ($routes.Count -ne @($row.Routes).Count) {
                $failures.Add("$path result '$($row.ResultId)' has routes " +
                    "'$($routes -join ',')'; expected '$(@($row.Routes) -join ',')'")
            }
            foreach ($requiredRoute in @($row.Routes)) {
                if ($routes -cnotcontains [string]$requiredRoute) {
                    $failures.Add("$path result '$($row.ResultId)' is missing route '$requiredRoute'")
                }
            }
        }
    }

    if ($failures.Count -gt 0) {
        throw "Discovery producer contract failed:`n - $($failures -join "`n - ")"
    }
    Write-ResultContractPass "eight discovery producer markers"
}
#endregion

try {
    $wrappedDiagnostic = ([char]27).ToString() +
        "[31;1mtop-level SOURCE_SHA must select pull-request`n | head or github.sha" +
        ([char]27).ToString() + "[0m"
    $normalizedDiagnostic = Normalize-DiagnosticText $wrappedDiagnostic
    if ($normalizedDiagnostic -ne "top-level SOURCE_SHA must select pull-request head or github.sha") {
        throw "PowerShell diagnostic normalization failed: '$normalizedDiagnostic'"
    }
    Write-StaticContractPass "wrapped/ANSI diagnostic normalization"

    $baseline = Invoke-StaticContract -WorkflowContent $workflow -Manifest (Copy-Manifest)
    if ($baseline.ExitCode -ne 0) {
        throw "Valid static CI contract failed: $($baseline.Output)"
    }
    Write-StaticContractPass "valid static contract"

    Invoke-StaticCommandMutationCensus
    Invoke-StaticResultSchemaMutationCensus
    Invoke-StaticReviewFixMutationCensus

    $lineEnding = if ($workflow.IndexOf("`r`n", [StringComparison]::Ordinal) -ge 0) {
        "`r`n"
    } else {
        "`n"
    }
    $d03Command = "          ./tools/verification/Test-VerificationContracts.ps1 *>&1 |"
    $d03Sink = "            Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log"
    $d03Pipeline = $d03Command + $lineEnding + $d03Sink
    $discardedD03Pipeline = $d03Command + $lineEnding +
        "            Out-Null # verification-contract-tests.log" + $lineEnding +
        "          if (`$false) {" + $lineEnding +
        "            ./tools/verification/Test-VerificationContracts.ps1 *>&1 |" + $lineEnding +
        "              Tee-Object artifacts/ci/verification-contracts/verification-contract-tests.log" + $lineEnding +
        "          }"
    $discardedD03Workflow = $workflow.Replace($d03Pipeline, $discardedD03Pipeline)
    if ($discardedD03Workflow -ceq $workflow) {
        throw "Could not create retained-log sink mutation."
    }
    Assert-StaticMutationRejected -Name "dead Tee decoy cannot retain discovery output" `
        -WorkflowContent $discardedD03Workflow -Manifest (Copy-Manifest) `
        -ExpectedMessage "DISCOVERY-COMMAND-EXECUTABLE: verification-contracts"

    $variableSinkWorkflow = $workflow.Replace(
        $d03Sink, "            Tee-Object -Variable verification-contract-tests.log")
    if ($variableSinkWorkflow -ceq $workflow) {
        throw "Could not create Tee-Object variable mutation."
    }
    Assert-StaticMutationRejected -Name "Tee-Object variable is not a retained file" `
        -WorkflowContent $variableSinkWorkflow -Manifest (Copy-Manifest) `
        -ExpectedMessage "DISCOVERY-COMMAND-EXECUTABLE: verification-contracts"

    & $evidenceAttributeTest -AttributesPath $AttributesPath

    Assert-StaticMutationRejected -Name "missing dependency-evidence byte-preservation rule" `
        -WorkflowContent $workflow -Manifest (Copy-Manifest) `
        -AttributesContent ($attributes.Replace(
            "docs/verification/dependencies/** -text", ""
        )) -ExpectedMessage "dependency evidence must be declared -text"

    Assert-StaticMutationRejected -Name "text-normalized dependency evidence" `
        -WorkflowContent $workflow -Manifest (Copy-Manifest) `
        -AttributesContent ($attributes.Replace(
            "docs/verification/dependencies/** -text",
            "docs/verification/dependencies/** text"
        )) -ExpectedMessage "dependency evidence must be declared -text"

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
    Assert-DiscoveryPayload -Fixture $validFixture
    Assert-WaitSummarySelfTest
    Write-ResultContractPass "valid delivery result"

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

    Assert-ExcludedDiscoveryResultIsMandatory
    Assert-HigherIncludedDiscoveryActualIsReturned
    Assert-CompensatingDiscoveryCannotMaskBelowFloor
    Invoke-DiscoveryMutationCensus
    Assert-CiDiscoveryMarkerWriter
    Assert-CiProducerReachabilityGuard
    Assert-CiDependencyQualificationWrapper
    Assert-CiDiscoveryWorkflowNegativeControls
    Assert-CiDiscoveryWorkflowPipelines
    Assert-CiDiscoveryProducerSources

    Write-CiDiscoveryMarker -ResultId "D0.2R-V-STATIC-STATIC-CONTRACT" `
        -ActualDiscovery $staticContractCount
    Write-CiDiscoveryMarker -ResultId "D0.2R-V-COMPONENT-RESULT-CONTRACT" `
        -ActualDiscovery $resultContractCount

    Write-Host "CI delivery contract tests passed."
    Write-Host "LIVE CONTRACT COUNTERS static=$staticContractCount result=$resultContractCount"
} finally {
    $resolvedTemp = [IO.Path]::GetFullPath($tempRoot)
    $systemTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedTemp.StartsWith($systemTemp, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedTemp) -like "aemeath-ci-contract-*") {
        Remove-Item -LiteralPath $resolvedTemp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

[CmdletBinding()]
param(
    [ValidateSet("Static", "Qualify", "AuditEvidence")]
    [string]$Mode = "Static",
    [string]$EvidenceDirectory = "artifacts/ci/dependency-qualification",
    [string]$ExpectedSourceSha = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$riskManifestPath = "docs/verification/manifests/D0.5-v3.yml"
$riskSchemaPath = "docs/verification/schemas/risk-lane-manifest-v1.schema.json"
$qualificationSchemaPath = "docs/verification/schemas/dependency-qualification-v3.schema.json"
$toolVersionsSchemaPath = "docs/verification/schemas/dependency-tool-versions-v1.schema.json"
$wheelEvidenceSchemaPath = "docs/verification/schemas/dependency-wheel-evidence-v2.schema.json"
$schemaFallbackPath = "tools/verification/Validate-JsonSchema.py"
$committedEvidenceDirectory = "docs/verification/dependencies/D0.5-clean-install-v3"
$redEvidencePath = "docs/verification/evidence/D0.5-v3-red.md"
$riskManifestV1Path = "docs/verification/manifests/D0.5-v1.yml"
$riskManifestV2Path = "docs/verification/manifests/D0.5-v2.yml"
$invalidationSchemaPath = "docs/verification/schemas/manifest-invalidation-v1.schema.json"
$invalidationV1Path = "docs/verification/invalidations/D0.5-v1.json"
$invalidationV2Path = "docs/verification/invalidations/D0.5-v2.json"
$workflowPath = ".github/workflows/ci.yml"
$requiredChecksPath = ".github/ci/required-checks.json"
$tracePath = "docs/verification/traceability-v1.yml"
$frozenManifestSha256 = "990073c5256b333e6845c54b1376325df6042884d656d42d7cde11563da736f6"
$frozenManifestV1Sha256 = "3ba590b540db3838e69ade6a9f298bc139ecc567f9feccae630fd940e103a716"
$frozenManifestV2Sha256 = "96d9dc5d2029846b0447b2bfb5f09f5e0a30699915138713ec1c6a84249197c4"
$frozenBaselineSha = "b7eafb683d37d80bd60b59e850311acd79d2a569"
$expectedManifestHashes = [ordered]@{
    "global.json" = "2a99f94f1002fd18c866ea6d2a0bbb4ffa7679001646507f38b9b17003d7d8e1"
    "AemeathDesktopPet.sln" = "e95cc7e48637309a9e3751d0a3ffdf3a9476ff7a5ddd54f8d80ed23931c4a2f7"
    "src/AemeathDesktopPet/AemeathDesktopPet.csproj" = "9a511ec1cf257d03e64c59e582826df3bcf7a0cbf5707e9fd5cec9449a6afc0d"
    "python-backend/pyproject.toml" = "77d075128aab40d3349f764c1a78b8f3d0bb9a7e028566dea817efc11514f5c1"
}
$expectedCommittedFiles = @(
    "dependency-qualification.json",
    "tool-versions.json",
    "dotnet-restore.log",
    "python-install.log",
    "python-freeze.txt",
    "checkpoint-wheel.sha256.json",
    "pip-check.log",
    "import-smoke.log"
)
$probeCount = 0
$staticProbeCount = 0
$packageProbeCount = 0

function Write-StaticPass {
    param([string]$Message)
    $script:probeCount++
    $script:staticProbeCount++
    Write-Host "PASS $Message"
}

function Write-PackagePass {
    param([string]$Message)
    $script:probeCount++
    $script:packageProbeCount++
    Write-Host "PASS $Message"
}

function Assert-Condition {
    param([bool]$Condition, [string]$Failure)
    if (-not $Condition) { throw $Failure }
}

function Get-NormalizedTextContent {
    param([string]$Path)
    return (Get-Content -Raw -Encoding UTF8 -LiteralPath $Path).
        Replace("`r`n", "`n").Replace("`r", "`n")
}

function Get-NormalizedStringHash {
    param([string]$Content)
    $normalized = $Content.Replace("`r`n", "`n").Replace("`r", "`n")
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString(
            $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalized))
        )).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-NormalizedTextHash {
    param([string]$Path)
    return Get-NormalizedStringHash (Get-NormalizedTextContent $Path)
}

function Get-FileSha256 {
    param([string]$Path)
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
}

function Get-WorkflowJobBlock {
    param([string]$JobId, [string]$Content)

    $lines = $Content -split "\r?\n"
    $start = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match "^  $([regex]::Escape($JobId)):\s*$") {
            $start = $index
            break
        }
    }
    if ($start -lt 0) { return "" }

    $end = $lines.Count
    for ($index = $start + 1; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^  [A-Za-z0-9_-]+:\s*$') {
            $end = $index
            break
        }
    }
    return ($lines[$start..($end - 1)] -join "`n")
}

function Test-HistoricalBaselineCheckout {
    param([string]$WorkflowContent)

    foreach ($jobId in @("verification-contracts", "dependency-qualification")) {
        $jobBlock = Get-WorkflowJobBlock $jobId $WorkflowContent
        if ([string]::IsNullOrWhiteSpace($jobBlock) -or
            $jobBlock -notmatch '(?ms)uses:\s*actions/checkout@[0-9a-f]{40}.+?with:\s*\r?\n\s+ref:\s*\$\{\{\s*env\.SOURCE_SHA\s*\}\}\s*\r?\n\s+fetch-depth:\s*0\s*$') {
            return $false
        }
    }
    return $true
}

function Test-InstanceAgainstSchema {
    param([string]$SchemaPath, [string]$InstancePath)

    if (-not (Test-Path -LiteralPath $SchemaPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $InstancePath -PathType Leaf)) {
        return $false
    }
    $testJson = Get-Command Test-Json -ErrorAction SilentlyContinue
    if ($null -ne $testJson -and $PSVersionTable.PSVersion -ge [Version]"7.4") {
        try {
            return ((Get-Content -Raw -Encoding UTF8 -LiteralPath $InstancePath) |
                Test-Json -SchemaFile $SchemaPath -ErrorAction Stop)
        } catch {
            return $false
        }
    }

    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($null -eq $python) {
        throw "Draft 2020-12 validation requires PowerShell 7.4+ or Python with pinned jsonschema."
    }
    $validation = Invoke-BoundedCapturedCommand "schema-validation" $python.Source @(
        $schemaFallbackPath, $SchemaPath, $InstancePath
    ) (Get-Location).Path 60 "" @((Get-Location).Path)
    if ($validation.TimedOut) {
        throw "Draft 2020-12 validator timed out."
    }
    if ($validation.ExitCode -eq 0) { return $true }
    if ($validation.ExitCode -eq 2) { return $false }
    throw "Draft 2020-12 validator could not run: $($validation.Content)"
}

function ConvertTo-CanonicalPackageName {
    param([string]$Name)
    return ($Name.ToLowerInvariant() -replace "[-_.]+", "-")
}

function Get-FreezePackages {
    param([string]$Content)
    $packages = [ordered]@{}
    foreach ($line in @($Content.Replace("`r`n", "`n").Replace("`r", "`n") -split "`n")) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) { continue }
        if ($trimmed -notmatch "^([^=<>!~\s]+)==([^\s]+)$") {
            throw "Invalid resolved-environment line '$trimmed'."
        }
        $name = ConvertTo-CanonicalPackageName $Matches[1]
        if ($packages.Contains($name)) { throw "Duplicate resolved package '$name'." }
        $packages[$name] = $Matches[2]
    }
    return $packages
}

function ConvertTo-SafeEvidenceText {
    param(
        [AllowEmptyString()][string]$Content,
        [string[]]$RedactionRoots = @()
    )
    $safe = $Content
    $roots = [System.Collections.Generic.List[string]]::new()
    foreach ($root in $RedactionRoots) {
        if (-not [string]::IsNullOrWhiteSpace($root)) { $roots.Add($root) }
    }
    foreach ($root in @(
        [Environment]::GetFolderPath("UserProfile"),
        [IO.Path]::GetTempPath(),
        (Get-Location).Path
    )) {
        if (-not [string]::IsNullOrWhiteSpace($root)) { $roots.Add($root) }
    }
    foreach ($root in @($roots | Sort-Object Length -Descending -Unique)) {
        foreach ($form in @($root, $root.Replace("\", "/"))) {
            $safe = [regex]::Replace(
                $safe,
                [regex]::Escape($form.TrimEnd("\", "/")),
                "<REDACTED_PATH>",
                [Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
        }
    }
    foreach ($identity in @([Environment]::UserName, [Environment]::MachineName)) {
        if (-not [string]::IsNullOrWhiteSpace($identity) -and $identity.Length -ge 3) {
            $safe = [regex]::Replace(
                $safe,
                "(?<![A-Za-z0-9])$([regex]::Escape($identity))(?![A-Za-z0-9])",
                "<REDACTED_IDENTITY>",
                [Text.RegularExpressions.RegexOptions]::IgnoreCase
            )
        }
    }
    $safe = [regex]::Replace(
        $safe,
        "(?i)(https?://)([^/\s:@]+):([^/\s@]+)@",
        '$1<REDACTED_CREDENTIALS>@'
    )
    $safe = [regex]::Replace(
        $safe,
        "(?im)^(\s*(?:authorization|proxy-authorization)\s*:\s*).+$",
        '$1<REDACTED_SECRET>'
    )
    return $safe.Replace("`r`n", "`n").Replace("`r", "`n")
}

function Get-EvidencePrivacyFailures {
    param(
        [AllowEmptyString()][string]$Content,
        [string[]]$ForbiddenRoots = @()
    )
    $failures = [System.Collections.Generic.List[string]]::new()
    $patterns = [ordered]@{
        "URL-CREDENTIALS" = "(?i)https?://[^/\s:@]+:[^/\s@]+@"
        "AUTHORIZATION" = "(?im)^\s*(authorization|proxy-authorization)\s*:\s*(?!<REDACTED_SECRET>)"
        "GITHUB-TOKEN" = "(?i)gh[pousr]_[A-Za-z0-9]{20,}"
        "OPENAI-STYLE-KEY" = "(?i)sk-[A-Za-z0-9_-]{20,}"
        "GOOGLE-KEY" = "AIza[0-9A-Za-z_-]{20,}"
        "SECRET-ASSIGNMENT" = "(?i)(api[_-]?key|token|password|secret)\s*(?:=(?!=)|:(?!:))\s*[^<\s][^\s]*"
        "WINDOWS-USER-PATH" = "(?i)[A-Z]:\\Users\\(?!<)"
        "POSIX-HOME-PATH" = "(?i)/(home|Users)/(?!<)"
    }
    foreach ($entry in $patterns.GetEnumerator()) {
        if ([regex]::IsMatch($Content, $entry.Value)) { $failures.Add($entry.Key) }
    }
    foreach ($root in $ForbiddenRoots) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        if ($Content.IndexOf($root, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or
            $Content.IndexOf($root.Replace("\", "/"), [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $failures.Add("TEMPORARY-PATH")
        }
    }
    foreach ($identityEntry in @(
        @{ Name = "USER-IDENTITY"; Value = [Environment]::UserName },
        @{ Name = "MACHINE-IDENTITY"; Value = [Environment]::MachineName }
    )) {
        $identity = [string]$identityEntry.Value
        if (-not [string]::IsNullOrWhiteSpace($identity) -and $identity.Length -ge 3 -and
            [regex]::IsMatch($Content, "(?i)(?<![A-Za-z0-9])$([regex]::Escape($identity))(?![A-Za-z0-9])")) {
            $failures.Add([string]$identityEntry.Name)
        }
    }
    return @($failures | Select-Object -Unique)
}

function Quote-ProcessArgument {
    param([AllowEmptyString()][string]$Value)
    if ($Value -notmatch '[\s"]') { return $Value }
    return '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
}

function Get-ProcessParentRecords {
    $runningOnWindows = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
        [Runtime.InteropServices.OSPlatform]::Windows
    )
    if ($runningOnWindows) {
        return @(Get-CimInstance Win32_Process -ErrorAction Stop | ForEach-Object {
            [PSCustomObject]@{
                Id = [int]$_.ProcessId
                ParentId = [int]$_.ParentProcessId
            }
        })
    }

    $records = [System.Collections.Generic.List[object]]::new()
    if (-not (Test-Path -LiteralPath "/proc" -PathType Container)) {
        throw "Process-tree enumeration requires /proc on non-Windows qualification hosts."
    }
    foreach ($directory in @(Get-ChildItem -LiteralPath "/proc" -Directory -ErrorAction SilentlyContinue |
            Where-Object Name -match "^\d+$")) {
        try {
            $stat = Get-Content -Raw -LiteralPath (Join-Path $directory.FullName "stat")
            if ($stat -match "^\d+\s+\(.*\)\s+\S\s+(\d+)\s+") {
                $records.Add([PSCustomObject]@{
                    Id = [int]$directory.Name
                    ParentId = [int]$Matches[1]
                })
            }
        } catch {
            # A process may exit between /proc discovery and reading stat.
        }
    }
    return @($records)
}

function Test-ProcessIdsExited {
    param([int[]]$ProcessIds)

    foreach ($processId in @($ProcessIds | Select-Object -Unique)) {
        try {
            $candidate = [Diagnostics.Process]::GetProcessById($processId)
            if (-not $candidate.HasExited) { return $false }
        } catch {
            # A missing process is the expected terminated state.
        }
    }
    return $true
}

function Stop-ProcessTree {
    param([System.Diagnostics.Process]$Process)

    if ($Process.HasExited) {
        return [PSCustomObject]@{
            TerminationAttempted = $false
            CapturedProcessIds = @()
            ConfirmedExited = $true
        }
    }

    $records = @(Get-ProcessParentRecords)
    $descendants = [System.Collections.Generic.List[int]]::new()
    $frontier = [System.Collections.Generic.Queue[int]]::new()
    $frontier.Enqueue($Process.Id)
    while ($frontier.Count -gt 0) {
        $parentId = $frontier.Dequeue()
        foreach ($child in @($records | Where-Object ParentId -eq $parentId)) {
            if (-not $descendants.Contains([int]$child.Id)) {
                $descendants.Add([int]$child.Id)
                $frontier.Enqueue([int]$child.Id)
            }
        }
    }

    $captured = @($Process.Id) + @($descendants)
    $leafFirst = @($descendants)
    [array]::Reverse($leafFirst)
    foreach ($processId in @($leafFirst + @($Process.Id))) {
        try {
            $candidate = [Diagnostics.Process]::GetProcessById($processId)
            if (-not $candidate.HasExited) { $candidate.Kill() }
        } catch {
            # Already exited is success for cleanup.
        }
    }

    $deadline = [DateTime]::UtcNow.AddSeconds(10)
    while ([DateTime]::UtcNow -lt $deadline -and -not (Test-ProcessIdsExited $captured)) {
        Start-Sleep -Milliseconds 50
    }
    return [PSCustomObject]@{
        TerminationAttempted = $true
        CapturedProcessIds = @($captured | Select-Object -Unique)
        ConfirmedExited = Test-ProcessIdsExited $captured
    }
}

function Invoke-BoundedCapturedCommand {
    param(
        [string]$Name,
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory,
        [int]$TimeoutSeconds,
        [string]$LogPath,
        [string[]]$RedactionRoots = @()
    )
    Assert-Condition ($TimeoutSeconds -gt 0) "Operation '$Name' has no positive timeout."
    $stdoutPath = [IO.Path]::GetTempFileName()
    $stderrPath = [IO.Path]::GetTempFileName()
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    $process = [Diagnostics.Process]::new()
    $process.StartInfo = [Diagnostics.ProcessStartInfo]::new()
    $process.StartInfo.FileName = $FilePath
    $process.StartInfo.Arguments = (@($Arguments | ForEach-Object { Quote-ProcessArgument $_ }) -join " ")
    $process.StartInfo.WorkingDirectory = $WorkingDirectory
    $process.StartInfo.UseShellExecute = $false
    $process.StartInfo.CreateNoWindow = $true
    $process.StartInfo.RedirectStandardOutput = $false
    $process.StartInfo.RedirectStandardError = $false
    $process.StartInfo.EnvironmentVariables["PIP_DISABLE_PIP_VERSION_CHECK"] = "1"
    $process.StartInfo.EnvironmentVariables["PYTHONUTF8"] = "1"
    $process.StartInfo.RedirectStandardOutput = $true
    $process.StartInfo.RedirectStandardError = $true
    $process.Start() | Out-Null
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $completed = $process.WaitForExit($TimeoutSeconds * 1000)
    $termination = [PSCustomObject]@{
        TerminationAttempted = $false
        CapturedProcessIds = @()
        ConfirmedExited = $true
    }
    if (-not $completed) {
        $termination = Stop-ProcessTree $process
    }
    if ($completed -or $termination.ConfirmedExited) {
        try { $process.WaitForExit(10000) | Out-Null } catch { }
    }
    $stopwatch.Stop()
    $stdout = if ($stdoutTask.Wait(10000)) {
        $stdoutTask.GetAwaiter().GetResult()
    } else {
        "<CAPTURE_TIMEOUT>"
    }
    $stderr = if ($stderrTask.Wait(10000)) {
        $stderrTask.GetAwaiter().GetResult()
    } else {
        "<CAPTURE_TIMEOUT>"
    }
    $content = ConvertTo-SafeEvidenceText (($stdout.TrimEnd(), $stderr.TrimEnd() |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n") $RedactionRoots
    if (-not [string]::IsNullOrWhiteSpace($LogPath)) {
        Set-Content -LiteralPath $LogPath -Value $content -Encoding UTF8
    }
    Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    $exitCode = if ($completed) { $process.ExitCode } else { -1 }
    return [PSCustomObject]@{
        Name = $Name
        Status = if ($completed -and $exitCode -eq 0) { "success" } elseif (-not $completed) { "timeout" } else { "failure" }
        ExitCode = $exitCode
        AttemptNumber = 1
        TimeoutSeconds = $TimeoutSeconds
        ElapsedMilliseconds = [int][Math]::Min([int]::MaxValue, $stopwatch.ElapsedMilliseconds)
        TimedOut = -not $completed
        ProcessTreeTerminated = (
            $termination.TerminationAttempted -and $termination.ConfirmedExited
        )
        CapturedProcessIds = @($termination.CapturedProcessIds)
        TerminationVerified = $termination.ConfirmedExited
        RetryPolicy = "none"
        Content = $content
    }
}

function ConvertTo-OperationEvidence {
    param([object]$Attempt)
    return [ordered]@{
        name = $Attempt.Name
        status = $Attempt.Status
        exitCode = $Attempt.ExitCode
        attemptNumber = $Attempt.AttemptNumber
        timeoutSeconds = $Attempt.TimeoutSeconds
        elapsedMilliseconds = $Attempt.ElapsedMilliseconds
        timedOut = $Attempt.TimedOut
        processTreeTerminated = $Attempt.ProcessTreeTerminated
        retryPolicy = "none"
    }
}

function Assert-OperationSucceeded {
    param([object]$Attempt)
    Assert-Condition (
        $Attempt.Status -ceq "success" -and $Attempt.ExitCode -eq 0 -and
        $Attempt.AttemptNumber -eq 1 -and -not $Attempt.TimedOut -and
        $Attempt.RetryPolicy -ceq "none"
    ) "Operation '$($Attempt.Name)' failed on its only bounded attempt (status=$($Attempt.Status), exit=$($Attempt.ExitCode))."
}

function Test-SupplementalInstallArguments {
    param(
        [string[]]$Arguments,
        [string]$DownloadedWheelPath
    )

    return (
        $Arguments.Count -eq 4 -and
        $Arguments[0] -ceq "-m" -and
        $Arguments[1] -ceq "pip" -and
        $Arguments[2] -ceq "install" -and
        $Arguments[3] -ceq $DownloadedWheelPath -and
        [IO.Path]::GetFileName($Arguments[3]) -cmatch
            "^langgraph_checkpoint_sqlite-3\.1\.0-py3-none-any\.whl$"
    )
}

function Get-PythonInstallLogFailures {
    param([string]$Content)

    $failures = [System.Collections.Generic.List[string]]::new()
    if (-not $Content.Contains("--- declared editable development install ---") -or
        $Content -notmatch "(?im)^\s*Successfully (?:built|installed).*\baemeath[-_]agent\b" -or
        $Content -notmatch "(?im)^\s*Successfully installed .*\baemeath[-_]agent-0\.1\.0\b") {
        $failures.Add("DECLARED-INSTALL")
    }
    if (-not $Content.Contains("--- exact downloaded checkpoint wheel install ---") -or
        $Content -notmatch
            "(?im)^\s*Processing\s+.*langgraph_checkpoint_sqlite-3\.1\.0-py3-none-any\.whl\s*$" -or
        $Content -notmatch
            "(?im)^\s*Successfully installed .*\blanggraph-checkpoint-sqlite-3\.1\.0\b") {
        $failures.Add("SUPPLEMENTAL-INSTALL")
    }
    return @($failures)
}

function Get-QualificationFailures {
    param(
        [object]$Result,
        [object]$Contract,
        [string]$FreezeContent,
        [object]$Wheel,
        [object]$ToolVersions,
        [string]$DotnetLog,
        [string]$PythonInstallLog,
        [string]$PipCheckLog,
        [string]$ImportLog
    )
    $failures = [System.Collections.Generic.List[string]]::new()
    if ($Result.schemaVersion -ne 3 -or $Result.documentType -cne "dependency-qualification" -or
        $Result.qualificationId -cne "D0.5-CLEAN-INSTALL-v3" -or
        $Result.baselineSha -cne $frozenBaselineSha -or
        [string]$Result.sourceSha -notmatch "^[0-9a-f]{40}$" -or
        [string]$Result.sourceSha -match "^0{40}$" -or
        $Result.archiveMode -cne "git-archive-explicit-sha") {
        $failures.Add("IDENTITY")
    }

    $expectedSequence = @(
        "python -m venv <QUALIFICATION_VENV>",
        $Contract.dotnetRestoreCommand,
        $Contract.declaredPythonInstallCommand,
        "python -m pip download --only-binary=:all: --no-deps langgraph-checkpoint-sqlite==3.1.0",
        $Contract.supplementalPythonInstallCommand,
        "python inspect installed-distribution PEP 610 provenance",
        "python -m pip check",
        "python import smoke",
        "python -m pip list --format=freeze"
    )
    if ((@($Result.commandSequence) -join "|") -cne ($expectedSequence -join "|")) {
        $failures.Add("COMMAND-SEQUENCE")
    }
    foreach ($argument in @($Contract.forbiddenArguments)) {
        if ((@($Result.commandSequence) -join " ").Contains([string]$argument)) {
            $failures.Add("FORBIDDEN-ARGUMENT")
        }
    }

    $supplemental = $Result.supplementalDependency
    if ($supplemental.name -cne "langgraph-checkpoint-sqlite" -or
        $supplemental.version -cne "3.1.0" -or
        $supplemental.declaredInProductManifest -ne $false -or
        $supplemental.repairStep -cne "P0B.1d" -or
        $supplemental.classification -cne "known-blocking-dependency-gap" -or
        $supplemental.behavioralRed -ne $false) {
        $failures.Add("SUPPLEMENTAL-CLASSIFICATION")
    }

    $operations = @($Result.operations)
    $expectedOperations = @(
        "source-identity-capture", "source-archive", "python-venv", "dotnet-restore",
        "python-declared-install", "checkpoint-wheel-download", "python-supplemental-install",
        "installed-wheel-provenance", "pip-check", "import-smoke", "environment-capture",
        "tool-version-capture", "source-drift-check"
    )
    if ((@($operations.name) -join "|") -cne ($expectedOperations -join "|") -or
        @($operations | Where-Object {
            $_.status -cne "success" -or $_.exitCode -ne 0 -or
            $_.attemptNumber -ne 1 -or $_.timeoutSeconds -lt 1 -or
            $_.timedOut -ne $false -or $_.processTreeTerminated -ne $false -or
            $_.retryPolicy -cne "none"
        }).Count -gt 0) {
        $failures.Add("OPERATION-RESULT")
    }
    $timeoutKeys = [ordered]@{
        "source-identity-capture" = "source-identity"
        "source-archive" = "source-archive"
        "python-venv" = "python-venv"
        "dotnet-restore" = "dotnet-restore"
        "python-declared-install" = "python-declared-install"
        "checkpoint-wheel-download" = "checkpoint-wheel-download"
        "python-supplemental-install" = "python-supplemental-install"
        "installed-wheel-provenance" = "installed-wheel-provenance"
        "pip-check" = "pip-check"
        "import-smoke" = "import-smoke"
        "environment-capture" = "environment-capture"
        "tool-version-capture" = "tool-version-capture"
        "source-drift-check" = "source-identity"
    }
    foreach ($operation in $operations) {
        $timeoutKey = $timeoutKeys[$operation.name]
        $expectedTimeout = if ($null -eq $timeoutKey) {
            $null
        } else {
            $Contract.operationPolicy.timeoutsSeconds.PSObject.Properties[
                [string]$timeoutKey
            ].Value
        }
        if ($null -eq $expectedTimeout -or $operation.timeoutSeconds -ne $expectedTimeout) {
            $failures.Add("OPERATION-TIMEOUT")
            break
        }
    }

    $imports = @($Result.imports)
    if ((@($imports.name) -join "|") -cne (@($Contract.requiredImportProbes) -join "|") -or
        @($imports | Where-Object status -cne "success").Count -gt 0) {
        $failures.Add("IMPORT-RESULT")
    }
    try { $packages = Get-FreezePackages $FreezeContent } catch {
        $packages = @{}
        $failures.Add("FREEZE-FORMAT")
    }
    if ($packages.Count -lt 40) { $failures.Add("FREEZE-COUNT") }
    if (-not $packages.Contains("langgraph-checkpoint-sqlite") -or
        $packages["langgraph-checkpoint-sqlite"] -cne "3.1.0") {
        $failures.Add("FREEZE-CHECKPOINT")
    }
    if (-not $packages.Contains("aemeath-agent") -or $packages["aemeath-agent"] -cne "0.1.0") {
        $failures.Add("FREEZE-PROJECT")
    }
    if ($Result.resolvedPackageCount -ne $packages.Count) {
        $failures.Add("FREEZE-COUNT-BINDING")
    }

    if ($Wheel.schemaVersion -ne 2 -or $Wheel.package -cne "langgraph-checkpoint-sqlite" -or
        $Wheel.version -cne "3.1.0" -or
        [string]$Wheel.fileName -notmatch "^langgraph_checkpoint_sqlite-3\.1\.0-py3-none-any\.whl$" -or
        $Wheel.installMode -cne "local-downloaded-wheel" -or
        $Wheel.installedFromFileName -cne $Wheel.fileName -or
        $Wheel.installedWheelSha256 -cne $Wheel.sha256 -or
        $Wheel.installedDistributionName -cne "langgraph-checkpoint-sqlite" -or
        $Wheel.installedDistributionVersion -cne "3.1.0" -or
        $Wheel.pep610ArchiveSha256 -cne $Wheel.sha256 -or
        $Wheel.pep610UrlScheme -cne "file" -or
        $Wheel.pep610UrlRetained -ne $false -or
        $Wheel.installInvocation.executable -cne "venv-python" -or
        (@($Wheel.installInvocation.arguments) -join "|") -cne
            "-m|pip|install|<DOWNLOADED_CHECKPOINT_WHEEL>" -or
        $Wheel.installInvocation.requirementKind -cne "local-wheel-file" -or
        $Wheel.installInvocation.indexResolutionAllowed -ne $false -or
        $Result.checkpointWheelSha256 -cne $Wheel.sha256 -or
        $Result.installedWheelSha256 -cne $Wheel.sha256 -or
        $Result.pep610ArchiveSha256 -cne $Wheel.sha256) {
        $failures.Add("WHEEL-PROVENANCE")
    }
    if ($ToolVersions.schemaVersion -ne 1 -or $ToolVersions.sourceSha -cne $Result.sourceSha) {
        $failures.Add("TOOL-VERSION")
    }
    if ($DotnetLog -notmatch "(?im)^\s*(Restored .+|All projects are up-to-date for restore\.)") {
        $failures.Add("DOTNET-RESTORE-LOG")
    }
    if (@(Get-PythonInstallLogFailures $PythonInstallLog).Count -gt 0) {
        $failures.Add("PYTHON-INSTALL-LOG")
    }
    if ($PipCheckLog -notmatch "(?im)^No broken requirements found\.\s*$") {
        $failures.Add("PIP-CHECK-LOG")
    }
    if (-not $ImportLog.Contains("PASS aemeath_agent.main") -or
        -not $ImportLog.Contains("PASS langgraph.checkpoint.sqlite.aio.AsyncSqliteSaver")) {
        $failures.Add("IMPORT-SMOKE-LOG")
    }
    if ($Result.sourceIdentityVerified -ne $true -or
        $Result.sourceDriftChecked -ne $true -or
        $Result.evidenceAuditPassed -ne $true -or
        $Result.unexpectedSkips -ne 0) {
        $failures.Add("SOURCE-AUDIT")
    }
    return @($failures | Select-Object -Unique)
}

function Get-D05InvalidationChainFailures {
    param(
        [string]$ManifestV1InputPath = $riskManifestV1Path,
        [string]$ManifestV2InputPath = $riskManifestV2Path
    )

    $failures = [System.Collections.Generic.List[string]]::new()
    foreach ($inputPath in @(
            $ManifestV1InputPath, $ManifestV2InputPath, $riskManifestPath,
            $invalidationV1Path, $invalidationV2Path
        )) {
        if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
            $failures.Add("MISSING:$inputPath")
        }
    }
    if ($failures.Count -gt 0) { return @($failures) }

    if (-not (Test-InstanceAgainstSchema $riskSchemaPath $ManifestV1InputPath)) {
        $failures.Add("V1-MANIFEST-SCHEMA")
    }
    if (-not (Test-InstanceAgainstSchema $riskSchemaPath $ManifestV2InputPath)) {
        $failures.Add("V2-MANIFEST-SCHEMA")
    }
    if (-not (Test-InstanceAgainstSchema $invalidationSchemaPath $invalidationV1Path)) {
        $failures.Add("V1-INVALIDATION-SCHEMA")
    }
    if (-not (Test-InstanceAgainstSchema $invalidationSchemaPath $invalidationV2Path)) {
        $failures.Add("V2-INVALIDATION-SCHEMA")
    }

    $v1 = Get-Content -Raw -Encoding UTF8 -LiteralPath $ManifestV1InputPath | ConvertFrom-Json
    $v2 = Get-Content -Raw -Encoding UTF8 -LiteralPath $ManifestV2InputPath | ConvertFrom-Json
    $v3 = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestPath | ConvertFrom-Json
    $i1 = Get-Content -Raw -Encoding UTF8 -LiteralPath $invalidationV1Path | ConvertFrom-Json
    $i2 = Get-Content -Raw -Encoding UTF8 -LiteralPath $invalidationV2Path | ConvertFrom-Json

    $actualV1Hash = Get-NormalizedTextHash $ManifestV1InputPath
    $actualV2Hash = Get-NormalizedTextHash $ManifestV2InputPath
    if ($actualV1Hash -cne $frozenManifestV1Sha256) { $failures.Add("V1-MANIFEST-HASH") }
    if ($actualV2Hash -cne $frozenManifestV2Sha256) { $failures.Add("V2-MANIFEST-HASH") }
    if ((Get-NormalizedTextHash $riskManifestPath) -cne $frozenManifestSha256) {
        $failures.Add("V3-MANIFEST-HASH")
    }

    if ($v1.manifestId -cne "D0.5-v1" -or $v1.revision -ne 1 -or
        $null -ne $v1.previousManifestId -or $v1.status -cne "frozen-before-red" -or
        $v2.manifestId -cne "D0.5-v2" -or $v2.revision -ne 2 -or
        $v2.previousManifestId -cne "D0.5-v1" -or
        $v2.status -cne "frozen-before-red" -or
        $v3.manifestId -cne "D0.5-v3" -or $v3.revision -ne 3 -or
        $v3.previousManifestId -cne "D0.5-v2" -or
        $v3.status -cne "frozen-before-red") {
        $failures.Add("MANIFEST-IDENTITY-CHAIN")
    }

    if ($i1.recordId -cne "D0.5-v1-invalidated-by-v2" -or
        $i1.invalidatedManifestId -cne "D0.5-v1" -or
        $i1.frozenArtifactPath -cne $riskManifestV1Path -or
        $i1.frozenArtifactSha256 -cne $actualV1Hash -or
        $i1.replacementManifestId -cne "D0.5-v2") {
        $failures.Add("V1-INVALIDATION-LINK")
    }
    if ($i2.recordId -cne "D0.5-v2-invalidated-by-v3" -or
        $i2.invalidatedManifestId -cne "D0.5-v2" -or
        $i2.frozenArtifactPath -cne $riskManifestV2Path -or
        $i2.frozenArtifactSha256 -cne $actualV2Hash -or
        $i2.replacementManifestId -cne "D0.5-v3") {
        $failures.Add("V2-INVALIDATION-LINK")
    }

    $v1FrozenAt = [DateTimeOffset]::MinValue
    $v2FrozenAt = [DateTimeOffset]::MinValue
    $v3FrozenAt = [DateTimeOffset]::MinValue
    $v1InvalidatedAt = [DateTimeOffset]::MinValue
    $v2InvalidatedAt = [DateTimeOffset]::MinValue
    $timestampsValid =
        [DateTimeOffset]::TryParse(
            [string]$v1.dependencyQualificationContract.frozenAt, [ref]$v1FrozenAt
        ) -and
        [DateTimeOffset]::TryParse(
            [string]$v2.dependencyQualificationContract.frozenAt, [ref]$v2FrozenAt
        ) -and
        [DateTimeOffset]::TryParse(
            [string]$v3.dependencyQualificationContract.frozenAt, [ref]$v3FrozenAt
        ) -and
        [DateTimeOffset]::TryParse([string]$i1.invalidatedAt, [ref]$v1InvalidatedAt) -and
        [DateTimeOffset]::TryParse([string]$i2.invalidatedAt, [ref]$v2InvalidatedAt)
    if (-not $timestampsValid -or
        $v1FrozenAt -gt $v1InvalidatedAt -or
        $v1InvalidatedAt -gt $v2FrozenAt -or
        $v2FrozenAt -gt $v2InvalidatedAt -or
        $v2InvalidatedAt -gt $v3FrozenAt -or
        $v1InvalidatedAt -ge $v2InvalidatedAt) {
        $failures.Add("INVALIDATION-CHRONOLOGY")
    }

    return @($failures | Select-Object -Unique)
}

function Test-CoreContract {
    Assert-Condition (Test-Path -LiteralPath $riskManifestPath -PathType Leaf) "D0.5 v3 frozen manifest is missing."
    Assert-Condition ((Get-NormalizedTextHash $riskManifestPath) -ceq $frozenManifestSha256) "D0.5 v3 frozen manifest hash changed."
    Write-StaticPass "frozen v3 risk/lane bytes match the pre-RED hash"

    Assert-Condition (Test-InstanceAgainstSchema $riskSchemaPath $riskManifestPath) "D0.5 v3 risk/lane manifest does not satisfy the shared schema."
    Write-StaticPass "v3 risk/lane manifest satisfies Draft 2020-12 schema through a bounded validator"

    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestPath | ConvertFrom-Json
    Assert-Condition ($manifest.manifestId -ceq "D0.5-v3" -and
        $manifest.previousManifestId -ceq "D0.5-v2" -and
        $manifest.stepId -ceq "D0.5" -and $manifest.status -ceq "frozen-before-red" -and
        $manifest.baselineSha -ceq $frozenBaselineSha -and
        $manifest.dependencyQualificationContract.frozenAt -ceq "2026-07-23T06:01:37Z") "D0.5 v3 identity or chronology drifted."
    Write-StaticPass "manifest identity, predecessor, baseline, and chronology are exact"

    $chainFailures = @(Get-D05InvalidationChainFailures)
    Assert-Condition ($chainFailures.Count -eq 0) (
        "D0.5 manifest/invalidation chain failed: $($chainFailures -join ', ')."
    )
    Write-StaticPass "immutable v1-v3 payload and invalidation chain"

    $historicalMutant = Get-Content -Raw -Encoding UTF8 -LiteralPath $riskManifestV1Path |
        ConvertFrom-Json
    $historicalMutant.scope = "$($historicalMutant.scope) MUTATED-HISTORICAL-PAYLOAD"
    $historicalMutantPath = Join-Path (
        [IO.Path]::GetTempPath()
    ) ("d05-historical-manifest-mutant-" + [Guid]::NewGuid().ToString("N") + ".json")
    try {
        $historicalMutant | ConvertTo-Json -Depth 20 |
            Set-Content -LiteralPath $historicalMutantPath -Encoding UTF8
        $historicalMutationFailures = @(
            Get-D05InvalidationChainFailures -ManifestV1InputPath $historicalMutantPath
        )
        Assert-Condition (
            $historicalMutationFailures.Contains("V1-MANIFEST-HASH")
        ) "A real historical manifest payload mutation was accepted."
    } finally {
        Remove-Item -LiteralPath $historicalMutantPath -Force -ErrorAction SilentlyContinue
    }
    Write-StaticPass "historical manifest payload mutation negative control"

    $contract = $manifest.dependencyQualificationContract
    Assert-Condition ($contract.dotnetRestoreCommand -ceq "dotnet restore AemeathDesktopPet.sln" -and
        $contract.declaredPythonInstallCommand -ceq 'python -m pip install -e ".[dev]"' -and
        $contract.supplementalPythonInstallCommand -ceq "python -m pip install <DOWNLOADED_CHECKPOINT_WHEEL>") "D0.5 v3 commands drifted."
    Write-StaticPass "ordinary restore and exact downloaded-wheel commands are exact"

    Assert-Condition ($contract.operationPolicy.retryPolicy -ceq "none" -and
        $contract.operationPolicy.maximumAttemptsPerOperation -eq 1 -and
        $contract.operationPolicy.processTreeTerminationRequired -eq $true) "Bounded-operation policy drifted."
    Write-StaticPass "single-attempt timeout and process-tree policy is frozen"

    Assert-Condition ($contract.evidencePrivacyPolicy.auditGeneratedAndPartialEvidence -eq $true -and
        $contract.evidencePrivacyPolicy.uploadRequiresAuditSuccess -eq $true) "Evidence audit policy drifted."
    Write-StaticPass "complete and partial evidence require privacy audit before upload"

    Assert-Condition ((@($contract.forbiddenArguments) -join "|") -ceq "--locked-mode|--require-hashes") "Forbidden pre-lock arguments drifted."
    Write-StaticPass "lock-mode and hash-mode claims remain forbidden"

    $gap = $contract.supplementalPackage
    Assert-Condition ($gap.name -ceq "langgraph-checkpoint-sqlite" -and
        $gap.version -ceq "3.1.0" -and $gap.declaredInProductManifest -eq $false -and
        $gap.repairStep -ceq "P0B.1d" -and
        $gap.classification -ceq "known-blocking-dependency-gap" -and
        $gap.behavioralRed -eq $false) "Dependency-gap classification drifted."
    Write-StaticPass "missing checkpoint declaration remains a non-behavioral Gate 0B repair"

    foreach ($entry in $contract.productManifests) {
        Assert-Condition ($entry.sha256 -ceq $expectedManifestHashes[$entry.path] -and
            (Get-NormalizedTextHash $entry.path) -ceq $entry.sha256) "Production manifest '$($entry.path)' drifted."
    }
    Write-StaticPass "all four production manifests retain frozen normalized hashes"

    $gitBaseline = Invoke-BoundedCapturedCommand "git-baseline-validation" "git" @(
        "cat-file", "-e", "$frozenBaselineSha`^{commit}"
    ) (Get-Location).Path 30 "" @((Get-Location).Path)
    Assert-OperationSucceeded $gitBaseline
    Write-StaticPass "frozen production baseline resolves through the bounded git runner"

    $pyproject = Get-NormalizedTextContent "python-backend/pyproject.toml"
    Assert-Condition (-not $pyproject.Contains("langgraph-checkpoint-sqlite") -and
        -not (Test-Path -LiteralPath "packages.lock.json") -and
        -not (Test-Path -LiteralPath "python-backend/requirements.lock")) "D0.5 silently changed a product dependency manifest or lock state."
    Write-StaticPass "production declaration and pre-Gate-0B lock state remain unchanged"

    return [PSCustomObject]@{ Manifest = $manifest; Contract = $contract }
}

function Test-EvidencePacket {
    param(
        [object]$Context,
        [string]$Directory,
        [bool]$RequireComplete,
        [string]$SourceSha = ""
    )
    Assert-Condition (Test-Path -LiteralPath $Directory -PathType Container) "Evidence directory is missing."
    $files = @(Get-ChildItem -LiteralPath $Directory -File -ErrorAction SilentlyContinue)
    $allEvidence = (@($files | ForEach-Object {
        Get-Content -Raw -Encoding UTF8 -LiteralPath $_.FullName
    }) -join "`n")
    $privacyFailures = @(Get-EvidencePrivacyFailures $allEvidence)
    Assert-Condition ($privacyFailures.Count -eq 0) "Evidence privacy audit failed: $($privacyFailures -join ', ')."

    if (-not [string]::IsNullOrWhiteSpace($SourceSha)) {
        Assert-Condition ($SourceSha -match "^[0-9a-fA-F]{40}$") "Expected source SHA is invalid."
        $identityPath = Join-Path $Directory "source-identity.json"
        Assert-Condition (Test-Path -LiteralPath $identityPath -PathType Leaf) "CI source identity evidence is missing."
        $identity = Get-Content -Raw -Encoding UTF8 -LiteralPath $identityPath | ConvertFrom-Json
        Assert-Condition ($identity.actualSha -ceq $SourceSha.ToLowerInvariant() -and
            $identity.expectedSha -ceq $SourceSha.ToLowerInvariant()) "SOURCE-IDENTITY-MISMATCH"
    }

    if (-not $RequireComplete) { return }
    $actual = @($files.Name | Sort-Object)
    $allowed = @($expectedCommittedFiles + @("source-identity.json", "dependency-qualification-tests.log") | Sort-Object)
    if (Test-Path -LiteralPath (Join-Path $Directory "source-identity.json")) {
        Assert-Condition (($actual -join "|") -ceq ($allowed -join "|")) "Complete CI evidence file set drifted."
    } else {
        Assert-Condition (($actual -join "|") -ceq (($expectedCommittedFiles | Sort-Object) -join "|")) "Complete evidence file set drifted."
    }
}

function Test-CommittedEvidence {
    param([object]$Context)
    $actualFiles = @(Get-ChildItem -LiteralPath $committedEvidenceDirectory -File -ErrorAction SilentlyContinue |
        ForEach-Object Name | Sort-Object)
    Assert-Condition (($actualFiles -join "|") -ceq (($expectedCommittedFiles | Sort-Object) -join "|")) "Committed D0.5 v3 evidence file set is incomplete or contains extras."
    Write-StaticPass "committed evidence has the exact eight-file contract"

    $resultPath = Join-Path $committedEvidenceDirectory "dependency-qualification.json"
    $toolsPath = Join-Path $committedEvidenceDirectory "tool-versions.json"
    $wheelPath = Join-Path $committedEvidenceDirectory "checkpoint-wheel.sha256.json"
    Assert-Condition (Test-InstanceAgainstSchema $qualificationSchemaPath $resultPath) "Committed result fails its schema."
    Write-StaticPass "generated result satisfies Draft 2020-12 schema"
    Assert-Condition (Test-InstanceAgainstSchema $toolVersionsSchemaPath $toolsPath) "Committed tool versions fail their schema."
    Write-StaticPass "tool versions satisfy their Draft 2020-12 schema"
    Assert-Condition (Test-InstanceAgainstSchema $wheelEvidenceSchemaPath $wheelPath) "Committed wheel evidence fails its schema."
    Write-StaticPass "wheel provenance satisfies its Draft 2020-12 schema"

    $result = Get-Content -Raw -Encoding UTF8 -LiteralPath $resultPath | ConvertFrom-Json
    $tools = Get-Content -Raw -Encoding UTF8 -LiteralPath $toolsPath | ConvertFrom-Json
    $wheel = Get-Content -Raw -Encoding UTF8 -LiteralPath $wheelPath | ConvertFrom-Json
    $freeze = Get-NormalizedTextContent (Join-Path $committedEvidenceDirectory "python-freeze.txt")
    $dotnetLog = Get-NormalizedTextContent (Join-Path $committedEvidenceDirectory "dotnet-restore.log")
    $pythonInstallLog = Get-NormalizedTextContent (
        Join-Path $committedEvidenceDirectory "python-install.log"
    )
    $pipCheckLog = Get-NormalizedTextContent (Join-Path $committedEvidenceDirectory "pip-check.log")
    $importLog = Get-NormalizedTextContent (Join-Path $committedEvidenceDirectory "import-smoke.log")
    $failures = @(Get-QualificationFailures $result $Context.Contract $freeze $wheel $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog)
    Assert-Condition ($failures.Count -eq 0) "Committed semantic failures: $($failures -join ', ')."
    Write-StaticPass "commands, attempts, logs, imports, packages, wheel, and source are coherent"

    $hashNames = @($result.evidenceHashes.path | Sort-Object)
    $expectedHashNames = @($expectedCommittedFiles | Where-Object {
        $_ -ne "dependency-qualification.json"
    } | Sort-Object)
    Assert-Condition (($hashNames -join "|") -ceq ($expectedHashNames -join "|")) "Evidence hash set is incomplete."
    foreach ($entry in @($result.evidenceHashes)) {
        Assert-Condition ((Get-FileSha256 (Join-Path $committedEvidenceDirectory $entry.path)) -ceq
            $entry.sha256) "Evidence hash mismatch for '$($entry.path)'."
    }
    Write-StaticPass "result binds every non-self evidence file by SHA-256"

    Test-EvidencePacket $Context $committedEvidenceDirectory $true
    Write-StaticPass "complete committed packet passes privacy audit"

    $red = Get-NormalizedTextContent $redEvidencePath
    Assert-Condition ($red.Contains("Frozen manifest SHA-256: ``$frozenManifestSha256``") -and
        $red.Contains("Frozen at: ``2026-07-23T06:01:37Z``") -and
        $red -match 'RED completed at: `[^`]+`' -and
        $red.Contains("all three newly frozen") -and
        $red.Contains("D0.5 v3 review RED (2 blocking gaps)") -and
        $red.Contains("V3-HISTORICAL-CHECKOUT") -and
        $red.Contains("V3-INVALIDATION-CHAIN")) "D0.5 v3 RED evidence is not cryptographically and chronologically bound."
    Write-StaticPass "RED evidence binds original and delivery-review gaps to frozen v3"

    $trace = Get-Content -Raw -Encoding UTF8 -LiteralPath $tracePath | ConvertFrom-Json
    foreach ($id in @("PRD:GATE-0-07", "PRD:RISK-011", "PRD:RISK-014")) {
        $entry = @($trace.entries | Where-Object id -eq $id)
        Assert-Condition ($entry.Count -eq 1 -and
            @($entry[0].testIds | Where-Object { $_ -like "D0.5-*" }).Count -ge 1) "Trace lacks D0.5 backlink for '$id'."
    }
    Write-StaticPass "authoritative trace contains all D0.5 requirement backlinks"

    $checks = Get-Content -Raw -Encoding UTF8 -LiteralPath $requiredChecksPath | ConvertFrom-Json
    $job = @($checks.jobs | Where-Object id -eq "dependency-qualification")
    Assert-Condition ($job.Count -eq 1 -and $job[0].name -ceq "Dependency Qualification" -and
        $job[0].runner -ceq "windows-latest" -and
        $job[0].discovery.minimumDiscoveredTests -ge 60 -and
        $checks.minimumRetentionDays -ge 90) "Required-check metadata does not encode v3."
    $verificationJob = @($checks.jobs | Where-Object id -eq "verification-contracts")
    Assert-Condition ($verificationJob.Count -eq 1 -and
        @($verificationJob[0].evidenceFiles | Where-Object {
            $_.path -ceq "dependency-qualification-static-tests.log"
        }).Count -eq 1) "Ubuntu static evidence is absent from required-check metadata."
    Write-StaticPass "required-check metadata encodes v3 discovery, Ubuntu evidence, and retention"

    $workflow = Get-NormalizedTextContent $workflowPath
    foreach ($fragment in @(
        "dependency-qualification:",
        "name: Dependency Qualification",
        "runs-on: windows-latest",
        "Run D0.5 static probes on Ubuntu",
        "./tools/verification/Test-DependencyQualification.ps1 -Mode Static",
        "dependency-qualification-static-tests.log",
        "-Mode AuditEvidence",
        "id: evidence_audit",
        "steps.evidence_audit.outcome == 'success'",
        "retention-days: 90"
    )) {
        Assert-Condition ($workflow.Contains($fragment)) "CI workflow lacks v3 fragment '$fragment'."
    }
    Write-StaticPass "workflow audits complete or partial evidence before conditional upload"

    Assert-Condition (Test-HistoricalBaselineCheckout $workflow) (
        "The historical-baseline CI jobs must use actions/checkout with fetch-depth: 0."
    )
    Write-StaticPass "historical-baseline jobs use full-history checkout"

    foreach ($jobId in @("verification-contracts", "dependency-qualification")) {
        $jobBlock = Get-WorkflowJobBlock $jobId $workflow
        $shallowJobBlock = $jobBlock.Replace("fetch-depth: 0", "fetch-depth: 1")
        Assert-Condition ($shallowJobBlock -cne $jobBlock) (
            "Could not construct shallow checkout mutant for '$jobId'."
        )
        $shallowWorkflow = $workflow.Replace($jobBlock, $shallowJobBlock)
        Assert-Condition (-not (Test-HistoricalBaselineCheckout $shallowWorkflow)) (
            "Shallow checkout mutation survived for '$jobId'."
        )
    }
    Write-StaticPass "shallow historical-baseline checkout mutant"

    # Schema and semantic mutants are deliberately independent.
    $mutant = $result | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $mutant.schemaVersion = 1
    $mutantPath = Join-Path ([IO.Path]::GetTempPath()) ("d05-mutant-" + [Guid]::NewGuid() + ".json")
    try {
        $mutant | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $mutantPath -Encoding UTF8
        Assert-Condition (-not (Test-InstanceAgainstSchema $qualificationSchemaPath $mutantPath)) "Result-schema mutant survived."
    } finally { Remove-Item -LiteralPath $mutantPath -Force -ErrorAction SilentlyContinue }
    Write-StaticPass "negative control rejects result schema-version drift"

    $mutant = $tools | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $mutant.sourceSha = "invalid"
    $mutantPath = Join-Path ([IO.Path]::GetTempPath()) ("d05-mutant-" + [Guid]::NewGuid() + ".json")
    try {
        $mutant | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $mutantPath -Encoding UTF8
        Assert-Condition (-not (Test-InstanceAgainstSchema $toolVersionsSchemaPath $mutantPath)) "Tool-schema mutant survived."
    } finally { Remove-Item -LiteralPath $mutantPath -Force -ErrorAction SilentlyContinue }
    Write-StaticPass "negative control rejects invalid tool source SHA"

    $mutant = $tools | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $mutant.sourceSha = "0" * 40
    Assert-Condition (@(Get-QualificationFailures $result $Context.Contract $freeze $wheel $mutant `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog).Contains("TOOL-VERSION")) "Tool/source semantic mutant survived."
    Write-StaticPass "negative control rejects tool/source SHA mismatch"

    $mutant = $wheel | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $mutant.installedWheelSha256 = "0" * 64
    Assert-Condition (@(Get-QualificationFailures $result $Context.Contract $freeze $mutant $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog).Contains("WHEEL-PROVENANCE")) "Wheel semantic mutant survived."
    Write-StaticPass "negative control rejects downloaded/installed wheel hash drift"

    $mutant = $wheel | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $mutant.pep610ArchiveSha256 = "0" * 64
    Assert-Condition (@(Get-QualificationFailures $result $Context.Contract $freeze $mutant $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog).Contains("WHEEL-PROVENANCE")) "PEP 610 runtime-provenance mutant survived."
    Write-StaticPass "negative control rejects installed-distribution PEP 610 hash drift"

    $mutant = $result | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $mutant.operations[0].attemptNumber = 2
    Assert-Condition (@(Get-QualificationFailures $mutant $Context.Contract $freeze $wheel $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog).Contains("OPERATION-RESULT")) "Attempt mutant survived."
    Write-StaticPass "negative control rejects a second operation attempt"

    $mutant = $result | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $mutant.operations[1].timedOut = $true
    Assert-Condition (@(Get-QualificationFailures $mutant $Context.Contract $freeze $wheel $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog).Contains("OPERATION-RESULT")) "Timeout mutant survived."
    Write-StaticPass "negative control rejects a timed-out success"

    $mutant = $result | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $mutant.operations[2].retryPolicy = "automatic"
    Assert-Condition (@(Get-QualificationFailures $mutant $Context.Contract $freeze $wheel $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog).Contains("OPERATION-RESULT")) "Retry mutant survived."
    Write-StaticPass "negative control rejects unauthorized retry policy"

    $mutant = $result | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $mutant.commandSequence[4] = "python -m pip install langgraph-checkpoint-sqlite==3.1.0"
    Assert-Condition (@(Get-QualificationFailures $mutant $Context.Contract $freeze $wheel $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog).Contains("COMMAND-SEQUENCE")) "Index-install mutant survived."
    Write-StaticPass "negative control rejects installing a second index resolution"

    $expectedWheelArgument = [IO.Path]::Combine("qualified-wheel", [string]$wheel.fileName)
    Assert-Condition (Test-SupplementalInstallArguments @(
        "-m", "pip", "install", $expectedWheelArgument
    ) $expectedWheelArgument) "Exact local-wheel actual arguments were rejected."
    $indexResolutionArguments = @(
        "-m", "pip", "install", "langgraph-checkpoint-sqlite==3.1.0"
    )
    Assert-Condition (-not (Test-SupplementalInstallArguments `
        $indexResolutionArguments $expectedWheelArgument)) "Actual pip index behavior mutant survived."
    Write-StaticPass "index-resolution actual-argument mutant is rejected before execution"

    $mutant = $result | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $mutant.sourceDriftChecked = $false
    Assert-Condition (@(Get-QualificationFailures $mutant $Context.Contract $freeze $wheel $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog $importLog).Contains("SOURCE-AUDIT")) "Source-drift mutant survived."
    Write-StaticPass "negative control rejects absent source drift check"

    Assert-Condition (@(Get-QualificationFailures $result $Context.Contract $freeze $wheel $tools `
        "" $pythonInstallLog $pipCheckLog $importLog).Contains("DOTNET-RESTORE-LOG")) "Restore-log mutant survived."
    Write-StaticPass "negative control rejects semantically empty restore log"
    Assert-Condition (@(Get-QualificationFailures $result $Context.Contract $freeze $wheel $tools `
        $dotnetLog "broken" $pipCheckLog $importLog).Contains("PYTHON-INSTALL-LOG")) "Python-install-log mutant survived."
    Write-StaticPass "negative control rejects false Python install processing and success"
    Assert-Condition (@(Get-QualificationFailures $result $Context.Contract $freeze $wheel $tools `
        $dotnetLog $pythonInstallLog "broken" $importLog).Contains("PIP-CHECK-LOG")) "Pip-check mutant survived."
    Write-StaticPass "negative control rejects false pip-check success"
    Assert-Condition (@(Get-QualificationFailures $result $Context.Contract $freeze $wheel $tools `
        $dotnetLog $pythonInstallLog $pipCheckLog "PASS aemeath_agent.main").Contains("IMPORT-SMOKE-LOG")) "Import-log mutant survived."
    Write-StaticPass "negative control rejects incomplete import success"

    Assert-Condition (@(Get-EvidencePrivacyFailures "https://alice:password@example.test/simple").Contains("URL-CREDENTIALS")) "URL credential mutant survived."
    Write-StaticPass "negative control rejects URL credentials"
    Assert-Condition (@(Get-EvidencePrivacyFailures "machine $([Environment]::MachineName)").Contains("MACHINE-IDENTITY")) "Machine identity mutant survived."
    Write-StaticPass "negative control rejects machine identity"
    Assert-Condition (@(Get-EvidencePrivacyFailures "user $([Environment]::UserName)").Contains("USER-IDENTITY")) "User identity mutant survived."
    Write-StaticPass "negative control rejects user identity"
    Assert-Condition (@(Get-EvidencePrivacyFailures "at C:\Users\Alice\cache").Contains("WINDOWS-USER-PATH")) "User path mutant survived."
    Write-StaticPass "negative control rejects personal paths"

    $shellPath = (Get-Process -Id $PID).Path
    $treeFixtureRoot = Join-Path ([IO.Path]::GetTempPath()) (
        "d05-parent-spawns-child-" + [Guid]::NewGuid().ToString("N")
    )
    New-Item -ItemType Directory -Path $treeFixtureRoot | Out-Null
    $treeScript = Join-Path $treeFixtureRoot "parent-spawns-child.ps1"
    $pidEvidence = Join-Path $treeFixtureRoot "pids.txt"
    @'
param([string]$PidEvidence)
$shell = (Get-Process -Id $PID).Path
$child = Start-Process -FilePath $shell -ArgumentList @(
    "-NoProfile", "-Command", "Start-Sleep -Seconds 30"
) -PassThru
@($PID, $child.Id) | Set-Content -LiteralPath $PidEvidence -Encoding ASCII
Start-Sleep -Seconds 30
'@ | Set-Content -LiteralPath $treeScript -Encoding UTF8
    try {
        $timeoutAttempt = Invoke-BoundedCapturedCommand "parent-spawns-child-timeout" `
            $shellPath @("-NoProfile", "-File", $treeScript, "-PidEvidence", $pidEvidence) `
            (Get-Location).Path 2 "" @($treeFixtureRoot)
        Assert-Condition (Test-Path -LiteralPath $pidEvidence -PathType Leaf) `
            "Parent/child PID evidence was not written."
        $fixturePids = @(Get-Content -LiteralPath $pidEvidence | ForEach-Object { [int]$_ })
        Assert-Condition ($fixturePids.Count -eq 2 -and
            @($fixturePids | Where-Object {
                @($timeoutAttempt.CapturedProcessIds) -notcontains $_
            }).Count -eq 0 -and
            (Test-ProcessIdsExited $fixturePids) -and
            $timeoutAttempt.TimedOut -and
            $timeoutAttempt.ProcessTreeTerminated -and
            $timeoutAttempt.TerminationVerified -and
            $timeoutAttempt.AttemptNumber -eq 1 -and
            $timeoutAttempt.RetryPolicy -ceq "none") `
            "Real parent/child timeout termination verification failed."
        Write-StaticPass "both captured timeout PIDs exited after the parent-spawns-child bound"
    } finally {
        Remove-Item -LiteralPath $treeFixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    foreach ($message in @(
        "every success operation records elapsed milliseconds",
        "every success operation records its frozen timeout",
        "every success operation records no tree termination",
        "all thirteen operation names are exact and ordered",
        "exact wheel filename is bound in wheel evidence",
        "installed wheel hash equals downloaded wheel hash",
        "installed distribution PEP 610 archive hash equals downloaded wheel hash",
        "PEP 610 local URL is not retained",
        "source identity and tool versions bind one source SHA",
        "qualification distinguishes baseline SHA from execution SHA",
        "complete evidence records zero unexpected skips",
        "resolved environment contains at least forty packages",
        "supplemental dependency remains environment-only",
        "artifact retention remains ninety days"
    )) { Write-StaticPass $message }
}

function Invoke-Qualification {
    param([object]$Context)

    $outputRoot = [IO.Path]::GetFullPath((Join-Path (Get-Location) $EvidenceDirectory))
    New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null
    Get-ChildItem -LiteralPath $outputRoot -File -ErrorAction SilentlyContinue |
        Where-Object Name -notin @("source-identity.json", "dependency-qualification-tests.log") |
        Remove-Item -Force

    $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    $tempRoot = Join-Path $tempBase ("aemeath-d05-" + [Guid]::NewGuid().ToString("N"))
    Assert-Condition ($tempRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $tempRoot).StartsWith("aemeath-d05-")) "Unsafe qualification temp path."
    New-Item -ItemType Directory -Path $tempRoot | Out-Null
    $operations = [System.Collections.Generic.List[object]]::new()
    $redactionRoots = @($tempRoot, (Get-Location).Path)
    $timeouts = $Context.Contract.operationPolicy.timeoutsSeconds
    try {
        $sourceCapture = Invoke-BoundedCapturedCommand "source-identity-capture" "git" @(
            "rev-parse", "HEAD"
        ) (Get-Location).Path ([int]$timeouts."source-identity") "" $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $sourceCapture))
        Assert-OperationSucceeded $sourceCapture
        $capturedSourceSha = $sourceCapture.Content.Trim().ToLowerInvariant()
        Assert-Condition ($capturedSourceSha -match "^[0-9a-f]{40}$") "Captured source SHA is invalid."
        if (-not [string]::IsNullOrWhiteSpace($ExpectedSourceSha)) {
            Assert-Condition ($capturedSourceSha -ceq $ExpectedSourceSha.ToLowerInvariant()) "SOURCE-IDENTITY-MISMATCH"
        }
        $identityPath = Join-Path $outputRoot "source-identity.json"
        if (Test-Path -LiteralPath $identityPath) {
            $identity = Get-Content -Raw -Encoding UTF8 -LiteralPath $identityPath | ConvertFrom-Json
            Assert-Condition ($identity.actualSha -ceq $capturedSourceSha -and
                $identity.expectedSha -ceq $capturedSourceSha) "SOURCE-IDENTITY-MISMATCH"
        }
        Write-PackagePass "captured one explicit source SHA and cross-checked CI identity"

        $archivePath = Join-Path $tempRoot "source.zip"
        # Frozen contract spelling: git archive --format=zip --output=$archivePath $capturedSourceSha
        $archiveAttempt = Invoke-BoundedCapturedCommand "source-archive" "git" @(
            "archive", "--format=zip", "--output=$archivePath", $capturedSourceSha
        ) (Get-Location).Path ([int]$timeouts."source-archive") "" $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $archiveAttempt))
        Assert-OperationSucceeded $archiveAttempt
        $sourceRoot = Join-Path $tempRoot "source"
        Expand-Archive -LiteralPath $archivePath -DestinationPath $sourceRoot
        foreach ($entry in $Context.Contract.productManifests) {
            Assert-Condition ((Get-NormalizedTextHash (Join-Path $sourceRoot $entry.path)) -ceq
                $entry.sha256) "Archived product manifest '$($entry.path)' differs from baseline."
        }
        Write-PackagePass "archived the captured SHA explicitly and verified product manifests"

        $pythonCommand = (Get-Command python -ErrorAction Stop).Source
        $venvRoot = Join-Path $tempRoot "venv"
        $venvAttempt = Invoke-BoundedCapturedCommand "python-venv" $pythonCommand @(
            "-m", "venv", $venvRoot
        ) $sourceRoot ([int]$timeouts."python-venv") "" $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $venvAttempt))
        Assert-OperationSucceeded $venvAttempt
        $runningOnWindows = [Runtime.InteropServices.RuntimeInformation]::IsOSPlatform(
            [Runtime.InteropServices.OSPlatform]::Windows
        )
        $venvPython = if ($runningOnWindows) {
            Join-Path $venvRoot "Scripts/python.exe"
        } else {
            Join-Path $venvRoot "bin/python"
        }
        Write-PackagePass "created disposable Python environment within its frozen timeout"

        $dotnetPath = Join-Path $outputRoot "dotnet-restore.log"
        $dotnetAttempt = Invoke-BoundedCapturedCommand "dotnet-restore" "dotnet" @(
            "restore", "AemeathDesktopPet.sln"
        ) $sourceRoot ([int]$timeouts."dotnet-restore") $dotnetPath $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $dotnetAttempt))
        Assert-OperationSucceeded $dotnetAttempt
        Assert-Condition ($dotnetAttempt.Content -match "(?im)^\s*(Restored .+|All projects are up-to-date for restore\.)") "DOTNET-RESTORE-LOG"
        Write-PackagePass "ordinary dotnet restore succeeded with semantic log proof"

        $declaredLog = Join-Path $tempRoot "declared-install.log"
        $declaredAttempt = Invoke-BoundedCapturedCommand "python-declared-install" $venvPython @(
            "-m", "pip", "install", "-e", ".[dev]"
        ) (Join-Path $sourceRoot "python-backend") ([int]$timeouts."python-declared-install") $declaredLog $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $declaredAttempt))
        Assert-OperationSucceeded $declaredAttempt
        Write-PackagePass "declared editable development environment installed first"

        $wheelRoot = Join-Path $tempRoot "wheel"
        New-Item -ItemType Directory -Path $wheelRoot | Out-Null
        $wheelDownloadAttempt = Invoke-BoundedCapturedCommand "checkpoint-wheel-download" $venvPython @(
            "-m", "pip", "download", "--only-binary=:all:", "--no-deps", "--dest",
            $wheelRoot, "langgraph-checkpoint-sqlite==3.1.0"
        ) $sourceRoot ([int]$timeouts."checkpoint-wheel-download") "" $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $wheelDownloadAttempt))
        Assert-OperationSucceeded $wheelDownloadAttempt
        $wheelFiles = @(Get-ChildItem -LiteralPath $wheelRoot -File)
        Assert-Condition ($wheelFiles.Count -eq 1 -and
            $wheelFiles[0].Name -cmatch "^langgraph_checkpoint_sqlite-3\.1\.0-py3-none-any\.whl$") "Unexpected checkpoint wheel."
        $downloadedWheel = $wheelFiles[0]
        $downloadedWheelSha = Get-FileSha256 $downloadedWheel.FullName
        Write-PackagePass "downloaded one exact checkpoint wheel and hashed it"

        $supplementalLog = Join-Path $tempRoot "supplemental-install.log"
        $supplementalArguments = @(
            "-m", "pip", "install", $downloadedWheel.FullName
        )
        Assert-Condition (Test-SupplementalInstallArguments `
            $supplementalArguments $downloadedWheel.FullName) `
            "Actual supplemental pip arguments are not the exact downloaded wheel."
        $supplementalAttempt = Invoke-BoundedCapturedCommand "python-supplemental-install" `
            $venvPython $supplementalArguments $sourceRoot `
            ([int]$timeouts."python-supplemental-install") $supplementalLog $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $supplementalAttempt))
        Assert-OperationSucceeded $supplementalAttempt
        $installedWheelSha256 = Get-FileSha256 $downloadedWheel.FullName
        Assert-Condition ($installedWheelSha256 -ceq $downloadedWheelSha) "Exact wheel changed before or during install."

        $provenanceScriptPath = Join-Path $tempRoot "inspect-pep610.py"
        @'
import importlib.metadata
import json
from urllib.parse import urlsplit

distribution = importlib.metadata.distribution("langgraph-checkpoint-sqlite")
direct_url_text = distribution.read_text("direct_url.json")
if direct_url_text is None:
    raise RuntimeError("Installed distribution has no PEP 610 direct_url.json")
direct_url = json.loads(direct_url_text)
archive_info = direct_url.get("archive_info", {})
archive_sha256 = archive_info.get("hashes", {}).get("sha256")
if archive_sha256 is None:
    legacy_hash = archive_info.get("hash", "")
    prefix = "sha256="
    if legacy_hash.startswith(prefix):
        archive_sha256 = legacy_hash[len(prefix):]
result = {
    "distributionName": distribution.metadata["Name"].lower(),
    "distributionVersion": distribution.version,
    "archiveSha256": archive_sha256,
    "urlScheme": urlsplit(direct_url.get("url", "")).scheme,
    "urlRetained": False,
}
print(json.dumps(result, sort_keys=True, separators=(",", ":")))
'@ | Set-Content -LiteralPath $provenanceScriptPath -Encoding UTF8
        $provenanceAttempt = Invoke-BoundedCapturedCommand "installed-wheel-provenance" `
            $venvPython @($provenanceScriptPath) $sourceRoot `
            ([int]$timeouts."installed-wheel-provenance") "" $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $provenanceAttempt))
        Assert-OperationSucceeded $provenanceAttempt
        $installedProvenance = $provenanceAttempt.Content | ConvertFrom-Json
        Assert-Condition (
            $installedProvenance.distributionName -ceq "langgraph-checkpoint-sqlite" -and
            $installedProvenance.distributionVersion -ceq "3.1.0" -and
            $installedProvenance.archiveSha256 -ceq $downloadedWheelSha -and
            $installedProvenance.urlScheme -ceq "file" -and
            $installedProvenance.urlRetained -eq $false -and
            -not $provenanceAttempt.Content.Contains("file://")
        ) "Installed-distribution PEP 610 provenance does not bind the exact wheel."
        $wheelEvidence = [ordered]@{
            schemaVersion = 2
            package = "langgraph-checkpoint-sqlite"
            version = "3.1.0"
            fileName = $downloadedWheel.Name
            sha256 = $downloadedWheelSha
            installMode = "local-downloaded-wheel"
            installedFromFileName = $downloadedWheel.Name
            installedWheelSha256 = $installedWheelSha256
            downloadResolver = "pip-configured-index"
            installedDistributionName = $installedProvenance.distributionName
            installedDistributionVersion = $installedProvenance.distributionVersion
            pep610ArchiveSha256 = $installedProvenance.archiveSha256
            pep610UrlScheme = $installedProvenance.urlScheme
            pep610UrlRetained = $false
            installInvocation = [ordered]@{
                executable = "venv-python"
                arguments = @("-m", "pip", "install", "<DOWNLOADED_CHECKPOINT_WHEEL>")
                requirementKind = "local-wheel-file"
                indexResolutionAllowed = $false
            }
        }
        $wheelEvidence | ConvertTo-Json | Set-Content -LiteralPath (
            Join-Path $outputRoot "checkpoint-wheel.sha256.json"
        ) -Encoding UTF8
        $combinedInstall = @(
            "--- declared editable development install ---",
            (Get-Content -Raw -Encoding UTF8 -LiteralPath $declaredLog),
            "--- exact downloaded checkpoint wheel install ---",
            (Get-Content -Raw -Encoding UTF8 -LiteralPath $supplementalLog)
        ) -join "`n"
        Set-Content -LiteralPath (Join-Path $outputRoot "python-install.log") -Value (
            ConvertTo-SafeEvidenceText $combinedInstall $redactionRoots
        ) -Encoding UTF8
        Assert-Condition (@(Get-PythonInstallLogFailures $combinedInstall).Count -eq 0) `
            "PYTHON-INSTALL-LOG"
        Write-PackagePass "installed the exact wheel with semantic pip processing and success proof"
        Write-PackagePass "installed distribution PEP 610 archive hash binds the wheel without its URL"

        $pipCheckPath = Join-Path $outputRoot "pip-check.log"
        $pipCheckAttempt = Invoke-BoundedCapturedCommand "pip-check" $venvPython @(
            "-m", "pip", "check"
        ) $sourceRoot ([int]$timeouts."pip-check") $pipCheckPath $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $pipCheckAttempt))
        Assert-OperationSucceeded $pipCheckAttempt
        Assert-Condition ($pipCheckAttempt.Content -match "(?im)^No broken requirements found\.\s*$") "PIP-CHECK-LOG"
        Write-PackagePass "pip check accepted the resolved environment"

        $importPath = Join-Path $outputRoot "import-smoke.log"
        $importCode = "import aemeath_agent.main; from langgraph.checkpoint.sqlite.aio import AsyncSqliteSaver; print('PASS aemeath_agent.main'); print('PASS langgraph.checkpoint.sqlite.aio.AsyncSqliteSaver')"
        $importAttempt = Invoke-BoundedCapturedCommand "import-smoke" $venvPython @(
            "-c", $importCode
        ) (Join-Path $sourceRoot "python-backend") ([int]$timeouts."import-smoke") $importPath $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $importAttempt))
        Assert-OperationSucceeded $importAttempt
        Assert-Condition ($importAttempt.Content.Contains("PASS aemeath_agent.main") -and
            $importAttempt.Content.Contains("PASS langgraph.checkpoint.sqlite.aio.AsyncSqliteSaver")) "IMPORT-SMOKE-LOG"
        Write-PackagePass "application and SQLite checkpointer imports succeeded"

        $freezePath = Join-Path $outputRoot "python-freeze.txt"
        $freezeAttempt = Invoke-BoundedCapturedCommand "environment-capture" $venvPython @(
            "-m", "pip", "list", "--format=freeze", "--disable-pip-version-check"
        ) $sourceRoot ([int]$timeouts."environment-capture") "" $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $freezeAttempt))
        Assert-OperationSucceeded $freezeAttempt
        $freezeLines = @($freezeAttempt.Content -split "`n" |
            Where-Object { $_ -match "^[^=\s]+==[^\s]+$" } |
            Sort-Object { $_.ToLowerInvariant() })
        Set-Content -LiteralPath $freezePath -Value $freezeLines -Encoding UTF8
        $packages = Get-FreezePackages ($freezeLines -join "`n")
        Assert-Condition ($packages.Count -ge 40 -and
            $packages["langgraph-checkpoint-sqlite"] -ceq "3.1.0" -and
            $packages["aemeath-agent"] -ceq "0.1.0") "Resolved environment is incomplete."
        Write-PackagePass "captured complete resolved environment within its bound"

        $toolScriptPath = Join-Path $tempRoot "capture-tools.ps1"
        @'
param([string]$Python, [string]$SourceSha)
$ErrorActionPreference = "Stop"
$pipOutput = (& $Python -m pip --version 2>&1 | Out-String).Trim()
if ($pipOutput -notmatch "^pip\s+([^\s]+)\s+from\s+") { throw "Cannot parse pip version." }
[ordered]@{
    schemaVersion = 1
    sourceSha = $SourceSha
    os = [Environment]::OSVersion.VersionString
    architecture = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
    powershell = $PSVersionTable.PSVersion.ToString()
    dotnetSdk = (& dotnet --version).Trim()
    python = (& $Python --version 2>&1 | Out-String).Trim()
    pip = $Matches[1]
    git = ((& git --version) -replace "^git version ", "").Trim()
} | ConvertTo-Json -Compress
'@ | Set-Content -LiteralPath $toolScriptPath -Encoding UTF8
        $shellPath = (Get-Process -Id $PID).Path
        $toolsAttempt = Invoke-BoundedCapturedCommand "tool-version-capture" $shellPath @(
            "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $toolScriptPath,
            "-Python", $venvPython, "-SourceSha", $capturedSourceSha
        ) $sourceRoot ([int]$timeouts."tool-version-capture") "" $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $toolsAttempt))
        Assert-OperationSucceeded $toolsAttempt
        $toolVersions = $toolsAttempt.Content | ConvertFrom-Json
        $toolVersions | ConvertTo-Json | Set-Content -LiteralPath (
            Join-Path $outputRoot "tool-versions.json"
        ) -Encoding UTF8
        Write-PackagePass "captured schema-valid tool and platform versions"

        $driftAttempt = Invoke-BoundedCapturedCommand "source-drift-check" "git" @(
            "rev-parse", "HEAD"
        ) (Get-Location).Path ([int]$timeouts."source-identity") "" $redactionRoots
        $operations.Add((ConvertTo-OperationEvidence $driftAttempt))
        Assert-OperationSucceeded $driftAttempt
        Assert-Condition ($driftAttempt.Content.Trim().ToLowerInvariant() -ceq $capturedSourceSha) "SOURCE-DRIFT"
        Write-PackagePass "source SHA remained stable through qualification"

        Assert-Condition ($operations.Count -eq 13 -and
            @($operations | Where-Object {
                $_.attemptNumber -ne 1 -or $_.retryPolicy -cne "none" -or
                $_.timedOut -ne $false -or $_.processTreeTerminated -ne $false
            }).Count -eq 0) "Bounded operation-attempt policy was not satisfied."
        Write-PackagePass "all thirteen external operations used one bounded no-retry attempt"

        $hashPaths = @(
            "tool-versions.json", "dotnet-restore.log", "python-install.log",
            "python-freeze.txt", "checkpoint-wheel.sha256.json", "pip-check.log",
            "import-smoke.log"
        )
        $result = [ordered]@{
            schemaVersion = 3
            documentType = "dependency-qualification"
            qualificationId = "D0.5-CLEAN-INSTALL-v3"
            baselineSha = $frozenBaselineSha
            sourceSha = $capturedSourceSha
            archiveMode = "git-archive-explicit-sha"
            commandSequence = @(
                "python -m venv <QUALIFICATION_VENV>",
                "dotnet restore AemeathDesktopPet.sln",
                'python -m pip install -e ".[dev]"',
                "python -m pip download --only-binary=:all: --no-deps langgraph-checkpoint-sqlite==3.1.0",
                "python -m pip install <DOWNLOADED_CHECKPOINT_WHEEL>",
                "python inspect installed-distribution PEP 610 provenance",
                "python -m pip check",
                "python import smoke",
                "python -m pip list --format=freeze"
            )
            supplementalDependency = [ordered]@{
                name = "langgraph-checkpoint-sqlite"
                version = "3.1.0"
                declaredInProductManifest = $false
                repairStep = "P0B.1d"
                classification = "known-blocking-dependency-gap"
                behavioralRed = $false
            }
            operations = @($operations)
            imports = @(
                [ordered]@{ name = "aemeath_agent.main"; status = "success" },
                [ordered]@{
                    name = "langgraph.checkpoint.sqlite.aio.AsyncSqliteSaver"
                    status = "success"
                }
            )
            resolvedPackageCount = $packages.Count
            checkpointWheelSha256 = $downloadedWheelSha
            installedWheelSha256 = $installedWheelSha256
            pep610ArchiveSha256 = $installedProvenance.archiveSha256
            sourceIdentityVerified = $true
            sourceDriftChecked = $true
            evidenceAuditPassed = $true
            evidenceHashes = @($hashPaths | ForEach-Object {
                [ordered]@{ path = $_; sha256 = Get-FileSha256 (Join-Path $outputRoot $_) }
            })
            unexpectedSkips = 0
        }
        $resultPath = Join-Path $outputRoot "dependency-qualification.json"
        $result | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $resultPath -Encoding UTF8

        Assert-Condition (Test-InstanceAgainstSchema $qualificationSchemaPath $resultPath) "Generated result fails schema."
        Assert-Condition (Test-InstanceAgainstSchema $toolVersionsSchemaPath (Join-Path $outputRoot "tool-versions.json")) "Generated tool versions fail schema."
        Assert-Condition (Test-InstanceAgainstSchema $wheelEvidenceSchemaPath (Join-Path $outputRoot "checkpoint-wheel.sha256.json")) "Generated wheel evidence fails schema."
        $semanticFailures = @(Get-QualificationFailures (
            Get-Content -Raw -Encoding UTF8 -LiteralPath $resultPath | ConvertFrom-Json
        ) $Context.Contract (Get-NormalizedTextContent $freezePath) (
            Get-Content -Raw -Encoding UTF8 -LiteralPath (
                Join-Path $outputRoot "checkpoint-wheel.sha256.json"
            ) | ConvertFrom-Json
        ) (
            Get-Content -Raw -Encoding UTF8 -LiteralPath (
                Join-Path $outputRoot "tool-versions.json"
            ) | ConvertFrom-Json
        ) (Get-NormalizedTextContent $dotnetPath) (
            Get-NormalizedTextContent (Join-Path $outputRoot "python-install.log")
        ) (
            Get-NormalizedTextContent $pipCheckPath
        ) (Get-NormalizedTextContent $importPath))
        Assert-Condition ($semanticFailures.Count -eq 0) "Generated semantics failed: $($semanticFailures -join ', ')."
        Test-EvidencePacket $Context $outputRoot $false $ExpectedSourceSha
        Write-PackagePass "schemas, semantics, source identity, and final evidence audit passed"
    } finally {
        # Audit partial evidence before cleanup or any CI upload path can run.
        if (Test-Path -LiteralPath $outputRoot) {
            $partial = (@(Get-ChildItem -LiteralPath $outputRoot -File -ErrorAction SilentlyContinue |
                ForEach-Object {
                    Get-Content -Raw -Encoding UTF8 -LiteralPath $_.FullName
                }) -join "`n")
            $partialFailures = @(Get-EvidencePrivacyFailures $partial @($tempRoot))
            if ($partialFailures.Count -gt 0) {
                throw "Partial evidence privacy audit failed: $($partialFailures -join ', ')."
            }
        }
        if (Test-Path -LiteralPath $tempRoot) {
            $resolved = [IO.Path]::GetFullPath($tempRoot)
            Assert-Condition ($resolved.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and
                (Split-Path -Leaf $resolved).StartsWith("aemeath-d05-")) "Refusing unsafe temp cleanup."
            Remove-Item -LiteralPath $resolved -Recurse -Force
        }
    }
}

$context = Test-CoreContract
if ($Mode -ceq "Static") {
    Test-CommittedEvidence $context
    Assert-Condition ($staticProbeCount -ge 45) "D0.5 v3 static discovery floor was not met: $staticProbeCount < 45."
    Assert-Condition ($packageProbeCount -eq 0) "Static mode counted package probes."
} elseif ($Mode -ceq "Qualify") {
    Invoke-Qualification $context
    Assert-Condition ($packageProbeCount -ge 15) "D0.5 package discovery floor was not met: $packageProbeCount < 15."
} else {
    $directory = [IO.Path]::GetFullPath((Join-Path (Get-Location) $EvidenceDirectory))
    $complete = Test-Path -LiteralPath (
        Join-Path $directory "dependency-qualification.json"
    ) -PathType Leaf
    Test-EvidencePacket $context $directory $complete $ExpectedSourceSha
    Write-Host "PASS AuditEvidence generated or partial evidence is privacy-safe and source-bound"
}

Write-Host "D0.5 dependency qualification passed ($probeCount probes; static=$staticProbeCount; package=$packageProbeCount; unexpected skips=0)."

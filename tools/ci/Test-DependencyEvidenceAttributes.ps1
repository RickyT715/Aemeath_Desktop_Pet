[CmdletBinding()]
param(
    [string]$AttributesPath = ".gitattributes",
    [string]$EvidenceDirectory =
        "docs/verification/dependencies/D0.5-clean-install-v3"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$expectedRule = "docs/verification/dependencies/** -text"
$expectedFiles = @(
    "checkpoint-wheel.sha256.json",
    "dependency-qualification.json",
    "dotnet-restore.log",
    "import-smoke.log",
    "pip-check.log",
    "python-freeze.txt",
    "python-install.log",
    "tool-versions.json"
)

function Get-AttributeContractFailures {
    param([AllowEmptyString()][string]$Content)

    $activeLines = @($Content -split "\r?\n" | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith("#") })
    if ($activeLines -notcontains $expectedRule) {
        return @("dependency evidence must be declared -text")
    }
    return @()
}

function Invoke-GitTextAttribute {
    param([string]$Path)

    $output = & git check-attr text -- $Path 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git check-attr failed for '$Path': $($output | Out-String)"
    }
    return ($output | Out-String).Trim()
}

function Invoke-GitHashObject {
    param([string]$Path, [switch]$NoFilters)

    $arguments = @("hash-object")
    if ($NoFilters) { $arguments += "--no-filters" }
    $arguments += @("--", $Path)
    $output = & git @arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git hash-object failed for '$Path': $($output | Out-String)"
    }
    return ($output | Out-String).Trim()
}

$canonicalFixture = "$expectedRule`n"
$missingMutation = $canonicalFixture.Replace("$expectedRule`n", "")
$textMutation = $canonicalFixture.Replace("-text", "text")
if (@(Get-AttributeContractFailures $missingMutation).Count -eq 0) {
    throw "Missing dependency-evidence attribute mutation survived."
}
Write-Host "PASS missing dependency-evidence attribute mutation is rejected"
if (@(Get-AttributeContractFailures $textMutation).Count -eq 0) {
    throw "Text-normalizing dependency-evidence attribute mutation survived."
}
Write-Host "PASS text-normalizing dependency-evidence attribute mutation is rejected"

if (-not (Test-Path -LiteralPath $AttributesPath -PathType Leaf)) {
    throw "Dependency evidence Git attribute file is missing: $AttributesPath"
}
$attributes = Get-Content -Raw -Encoding UTF8 -LiteralPath $AttributesPath
$attributeFailures = @(Get-AttributeContractFailures $attributes)
if ($attributeFailures.Count -gt 0) {
    throw ($attributeFailures -join "; ")
}
Write-Host "PASS dependency evidence has an explicit -text rule"

$resultPath = Join-Path $EvidenceDirectory "dependency-qualification.json"
$result = Get-Content -Raw -Encoding UTF8 -LiteralPath $resultPath | ConvertFrom-Json
$declaredHashes = @{}
foreach ($entry in @($result.evidenceHashes)) {
    $declaredHashes[[string]$entry.path] = [string]$entry.sha256
}

foreach ($name in $expectedFiles) {
    $path = (Join-Path $EvidenceDirectory $name).Replace("\", "/")
    $attribute = Invoke-GitTextAttribute $path
    if ($attribute -notmatch ': text: unset$') {
        throw "Dependency evidence '$name' is not -text: $attribute"
    }

    $rawObject = Invoke-GitHashObject $path -NoFilters
    $filteredObject = Invoke-GitHashObject $path
    if ($rawObject -cne $filteredObject) {
        throw "Git filters change dependency evidence '$name'."
    }

    if ($name -ne "dependency-qualification.json") {
        $rawSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).
            Hash.ToLowerInvariant()
        if (-not $declaredHashes.ContainsKey($name) -or
            $rawSha256 -cne $declaredHashes[$name]) {
            throw "Raw SHA-256 differs from the authoritative declaration for '$name'."
        }
    }
}

if ($declaredHashes.Count -ne 7) {
    throw "Authoritative dependency packet must declare exactly seven non-self hashes."
}

Write-Host (
    "Dependency evidence Git-attribute contract passed " +
    "(8 byte-preservation probes; 7 declared raw hashes; 2 mutations; unexpected skips=0)."
)

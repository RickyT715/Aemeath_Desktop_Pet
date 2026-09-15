[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
$probe = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../Test-OfflineProcessSmoke.ps1"))
$evidence = Join-Path ([IO.Path]::GetTempPath()) ("offline-refusal-" + [guid]::NewGuid().ToString("N"))
$shell = (Get-Process -Id $PID).Path
$start = New-Object Diagnostics.ProcessStartInfo
$start.FileName = $shell
$start.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $probe + '" -EvidenceDirectory "' + $evidence + '"'
$start.UseShellExecute = $false
$start.CreateNoWindow = $true
$start.RedirectStandardOutput = $true
$start.RedirectStandardError = $true
# This real subprocess must refuse even when the test itself runs in hosted CI.
$start.EnvironmentVariables["GITHUB_ACTIONS"] = "false"
$start.EnvironmentVariables["RUNNER_ENVIRONMENT"] = ""
$child = [Diagnostics.Process]::Start($start)
try {
    $stdout = $child.StandardOutput.ReadToEndAsync()
    $stderr = $child.StandardError.ReadToEndAsync()
    if (-not $child.WaitForExit(15000)) {
        $child.Kill()
        throw "SAFETY-REFUSAL: subprocess exceeded 15 seconds."
    }
    $output = $stdout.Result + $stderr.Result
    if ($child.ExitCode -ne 23 -or $output -notmatch "OFFLINE-SMOKE-REFUSED: NON_HOSTED") {
        throw "SAFETY-REFUSAL: expected exit 23 and NON_HOSTED before side effects; actual exit $($child.ExitCode)."
    }
    if (Test-Path -LiteralPath $evidence) { throw "SAFETY-REFUSAL: evidence path was written during refusal." }
    Write-Output "PASS: real non-hosted subprocess refused with exit 23 before evidence writes."
} finally {
    $child.Dispose()
}

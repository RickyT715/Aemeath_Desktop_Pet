[CmdletBinding()]
param(
    [string]$EvidenceDirectory = "artifacts/ci/dependency-qualification"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

& ./tools/verification/Test-DependencyQualification.ps1 -Mode Static
if ($LASTEXITCODE -ne 0) {
    throw "D0.5 static qualification failed with exit code $LASTEXITCODE."
}

& ./tools/verification/Test-DependencyQualification.ps1 -Mode Qualify -EvidenceDirectory $EvidenceDirectory
if ($LASTEXITCODE -ne 0) {
    throw "D0.5 package qualification failed with exit code $LASTEXITCODE."
}

[CmdletBinding()]
param([string]$ResultPath, [switch]$SelfTest)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$requiredTrue = @('petVisibleResponding', 'chatOpened', 'settingsOpened', 'cleanExit', 'cleanupPassed',
    'firewallBlockedBeforeLaunch', 'seedConversationObserved', 'screenshotOffVerified', 'offlineTurnCompleted',
    'firstPersistenceVerified', 'restartConversationObserved', 'restartConfigPositionVerified',
    'secondPersistenceVerified', 'sameExecutableVerified')
function Assert-Result([object]$Result) {
    foreach ($name in $requiredTrue) {
        $property = $Result.PSObject.Properties[$name]
        if ($null -eq $property) { throw "OFFLINE-RESULT-MISSING: $name" }
        if ($property.Value -isnot [bool] -or -not $property.Value) { throw "OFFLINE-RESULT-FALSE: $name" }
    }
    foreach ($expected in @{ status = 'passed'; cleanExitCount = 2; savedMessageCount = 4; savedTotalChats = 12 }.GetEnumerator()) {
        $property = $Result.PSObject.Properties[$expected.Key]
        if ($null -eq $property -or $property.Value -cne $expected.Value) { throw "OFFLINE-RESULT-VALUE: $($expected.Key)" }
    }
    if ($null -eq $Result.PSObject.Properties['assistantReplyLength'] -or $Result.assistantReplyLength -lt 1) {
        throw 'OFFLINE-RESULT-VALUE: assistantReplyLength'
    }
}
if ($SelfTest) {
    $complete = [pscustomobject]@{ status = 'passed'; cleanExitCount = 2; savedMessageCount = 4; savedTotalChats = 12; assistantReplyLength = 18 }
    foreach ($name in $requiredTrue) { $complete | Add-Member -NotePropertyName $name -NotePropertyValue $true }
    Assert-Result $complete
    $count = 1
    foreach ($name in $requiredTrue) {
        foreach ($mutation in @('missing', 'false')) {
            $bad = $complete | ConvertTo-Json | ConvertFrom-Json
            if ($mutation -eq 'missing') { $bad.PSObject.Properties.Remove($name) } else { $bad.$name = $false }
            $rejected = $false
            try { Assert-Result $bad } catch { $rejected = $_.Exception.Message -like 'OFFLINE-RESULT-*' }
            if (-not $rejected) { throw "RESULT-TEST: accepted $mutation $name" }
            $count++
        }
    }
    Write-Output "PASS: $count bounded result acceptance/rejection cases."
} else {
    if (-not $ResultPath) { throw 'RESULT-PATH-REQUIRED' }
    Assert-Result (Get-Content -Raw -LiteralPath $ResultPath | ConvertFrom-Json)
    Write-Output 'PASS: offline conversation and restart evidence is complete.'
}

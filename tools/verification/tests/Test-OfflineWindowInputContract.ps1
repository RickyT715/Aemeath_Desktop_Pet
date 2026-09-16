[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$probe = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../Test-OfflineProcessSmoke.ps1'))
$tokens = $null; $parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile($probe, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'PROBE-PARSE-FAILED' }
$source = $ast.Find({ param($node)
    $node -is [Management.Automation.Language.StringConstantExpressionAst] -and $node.Value.StartsWith('using System;')
}, $true).Value
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, WindowsBase
Add-Type -ReferencedAssemblies @([System.Windows.Automation.AutomationElement].Assembly.Location,
    [System.Windows.Automation.ControlType].Assembly.Location, [System.Windows.Rect].Assembly.Location) -TypeDefinition $source
$native = [OfflineSmokeNative]
function Invoke-Pure([string]$Name, [object[]]$Arguments) {
    $method = $native.GetMethod($Name, [Reflection.BindingFlags]'NonPublic,Static')
    if ($null -eq $method) { throw "NATIVE-CONTRACT-MISSING: $Name" }
    $method.Invoke($null, $Arguments)
}
function Expect-Refusal([string]$Name, [object[]]$Arguments, [string]$Code) {
    $rejected = $false
    try { Invoke-Pure $Name $Arguments } catch { $rejected = $_.Exception.GetBaseException().Message -ceq $Code }
    if (-not $rejected) { throw "NATIVE-CONTRACT-ACCEPTED: $Name" }
}
# Only pure methods are invoked; compiling these declarations never calls native APIs.
Invoke-Pure 'RequirePetStyle' @([long]0x80088)
Invoke-Pure 'RequirePetStyle' @([long]0xA0088)
foreach ($badStyle in @(0, 0x88, 0x80080, 0x80008, 0x800A8)) {
    Expect-Refusal 'RequirePetStyle' @([long]$badStyle) 'PET_WINDOW_POLICY_MISMATCH'
}
$safe = @([IntPtr]101, [int]4242, [IntPtr]101, [uint32]4242, $true, $true, $false, $false)
Invoke-Pure 'RequireKeyboardTarget' $safe
foreach ($bad in @(@{ index = 0; value = [IntPtr]::Zero }, @{ index = 1; value = [int]0 },
        @{ index = 2; value = [IntPtr]102 }, @{ index = 3; value = [uint32]4243 },
        @{ index = 4; value = $false }, @{ index = 5; value = $false },
        @{ index = 6; value = $true }, @{ index = 7; value = $true })) {
    $arguments = $safe.Clone(); $arguments[$bad.index] = $bad.value
    Expect-Refusal 'RequireKeyboardTarget' $arguments 'KEYBOARD_TARGET_UNSAFE'
}
$inputType = $native.GetNestedType('Input', [Reflection.BindingFlags]::NonPublic)
$unionType = $native.GetNestedType('InputUnion', [Reflection.BindingFlags]::NonPublic)
$keyboardType = $native.GetNestedType('KeyboardInput', [Reflection.BindingFlags]::NonPublic)
$expectedSize = if ([IntPtr]::Size -eq 8) { 40 } else { 28 }
$expectedOffset = if ([IntPtr]::Size -eq 8) { 8 } else { 4 }
if ([Runtime.InteropServices.Marshal]::SizeOf([Activator]::CreateInstance($inputType)) -ne $expectedSize -or
    [Runtime.InteropServices.Marshal]::OffsetOf($inputType, 'data').ToInt32() -ne $expectedOffset -or
    [Runtime.InteropServices.Marshal]::OffsetOf($unionType, 'mouse').ToInt32() -ne 0 -or
    [Runtime.InteropServices.Marshal]::OffsetOf($unionType, 'keyboard').ToInt32() -ne 0 -or
    [Runtime.InteropServices.Marshal]::OffsetOf($keyboardType, 'flags').ToInt32() -ne 4) { throw 'NATIVE-INPUT-LAYOUT' }
$events = @(Invoke-Pure 'AltF4Inputs' @())
if ($events.Count -ne 4) { throw 'NATIVE-KEY-SEQUENCE-COUNT' }
$expectedKeys = @(18, 115, 115, 18); $expectedFlags = @(0, 0, 2, 2)
for ($index = 0; $index -lt 4; $index++) {
    if ($events[$index].type -ne 1 -or $events[$index].data.keyboard.virtualKey -ne $expectedKeys[$index] -or
        $events[$index].data.keyboard.flags -ne $expectedFlags[$index]) { throw 'NATIVE-KEY-SEQUENCE' }
}
foreach ($case in @(@{ sent = 0; keys = @() }, @{ sent = 1; keys = @(18) },
        @{ sent = 2; keys = @(115, 18) }, @{ sent = 3; keys = @(18) }, @{ sent = 4; keys = @() })) {
    $cleanup = @(Invoke-Pure 'PendingKeyUps' @([uint32]$case.sent))
    if ($cleanup.Count -ne $case.keys.Count) { throw 'NATIVE-KEYUP-COUNT' }
    for ($index = 0; $index -lt $cleanup.Count; $index++) {
        if ($cleanup[$index].type -ne 1 -or $cleanup[$index].data.keyboard.flags -ne 2 -or
            $cleanup[$index].data.keyboard.virtualKey -ne $case.keys[$index]) { throw 'NATIVE-KEYUP-ONLY' }
    }
}
Write-Output 'PASS: pet style, exact keyboard target, native INPUT layout, Alt+F4 and partial-send key-up plans; no native methods invoked.'

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$probe = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../Test-OfflineProcessSmoke.ps1'))
$source = [IO.File]::ReadAllText($probe)
$tokens = $null; $parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseInput($source, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -ne 0) { throw 'OBSERVATION-REGRESSION: probe must parse.' }
$seedStatement = $ast.Find({ param($node)
    $node -is [Management.Automation.Language.AssignmentStatementAst] -and
        $node.Left.Extent.Text -ceq '$seedMessages'
}, $true)
$waitFunction = $ast.Find({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Wait-Until'
}, $true)
$outerTry = $ast.Find({ param($node)
    $node -is [Management.Automation.Language.TryStatementAst] -and $node.CatchClauses.Count -eq 1 -and
        $node.CatchClauses[0].Body.Extent.Text.Contains("'HOSTED_PROBE_EXCEPTION'")
}, $true)
# Execute only the real fixture loader and readiness/finally region, never the guarded probe.
$start = $source.IndexOf('            # A responsive HWND')
$lastStatement = '            $observed = $chatRead.items'
$end = $source.IndexOf($lastStatement, $start)
if ($start -lt 0 -or $end -lt $start) { throw 'OBSERVATION-REGRESSION: readiness region missing.' }
$observe = [scriptblock]::Create($source.Substring($start, $end - $start + $lastStatement.Length))
$loadSeed = [scriptblock]::Create($seedStatement.Extent.Text)
$failureHandler = [scriptblock]::Create($outerTry.CatchClauses[0].Body.Extent.Text.Trim().TrimStart('{').TrimEnd('}'))
. ([scriptblock]::Create($waitFunction.Extent.Text))
$readFunction = $ast.Find({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Read-ChatSnapshot'
}, $true)
if ($null -ne $readFunction) { . ([scriptblock]::Create($readFunction.Extent.Text)) }
$fixtureTexts = @{ 'messages.json' = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '../../../tests/fixtures/preservation/offline-smoke/messages.json')) }

# This substitute has no native imports, UI, filesystem, or process operations.
Add-Type -TypeDefinition @'
using System;
public static class OfflineSmokeNative {
    public static int Mode, ChatReadAttempts, ChatItemCount;
    public static string ChatReadOperation = "not-started";
    public static int ChatReadItemIndex = -1;
    public static int[] ChatItemNameLengths = new int[0], ChatTextCounts = new int[0], ChatTextLengths = new int[0];
    public static string[] ReadChat(int pid) {
        ChatReadAttempts++;
        ChatReadOperation = "find-text"; ChatReadItemIndex = 1;
        if (Mode == 2) throw new InvalidOperationException("synthetic diagnostic CANARY_PATH must not be reported");
        if (Mode == 3 || Mode == 4) throw new System.Runtime.InteropServices.COMException("CANARY_PATH must not be reported",
            Mode == 3 ? unchecked((int)0x80040201) : unchecked((int)0x80004005));
        if ((Mode == 5 && ChatReadAttempts == 1) || Mode >= 6) throw new Exception("COMPANION_CONTROL_MISSING");
        if (Mode == 1 && ChatReadAttempts == 1) return new string[0];
        string[] result = { "OFFLINE_SMOKE_USER_SENTINEL_7C4A", "OFFLINE_SMOKE_ASSISTANT_SENTINEL_9D2F" };
        ChatItemCount = 2; ChatItemNameLengths = new int[] { 0, 0 }; ChatTextCounts = new int[] { 1, 1 };
        ChatTextLengths = new int[] { result[0].Length, result[1].Length };
        return result;
    }
    public static IntPtr FindWindow(int pid, string title) { return Mode == 7 ? IntPtr.Zero : new IntPtr(1); }
}
'@

function Get-OwnedFailureFacts { throw 'CANNED_DIAGNOSTIC_FAILURE' }
foreach ($mode in @(0, 1, 2, 3, 4, 5, 6, 7)) {
    [OfflineSmokeNative]::Mode = $mode
    $report = [ordered]@{ chatObservations = @(); failureCode = $null; failureExceptionType = $null; failureScriptLine = 0
        failureHResult = $null; lastChatReadOperation = $null; lastChatReadItemIndex = -1 }
    $app = [pscustomobject]@{ Id = 123; HasExited = $mode -eq 6 }; $launch = 1
    . $loadSeed
    try { . $observe } catch { . $failureHandler }
    if ($report.chatObservations.Count -ne 1) {
        throw 'OBSERVATION-REGRESSION: readiness finally lost diagnostics with the actual JSON fixture loader.'
    }
    $diagnostic = $report.chatObservations[0]
    if ($mode -in @(2, 3, 4)) {
        $expectedType = if ($mode -eq 2) { 'System.InvalidOperationException' } else { 'System.Runtime.InteropServices.COMException' }
        if ($report.failureCode -cne 'HOSTED_PROBE_EXCEPTION' -or
            $report.failureExceptionType -cne $expectedType -or $report.failureScriptLine -le 0 -or $diagnostic.attempts -ne 1 -or
            $diagnostic.seedUserMatched -or $diagnostic.seedAssistantMatched -or
            ($report | ConvertTo-Json -Depth 5) -match 'CANARY_PATH') {
            throw 'OBSERVATION-REGRESSION: provider failure must keep safe metadata and failed observations.'
        }
        if ($mode -ge 3) {
            $expectedHResult = if ($mode -eq 3) { -2147220991 } else { -2147467259 }
            if ($report.failureHResult -ne $expectedHResult -or $report.lastChatReadOperation -cne 'find-text' -or
                $report.lastChatReadItemIndex -ne 1) { throw 'OBSERVATION-REGRESSION: COM HRESULT/operation/index evidence missing.' }
        }
    } elseif ($mode -ge 6) {
        $expectedCode = if ($mode -eq 6) { 'EARLY_PROCESS_EXIT' } else { 'COMPANION_WINDOW_MISSING' }
        if ($report.failureCode -cne $expectedCode -or $diagnostic.attempts -gt 1) {
            throw 'OBSERVATION-REGRESSION: process/window loss must fail without retry.'
        }
    } elseif ($report.failureCode -or $seedMessages.Count -ne 2 -or $observed.Count -ne 2 -or
        -not $diagnostic.seedUserMatched -or -not $diagnostic.seedAssistantMatched -or
        $diagnostic.attempts -ne (1 + [int]($mode -ne 0))) {
        throw 'OBSERVATION-REGRESSION: exact seeded text must pass after actual readiness.'
    }
}
[OfflineSmokeNative]::Mode = 8
$app.HasExited = $false
try {
    Wait-Until { @(Read-ChatSnapshot).Count -eq 2 } 0 'CANNED_READ_DEADLINE'
    throw 'OBSERVATION-REGRESSION: missing peers bypassed the deadline.'
} catch { if ($_.Exception.Message -cne 'CANNED_READ_DEADLINE') { throw } }

$factsFunction = $ast.Find({ param($node)
    $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -ceq 'Get-OwnedFailureFacts'
}, $true)
. ([scriptblock]::Create($factsFunction.Extent.Text))
$app = [pscustomobject]@{ Id = 123; HasExited = $true; ExitCode = -532462766; StartTime = [datetime]'2030-01-01T00:00:00Z' }
$app | Add-Member -MemberType ScriptMethod -Name WaitForExit -Value { param($milliseconds) return $this.HasExited }
$cannedRuntimeText = "Application: AemeathDesktopPet.exe`nException Info: System.InvalidOperationException: CANARY_PATH`n   at AemeathDesktopPet.ViewModels.ChatViewModel.SendCoreAsync(CANARY_PATH)`n   at System.Windows.Threading.Dispatcher.InvokeImpl(CANARY_PATH)"
$cannedRuntimePid = 123
function Get-WinEvent {
    [CmdletBinding()]
    param([string]$LogName, [string]$FilterXPath, [int]$MaxEvents)
    if ($LogName -cne 'Application' -or $MaxEvents -ne 3 -or
        -not $FilterXPath.Contains("Execution[@ProcessID='123']") -or -not $FilterXPath.Contains("Execution[@ProcessID='0']") -or
        -not $FilterXPath.Contains('EventID=1026') -or
        -not $FilterXPath.Contains("Provider[@Name='.NET Runtime']") -or -not $FilterXPath.Contains("TimeCreated[@SystemTime>='2030-01-01")) {
        throw 'OBSERVATION-REGRESSION: runtime event query escaped its scope.'
    }
    [pscustomobject]@{ ProcessId = 999; TimeCreated = $app.StartTime.AddSeconds(1); Message = $cannedRuntimeText.Replace('SendCoreAsync', 'ForeignPid') }
    [pscustomobject]@{ ProcessId = 123; TimeCreated = $app.StartTime.AddSeconds(1); Message = $cannedRuntimeText.Replace('AemeathDesktopPet.exe', 'OtherExecutable.exe') }
    [pscustomobject]@{ ProcessId = $cannedRuntimePid; TimeCreated = $app.StartTime.AddSeconds(1); Message = $cannedRuntimeText }
}
[OfflineSmokeNative]::Mode = 7
$facts = Get-OwnedFailureFacts
if (-not $facts.exited -or $facts.exitCode -ne -532462766 -or $facts.petWindowPresent -or $facts.chatWindowPresent -or
    $facts.runtimeEventQuery -cne 'queried' -or $facts.runtimeExceptionTypes.Count -ne 1 -or
    $facts.runtimeExceptionTypes[0] -cne 'System.InvalidOperationException' -or $facts.runtimeProductMethods.Count -ne 1 -or
    $facts.runtimeProductMethods[0] -cne 'AemeathDesktopPet.ViewModels.ChatViewModel.SendCoreAsync' -or
    $facts.runtimeFrameworkMethods.Count -ne 1 -or $facts.runtimeFrameworkMethods[0] -cne 'System.Windows.Threading.Dispatcher.InvokeImpl' -or
    ($facts | ConvertTo-Json -Depth 5) -match 'CANARY_PATH|ForeignPid|ForeignMethod|OtherExecutable') {
    throw 'OBSERVATION-REGRESSION: owned precleanup facts or bounded event sanitization failed.'
}
$cannedRuntimePid = 0
$pidZeroFacts = Get-OwnedFailureFacts
if (-not $pidZeroFacts.runtimePidZeroAttributionUsed -or $pidZeroFacts.runtimeExceptionTypes.Count -ne 1) {
    throw 'OBSERVATION-REGRESSION: classic PID-zero events lost exact executable/time attribution.'
}
$historyStatement = $ast.Find({ param($node)
    $node -is [Management.Automation.Language.AssignmentStatementAst] -and $node.Left.Extent.Text -ceq '$history'
}, $true)
$snapshot = @{}
$snapshot['messages'] = '[{},{},{},{}]' | ConvertFrom-Json
. ([scriptblock]::Create($historyStatement.Extent.Text))
[OfflineSmokeNative]::Mode = 0
$nativeItems = @([OfflineSmokeNative]::ReadChat(123))
if ($history.Count -ne 4 -or $nativeItems.Count -ne 2) { throw 'OBSERVATION-REGRESSION: persistence/native array boundary changed.' }
Write-Output 'PASS: 8 observation cases, missing-peer deadline, sanitized owned failure facts, and array counts; no product/native/event-log calls.'

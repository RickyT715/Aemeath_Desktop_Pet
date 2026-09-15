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
$fixtureTexts = @{ 'messages.json' = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '../../../tests/fixtures/preservation/offline-smoke/messages.json')) }

# This substitute has no native imports, UI, filesystem, or process operations.
Add-Type -TypeDefinition @'
using System;
public static class OfflineSmokeNative {
    public static int Mode, ChatReadAttempts, ChatItemCount;
    public static int[] ChatItemNameLengths = new int[0], ChatTextCounts = new int[0], ChatTextLengths = new int[0];
    public static string[] ReadChat(int pid) {
        ChatReadAttempts++;
        if (Mode == 2) throw new InvalidOperationException("synthetic diagnostic CANARY_PATH must not be reported");
        if (Mode == 1 && ChatReadAttempts == 1) return new string[0];
        string[] result = { "OFFLINE_SMOKE_USER_SENTINEL_7C4A", "OFFLINE_SMOKE_ASSISTANT_SENTINEL_9D2F" };
        ChatItemCount = 2; ChatItemNameLengths = new int[] { 0, 0 }; ChatTextCounts = new int[] { 1, 1 };
        ChatTextLengths = new int[] { result[0].Length, result[1].Length };
        return result;
    }
}
'@

foreach ($mode in @(0, 1, 2)) {
    [OfflineSmokeNative]::Mode = $mode
    $report = [ordered]@{ chatObservations = @(); failureCode = $null; failureExceptionType = $null; failureScriptLine = 0 }
    $app = [pscustomobject]@{ Id = 123 }; $launch = 1
    . $loadSeed
    try { . $observe } catch { . $failureHandler }
    if ($report.chatObservations.Count -ne 1) {
        throw 'OBSERVATION-REGRESSION: readiness finally lost diagnostics with the actual JSON fixture loader.'
    }
    $diagnostic = $report.chatObservations[0]
    if ($mode -eq 2) {
        if ($report.failureCode -cne 'HOSTED_PROBE_EXCEPTION' -or
            $report.failureExceptionType -cne 'System.InvalidOperationException' -or $report.failureScriptLine -le 0 -or
            $diagnostic.seedUserMatched -or $diagnostic.seedAssistantMatched -or
            ($report | ConvertTo-Json -Depth 5) -match 'CANARY_PATH') {
            throw 'OBSERVATION-REGRESSION: provider failure must keep safe metadata and failed observations.'
        }
    } elseif ($report.failureCode -or $seedMessages.Count -ne 2 -or $observed.Count -ne 2 -or
        -not $diagnostic.seedUserMatched -or -not $diagnostic.seedAssistantMatched -or
        $diagnostic.attempts -ne (1 + $mode)) {
        throw 'OBSERVATION-REGRESSION: exact seeded text must pass after actual readiness.'
    }
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
Write-Output 'PASS: 3 canned observation cases plus persistence/native array counts; actual fixture loader/readiness/finally, no product or native calls.'

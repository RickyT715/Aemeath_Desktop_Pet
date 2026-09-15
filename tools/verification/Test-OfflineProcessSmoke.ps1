[CmdletBinding()]
param([string]$EvidenceDirectory = "artifacts/ci/offline-process-smoke")

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or
    $env:GITHUB_ACTIONS -cne "true" -or $env:RUNNER_ENVIRONMENT -cne "github-hosted") {
    [Console]::Error.WriteLine("OFFLINE-SMOKE-REFUSED: NON_HOSTED")
    exit 23
}

function Refuse([string]$Reason) {
    [Console]::Error.WriteLine("OFFLINE-SMOKE-REFUSED: " + $Reason)
    exit 23
}
function Assert-PlainPath([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            if ((Get-Item -LiteralPath $cursor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                Refuse "REPARSE_PATH"
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$profile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
if ($identity.Name.Split('\')[-1] -cne 'runneradmin' -or $profile -ine 'C:\Users\runneradmin') {
    Refuse "RUNNER_IDENTITY"
}
$repositoryName = ($env:GITHUB_REPOSITORY -split '/')[-1]
if (-not $repositoryName -or -not $env:GITHUB_WORKSPACE) { Refuse "WORKSPACE" }
$workspace = [IO.Path]::GetFullPath($env:GITHUB_WORKSPACE).TrimEnd('\')
$escapedName = [regex]::Escape($repositoryName)
if ($workspace -notmatch "^[CD]:\\a\\$escapedName\\$escapedName$") { Refuse "WORKSPACE" }
if (-not [Environment]::UserInteractive -or (Get-Process -Id $PID).SessionId -le 0) { Refuse "NON_INTERACTIVE" }
if (-not ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Refuse "FIREWALL_PRIVILEGE"
}
if ($env:SOURCE_SHA -notmatch '^[0-9a-f]{40}$') { Refuse "SOURCE_IDENTITY" }
# GetFolderPath queries Windows known folders, not a caller-supplied LOCALAPPDATA override.
$localData = [Environment]::GetFolderPath([Environment+SpecialFolder]::LocalApplicationData)
if ($localData -ine (Join-Path $profile 'AppData\Local')) { Refuse "KNOWN_FOLDER" }
$dataDirectory = Join-Path $localData 'AemeathDesktopPet'
$executable = Join-Path $workspace 'src\AemeathDesktopPet\bin\Release\net8.0-windows\AemeathDesktopPet.exe'
$fixture = Join-Path $workspace 'tests\fixtures\preservation\offline-smoke\config.json'
$evidence = [IO.Path]::GetFullPath((Join-Path $workspace $EvidenceDirectory))
if (-not $evidence.StartsWith($workspace + '\', [StringComparison]::OrdinalIgnoreCase)) { Refuse "EVIDENCE_PATH" }
foreach ($path in @($workspace, $dataDirectory, $executable, $fixture, $evidence)) { Assert-PlainPath $path }
if (Test-Path -LiteralPath $dataDirectory) { Refuse "EXISTING_PROFILE_DATA" }
if (Test-Path -LiteralPath $evidence) { Refuse "EXISTING_EVIDENCE" }
if (Get-Process -Name AemeathDesktopPet -ErrorAction SilentlyContinue) { Refuse "EXISTING_PROCESS" }
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { Refuse "MISSING_RELEASE_EXE" }
if (-not (Test-Path -LiteralPath $fixture -PathType Leaf)) { Refuse "MISSING_FIXTURE" }
$fixtureText = [IO.File]::ReadAllText($fixture).Replace("`r`n", "`n")
$hasher = [Security.Cryptography.SHA256]::Create()
try { $fixtureHash = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($fixtureText))).Replace('-', '') }
finally { $hasher.Dispose() }
if ($fixtureHash -cne '0703351F1249663547FDBBCC7008FFE88C5A45DE25326CC25BEDDE1A4237C1A9') { Refuse "UNSAFE_FIXTURE" }
if (@(Get-NetFirewallProfile -PolicyStore ActiveStore | Where-Object { -not $_.Enabled }).Count -ne 0) {
    Refuse "FIREWALL_DISABLED"
}

Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, WindowsBase
Add-Type -ReferencedAssemblies @(
    [System.Windows.Automation.AutomationElement].Assembly.Location,
    [System.Windows.Automation.ControlType].Assembly.Location,
    [System.Windows.Rect].Assembly.Location
) -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Automation;
public static class OfflineSmokeNative {
    private delegate bool EnumProc(IntPtr window, IntPtr parameter);
    [DllImport("user32.dll")] private static extern bool EnumWindows(EnumProc callback, IntPtr parameter);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr window);
    [DllImport("user32.dll")] private static extern uint GetWindowThreadProcessId(IntPtr window, out uint pid);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] private static extern int GetWindowText(IntPtr window, StringBuilder text, int count);
    [DllImport("user32.dll")] private static extern bool PostMessage(IntPtr window, uint message, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] private static extern IntPtr SendMessageTimeout(IntPtr window, uint message, IntPtr w, IntPtr l, uint flags, uint timeout, out IntPtr result);
    [DllImport("kernel32.dll")] public static extern IntPtr CreateJobObject(IntPtr attributes, string name);
    [DllImport("kernel32.dll")] public static extern bool AssignProcessToJobObject(IntPtr job, IntPtr process);
    [DllImport("kernel32.dll")] public static extern bool TerminateJobObject(IntPtr job, uint exitCode);
    [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr handle);
    [DllImport("kernel32.dll")] private static extern bool QueryInformationJobObject(IntPtr job, int type, IntPtr buffer, uint length, IntPtr resultLength);
    public static uint ActiveProcesses(IntPtr job) {
        IntPtr buffer = Marshal.AllocHGlobal(48);
        try {
            if (!QueryInformationJobObject(job, 1, buffer, 48, IntPtr.Zero)) throw new Exception("JOB_QUERY");
            return (uint)Marshal.ReadInt32(buffer, 40);
        } finally { Marshal.FreeHGlobal(buffer); }
    }
    public static IntPtr FindWindow(int pid, string title) {
        IntPtr found = IntPtr.Zero;
        EnumWindows(delegate(IntPtr window, IntPtr unused) {
            uint owner; GetWindowThreadProcessId(window, out owner);
            if (owner != pid || !IsWindowVisible(window)) return true;
            var text = new StringBuilder(256); GetWindowText(window, text, 256);
            if (text.ToString() != title) return true;
            found = window; return false;
        }, IntPtr.Zero);
        return found;
    }
    public static bool Responding(IntPtr window) {
        IntPtr result;
        return SendMessageTimeout(window, 0, IntPtr.Zero, IntPtr.Zero, 2, 1000, out result) != IntPtr.Zero;
    }
    public static void RightClick(IntPtr window, int pid) {
        uint owner; GetWindowThreadProcessId(window, out owner);
        if (owner != pid) throw new Exception("WINDOW_OWNER");
        IntPtr point = new IntPtr((100 << 16) | 100);
        if (!PostMessage(window, 0x204, new IntPtr(2), point) || !PostMessage(window, 0x205, IntPtr.Zero, point)) throw new Exception("MENU_INPUT");
    }
    public static bool InvokeMenu(int pid, string name) {
        var task = Task.Run(delegate {
            var windows = AutomationElement.RootElement.FindAll(TreeScope.Children,
                new PropertyCondition(AutomationElement.ProcessIdProperty, pid));
            foreach (AutomationElement window in windows) {
                var item = window.FindFirst(TreeScope.Descendants, new AndCondition(
                    new PropertyCondition(AutomationElement.NameProperty, name),
                    new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.MenuItem),
                    new PropertyCondition(AutomationElement.ProcessIdProperty, pid)));
                if (item == null) continue;
                ((InvokePattern)item.GetCurrentPattern(InvokePattern.Pattern)).Invoke();
                return true;
            }
            return false;
        });
        if (!task.Wait(5000)) throw new Exception("MENU_TIMEOUT");
        return task.Result;
    }
    public static void CloseWindow(IntPtr window, int pid) {
        uint owner; GetWindowThreadProcessId(window, out owner);
        if (owner != pid || !PostMessage(window, 0x10, IntPtr.Zero, IntPtr.Zero)) throw new Exception("WINDOW_CLOSE");
    }
}
'@

function Wait-Until([scriptblock]$Condition, [int]$Seconds, [string]$Failure) {
    $timer = [Diagnostics.Stopwatch]::StartNew()
    do {
        if (& $Condition) { return }
        Start-Sleep -Milliseconds 200
    } while ($timer.Elapsed.TotalSeconds -lt $Seconds)
    throw $Failure
}
function Open-PetMenu([string]$ItemName) {
    $window = [OfflineSmokeNative]::FindWindow($app.Id, 'Aemeath')
    if ($window -eq [IntPtr]::Zero) { throw 'PET_WINDOW_MISSING' }
    [OfflineSmokeNative]::RightClick($window, $app.Id)
    Wait-Until { [OfflineSmokeNative]::InvokeMenu($app.Id, $ItemName) } 10 'MENU_ITEM_UNAVAILABLE'
}

$rules = @()
$app = $null
$job = [IntPtr]::Zero
$exitStatus = 1
$report = [ordered]@{
    schemaVersion = 1; sourceSha = $env:SOURCE_SHA; qualification = 'hosted-offline-process-smoke-only'
    status = 'failed'; stage = 'firewall'; failureCode = $null; fixtureSha256 = $fixtureHash.ToLowerInvariant()
    executableSha256 = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash.ToLowerInvariant()
    osVersion = [Environment]::OSVersion.Version.ToString(); sessionId = (Get-Process -Id $PID).SessionId
    petVisibleResponding = $false; chatOpened = $false; settingsOpened = $false; cleanExit = $false
    processId = $null; exitCode = $null; firewallBlockedBeforeLaunch = $false; cleanupPassed = $false
    limitations = @('No restart continuity journey', 'No Windows 10/11 real-boundary qualification', 'No accessibility or keyboard-entry qualification')
    createdData = @()
}
New-Item -ItemType Directory -Path $evidence | Out-Null
try {
    foreach ($direction in @('Inbound', 'Outbound')) {
        $name = 'AemeathOfflineSmoke-' + [guid]::NewGuid().ToString('N')
        $rules += $name
        New-NetFirewallRule -Name $name -DisplayName $name -Direction $direction -Action Block `
            -Program $executable -Profile Any -Enabled True -PolicyStore PersistentStore | Out-Null
        $rule = Get-NetFirewallRule -Name $name -PolicyStore ActiveStore
        $program = $rule | Get-NetFirewallApplicationFilter
        if ($rule.Enabled -ne 'True' -or $rule.Action -ne 'Block' -or $rule.Direction -ne $direction -or
            $rule.Profile -ne 'Any' -or $program.Program -ine $executable) { throw 'FIREWALL_BLOCK_NOT_EFFECTIVE' }
    }
    $report.firewallBlockedBeforeLaunch = $true
    $report.stage = 'synthetic-profile'
    # Refuse a race with another app/job; never merge with an existing profile directory.
    if ((Test-Path -LiteralPath $dataDirectory) -or (Get-Process -Name AemeathDesktopPet -ErrorAction SilentlyContinue)) {
        throw 'ISOLATION_CHANGED'
    }
    New-Item -ItemType Directory -Path $dataDirectory | Out-Null
    [IO.File]::WriteAllText((Join-Path $dataDirectory 'config.json'), $fixtureText, (New-Object Text.UTF8Encoding($false)))
    $job = [OfflineSmokeNative]::CreateJobObject([IntPtr]::Zero, $null)
    if ($job -eq [IntPtr]::Zero) { throw 'JOB_CREATE_FAILED' }
    $report.stage = 'launch'
    # A visible application is the subject of this probe on the disposable interactive worker.
    $app = Start-Process -FilePath $executable -WorkingDirectory (Split-Path $executable) -PassThru -WindowStyle Normal
    $report.processId = $app.Id
    if (-not [OfflineSmokeNative]::AssignProcessToJobObject($job, $app.Handle)) { throw 'JOB_ASSIGN_FAILED' }
    $report.stage = 'pet-visible-responding'
    Wait-Until {
        if ($app.HasExited) { throw 'EARLY_PROCESS_EXIT' }
        $pet = [OfflineSmokeNative]::FindWindow($app.Id, 'Aemeath')
        $pet -ne [IntPtr]::Zero -and [OfflineSmokeNative]::Responding($pet)
    } 30 'PET_NOT_VISIBLE_RESPONDING'
    $report.petVisibleResponding = $true
    foreach ($surface in @(@{ menu = 'Chat with Aemeath'; title = 'Chat with Aemeath'; field = 'chatOpened' },
            @{ menu = 'Settings'; title = 'Aemeath Settings'; field = 'settingsOpened' })) {
        $report.stage = $surface.field
        Open-PetMenu $surface.menu
        Wait-Until {
            $handle = [OfflineSmokeNative]::FindWindow($app.Id, $surface.title)
            $handle -ne [IntPtr]::Zero -and [OfflineSmokeNative]::Responding($handle)
        } 15 'COMPANION_NOT_VISIBLE_RESPONDING'
        $report[$surface.field] = $true
        [OfflineSmokeNative]::CloseWindow([OfflineSmokeNative]::FindWindow($app.Id, $surface.title), $app.Id)
        Wait-Until { [OfflineSmokeNative]::FindWindow($app.Id, $surface.title) -eq [IntPtr]::Zero } 10 'COMPANION_DID_NOT_CLOSE'
    }
    $report.stage = 'quit'
    Open-PetMenu 'Quit'
    if (-not $app.WaitForExit(15000)) { throw 'QUIT_TIMEOUT' }
    $report.exitCode = $app.ExitCode
    if ($app.ExitCode -ne 0) { throw 'NONZERO_PRODUCT_EXIT' }
    if ([OfflineSmokeNative]::ActiveProcesses($job) -ne 0) { throw 'ORPHAN_PROCESS' }
    $report.cleanExit = $true
    $report.status = 'passed'
    $report.stage = 'complete'
    $exitStatus = 0
} catch {
    # Exception text can contain runner paths; retain only the bounded test diagnostic.
    $code = $_.Exception.Message
    $report.failureCode = if ($code -cmatch '^[A-Z_]{3,80}$') { $code } else { 'HOSTED_PROBE_EXCEPTION' }
} finally {
    $cleanupErrors = @()
    if ($job -ne [IntPtr]::Zero) {
        try {
            if (-not [OfflineSmokeNative]::TerminateJobObject($job, 99)) { $cleanupErrors += 'job' }
            Wait-Until { [OfflineSmokeNative]::ActiveProcesses($job) -eq 0 } 5 'JOB_CLEANUP_TIMEOUT'
        } catch { $cleanupErrors += 'job' }
        finally { if (-not [OfflineSmokeNative]::CloseHandle($job)) { $cleanupErrors += 'job-handle' } }
    }
    if ($null -ne $app) {
        try {
            if (-not $app.HasExited) { $app.Kill(); if (-not $app.WaitForExit(5000)) { $cleanupErrors += 'process' } }
        } catch { $cleanupErrors += 'process' }
        finally { $app.Dispose() }
    }
    foreach ($name in $rules) {
        try {
            Get-NetFirewallRule -Name $name -ErrorAction SilentlyContinue | Remove-NetFirewallRule
            if (Get-NetFirewallRule -Name $name -ErrorAction SilentlyContinue) { $cleanupErrors += 'firewall' }
        } catch { $cleanupErrors += 'firewall' }
    }
    $report.cleanupPassed = $cleanupErrors.Count -eq 0
    if (-not $report.cleanupPassed) { $report.status = 'failed'; $report.failureCode = 'CLEANUP_FAILED'; $exitStatus = 1 }
    foreach ($name in @('config.json', 'stats.json', 'messages.json', 'core_memory.json', 'procedural_memory.json', 'observation_buffer.json')) {
        $file = Join-Path $dataDirectory $name
        if (Test-Path -LiteralPath $file -PathType Leaf) {
            $report.createdData += @{ name = $name; bytes = (Get-Item -LiteralPath $file).Length; sha256 = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() }
        }
    }
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidence 'offline-process-smoke.json') -Encoding UTF8
}
Write-Output ("OFFLINE-SMOKE: " + $report.status + '; pet=' + $report.petVisibleResponding + '; chat=' + $report.chatOpened + '; settings=' + $report.settingsOpened + '; cleanExit=' + $report.cleanExit)
exit $exitStatus

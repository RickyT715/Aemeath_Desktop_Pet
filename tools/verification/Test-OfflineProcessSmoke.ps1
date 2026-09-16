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
$fixtureTexts = @{ 'config.json' = $fixtureText }
foreach ($entry in @{
        'messages.json' = '3BE2810A95B901089082CC494CE84F7F4A4BE0ECB4D5C7CA81AFD49216E27CAE'
        'stats.json' = '7C0C0D70AF40B2EED4F32268CA45DF4D74E7285FC4109523F180CECB02B6CD3A'
    }.GetEnumerator()) {
    $file = Join-Path (Split-Path $fixture) $entry.Key
    Assert-PlainPath $file
    $text = [IO.File]::ReadAllText($file).Replace("`r`n", "`n")
    $hasher = [Security.Cryptography.SHA256]::Create()
    try { $hash = [BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))).Replace('-', '') }
    finally { $hasher.Dispose() }
    if ($hash -cne $entry.Value) { Refuse 'UNSAFE_FIXTURE' }
    $fixtureTexts[$entry.Key] = $text
}
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
    [StructLayout(LayoutKind.Sequential)] private struct Point { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] private struct Rect { public int left, top, right, bottom; }
    [StructLayout(LayoutKind.Sequential)] private struct MouseInput { public int dx, dy; public uint data, flags, time; public UIntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] private struct Input { public uint type; public MouseInput mouse; }
    [StructLayout(LayoutKind.Sequential)] private struct GuiThreadInfo {
        public uint size, flags; public IntPtr active, focus, capture, menuOwner, moveSize, caret; public Rect caretRect;
    }
    private static Point originalCursor;
    private static bool cursorSaved;
    public static bool CursorTargetVerified;
    public static uint InputEventsSent;
    public static int OwnedUiaWindows, OwnedMenuItems;
    public static int ChatReadAttempts, ChatItemCount;
    public static string ChatReadOperation = "not-started";
    public static int ChatReadItemIndex = -1;
    public static int[] ChatItemNameLengths = new int[0], ChatTextCounts = new int[0], ChatTextLengths = new int[0];
    [DllImport("user32.dll")] private static extern bool GetCursorPos(out Point point);
    [DllImport("user32.dll")] private static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] private static extern IntPtr WindowFromPoint(Point point);
    [DllImport("user32.dll")] private static extern bool GetClientRect(IntPtr window, out Rect rectangle);
    [DllImport("user32.dll")] private static extern bool ClientToScreen(IntPtr window, ref Point point);
    [DllImport("user32.dll")] private static extern bool GetGUIThreadInfo(uint thread, ref GuiThreadInfo info);
    [DllImport("user32.dll")] private static extern short GetAsyncKeyState(int key);
    [DllImport("user32.dll")] private static extern uint SendInput(uint count, Input[] inputs, int size);
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
    public static bool RightClick(IntPtr window, int pid) {
        CursorTargetVerified = false; InputEventsSent = 0; OwnedUiaWindows = 0; OwnedMenuItems = 0;
        uint owner; GetWindowThreadProcessId(window, out owner);
        if (owner != pid || !IsWindowVisible(window)) throw new Exception("WINDOW_OWNER");
        Rect bounds;
        if (!GetClientRect(window, out bounds)) throw new Exception("CLIENT_RECT_UNAVAILABLE");
        Point point = new Point(); bool found = false;
        int[] fractions = { 5, 4, 6, 3, 7, 2, 8, 1, 9 };
        foreach (int y in fractions) {
            foreach (int x in fractions) {
                point = new Point { x = bounds.left + (bounds.right - bounds.left) * x / 10,
                    y = bounds.top + (bounds.bottom - bounds.top) * y / 10 };
                if (!ClientToScreen(window, ref point)) throw new Exception("CLIENT_RECT_UNAVAILABLE");
                if (WindowFromPoint(point) == window) { found = true; break; }
            }
            if (found) break;
        }
        if (!found) return false;
        var gui = new GuiThreadInfo { size = (uint)Marshal.SizeOf(typeof(GuiThreadInfo)) };
        if (!GetGUIThreadInfo(0, ref gui) || gui.capture != IntPtr.Zero) throw new Exception("INPUT_DESKTOP_CAPTURED");
        foreach (int key in new int[] { 1, 2, 4, 5, 6, 16, 17, 18 }) {
            if ((GetAsyncKeyState(key) & 0x8000) != 0) throw new Exception("INPUT_ALREADY_PRESSED");
        }
        if (!cursorSaved) {
            if (!GetCursorPos(out originalCursor)) throw new Exception("CURSOR_UNAVAILABLE");
            cursorSaved = true;
        }
        if (!SetCursorPos(point.x, point.y) || !GetCursorPos(out point)) throw new Exception("CURSOR_UNAVAILABLE");
        GetWindowThreadProcessId(window, out owner);
        if (owner != pid || WindowFromPoint(point) != window) return false;
        CursorTargetVerified = true;
        var inputs = new Input[] { new Input { mouse = new MouseInput { flags = 0x0008 } },
            new Input { mouse = new MouseInput { flags = 0x0010 } } };
        InputEventsSent = SendInput(2, inputs, Marshal.SizeOf(typeof(Input)));
        if (InputEventsSent != 2) {
            if (InputEventsSent == 1) SendInput(1, new Input[] { inputs[1] }, Marshal.SizeOf(typeof(Input)));
            throw new Exception("MOUSE_INPUT_REJECTED");
        }
        return true;
    }
    public static bool RestoreCursor() {
        return !cursorSaved || SetCursorPos(originalCursor.x, originalCursor.y);
    }
    public static bool InvokeMenu(int pid, string name) {
        var task = Task.Run(delegate {
            var windows = AutomationElement.RootElement.FindAll(TreeScope.Children,
                new PropertyCondition(AutomationElement.ProcessIdProperty, pid));
            OwnedUiaWindows = windows.Count; OwnedMenuItems = 0;
            foreach (AutomationElement window in windows) {
                OwnedMenuItems += window.FindAll(TreeScope.Descendants, new AndCondition(
                    new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.MenuItem),
                    new PropertyCondition(AutomationElement.ProcessIdProperty, pid))).Count;
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
    private static T Uia<T>(Func<T> operation) {
        var task = Task.Run(operation);
        if (!task.Wait(5000)) throw new Exception("CHAT_UIA_TIMEOUT");
        return task.Result;
    }
    private static AutomationElement Control(int pid, string title, string id) {
        IntPtr handle = FindWindow(pid, title);
        if (handle == IntPtr.Zero) throw new Exception("COMPANION_WINDOW_MISSING");
        var window = AutomationElement.FromHandle(handle);
        var control = window.FindFirst(TreeScope.Descendants, new AndCondition(
            new PropertyCondition(AutomationElement.AutomationIdProperty, id),
            new PropertyCondition(AutomationElement.ProcessIdProperty, pid)));
        if (control == null) throw new Exception("COMPANION_CONTROL_MISSING");
        return control;
    }
    public static string[] ReadChat(int pid) {
        ChatReadOperation = "dispatch"; ChatReadItemIndex = -1;
        return Uia(delegate {
            ChatReadAttempts++;
            ChatReadOperation = "find-list";
            var list = Control(pid, "Chat with Aemeath", "MessageList");
            ChatReadOperation = "find-items";
            var items = list.FindAll(TreeScope.Children,
                new AndCondition(new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.ListItem),
                    new PropertyCondition(AutomationElement.ProcessIdProperty, pid)));
            ChatItemCount = items.Count;
            int count = Math.Min(items.Count, 6);
            ChatItemNameLengths = new int[count]; ChatTextCounts = new int[count]; ChatTextLengths = new int[count];
            var result = new string[count];
            for (int index = 0; index < count; index++) {
                ChatReadItemIndex = index; ChatReadOperation = "scroll-pattern";
                var item = items[index];
                object scroll;
                if (item.TryGetCurrentPattern(ScrollItemPattern.Pattern, out scroll)) {
                    ChatReadOperation = "scroll-item"; ((ScrollItemPattern)scroll).ScrollIntoView();
                }
                ChatReadOperation = "item-name";
                ChatItemNameLengths[index] = item.Current.Name.Length;
                ChatReadOperation = "find-text";
                var texts = item.FindAll(TreeScope.Descendants, new AndCondition(
                    new PropertyCondition(AutomationElement.ControlTypeProperty, ControlType.Text),
                    new PropertyCondition(AutomationElement.ProcessIdProperty, pid)));
                ChatTextCounts[index] = texts.Count;
                var content = new StringBuilder();
                ChatReadOperation = "text-name";
                foreach (AutomationElement text in texts) content.Append(text.Current.Name);
                result[index] = content.ToString(); ChatTextLengths[index] = result[index].Length;
            }
            ChatReadOperation = "complete";
            return result;
        });
    }
    public static bool ScreenshotOff(int pid) {
        return Uia(delegate { return ((TogglePattern)Control(pid, "Chat with Aemeath", "ScreenshotToggle")
            .GetCurrentPattern(TogglePattern.Pattern)).Current.ToggleState == ToggleState.Off; });
    }
    public static void Draft(int pid, string text) {
        Uia(delegate {
            var input = Control(pid, "Chat with Aemeath", "InputBox"); input.SetFocus();
            ((ValuePattern)input.GetCurrentPattern(ValuePattern.Pattern)).SetValue(text); return true;
        });
    }
    public static bool SendEnabled(int pid) {
        return Uia(delegate { return Control(pid, "Chat with Aemeath", "SendButton").Current.IsEnabled; });
    }
    public static void Send(int pid) {
        if (!ScreenshotOff(pid)) throw new Exception("SCREENSHOT_NOT_OFF");
        Uia(delegate { ((InvokePattern)Control(pid, "Chat with Aemeath", "SendButton")
            .GetCurrentPattern(InvokePattern.Pattern)).Invoke(); return true; });
    }
    public static bool SafeSettingsObserved(int pid) {
        return Uia(delegate {
            foreach (string id in new string[] { "StartWithWindowsCheck", "LaunchMonitorCheck", "LaunchTodoCheck", "EnablePomodoroIntegrationCheck" }) {
                if (((TogglePattern)Control(pid, "Aemeath Settings", id).GetCurrentPattern(TogglePattern.Pattern)).Current.ToggleState != ToggleState.Off) return false;
            }
            return true;
        });
    }
    public static double[] PetRectangle(int pid) {
        return Uia(delegate {
            var rectangle = AutomationElement.FromHandle(FindWindow(pid, "Aemeath")).Current.BoundingRectangle;
            return new double[] { rectangle.Left, rectangle.Top, rectangle.Width, rectangle.Height };
        });
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
function Read-ChatSnapshot {
    if ($app.HasExited) { throw 'EARLY_PROCESS_EXIT' }
    try { return [OfflineSmokeNative]::ReadChat($app.Id) }
    catch {
        $readError = $_.Exception.GetBaseException()
        if ($readError.GetType() -ne [Exception] -or $readError.Message -cne 'COMPANION_CONTROL_MISSING') { throw }
        if ($app.HasExited) { throw 'EARLY_PROCESS_EXIT' }
        if ([OfflineSmokeNative]::FindWindow($app.Id, 'Chat with Aemeath') -eq [IntPtr]::Zero) { throw 'COMPANION_WINDOW_MISSING' }
        return @() # Only this owned missing peer is pending; the caller's original deadline still applies.
    }
}
function Get-OwnedFailureFacts {
    $facts = [ordered]@{ exited = $null; exitCode = $null; petWindowPresent = $null; chatWindowPresent = $null
        runtimeEventQuery = 'not-run'; runtimePidZeroAttributionUsed = $false; runtimeExceptionTypes = @()
        runtimeProductMethods = @(); runtimeFrameworkMethods = @() }
    if ($null -eq $app) { return [pscustomobject]$facts }
    try {
        [void]$app.WaitForExit(1000) # Bounded wait for an already-failing owned process, before cleanup can terminate it.
        $facts.exited = $app.HasExited
        if ($facts.exited) { $facts.exitCode = $app.ExitCode }
    } catch { }
    try {
        $facts.petWindowPresent = [OfflineSmokeNative]::FindWindow($app.Id, 'Aemeath') -ne [IntPtr]::Zero
        $facts.chatWindowPresent = [OfflineSmokeNative]::FindWindow($app.Id, 'Chat with Aemeath') -ne [IntPtr]::Zero
    } catch { }
    try {
        $since = $app.StartTime.ToUniversalTime().ToString('o')
        $query = "*[System[Provider[@Name='.NET Runtime'] and EventID=1026 and (Execution[@ProcessID='$($app.Id)'] or Execution[@ProcessID='0']) and TimeCreated[@SystemTime>='$since']]]"
        $events = @(Get-WinEvent -LogName Application -FilterXPath $query -MaxEvents 3 -ErrorAction Stop)
        $facts.runtimeEventQuery = 'queried'
        foreach ($event in $events) {
            if (($event.ProcessId -ne $app.Id -and $event.ProcessId -ne 0) -or $event.TimeCreated -lt $app.StartTime) { continue }
            $message = $event.Message
            if ($message -cnotmatch '(?m)^Application: AemeathDesktopPet\.exe\r?$') { continue }
            # Classic runtime events may omit PID; exact basename/start time is scoped by the exclusive disposable-worker guard.
            if ($event.ProcessId -eq 0) { $facts.runtimePidZeroAttributionUsed = $true }
            $facts.runtimeExceptionTypes += @([regex]::Matches($message,
                '(?m)^Exception Info: (System\.(?:InvalidOperationException|NullReferenceException|ArgumentException|ArgumentOutOfRangeException|IndexOutOfRangeException|ObjectDisposedException|StackOverflowException|AccessViolationException|Runtime\.InteropServices\.COMException))(?=:|\r?$)') |
                ForEach-Object { $_.Groups[1].Value } | Select-Object -First 3)
            $facts.runtimeProductMethods += @([regex]::Matches($message, '(?m)^\s+at (AemeathDesktopPet\.[A-Za-z0-9_.+<>]+)\(') |
                ForEach-Object { $_.Groups[1].Value } | Select-Object -First 6)
            $facts.runtimeFrameworkMethods += @([regex]::Matches($message, '(?m)^\s+at (System\.(?:Windows|Collections)\.[A-Za-z0-9_.+`]+)(?:<[^()\r\n]{0,256}>)?(\.[A-Za-z0-9_<>]+)?\(') |
                ForEach-Object { $_.Groups[1].Value + $_.Groups[2].Value } | Select-Object -First 12)
        }
        $facts.runtimeExceptionTypes = @($facts.runtimeExceptionTypes | Select-Object -Unique -First 3)
        $facts.runtimeProductMethods = @($facts.runtimeProductMethods | Select-Object -Unique -First 6)
        $facts.runtimeFrameworkMethods = @($facts.runtimeFrameworkMethods | Select-Object -Unique -First 12)
    } catch { $facts.runtimeEventQuery = if ($_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { 'none' } else { 'unavailable' } }
    return [pscustomobject]$facts
}
function Open-PetMenu([string]$ItemName) {
    $window = [OfflineSmokeNative]::FindWindow($app.Id, 'Aemeath')
    if ($window -eq [IntPtr]::Zero) { throw 'PET_WINDOW_MISSING' }
    try {
        # WPF rejects inactive-window mouse reports if the real cursor is elsewhere.
        Wait-Until { [OfflineSmokeNative]::RightClick($window, $app.Id) } 5 'NO_OWNED_CLICK_POINT'
        Wait-Until { [OfflineSmokeNative]::InvokeMenu($app.Id, $ItemName) } 10 'MENU_ITEM_UNAVAILABLE'
        if (-not [OfflineSmokeNative]::RestoreCursor()) { throw 'CURSOR_RESTORE_FAILED' }
    } finally {
        $report.menuAttempts += @{ item = $ItemName; cursorTargetVerified = [OfflineSmokeNative]::CursorTargetVerified
            inputEventsSent = [OfflineSmokeNative]::InputEventsSent; ownedUiaWindows = [OfflineSmokeNative]::OwnedUiaWindows
            ownedMenuItems = [OfflineSmokeNative]::OwnedMenuItems }
    }
}

function Assert-OwnedPersistence([datetime]$QuitStarted, [datetime]$QuitEnded) {
    $snapshot = @{}
    foreach ($name in @('config', 'stats', 'messages')) {
        $path = Join-Path $dataDirectory ($name + '.json')
        Assert-PlainPath $path
        $snapshot[$name] = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
    }
    $history = @($snapshot.messages)
    if ($history.Count -ne 4) { throw 'HISTORY_COUNT' }
    for ($i = 0; $i -lt 2; $i++) {
        foreach ($field in @('id', 'role', 'content', 'timestamp')) {
            if ($history[$i].$field -cne $seedMessages[$i].$field) { throw 'SEED_HISTORY_CHANGED' }
        }
    }
    if ($history[2].role -cne 'user' -or $history[2].content -cne $sentText -or
        $history[3].role -cne 'assistant' -or $history[3].content -cne $assistantReply) { throw 'NEW_HISTORY_CHANGED' }
    if (@($history | Where-Object { $_.isStreaming }).Count -ne 0) { throw 'PERSISTED_STREAMING_MESSAGE' }
    $stats = $snapshot.stats
    foreach ($counter in @{ totalChats = 12; totalPets = 13; totalSongs = 17; totalPaperPlanes = 19; totalGames = 23 }.GetEnumerator()) {
        if ($stats.($counter.Key) -ne $counter.Value) { throw 'STATS_COUNTER_CHANGED' }
    }
    if ([datetimeoffset]$stats.firstLaunch -ne [datetimeoffset]'2024-02-03T04:05:06Z') { throw 'FIRST_LAUNCH_CHANGED' }
    $lastSeen = [datetimeoffset]$stats.lastSeen
    if ($lastSeen.UtcDateTime -lt $QuitStarted -or $lastSeen.UtcDateTime -gt $QuitEnded) { throw 'LAST_SEEN_OUTSIDE_QUIT' }
    if ($stats.mood -lt 30 -or $stats.mood -gt 86.25 -or $stats.energy -lt 20 -or $stats.energy -gt 64.5 -or
        $stats.affection -lt 40 -or $stats.affection -gt 79.75) { throw 'STATS_OUTSIDE_DECAY_RANGE' }
    foreach ($flag in @('backend', 'pomodoroIntegration', 'tts', 'voiceInput', 'screenAwareness', 'activityMonitor', 'mcp')) {
        if ($snapshot.config.$flag.enabled) { throw 'CONFIG_INTEGRATION_CHANGED' }
    }
    if ($snapshot.config.startWithWindows -or $snapshot.config.companionApps.launchMonitor -or
        $snapshot.config.companionApps.launchTodoList -or $snapshot.config.voiceInput.includeScreenshot -or
        $snapshot.config.apiKey -or $snapshot.config.geminiApiKey -or $snapshot.config.petSize -ne 200 -or
        $snapshot.config.opacity -ne 1.0) { throw 'CONFIG_CHANGED' }
    return [pscustomobject]$snapshot
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
    limitations = @('No Windows 10/11 real-boundary qualification', 'No accessibility or keyboard-entry qualification')
    createdData = @(); menuAttempts = @(); chatObservations = @(); cleanExitCount = 0; processIds = @(); exitCodes = @()
    seedConversationObserved = $false; screenshotOffVerified = $false; offlineTurnCompleted = $false
    firstPersistenceVerified = $false; restartConversationObserved = $false; restartConfigPositionVerified = $false
    secondPersistenceVerified = $false; sameExecutableVerified = $false
    assistantReplyLength = 0; savedMessageCount = 0; savedTotalChats = 0
    failureExceptionType = $null; failureScriptLine = 0
    failureHResult = $null; lastChatReadOperation = $null; lastChatReadItemIndex = -1
    ownedFailureFacts = $null
}
# PS5 emits a JSON array as one pipeline object; assignment preserves that array without nesting it.
$seedMessages = $fixtureTexts['messages.json'] | ConvertFrom-Json
$sentText = 'OFFLINE_SMOKE_NEW_TURN_51B8: hello from the synthetic test.'
$assistantReply = $null
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
    foreach ($entry in $fixtureTexts.GetEnumerator()) {
        [IO.File]::WriteAllText((Join-Path $dataDirectory $entry.Key), $entry.Value, (New-Object Text.UTF8Encoding($false)))
    }
    $job = [OfflineSmokeNative]::CreateJobObject([IntPtr]::Zero, $null)
    if ($job -eq [IntPtr]::Zero) { throw 'JOB_CREATE_FAILED' }
    for ($launch = 1; $launch -le 2; $launch++) {
    $report.stage = "launch-$launch"
    if ((Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash.ToLowerInvariant() -cne $report.executableSha256) { throw 'EXE_CHANGED' }
    foreach ($name in $rules) {
        $rule = Get-NetFirewallRule -Name $name -PolicyStore ActiveStore
        if ($rule.Enabled -ne 'True' -or $rule.Action -ne 'Block' -or
            ($rule | Get-NetFirewallApplicationFilter).Program -ine $executable) { throw 'FIREWALL_BLOCK_LOST' }
    }
    # A visible application is the subject of this probe on the disposable interactive worker.
    $app = Start-Process -FilePath $executable -WorkingDirectory (Split-Path $executable) -PassThru -WindowStyle Normal
    $report.processId = $app.Id
    $report.processIds += $app.Id
    if (-not [OfflineSmokeNative]::AssignProcessToJobObject($job, $app.Handle)) { throw 'JOB_ASSIGN_FAILED' }
    $report.stage = 'pet-visible-responding'
    Wait-Until {
        if ($app.HasExited) { throw 'EARLY_PROCESS_EXIT' }
        $pet = [OfflineSmokeNative]::FindWindow($app.Id, 'Aemeath')
        $pet -ne [IntPtr]::Zero -and [OfflineSmokeNative]::Responding($pet)
    } 30 'PET_NOT_VISIBLE_RESPONDING'
    $report.petVisibleResponding = $true
    if ($launch -eq 2) {
        $restored = [OfflineSmokeNative]::PetRectangle($app.Id)
        if ([math]::Abs($restored[0] - $firstSaved.config.lastX) -gt 2 -or
            [math]::Abs($restored[1] - $firstSaved.config.lastY) -gt 2 -or
            [math]::Abs($restored[2] - 200) -gt 2 -or [math]::Abs($restored[3] - 200) -gt 2) { throw 'RESTORED_POSITION_SIZE_MISMATCH' }
        $report.sameExecutableVerified = $true
    }
    foreach ($surface in @(@{ menu = 'Chat with Aemeath'; title = 'Chat with Aemeath'; field = 'chatOpened' },
            @{ menu = 'Settings'; title = 'Aemeath Settings'; field = 'settingsOpened' })) {
        $report.stage = $surface.field
        Open-PetMenu $surface.menu
        Wait-Until {
            $handle = [OfflineSmokeNative]::FindWindow($app.Id, $surface.title)
            $handle -ne [IntPtr]::Zero -and [OfflineSmokeNative]::Responding($handle)
        } 15 'COMPANION_NOT_VISIBLE_RESPONDING'
        $report[$surface.field] = $true
        if ($surface.field -eq 'chatOpened') {
            # A responsive HWND does not imply WPF item-container/text-peer realization.
            $chatRead = @{ items = @() }
            [OfflineSmokeNative]::ChatReadAttempts = 0
            try {
                Wait-Until {
                    $chatRead.items = @(Read-ChatSnapshot)
                    $chatRead.items.Count -ge 2 -and $chatRead.items[0] -ceq $seedMessages[0].content -and
                        $chatRead.items[1] -ceq $seedMessages[1].content
                } 15 'SEED_CHAT_NOT_OBSERVED'
            } finally {
                $report.chatObservations += @{ launch = $launch; attempts = [OfflineSmokeNative]::ChatReadAttempts
                    itemCount = [OfflineSmokeNative]::ChatItemCount; itemNameLengths = @([OfflineSmokeNative]::ChatItemNameLengths)
                    childTextCounts = @([OfflineSmokeNative]::ChatTextCounts); childTextLengths = @([OfflineSmokeNative]::ChatTextLengths)
                    seedUserMatched = $chatRead.items.Count -ge 1 -and $chatRead.items[0] -ceq $seedMessages[0].content
                    seedAssistantMatched = $chatRead.items.Count -ge 2 -and $chatRead.items[1] -ceq $seedMessages[1].content }
            }
            $observed = $chatRead.items
            if (-not [OfflineSmokeNative]::ScreenshotOff($app.Id)) { throw 'SCREENSHOT_NOT_OFF' }
            $report.seedConversationObserved = $true; $report.screenshotOffVerified = $true
            if ($launch -eq 1) {
                [OfflineSmokeNative]::Draft($app.Id, $sentText)
                Wait-Until { [OfflineSmokeNative]::SendEnabled($app.Id) } 5 'SEND_NOT_READY'
                [OfflineSmokeNative]::Send($app.Id)
                $report.stage = 'offline-reply'
                Wait-Until { $items = @(Read-ChatSnapshot); $items.Count -eq 4 -and
                    $items[2] -ceq $sentText -and -not [string]::IsNullOrWhiteSpace($items[3]) } 30 'OFFLINE_REPLY_MISSING'
                [OfflineSmokeNative]::Draft($app.Id, 'OFFLINE_SMOKE_UNSENT_READY_DRAFT')
                Wait-Until { [OfflineSmokeNative]::SendEnabled($app.Id) } 10 'CHAT_NOT_READY_AFTER_REPLY'
                [OfflineSmokeNative]::Draft($app.Id, '')
                $assistantReply = @([OfflineSmokeNative]::ReadChat($app.Id))[3]
                $report.assistantReplyLength = $assistantReply.Length; $report.offlineTurnCompleted = $true
            } else {
                if ($observed.Count -ne 4 -or $observed[2] -cne $sentText -or $observed[3] -cne $assistantReply) { throw 'RESTART_CHAT_CHANGED' }
                $report.restartConversationObserved = $true
            }
        } elseif ($launch -eq 2) {
            if (-not [OfflineSmokeNative]::SafeSettingsObserved($app.Id)) { throw 'RESTART_SETTINGS_CHANGED' }
            $report.restartConfigPositionVerified = $true
        }
        [OfflineSmokeNative]::CloseWindow([OfflineSmokeNative]::FindWindow($app.Id, $surface.title), $app.Id)
        Wait-Until { [OfflineSmokeNative]::FindWindow($app.Id, $surface.title) -eq [IntPtr]::Zero } 10 'COMPANION_DID_NOT_CLOSE'
    }
    $report.stage = "quit-$launch"
    $quitStarted = [datetime]::UtcNow
    Open-PetMenu 'Quit'
    if (-not $app.WaitForExit(15000)) { throw 'QUIT_TIMEOUT' }
    $report.exitCode = $app.ExitCode
    $quitEnded = [datetime]::UtcNow
    if ($app.ExitCode -ne 0) { throw 'NONZERO_PRODUCT_EXIT' }
    if ([OfflineSmokeNative]::ActiveProcesses($job) -ne 0) { throw 'ORPHAN_PROCESS' }
    $report.cleanExitCount++; $report.exitCodes += $app.ExitCode
    $report.stage = "persistence-$launch"
    $saved = Assert-OwnedPersistence $quitStarted $quitEnded
    $report.savedMessageCount = @($saved.messages).Count; $report.savedTotalChats = $saved.stats.totalChats
    if ($launch -eq 1) { $firstSaved = $saved; $report.firstPersistenceVerified = $true }
    else { $report.secondPersistenceVerified = $true }
    $app.Dispose(); $app = $null
    }
    $report.cleanExit = $report.cleanExitCount -eq 2
    $report.status = 'passed'
    $report.stage = 'complete'
    $exitStatus = 0
} catch {
    # Exception text can contain runner paths; retain only the bounded test diagnostic.
    $baseException = $_.Exception.GetBaseException()
    $code = $baseException.Message
    $report.failureCode = if ($code -cmatch '^[A-Z_]{3,80}$') { $code } else { 'HOSTED_PROBE_EXCEPTION' }
    $report.failureExceptionType = $baseException.GetType().FullName
    $report.failureScriptLine = $_.InvocationInfo.ScriptLineNumber
    $report.failureHResult = $baseException.HResult
    $report.lastChatReadOperation = [OfflineSmokeNative]::ChatReadOperation
    $report.lastChatReadItemIndex = [OfflineSmokeNative]::ChatReadItemIndex
    try { $report.ownedFailureFacts = Get-OwnedFailureFacts } catch { } # Diagnostics cannot replace the original failure.
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
    if (-not [OfflineSmokeNative]::RestoreCursor()) { $cleanupErrors += 'cursor' }
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

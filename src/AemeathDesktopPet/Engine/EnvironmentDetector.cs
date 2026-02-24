using System.Diagnostics;
using System.Windows;
using AemeathDesktopPet.Interop;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// Detects screen bounds, taskbar, fullscreen applications, and visible windows.
/// </summary>
public class EnvironmentDetector
{
    /// <summary>
    /// Returns the work area (screen minus taskbar).
    /// </summary>
    public Rect GetWorkArea()
    {
        // Use WPF's SystemParameters which returns DIPs (device-independent pixels),
        // matching WPF Window.Left/Top coordinate space.
        // Win32Api.GetWorkArea() returns physical pixels and causes DPI mismatch.
        return SystemParameters.WorkArea;
    }

    /// <summary>
    /// Returns the primary screen full bounds.
    /// </summary>
    public Rect GetScreenBounds()
    {
        return new Rect(0, 0,
            SystemParameters.PrimaryScreenWidth,
            SystemParameters.PrimaryScreenHeight);
    }

    /// <summary>
    /// Checks if a fullscreen application is currently active.
    /// </summary>
    public bool IsFullscreenAppActive()
    {
        var foreground = Win32Api.GetForegroundWindow();
        if (foreground == IntPtr.Zero) return false;

        // Skip shell and desktop windows
        if (foreground == Win32Api.GetShellWindow()) return false;
        if (foreground == Win32Api.GetDesktopWindow()) return false;

        if (!Win32Api.GetWindowRect(foreground, out var rect)) return false;

        var screenW = SystemParameters.PrimaryScreenWidth;
        var screenH = SystemParameters.PrimaryScreenHeight;

        // A window is "fullscreen" if it covers the entire screen
        return rect.Left <= 0 && rect.Top <= 0
            && rect.Width >= screenW && rect.Height >= screenH;
    }

    /// <summary>
    /// Gets the foreground window's process name and title (for app blacklist checks).
    /// </summary>
    public (string processName, string title) GetForegroundAppInfo()
    {
        var hwnd = Win32Api.GetForegroundWindow();
        if (hwnd == IntPtr.Zero) return ("", "");

        string title = Win32Api.GetWindowTitle(hwnd);

        Win32Api.GetWindowThreadProcessId(hwnd, out uint pid);
        string processName = "";
        try
        {
            using var proc = Process.GetProcessById((int)pid);
            processName = proc.ProcessName;
        }
        catch { }

        return (processName, title);
    }

    /// <summary>
    /// Enumerates all visible, non-cloaked windows and returns their bounds.
    /// </summary>
    public List<(IntPtr hwnd, Rect bounds, string title)> GetVisibleWindows()
    {
        var results = new List<(IntPtr, Rect, string)>();
        var shellWnd = Win32Api.GetShellWindow();
        var desktopWnd = Win32Api.GetDesktopWindow();

        Win32Api.EnumWindows((hwnd, _) =>
        {
            if (hwnd == shellWnd || hwnd == desktopWnd) return true;
            if (!Win32Api.IsWindowVisible(hwnd)) return true;
            if (Win32Api.IsWindowCloaked(hwnd)) return true;

            if (Win32Api.TryGetExtendedFrameBounds(hwnd, out var bounds))
            {
                // Filter out tiny windows (toolbars, popups)
                if (bounds.Width > 100 && bounds.Height > 50)
                {
                    string title = Win32Api.GetWindowTitle(hwnd);
                    if (!string.IsNullOrEmpty(title))
                        results.Add((hwnd, bounds, title));
                }
            }
            return true;
        }, IntPtr.Zero);

        return results;
    }
}

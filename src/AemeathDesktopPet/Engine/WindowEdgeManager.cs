using System.Windows;
using System.Windows.Threading;
using AemeathDesktopPet.Interop;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// Detects nearby window edges for perching, peeking, and edge-aware behaviors.
/// Uses EnvironmentDetector.GetVisibleWindows() for window bounds.
/// </summary>
public class WindowEdgeManager
{
    private readonly EnvironmentDetector _env;
    private readonly DispatcherTimer _pollTimer;
    private IntPtr _winEventHook = IntPtr.Zero;
    private Win32Api.WinEventDelegate? _hookDelegate;

    // Current nearby edge info
    public bool IsNearWindowEdge { get; private set; }
    public bool IsNearScreenEdge { get; private set; }
    public bool IsNearTaskbar { get; private set; }
    public string? NearbyWindowTitle { get; private set; }
    public Rect NearbyWindowBounds { get; private set; }

    /// <summary>
    /// Fired when the window the pet was perched on closes or moves away.
    /// </summary>
    public event Action? PerchedWindowClosed;

    /// <summary>
    /// Fired when a suitable window edge is found/lost.
    /// </summary>
    public event Action<bool>? NearbyEdgeChanged;

    public WindowEdgeManager(EnvironmentDetector env)
    {
        _env = env;
        _pollTimer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromMilliseconds(500)
        };
        _pollTimer.Tick += OnPollTick;
    }

    public void Start()
    {
        _pollTimer.Start();
        InstallHook();
    }

    public void Stop()
    {
        _pollTimer.Stop();
        UninstallHook();
    }

    /// <summary>
    /// Finds a window title bar near the pet's current position.
    /// Returns null if no suitable edge found.
    /// </summary>
    public (string title, Rect bounds)? FindNearbyEdge(double petX, double petY, double size)
    {
        var windows = _env.GetVisibleWindows();
        double proximity = 30; // pixels

        foreach (var (_, bounds, title) in windows)
        {
            // Check if pet is near the top edge (title bar) of any window
            double topEdge = bounds.Top;
            double petBottom = petY + size;

            // Pet is within proximity of the window's top edge
            if (Math.Abs(petBottom - topEdge) < proximity
                && petX + size > bounds.Left && petX < bounds.Right)
            {
                return (title, bounds);
            }
        }

        return null;
    }

    /// <summary>
    /// Updates edge detection for the given pet position.
    /// </summary>
    public void Update(double petX, double petY, double size)
    {
        var workArea = _env.GetWorkArea();
        var screenBounds = _env.GetScreenBounds();

        // Screen edge detection
        IsNearScreenEdge = petX <= workArea.Left + 20
                        || petX + size >= workArea.Right - 20
                        || petY <= workArea.Top + 20;

        // Taskbar detection (pet near bottom of work area)
        IsNearTaskbar = petY + size >= workArea.Bottom - 10;

        // Window edge detection
        var edge = FindNearbyEdge(petX, petY, size);
        bool wasNearEdge = IsNearWindowEdge;
        IsNearWindowEdge = edge.HasValue;
        NearbyWindowTitle = edge?.title;
        NearbyWindowBounds = edge?.bounds ?? default;

        if (wasNearEdge != IsNearWindowEdge)
            NearbyEdgeChanged?.Invoke(IsNearWindowEdge);
    }

    private void OnPollTick(object? sender, EventArgs e)
    {
        // When perched on a window, poll faster to detect window close
        if (IsNearWindowEdge)
        {
            _pollTimer.Interval = TimeSpan.FromMilliseconds(100);

            // Check if the window we were near still exists
            if (NearbyWindowTitle is not null)
            {
                var windows = _env.GetVisibleWindows();
                bool found = false;
                foreach (var (_, _, title) in windows)
                {
                    if (title == NearbyWindowTitle) { found = true; break; }
                }
                if (!found)
                {
                    IsNearWindowEdge = false;
                    NearbyWindowTitle = null;
                    PerchedWindowClosed?.Invoke();
                    NearbyEdgeChanged?.Invoke(false);
                }
            }
        }
        else
        {
            _pollTimer.Interval = TimeSpan.FromMilliseconds(500);
        }
    }

    private void InstallHook()
    {
        _hookDelegate = OnWinEvent;
        _winEventHook = Win32Api.SetWinEventHook(
            Win32Api.EVENT_OBJECT_LOCATIONCHANGE,
            Win32Api.EVENT_OBJECT_LOCATIONCHANGE,
            IntPtr.Zero,
            _hookDelegate,
            0, 0,
            Win32Api.WINEVENT_OUTOFCONTEXT);
    }

    private void UninstallHook()
    {
        if (_winEventHook != IntPtr.Zero)
        {
            Win32Api.UnhookWinEvent(_winEventHook);
            _winEventHook = IntPtr.Zero;
        }
    }

    private void OnWinEvent(IntPtr hWinEventHook, uint eventType, IntPtr hwnd,
        int idObject, int idChild, uint dwEventThread, uint dwmsEventTime)
    {
        // A window moved — if we're perched, check if our window moved
        if (IsNearWindowEdge)
        {
            // Let the poll timer handle the detailed check
            _pollTimer.Interval = TimeSpan.FromMilliseconds(50);
        }
    }
}

using System.Windows;
using System.Windows.Threading;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// Handles gravity, velocity, screen-edge collision, and bounce physics.
/// </summary>
public class PhysicsEngine
{
    private const double Gravity = 800.0;         // pixels per second squared
    private const double BounceDamping = 0.4;     // energy retained on bounce
    private const double FlySpeed = 80.0;         // pixels per second horizontal flight
    private const double MinBounceVelocity = 50.0;// below this, stop bouncing
    private const double DragSmoothing = 0.3;     // lerp factor for drag velocity tracking

    private readonly DispatcherTimer _physicsTimer;
    private DateTime _lastTick;

    // Position and velocity
    public double X { get; set; }
    public double Y { get; set; }
    public double VelocityX { get; set; }
    public double VelocityY { get; set; }

    // Tracked drag velocity (for throw calculation)
    public double DragVelocityX { get; private set; }
    public double DragVelocityY { get; private set; }
    private double _lastDragX, _lastDragY;

    // Boundaries
    public Rect ScreenBounds { get; set; }
    public double GroundY { get; set; }   // bottom boundary (work area height - sprite size)
    public double SpriteSize { get; set; } = 200;

    // State
    public bool IsGravityActive { get; set; }
    public bool IsDragging { get; set; }
    public bool IsFlying { get; set; }
    public int FlyDirection { get; set; } // -1 left, 0 none, 1 right

    public event Action? PositionChanged;
    public event Action? HitGround;
    public event Action? HitScreenEdge;

    public PhysicsEngine()
    {
        _physicsTimer = new DispatcherTimer(DispatcherPriority.Render)
        {
            Interval = TimeSpan.FromMilliseconds(16) // ~60 FPS physics
        };
        _physicsTimer.Tick += OnPhysicsTick;
        _lastTick = DateTime.UtcNow;
    }

    public void Start()
    {
        _lastTick = DateTime.UtcNow;
        _physicsTimer.Start();
    }

    public void Stop()
    {
        _physicsTimer.Stop();
    }

    /// <summary>
    /// Updates screen boundaries. Call when screen resolution changes.
    /// </summary>
    public void UpdateBounds(Rect workArea)
    {
        ScreenBounds = workArea;
        GroundY = workArea.Bottom - SpriteSize;
    }

    /// <summary>
    /// Start dragging — records initial position for velocity tracking.
    /// </summary>
    public void BeginDrag(double mouseX, double mouseY)
    {
        IsDragging = true;
        IsGravityActive = false;
        IsFlying = false;
        VelocityX = 0;
        VelocityY = 0;
        DragVelocityX = 0;
        DragVelocityY = 0;
        _lastDragX = mouseX;
        _lastDragY = mouseY;
    }

    /// <summary>
    /// Updates drag position and tracks velocity for throwing.
    /// </summary>
    public void UpdateDrag(double mouseX, double mouseY, double offsetX, double offsetY)
    {
        X = mouseX - offsetX;
        Y = mouseY - offsetY;

        // Track velocity with smoothing
        double dx = mouseX - _lastDragX;
        double dy = mouseY - _lastDragY;
        DragVelocityX = DragVelocityX * (1 - DragSmoothing) + dx * 60 * DragSmoothing;
        DragVelocityY = DragVelocityY * (1 - DragSmoothing) + dy * 60 * DragSmoothing;
        _lastDragX = mouseX;
        _lastDragY = mouseY;

        ClampToScreen();
        PositionChanged?.Invoke();
    }

    /// <summary>
    /// End drag — apply tracked velocity as throw or start falling.
    /// </summary>
    public void EndDrag()
    {
        IsDragging = false;
        VelocityX = 0;
        VelocityY = 0;
        IsGravityActive = false;
    }

    /// <summary>
    /// Start flying in a direction. Disables gravity.
    /// </summary>
    public void StartFlying(int direction)
    {
        IsFlying = true;
        IsGravityActive = false;
        FlyDirection = direction;
        VelocityX = FlySpeed * direction;
        VelocityY = 0;
    }

    /// <summary>
    /// Stop flying — hover in place.
    /// </summary>
    public void StopFlying()
    {
        IsFlying = false;
        FlyDirection = 0;
        VelocityX = 0;
        VelocityY = 0;
    }

    private void OnPhysicsTick(object? sender, EventArgs e)
    {
        var now = DateTime.UtcNow;
        double dt = Math.Min((now - _lastTick).TotalSeconds, 0.05); // cap at 50ms
        _lastTick = now;
        SimulateTick(dt);
    }

    /// <summary>
    /// Runs one physics step with the given delta time. Exposed for testing.
    /// </summary>
    internal void SimulateTick(double dt)
    {
        if (IsDragging) return;
        if (dt <= 0) return;

        bool moved = false;

        // Apply gravity
        if (IsGravityActive)
        {
            VelocityY += Gravity * dt;
        }

        // Apply flying gentle bob (sine wave vertical oscillation)
        if (IsFlying)
        {
            double bobAmplitude = 0.3;
            double bobFreq = 2.0;
            VelocityY = Math.Sin(DateTime.UtcNow.TimeOfDay.TotalSeconds * bobFreq) * bobAmplitude * 60;
        }

        // Update position
        if (Math.Abs(VelocityX) > 0.1 || Math.Abs(VelocityY) > 0.1)
        {
            X += VelocityX * dt;
            Y += VelocityY * dt;
            moved = true;
        }

        // Ground collision
        if (Y >= GroundY)
        {
            Y = GroundY;
            if (VelocityY > MinBounceVelocity)
            {
                VelocityY = -VelocityY * BounceDamping;
                VelocityX *= 0.8; // friction
            }
            else
            {
                VelocityY = 0;
                if (IsGravityActive && Math.Abs(VelocityX) < 10)
                {
                    VelocityX = 0;
                    IsGravityActive = false;
                    HitGround?.Invoke();
                }
            }
            moved = true;
        }

        // Screen left/right edge collision
        if (X < ScreenBounds.Left)
        {
            X = ScreenBounds.Left;
            if (IsFlying)
            {
                HitScreenEdge?.Invoke();
            }
            else
            {
                VelocityX = Math.Abs(VelocityX) * BounceDamping;
            }
            moved = true;
        }
        else if (X > ScreenBounds.Right - SpriteSize)
        {
            X = ScreenBounds.Right - SpriteSize;
            if (IsFlying)
            {
                HitScreenEdge?.Invoke();
            }
            else
            {
                VelocityX = -Math.Abs(VelocityX) * BounceDamping;
            }
            moved = true;
        }

        // Top edge
        if (Y < ScreenBounds.Top)
        {
            Y = ScreenBounds.Top;
            VelocityY = Math.Abs(VelocityY) * BounceDamping;
            moved = true;
        }

        if (moved)
            PositionChanged?.Invoke();
    }

    private void ClampToScreen()
    {
        double minX = ScreenBounds.Left;
        double maxX = ScreenBounds.Right - SpriteSize;
        double minY = ScreenBounds.Top;
        double maxY = ScreenBounds.Bottom - SpriteSize;

        // Guard against uninitialized or too-small bounds
        if (maxX >= minX)
            X = Math.Clamp(X, minX, maxX);
        if (maxY >= minY)
            Y = Math.Clamp(Y, minY, maxY);
    }
}

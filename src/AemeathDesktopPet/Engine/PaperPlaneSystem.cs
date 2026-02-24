using System.Windows;
using System.Windows.Threading;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// Paper plane system: thrown planes (parabolic + sinusoidal trajectory) and
/// ambient planes (slow sinusoidal drift from screen edges).
/// </summary>
public class PaperPlaneSystem
{
    private static readonly Random _rng = new();

    private readonly DispatcherTimer _updateTimer;
    private readonly DispatcherTimer _ambientSpawnTimer;
    private readonly List<PaperPlane> _planes = new();

    public IReadOnlyList<PaperPlane> Planes => _planes;
    public bool EnableAmbient { get; set; } = true;

    /// <summary>
    /// Fired when a thrown plane lands (hits bottom of screen). Used by CatBehaviorEngine.
    /// Args: landing X position.
    /// </summary>
    public event Action<double>? PlaneLanded;

    /// <summary>
    /// Fired whenever the planes list changes (for UI rendering).
    /// </summary>
    public event Action? PlanesChanged;

    public PaperPlaneSystem()
    {
        _updateTimer = new DispatcherTimer(DispatcherPriority.Render)
        {
            Interval = TimeSpan.FromMilliseconds(33) // ~30 FPS
        };
        _updateTimer.Tick += OnUpdateTick;

        _ambientSpawnTimer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromMinutes(5)
        };
        _ambientSpawnTimer.Tick += OnAmbientSpawnTick;
    }

    public void Start()
    {
        _updateTimer.Start();
        if (EnableAmbient)
            _ambientSpawnTimer.Start();
    }

    public void Stop()
    {
        _updateTimer.Stop();
        _ambientSpawnTimer.Stop();
    }

    /// <summary>
    /// Throws a paper plane from Aemeath's position.
    /// </summary>
    public void ThrowPlane(double startX, double startY, Rect screenBounds)
    {
        int direction = _rng.NextDouble() < 0.5 ? -1 : 1;
        _planes.Add(new PaperPlane
        {
            X = startX,
            Y = startY,
            VelocityX = direction * (80 + _rng.NextDouble() * 60),
            VelocityY = -40 - _rng.NextDouble() * 30, // initial upward arc
            IsAmbient = false,
            ScreenBounds = screenBounds,
            Angle = direction * 15,
            TimeAlive = 0,
        });
        PlanesChanged?.Invoke();
    }

    /// <summary>
    /// Spawns an ambient plane from a random screen edge.
    /// </summary>
    public void SpawnAmbient(Rect screenBounds)
    {
        bool fromLeft = _rng.NextDouble() < 0.5;
        double startX = fromLeft ? screenBounds.Left - 30 : screenBounds.Right + 30;
        double startY = screenBounds.Top + _rng.NextDouble() * screenBounds.Height * 0.5;
        int direction = fromLeft ? 1 : -1;

        _planes.Add(new PaperPlane
        {
            X = startX,
            Y = startY,
            VelocityX = direction * (20 + _rng.NextDouble() * 30),
            VelocityY = 5 + _rng.NextDouble() * 10,
            IsAmbient = true,
            ScreenBounds = screenBounds,
            Angle = direction * 10,
            TimeAlive = 0,
        });
        PlanesChanged?.Invoke();
    }

    /// <summary>
    /// Click interaction with a plane — makes it spin and change trajectory.
    /// </summary>
    public bool TryClickPlane(double clickX, double clickY)
    {
        for (int i = 0; i < _planes.Count; i++)
        {
            var p = _planes[i];
            if (Math.Abs(p.X - clickX) < 25 && Math.Abs(p.Y - clickY) < 25)
            {
                p.VelocityX = -p.VelocityX * 0.8;
                p.VelocityY = -30 - _rng.NextDouble() * 20;
                p.Angle += 360; // spin
                PlanesChanged?.Invoke();
                return true;
            }
        }
        return false;
    }

    private void OnUpdateTick(object? sender, EventArgs e)
    {
        if (_planes.Count == 0) return;

        double dt = 0.033; // ~30 FPS
        bool changed = false;

        for (int i = _planes.Count - 1; i >= 0; i--)
        {
            var p = _planes[i];
            p.TimeAlive += dt;

            // Parabolic trajectory (gravity) + sinusoidal wobble
            p.VelocityY += 20 * dt; // gentle gravity
            p.X += p.VelocityX * dt;
            p.Y += p.VelocityY * dt + Math.Sin(p.TimeAlive * 3) * 0.5; // wobble

            // Angle follows velocity
            p.Angle = Math.Atan2(p.VelocityY, p.VelocityX) * 180 / Math.PI;

            // Remove if off-screen or hit ground
            bool offScreen = p.X < p.ScreenBounds.Left - 50 || p.X > p.ScreenBounds.Right + 50;
            bool hitGround = p.Y > p.ScreenBounds.Bottom;
            bool tooOld = p.TimeAlive > 20; // 20 seconds max

            if (offScreen || hitGround || tooOld)
            {
                if (hitGround && !p.IsAmbient)
                    PlaneLanded?.Invoke(p.X);

                _planes.RemoveAt(i);
            }

            changed = true;
        }

        if (changed)
            PlanesChanged?.Invoke();
    }

    private void OnAmbientSpawnTick(object? sender, EventArgs e)
    {
        if (!EnableAmbient) return;

        // Randomize next spawn: 3-8 minutes
        _ambientSpawnTimer.Interval = TimeSpan.FromMinutes(3 + _rng.NextDouble() * 5);

        // Use a reasonable default screen bounds
        var bounds = new Rect(0, 0, SystemParameters.PrimaryScreenWidth, SystemParameters.PrimaryScreenHeight);
        SpawnAmbient(bounds);
    }
}

public class PaperPlane
{
    public double X { get; set; }
    public double Y { get; set; }
    public double VelocityX { get; set; }
    public double VelocityY { get; set; }
    public double Angle { get; set; }
    public double TimeAlive { get; set; }
    public bool IsAmbient { get; set; }
    public Rect ScreenBounds { get; set; }
}

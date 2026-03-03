using System.Windows.Threading;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// Lightweight particle system for visual effects. Max 12 particles.
/// Particle types: MusicNote, Heart, Sparkle, SleepZ, PawPrint, FurPuff.
/// </summary>
public class ParticleSystem
{
    private static readonly Random _rng = new();
    private const int MaxParticles = 12;

    private readonly DispatcherTimer _timer;
    private readonly List<Particle> _particles = new();

    public IReadOnlyList<Particle> Particles => _particles;

    public event Action? ParticlesChanged;

    public ParticleSystem()
    {
        _timer = new DispatcherTimer(DispatcherPriority.Render)
        {
            Interval = TimeSpan.FromMilliseconds(50) // 20 FPS
        };
        _timer.Tick += OnTick;
    }

    public void Start() => _timer.Start();
    public void Stop() => _timer.Stop();

    /// <summary>
    /// Emits particles of the given type at position (x, y).
    /// </summary>
    public void Emit(ParticleType type, double x, double y, int count = 3)
    {
        for (int i = 0; i < count && _particles.Count < MaxParticles; i++)
        {
            _particles.Add(new Particle
            {
                Type = type,
                X = x + _rng.Next(-20, 20),
                Y = y + _rng.Next(-10, 10),
                VelocityX = (_rng.NextDouble() - 0.5) * 40,
                VelocityY = -30 - _rng.NextDouble() * 40, // float upward
                Life = 1.0,
                DecayRate = 0.02 + _rng.NextDouble() * 0.02,
                Glyph = GetGlyph(type),
            });
        }
        ParticlesChanged?.Invoke();
    }

    private void OnTick(object? sender, EventArgs e)
    {
        if (_particles.Count == 0)
            return;

        bool changed = false;
        for (int i = _particles.Count - 1; i >= 0; i--)
        {
            var p = _particles[i];
            p.X += p.VelocityX * 0.05; // dt = 50ms
            p.Y += p.VelocityY * 0.05;
            p.VelocityY += 5; // slight gravity/slowdown
            p.Life -= p.DecayRate;
            p.Opacity = Math.Max(0, p.Life);

            if (p.Life <= 0)
                _particles.RemoveAt(i);

            changed = true;
        }

        if (changed)
            ParticlesChanged?.Invoke();
    }

    private static string GetGlyph(ParticleType type) => type switch
    {
        ParticleType.MusicNote => "\u266A",
        ParticleType.Heart => "\u2665",
        ParticleType.Sparkle => "\u2726",
        ParticleType.SleepZ => "Z",
        ParticleType.PawPrint => "\uD83D\uDC3E", // 🐾
        ParticleType.FurPuff => "\u2022",
        _ => "\u2726",
    };
}

public enum ParticleType
{
    MusicNote,
    Heart,
    Sparkle,
    SleepZ,
    PawPrint,
    FurPuff,
}

public class Particle
{
    public ParticleType Type { get; set; }
    public double X { get; set; }
    public double Y { get; set; }
    public double VelocityX { get; set; }
    public double VelocityY { get; set; }
    public double Life { get; set; } = 1.0;
    public double DecayRate { get; set; } = 0.03;
    public double Opacity { get; set; } = 1.0;
    public string Glyph { get; set; } = "\u2726";
}

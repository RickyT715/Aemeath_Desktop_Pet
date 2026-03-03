using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// Digital ghost glitch effect: RGB split, horizontal slice displacement, opacity flicker.
/// 2-5% trigger chance per 5-10s tick, 300-800ms duration.
/// </summary>
public class GlitchEffect
{
    private static readonly Random _rng = new();

    private readonly DispatcherTimer _triggerTimer;
    private readonly DispatcherTimer _animTimer;

    private bool _isGlitching;
    private int _glitchFramesRemaining;
    private int _glitchTotalFrames;

    public bool IsGlitching => _isGlitching;
    public bool IsEnabled { get; set; } = true;

    /// <summary>
    /// Fired when a glitch sequence starts.
    /// </summary>
    public event Action? GlitchStarted;

    /// <summary>
    /// Fired when a glitch sequence ends.
    /// </summary>
    public event Action? GlitchEnded;

    /// <summary>
    /// Provides the current glitch overlay frame (WriteableBitmap with effects applied).
    /// Args: opacity (0-1), horizontalOffset (px), rgbSplit (bool)
    /// </summary>
    public event Action<double, double, bool>? GlitchFrameChanged;

    public GlitchEffect()
    {
        _triggerTimer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromSeconds(7) // check every 7s average
        };
        _triggerTimer.Tick += OnTriggerTick;

        _animTimer = new DispatcherTimer(DispatcherPriority.Render)
        {
            Interval = TimeSpan.FromMilliseconds(50) // 20 FPS for glitch animation
        };
        _animTimer.Tick += OnAnimTick;
    }

    public void Start()
    {
        _triggerTimer.Start();
    }

    public void Stop()
    {
        _triggerTimer.Stop();
        _animTimer.Stop();
        _isGlitching = false;
    }

    /// <summary>
    /// Force a glitch (e.g., for testing or special events).
    /// </summary>
    public void TriggerGlitch()
    {
        if (_isGlitching || !IsEnabled)
            return;

        _isGlitching = true;
        // 300-800ms duration at 50ms per frame = 6-16 frames
        int durationMs = _rng.Next(300, 800);
        _glitchTotalFrames = durationMs / 50;
        _glitchFramesRemaining = _glitchTotalFrames;

        GlitchStarted?.Invoke();
        _animTimer.Start();
    }

    private void OnTriggerTick(object? sender, EventArgs e)
    {
        if (_isGlitching || !IsEnabled)
            return;

        // Randomize next check interval (5-10s)
        _triggerTimer.Interval = TimeSpan.FromSeconds(5 + _rng.NextDouble() * 5);

        // 2-5% chance to trigger
        double chance = 0.02 + _rng.NextDouble() * 0.03;
        if (_rng.NextDouble() < chance)
        {
            TriggerGlitch();
        }
    }

    private void OnAnimTick(object? sender, EventArgs e)
    {
        if (_glitchFramesRemaining <= 0)
        {
            _animTimer.Stop();
            _isGlitching = false;
            GlitchFrameChanged?.Invoke(1.0, 0, false); // reset
            GlitchEnded?.Invoke();
            return;
        }

        _glitchFramesRemaining--;
        double progress = 1.0 - (double)_glitchFramesRemaining / _glitchTotalFrames;

        // Opacity flicker: alternate between 100% and 40%
        double opacity = _glitchFramesRemaining % 2 == 0 ? 1.0 : 0.4;

        // Horizontal displacement: random -6 to +6 px
        double hOffset = _rng.Next(-6, 7);

        // RGB split on random frames
        bool rgbSplit = _rng.NextDouble() < 0.5;

        GlitchFrameChanged?.Invoke(opacity, hOffset, rgbSplit);
    }
}

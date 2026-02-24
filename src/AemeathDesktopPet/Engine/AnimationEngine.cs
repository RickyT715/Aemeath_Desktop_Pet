using System.IO;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Threading;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Engine;

/// <summary>
/// Loads GIF animations, decodes frames, and drives frame-by-frame playback.
/// </summary>
public class AnimationEngine
{
    private readonly Dictionary<string, BitmapSource[]> _frameCache = new();
    private readonly Dictionary<string, BitmapSource[]> _mirroredCache = new();
    private readonly DispatcherTimer _timer;
    private readonly string _spritesDir;

    private BitmapSource[]? _currentFrames;
    private int _currentFrameIndex;
    private bool _loop;
    private bool _isDirty;

    public event Action<BitmapSource>? FrameChanged;
    public event Action? AnimationCompleted;

    public BitmapSource? CurrentFrame => _currentFrames is not null && _currentFrameIndex < _currentFrames.Length
        ? _currentFrames[_currentFrameIndex]
        : null;

    public bool IsPlaying { get; private set; }

    public AnimationEngine()
    {
        _spritesDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Resources", "Sprites");

        _timer = new DispatcherTimer(DispatcherPriority.Render)
        {
            Interval = TimeSpan.FromMilliseconds(109) // ~9 FPS default
        };
        _timer.Tick += OnTimerTick;
    }

    /// <summary>
    /// Pre-loads all GIF animations from disk into memory.
    /// Call once at startup.
    /// </summary>
    public void PreloadAll()
    {
        var ameathDir = Path.Combine(_spritesDir, "Aemeath");
        if (!Directory.Exists(ameathDir)) return;

        foreach (var gif in Directory.EnumerateFiles(ameathDir, "*.gif"))
        {
            var key = Path.GetFileNameWithoutExtension(gif);
            if (!_frameCache.ContainsKey(key))
            {
                var frames = DecodeGif(gif);
                if (frames.Length > 0)
                    _frameCache[key] = frames;
            }
        }
    }

    /// <summary>
    /// Plays an animation by GIF filename (without extension).
    /// </summary>
    public void Play(AnimationInfo anim)
    {
        var key = Path.GetFileNameWithoutExtension(anim.GifFileName);

        BitmapSource[]? frames;
        if (anim.Mirror)
        {
            if (!_mirroredCache.TryGetValue(key, out frames))
            {
                if (_frameCache.TryGetValue(key, out var origFrames))
                {
                    frames = MirrorFrames(origFrames);
                    _mirroredCache[key] = frames;
                }
            }
        }
        else
        {
            _frameCache.TryGetValue(key, out frames);
        }

        // Fallback to normal.gif if animation not found
        if (frames is null || frames.Length == 0)
        {
            if (key != "normal")
                _frameCache.TryGetValue("normal", out frames);
            if (frames is null || frames.Length == 0)
                return;
        }

        _currentFrames = frames;
        _currentFrameIndex = 0;
        _loop = anim.Loop;
        _isDirty = true;

        _timer.Interval = TimeSpan.FromMilliseconds(1000.0 / anim.Fps);
        _timer.Start();
        IsPlaying = true;

        // Emit first frame immediately
        FrameChanged?.Invoke(_currentFrames[0]);
    }

    public void Stop()
    {
        _timer.Stop();
        IsPlaying = false;
    }

    private void OnTimerTick(object? sender, EventArgs e)
    {
        if (_currentFrames is null) return;

        _currentFrameIndex++;

        if (_currentFrameIndex >= _currentFrames.Length)
        {
            if (_loop)
            {
                _currentFrameIndex = 0;
            }
            else
            {
                _currentFrameIndex = _currentFrames.Length - 1;
                _timer.Stop();
                IsPlaying = false;
                AnimationCompleted?.Invoke();
                return;
            }
        }

        _isDirty = true;
        FrameChanged?.Invoke(_currentFrames[_currentFrameIndex]);
    }

    /// <summary>
    /// Decodes all frames from a GIF file into individual BitmapSource objects.
    /// </summary>
    private static BitmapSource[] DecodeGif(string filePath)
    {
        try
        {
            using var stream = File.OpenRead(filePath);
            var decoder = new GifBitmapDecoder(stream, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad);
            var frames = new BitmapSource[decoder.Frames.Count];

            for (int i = 0; i < decoder.Frames.Count; i++)
            {
                // Convert to Pbgra32 for fast rendering
                var converted = new FormatConvertedBitmap(decoder.Frames[i], PixelFormats.Pbgra32, null, 0);
                converted.Freeze();
                frames[i] = converted;
            }

            return frames;
        }
        catch
        {
            return Array.Empty<BitmapSource>();
        }
    }

    /// <summary>
    /// Creates horizontally mirrored copies of all frames.
    /// </summary>
    private static BitmapSource[] MirrorFrames(BitmapSource[] originals)
    {
        var mirrored = new BitmapSource[originals.Length];
        for (int i = 0; i < originals.Length; i++)
        {
            var tb = new TransformedBitmap(originals[i], new ScaleTransform(-1, 1, originals[i].PixelWidth / 2.0, 0));
            tb.Freeze();
            mirrored[i] = tb;
        }
        return mirrored;
    }
}

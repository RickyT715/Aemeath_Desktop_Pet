using System.Collections.Concurrent;
using System.IO;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using NAudio.Wave;

namespace AemeathDesktopPet.Services;

/// <summary>
/// Main TTS service — synthesizes text via a configurable provider and plays audio via NAudio.
/// Supports queue-based playback, cancellation, volume control, and fullscreen auto-mute.
/// </summary>
public class TtsVoiceService : ITtsService, IDisposable
{
    private readonly Func<TtsConfig> _getConfig;
    private readonly EnvironmentDetector _environment;
    private ITtsProvider? _provider;

    private WaveOutEvent? _waveOut;
    private IWaveProvider? _currentReader;

    private readonly ConcurrentQueue<string> _queue = new();
    private CancellationTokenSource? _cts;
    private readonly SemaphoreSlim _playbackLock = new(1, 1);
    private volatile bool _disposed;
    private double _volume = 0.7;

    public bool IsAvailable => _provider?.IsAvailable ?? false;

    public TtsVoiceService(Func<TtsConfig> getConfig, EnvironmentDetector environment)
    {
        _getConfig = getConfig;
        _environment = environment;
        _volume = getConfig().Volume;
        RecreateProvider();
    }

    public void RecreateProvider()
    {
        _provider?.Dispose();
        _provider = CreateProvider(_getConfig());
    }

    private ITtsProvider CreateProvider(TtsConfig config)
    {
        return config.Provider switch
        {
            "gptsovits" => new GptSovitsTtsProvider(() => _getConfig()),
            "elevenlabs" => new ElevenLabsTtsProvider(() => _getConfig()),
            "fishaudio" => new FishAudioTtsProvider(() => _getConfig()),
            "openaitts" => new OpenAiTtsProvider(() => _getConfig()),
            _ => new EdgeTtsProvider(() => _getConfig()),
        };
    }

    public async Task SpeakAsync(string text)
    {
        if (_disposed || string.IsNullOrWhiteSpace(text)) return;

        var config = _getConfig();
        if (!config.Enabled) return;

        // Auto-mute: skip if fullscreen app is active
        if (config.AutoMuteFullscreen && _environment.IsFullscreenAppActive())
            return;

        _queue.Enqueue(text);
        await ProcessQueueAsync();
    }

    public void Stop()
    {
        // Cancel current synthesis
        _cts?.Cancel();

        // Clear the queue
        while (_queue.TryDequeue(out _)) { }

        // Stop audio playback
        StopPlayback();
    }

    public void SetVolume(double volume)
    {
        _volume = Math.Clamp(volume, 0.0, 1.0);
        if (_waveOut != null)
            _waveOut.Volume = (float)_volume;
    }

    private async Task ProcessQueueAsync()
    {
        if (!await _playbackLock.WaitAsync(0))
            return; // Already processing

        try
        {
            while (_queue.TryDequeue(out var text) && !_disposed)
            {
                await SynthesizeAndPlayAsync(text);
            }
        }
        finally
        {
            _playbackLock.Release();
        }
    }

    private async Task SynthesizeAndPlayAsync(string text)
    {
        if (_provider == null || !_provider.IsAvailable) return;

        _cts?.Dispose();
        _cts = new CancellationTokenSource();
        var ct = _cts.Token;

        try
        {
            var audioBytes = await _provider.SynthesizeAsync(text, ct);
            if (audioBytes == null || audioBytes.Length == 0 || ct.IsCancellationRequested)
                return;

            // Re-check fullscreen before playing
            var config = _getConfig();
            if (config.AutoMuteFullscreen && _environment.IsFullscreenAppActive())
                return;

            await PlayAudioBytesAsync(audioBytes, ct);
        }
        catch (OperationCanceledException)
        {
            // Expected when Stop() is called
        }
        catch
        {
            // Synthesis or playback failed — silently continue
        }
    }

    private async Task PlayAudioBytesAsync(byte[] audioBytes, CancellationToken ct)
    {
        StopPlayback();

        var ms = new MemoryStream(audioBytes);

        try
        {
            // Detect format: MP3 (Edge TTS, ElevenLabs) or WAV (GPT-SoVITS)
            IWaveProvider reader;
            if (IsWavFormat(audioBytes))
                reader = new WaveFileReader(ms);
            else
                reader = new Mp3FileReader(ms);

            _currentReader = reader;

            _waveOut = new WaveOutEvent();
            _waveOut.Volume = (float)_volume;
            _waveOut.Init(reader);

            var tcs = new TaskCompletionSource<bool>();
            _waveOut.PlaybackStopped += (_, _) => tcs.TrySetResult(true);

            _waveOut.Play();

            // Wait for playback to complete or cancellation
            using var reg = ct.Register(() =>
            {
                StopPlayback();
                tcs.TrySetResult(false);
            });

            await tcs.Task;
        }
        catch (OperationCanceledException)
        {
            throw;
        }
        catch
        {
            // Format error or device error — skip this utterance
        }
        finally
        {
            StopPlayback();
            ms.Dispose();
        }
    }

    private void StopPlayback()
    {
        try
        {
            if (_waveOut != null)
            {
                if (_waveOut.PlaybackState == PlaybackState.Playing)
                    _waveOut.Stop();
                _waveOut.Dispose();
                _waveOut = null;
            }

            if (_currentReader is IDisposable disposable)
            {
                disposable.Dispose();
                _currentReader = null;
            }
        }
        catch
        {
            // Cleanup errors are non-critical
        }
    }

    private static bool IsWavFormat(byte[] data)
    {
        // WAV files start with "RIFF"
        return data.Length >= 4
            && data[0] == 'R' && data[1] == 'I'
            && data[2] == 'F' && data[3] == 'F';
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;

        Stop();
        _cts?.Dispose();
        _provider?.Dispose();
        _playbackLock.Dispose();
    }
}

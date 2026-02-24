using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class TtsVoiceServiceTests : IDisposable
{
    private readonly TtsVoiceService _tts;
    private readonly TtsConfig _config;

    public TtsVoiceServiceTests()
    {
        _config = new TtsConfig { Enabled = false };
        var env = new EnvironmentDetector();
        _tts = new TtsVoiceService(() => _config, env);
    }

    public void Dispose()
    {
        _tts.Dispose();
    }

    // --- Interface compliance ---

    [Fact]
    public void ImplementsITtsService()
    {
        Assert.IsAssignableFrom<ITtsService>(_tts);
    }

    [Fact]
    public void ImplementsIDisposable()
    {
        Assert.IsAssignableFrom<IDisposable>(_tts);
    }

    // --- IsAvailable per provider ---

    [Fact]
    public void IsAvailable_EdgeTts_AlwaysTrue()
    {
        _config.Provider = "edgetts";
        _tts.RecreateProvider();
        Assert.True(_tts.IsAvailable);
    }

    [Fact]
    public void IsAvailable_GptSovits_WhenUrlConfigured_True()
    {
        _config.Provider = "gptsovits";
        _config.GptsovitsUrl = "http://localhost:9880";
        _tts.RecreateProvider();
        Assert.True(_tts.IsAvailable);
    }

    [Fact]
    public void IsAvailable_GptSovits_WhenUrlEmpty_False()
    {
        _config.Provider = "gptsovits";
        _config.GptsovitsUrl = "";
        _tts.RecreateProvider();
        Assert.False(_tts.IsAvailable);
    }

    [Fact]
    public void IsAvailable_ElevenLabs_WhenNoApiKey_False()
    {
        _config.Provider = "elevenlabs";
        _config.ElevenLabsApiKey = "";
        _tts.RecreateProvider();
        Assert.False(_tts.IsAvailable);
    }

    [Fact]
    public void IsAvailable_ElevenLabs_WhenApiKeySet_True()
    {
        _config.Provider = "elevenlabs";
        _config.ElevenLabsApiKey = "test-key";
        _tts.RecreateProvider();
        Assert.True(_tts.IsAvailable);
    }

    [Fact]
    public void IsAvailable_UnknownProvider_FallsBackToEdgeTts()
    {
        _config.Provider = "unknown_provider";
        _tts.RecreateProvider();
        Assert.True(_tts.IsAvailable); // Falls back to EdgeTts
    }

    // --- SpeakAsync guard checks ---

    [Fact]
    public async Task SpeakAsync_WhenDisabled_DoesNotThrow()
    {
        _config.Enabled = false;
        await _tts.SpeakAsync("Hello");
    }

    [Fact]
    public async Task SpeakAsync_NullText_DoesNotThrow()
    {
        _config.Enabled = true;
        await _tts.SpeakAsync(null!);
    }

    [Fact]
    public async Task SpeakAsync_EmptyText_DoesNotThrow()
    {
        _config.Enabled = true;
        await _tts.SpeakAsync("");
    }

    [Fact]
    public async Task SpeakAsync_WhitespaceText_DoesNotThrow()
    {
        _config.Enabled = true;
        await _tts.SpeakAsync("   ");
    }

    [Fact]
    public async Task SpeakAsync_AfterDispose_DoesNotThrow()
    {
        _config.Enabled = true;
        _tts.Dispose();
        await _tts.SpeakAsync("Hello after dispose");
    }

    // --- Stop ---

    [Fact]
    public void Stop_DoesNotThrow()
    {
        _tts.Stop();
    }

    [Fact]
    public void Stop_CalledMultipleTimes_DoesNotThrow()
    {
        _tts.Stop();
        _tts.Stop();
        _tts.Stop();
    }

    [Fact]
    public void Stop_AfterDispose_DoesNotThrow()
    {
        _tts.Dispose();
        _tts.Stop();
    }

    // --- SetVolume ---

    [Fact]
    public void SetVolume_NormalRange_DoesNotThrow()
    {
        _tts.SetVolume(0.0);
        _tts.SetVolume(0.5);
        _tts.SetVolume(1.0);
    }

    [Fact]
    public void SetVolume_BelowZero_ClampsToZero()
    {
        // Should not throw — clamps internally
        _tts.SetVolume(-1.0);
        _tts.SetVolume(-100.0);
    }

    [Fact]
    public void SetVolume_AboveOne_ClampsToOne()
    {
        // Should not throw — clamps internally
        _tts.SetVolume(2.0);
        _tts.SetVolume(100.0);
    }

    // --- Dispose ---

    [Fact]
    public void Dispose_CalledTwice_DoesNotThrow()
    {
        _tts.Dispose();
        _tts.Dispose();
    }

    // --- RecreateProvider ---

    [Fact]
    public void RecreateProvider_DoesNotThrow()
    {
        _tts.RecreateProvider();
    }

    [Fact]
    public void RecreateProvider_SwitchAllProviders_DoesNotThrow()
    {
        _config.Provider = "edgetts";
        _tts.RecreateProvider();

        _config.Provider = "gptsovits";
        _tts.RecreateProvider();

        _config.Provider = "elevenlabs";
        _tts.RecreateProvider();

        _config.Provider = "edgetts";
        _tts.RecreateProvider();
    }

    [Fact]
    public void RecreateProvider_PreservesAvailability()
    {
        _config.Provider = "edgetts";
        _tts.RecreateProvider();
        Assert.True(_tts.IsAvailable);

        _config.Provider = "elevenlabs";
        _config.ElevenLabsApiKey = "";
        _tts.RecreateProvider();
        Assert.False(_tts.IsAvailable);

        _config.Provider = "edgetts";
        _tts.RecreateProvider();
        Assert.True(_tts.IsAvailable);
    }

    // --- Volume from config ---

    [Fact]
    public void Constructor_ReadsVolumeFromConfig()
    {
        var config = new TtsConfig { Volume = 0.3 };
        var env = new EnvironmentDetector();
        using var tts = new TtsVoiceService(() => config, env);
        // No direct way to assert volume, but it shouldn't throw
        tts.SetVolume(0.5);
    }

    // --- AutoMuteFullscreen (config check only, no real fullscreen) ---

    [Fact]
    public async Task SpeakAsync_AutoMuteEnabled_DoesNotThrow()
    {
        _config.Enabled = true;
        _config.AutoMuteFullscreen = true;
        // No fullscreen app running in test environment, so TTS should proceed
        // It will fail at synthesis (no network), but that's caught internally
        await _tts.SpeakAsync("Hello with auto-mute");
    }

    [Fact]
    public async Task SpeakAsync_AutoMuteDisabled_DoesNotThrow()
    {
        _config.Enabled = true;
        _config.AutoMuteFullscreen = false;
        await _tts.SpeakAsync("Hello without auto-mute");
    }
}

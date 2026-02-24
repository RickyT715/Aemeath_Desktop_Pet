using System.Collections.Generic;
using System.Net.Http;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class GptSovitsTtsProviderTests : IDisposable
{
    private readonly TtsConfig _config;
    private readonly GptSovitsTtsProvider _provider;

    public GptSovitsTtsProviderTests()
    {
        _config = new TtsConfig { GptsovitsUrl = "http://localhost:9880" };
        _provider = new GptSovitsTtsProvider(() => _config);
    }

    public void Dispose()
    {
        _provider.Dispose();
    }

    [Fact]
    public void Name_IsGptSovits()
    {
        Assert.Equal("GPT-SoVITS", _provider.Name);
    }

    [Fact]
    public void IsAvailable_TrueWhenUrlConfigured()
    {
        _config.GptsovitsUrl = "http://localhost:9880";
        Assert.True(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenUrlEmpty()
    {
        _config.GptsovitsUrl = "";
        Assert.False(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenUrlWhitespace()
    {
        _config.GptsovitsUrl = "   ";
        Assert.False(_provider.IsAvailable);
    }

    [Fact]
    public async Task SynthesizeAsync_NullText_ReturnsNull()
    {
        var result = await _provider.SynthesizeAsync(null!, CancellationToken.None);
        Assert.Null(result);
    }

    [Fact]
    public async Task SynthesizeAsync_EmptyText_ReturnsNull()
    {
        var result = await _provider.SynthesizeAsync("", CancellationToken.None);
        Assert.Null(result);
    }

    [Fact]
    public async Task SynthesizeAsync_WhitespaceText_ReturnsNull()
    {
        var result = await _provider.SynthesizeAsync("   ", CancellationToken.None);
        Assert.Null(result);
    }

    [Fact]
    public async Task SynthesizeAsync_NoServer_ThrowsHttpRequestException()
    {
        // No server running on this port — should fail with connection error
        _config.GptsovitsUrl = "http://localhost:19999";
        await Assert.ThrowsAsync<HttpRequestException>(
            () => _provider.SynthesizeAsync("Hello", CancellationToken.None));
    }

    [Fact]
    public async Task SynthesizeAsync_CancelledToken_ThrowsOperationCanceled()
    {
        var cts = new CancellationTokenSource();
        cts.Cancel();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(
            () => _provider.SynthesizeAsync("Hello", cts.Token));
    }

    [Fact]
    public void Dispose_DoesNotThrow()
    {
        _provider.Dispose();
    }

    [Fact]
    public void ImplementsITtsProvider()
    {
        Assert.IsAssignableFrom<ITtsProvider>(_provider);
    }

    [Fact]
    public async Task SynthesizeAsync_NoProfiles_UsesLegacyPayload()
    {
        // No profiles configured — should attempt legacy /tts and fail with connection error
        _config.GptsovitsUrl = "http://localhost:19999";
        _config.GptsovitsProfiles = new List<GptSovitsProfile>();
        _config.GptsovitsActiveProfile = "";

        await Assert.ThrowsAsync<HttpRequestException>(
            () => _provider.SynthesizeAsync("Hello", CancellationToken.None));
    }

    [Fact]
    public async Task SynthesizeAsync_ActiveProfileNotFound_UsesLegacyPayload()
    {
        // Active profile name doesn't match any existing profile — falls back to legacy
        _config.GptsovitsUrl = "http://localhost:19999";
        _config.GptsovitsProfiles = new List<GptSovitsProfile>
        {
            new() { Name = "ModelA" }
        };
        _config.GptsovitsActiveProfile = "NonExistent";

        await Assert.ThrowsAsync<HttpRequestException>(
            () => _provider.SynthesizeAsync("Hello", CancellationToken.None));
    }

    [Fact]
    public async Task SynthesizeAsync_WithProfile_NoServer_ThrowsHttpRequestException()
    {
        // Profile found — should attempt model switch (GET /set_gpt_weights) and fail
        _config.GptsovitsUrl = "http://localhost:19999";
        _config.GptsovitsProfiles = new List<GptSovitsProfile>
        {
            new()
            {
                Name = "TestModel",
                GptWeightsPath = "/models/test.ckpt",
                SovitsWeightsPath = "/models/test.pth",
                RefAudioPath = "/audio/ref.wav",
                PromptText = "test prompt"
            }
        };
        _config.GptsovitsActiveProfile = "TestModel";

        await Assert.ThrowsAsync<HttpRequestException>(
            () => _provider.SynthesizeAsync("Hello", CancellationToken.None));
    }
}

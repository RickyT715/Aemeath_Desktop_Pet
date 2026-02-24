using System.Net.Http;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class ElevenLabsTtsProviderTests : IDisposable
{
    private readonly TtsConfig _config;
    private readonly ElevenLabsTtsProvider _provider;

    public ElevenLabsTtsProviderTests()
    {
        _config = new TtsConfig { ElevenLabsApiKey = "test-key" };
        _provider = new ElevenLabsTtsProvider(() => _config);
    }

    public void Dispose()
    {
        _provider.Dispose();
    }

    [Fact]
    public void Name_IsElevenLabs()
    {
        Assert.Equal("ElevenLabs", _provider.Name);
    }

    [Fact]
    public void IsAvailable_TrueWhenApiKeySet()
    {
        _config.ElevenLabsApiKey = "some-key";
        Assert.True(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyEmpty()
    {
        _config.ElevenLabsApiKey = "";
        Assert.False(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyWhitespace()
    {
        _config.ElevenLabsApiKey = "   ";
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
    public async Task SynthesizeAsync_InvalidApiKey_ThrowsHttpRequestException()
    {
        // Fake key will fail auth with 401
        _config.ElevenLabsApiKey = "invalid-key";
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
    public void DefaultVoiceId_IsRachel()
    {
        Assert.Equal("21m00Tcm4TlvDq8ikWAM", _config.ElevenLabsVoiceId);
    }

    [Fact]
    public void DefaultModelId_IsMultilingualV2()
    {
        Assert.Equal("eleven_multilingual_v2", _config.ElevenLabsModelId);
    }
}

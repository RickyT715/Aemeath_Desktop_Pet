using System.Net.Http;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class FishAudioTtsProviderTests : IDisposable
{
    private readonly TtsConfig _config;
    private readonly FishAudioTtsProvider _provider;

    public FishAudioTtsProviderTests()
    {
        _config = new TtsConfig { FishAudioApiKey = "test-key" };
        _provider = new FishAudioTtsProvider(() => _config);
    }

    public void Dispose()
    {
        _provider.Dispose();
    }

    [Fact]
    public void Name_IsFishAudio()
    {
        Assert.Equal("Fish Audio", _provider.Name);
    }

    [Fact]
    public void IsAvailable_TrueWhenApiKeySet()
    {
        _config.FishAudioApiKey = "some-key";
        Assert.True(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyEmpty()
    {
        _config.FishAudioApiKey = "";
        Assert.False(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyWhitespace()
    {
        _config.FishAudioApiKey = "   ";
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
    public async Task SynthesizeAsync_InvalidApiKey_Throws()
    {
        _config.FishAudioApiKey = "invalid-key";
        // Throws HttpRequestException (401) or TaskCanceledException (timeout) depending on network
        await Assert.ThrowsAnyAsync<Exception>(
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
    public void DefaultBaseUrl_IsFishAudioApi()
    {
        Assert.Equal("https://api.fish.audio", _config.FishAudioBaseUrl);
    }

    [Fact]
    public void DefaultModelId_IsEmpty()
    {
        Assert.Equal("", _config.FishAudioModelId);
    }
}

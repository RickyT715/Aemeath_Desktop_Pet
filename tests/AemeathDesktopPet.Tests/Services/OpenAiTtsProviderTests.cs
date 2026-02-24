using System.Net.Http;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class OpenAiTtsProviderTests : IDisposable
{
    private readonly TtsConfig _config;
    private readonly OpenAiTtsProvider _provider;

    public OpenAiTtsProviderTests()
    {
        _config = new TtsConfig { OpenAiTtsApiKey = "test-key" };
        _provider = new OpenAiTtsProvider(() => _config);
    }

    public void Dispose()
    {
        _provider.Dispose();
    }

    [Fact]
    public void Name_IsOpenAiTts()
    {
        Assert.Equal("OpenAI TTS", _provider.Name);
    }

    [Fact]
    public void IsAvailable_TrueWhenApiKeySet()
    {
        _config.OpenAiTtsApiKey = "some-key";
        Assert.True(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyEmpty()
    {
        _config.OpenAiTtsApiKey = "";
        Assert.False(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyWhitespace()
    {
        _config.OpenAiTtsApiKey = "   ";
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
        _config.OpenAiTtsApiKey = "invalid-key";
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
    public void DefaultModel_IsTts1()
    {
        Assert.Equal("tts-1", _config.OpenAiTtsModel);
    }

    [Fact]
    public void DefaultVoice_IsAlloy()
    {
        Assert.Equal("alloy", _config.OpenAiTtsVoice);
    }

    [Fact]
    public void DefaultSpeed_IsOne()
    {
        Assert.Equal(1.0, _config.OpenAiTtsSpeed);
    }
}

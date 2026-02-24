using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class EdgeTtsProviderTests : IDisposable
{
    private readonly TtsConfig _config;
    private readonly EdgeTtsProvider _provider;

    public EdgeTtsProviderTests()
    {
        _config = new TtsConfig();
        _provider = new EdgeTtsProvider(() => _config);
    }

    public void Dispose()
    {
        _provider.Dispose();
    }

    [Fact]
    public void Name_IsEdgeTts()
    {
        Assert.Equal("Edge TTS", _provider.Name);
    }

    [Fact]
    public void IsAvailable_AlwaysTrue()
    {
        Assert.True(_provider.IsAvailable);
    }

    [Fact]
    public void IsAvailable_TrueRegardlessOfConfig()
    {
        _config.EdgeTtsVoice = "";
        Assert.True(_provider.IsAvailable);
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
    public void Dispose_CalledTwice_DoesNotThrow()
    {
        _provider.Dispose();
        _provider.Dispose();
    }

    [Fact]
    public void ImplementsITtsProvider()
    {
        Assert.IsAssignableFrom<ITtsProvider>(_provider);
    }

    [Fact]
    public void ImplementsIDisposable()
    {
        Assert.IsAssignableFrom<IDisposable>(_provider);
    }
}

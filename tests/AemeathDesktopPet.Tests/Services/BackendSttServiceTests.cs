using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class BackendSttServiceTests
{
    private static BackendProcessManager CreateOfflineBackend()
    {
        return new BackendProcessManager(new BackendConfig { Port = 19999 });
    }

    [Fact]
    public void IsAvailable_FalseWhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendSttService(backend);
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public async Task Transcribe_ReturnsEmpty_WhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendSttService(backend);
        var result = await service.TranscribeAsync(new byte[] { 1, 2, 3 }, "en");
        Assert.Empty(result);
    }

    [Fact]
    public async Task Transcribe_EmptyAudio_ReturnsEmpty_WhenNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendSttService(backend);
        var result = await service.TranscribeAsync(Array.Empty<byte>(), "en");
        Assert.Empty(result);
    }

    [Fact]
    public async Task Transcribe_DifferentLanguage_ReturnsEmpty_WhenNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendSttService(backend);
        var result = await service.TranscribeAsync(new byte[] { 1, 2, 3 }, "zh");
        Assert.Empty(result);
    }

    [Fact]
    public async Task Transcribe_DefaultLanguageIsEn()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendSttService(backend);
        // The default parameter is "en"; calling without specifying language should work
        var result = await service.TranscribeAsync(new byte[] { 1, 2, 3 });
        Assert.Empty(result);
    }

    [Fact]
    public void Constructor_DoesNotThrow()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendSttService(backend);
        Assert.NotNull(service);
    }

    [Fact]
    public async Task Transcribe_LargeAudio_ReturnsEmpty_WhenNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendSttService(backend);
        var largeAudio = new byte[10000];
        var result = await service.TranscribeAsync(largeAudio, "en");
        Assert.Empty(result);
    }

    [Fact]
    public async Task Transcribe_JapaneseLanguage_ReturnsEmpty_WhenNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendSttService(backend);
        var result = await service.TranscribeAsync(new byte[] { 1, 2, 3 }, "ja");
        Assert.Empty(result);
    }
}

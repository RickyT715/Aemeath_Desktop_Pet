using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class BackendVisionServiceTests
{
    private static BackendProcessManager CreateOfflineBackend()
    {
        return new BackendProcessManager(new BackendConfig { Port = 19999 });
    }

    [Fact]
    public void IsAvailable_FalseWhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendVisionService(backend);
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public async Task Analyze_ReturnsEmpty_WhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendVisionService(backend);
        var result = await service.AnalyzeAsync(new byte[] { 1, 2, 3 }, "What do you see?");
        Assert.Empty(result);
    }

    [Fact]
    public async Task Analyze_EmptyScreenshot_ReturnsEmpty_WhenNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendVisionService(backend);
        var result = await service.AnalyzeAsync(Array.Empty<byte>(), "Describe this");
        Assert.Empty(result);
    }

    [Fact]
    public async Task Analyze_EmptyPrompt_ReturnsEmpty_WhenNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendVisionService(backend);
        var result = await service.AnalyzeAsync(new byte[] { 1, 2, 3 }, "");
        Assert.Empty(result);
    }

    [Fact]
    public async Task Analyze_NullPrompt_ReturnsEmpty_WhenNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendVisionService(backend);
        var result = await service.AnalyzeAsync(new byte[] { 1, 2, 3 }, null!);
        Assert.Empty(result);
    }

    [Fact]
    public async Task Analyze_LargeScreenshot_ReturnsEmpty_WhenNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendVisionService(backend);
        var largeScreenshot = new byte[50000];
        var result = await service.AnalyzeAsync(largeScreenshot, "What do you see?");
        Assert.Empty(result);
    }

    [Fact]
    public void Constructor_DoesNotThrow()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendVisionService(backend);
        Assert.NotNull(service);
    }
}

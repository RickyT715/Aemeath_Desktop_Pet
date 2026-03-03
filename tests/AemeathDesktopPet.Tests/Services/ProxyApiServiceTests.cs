using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class ProxyApiServiceTests
{
    private static AppConfig ConfigWithUrl() => new() { ProxyBaseUrl = "http://localhost:42069" };
    private static AppConfig ConfigWithoutUrl() => new() { ProxyBaseUrl = "" };
    private static AppConfig ConfigWhitespaceUrl() => new() { ProxyBaseUrl = "   " };
    private static AemeathStats DefaultStats() => new();

    [Fact]
    public void IsAvailable_TrueWhenUrlSet()
    {
        var service = new ProxyApiService(() => ConfigWithUrl(), () => DefaultStats());
        Assert.True(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenUrlEmpty()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenUrlWhitespace()
    {
        var service = new ProxyApiService(() => ConfigWhitespaceUrl(), () => DefaultStats());
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_TrueWithDefaultConfig()
    {
        // Default AppConfig has ProxyBaseUrl = "http://localhost:42069"
        var service = new ProxyApiService(() => new AppConfig(), () => DefaultStats());
        Assert.True(service.IsAvailable);
    }

    [Fact]
    public async Task SendMessageAsync_ReturnsOfflineResponse_WhenUrlEmpty()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task SendMessageAsync_WithScreenshot_ReturnsOfflineResponse_WhenUrlEmpty()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        var screenshot = new byte[] { 1, 2, 3 };
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>(), screenshot);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessageAsync_YieldsOfflineResponse_WhenUrlEmpty()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync("Hello", new List<ChatMessage>()))
        {
            chunks.Add(chunk);
        }

        Assert.Single(chunks);
        Assert.False(string.IsNullOrEmpty(chunks[0]));
    }

    [Fact]
    public async Task StreamMessageAsync_WithScreenshot_YieldsOfflineResponse_WhenUrlEmpty()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync(
            "Hello", new List<ChatMessage>(), new byte[] { 1, 2, 3 }))
        {
            chunks.Add(chunk);
        }

        Assert.Single(chunks);
        Assert.False(string.IsNullOrEmpty(chunks[0]));
    }

    [Fact]
    public async Task SendMessageAsync_WithNullScreenshot_ReturnsOfflineResponse_WhenUrlEmpty()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>(), null);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessageAsync_WithNullScreenshot_YieldsOfflineResponse_WhenUrlEmpty()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync(
            "Hello", new List<ChatMessage>(), null))
        {
            chunks.Add(chunk);
        }

        Assert.Single(chunks);
        Assert.False(string.IsNullOrEmpty(chunks[0]));
    }

    [Fact]
    public void Constructor_DoesNotThrow()
    {
        var exception = Record.Exception(() =>
            new ProxyApiService(() => ConfigWithUrl(), () => DefaultStats()));
        Assert.Null(exception);
    }

    [Fact]
    public async Task SendMessageAsync_EmptyHistory_Accepted()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessageAsync_EmptyHistory_Accepted()
    {
        var service = new ProxyApiService(() => ConfigWithoutUrl(), () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync("Hello", new List<ChatMessage>()))
        {
            chunks.Add(chunk);
        }

        Assert.NotEmpty(chunks);
    }
}

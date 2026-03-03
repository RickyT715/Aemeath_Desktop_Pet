using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class GeminiApiServiceTests
{
    private static AppConfig ConfigWithoutKey() => new() { GeminiApiKey = "" };
    private static AppConfig ConfigWithKey() => new() { GeminiApiKey = "test-gemini-key" };
    private static AemeathStats DefaultStats() => new();

    [Fact]
    public void IsAvailable_FalseWhenNoApiKey()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_TrueWhenApiKeySet()
    {
        var service = new GeminiApiService(() => ConfigWithKey(), () => DefaultStats());
        Assert.True(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyWhitespace()
    {
        var config = new AppConfig { GeminiApiKey = "   " };
        var service = new GeminiApiService(() => config, () => DefaultStats());
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public async Task SendMessageAsync_ReturnsOfflineResponse_WhenNoApiKey()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task SendMessageAsync_WithScreenshot_ReturnsOfflineResponse_WhenNoApiKey()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
        var screenshot = new byte[] { 1, 2, 3 };
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>(), screenshot);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessageAsync_YieldsOfflineResponse_WhenNoApiKey()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync("Hello", new List<ChatMessage>()))
        {
            chunks.Add(chunk);
        }

        Assert.Single(chunks);
        Assert.False(string.IsNullOrEmpty(chunks[0]));
    }

    [Fact]
    public async Task StreamMessageAsync_WithScreenshot_YieldsOfflineResponse_WhenNoApiKey()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
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
    public async Task SendMessageAsync_WithNullScreenshot_ReturnsOfflineResponse_WhenNoApiKey()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>(), null);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessageAsync_WithNullScreenshot_YieldsOfflineResponse_WhenNoApiKey()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
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
    public async Task SendMessageAsync_WithInvalidKey_ReturnsOfflineResponse()
    {
        // Even with a key set, if the API call fails it should fall back
        var service = new GeminiApiService(() => ConfigWithKey(), () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task SendMessageAsync_EmptyHistory_Accepted()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessageAsync_EmptyHistory_Accepted()
    {
        var service = new GeminiApiService(() => ConfigWithoutKey(), () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync("Hello", new List<ChatMessage>()))
        {
            chunks.Add(chunk);
        }

        Assert.NotEmpty(chunks);
    }
}

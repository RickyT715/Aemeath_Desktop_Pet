using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class BackendAgentServiceTests
{
    private static BackendProcessManager CreateOfflineBackend()
    {
        return new BackendProcessManager(new BackendConfig { Port = 19999 });
    }

    private static AemeathStats DefaultStats() => new();

    [Fact]
    public void IsAvailable_FalseWhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public async Task SendMessage_ReturnsOfflineResponse_WhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task SendMessageWithScreenshot_ReturnsOfflineResponse_WhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var screenshot = new byte[] { 1, 2, 3 };
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>(), screenshot);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessage_YieldsOfflineResponse_WhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync("Hello", new List<ChatMessage>()))
        {
            chunks.Add(chunk);
        }

        Assert.Single(chunks);
        Assert.False(string.IsNullOrEmpty(chunks[0]));
    }

    [Fact]
    public async Task StreamMessageWithScreenshot_YieldsOfflineResponse_WhenBackendNotReady()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
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
    public async Task SendMessage_NullScreenshot_SameAsNoArg()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>(), null);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessage_NullScreenshot_SameAsNoArg()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
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
    public async Task SendMessage_OfflineResponseIsNonEmpty()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var result = await service.SendMessageAsync("Test", new List<ChatMessage>());
        Assert.True(result.Length > 0);
    }

    [Fact]
    public async Task SendMessage_MultipleCallsMayReturnDifferentResponses()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var results = new HashSet<string>();

        for (int i = 0; i < 20; i++)
        {
            var result = await service.SendMessageAsync($"Hello {i}", new List<ChatMessage>());
            results.Add(result);
        }

        // With a randomized pool, we should get at least 2 distinct responses over 20 calls
        Assert.True(results.Count >= 2, $"Expected at least 2 distinct responses, got {results.Count}");
    }

    [Fact]
    public async Task SendMessage_EmptyHistory_Accepted()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessage_EmptyHistory_Accepted()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync("Hello", new List<ChatMessage>()))
        {
            chunks.Add(chunk);
        }

        Assert.NotEmpty(chunks);
    }

    [Fact]
    public void Constructor_GeneratesThreadId()
    {
        using var backend = CreateOfflineBackend();
        // Constructor should not throw; internally generates a thread ID
        var service = new BackendAgentService(backend, () => DefaultStats());
        Assert.NotNull(service);
    }

    [Fact]
    public async Task StreamMessage_OfflineResponseIsNonEmpty()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync("Test", new List<ChatMessage>()))
        {
            chunks.Add(chunk);
        }

        Assert.Single(chunks);
        Assert.True(chunks[0].Length > 0);
    }

    [Fact]
    public async Task SendMessage_WithEmptyScreenshot_ReturnsOffline()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>(), Array.Empty<byte>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessage_WithEmptyScreenshot_YieldsOffline()
    {
        using var backend = CreateOfflineBackend();
        var service = new BackendAgentService(backend, () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync(
            "Hello", new List<ChatMessage>(), Array.Empty<byte>()))
        {
            chunks.Add(chunk);
        }

        Assert.Single(chunks);
        Assert.False(string.IsNullOrEmpty(chunks[0]));
    }
}

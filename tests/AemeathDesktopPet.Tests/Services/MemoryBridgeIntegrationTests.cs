using System.Net;
using System.Net.Http;
using System.Reflection;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

/// <summary>
/// Integration tests for MemoryBridgeService with mock HTTP.
/// Verifies correct HTTP calls, JSON payload format, and error handling.
/// Uses reflection to set BackendProcessManager.IsReady for testing.
/// </summary>
public class MemoryBridgeIntegrationTests : IDisposable
{
    private readonly string _tempDir;
    private readonly CoreMemoryService _coreMemory;
    private readonly ProceduralMemoryService _proceduralMemory;
    private readonly ObservationBufferService _observationBuffer;

    public MemoryBridgeIntegrationTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        Directory.CreateDirectory(_tempDir);
        _coreMemory = new CoreMemoryService(Path.Combine(_tempDir, "core"));
        _coreMemory.Load();
        _proceduralMemory = new ProceduralMemoryService(Path.Combine(_tempDir, "proc"));
        _proceduralMemory.Load();
        _observationBuffer = new ObservationBufferService(Path.Combine(_tempDir, "obs"));
        _observationBuffer.Load();
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    // --- Mock HTTP Infrastructure ---

    private class CapturingHttpHandler : HttpMessageHandler
    {
        public HttpRequestMessage? LastRequest { get; private set; }
        public string? LastRequestBody { get; private set; }
        public HttpStatusCode ResponseStatusCode { get; set; } = HttpStatusCode.OK;
        public string ResponseBody { get; set; } = "{}";
        public int CallCount { get; private set; }

        protected override async Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken ct)
        {
            LastRequest = request;
            CallCount++;
            if (request.Content != null)
                LastRequestBody = await request.Content.ReadAsStringAsync(ct);

            return new HttpResponseMessage(ResponseStatusCode)
            {
                Content = new StringContent(ResponseBody, Encoding.UTF8, "application/json")
            };
        }
    }

    private class FailingHttpHandler : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(
            HttpRequestMessage request, CancellationToken ct)
        {
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.InternalServerError)
            {
                Content = new StringContent("Internal Server Error")
            });
        }
    }

    /// <summary>
    /// Creates a BackendProcessManager with IsReady forced to true via reflection.
    /// This avoids launching an actual Python process during tests.
    /// </summary>
    private static BackendProcessManager CreateMockReadyBackend(int port = 18900)
    {
        var config = new BackendConfig { Port = port, Enabled = true };
        var backend = new BackendProcessManager(config);

        // Set IsReady via the compiler-generated backing field
        var backingField = typeof(BackendProcessManager)
            .GetField("<IsReady>k__BackingField",
                BindingFlags.NonPublic | BindingFlags.Instance);
        Assert.NotNull(backingField);
        backingField!.SetValue(backend, true);

        Assert.True(backend.IsReady);
        return backend;
    }

    // --- GetMemoryContextAsync with Backend Tests ---

    [Fact]
    public async Task WithBackend_RetrievesEpisodicMemories()
    {
        var handler = new CapturingHttpHandler
        {
            ResponseBody = """{"memories": [{"content": "User enjoys coding", "type": "fact", "created_at": "2026-03-01", "importance": 0.8}]}"""
        };

        var backend = CreateMockReadyBackend();
        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        var context = await service.GetMemoryContextAsync("Tell me about coding");

        Assert.Contains("User enjoys coding", context.RecentTopics);
    }

    [Fact]
    public async Task EmptyUserMessage_SkipsPythonRetrieval()
    {
        var handler = new CapturingHttpHandler();
        var backend = CreateMockReadyBackend();

        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        await service.GetMemoryContextAsync("   ");

        Assert.Equal(0, handler.CallCount);
    }

    [Fact]
    public async Task HttpFailure_UsesCachedEpisodic()
    {
        // First call succeeds and populates cache
        var handler = new CapturingHttpHandler
        {
            ResponseBody = """{"memories": [{"content": "Cached memory", "type": "fact", "created_at": "2026-03-01", "importance": 0.7}]}"""
        };

        var backend = CreateMockReadyBackend();
        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        var ctx1 = await service.GetMemoryContextAsync("test");
        Assert.Contains("Cached memory", ctx1.RecentTopics);

        // Second call fails -- should fall back to cached results
        handler.ResponseStatusCode = HttpStatusCode.InternalServerError;
        var ctx2 = await service.GetMemoryContextAsync("test again");

        Assert.Contains("Cached memory", ctx2.RecentTopics);
    }

    // --- SubmitForExtraction Tests ---

    [Fact]
    public async Task SubmitForExtraction_SendsCorrectJsonPayload()
    {
        var handler = new CapturingHttpHandler();
        var backend = CreateMockReadyBackend();

        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        await service.SubmitForExtraction("Hello user", "Hi from Aemeath!");

        Assert.NotNull(handler.LastRequestBody);
        Assert.Contains("\"user_message\"", handler.LastRequestBody);
        Assert.Contains("\"assistant_response\"", handler.LastRequestBody);
        Assert.DoesNotContain("\"userMessage\"", handler.LastRequestBody);
    }

    [Fact]
    public async Task SubmitForExtraction_PostsToCorrectEndpoint()
    {
        var handler = new CapturingHttpHandler();
        var backend = CreateMockReadyBackend();

        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        await service.SubmitForExtraction("msg", "reply");

        Assert.NotNull(handler.LastRequest);
        Assert.Contains("/memory/extract", handler.LastRequest!.RequestUri!.ToString());
    }

    [Fact]
    public async Task SubmitForExtraction_HttpFailure_DoesNotThrow()
    {
        var handler = new FailingHttpHandler();
        var backend = CreateMockReadyBackend();

        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);

        // Should not throw even when the HTTP call returns 500
        await service.SubmitForExtraction("msg", "reply");
    }

    // --- SubmitObservationsAsync Tests ---

    [Fact]
    public async Task SubmitObservations_SendsCorrectPayload()
    {
        var handler = new CapturingHttpHandler();
        var backend = CreateMockReadyBackend();

        _observationBuffer.AddObservation("screen", "VS Code open", "StudyingCoding");

        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        await service.SubmitObservationsAsync();

        Assert.NotNull(handler.LastRequestBody);
        Assert.Contains("\"activity_context\"", handler.LastRequestBody);
        Assert.DoesNotContain("\"activityContext\"", handler.LastRequestBody);
    }

    [Fact]
    public async Task SubmitObservations_Success_ClearsBuffer()
    {
        var handler = new CapturingHttpHandler();
        var backend = CreateMockReadyBackend();

        _observationBuffer.AddObservation("screen", "test", "Default");
        Assert.Equal(1, _observationBuffer.Count);

        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        await service.SubmitObservationsAsync();

        Assert.Equal(0, _observationBuffer.Count);
    }

    [Fact]
    public async Task SubmitObservations_Failure_RetainsBuffer()
    {
        var handler = new FailingHttpHandler();
        var backend = CreateMockReadyBackend();

        _observationBuffer.AddObservation("screen", "test", "Default");

        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        await service.SubmitObservationsAsync();

        Assert.Equal(1, _observationBuffer.Count);
    }

    [Fact]
    public async Task SubmitObservations_PostsToCorrectEndpoint()
    {
        var handler = new CapturingHttpHandler();
        var backend = CreateMockReadyBackend();

        _observationBuffer.AddObservation("screen", "test", "Default");

        var service = new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, handler);
        await service.SubmitObservationsAsync();

        Assert.NotNull(handler.LastRequest);
        Assert.Contains("/memory/distill", handler.LastRequest!.RequestUri!.ToString());
    }
}

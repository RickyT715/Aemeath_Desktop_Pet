using System.Net.Http;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class MemoryBridgeServiceTests : IDisposable
{
    private readonly string _tempDir;
    private readonly CoreMemoryService _coreMemory;
    private readonly ProceduralMemoryService _proceduralMemory;
    private readonly ObservationBufferService _observationBuffer;

    public MemoryBridgeServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        Directory.CreateDirectory(_tempDir);

        _coreMemory = new CoreMemoryService(Path.Combine(_tempDir, "core"));
        _proceduralMemory = new ProceduralMemoryService(Path.Combine(_tempDir, "procedural"));
        _observationBuffer = new ObservationBufferService(Path.Combine(_tempDir, "buffer"));
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    private MemoryBridgeService CreateService(BackendProcessManager? backend = null, HttpMessageHandler? httpHandler = null)
    {
        return new MemoryBridgeService(_coreMemory, _proceduralMemory, _observationBuffer, backend, httpHandler);
    }

    // ---- GetMemoryContextAsync — local-only mode (no Python backend) ----

    [Fact]
    public async Task GetMemoryContextAsync_AssemblesContext_FromCoreMemory()
    {
        var core = _coreMemory.Load();
        core.UserProfile.Name = "Ricky";
        core.UserProfile.Occupation = "CS student";
        core.UserProfile.AgeRange = "20-25";
        core.UserProfile.Languages.Add("English");
        core.UserProfile.KeyFacts.Add("Plays piano");
        core.Personality.Interests.Add("Gaming");
        core.Personality.CommunicationStyle = "Casual";
        core.Relationship.Stage = "familiar";
        core.Relationship.DaysTogether = 45;
        _coreMemory.Save(core);
        _coreMemory.Load(); // Reload to ensure cache is updated

        var service = CreateService();
        var context = await service.GetMemoryContextAsync("Hello");

        Assert.Equal("Ricky", context.UserName);
        Assert.Equal("Casual", context.CommunicationStyle);
        Assert.Equal("familiar", context.RelationshipStage);
        Assert.Equal(45, context.DaysTogether);
        Assert.Contains("Occupation: CS student", context.UserFacts);
        Assert.Contains("Age range: 20-25", context.UserFacts);
        Assert.Contains("Languages: English", context.UserFacts);
        Assert.Contains("Plays piano", context.UserFacts);
        Assert.Contains("Gaming", context.Preferences);
    }

    [Fact]
    public async Task GetMemoryContextAsync_IncludesUpcomingEvents()
    {
        var mem = new ProceduralMemory();
        var tomorrow = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");
        mem.ScheduledEvents.Add(new ScheduledEvent
        {
            Id = "exam",
            Event = "Calculus exam",
            Date = tomorrow,
            FollowUp = "Ask about prep"
        });
        _proceduralMemory.Save(mem);
        _proceduralMemory.Load();

        var service = CreateService();
        var context = await service.GetMemoryContextAsync("How's studying?");

        Assert.Single(context.UpcomingEvents);
        Assert.Contains("Calculus exam", context.UpcomingEvents[0]);
        Assert.Contains("(tomorrow)", context.UpcomingEvents[0]);
    }

    [Fact]
    public async Task GetMemoryContextAsync_IncludesObservations()
    {
        _observationBuffer.Load();
        _observationBuffer.AddObservation("screen", "VS Code open", "StudyingCoding");
        _observationBuffer.AddObservation("activity", "Chrome on Stack Overflow", "StudyingCoding");

        var service = CreateService();
        var context = await service.GetMemoryContextAsync("What am I doing?");

        Assert.Equal(2, context.Observations.Count);
        Assert.Contains(context.Observations, o => o.Contains("VS Code open"));
        Assert.Contains(context.Observations, o => o.Contains("Stack Overflow"));
    }

    [Fact]
    public async Task GetMemoryContextAsync_ObservationsLimitedTo5()
    {
        _observationBuffer.Load();
        for (int i = 1; i <= 8; i++)
            _observationBuffer.AddObservation("screen", $"Observation {i}", "Default");

        var service = CreateService();
        var context = await service.GetMemoryContextAsync("test");

        Assert.Equal(5, context.Observations.Count);
    }

    [Fact]
    public async Task GetMemoryContextAsync_EmptyMemory_ReturnsValidContext()
    {
        _coreMemory.Load();
        _proceduralMemory.Load();
        _observationBuffer.Load();

        var service = CreateService();
        var context = await service.GetMemoryContextAsync("Hello");

        Assert.NotNull(context);
        Assert.Null(context.UserName);
        Assert.Empty(context.UpcomingEvents);
        Assert.Empty(context.Observations);
        Assert.Empty(context.RecentTopics);
    }

    // ---- Graceful degradation when Python unavailable ----

    [Fact]
    public async Task GetMemoryContextAsync_NullBackend_StillReturnsLocalContext()
    {
        var core = _coreMemory.Load();
        core.UserProfile.Name = "TestUser";
        _coreMemory.Save(core);
        _coreMemory.Load();

        var service = CreateService(backend: null);
        var context = await service.GetMemoryContextAsync("test");

        Assert.Equal("TestUser", context.UserName);
        Assert.Empty(context.RecentTopics); // No episodic memories without Python
    }

    // ---- SubmitForExtraction ----

    [Fact]
    public async Task SubmitForExtraction_NullBackend_DoesNotThrow()
    {
        var service = CreateService(backend: null);

        // Should be a no-op when backend is null
        await service.SubmitForExtraction("Hello", "Hi there!");
        // No exception should occur
    }

    // ---- SubmitObservationsAsync ----

    [Fact]
    public async Task SubmitObservationsAsync_NullBackend_DoesNotThrow()
    {
        _observationBuffer.Load();
        _observationBuffer.AddObservation("screen", "test", "Default");

        var service = CreateService(backend: null);
        await service.SubmitObservationsAsync();

        // Observations should still be in buffer (not cleared since Python not available)
        Assert.Equal(1, _observationBuffer.Count);
    }

    [Fact]
    public async Task SubmitObservationsAsync_EmptyBuffer_DoesNothing()
    {
        _observationBuffer.Load();

        var service = CreateService(backend: null);
        await service.SubmitObservationsAsync();
        // No exception
    }

    // ---- ReloadLocalMemory ----

    [Fact]
    public void ReloadLocalMemory_ReloadsFromDisk()
    {
        // Initial load
        var core = _coreMemory.Load();
        _proceduralMemory.Load();

        var service = CreateService();

        // Modify core memory file directly
        core.UserProfile.Name = "Updated";
        _coreMemory.Save(core);

        // Before reload, the service's core still has cached version
        service.ReloadLocalMemory();

        // After reload, the updated name should be available
        Assert.Equal("Updated", _coreMemory.Current.UserProfile.Name);
    }
}

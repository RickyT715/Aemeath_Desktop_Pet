using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

/// <summary>
/// End-to-end tests for the memory system lifecycle.
/// Tests full flows with real services and mock HTTP, verifying
/// the complete path from memory storage through prompt injection.
/// </summary>
public class MemoryE2ETests : IDisposable
{
    private readonly string _tempDir;

    public MemoryE2ETests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        Directory.CreateDirectory(_tempDir);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    [Fact]
    public async Task FullLifecycle_MessageToPromptInjection()
    {
        // 1. Setup services with populated memory
        var coreMemory = new CoreMemoryService(Path.Combine(_tempDir, "core"));
        var core = coreMemory.Load();
        core.UserProfile.Name = "TestUser";
        core.UserProfile.Occupation = "Developer";
        core.Personality.Interests.Add("Gaming");
        core.Personality.CommunicationStyle = "Casual";
        core.Relationship.Stage = "familiar";
        core.Relationship.DaysTogether = 30;
        coreMemory.Save(core);
        coreMemory.Load();

        var procMemory = new ProceduralMemoryService(Path.Combine(_tempDir, "proc"));
        var procMem = new ProceduralMemory();
        var tomorrow = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");
        procMem.ScheduledEvents.Add(new ScheduledEvent
        {
            Id = "exam",
            Event = "Math exam",
            Date = tomorrow,
            FollowUp = "Ask how it went"
        });
        procMemory.Save(procMem);
        procMemory.Load();

        var obsBuffer = new ObservationBufferService(Path.Combine(_tempDir, "obs"));
        obsBuffer.Load();
        obsBuffer.AddObservation("screen", "VS Code editing", "StudyingCoding");

        // 2. Create bridge (no backend -- local only)
        var bridge = new MemoryBridgeService(coreMemory, procMemory, obsBuffer, null);

        // 3. Get memory context
        var context = await bridge.GetMemoryContextAsync("How's studying?");

        // 4. Verify all local memory is assembled
        Assert.Equal("TestUser", context.UserName);
        Assert.Contains("Occupation: Developer", context.UserFacts);
        Assert.Contains("Gaming", context.Preferences);
        Assert.Equal("Casual", context.CommunicationStyle);
        Assert.Equal("familiar", context.RelationshipStage);
        Assert.Equal(30, context.DaysTogether);
        Assert.Single(context.UpcomingEvents);
        Assert.Contains("Math exam", context.UpcomingEvents[0]);
        Assert.Single(context.Observations);
        Assert.Contains("VS Code editing", context.Observations[0]);

        // 5. Inject into ChatPromptBuilder and verify end-to-end prompt content
        var stats = new AemeathStats { Mood = 80, Energy = 70, Affection = 60 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro", context);

        Assert.Contains("TestUser", prompt);
        Assert.Contains("Occupation: Developer", prompt);
        Assert.Contains("Gaming", prompt);
        Assert.Contains("Math exam", prompt);
        Assert.Contains("VS Code editing", prompt);
    }

    [Fact]
    public async Task ObservationDistillationLifecycle_BufferToClear()
    {
        // Test the observation buffer lifecycle: add -> get pending -> manual clear
        var obsBuffer = new ObservationBufferService(Path.Combine(_tempDir, "obs2"));
        obsBuffer.Load();
        obsBuffer.AddObservation("screen", "Chrome on Reddit", "Default");
        obsBuffer.AddObservation("activity", "Switched to Discord", "Default");
        Assert.Equal(2, obsBuffer.Count);

        // Without backend, SubmitObservationsAsync is a no-op
        var coreMemory = new CoreMemoryService(Path.Combine(_tempDir, "core2"));
        coreMemory.Load();
        var procMemory = new ProceduralMemoryService(Path.Combine(_tempDir, "proc2"));
        procMemory.Load();

        var bridge = new MemoryBridgeService(coreMemory, procMemory, obsBuffer, null);
        await bridge.SubmitObservationsAsync();

        // Buffer NOT cleared (no backend available)
        Assert.Equal(2, obsBuffer.Count);

        // Manual clear simulating what happens after successful distillation
        var pending = obsBuffer.GetPending();
        obsBuffer.ClearProcessed(pending.Select(o => o.Id).ToList());
        Assert.Equal(0, obsBuffer.Count);
    }

    [Fact]
    public async Task GracefulDegradation_NoPython_StillAssemblesLocalContext()
    {
        var coreMemory = new CoreMemoryService(Path.Combine(_tempDir, "core3"));
        var core = coreMemory.Load();
        core.UserProfile.Name = "Ricky";
        coreMemory.Save(core);
        coreMemory.Load();

        var procMemory = new ProceduralMemoryService(Path.Combine(_tempDir, "proc3"));
        procMemory.Load();
        var obsBuffer = new ObservationBufferService(Path.Combine(_tempDir, "obs3"));
        obsBuffer.Load();

        // No backend at all -- should still work with local memory only
        var bridge = new MemoryBridgeService(coreMemory, procMemory, obsBuffer, null);
        var context = await bridge.GetMemoryContextAsync("Hello!");

        Assert.Equal("Ricky", context.UserName);
        Assert.Empty(context.RecentTopics); // No episodic memories without Python
    }

    [Fact]
    public void ReloadLocalMemory_PicksUpExternalChanges()
    {
        var coreMemory = new CoreMemoryService(Path.Combine(_tempDir, "core4"));
        var core = coreMemory.Load();
        core.UserProfile.Name = "Original";
        coreMemory.Save(core);

        var procMemory = new ProceduralMemoryService(Path.Combine(_tempDir, "proc4"));
        procMemory.Load();
        var obsBuffer = new ObservationBufferService(Path.Combine(_tempDir, "obs4"));
        obsBuffer.Load();

        var bridge = new MemoryBridgeService(coreMemory, procMemory, obsBuffer, null);

        // Externally modify the file (simulating Python backend updating it)
        core.UserProfile.Name = "Modified";
        coreMemory.Save(core);

        // Reload should pick up the external changes
        bridge.ReloadLocalMemory();

        Assert.Equal("Modified", coreMemory.Current.UserProfile.Name);
    }
}

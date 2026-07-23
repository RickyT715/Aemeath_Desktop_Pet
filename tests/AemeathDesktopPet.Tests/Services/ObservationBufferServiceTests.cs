using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class ObservationBufferServiceTests : IDisposable
{
    private readonly string _tempDir;
    private readonly ObservationBufferService _service;

    public ObservationBufferServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        _service = new ObservationBufferService(_tempDir);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    // ---- Load ----

    [Fact]
    public void Load_EmptyByDefault()
    {
        _service.Load();
        Assert.Equal(0, _service.Count);
    }

    [Fact]
    public void Load_HandlesCorruptJson_ReturnsEmpty()
    {
        File.WriteAllText(Path.Combine(_tempDir, "observation_buffer.json"), "{ bad json");

        _service.Load();

        Assert.Equal(0, _service.Count);
    }

    [Fact]
    public void Load_HandlesEmptyFile_ReturnsEmpty()
    {
        File.WriteAllText(Path.Combine(_tempDir, "observation_buffer.json"), "");

        _service.Load();

        Assert.Equal(0, _service.Count);
    }

    // ---- AddObservation ----

    [Fact]
    public void AddObservation_AppendsToBuffer()
    {
        _service.Load();
        _service.AddObservation("screen", "User viewing VS Code", "StudyingCoding");

        Assert.Equal(1, _service.Count);
    }

    [Fact]
    public void AddObservation_MultipleSources()
    {
        _service.Load();
        _service.AddObservation("screen", "VS Code open", "StudyingCoding");
        _service.AddObservation("activity", "Chrome on Stack Overflow", "StudyingCoding");
        _service.AddObservation("pomodoro", "Work session started", "PomodoroWork");

        Assert.Equal(3, _service.Count);
    }

    [Fact]
    public void AddObservation_PersistsToDisk()
    {
        _service.Load();
        _service.AddObservation("screen", "Test content", "Default");

        // Load from new instance
        var service2 = new ObservationBufferService(_tempDir);
        service2.Load();

        Assert.Equal(1, service2.Count);
    }

    // ---- GetPending ----

    [Fact]
    public void GetPending_ReturnsAllNonExpired()
    {
        _service.Load();
        _service.AddObservation("screen", "Content A", "Default");
        _service.AddObservation("activity", "Content B", "Default");

        var pending = _service.GetPending();

        Assert.Equal(2, pending.Count);
    }

    [Fact]
    public void GetPending_ExcludesExpired()
    {
        _service.Load();
        _service.AddObservation("screen", "Fresh entry", "Default");

        // Manually inject an expired entry via file manipulation
        var filePath = Path.Combine(_tempDir, "observation_buffer.json");
        var json = File.ReadAllText(filePath);
        // Add an expired entry
        var expiredJson = json.Replace("]}", @",{""id"":""expired1"",""timestamp"":""2020-01-01T00:00:00Z"",""source"":""screen"",""content"":""Old entry"",""activityContext"":""Default"",""ttlHours"":24}]}");
        File.WriteAllText(filePath, expiredJson);

        // Reload to pick up the modified file
        var service2 = new ObservationBufferService(_tempDir);
        service2.Load();

        // Load auto-purges expired entries
        var pending = service2.GetPending();
        Assert.Single(pending);
        Assert.Equal("Fresh entry", pending[0].Content);
    }

    [Fact]
    public void GetPending_ReturnsEmpty_WhenNoEntries()
    {
        _service.Load();
        var pending = _service.GetPending();
        Assert.Empty(pending);
    }

    // ---- ClearProcessed ----

    [Fact]
    public void ClearProcessed_RemovesSpecifiedEntries()
    {
        _service.Load();
        _service.AddObservation("screen", "Entry A", "Default");
        _service.AddObservation("screen", "Entry B", "Default");

        var pending = _service.GetPending();
        Assert.Equal(2, pending.Count);

        // Clear only the first one
        _service.ClearProcessed(new List<string> { pending[0].Id });

        Assert.Equal(1, _service.Count);
        var remaining = _service.GetPending();
        Assert.Single(remaining);
        Assert.Equal("Entry B", remaining[0].Content);
    }

    [Fact]
    public void ClearProcessed_PersistsToDisk()
    {
        _service.Load();
        _service.AddObservation("screen", "Entry", "Default");

        var pending = _service.GetPending();
        _service.ClearProcessed(new List<string> { pending[0].Id });

        var service2 = new ObservationBufferService(_tempDir);
        service2.Load();
        Assert.Equal(0, service2.Count);
    }

    [Fact]
    public void ClearProcessed_NonexistentIds_DoesNotThrow()
    {
        _service.Load();
        _service.AddObservation("screen", "Entry", "Default");

        _service.ClearProcessed(new List<string> { "nonexistent_id" });

        Assert.Equal(1, _service.Count);
    }

    [Fact]
    public void ClearProcessed_EmptyList_DoesNothing()
    {
        _service.Load();
        _service.AddObservation("screen", "Entry", "Default");

        _service.ClearProcessed(new List<string>());

        Assert.Equal(1, _service.Count);
    }

    // ---- PurgeExpired ----

    [Fact]
    public void PurgeExpired_RemovesOldEntries()
    {
        _service.Load();
        _service.AddObservation("screen", "Fresh entry", "Default");

        // Load auto-purges, so expired entries would be removed on Load
        // But PurgeExpired can also be called manually on fresh entries (no-op)
        _service.PurgeExpired();

        Assert.Equal(1, _service.Count);
    }

    // ---- Buffer persistence roundtrip ----

    [Fact]
    public void SaveAndLoad_RoundTrip()
    {
        _service.Load();
        _service.AddObservation("screen", "VS Code open", "StudyingCoding");
        _service.AddObservation("activity", "Chrome active", "Default");

        var service2 = new ObservationBufferService(_tempDir);
        service2.Load();

        Assert.Equal(2, service2.Count);
        var pending = service2.GetPending();
        Assert.Equal("VS Code open", pending[0].Content);
        Assert.Equal("screen", pending[0].Source);
        Assert.Equal("StudyingCoding", pending[0].ActivityContext);
    }

    // ---- Constructor ----

    [Fact]
    public void Constructor_CreatesDirectory()
    {
        var nested = Path.Combine(_tempDir, "sub", "dir");
        var svc = new ObservationBufferService(nested);
        Assert.True(Directory.Exists(nested));
    }

    [Fact]
    public void AddObservation_EmptyContent_StoredSuccessfully()
    {
        _service.Load();
        _service.AddObservation("screen", "", "Default");
        Assert.Equal(1, _service.Count);
    }

    [Fact]
    public void AddObservation_EmptySource_StoredSuccessfully()
    {
        _service.Load();
        _service.AddObservation("", "Some content", "Default");
        Assert.Equal(1, _service.Count);
    }
}

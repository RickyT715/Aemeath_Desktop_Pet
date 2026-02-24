using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class JsonPersistenceServiceTests : IDisposable
{
    private readonly string _tempDir;
    private readonly JsonPersistenceService _service;

    public JsonPersistenceServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        _service = new JsonPersistenceService(_tempDir);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    [Fact]
    public void SaveAndLoadStats_RoundTrip()
    {
        var stats = new AemeathStats { Mood = 85, Energy = 60, Affection = 75, TotalChats = 42 };
        _service.SaveStats(stats);

        var loaded = _service.LoadStats();
        Assert.NotNull(loaded);
        Assert.Equal(85, loaded!.Mood);
        Assert.Equal(60, loaded.Energy);
        Assert.Equal(75, loaded.Affection);
        Assert.Equal(42, loaded.TotalChats);
    }

    [Fact]
    public void LoadStats_NoFile_ReturnsNull()
    {
        var result = _service.LoadStats();
        Assert.Null(result);
    }

    [Fact]
    public void SaveAndLoadMessages_RoundTrip()
    {
        var messages = new List<ChatMessage>
        {
            new("user", "Hello"),
            new("assistant", "Hi there!"),
        };
        _service.SaveMessages(messages);

        var loaded = _service.LoadMessages();
        Assert.NotNull(loaded);
        Assert.Equal(2, loaded!.Count);
        Assert.Equal("Hello", loaded[0].Content);
        Assert.Equal("assistant", loaded[1].Role);
    }

    [Fact]
    public void LoadMessages_NoFile_ReturnsNull()
    {
        var result = _service.LoadMessages();
        Assert.Null(result);
    }

    [Fact]
    public void CreatesDirectory()
    {
        Assert.True(Directory.Exists(_tempDir));
    }
}

using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class MemoryServiceTests : IDisposable
{
    private readonly string _tempDir;
    private readonly JsonPersistenceService _persistence;
    private readonly MemoryService _service;

    public MemoryServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        _persistence = new JsonPersistenceService(_tempDir);
        _service = new MemoryService(_persistence);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    [Fact]
    public void Load_EmptyByDefault()
    {
        _service.Load();
        Assert.Empty(_service.Messages);
    }

    [Fact]
    public void AddMessage_StoresMessage()
    {
        _service.Load();
        _service.AddMessage(new ChatMessage("user", "Hello"));
        Assert.Single(_service.Messages);
    }

    [Fact]
    public void Save_PersistsMessages()
    {
        _service.Load();
        _service.AddMessage(new ChatMessage("user", "Hello"));
        _service.Save();

        var loaded = _persistence.LoadMessages();
        Assert.NotNull(loaded);
        Assert.Single(loaded!);
        Assert.Equal("Hello", loaded[0].Content);
    }

    [Fact]
    public void GetContextWindow_ReturnsRecentMessages()
    {
        _service.Load();
        for (int i = 0; i < 30; i++)
            _service.AddMessage(new ChatMessage("user", $"Message {i}"));

        var context = _service.GetContextWindow(10);
        Assert.Equal(10, context.Count);
        Assert.Equal("Message 20", context[0].Content);
        Assert.Equal("Message 29", context[9].Content);
    }

    [Fact]
    public void GetContextWindow_ReturnsAll_WhenFewerThanMax()
    {
        _service.Load();
        _service.AddMessage(new ChatMessage("user", "Only one"));

        var context = _service.GetContextWindow(20);
        Assert.Single(context);
    }

    [Fact]
    public void AddMessage_TrimsOldMessages_Over200()
    {
        _service.Load();
        for (int i = 0; i < 210; i++)
            _service.AddMessage(new ChatMessage("user", $"Msg {i}"));

        Assert.True(_service.Messages.Count <= 200);
    }

    [Fact]
    public void Clear_RemovesAllMessages()
    {
        _service.Load();
        _service.AddMessage(new ChatMessage("user", "test"));
        _service.Clear();
        Assert.Empty(_service.Messages);
    }
}

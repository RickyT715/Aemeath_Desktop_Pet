using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class StatsServiceTests : IDisposable
{
    private readonly string _tempDir;
    private readonly JsonPersistenceService _persistence;
    private readonly StatsService _service;

    public StatsServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        _persistence = new JsonPersistenceService(_tempDir);
        _service = new StatsService(_persistence);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    [Fact]
    public void Load_CreatesDefaultStats_WhenNoFile()
    {
        _service.Load();
        Assert.NotNull(_service.Stats);
        Assert.Equal(70, _service.Stats.Mood);
    }

    [Fact]
    public void Save_PersistsStats()
    {
        _service.Load();
        _service.Stats.Mood = 50;
        _service.Save();

        var loaded = _persistence.LoadStats();
        Assert.NotNull(loaded);
        Assert.Equal(50, loaded!.Mood);
    }

    [Fact]
    public void OnChatted_IncreasesStatAndCounter()
    {
        _service.Load();
        double initialMood = _service.Stats.Mood;

        _service.OnChatted();

        Assert.True(_service.Stats.Mood > initialMood);
        Assert.Equal(1, _service.Stats.TotalChats);
    }

    [Fact]
    public void OnPetted_IncreasesStatAndCounter()
    {
        _service.Load();
        double initialMood = _service.Stats.Mood;

        _service.OnPetted();

        Assert.True(_service.Stats.Mood > initialMood);
        Assert.Equal(1, _service.Stats.TotalPets);
    }

    [Fact]
    public void OnSang_IncreasesCounterAndMood_DecreasesEnergy()
    {
        _service.Load();
        double initialEnergy = _service.Stats.Energy;
        double initialMood = _service.Stats.Mood;

        _service.OnSang();

        Assert.Equal(1, _service.Stats.TotalSongs);
        Assert.True(_service.Stats.Mood > initialMood);
        Assert.True(_service.Stats.Energy < initialEnergy);
    }

    [Fact]
    public void OnPaperPlaneThrown_IncreasesCounter()
    {
        _service.Load();
        _service.OnPaperPlaneThrown();
        Assert.Equal(1, _service.Stats.TotalPaperPlanes);
    }

    [Fact]
    public void StatsChanged_FiresOnInteraction()
    {
        _service.Load();
        bool fired = false;
        _service.StatsChanged += () => fired = true;

        _service.OnChatted();

        Assert.True(fired);
    }
}

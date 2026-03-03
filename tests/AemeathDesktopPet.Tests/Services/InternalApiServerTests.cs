using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class InternalApiServerTests
{
    private static StatsService CreateStatsService()
    {
        var persistence = new JsonPersistenceService();
        return new StatsService(persistence);
    }

    private static MusicService CreateMusicService() => new();

    private static BehaviorEngine CreateBehavior() => new();

    [Fact]
    public void Constructor_DoesNotThrow()
    {
        var server = new InternalApiServer(
            18901,
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
        server.Dispose();
    }

    [Fact]
    public void Dispose_CanBeCalledMultipleTimes()
    {
        var server = new InternalApiServer(
            18901,
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
        server.Dispose();
        server.Dispose(); // Should not throw
    }

    [Fact]
    public void Dispose_StopsWithoutStarting()
    {
        // Creating and disposing without starting should not throw
        using var server = new InternalApiServer(
            0, // Port 0 — never actually starts
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
    }

    [Fact]
    public void Constructor_NullPomodoro_Accepted()
    {
        using var server = new InternalApiServer(
            18901,
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
        Assert.NotNull(server);
    }

    [Fact]
    public void Constructor_Port0_Accepted()
    {
        using var server = new InternalApiServer(
            0,
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
        Assert.NotNull(server);
    }

    [Fact]
    public void Constructor_HighPort_Accepted()
    {
        using var server = new InternalApiServer(
            65535,
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
        Assert.NotNull(server);
    }

    [Fact]
    public void Constructor_CustomPort_Accepted()
    {
        using var server = new InternalApiServer(
            12345,
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
        Assert.NotNull(server);
    }

    [Fact]
    public void Constructor_AllDependencies_StoredWithoutError()
    {
        var stats = CreateStatsService();
        var music = CreateMusicService();
        var behavior = CreateBehavior();

        using var server = new InternalApiServer(
            18901,
            stats,
            music,
            behavior,
            null);
        Assert.NotNull(server);
    }

    [Fact]
    public void Constructor_DefaultPort18901_Accepted()
    {
        using var server = new InternalApiServer(
            18901,
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
        // Should construct without issues
        Assert.NotNull(server);
    }

    [Fact]
    public void Dispose_AfterMultipleDispose_NoThrow()
    {
        var server = new InternalApiServer(
            18901,
            CreateStatsService(),
            CreateMusicService(),
            CreateBehavior(),
            null);
        server.Dispose();
        server.Dispose();
        server.Dispose(); // Third call also safe
    }
}

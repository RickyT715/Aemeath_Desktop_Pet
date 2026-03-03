using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class BackendProcessManagerTests
{
    private static BackendConfig DefaultConfig() => new();

    [Fact]
    public void Constructor_SetsPortFromConfig()
    {
        var config = new BackendConfig { Port = 12345 };
        using var manager = new BackendProcessManager(config);
        Assert.Equal(12345, manager.Port);
    }

    [Fact]
    public void IsReady_DefaultsFalse()
    {
        using var manager = new BackendProcessManager(DefaultConfig());
        Assert.False(manager.IsReady);
    }

    [Fact]
    public void LastError_DefaultsNull()
    {
        using var manager = new BackendProcessManager(DefaultConfig());
        Assert.Null(manager.LastError);
    }

    [Fact]
    public void Dispose_CanBeCalledMultipleTimes()
    {
        var manager = new BackendProcessManager(DefaultConfig());
        manager.Dispose();
        manager.Dispose(); // Should not throw
    }

    [Fact]
    public async Task StopAsync_WhenNotStarted_DoesNotThrow()
    {
        using var manager = new BackendProcessManager(DefaultConfig());
        await manager.StopAsync(); // Should not throw
    }

    [Fact]
    public void BackendReady_EventCanBeSubscribed()
    {
        using var manager = new BackendProcessManager(DefaultConfig());
        bool fired = false;
        manager.BackendReady += (_, _) => fired = true;
        // Event not fired until backend actually starts
        Assert.False(fired);
    }

    [Fact]
    public void BackendCrashed_EventCanBeSubscribed()
    {
        using var manager = new BackendProcessManager(DefaultConfig());
        string? errorMessage = null;
        manager.BackendCrashed += (_, msg) => errorMessage = msg;
        // Event not fired until backend actually crashes
        Assert.Null(errorMessage);
    }

    [Fact]
    public void DefaultConfig_UsesPort18900()
    {
        var config = new BackendConfig();
        Assert.Equal(18900, config.Port);
    }

    [Fact]
    public void CustomConfig_AllFieldsSet()
    {
        var config = new BackendConfig
        {
            Enabled = false,
            Mode = "dev",
            Port = 9999,
            InternalPort = 9998,
            PythonPath = "/usr/bin/python3",
            TavilyApiKey = "tavily-key",
            OpenWeatherMapApiKey = "owm-key",
            MaxRetries = 5
        };
        Assert.False(config.Enabled);
        Assert.Equal("dev", config.Mode);
        Assert.Equal(9999, config.Port);
        Assert.Equal(9998, config.InternalPort);
        Assert.Equal("/usr/bin/python3", config.PythonPath);
        Assert.Equal("tavily-key", config.TavilyApiKey);
        Assert.Equal("owm-key", config.OpenWeatherMapApiKey);
        Assert.Equal(5, config.MaxRetries);
    }

    [Fact]
    public void Port_MatchesConfig()
    {
        var config = new BackendConfig { Port = 55555 };
        using var manager = new BackendProcessManager(config);
        Assert.Equal(55555, manager.Port);
    }

    [Fact]
    public async Task StopAsync_SetsIsReadyFalse()
    {
        using var manager = new BackendProcessManager(DefaultConfig());
        await manager.StopAsync();
        Assert.False(manager.IsReady);
    }

    [Fact]
    public async Task Dispose_AfterStopAsync_Safe()
    {
        var manager = new BackendProcessManager(DefaultConfig());
        await manager.StopAsync();
        manager.Dispose(); // Should not throw
    }

    [Fact]
    public void BackendConfig_ModeDefault_IsAuto()
    {
        var config = new BackendConfig();
        Assert.Equal("auto", config.Mode);
    }

    [Fact]
    public void BackendConfig_MaxRetries_Default_Is3()
    {
        var config = new BackendConfig();
        Assert.Equal(3, config.MaxRetries);
    }
}

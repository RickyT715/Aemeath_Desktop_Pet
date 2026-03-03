using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class BackendConfigTests
{
    [Fact]
    public void Defaults_AreCorrect()
    {
        var config = new BackendConfig();
        Assert.True(config.Enabled);
        Assert.Equal("auto", config.Mode);
        Assert.Equal(18900, config.Port);
        Assert.Equal(18901, config.InternalPort);
        Assert.Equal("python", config.PythonPath);
        Assert.Empty(config.TavilyApiKey);
        Assert.Empty(config.OpenWeatherMapApiKey);
        Assert.Equal(3, config.MaxRetries);
    }

    [Fact]
    public void McpConfig_Defaults()
    {
        var config = new McpConfig();
        Assert.False(config.Enabled);
        Assert.False(config.ExposeAsServer);
        Assert.Empty(config.Servers);
    }

    [Fact]
    public void McpServerDefinition_Defaults()
    {
        var def = new McpServerDefinition();
        Assert.Empty(def.Id);
        Assert.Empty(def.Name);
        Assert.Empty(def.Command);
        Assert.Empty(def.Arguments);
        Assert.Equal("stdio", def.TransportType);
        Assert.True(def.Enabled);
    }

    [Fact]
    public void AppConfig_HasBackendAndMcpProperties()
    {
        var config = new AppConfig();
        Assert.NotNull(config.Backend);
        Assert.NotNull(config.Mcp);
    }
}

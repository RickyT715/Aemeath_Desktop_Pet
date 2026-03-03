using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class McpClientServiceTests
{
    [Fact]
    public void Constructor_InitializesEmpty()
    {
        using var service = new McpClientService();
        Assert.Empty(service.ConnectedServerIds);
    }

    [Fact]
    public void IsConnected_FalseForUnknownServer()
    {
        using var service = new McpClientService();
        Assert.False(service.IsConnected("nonexistent"));
    }

    [Fact]
    public void Dispose_CanBeCalledMultipleTimes()
    {
        var service = new McpClientService();
        service.Dispose();
        service.Dispose();
    }

    [Fact]
    public async Task DisconnectAsync_NonexistentServer_NoOp()
    {
        using var service = new McpClientService();
        await service.DisconnectAsync("nonexistent"); // Should not throw
    }

    [Fact]
    public async Task ListToolsAsync_NonexistentServer_ReturnsEmpty()
    {
        using var service = new McpClientService();
        var tools = await service.ListToolsAsync("nonexistent");
        Assert.Empty(tools);
    }

    [Fact]
    public async Task CallToolAsync_NonexistentServer_ReturnsError()
    {
        using var service = new McpClientService();
        var result = await service.CallToolAsync(
            "nonexistent", "test_tool", new Dictionary<string, object?>());
        Assert.Contains("not connected", result);
    }

    [Fact]
    public void McpToolInfo_Defaults()
    {
        var info = new McpToolInfo();
        Assert.Empty(info.Name);
        Assert.Empty(info.Description);
    }

    [Fact]
    public void ConnectedServerIds_EmptyInitially_ExplicitCount()
    {
        using var service = new McpClientService();
        Assert.Equal(0, service.ConnectedServerIds.Count);
    }

    [Fact]
    public void IsConnected_FalseAfterDispose()
    {
        var service = new McpClientService();
        service.Dispose();
        Assert.False(service.IsConnected("any-server"));
    }

    [Fact]
    public void McpToolInfo_PropertiesSettableAndGettable()
    {
        var info = new McpToolInfo
        {
            Name = "test_tool",
            Description = "A test tool description"
        };
        Assert.Equal("test_tool", info.Name);
        Assert.Equal("A test tool description", info.Description);
    }

    [Fact]
    public async Task CallToolAsync_NonexistentServer_ErrorContainsNotConnected()
    {
        using var service = new McpClientService();
        var result = await service.CallToolAsync(
            "missing-server", "some_tool", new Dictionary<string, object?>());
        Assert.Contains("not connected", result, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task ListToolsAsync_MultipleNonexistentServers_AllReturnEmpty()
    {
        using var service = new McpClientService();
        var tools1 = await service.ListToolsAsync("server1");
        var tools2 = await service.ListToolsAsync("server2");
        Assert.Empty(tools1);
        Assert.Empty(tools2);
    }
}

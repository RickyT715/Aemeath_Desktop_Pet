using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class ChatMessageTests
{
    [Fact]
    public void DefaultValues()
    {
        var msg = new ChatMessage();
        Assert.Equal("user", msg.Role);
        Assert.Equal("", msg.Content);
        Assert.False(msg.IsStreaming);
        Assert.NotEmpty(msg.Id);
    }

    [Fact]
    public void Constructor_SetsRoleAndContent()
    {
        var msg = new ChatMessage("assistant", "Hello!");
        Assert.Equal("assistant", msg.Role);
        Assert.Equal("Hello!", msg.Content);
    }

    [Fact]
    public void IsUser_TrueForUserRole()
    {
        var msg = new ChatMessage("user", "test");
        Assert.True(msg.IsUser);
        Assert.False(msg.IsAssistant);
    }

    [Fact]
    public void IsAssistant_TrueForAssistantRole()
    {
        var msg = new ChatMessage("assistant", "test");
        Assert.True(msg.IsAssistant);
        Assert.False(msg.IsUser);
    }

    [Fact]
    public void Timestamp_SetToUtcNow()
    {
        var before = DateTime.UtcNow;
        var msg = new ChatMessage();
        var after = DateTime.UtcNow;

        Assert.InRange(msg.Timestamp, before, after);
    }

    [Fact]
    public void Id_IsUnique()
    {
        var msg1 = new ChatMessage();
        var msg2 = new ChatMessage();
        Assert.NotEqual(msg1.Id, msg2.Id);
    }
}

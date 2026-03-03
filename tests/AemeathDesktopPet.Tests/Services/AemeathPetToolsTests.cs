using System.Text.Json;
using AemeathDesktopPet.Engine;
using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;
using AemeathDesktopPet.Services.McpServer;

namespace AemeathDesktopPet.Tests.Services;

/// <summary>
/// Tests for AemeathPetTools that do NOT require initialization.
/// These run in a separate class to avoid test ordering issues with static state.
/// </summary>
public class AemeathPetToolsDefinitionTests
{
    [Fact]
    public void GetToolDefinitions_ReturnsFourTools()
    {
        var tools = AemeathPetTools.GetToolDefinitions();
        Assert.Equal(4, tools.Count);
    }

    [Fact]
    public void GetToolDefinitions_ContainsGetPetStatus()
    {
        var tools = AemeathPetTools.GetToolDefinitions();
        var json = JsonSerializer.Serialize(tools);
        Assert.Contains("get_pet_status", json);
    }

    [Fact]
    public void GetToolDefinitions_ContainsFeedPet()
    {
        var tools = AemeathPetTools.GetToolDefinitions();
        var json = JsonSerializer.Serialize(tools);
        Assert.Contains("feed_pet", json);
    }

    [Fact]
    public void GetToolDefinitions_ContainsPlayAnimation()
    {
        var tools = AemeathPetTools.GetToolDefinitions();
        var json = JsonSerializer.Serialize(tools);
        Assert.Contains("play_animation", json);
    }

    [Fact]
    public void GetToolDefinitions_ContainsSendMessage()
    {
        var tools = AemeathPetTools.GetToolDefinitions();
        var json = JsonSerializer.Serialize(tools);
        Assert.Contains("send_message", json);
    }

    [Fact]
    public void ExecuteTool_UnknownTool_ReturnsError()
    {
        var result = AemeathPetTools.ExecuteTool("nonexistent_tool", null);
        Assert.Contains("error", result);
        Assert.Contains("Unknown tool", result);
    }
}

/// <summary>
/// Tests for AemeathPetTools after initialization.
/// Uses [Collection] to ensure these don't run in parallel with other static-state tests.
/// </summary>
[Collection("AemeathPetTools")]
public class AemeathPetToolsExecutionTests : IDisposable
{
    private readonly StatsService _statsService;

    public AemeathPetToolsExecutionTests()
    {
        var tempDir = Path.Combine(Path.GetTempPath(), "aemeath_test_" + Guid.NewGuid().ToString("N"));
        var persistence = new JsonPersistenceService(tempDir);
        _statsService = new StatsService(persistence);
        _statsService.Load();
    }

    public void Dispose()
    {
        // Re-initialize to clean up static state for next test class
        // (static state will be overwritten by next Initialize call)
    }

    private void InitializeTools(Action<string>? sendChat = null)
    {
        // BehaviorEngine requires WPF dispatcher; pass null for behavior to test non-animation tools
        AemeathPetTools.Initialize(_statsService, null!, sendChat);
    }

    [Fact]
    public void GetPetStatus_AfterInit_ReturnsJson()
    {
        InitializeTools();
        var result = AemeathPetTools.ExecuteTool("get_pet_status", null);
        Assert.DoesNotContain("error", result);

        var doc = JsonDocument.Parse(result);
        Assert.True(doc.RootElement.TryGetProperty("mood", out _));
        Assert.True(doc.RootElement.TryGetProperty("energy", out _));
        Assert.True(doc.RootElement.TryGetProperty("affection", out _));
    }

    [Fact]
    public void GetPetStatus_ContainsDaysTogether()
    {
        InitializeTools();
        var result = AemeathPetTools.ExecuteTool("get_pet_status", null);
        var doc = JsonDocument.Parse(result);
        Assert.True(doc.RootElement.TryGetProperty("days_together", out var dt));
        Assert.True(dt.GetInt32() >= 1);
    }

    [Fact]
    public void GetPetStatus_ContainsTotalCounters()
    {
        InitializeTools();
        var result = AemeathPetTools.ExecuteTool("get_pet_status", null);
        var doc = JsonDocument.Parse(result);
        Assert.True(doc.RootElement.TryGetProperty("total_chats", out _));
        Assert.True(doc.RootElement.TryGetProperty("total_pets", out _));
        Assert.True(doc.RootElement.TryGetProperty("total_songs", out _));
    }

    [Fact]
    public void FeedPet_DefaultAmount_BoostsMood()
    {
        InitializeTools();
        var moodBefore = _statsService.Stats.Mood;

        // No arguments = default amount 10
        var result = AemeathPetTools.ExecuteTool("feed_pet", null);
        var doc = JsonDocument.Parse(result);
        Assert.Equal("ok", doc.RootElement.GetProperty("status").GetString());
        Assert.Equal(10, doc.RootElement.GetProperty("boosted_by").GetInt32());
        Assert.True(_statsService.Stats.Mood >= moodBefore);
    }

    [Fact]
    public void FeedPet_CustomAmount_UsesSpecifiedAmount()
    {
        InitializeTools();
        var args = JsonDocument.Parse("""{"amount": 25}""").RootElement;
        var result = AemeathPetTools.ExecuteTool("feed_pet", args);
        var doc = JsonDocument.Parse(result);
        Assert.Equal(25, doc.RootElement.GetProperty("boosted_by").GetInt32());
    }

    [Fact]
    public void FeedPet_AmountClamped_Above100()
    {
        InitializeTools();
        var args = JsonDocument.Parse("""{"amount": 200}""").RootElement;
        var result = AemeathPetTools.ExecuteTool("feed_pet", args);
        var doc = JsonDocument.Parse(result);
        Assert.Equal(100, doc.RootElement.GetProperty("boosted_by").GetInt32());
    }

    [Fact]
    public void FeedPet_AmountClamped_Below1()
    {
        InitializeTools();
        var args = JsonDocument.Parse("""{"amount": -5}""").RootElement;
        var result = AemeathPetTools.ExecuteTool("feed_pet", args);
        var doc = JsonDocument.Parse(result);
        Assert.Equal(1, doc.RootElement.GetProperty("boosted_by").GetInt32());
    }

    [Fact]
    public void PlayAnimation_NullBehavior_ReturnsError()
    {
        // Initialize with null behavior engine
        AemeathPetTools.Initialize(_statsService, null!, null);
        var args = JsonDocument.Parse("""{"animation": "wave"}""").RootElement;
        var result = AemeathPetTools.ExecuteTool("play_animation", args);
        Assert.Contains("error", result);
    }

    [Fact]
    public void SendMessage_WithCallback_InvokesCallback()
    {
        string? captured = null;
        InitializeTools(msg => captured = msg);
        var args = JsonDocument.Parse("""{"message": "Hello Aemeath!"}""").RootElement;
        var result = AemeathPetTools.ExecuteTool("send_message", args);
        var doc = JsonDocument.Parse(result);
        Assert.Equal("ok", doc.RootElement.GetProperty("status").GetString());
        Assert.Equal("Hello Aemeath!", doc.RootElement.GetProperty("message_sent").GetString());
        Assert.Equal("Hello Aemeath!", captured);
    }

    [Fact]
    public void SendMessage_WithoutCallback_ReturnsError()
    {
        AemeathPetTools.Initialize(_statsService, null!, null);
        var args = JsonDocument.Parse("""{"message": "Hello"}""").RootElement;
        var result = AemeathPetTools.ExecuteTool("send_message", args);
        Assert.Contains("error", result);
        Assert.Contains("Chat not available", result);
    }
}

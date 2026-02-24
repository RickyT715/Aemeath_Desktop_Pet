using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class ClaudeApiServiceTests
{
    private static AppConfig ConfigWithoutKey() => new() { ApiKey = "" };
    private static AppConfig ConfigWithKey() => new() { ApiKey = "sk-ant-test-key" };
    private static AemeathStats DefaultStats() => new();

    [Fact]
    public void IsAvailable_FalseWhenNoApiKey()
    {
        var service = new ClaudeApiService(() => ConfigWithoutKey(), () => DefaultStats());
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_TrueWhenApiKeySet()
    {
        var service = new ClaudeApiService(() => ConfigWithKey(), () => DefaultStats());
        Assert.True(service.IsAvailable);
    }

    [Fact]
    public void IsAvailable_FalseWhenApiKeyWhitespace()
    {
        var config = new AppConfig { ApiKey = "   " };
        var service = new ClaudeApiService(() => config, () => DefaultStats());
        Assert.False(service.IsAvailable);
    }

    [Fact]
    public async Task SendMessageAsync_ReturnsOfflineResponse_WhenNoApiKey()
    {
        var service = new ClaudeApiService(() => ConfigWithoutKey(), () => DefaultStats());
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public async Task StreamMessageAsync_YieldsOfflineResponse_WhenNoApiKey()
    {
        var service = new ClaudeApiService(() => ConfigWithoutKey(), () => DefaultStats());
        var chunks = new List<string>();

        await foreach (var chunk in service.StreamMessageAsync("Hello", new List<ChatMessage>()))
        {
            chunks.Add(chunk);
        }

        Assert.Single(chunks);
        Assert.False(string.IsNullOrEmpty(chunks[0]));
    }

    [Fact]
    public void BuildSystemPrompt_ContainsAemeath()
    {
        var stats = new AemeathStats { Mood = 80, Energy = 60, Affection = 70 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("Aemeath", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsCatName()
    {
        var stats = DefaultStats();
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "TestCat");
        Assert.Contains("TestCat", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsStatValues()
    {
        var stats = new AemeathStats { Mood = 85, Energy = 45, Affection = 72 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("85", prompt);
        Assert.Contains("45", prompt);
        Assert.Contains("72", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsTimeOfDay()
    {
        var stats = DefaultStats();
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        // Should contain one of the time-of-day strings
        Assert.True(
            prompt.Contains("Morning") || prompt.Contains("Afternoon") ||
            prompt.Contains("Evening") || prompt.Contains("Late Night"));
    }

    [Fact]
    public void BuildSystemPrompt_ContainsPersonalityTraits()
    {
        var stats = DefaultStats();
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("bubbly", prompt);
        Assert.Contains("Fleet Snowfluff", prompt);
        Assert.Contains("paper planes", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsBehavioralGuidelines()
    {
        var stats = DefaultStats();
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("High mood", prompt);
        Assert.Contains("Low energy", prompt);
        Assert.Contains("Family-friendly", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsDaysTogether()
    {
        var stats = new AemeathStats();
        stats.FirstLaunch = DateTime.UtcNow.AddDays(-10);
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("10", prompt);
    }

    [Fact]
    public async Task SendMessageAsync_WithInvalidKey_ReturnsOfflineResponse()
    {
        // Even with a key set, if the API call fails it should fall back
        var service = new ClaudeApiService(() => ConfigWithKey(), () => DefaultStats());
        // This will fail because the key is fake — should fall back to offline
        var result = await service.SendMessageAsync("Hello", new List<ChatMessage>());
        Assert.False(string.IsNullOrEmpty(result));
    }
}

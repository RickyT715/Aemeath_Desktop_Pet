using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class ChatPromptBuilderTests
{
    private static AemeathStats DefaultStats() => new();

    [Fact]
    public void BuildSystemPrompt_ContainsCharacterName()
    {
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro");
        Assert.Contains("Aemeath", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsCustomCatName()
    {
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "MyCatName");
        Assert.Contains("MyCatName", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_EmptyCatName_DoesNotThrow()
    {
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "");
        Assert.NotNull(prompt);
        Assert.Contains("Aemeath", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_NullCatName_DoesNotThrow()
    {
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), null!);
        Assert.NotNull(prompt);
        Assert.Contains("Aemeath", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsMoodValue()
    {
        var stats = new AemeathStats { Mood = 85 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("85", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsEnergyValue()
    {
        var stats = new AemeathStats { Energy = 45 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("45", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsAffectionValue()
    {
        var stats = new AemeathStats { Affection = 72 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("72", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsAllStatValues()
    {
        var stats = new AemeathStats { Mood = 91, Energy = 37, Affection = 63 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.Contains("91", prompt);
        Assert.Contains("37", prompt);
        Assert.Contains("63", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsTimeOfDay()
    {
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro");
        Assert.True(
            prompt.Contains("Morning") || prompt.Contains("Afternoon") ||
            prompt.Contains("Evening") || prompt.Contains("Late Night"));
    }

    [Fact]
    public void BuildSystemPrompt_ContainsPersonalityTraits()
    {
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro");
        Assert.Contains("bubbly", prompt);
        Assert.Contains("Fleet Snowfluff", prompt);
        Assert.Contains("paper planes", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsBehavioralGuidelines()
    {
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro");
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
    public void BuildSystemPrompt_ZeroStats_DoesNotThrow()
    {
        var stats = new AemeathStats { Mood = 0, Energy = 0, Affection = 0 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.NotNull(prompt);
        Assert.Contains("Aemeath", prompt);
        // 0 formatted as "0" should appear (Mood: 0/100)
        Assert.Contains("0/100", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_MaxStats_DoesNotThrow()
    {
        var stats = new AemeathStats { Mood = 100, Energy = 100, Affection = 100 };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(stats, "Kuro");
        Assert.NotNull(prompt);
        Assert.Contains("100/100", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_ContainsSpeakingStyle()
    {
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro");
        Assert.Contains("Speaking Style", prompt);
        Assert.Contains("concise", prompt);
    }
}

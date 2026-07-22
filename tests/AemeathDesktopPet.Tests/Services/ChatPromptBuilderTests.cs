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

    // ---- Memory context tests (new overload) ----

    [Fact]
    public void BuildSystemPrompt_NullMemory_ReturnsOriginalPrompt()
    {
        var withoutMemory = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", null);
        var twoArgVersion = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro");

        // Both should produce the same prompt
        Assert.Equal(withoutMemory, twoArgVersion);
    }

    [Fact]
    public void BuildSystemPrompt_EmptyMemory_NoMemorySection()
    {
        var emptyMemory = new MemoryContext();
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", emptyMemory);

        // An empty memory context should not inject any memory section
        Assert.DoesNotContain("What You Remember", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_WithUserName_ContainsNameInMemorySection()
    {
        var memory = new MemoryContext
        {
            UserName = "Ricky",
            UserFacts = new List<string> { "CS student" }
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("What You Remember About Ricky", prompt);
        Assert.Contains("Name: Ricky", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_NullUserName_UsesDefaultLabel()
    {
        var memory = new MemoryContext
        {
            UserFacts = new List<string> { "Likes games" }
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("What You Remember About the user", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_WithMemoryContext_IncludesCoreMemorySection()
    {
        var memory = new MemoryContext
        {
            UserName = "Ricky",
            UserFacts = new List<string> { "CS student", "Plays piano" },
            Preferences = new List<string> { "Dark mode", "Gaming" },
            CommunicationStyle = "Casual",
            RelationshipStage = "familiar",
            DaysTogether = 45
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("Core Memory", prompt);
        Assert.Contains("CS student", prompt);
        Assert.Contains("Plays piano", prompt);
        Assert.Contains("Interests: Dark mode, Gaming", prompt);
        Assert.Contains("Communication style: Casual", prompt);
        Assert.Contains("Relationship: familiar (45 days together)", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_WithEpisodicMemories_IncludesRelevantPastSection()
    {
        var memory = new MemoryContext
        {
            RecentTopics = new List<string>
            {
                "[3 days ago] Talked about calculus exam",
                "[1 week ago] Discussed React hooks"
            }
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("Relevant Past Memories", prompt);
        Assert.Contains("calculus exam", prompt);
        Assert.Contains("React hooks", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_WithUpcomingEvents_IncludesEventsSection()
    {
        var memory = new MemoryContext
        {
            UpcomingEvents = new List<string> { "Calculus exam: March 10 (in 7 days)" }
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("Upcoming Events", prompt);
        Assert.Contains("Calculus exam", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_WithObservations_IncludesContextSection()
    {
        var memory = new MemoryContext
        {
            Observations = new List<string> { "VS Code open for 45 min" },
            SessionSummary = "Focused coding session"
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("Current Context", prompt);
        Assert.Contains("VS Code open for 45 min", prompt);
        Assert.Contains("Session: Focused coding session", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_MemoryFactsCapped_At10()
    {
        var memory = new MemoryContext
        {
            UserFacts = Enumerable.Range(1, 15).Select(i => $"Fact {i}").ToList()
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("Fact 10", prompt);
        Assert.DoesNotContain("Fact 11", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_PreferencesCapped_At5()
    {
        var memory = new MemoryContext
        {
            Preferences = Enumerable.Range(1, 8).Select(i => $"Pref{i}").ToList()
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("Pref5", prompt);
        Assert.DoesNotContain("Pref6", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_EpisodicCapped_At5()
    {
        var memory = new MemoryContext
        {
            RecentTopics = Enumerable.Range(1, 8).Select(i => $"Topic {i}").ToList()
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("Topic 5", prompt);
        Assert.DoesNotContain("Topic 6", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_WithMemory_ContainsNaturalUseInstruction()
    {
        var memory = new MemoryContext
        {
            UserFacts = new List<string> { "Some fact" }
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        Assert.Contains("naturally", prompt);
        Assert.Contains("Never list them robotically", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_WithMemory_StillContainsCharacterInfo()
    {
        var memory = new MemoryContext
        {
            UserName = "Ricky",
            UserFacts = new List<string> { "CS student" }
        };
        var prompt = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", memory);

        // Memory section should not break existing prompt sections
        Assert.Contains("Aemeath", prompt);
        Assert.Contains("bubbly", prompt);
        Assert.Contains("Family-friendly", prompt);
        Assert.Contains("Boundaries", prompt);
    }

    [Fact]
    public void BuildSystemPrompt_TwoArgOverload_CallsThreeArgWithNull()
    {
        // Verify backward compatibility: 2-arg should produce same as 3-arg with null
        var twoArg = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro");
        var threeArgNull = ChatPromptBuilder.BuildSystemPrompt(DefaultStats(), "Kuro", null);

        Assert.Equal(twoArg, threeArgNull);
    }
}

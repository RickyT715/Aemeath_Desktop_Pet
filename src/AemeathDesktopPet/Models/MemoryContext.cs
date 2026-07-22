namespace AemeathDesktopPet.Models;

/// <summary>
/// Lightweight context object assembled before each AI call.
/// Contains all memory tiers formatted for injection into the system prompt.
/// </summary>
public class MemoryContext
{
    /// <summary>User's name from core memory (null if unknown).</summary>
    public string? UserName { get; set; }

    /// <summary>Key facts about the user from core memory.</summary>
    public List<string> UserFacts { get; set; } = new();

    /// <summary>Known user preferences and interests.</summary>
    public List<string> Preferences { get; set; } = new();

    /// <summary>Relevant past memories retrieved from episodic store.</summary>
    public List<string> RecentTopics { get; set; } = new();

    /// <summary>Brief summary of the current or last session.</summary>
    public string? SessionSummary { get; set; }

    /// <summary>Recent observations from screen/activity/camera sources.</summary>
    public List<string> Observations { get; set; } = new();

    /// <summary>Upcoming scheduled events from procedural memory.</summary>
    public List<string> UpcomingEvents { get; set; } = new();

    /// <summary>Relationship stage (e.g. "new", "familiar", "close_friend").</summary>
    public string? RelationshipStage { get; set; }

    /// <summary>Days the user has been with Aemeath.</summary>
    public int DaysTogether { get; set; }

    /// <summary>User's communication style from core memory.</summary>
    public string? CommunicationStyle { get; set; }
}

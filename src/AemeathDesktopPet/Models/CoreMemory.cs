namespace AemeathDesktopPet.Models;

/// <summary>
/// Always-loaded user profile and relationship data.
/// Injected into every system prompt. Hard cap: ~500 tokens.
/// Persisted to core_memory.json.
/// </summary>
public class CoreMemory
{
    public int Version { get; set; } = 1;
    public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    public UserProfile UserProfile { get; set; } = new();
    public UserPersonality Personality { get; set; } = new();
    public RelationshipState Relationship { get; set; } = new();
}

/// <summary>
/// Basic user identity and demographic facts.
/// </summary>
public class UserProfile
{
    public string? Name { get; set; }
    public string? Nickname { get; set; }
    public string? AgeRange { get; set; }
    public string? Occupation { get; set; }
    public List<string> KeyFacts { get; set; } = new();
    public List<string> Languages { get; set; } = new();
}

/// <summary>
/// Observed personality traits and communication preferences.
/// </summary>
public class UserPersonality
{
    public string? CommunicationStyle { get; set; }
    public string? MoodPatterns { get; set; }
    public List<string> Interests { get; set; } = new();
    public List<string> Dislikes { get; set; } = new();
}

/// <summary>
/// Tracks the evolving relationship between user and Aemeath.
/// Stages: new -> acquaintance -> familiar -> close_friend -> best_friend
/// </summary>
public class RelationshipState
{
    public string Stage { get; set; } = "new";
    public int DaysTogether { get; set; } = 0;
    public string TrustLevel { get; set; } = "initial";
    public List<string> InsideJokes { get; set; } = new();
    public List<string> Milestones { get; set; } = new();
}

namespace AemeathDesktopPet.Models;

/// <summary>
/// Learned patterns, routines, and scheduled events.
/// Detected from accumulated observations over time.
/// Persisted to procedural_memory.json.
/// </summary>
public class ProceduralMemory
{
    public int Version { get; set; } = 1;
    public List<Routine> Routines { get; set; } = new();
    public List<ScheduledEvent> ScheduledEvents { get; set; } = new();
    public List<LearnedPreference> LearnedPreferences { get; set; } = new();
}

/// <summary>
/// A recurring pattern detected from user behavior (e.g. "starts coding at 9am on weekdays").
/// </summary>
public class Routine
{
    public string Id { get; set; } = "";
    public string Pattern { get; set; } = "";
    public double Confidence { get; set; }
    public int Observations { get; set; }
    public string FirstSeen { get; set; } = "";
    public string LastSeen { get; set; } = "";
    public List<int> DaysOfWeek { get; set; } = new();
}

/// <summary>
/// A future event mentioned by the user that Aemeath should follow up on.
/// </summary>
public class ScheduledEvent
{
    public string Id { get; set; } = "";
    public string Event { get; set; } = "";
    public string Date { get; set; } = "";
    public string Source { get; set; } = "";
    public string FollowUp { get; set; } = "";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// A user preference detected from repeated observations (e.g. "uses dark mode").
/// </summary>
public class LearnedPreference
{
    public string Id { get; set; } = "";
    public string Preference { get; set; } = "";
    public double Confidence { get; set; }
    public int Observations { get; set; }
    public string Source { get; set; } = "";
}

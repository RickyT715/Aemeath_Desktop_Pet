namespace AemeathDesktopPet.Models;

/// <summary>
/// A single observation buffer entry. Accumulated from screen awareness,
/// activity monitor, camera, and pomodoro sources. Has a 24-hour TTL
/// before being distilled into episodic memory or purged.
/// </summary>
public class ObservationEntry
{
    /// <summary>Short unique identifier for this entry.</summary>
    public string Id { get; set; } = Guid.NewGuid().ToString("N")[..8];

    /// <summary>When the observation was recorded.</summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    /// <summary>Source of the observation: "screen", "activity", "camera", "pomodoro".</summary>
    public string Source { get; set; } = "";

    /// <summary>Human-readable description of what was observed.</summary>
    public string Content { get; set; } = "";

    /// <summary>Activity context at time of observation (e.g. "StudyingCoding").</summary>
    public string ActivityContext { get; set; } = "";

    /// <summary>Time-to-live in hours before this entry expires.</summary>
    public int TtlHours { get; set; } = 24;

    /// <summary>Whether this entry has expired based on its timestamp and TTL.</summary>
    public bool IsExpired => DateTime.UtcNow > Timestamp.AddHours(TtlHours);
}

/// <summary>
/// Container for persisting the observation buffer to JSON.
/// </summary>
public class ObservationBuffer
{
    public List<ObservationEntry> Entries { get; set; } = new();
}

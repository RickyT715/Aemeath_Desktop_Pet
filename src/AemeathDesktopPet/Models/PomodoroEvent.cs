namespace AemeathDesktopPet.Models;

public enum PomodoroEventType
{
    WorkStarted,
    WorkFinished,
    BreakStarted,
    BreakFinished,
    TaskAdded
}

public class PomodoroEvent
{
    public string Event { get; set; } = "";
    public string? TaskTitle { get; set; }
    public string? BreakType { get; set; }  // "short" or "long"
    public int? Duration { get; set; }       // minutes
}

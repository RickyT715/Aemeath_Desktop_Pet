using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class ProceduralMemoryTests
{
    [Fact]
    public void DefaultValues()
    {
        var mem = new ProceduralMemory();

        Assert.Equal(1, mem.Version);
        Assert.Empty(mem.Routines);
        Assert.Empty(mem.ScheduledEvents);
        Assert.Empty(mem.LearnedPreferences);
    }
}

public class RoutineTests
{
    [Fact]
    public void DefaultValues()
    {
        var routine = new Routine();

        Assert.Equal("", routine.Id);
        Assert.Equal("", routine.Pattern);
        Assert.Equal(0, routine.Confidence);
        Assert.Equal(0, routine.Observations);
        Assert.Equal("", routine.FirstSeen);
        Assert.Equal("", routine.LastSeen);
        Assert.Empty(routine.DaysOfWeek);
    }

    [Fact]
    public void SetAllFields()
    {
        var routine = new Routine
        {
            Id = "morning_routine",
            Pattern = "Starts coding around 9:00-9:30 AM on weekdays",
            Confidence = 0.75,
            Observations = 12,
            FirstSeen = "2026-02-15",
            LastSeen = "2026-03-03",
            DaysOfWeek = new List<int> { 1, 2, 3, 4, 5 }
        };

        Assert.Equal("morning_routine", routine.Id);
        Assert.Equal(0.75, routine.Confidence);
        Assert.Equal(12, routine.Observations);
        Assert.Equal(5, routine.DaysOfWeek.Count);
        Assert.DoesNotContain(0, routine.DaysOfWeek); // no Sunday
        Assert.DoesNotContain(6, routine.DaysOfWeek); // no Saturday
    }
}

public class ScheduledEventTests
{
    [Fact]
    public void DefaultValues()
    {
        var evt = new ScheduledEvent();

        Assert.Equal("", evt.Id);
        Assert.Equal("", evt.Event);
        Assert.Equal("", evt.Date);
        Assert.Equal("", evt.Source);
        Assert.Equal("", evt.FollowUp);
    }

    [Fact]
    public void CreatedAt_DefaultsToUtcNow()
    {
        var before = DateTime.UtcNow;
        var evt = new ScheduledEvent();
        var after = DateTime.UtcNow;

        Assert.InRange(evt.CreatedAt, before, after);
    }

    [Fact]
    public void SetAllFields()
    {
        var evt = new ScheduledEvent
        {
            Id = "calc_exam_20260310",
            Event = "Calculus exam",
            Date = "2026-03-10",
            Source = "conversation",
            FollowUp = "Ask how the exam went"
        };

        Assert.Equal("calc_exam_20260310", evt.Id);
        Assert.Equal("Calculus exam", evt.Event);
        Assert.Equal("2026-03-10", evt.Date);
        Assert.Equal("conversation", evt.Source);
        Assert.Equal("Ask how the exam went", evt.FollowUp);
    }
}

public class LearnedPreferenceTests
{
    [Fact]
    public void DefaultValues()
    {
        var pref = new LearnedPreference();

        Assert.Equal("", pref.Id);
        Assert.Equal("", pref.Preference);
        Assert.Equal(0, pref.Confidence);
        Assert.Equal(0, pref.Observations);
        Assert.Equal("", pref.Source);
    }

    [Fact]
    public void SetAllFields()
    {
        var pref = new LearnedPreference
        {
            Id = "prefers_dark_mode",
            Preference = "Uses dark mode in all applications",
            Confidence = 0.9,
            Observations = 20,
            Source = "screen_observation"
        };

        Assert.Equal("prefers_dark_mode", pref.Id);
        Assert.Equal("Uses dark mode in all applications", pref.Preference);
        Assert.Equal(0.9, pref.Confidence);
        Assert.Equal(20, pref.Observations);
        Assert.Equal("screen_observation", pref.Source);
    }
}

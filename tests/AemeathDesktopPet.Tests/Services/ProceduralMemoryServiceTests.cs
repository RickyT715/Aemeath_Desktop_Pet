using AemeathDesktopPet.Models;
using AemeathDesktopPet.Services;

namespace AemeathDesktopPet.Tests.Services;

public class ProceduralMemoryServiceTests : IDisposable
{
    private readonly string _tempDir;
    private readonly ProceduralMemoryService _service;

    public ProceduralMemoryServiceTests()
    {
        _tempDir = Path.Combine(Path.GetTempPath(), $"AemeathTest_{Guid.NewGuid():N}");
        _service = new ProceduralMemoryService(_tempDir);
    }

    public void Dispose()
    {
        if (Directory.Exists(_tempDir))
            Directory.Delete(_tempDir, true);
    }

    // ---- Load ----

    [Fact]
    public void Load_ReturnsEmpty_WhenFileDoesNotExist()
    {
        var mem = _service.Load();

        Assert.NotNull(mem);
        Assert.Equal(1, mem.Version);
        Assert.Empty(mem.Routines);
        Assert.Empty(mem.ScheduledEvents);
        Assert.Empty(mem.LearnedPreferences);
    }

    [Fact]
    public void Load_HandlesCorruptJson_ReturnsDefault()
    {
        File.WriteAllText(Path.Combine(_tempDir, "procedural_memory.json"), "broken json!!!");

        var mem = _service.Load();

        Assert.NotNull(mem);
        Assert.Equal(1, mem.Version);
    }

    [Fact]
    public void Load_HandlesEmptyFile_ReturnsDefault()
    {
        File.WriteAllText(Path.Combine(_tempDir, "procedural_memory.json"), "");

        var mem = _service.Load();

        Assert.NotNull(mem);
    }

    // ---- Save & Load Roundtrip ----

    [Fact]
    public void SaveAndLoad_RoundTrip()
    {
        var mem = new ProceduralMemory();
        mem.Routines.Add(new Routine
        {
            Id = "morning_routine",
            Pattern = "Starts coding at 9am",
            Confidence = 0.8,
            Observations = 15,
            DaysOfWeek = new List<int> { 1, 2, 3, 4, 5 }
        });
        mem.ScheduledEvents.Add(new ScheduledEvent
        {
            Id = "exam1",
            Event = "Calculus exam",
            Date = "2026-03-10",
            Source = "conversation",
            FollowUp = "Ask how it went"
        });
        mem.LearnedPreferences.Add(new LearnedPreference
        {
            Id = "dark_mode",
            Preference = "Uses dark mode",
            Confidence = 0.9,
            Observations = 20,
            Source = "screen_observation"
        });

        _service.Save(mem);

        var service2 = new ProceduralMemoryService(_tempDir);
        var loaded = service2.Load();

        Assert.Single(loaded.Routines);
        Assert.Equal("morning_routine", loaded.Routines[0].Id);
        Assert.Equal(0.8, loaded.Routines[0].Confidence);

        Assert.Single(loaded.ScheduledEvents);
        Assert.Equal("Calculus exam", loaded.ScheduledEvents[0].Event);

        Assert.Single(loaded.LearnedPreferences);
        Assert.Equal("Uses dark mode", loaded.LearnedPreferences[0].Preference);
    }

    // ---- GetUpcomingEvents ----

    [Fact]
    public void GetUpcomingEvents_ReturnsEventsWithinRange()
    {
        var mem = new ProceduralMemory();
        var tomorrow = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");
        var inThreeDays = DateTime.UtcNow.Date.AddDays(3).ToString("yyyy-MM-dd");

        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "e1", Event = "Event 1", Date = tomorrow });
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "e2", Event = "Event 2", Date = inThreeDays });

        _service.Save(mem);
        _service.Load();

        var upcoming = _service.GetUpcomingEvents(7);

        Assert.Equal(2, upcoming.Count);
    }

    [Fact]
    public void GetUpcomingEvents_ExcludesPastEvents()
    {
        var mem = new ProceduralMemory();
        var yesterday = DateTime.UtcNow.Date.AddDays(-1).ToString("yyyy-MM-dd");
        var tomorrow = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");

        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "past", Event = "Past event", Date = yesterday });
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "future", Event = "Future event", Date = tomorrow });

        _service.Save(mem);
        _service.Load();

        var upcoming = _service.GetUpcomingEvents(7);

        Assert.Single(upcoming);
        Assert.Equal("Future event", upcoming[0].Event);
    }

    [Fact]
    public void GetUpcomingEvents_ExcludesEventsBeyondRange()
    {
        var mem = new ProceduralMemory();
        var inTwoDays = DateTime.UtcNow.Date.AddDays(2).ToString("yyyy-MM-dd");
        var inTenDays = DateTime.UtcNow.Date.AddDays(10).ToString("yyyy-MM-dd");

        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "near", Event = "Near event", Date = inTwoDays });
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "far", Event = "Far event", Date = inTenDays });

        _service.Save(mem);
        _service.Load();

        var upcoming = _service.GetUpcomingEvents(7);

        Assert.Single(upcoming);
        Assert.Equal("Near event", upcoming[0].Event);
    }

    [Fact]
    public void GetUpcomingEvents_IncludesToday()
    {
        var mem = new ProceduralMemory();
        var today = DateTime.UtcNow.Date.ToString("yyyy-MM-dd");

        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "today", Event = "Today's event", Date = today });

        _service.Save(mem);
        _service.Load();

        var upcoming = _service.GetUpcomingEvents(7);

        Assert.Single(upcoming);
        Assert.Equal("Today's event", upcoming[0].Event);
    }

    [Fact]
    public void GetUpcomingEvents_HandlesInvalidDateFormat()
    {
        var mem = new ProceduralMemory();
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "bad", Event = "Bad date", Date = "not-a-date" });

        _service.Save(mem);
        _service.Load();

        var upcoming = _service.GetUpcomingEvents(7);

        Assert.Empty(upcoming); // Invalid date should be excluded
    }

    [Fact]
    public void GetUpcomingEvents_ReturnsOrderedByDate()
    {
        var mem = new ProceduralMemory();
        var inFive = DateTime.UtcNow.Date.AddDays(5).ToString("yyyy-MM-dd");
        var inTwo = DateTime.UtcNow.Date.AddDays(2).ToString("yyyy-MM-dd");
        var inOne = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");

        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "e5", Event = "In 5 days", Date = inFive });
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "e2", Event = "In 2 days", Date = inTwo });
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "e1", Event = "In 1 day", Date = inOne });

        _service.Save(mem);
        _service.Load();

        var upcoming = _service.GetUpcomingEvents(7);

        Assert.Equal(3, upcoming.Count);
        Assert.Equal("In 1 day", upcoming[0].Event);
        Assert.Equal("In 2 days", upcoming[1].Event);
        Assert.Equal("In 5 days", upcoming[2].Event);
    }

    [Fact]
    public void GetUpcomingEvents_DefaultDaysAhead_IsSeven()
    {
        var mem = new ProceduralMemory();
        var inSix = DateTime.UtcNow.Date.AddDays(6).ToString("yyyy-MM-dd");
        var inEight = DateTime.UtcNow.Date.AddDays(8).ToString("yyyy-MM-dd");

        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "in6", Event = "In 6", Date = inSix });
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "in8", Event = "In 8", Date = inEight });

        _service.Save(mem);
        _service.Load();

        var upcoming = _service.GetUpcomingEvents(); // default 7 days

        Assert.Single(upcoming);
        Assert.Equal("In 6", upcoming[0].Event);
    }

    // ---- GetActiveRoutines ----

    [Fact]
    public void GetActiveRoutines_FiltersbyConfidence()
    {
        var mem = new ProceduralMemory();
        mem.Routines.Add(new Routine { Id = "high", Pattern = "Morning coding", Confidence = 0.8 });
        mem.Routines.Add(new Routine { Id = "low", Pattern = "Random habit", Confidence = 0.3 });
        mem.Routines.Add(new Routine { Id = "mid", Pattern = "Lunch break", Confidence = 0.5 });

        _service.Save(mem);
        _service.Load();

        var active = _service.GetActiveRoutines(0.5);

        Assert.Equal(2, active.Count);
        Assert.Contains(active, r => r.Id == "high");
        Assert.Contains(active, r => r.Id == "mid");
        Assert.DoesNotContain(active, r => r.Id == "low");
    }

    [Fact]
    public void GetActiveRoutines_DefaultThreshold_Is05()
    {
        var mem = new ProceduralMemory();
        mem.Routines.Add(new Routine { Id = "r1", Pattern = "Test", Confidence = 0.49 });
        mem.Routines.Add(new Routine { Id = "r2", Pattern = "Test", Confidence = 0.5 });

        _service.Save(mem);
        _service.Load();

        var active = _service.GetActiveRoutines();

        Assert.Single(active);
        Assert.Equal("r2", active[0].Id);
    }

    [Fact]
    public void GetActiveRoutines_ReturnsEmpty_WhenNoneQualify()
    {
        var mem = new ProceduralMemory();
        mem.Routines.Add(new Routine { Id = "r1", Confidence = 0.1 });

        _service.Save(mem);
        _service.Load();

        var active = _service.GetActiveRoutines();
        Assert.Empty(active);
    }

    // ---- FormatForPrompt ----

    [Fact]
    public void FormatForPrompt_EmptyMemory_ReturnsEmpty()
    {
        _service.Load();
        var text = _service.FormatForPrompt();
        Assert.Equal("", text);
    }

    [Fact]
    public void FormatForPrompt_ContainsUpcomingEvents()
    {
        var mem = new ProceduralMemory();
        var tomorrow = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");
        mem.ScheduledEvents.Add(new ScheduledEvent
        {
            Id = "exam",
            Event = "Calculus exam",
            Date = tomorrow,
            FollowUp = "Ask about preparation"
        });

        _service.Save(mem);
        _service.Load();

        var text = _service.FormatForPrompt();

        Assert.Contains("Upcoming Events", text);
        Assert.Contains("Calculus exam", text);
        Assert.Contains("(tomorrow)", text);
        Assert.Contains("Reminder: Ask about preparation", text);
    }

    [Fact]
    public void FormatForPrompt_TodayEvent_ShowsToday()
    {
        var mem = new ProceduralMemory();
        var today = DateTime.UtcNow.Date.ToString("yyyy-MM-dd");
        mem.ScheduledEvents.Add(new ScheduledEvent
        {
            Id = "today_event",
            Event = "Team meeting",
            Date = today
        });

        _service.Save(mem);
        _service.Load();

        var text = _service.FormatForPrompt();

        Assert.Contains("(today)", text);
    }

    [Fact]
    public void FormatForPrompt_LimitsToThreeEvents()
    {
        var mem = new ProceduralMemory();
        for (int i = 1; i <= 5; i++)
        {
            var date = DateTime.UtcNow.Date.AddDays(i).ToString("yyyy-MM-dd");
            mem.ScheduledEvents.Add(new ScheduledEvent
            {
                Id = $"e{i}",
                Event = $"Event {i}",
                Date = date
            });
        }

        _service.Save(mem);
        _service.Load();

        var text = _service.FormatForPrompt();

        Assert.Contains("Event 1", text);
        Assert.Contains("Event 2", text);
        Assert.Contains("Event 3", text);
        Assert.DoesNotContain("Event 4", text);
        Assert.DoesNotContain("Event 5", text);
    }

    // ---- Current ----

    [Fact]
    public void Current_ReturnsCache()
    {
        var loaded = _service.Load();
        Assert.Same(loaded, _service.Current);
    }

    // ---- Constructor ----

    [Fact]
    public void Constructor_CreatesDirectory()
    {
        var nested = Path.Combine(_tempDir, "sub", "dir");
        var svc = new ProceduralMemoryService(nested);
        Assert.True(Directory.Exists(nested));
    }

    [Fact]
    public void GetUpcomingEvents_ZeroDaysAhead_ReturnsOnlyToday()
    {
        var mem = new ProceduralMemory();
        var today = DateTime.UtcNow.Date.ToString("yyyy-MM-dd");
        var tomorrow = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "today", Event = "Today event", Date = today });
        mem.ScheduledEvents.Add(new ScheduledEvent { Id = "tmrw", Event = "Tomorrow event", Date = tomorrow });

        _service.Save(mem);
        _service.Load();

        var upcoming = _service.GetUpcomingEvents(0);
        Assert.Single(upcoming);
        Assert.Equal("Today event", upcoming[0].Event);
    }

    [Fact]
    public void FormatForPrompt_WithFollowUp_ContainsReminderText()
    {
        var mem = new ProceduralMemory();
        var tomorrow = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");
        mem.ScheduledEvents.Add(new ScheduledEvent
        {
            Id = "exam",
            Event = "Physics exam",
            Date = tomorrow,
            FollowUp = "Ask about preparation"
        });
        _service.Save(mem);
        _service.Load();

        var text = _service.FormatForPrompt();
        Assert.Contains("Reminder: Ask about preparation", text);
    }

    [Fact]
    public void FormatForPrompt_WithoutFollowUp_NoReminderLine()
    {
        var mem = new ProceduralMemory();
        var tomorrow = DateTime.UtcNow.Date.AddDays(1).ToString("yyyy-MM-dd");
        mem.ScheduledEvents.Add(new ScheduledEvent
        {
            Id = "meeting",
            Event = "Team meeting",
            Date = tomorrow
        });
        _service.Save(mem);
        _service.Load();

        var text = _service.FormatForPrompt();
        Assert.Contains("Team meeting", text);
        Assert.DoesNotContain("Reminder:", text);
    }

    [Fact]
    public void FormatForPrompt_InNDays_Label()
    {
        var mem = new ProceduralMemory();
        var inThree = DateTime.UtcNow.Date.AddDays(3).ToString("yyyy-MM-dd");
        mem.ScheduledEvents.Add(new ScheduledEvent
        {
            Id = "event3",
            Event = "Deadline",
            Date = inThree
        });
        _service.Save(mem);
        _service.Load();

        var text = _service.FormatForPrompt();
        Assert.Contains("(in 3 days)", text);
    }
}

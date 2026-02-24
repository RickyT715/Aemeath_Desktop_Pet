using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class OfflineResponsesTests
{
    [Fact]
    public void Greetings_HasAtLeast10Entries()
    {
        Assert.True(OfflineResponses.Greetings.Length >= 10);
    }

    [Fact]
    public void IdleChatter_HasAtLeast20Entries()
    {
        Assert.True(OfflineResponses.IdleChatter.Length >= 20);
    }

    [Fact]
    public void AllArrays_HaveContent()
    {
        Assert.NotEmpty(OfflineResponses.Greetings);
        Assert.NotEmpty(OfflineResponses.IdleChatter);
        Assert.NotEmpty(OfflineResponses.HappyReactions);
        Assert.NotEmpty(OfflineResponses.SleepyReactions);
        Assert.NotEmpty(OfflineResponses.LonelyMelancholy);
        Assert.NotEmpty(OfflineResponses.CatReactions);
        Assert.NotEmpty(OfflineResponses.PaperPlaneLines);
        Assert.NotEmpty(OfflineResponses.ReturnAfterAbsence);
        Assert.NotEmpty(OfflineResponses.PomodoroWorkStarted);
        Assert.NotEmpty(OfflineResponses.PomodoroWorkFinished);
        Assert.NotEmpty(OfflineResponses.PomodoroBreakStarted);
        Assert.NotEmpty(OfflineResponses.PomodoroBreakFinished);
        Assert.NotEmpty(OfflineResponses.TaskAddedReactions);
    }

    [Fact]
    public void GetPomodoroLine_ReturnsNonEmpty()
    {
        var result = OfflineResponses.GetPomodoroLine(OfflineResponses.PomodoroWorkStarted);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public void GetPomodoroLine_WithTaskTitle_FormatsPlaceholder()
    {
        var result = OfflineResponses.GetPomodoroLine(OfflineResponses.TaskAddedReactions, "Buy milk");
        Assert.Contains("Buy milk", result);
    }

    [Fact]
    public void GetPomodoroLine_WithoutPlaceholder_IgnoresTaskTitle()
    {
        // PomodoroWorkStarted lines don't have {0} placeholders
        var result = OfflineResponses.GetPomodoroLine(OfflineResponses.PomodoroWorkStarted, "Some task");
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public void Pick_ReturnsNonEmptyString()
    {
        var result = OfflineResponses.Pick(OfflineResponses.Greetings);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public void GetContextual_ReturnsNonEmpty()
    {
        var stats = new AemeathStats();
        var result = OfflineResponses.GetContextual(stats, DateTime.Now);
        Assert.False(string.IsNullOrEmpty(result));
    }

    [Fact]
    public void GetContextual_LowEnergy_ReturnsSleepyReaction()
    {
        var stats = new AemeathStats { Energy = 10, LastSeen = DateTime.UtcNow };
        var result = OfflineResponses.GetContextual(stats, DateTime.Now);
        Assert.Contains(result, OfflineResponses.SleepyReactions);
    }

    [Fact]
    public void GetContextual_LongAbsence_ReturnsReturnMessage()
    {
        // Use a daytime hour (14:00) so the sleepy check doesn't trigger first
        var daytime = new DateTime(2026, 1, 15, 14, 0, 0);
        var stats = new AemeathStats { LastSeen = daytime.AddHours(-5), Energy = 80 };
        var result = OfflineResponses.GetContextual(stats, daytime);
        Assert.Contains(result, OfflineResponses.ReturnAfterAbsence);
    }

    [Fact]
    public void GetGreeting_ReturnsNonEmpty()
    {
        var stats = new AemeathStats { LastSeen = DateTime.UtcNow };
        var result = OfflineResponses.GetGreeting(stats, DateTime.Now);
        Assert.False(string.IsNullOrEmpty(result));
    }
}

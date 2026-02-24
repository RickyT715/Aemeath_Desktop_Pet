using System.Text.Json;
using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class PomodoroEventTests
{
    private static readonly JsonSerializerOptions _jsonOptions = new()
    {
        PropertyNameCaseInsensitive = true
    };

    [Fact]
    public void PomodoroEvent_Deserialize_WorkStarted()
    {
        var json = """{"event":"work_started","taskTitle":"Write report","duration":25}""";
        var evt = JsonSerializer.Deserialize<PomodoroEvent>(json, _jsonOptions);

        Assert.NotNull(evt);
        Assert.Equal("work_started", evt!.Event);
        Assert.Equal("Write report", evt.TaskTitle);
        Assert.Equal(25, evt.Duration);
        Assert.Null(evt.BreakType);
    }

    [Fact]
    public void PomodoroEvent_Deserialize_BreakStarted()
    {
        var json = """{"event":"break_started","breakType":"short","duration":5}""";
        var evt = JsonSerializer.Deserialize<PomodoroEvent>(json, _jsonOptions);

        Assert.NotNull(evt);
        Assert.Equal("break_started", evt!.Event);
        Assert.Equal("short", evt.BreakType);
        Assert.Equal(5, evt.Duration);
        Assert.Null(evt.TaskTitle);
    }

    [Fact]
    public void PomodoroEvent_Deserialize_TaskAdded()
    {
        var json = """{"event":"task_added","taskTitle":"Buy groceries"}""";
        var evt = JsonSerializer.Deserialize<PomodoroEvent>(json, _jsonOptions);

        Assert.NotNull(evt);
        Assert.Equal("task_added", evt!.Event);
        Assert.Equal("Buy groceries", evt.TaskTitle);
        Assert.Null(evt.Duration);
    }

    [Fact]
    public void PomodoroEvent_DefaultValues()
    {
        var evt = new PomodoroEvent();

        Assert.Equal("", evt.Event);
        Assert.Null(evt.TaskTitle);
        Assert.Null(evt.BreakType);
        Assert.Null(evt.Duration);
    }

    [Fact]
    public void PomodoroIntegrationConfig_DefaultValues()
    {
        var config = new PomodoroIntegrationConfig();

        Assert.True(config.Enabled);
        Assert.Equal("AemeathDesktopPet", config.PipeName);
    }

    [Fact]
    public void PomodoroEventType_HasAllExpectedValues()
    {
        Assert.Equal(5, Enum.GetValues<PomodoroEventType>().Length);
        Assert.True(Enum.IsDefined(PomodoroEventType.WorkStarted));
        Assert.True(Enum.IsDefined(PomodoroEventType.WorkFinished));
        Assert.True(Enum.IsDefined(PomodoroEventType.BreakStarted));
        Assert.True(Enum.IsDefined(PomodoroEventType.BreakFinished));
        Assert.True(Enum.IsDefined(PomodoroEventType.TaskAdded));
    }
}

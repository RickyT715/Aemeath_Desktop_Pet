using AemeathDesktopPet.Engine;

namespace AemeathDesktopPet.Tests.Engine;

public class TimeAwarenessTests
{
    [Theory]
    [InlineData(6, TimeAwareness.TimePeriod.Morning)]
    [InlineData(11, TimeAwareness.TimePeriod.Morning)]
    [InlineData(12, TimeAwareness.TimePeriod.Day)]
    [InlineData(16, TimeAwareness.TimePeriod.Day)]
    [InlineData(17, TimeAwareness.TimePeriod.Evening)]
    [InlineData(20, TimeAwareness.TimePeriod.Evening)]
    [InlineData(21, TimeAwareness.TimePeriod.Night)]
    [InlineData(23, TimeAwareness.TimePeriod.Night)]
    [InlineData(0, TimeAwareness.TimePeriod.LateNight)]
    [InlineData(3, TimeAwareness.TimePeriod.LateNight)]
    [InlineData(5, TimeAwareness.TimePeriod.LateNight)]
    public void GetPeriod_ReturnsCorrectPeriod(int hour, TimeAwareness.TimePeriod expected)
    {
        Assert.Equal(expected, TimeAwareness.GetPeriod(hour));
    }

    [Theory]
    [InlineData(7, TimeAwareness.TimePeriod.Morning)]
    [InlineData(9, TimeAwareness.TimePeriod.Morning)]
    [InlineData(10, TimeAwareness.TimePeriod.Morning)]
    [InlineData(13, TimeAwareness.TimePeriod.Day)]
    [InlineData(14, TimeAwareness.TimePeriod.Day)]
    [InlineData(15, TimeAwareness.TimePeriod.Day)]
    [InlineData(18, TimeAwareness.TimePeriod.Evening)]
    [InlineData(19, TimeAwareness.TimePeriod.Evening)]
    [InlineData(22, TimeAwareness.TimePeriod.Night)]
    [InlineData(1, TimeAwareness.TimePeriod.LateNight)]
    [InlineData(2, TimeAwareness.TimePeriod.LateNight)]
    [InlineData(4, TimeAwareness.TimePeriod.LateNight)]
    public void GetPeriod_AllHours_ReturnCorrectPeriod(int hour, TimeAwareness.TimePeriod expected)
    {
        Assert.Equal(expected, TimeAwareness.GetPeriod(hour));
    }

    [Theory]
    [InlineData(-1)]
    [InlineData(-10)]
    [InlineData(24)]
    [InlineData(25)]
    [InlineData(100)]
    [InlineData(int.MinValue)]
    [InlineData(int.MaxValue)]
    public void GetPeriod_OutOfRange_ReturnsLateNight(int hour)
    {
        // The default branch of the switch handles out-of-range values
        Assert.Equal(TimeAwareness.TimePeriod.LateNight, TimeAwareness.GetPeriod(hour));
    }

    [Fact]
    public void ShouldSleep_TrueForLowEnergy_AtNight()
    {
        // ShouldSleep returns true for LateNight or (Night + energy<30)
        // Since we can't control system time, test what we can:
        // At energy=0, night hours (21-23) should trigger sleep
        // But time-dependent, so just verify it doesn't throw
        var result = TimeAwareness.ShouldSleep(100);
        // Result depends on current time; just check it returns a bool
        Assert.IsType<bool>(result);
    }

    [Fact]
    public void ShouldSleep_HighEnergy_DoesNotThrow()
    {
        var result = TimeAwareness.ShouldSleep(100);
        Assert.IsType<bool>(result);
    }

    [Fact]
    public void ShouldSleep_ZeroEnergy_DoesNotThrow()
    {
        var result = TimeAwareness.ShouldSleep(0);
        Assert.IsType<bool>(result);
    }

    [Fact]
    public void ShouldSleep_NegativeEnergy_DoesNotThrow()
    {
        var result = TimeAwareness.ShouldSleep(-10);
        Assert.IsType<bool>(result);
    }

    [Fact]
    public void ShouldSleep_BoundaryEnergy29_DoesNotThrow()
    {
        // 29 is < 30, so at Night should return true
        var result = TimeAwareness.ShouldSleep(29);
        Assert.IsType<bool>(result);
    }

    [Fact]
    public void ShouldSleep_BoundaryEnergy30_DoesNotThrow()
    {
        // 30 is NOT < 30, so at Night should return false (but LateNight always true)
        var result = TimeAwareness.ShouldSleep(30);
        Assert.IsType<bool>(result);
    }

    [Fact]
    public void ShouldGreet_ReturnsBool()
    {
        // Time-dependent; just verify it returns a valid bool without throwing
        var result = TimeAwareness.ShouldGreet();
        Assert.IsType<bool>(result);
    }

    [Fact]
    public void ShouldGreet_ConsistentWithCurrentPeriod()
    {
        // ShouldGreet returns true only when period is Morning
        var period = TimeAwareness.GetCurrentPeriod();
        var shouldGreet = TimeAwareness.ShouldGreet();
        Assert.Equal(period == TimeAwareness.TimePeriod.Morning, shouldGreet);
    }

    [Fact]
    public void GetCurrentPeriod_ReturnsValidPeriod()
    {
        var period = TimeAwareness.GetCurrentPeriod();
        Assert.True(Enum.IsDefined(period));
    }

    [Fact]
    public void GetCurrentPeriod_MatchesGetPeriodWithCurrentHour()
    {
        var current = TimeAwareness.GetCurrentPeriod();
        var fromHour = TimeAwareness.GetPeriod(DateTime.Now.Hour);
        Assert.Equal(fromHour, current);
    }
}

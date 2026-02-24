using AemeathDesktopPet.Models;

namespace AemeathDesktopPet.Tests.Models;

public class AemeathStatsTests
{
    [Fact]
    public void DefaultValues()
    {
        var stats = new AemeathStats();
        Assert.Equal(70, stats.Mood);
        Assert.Equal(80, stats.Energy);
        Assert.Equal(50, stats.Affection);
    }

    [Fact]
    public void Clamp_KeepsWithinBounds()
    {
        var stats = new AemeathStats { Mood = 150, Energy = -20, Affection = 50 };
        stats.Clamp();
        Assert.Equal(100, stats.Mood);
        Assert.Equal(0, stats.Energy);
        Assert.Equal(50, stats.Affection);
    }

    [Fact]
    public void Adjust_IncreasesAndClamps()
    {
        var stats = new AemeathStats { Mood = 95 };
        stats.Adjust(StatType.Mood, 10);
        Assert.Equal(100, stats.Mood);
    }

    [Fact]
    public void Adjust_DecreasesAndClamps()
    {
        var stats = new AemeathStats { Energy = 5 };
        stats.Adjust(StatType.Energy, -10);
        Assert.Equal(0, stats.Energy);
    }

    [Fact]
    public void ApplyOfflineDecay_ShortAbsence_SmallDecay()
    {
        var stats = new AemeathStats { Mood = 70, Energy = 80, Affection = 60 };
        var twoHoursAgo = DateTime.UtcNow.AddHours(-2);

        stats.ApplyOfflineDecay(twoHoursAgo);

        // Mood: 70 - 2*5 = 60 (allow floating point tolerance)
        Assert.InRange(stats.Mood, 59.9, 60.1);
        // Energy: 80 - 2*3 = 74
        Assert.InRange(stats.Energy, 73.9, 74.1);
        // Affection: 60 - 2*1 = 58
        Assert.InRange(stats.Affection, 57.9, 58.1);
    }

    [Fact]
    public void ApplyOfflineDecay_LongAbsence_DiminishingReturns()
    {
        var stats = new AemeathStats { Mood = 70, Energy = 80, Affection = 60 };
        var tenHoursAgo = DateTime.UtcNow.AddHours(-10);

        stats.ApplyOfflineDecay(tenHoursAgo);

        // Mood: 70 - (4*5 + 6*2) = 70 - 32 = 38
        Assert.InRange(stats.Mood, 37, 39);
        // Energy: 80 - (6*3 + 4*1) = 80 - 22 = 58
        Assert.InRange(stats.Energy, 57, 59);
    }

    [Fact]
    public void ApplyOfflineDecay_RespectsFloorValues()
    {
        var stats = new AemeathStats { Mood = 35, Energy = 25, Affection = 45 };
        var longAgo = DateTime.UtcNow.AddHours(-100);

        stats.ApplyOfflineDecay(longAgo);

        Assert.True(stats.Mood >= 30, "Mood floor is 30");
        Assert.True(stats.Energy >= 20, "Energy floor is 20");
        Assert.True(stats.Affection >= 40, "Affection floor is 40");
    }

    [Fact]
    public void ApplyOfflineDecay_VeryShort_NoEffect()
    {
        var stats = new AemeathStats { Mood = 70, Energy = 80, Affection = 60 };
        var justNow = DateTime.UtcNow.AddMinutes(-3);

        stats.ApplyOfflineDecay(justNow);

        Assert.Equal(70, stats.Mood);
        Assert.Equal(80, stats.Energy);
        Assert.Equal(60, stats.Affection);
    }

    [Fact]
    public void DaysTogether_MinimumIsOne()
    {
        var stats = new AemeathStats { FirstLaunch = DateTime.UtcNow };
        Assert.True(stats.DaysTogether >= 1);
    }

    [Fact]
    public void LifetimeCounters_IncrementCorrectly()
    {
        var stats = new AemeathStats();
        Assert.Equal(0, stats.TotalChats);
        stats.TotalChats++;
        Assert.Equal(1, stats.TotalChats);
    }
}
